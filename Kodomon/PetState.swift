import Foundation

enum Stage: String, Codable, CaseIterable {
    case tamago = "tamago"
    case kobito = "kobito"
    case kani = "kani"
    case kamisama = "kamisama"

    var displayName: String {
        switch self {
        case .tamago: return "Tamago 卵"
        case .kobito: return "Kobito 小人"
        case .kani: return "Kani 蟹"
        case .kamisama: return "Kamisama 神様"
        }
    }

    var xpThreshold: Double {
        switch self {
        case .tamago: return 0
        case .kobito: return 3000
        case .kani: return 20000
        case .kamisama: return 100000
        }
    }

    var requiredActiveDays: Int {
        switch self {
        case .tamago: return 0
        case .kobito: return 5
        case .kani: return 21
        case .kamisama: return 60
        }
    }

    var requiredStreak: Int {
        switch self {
        case .tamago: return 0
        case .kobito: return 3
        case .kani: return 7
        case .kamisama: return 14
        }
    }

    /// XP floor before de-evolution triggers (with grace buffer)
    var deEvolveFloor: Double {
        switch self {
        case .tamago: return 0
        case .kobito: return 1500
        case .kani: return 12000
        case .kamisama: return 70000
        }
    }

    var nextStage: Stage? {
        switch self {
        case .tamago: return .kobito
        case .kobito: return .kani
        case .kani: return .kamisama
        case .kamisama: return nil
        }
    }

    var previousStage: Stage? {
        switch self {
        case .tamago: return nil
        case .kobito: return .tamago
        case .kani: return .kobito
        case .kamisama: return .kani
        }
    }
}

enum NeglectState: String, Codable {
    case none
    case hungry    // 2h no activity
    case tired     // 8h no activity
    case sad       // 1 missed day
    case sick      // 3 missed days
    case critical  // 7 missed days
    case ranAway   // 14 missed days
}

struct PetState: Codable {
    var petName: String
    var petHue: Double  // 0.0-1.0, random at creation, permanent
    var daysAlive: Int
    var activeDays: Int
    var createdAt: Date
    var totalXP: Double
    var todayXP: Double
    var todaySessionMins: Int
    var lifetimeXP: Double
    var stage: Stage
    var currentStreak: Int
    var longestStreak: Int
    var mood: Double
    var neglectState: NeglectState
    var equippedAccessories: [String]
    var unlockedItems: Set<String>
    var activeBackground: String
    var totalCommits: Int
    var totalLinesWritten: Int
    var biggestCommitLines: Int
    var lastActiveDate: Date
    var stageReachedDate: Date?
    var lastMidnightReset: Date
    var todayFileTypes: Set<String>
    var todayFilesWritten: Set<String>
    var todayIsActive: Bool
    var activeEvent: RandomEvent?
    var activeEventExpiry: Date?

    /// Pick a random hue that produces a good, readable pet color
    static func randomGoodHue() -> Double {
        // Good hue ranges that look great and contrast well:
        // 0.0-0.05  = red/scarlet
        // 0.08-0.12 = orange (default peach area)
        // 0.30-0.45 = green/teal
        // 0.55-0.65 = blue
        // 0.70-0.80 = purple/violet
        // 0.85-0.95 = pink/magenta
        // Avoid: 0.13-0.20 (muddy yellow), 0.45-0.55 (cyan that blends with backgrounds)
        let ranges: [(Double, Double)] = [
            (0.0, 0.05),   // red
            (0.08, 0.12),  // orange
            (0.30, 0.42),  // green
            (0.57, 0.65),  // blue
            (0.72, 0.80),  // purple
            (0.88, 0.97),  // pink
        ]
        let range = ranges.randomElement()!
        return Double.random(in: range.0...range.1)
    }

    static func initial() -> PetState {
        let now = Date()
        return PetState(
            petName: "",
            petHue: PetState.randomGoodHue(),
            daysAlive: 0,
            activeDays: 0,
            createdAt: now,
            totalXP: 0,
            todayXP: 0,
            todaySessionMins: 0,
            lifetimeXP: 0,
            stage: .tamago,
            currentStreak: 0,
            longestStreak: 0,
            mood: 50,
            neglectState: .none,
            equippedAccessories: [],
            unlockedItems: [],
            activeBackground: "none",
            totalCommits: 0,
            totalLinesWritten: 0,
            biggestCommitLines: 0,
            lastActiveDate: now,
            stageReachedDate: now,
            lastMidnightReset: Calendar.current.startOfDay(for: now),
            todayFileTypes: [],
            todayFilesWritten: [],
            todayIsActive: false,
            activeEvent: nil,
            activeEventExpiry: nil
        )
    }
}
