//
//  KodomonState.swift
//  Kodomon
//
//  Per-creature state for Kodomon v2. One instance per caught Kodomon in the
//  player's collection. Only the currently active Kodomon earns species XP,
//  decays, and fires notifications — inactive ones are fully frozen.
//
//  See docs/v2-catching-design.md.
//

import Foundation

struct KodomonState: Codable, Identifiable {
    // MARK: - Identity
    let id: UUID
    /// Stable catalog ID (e.g. "tamago_crab", "committer"). Resolves to a
    /// `SpeciesDefinition` via `SpeciesCatalog.definition(forID:)`. Never rename.
    var speciesID: String
    var name: String
    var hue: Double

    // MARK: - Progression
    /// XP accumulated by this Kodomon while it was the active pet. Drives
    /// stage evolution. Decays only while this Kodomon is active.
    var speciesXP: Double
    var stage: Stage
    /// When this Kodomon's current stage was reached. Drives de-evolution
    /// grace period and evolution cutscene pacing.
    var stageReachedDate: Date?

    // MARK: - Per-creature clocks (count only while this Kodomon is active)
    /// Days since this Kodomon hatched. Counts only while active.
    var daysAlive: Int
    /// Days this Kodomon has been the active pet AND the player coded.
    var activeDays: Int
    /// Timestamp of the last day this Kodomon was the active pet and saw
    /// any activity. Used for per-creature decay math — ensures decay only
    /// counts days while the Kodomon was actually equipped.
    var lastActiveWhileEquipped: Date

    // MARK: - Mood & neglect (per-creature; frozen while inactive)
    var mood: Double
    var neglectState: NeglectState

    // MARK: - Cosmetics attached to this creature
    var equippedAccessories: [String]

    // MARK: - Badges
    /// True if this specific Kodomon was ever revived from a runaway state.
    /// Per-creature — earned by the pet that actually went through revival.
    var hasRevived: Bool

    // MARK: - Evolution cutscene queue (per-creature)
    /// Set when this Kodomon evolves; cleared when the cutscene plays.
    /// Survives inactivity — if this Kodomon was swapped out mid-cutscene,
    /// the cutscene plays the next time it becomes active again.
    var pendingEvolutionFrom: String?
    var pendingEvolutionTo: String?

    // MARK: - History
    /// When this Kodomon hatched (or, for the migrated v1 crab, `createdAt`).
    var caughtDate: Date

    // MARK: - Convenience accessors

    /// The species definition this Kodomon corresponds to. Returns nil if
    /// `speciesID` references a removed species — handle gracefully in UI.
    var species: SpeciesDefinition? {
        SpeciesCatalog.definition(forID: speciesID)
    }

    /// The rarity of this Kodomon's species. Defaults to `.common` if the
    /// species ID is unknown (defensive — old saves from a future version).
    var rarity: Rarity {
        species?.rarity ?? .common
    }
}

// MARK: - Defensive decoding

extension KodomonState {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let now = Date()
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        speciesID = try c.decodeIfPresent(String.self, forKey: .speciesID) ?? ""
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        hue = try c.decodeIfPresent(Double.self, forKey: .hue) ?? 0
        speciesXP = try c.decodeIfPresent(Double.self, forKey: .speciesXP) ?? 0
        stage = try c.decodeIfPresent(Stage.self, forKey: .stage) ?? .tamago
        stageReachedDate = try c.decodeIfPresent(Date.self, forKey: .stageReachedDate)
        daysAlive = try c.decodeIfPresent(Int.self, forKey: .daysAlive) ?? 0
        activeDays = try c.decodeIfPresent(Int.self, forKey: .activeDays) ?? 0
        lastActiveWhileEquipped = try c.decodeIfPresent(Date.self, forKey: .lastActiveWhileEquipped) ?? now
        mood = try c.decodeIfPresent(Double.self, forKey: .mood) ?? 50
        neglectState = try c.decodeIfPresent(NeglectState.self, forKey: .neglectState) ?? .none
        equippedAccessories = try c.decodeIfPresent([String].self, forKey: .equippedAccessories) ?? []
        hasRevived = try c.decodeIfPresent(Bool.self, forKey: .hasRevived) ?? false
        pendingEvolutionFrom = try c.decodeIfPresent(String.self, forKey: .pendingEvolutionFrom)
        pendingEvolutionTo = try c.decodeIfPresent(String.self, forKey: .pendingEvolutionTo)
        caughtDate = try c.decodeIfPresent(Date.self, forKey: .caughtDate) ?? now
    }
}

// MARK: - Factory

extension KodomonState {
    /// Build a fresh Kodomon of the given species at Tamago stage with
    /// default mood/hue. Used for starter creation and egg hatching.
    static func fresh(speciesID: String, name: String) -> KodomonState {
        let now = Date()
        return KodomonState(
            id: UUID(),
            speciesID: speciesID,
            name: name,
            hue: PetHue.random(),
            speciesXP: 0,
            stage: .tamago,
            stageReachedDate: now,
            daysAlive: 0,
            activeDays: 0,
            lastActiveWhileEquipped: now,
            mood: 50,
            neglectState: .none,
            equippedAccessories: [],
            hasRevived: false,
            pendingEvolutionFrom: nil,
            pendingEvolutionTo: nil,
            caughtDate: now
        )
    }
}

// MARK: - PendingEgg

/// An egg that has been discovered but not yet hatched. Accumulates
/// incubation XP from the active Kodomon's coding sessions until it meets
/// the rarity-scaled hatch requirements.
struct PendingEgg: Codable, Identifiable {
    var id: UUID
    /// Stable species ID of the Kodomon that will hatch from this egg.
    var speciesID: String
    /// Incubation XP accumulated so far (out of `rarity.hatchXP`).
    var incubationXP: Double
    /// Active days accumulated during incubation (out of `rarity.hatchActiveDays`).
    /// Counts only days while the player had an active (non-runaway) Kodomon.
    var incubationActiveDays: Int
    /// Timestamp when the trigger fired.
    var triggeredDate: Date

    /// The species definition for this egg. Returns nil if the species was
    /// removed in a newer version.
    var species: SpeciesDefinition? {
        SpeciesCatalog.definition(forID: speciesID)
    }

    /// Factory — create a new pending egg for the given species right now.
    static func newlyTriggered(speciesID: String) -> PendingEgg {
        PendingEgg(
            id: UUID(),
            speciesID: speciesID,
            incubationXP: 0,
            incubationActiveDays: 0,
            triggeredDate: Date()
        )
    }
}

// MARK: - PendingEgg defensive decoding

extension PendingEgg {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        speciesID = try c.decodeIfPresent(String.self, forKey: .speciesID) ?? ""
        incubationXP = try c.decodeIfPresent(Double.self, forKey: .incubationXP) ?? 0
        incubationActiveDays = try c.decodeIfPresent(Int.self, forKey: .incubationActiveDays) ?? 0
        triggeredDate = try c.decodeIfPresent(Date.self, forKey: .triggeredDate) ?? Date()
    }
}

// MARK: - Hue helper

/// Picks a random hue in the "good" ranges — avoiding muddy yellows and
/// background-clashing cyans. Shared between fresh Kodomon creation and
/// the v1 migration helper.
enum PetHue {
    static func random() -> Double {
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
}
