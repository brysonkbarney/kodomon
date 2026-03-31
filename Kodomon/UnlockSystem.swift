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
        UnlockableBackground(id: "tokyoNight", displayName: "Tokyo Night", xpRequired: 500, description: "Neon city skyline"),
        UnlockableBackground(id: "sakura", displayName: "Sakura", xpRequired: 2000, description: "Cherry blossom garden"),
        UnlockableBackground(id: "mountFuji", displayName: "Mount Fuji", xpRequired: 5000, description: "Snow-capped mountain"),
        UnlockableBackground(id: "toriiGate", displayName: "Torii Gate", xpRequired: 10000, description: "Sacred shrine entrance"),
    ]

    static let accessories: [UnlockableAccessory] = [
        UnlockableAccessory(id: "tiny_headband", displayName: "Tiny Headband", xpRequired: 200, slot: "head", description: "A simple headband"),
        UnlockableAccessory(id: "pixel_crown", displayName: "Pixel Crown", xpRequired: 1000, slot: "head", description: "A small crown"),
        UnlockableAccessory(id: "dev_hoodie", displayName: "Dev Hoodie", xpRequired: 3000, slot: "body", description: "Cozy hoodie"),
        UnlockableAccessory(id: "pixel_sunglasses", displayName: "Sunglasses", xpRequired: 4000, slot: "face", description: "Cool shades"),
        UnlockableAccessory(id: "sakura_crown", displayName: "Sakura Crown", xpRequired: 6000, slot: "head", description: "Cherry blossom crown"),
        UnlockableAccessory(id: "golden_crown", displayName: "Golden Crown", xpRequired: 8000, slot: "head", description: "A golden crown"),
        UnlockableAccessory(id: "katana", displayName: "Katana", xpRequired: 12000, slot: "body", description: "A pixel blade"),
        UnlockableAccessory(id: "halo", displayName: "Halo", xpRequired: 15000, slot: "head", description: "Angelic glow"),
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
