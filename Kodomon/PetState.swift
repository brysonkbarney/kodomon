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
        case .kobito: return 1000
        case .kani: return 10000
        case .kamisama: return 30000
        }
    }

    var requiredActiveDays: Int {
        switch self {
        case .tamago: return 0
        case .kobito: return 2
        case .kani: return 5
        case .kamisama: return 14
        }
    }

    var requiredStreak: Int {
        switch self {
        case .tamago: return 0
        case .kobito: return 2
        case .kani: return 5
        case .kamisama: return 10
        }
    }

    /// XP floor before de-evolution triggers (with grace buffer)
    var deEvolveFloor: Double {
        switch self {
        case .tamago: return 0
        case .kobito: return 500
        case .kani: return 5000
        case .kamisama: return 15000
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
    case tired     // 8h no activity
    case sad       // 1 missed day
    case sick      // 2-4 missed days
    case critical  // 5-6 missed days
    case ranAway   // 7+ missed days
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
    var isReviving: Bool
    var revivalSessionStart: Date?
    var hasRevived: Bool  // survivor badge
    var pendingEvolutionFrom: String?  // Stage rawValue — set when evolution triggers, cleared when cutscene plays
    var pendingEvolutionTo: String?    // Stage rawValue — paired with pendingEvolutionFrom

    // MARK: - Memberwise init (needed because custom Decodable init disables auto-synthesis)

    init(petName: String, petHue: Double, daysAlive: Int, activeDays: Int, createdAt: Date,
         totalXP: Double, todayXP: Double, todaySessionMins: Int, lifetimeXP: Double, stage: Stage,
         currentStreak: Int, longestStreak: Int, mood: Double, neglectState: NeglectState,
         equippedAccessories: [String], unlockedItems: Set<String>, activeBackground: String,
         totalCommits: Int, totalLinesWritten: Int, biggestCommitLines: Int, lastActiveDate: Date,
         stageReachedDate: Date?, lastMidnightReset: Date, todayFileTypes: Set<String>,
         todayFilesWritten: Set<String>, todayIsActive: Bool, activeEvent: RandomEvent?,
         activeEventExpiry: Date?, isReviving: Bool, revivalSessionStart: Date?, hasRevived: Bool,
         pendingEvolutionFrom: String? = nil, pendingEvolutionTo: String? = nil) {
        self.petName = petName; self.petHue = petHue; self.daysAlive = daysAlive
        self.activeDays = activeDays; self.createdAt = createdAt; self.totalXP = totalXP
        self.todayXP = todayXP; self.todaySessionMins = todaySessionMins; self.lifetimeXP = lifetimeXP
        self.stage = stage; self.currentStreak = currentStreak; self.longestStreak = longestStreak
        self.mood = mood; self.neglectState = neglectState; self.equippedAccessories = equippedAccessories
        self.unlockedItems = unlockedItems; self.activeBackground = activeBackground
        self.totalCommits = totalCommits; self.totalLinesWritten = totalLinesWritten
        self.biggestCommitLines = biggestCommitLines; self.lastActiveDate = lastActiveDate
        self.stageReachedDate = stageReachedDate; self.lastMidnightReset = lastMidnightReset
        self.todayFileTypes = todayFileTypes; self.todayFilesWritten = todayFilesWritten
        self.todayIsActive = todayIsActive; self.activeEvent = activeEvent
        self.activeEventExpiry = activeEventExpiry; self.isReviving = isReviving
        self.revivalSessionStart = revivalSessionStart; self.hasRevived = hasRevived
        self.pendingEvolutionFrom = pendingEvolutionFrom; self.pendingEvolutionTo = pendingEvolutionTo
    }

    // MARK: - Migration-safe decoding

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let now = Date()
        petName = try c.decodeIfPresent(String.self, forKey: .petName) ?? ""
        petHue = try c.decodeIfPresent(Double.self, forKey: .petHue) ?? PetState.randomGoodHue()
        daysAlive = try c.decodeIfPresent(Int.self, forKey: .daysAlive) ?? 0
        activeDays = try c.decodeIfPresent(Int.self, forKey: .activeDays) ?? 0
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? now
        totalXP = try c.decodeIfPresent(Double.self, forKey: .totalXP) ?? 0
        todayXP = try c.decodeIfPresent(Double.self, forKey: .todayXP) ?? 0
        todaySessionMins = try c.decodeIfPresent(Int.self, forKey: .todaySessionMins) ?? 0
        let decodedLifetimeXP = try c.decodeIfPresent(Double.self, forKey: .lifetimeXP) ?? 0
        lifetimeXP = decodedLifetimeXP == 0 && totalXP > 0 ? totalXP : decodedLifetimeXP
        stage = try c.decodeIfPresent(Stage.self, forKey: .stage) ?? .tamago
        currentStreak = try c.decodeIfPresent(Int.self, forKey: .currentStreak) ?? 0
        longestStreak = try c.decodeIfPresent(Int.self, forKey: .longestStreak) ?? 0
        mood = try c.decodeIfPresent(Double.self, forKey: .mood) ?? 50
        neglectState = try c.decodeIfPresent(NeglectState.self, forKey: .neglectState) ?? .none
        equippedAccessories = try c.decodeIfPresent([String].self, forKey: .equippedAccessories) ?? []
        unlockedItems = try c.decodeIfPresent(Set<String>.self, forKey: .unlockedItems) ?? []
        activeBackground = try c.decodeIfPresent(String.self, forKey: .activeBackground) ?? "none"
        totalCommits = try c.decodeIfPresent(Int.self, forKey: .totalCommits) ?? 0
        totalLinesWritten = try c.decodeIfPresent(Int.self, forKey: .totalLinesWritten) ?? 0
        biggestCommitLines = try c.decodeIfPresent(Int.self, forKey: .biggestCommitLines) ?? 0
        lastActiveDate = try c.decodeIfPresent(Date.self, forKey: .lastActiveDate) ?? now
        stageReachedDate = try c.decodeIfPresent(Date.self, forKey: .stageReachedDate)
        lastMidnightReset = try c.decodeIfPresent(Date.self, forKey: .lastMidnightReset) ?? Calendar.current.startOfDay(for: now)
        todayFileTypes = try c.decodeIfPresent(Set<String>.self, forKey: .todayFileTypes) ?? []
        todayFilesWritten = try c.decodeIfPresent(Set<String>.self, forKey: .todayFilesWritten) ?? []
        todayIsActive = try c.decodeIfPresent(Bool.self, forKey: .todayIsActive) ?? false
        activeEvent = try c.decodeIfPresent(RandomEvent.self, forKey: .activeEvent)
        activeEventExpiry = try c.decodeIfPresent(Date.self, forKey: .activeEventExpiry)
        isReviving = try c.decodeIfPresent(Bool.self, forKey: .isReviving) ?? false
        revivalSessionStart = try c.decodeIfPresent(Date.self, forKey: .revivalSessionStart)
        hasRevived = try c.decodeIfPresent(Bool.self, forKey: .hasRevived) ?? false
        pendingEvolutionFrom = try c.decodeIfPresent(String.self, forKey: .pendingEvolutionFrom)
        pendingEvolutionTo = try c.decodeIfPresent(String.self, forKey: .pendingEvolutionTo)
    }

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
            activeEventExpiry: nil,
            isReviving: false,
            revivalSessionStart: nil,
            hasRevived: false,
            pendingEvolutionFrom: nil,
            pendingEvolutionTo: nil
        )
    }
}
