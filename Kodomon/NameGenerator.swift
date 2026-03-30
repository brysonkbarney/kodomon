import Foundation

struct NameGenerator {
    static let names: [String] = [
        // Japanese names (romaji)
        "Mochi", "Kuro", "Shiro", "Hana", "Yuki",
        "Sora", "Taro", "Chibi", "Nori", "Riku",
        "Aki", "Kai", "Maru", "Hoshi", "Kumo",
        "Tsuyu", "Ren", "Suki", "Miso", "Dango",
        "Tofu", "Yuzu", "Matcha", "Wasabi", "Goma",
        "Azuki", "Kinako", "Sakura", "Kaede", "Umi",
        "Kaze", "Tsuki", "Haru", "Natsu", "Fuyu",
        "Momo", "Kiko", "Nana", "Roku", "Jiro",
        "Pochi", "Tama", "Mikan", "Anko", "Soba",

        // American / English names
        "Pixel", "Byte", "Chip", "Dot", "Boop",
        "Bean", "Nugget", "Pepper", "Clover", "Gizmo",
        "Pebble", "Sprout", "Biscuit", "Waffles", "Pickles",
        "Bumble", "Fizz", "Zippy", "Scooter", "Pip",
        "Pudding", "Noodle", "Maple", "Cocoa", "Mocha",
        "Olive", "Ginger", "Sage", "Basil", "Thyme",
        "Cricket", "Sparky", "Buttons", "Patches", "Sunny",
        "Blip", "Glitch", "Debug", "Cache", "Stack",
        "Sudo", "Bash", "Kernel", "Bit", "Loop",
    ]

    static func randomThree() -> [String] {
        var pool = names.shuffled()
        return Array(pool.prefix(3))
    }

    static func reroll(excluding: [String]) -> [String] {
        let pool = names.filter { !excluding.contains($0) }.shuffled()
        return Array(pool.prefix(3))
    }
}
