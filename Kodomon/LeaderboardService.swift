import Foundation
import Combine

struct LeaderboardEntry: Codable, Identifiable {
    var id: String { pet_name + stage + String(pet_hue) }
    let pet_name: String
    let total_xp: Double
    let lifetime_xp: Double
    let stage: String
    let current_streak: Int
    let longest_streak: Int
    let active_days: Int
    let total_commits: Int
    let lines_written: Int
    let mood: Double
    let equipped_accessories: [String]
    let active_background: String
    let pet_hue: Double
    let updated_at: String
}

@MainActor
class LeaderboardService: ObservableObject {
    static let shared = LeaderboardService()

    @Published var entries: [LeaderboardEntry] = []
    @Published var isOptedIn: Bool = false
    @Published var isSyncing: Bool = false

    private let endpoint = "https://iczwbhwfepgldhznbfjz.supabase.co/functions/v1/leaderboard-sync"
    private let kodomonIdKey = "kodomonLeaderboardId"
    private let optedInKey = "kodomonLeaderboardOptedIn"

    var kodomonId: String {
        if let existing = UserDefaults.standard.string(forKey: kodomonIdKey) {
            return existing
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: kodomonIdKey)
        return newId
    }

    private init() {
        isOptedIn = UserDefaults.standard.bool(forKey: optedInKey)
    }

    func optIn() {
        isOptedIn = true
        UserDefaults.standard.set(true, forKey: optedInKey)
        NSLog("[Kodomon] Leaderboard opted in")
    }

    func optOut() {
        isOptedIn = false
        UserDefaults.standard.set(false, forKey: optedInKey)
        NSLog("[Kodomon] Leaderboard opted out")
    }

    // MARK: - Sync stats to leaderboard

    /// Sync the currently active Kodomon + player progress to the leaderboard.
    /// Payload keeps the v1 `total_xp` field for backend compatibility during
    /// the v2 ramp — it carries the active Kodomon's species XP (which was
    /// v1's `totalXP` semantics). `lifetime_xp` is the player-wide cumulative
    /// value used for ranking.
    func sync(player: PlayerState, force: Bool = false) {
        guard isOptedIn else { return }
        guard force else { return } // Only sync when explicitly forced (midnight, opt-in, evolution)
        isSyncing = true

        let kodomon = player.activeKodomon
        let body: [String: Any] = [
            "pet_name": kodomon.name,
            "total_xp": kodomon.speciesXP,
            "lifetime_xp": player.lifetimeXP,
            "stage": kodomon.stage.rawValue,
            "current_streak": player.currentStreak,
            "longest_streak": player.longestStreak,
            "active_days": kodomon.activeDays,
            "total_commits": player.totalCommits,
            "lines_written": player.totalLinesWritten,
            "mood": kodomon.mood,
            "equipped_accessories": kodomon.equippedAccessories,
            "active_background": player.activeBackground,
            "pet_hue": kodomon.hue,
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            isSyncing = false
            return
        }

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(kodomonId, forHTTPHeaderField: "X-Kodomon-Id")
        request.timeoutInterval = 10

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async { self.isSyncing = false }
            if let error = error {
                NSLog("[Kodomon] Leaderboard sync failed: %@", error.localizedDescription)
                return
            }
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                NSLog("[Kodomon] Leaderboard synced")
            } else if let http = response as? HTTPURLResponse {
                NSLog("[Kodomon] Leaderboard sync error: %d", http.statusCode)
            }
        }.resume()
    }

    // MARK: - Fetch leaderboard

    func fetch(sort: String = "total_xp") {
        var components = URLComponents(string: endpoint)!
        components.queryItems = [
            URLQueryItem(name: "sort", value: sort),
            URLQueryItem(name: "limit", value: "50"),
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.timeoutInterval = 10

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                NSLog("[Kodomon] Leaderboard fetch failed: %@", error.localizedDescription)
                return
            }
            guard let data = data else { return }
            do {
                let decoded = try JSONDecoder().decode([LeaderboardEntry].self, from: data)
                DispatchQueue.main.async {
                    self.entries = decoded
                    NSLog("[Kodomon] Leaderboard fetched: %d entries", decoded.count)
                }
            } catch {
                NSLog("[Kodomon] Leaderboard decode error: %@", error.localizedDescription)
            }
        }.resume()
    }
}
