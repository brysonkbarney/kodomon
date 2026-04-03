import Foundation

enum RandomEvent: String, Codable, CaseIterable {
    // Positive (common)
    case codingStorm    // 2x XP for 60 min
    case goodVibes      // +30 mood
    case luckyCommit    // next commit worth 3x
    case flowState      // no diminishing returns for 45 min

    // Challenge (common)
    case bugInvasion    // -50 XP unless 3 files edited in 2h
    case homesick       // mood locked at 30 for the day
    case codeDrought    // XP halved until next commit
    case restlessNight  // starts day at 40 mood

    // Rare (1% chance each)
    case kaniFestival   // triple XP all day
    case ancientBug     // -200 XP but +5 base XP/commit forever
    case developerGod   // Kamisama appears briefly

    var isPositive: Bool {
        switch self {
        case .codingStorm, .goodVibes, .luckyCommit, .flowState,
             .kaniFestival, .developerGod:
            return true
        case .bugInvasion, .homesick, .codeDrought, .restlessNight, .ancientBug:
            return false
        }
    }

    var isRare: Bool {
        switch self {
        case .kaniFestival, .ancientBug, .developerGod:
            return true
        default:
            return false
        }
    }

    var displayName: String {
        switch self {
        case .codingStorm: return "Coding Storm ⚡"
        case .goodVibes: return "Good Vibes ✨"
        case .luckyCommit: return "Lucky Commit 🍀"
        case .flowState: return "Flow State 🌊"
        case .bugInvasion: return "Bug Invasion 🐛"
        case .homesick: return "Homesick 🏠"
        case .codeDrought: return "Code Drought 🏜️"
        case .restlessNight: return "Restless Night 😴"
        case .kaniFestival: return "Kani Festival 🦀🎉"
        case .ancientBug: return "Ancient Bug 🪲"
        case .developerGod: return "Developer God Visits 👑"
        }
    }
}

struct RandomEventEngine {
    /// Roll for a daily event. 30% chance of common, 1% chance per rare.
    static func rollDailyEvent(currentStreak: Int, stage: Stage) -> RandomEvent? {
        // Rare events: 1% each
        for rare in RandomEvent.allCases where rare.isRare {
            if Double.random(in: 0...1) < 0.01 {
                return rare
            }
        }

        // 30% chance of a common event
        guard Double.random(in: 0...1) < 0.30 else { return nil }

        // Filter eligible events
        var pool: [RandomEvent] = []

        // Positive events (only include fully implemented ones)
        pool.append(.codingStorm)
        if currentStreak >= 3 {
            pool.append(.goodVibes)
        }

        // Challenge events (only include fully implemented ones)
        pool.append(.codeDrought)
        pool.append(.restlessNight)

        return pool.randomElement()
    }

    /// Apply the immediate effects of an event to pet state
    static func applyEvent(_ event: RandomEvent, to state: inout PetState) {
        switch event {
        case .goodVibes:
            state.mood = min(100, state.mood + 30)
        case .restlessNight:
            state.mood = 40
        case .homesick:
            state.mood = 30
        case .ancientBug:
            state.totalXP = max(0, state.totalXP - 200)
        case .kaniFestival:
            state.mood = min(100, state.mood + 20)
        default:
            break // Other events modify XP rates, handled in PetEngine
        }

        NSLog("[Kodomon] Random event: %@", event.displayName)
    }
}
