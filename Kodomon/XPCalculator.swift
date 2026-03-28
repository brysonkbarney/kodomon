import Foundation

struct XPCalculator {
    static let dailyCap: Double = 900

    /// XP for a git commit based on total lines changed
    static func commitXP(linesAdded: Int, linesRemoved: Int) -> Double {
        let total = linesAdded + linesRemoved
        switch total {
        case 1...25: return 25
        case 26...100: return 60
        case 101...300: return 150
        case 301...500: return 350
        case 501...: return min(Double(total), 800)
        default: return 0
        }
    }

    /// XP for active session minutes
    static func sessionXP(minutes: Int) -> Double {
        return Double(min(minutes, 120)) * 2
    }

    /// XP for writing lines of code (nearly negligible)
    static func linesXP(linesWritten: Int) -> Double {
        return Double(linesWritten / 50)
    }

    /// Diminishing returns multiplier based on session time today
    static func diminishingReturns(todaySessionMins: Int) -> Double {
        switch todaySessionMins {
        case 0..<90: return 1.0
        case 90..<180: return 0.6
        default: return 0.25
        }
    }

    /// Streak multiplier
    static func streakMultiplier(streak: Int) -> Double {
        switch streak {
        case 0...2: return 1.0
        case 3...6: return 1.2
        case 7...13: return 1.5
        case 14...29: return 1.8
        default: return 2.0
        }
    }

    /// Mood multiplier
    static func moodMultiplier(mood: Double) -> Double {
        switch mood {
        case 80...100: return 1.3
        case 60..<80: return 1.15
        case 40..<60: return 1.0
        case 20..<40: return 0.85
        default: return 0.6
        }
    }

    /// Apply all multipliers and cap
    static func applyMultipliers(
        rawXP: Double,
        todaySessionMins: Int,
        streak: Int,
        mood: Double,
        todayXP: Double
    ) -> Double {
        var xp = rawXP
        xp *= diminishingReturns(todaySessionMins: todaySessionMins)
        xp *= streakMultiplier(streak: streak)
        xp *= moodMultiplier(mood: mood)

        // Don't exceed daily cap
        let remaining = max(0, dailyCap - todayXP)
        return min(xp, remaining)
    }
}
