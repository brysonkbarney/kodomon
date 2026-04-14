//
//  SpeciesCatalog.swift
//  Kodomon
//
//  Data-driven registry of Kodomon species. Adding a new species in a future
//  version is a one-entry append to `SpeciesCatalog.all` + a sprite bundle.
//  Persistence uses the stable string `id` on each definition — never rename.
//

import Foundation

// MARK: - Rarity

/// Rarity tier for a species. Controls evolution XP scaling and hatch requirements.
enum Rarity: String, Codable, CaseIterable, Sendable {
    case common
    case uncommon
    case rare
    case legendary

    /// XP required to evolve a species of this rarity to the given stage from Tamago.
    /// Common matches v1 Tamago crab thresholds exactly.
    func xpThreshold(for stage: Stage) -> Double {
        switch stage {
        case .tamago:
            return 0
        case .kobito:
            switch self {
            case .common: return 1_000
            case .uncommon: return 1_200
            case .rare: return 1_500
            case .legendary: return 2_000
            }
        case .kani:
            switch self {
            case .common: return 10_000
            case .uncommon: return 12_000
            case .rare: return 15_000
            case .legendary: return 20_000
            }
        case .kamisama:
            switch self {
            case .common: return 30_000
            case .uncommon: return 36_000
            case .rare: return 45_000
            case .legendary: return 60_000
            }
        }
    }

    /// Species XP required for an egg of this rarity to hatch.
    var hatchXP: Double {
        switch self {
        case .common: return 1_000
        case .uncommon: return 1_200
        case .rare: return 1_500
        case .legendary: return 2_000
        }
    }

    /// Active days required during incubation before an egg of this rarity can hatch.
    var hatchActiveDays: Int {
        switch self {
        case .common, .uncommon: return 2
        case .rare, .legendary: return 3
        }
    }

    /// Streak required during incubation before an egg of this rarity can hatch.
    var hatchStreak: Int {
        switch self {
        case .common, .uncommon, .rare: return 2
        case .legendary: return 3
        }
    }
}

// MARK: - Trigger

/// How a species is unlocked. Each case carries its own parameters so new
/// triggers are added by extending this enum (not by editing PetEngine).
enum SpeciesTrigger: Sendable {
    /// Default starter — created at first launch, not runtime-evaluated.
    case defaultStarter
    /// Fires when the player makes `count` or more commits in a single local day.
    case commitsInDay(count: Int)
    /// Fires when the player touches `count` or more distinct file extensions in a single local day.
    case distinctExtensionsInDay(count: Int)
    /// Fires when a coding session's start and stop timestamps straddle local midnight.
    case sessionCrossesMidnight
    /// Fires when a git commit has more deletions than insertions.
    case commitDeletionsExceedInsertions
    /// Fires the first time any of the player's Kodomon evolves into the given stage.
    case anyKodomonReachesStage(Stage)
}

// Manual `nonisolated` `Equatable` conformance. Required because `Stage` is
// implicitly MainActor-isolated (default actor isolation), which would make the
// auto-synthesized `Equatable` conformance MainActor-isolated too — and we
// want `SpeciesTrigger` comparable from any context. Compares stages by their
// String raw value to sidestep any actor isolation on `Stage.==`.
extension SpeciesTrigger: Equatable {
    nonisolated static func == (lhs: SpeciesTrigger, rhs: SpeciesTrigger) -> Bool {
        switch (lhs, rhs) {
        case (.defaultStarter, .defaultStarter):
            return true
        case let (.commitsInDay(l), .commitsInDay(r)):
            return l == r
        case let (.distinctExtensionsInDay(l), .distinctExtensionsInDay(r)):
            return l == r
        case (.sessionCrossesMidnight, .sessionCrossesMidnight):
            return true
        case (.commitDeletionsExceedInsertions, .commitDeletionsExceedInsertions):
            return true
        case let (.anyKodomonReachesStage(l), .anyKodomonReachesStage(r)):
            return l.rawValue == r.rawValue
        default:
            return false
        }
    }
}

// MARK: - Definition

/// Full definition of a species. All species data lives in one place so
/// adding a new species is a single-file change.
struct SpeciesDefinition: Equatable, Sendable {
    /// STABLE string ID persisted in state. Never rename across versions.
    let id: String
    /// User-facing display name.
    let displayName: String
    /// Rarity tier — controls XP scaling and hatch requirements.
    let rarity: Rarity
    /// Key into the sprite asset registry.
    let spriteBundle: String
    /// What unlocks this species.
    let trigger: SpeciesTrigger
    /// Copy shown on the collection card after the player earns this species.
    let earnedDescription: String
}

// MARK: - Catalog

/// Static registry of all Kodomon species. The single source of truth for
/// species data. Add a new species by appending an entry here and shipping
/// its sprite bundle — no other files need to change.
enum SpeciesCatalog {
    /// Every species known to the game. Order is the display order in the collection grid.
    nonisolated static let all: [SpeciesDefinition] = [
        SpeciesDefinition(
            id: "tamago_crab",
            displayName: "Tamago Crab",
            rarity: .common,
            spriteBundle: "tamago_crab",
            trigger: .defaultStarter,
            earnedDescription: "The original. Your first Kodomon."
        ),
        SpeciesDefinition(
            id: "committer",
            displayName: "Committer",
            rarity: .common,
            spriteBundle: "committer",
            trigger: .commitsInDay(count: 10),
            earnedDescription: "You shipped 10 commits in one day."
        ),
        SpeciesDefinition(
            id: "polyglot",
            displayName: "Polyglot",
            rarity: .common,
            spriteBundle: "polyglot",
            trigger: .distinctExtensionsInDay(count: 5),
            earnedDescription: "You touched 5 different file types in one day."
        ),
        SpeciesDefinition(
            id: "night_owl",
            displayName: "Night Owl",
            rarity: .uncommon,
            spriteBundle: "night_owl",
            trigger: .sessionCrossesMidnight,
            earnedDescription: "You coded through midnight. Time flies."
        ),
        SpeciesDefinition(
            id: "refactorer",
            displayName: "Refactorer",
            rarity: .rare,
            spriteBundle: "refactorer",
            trigger: .commitDeletionsExceedInsertions,
            earnedDescription: "You shipped a commit that deleted more than it added. Beautiful."
        ),
        SpeciesDefinition(
            id: "graduation",
            displayName: "Graduation",
            rarity: .legendary,
            spriteBundle: "graduation",
            trigger: .anyKodomonReachesStage(.kamisama),
            earnedDescription: "One of your Kodomon reached Kamisama. Congratulations, sensei."
        ),
    ]

    /// Look up a species by its stable ID. Returns nil if the ID is unknown
    /// (which can legitimately happen if state.json references a species
    /// that was removed in a future version).
    nonisolated static func definition(forID id: String) -> SpeciesDefinition? {
        all.first { $0.id == id }
    }

    /// The default starter species assigned to new players on first launch.
    /// Looked up by stable ID (not by trigger equality) so `starter` can be
    /// `nonisolated` without depending on actor-isolated Equatable machinery.
    /// Force-unwrap is safe: the `tamago_crab` entry is hardcoded above.
    nonisolated static var starter: SpeciesDefinition {
        definition(forID: "tamago_crab")!
    }
}
