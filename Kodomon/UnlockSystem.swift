import Foundation

struct UnlockableBackground: Codable, Identifiable {
    let id: String
    let displayName: String
    let xpRequired: Double
    let description: String
}

struct UnlockableAccessory: Codable, Identifiable {
    let id: String
    let displayName: String
    let xpRequired: Double
    let slot: String // "head", "face", "body"
    let description: String
}

struct UnlockSystem {
    static let backgrounds: [UnlockableBackground] = [
        UnlockableBackground(id: "none", displayName: "Blank", xpRequired: 0, description: "Default"),
        UnlockableBackground(id: "tokyoNight", displayName: "Tokyo Night", xpRequired: 1000, description: "Neon city skyline"),
        UnlockableBackground(id: "sakura", displayName: "Sakura", xpRequired: 5000, description: "Cherry blossom garden"),
        UnlockableBackground(id: "mountFuji", displayName: "Mount Fuji", xpRequired: 20000, description: "Snow-capped mountain"),
        UnlockableBackground(id: "toriiGate", displayName: "Torii Gate", xpRequired: 40000, description: "Sacred shrine entrance"),
        UnlockableBackground(id: "beach", displayName: "Beach", xpRequired: 50000, description: "Sunset paradise"),
    ]

    static let accessories: [UnlockableAccessory] = [
        UnlockableAccessory(id: "tiny_headband", displayName: "Tiny Headband", xpRequired: 500, slot: "head", description: "A simple headband"),
        UnlockableAccessory(id: "sneakers", displayName: "Sneakers", xpRequired: 2000, slot: "feet", description: "Fresh kicks"),
        UnlockableAccessory(id: "pixel_sunglasses", displayName: "Sunglasses", xpRequired: 5000, slot: "face", description: "Cool shades"),
        UnlockableAccessory(id: "boots", displayName: "Boots", xpRequired: 8000, slot: "feet", description: "Sturdy boots"),
        UnlockableAccessory(id: "devil_horns", displayName: "Devil Horns", xpRequired: 12000, slot: "head", description: "Little red horns"),
        UnlockableAccessory(id: "golden_crown", displayName: "Golden Crown", xpRequired: 18000, slot: "head", description: "Fit for royalty"),
        UnlockableAccessory(id: "rice_hat", displayName: "Rice Hat", xpRequired: 25000, slot: "head", description: "Classic kasa"),
        UnlockableAccessory(id: "propeller_hat", displayName: "Propeller Hat", xpRequired: 35000, slot: "head", description: "Wheeee"),
        UnlockableAccessory(id: "top_hat", displayName: "Top Hat", xpRequired: 45000, slot: "head", description: "Classy"),
        UnlockableAccessory(id: "katana", displayName: "Katana", xpRequired: 60000, slot: "side", description: "A warrior's blade"),
    ]

    /// Returns all backgrounds the player has unlocked based on lifetime XP
    static func unlockedBackgrounds(lifetimeXP: Double) -> [UnlockableBackground] {
        return backgrounds.filter { $0.xpRequired <= lifetimeXP }
    }

    /// Returns all accessories the player has unlocked based on lifetime XP
    static func unlockedAccessories(lifetimeXP: Double) -> [UnlockableAccessory] {
        return accessories.filter { $0.xpRequired <= lifetimeXP }
    }

    /// Returns the next locked background (for showing progress)
    static func nextLockedBackground(lifetimeXP: Double) -> UnlockableBackground? {
        return backgrounds.first { $0.xpRequired > lifetimeXP }
    }

    /// Returns the next locked accessory
    static func nextLockedAccessory(lifetimeXP: Double) -> UnlockableAccessory? {
        return accessories.first { $0.xpRequired > lifetimeXP }
    }

    /// Check for newly unlocked items and return them
    static func checkNewUnlocks(oldXP: Double, newXP: Double) -> (backgrounds: [UnlockableBackground], accessories: [UnlockableAccessory]) {
        let newBGs = backgrounds.filter { $0.xpRequired > oldXP && $0.xpRequired <= newXP }
        let newAccs = accessories.filter { $0.xpRequired > oldXP && $0.xpRequired <= newXP }
        return (newBGs, newAccs)
    }
}
