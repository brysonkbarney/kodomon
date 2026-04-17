//
//  StateStore.swift
//  Kodomon
//
//  Persistence layer for PlayerState.
//
//  File layout on disk:
//    ~/.kodomon/state.v2.json   - canonical v2 save (PlayerState)
//    ~/.kodomon/state.json      - v1 save, kept as rollback breadcrumb
//
//  Load order on first v2 launch:
//    1. state.v2.json present    → decode PlayerState directly
//    2. state.json present       → decode LegacyV1PetState, migrate, write
//                                  state.v2.json, leave state.json alone
//    3. neither present          → fresh install with a starter Tamago
//
//  Save always writes state.v2.json atomically. state.json is never touched
//  after migration, so a Sparkle v2→v1 rollback preserves the v1 snapshot.
//

import Foundation

enum StateStore {
    /// The real v2 state file, used by Release builds and read by
    /// Debug builds only to seed the sandbox on first launch.
    static let realV2URL: URL = {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".kodomon/state.v2.json")
    }()

    /// The canonical URL the engine reads and writes. In Debug builds this
    /// points to a sandboxed file so test mutations never touch the real
    /// save. In Release builds it's the real v2 URL.
    static let v2URL: URL = {
        #if DEBUG
        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".kodomon/state.debug.json")
        #else
        return realV2URL
        #endif
    }()

    static let v1URL: URL = {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".kodomon/state.json")
    }()

    // MARK: - Load

    /// Returns a PlayerState from disk, migrating v1 state if needed. Never
    /// returns nil — a fresh install produces an empty PlayerState with a
    /// default Tamago starter.
    static func load() -> PlayerState {
        #if DEBUG
        // First-launch seeding for the debug sandbox. If the debug file
        // doesn't exist yet but a real v2 save does, copy it once so
        // testing starts from a mirror of the real state. After that,
        // the debug file is independent — changes here never leak back
        // to the real save.
        seedDebugSandboxIfNeeded()
        #endif

        let v2Exists = FileManager.default.fileExists(atPath: v2URL.path)

        if let player = loadV2() {
            NSLog("[Kodomon] Loaded %@ — %d Kodomon in collection",
                  v2URL.lastPathComponent, player.collection.count)
            return player
        }

        // If the v2 file exists on disk but failed to decode, do NOT fall
        // through to v1 migration — that would overwrite v2 progress with
        // stale v1 data. Return a fresh install instead.
        if v2Exists {
            NSLog("[Kodomon] CRITICAL: %@ exists but failed to decode — refusing to migrate from v1. Starting fresh.", v2URL.lastPathComponent)
            return freshInstall()
        }

        if let migrated = migrateFromV1() {
            NSLog("[Kodomon] Migrated v1 state.json to %@", v2URL.lastPathComponent)
            return migrated
        }
        NSLog("[Kodomon] Fresh install — creating starter Tamago")
        return freshInstall()
    }

    #if DEBUG
    /// One-time seed of the debug sandbox file from the real v2 save.
    /// Runs only when the debug file doesn't exist and the real file does.
    /// No-op otherwise. Runs before any load, so the engine sees a
    /// populated debug file on its first read.
    private static func seedDebugSandboxIfNeeded() {
        let fm = FileManager.default
        guard !fm.fileExists(atPath: v2URL.path) else { return }
        guard fm.fileExists(atPath: realV2URL.path) else { return }
        do {
            try fm.copyItem(at: realV2URL, to: v2URL)
            NSLog("[Kodomon] Seeded debug sandbox %@ from real state.v2.json",
                  v2URL.lastPathComponent)
        } catch {
            NSLog("[Kodomon] Failed to seed debug sandbox: %@", error.localizedDescription)
        }
    }
    #endif

    private static func loadV2() -> PlayerState? {
        guard let data = try? Data(contentsOf: v2URL) else { return nil }
        do {
            return try JSONDecoder.kodomon.decode(PlayerState.self, from: data)
        } catch {
            NSLog("[Kodomon] Failed to decode state.v2.json: %@", error.localizedDescription)
            return nil
        }
    }

    private static func migrateFromV1() -> PlayerState? {
        guard let data = try? Data(contentsOf: v1URL) else { return nil }
        do {
            let legacy = try JSONDecoder.kodomon.decode(LegacyV1PetState.self, from: data)
            let player = Self.buildPlayerState(fromV1: legacy)
            // Write the new v2 file atomically. Leave state.json untouched
            // — it serves as a rollback breadcrumb for Sparkle v2→v1 downgrades.
            save(player)
            return player
        } catch {
            NSLog("[Kodomon] Failed to decode legacy state.json during migration: %@", error.localizedDescription)
            return nil
        }
    }

    private static func freshInstall() -> PlayerState {
        let starter = KodomonState.fresh(speciesID: "tamago_crab", name: "")
        return PlayerState.initial(starter: starter)
    }

    // MARK: - Save

    static func save(_ player: PlayerState) {
        let dir = v2URL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        do {
            let data = try JSONEncoder.kodomon.encode(player)
            try data.write(to: v2URL, options: .atomic)
        } catch {
            NSLog("[Kodomon] Failed to save player state: %@", error.localizedDescription)
        }
    }

    // MARK: - v1 → v2 migration

    /// Build a PlayerState + starter KodomonState from a decoded v1 save.
    /// See docs/v2-catching-design.md "Complete field mapping v1 → v2" table.
    static func buildPlayerState(fromV1 v1: LegacyV1PetState) -> PlayerState {
        let now = Date()

        // The existing v1 crab becomes a Tamago species KodomonState.
        // Important mapping: v1 `totalXP` seeds `speciesXP` (because v1
        // totalXP drove stage progression and continues to do so in v2).
        // v1 `lifetimeXP` stays as `lifetimeXP` (cosmetics/leaderboard).
        // The two numbers may have legitimately drifted in v1 because of
        // random events and decay — that's correct, not a bug.
        let crab = KodomonState(
            id: UUID(),
            speciesID: "tamago_crab",
            name: v1.petName,
            hue: v1.petHue,
            speciesXP: v1.totalXP,
            stage: v1.stage,
            stageReachedDate: v1.stageReachedDate,
            daysAlive: v1.daysAlive,
            activeDays: v1.activeDays,
            lastActiveWhileEquipped: v1.lastActiveDate,
            mood: v1.mood,
            neglectState: v1.neglectState,
            equippedAccessories: v1.equippedAccessories,
            hasRevived: v1.hasRevived,
            pendingEvolutionFrom: v1.pendingEvolutionFrom,
            pendingEvolutionTo: v1.pendingEvolutionTo,
            caughtDate: v1.createdAt
        )

        return PlayerState(
            lifetimeXP: v1.lifetimeXP,
            totalCommits: v1.totalCommits,
            totalSessionMins: v1.totalSessionMins,
            totalLinesWritten: v1.totalLinesWritten,
            biggestCommitLines: v1.biggestCommitLines,
            currentStreak: v1.currentStreak,
            longestStreak: v1.longestStreak,
            lastActiveDate: v1.lastActiveDate,
            lastMidnightReset: v1.lastMidnightReset,
            todayXP: v1.todayXP,
            todaySessionMins: v1.todaySessionMins,
            todayFileTypes: v1.todayFileTypes,
            todayFilesWritten: v1.todayFilesWritten,
            todayIsActive: v1.todayIsActive,
            todayCommitCount: 0, // new in v2, no v1 equivalent
            activeEvent: v1.activeEvent,
            activeEventExpiry: v1.activeEventExpiry,
            activeKodomonID: crab.id,
            collection: [crab],
            pendingEggs: [],
            triggersArmedAt: now, // historical v1 activity never retroactively triggers
            triggersFired: [],
            unlockedItems: v1.unlockedItems,
            activeBackground: v1.activeBackground,
            isReviving: v1.isReviving,
            revivalSessionStart: v1.revivalSessionStart,
            schemaVersion: 2
        )
    }
}

// MARK: - Legacy v1 schema (for migration only)

/// The v1 `PetState` struct, preserved here verbatim for migration parsing.
/// This type is never constructed at runtime in v2 — it exists solely so
/// `JSONDecoder` can read v1 `state.json` files one final time during
/// the upgrade flow. Do not reference from engine or view code.
struct LegacyV1PetState: Codable {
    var petName: String
    var petHue: Double
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
    var totalSessionMins: Int
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
    var hasRevived: Bool
    var pendingEvolutionFrom: String?
    var pendingEvolutionTo: String?

    // MARK: - Migration-safe decoding

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let now = Date()
        petName = try c.decodeIfPresent(String.self, forKey: .petName) ?? ""
        petHue = try c.decodeIfPresent(Double.self, forKey: .petHue) ?? PetHue.random()
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
        totalSessionMins = try c.decodeIfPresent(Int.self, forKey: .totalSessionMins) ?? 0
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
}

// MARK: - JSON encoder/decoder

extension JSONEncoder {
    static let kodomon: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()
}

extension JSONDecoder {
    static let kodomon: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
