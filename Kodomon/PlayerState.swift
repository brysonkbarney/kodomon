//
//  PlayerState.swift
//  Kodomon
//
//  Player-wide state for Kodomon v2. Holds everything that belongs to the
//  player (not to any single creature): lifetime XP, streaks, cosmetic unlocks,
//  daily rollup buffers, random events, revival session, and the collection
//  of all caught Kodomon.
//
//  Seeds v1 state migration via StateStore. See docs/v2-catching-design.md.
//

import Foundation

struct PlayerState: Codable {
    // MARK: - Identity + lifetime progress (never reset, never decay)
    var lifetimeXP: Double
    var totalCommits: Int
    var totalSessionMins: Int
    var totalLinesWritten: Int
    var biggestCommitLines: Int

    // MARK: - Streaks & activity (player-wide)
    var currentStreak: Int
    var longestStreak: Int
    var lastActiveDate: Date
    var lastMidnightReset: Date

    // MARK: - Today buffers (player-wide, reset at midnight)
    var todayXP: Double
    var todaySessionMins: Int
    var todayFileTypes: Set<String>
    var todayFilesWritten: Set<String>
    var todayIsActive: Bool
    /// Number of git commits the player has made today. New in v2 for the
    /// Committer trigger. Resets at midnight.
    var todayCommitCount: Int

    // MARK: - Random event state (player-wide)
    var activeEvent: RandomEvent?
    var activeEventExpiry: Date?

    // MARK: - Collection
    /// ID of the currently active Kodomon. Must correspond to an entry in `collection`.
    var activeKodomonID: UUID
    /// All Kodomon the player owns. Contains at least one entry (the starter).
    var collection: [KodomonState]
    /// Queue of eggs waiting to hatch. FIFO — `first` is the head incubating
    /// and visible on the widget; subsequent eggs wait their turn.
    var pendingEggs: [PendingEgg]

    // MARK: - Trigger bookkeeping
    /// The moment v2 was first installed (or migrated to). Events with
    /// timestamps before this do not count toward trigger evaluation.
    var triggersArmedAt: Date
    /// Stable species IDs whose discovery trigger has already fired. Each
    /// entry means "this species has already dropped an egg for the player
    /// and should never drop another one." Starter Tamago crab is not in
    /// this set — its trigger is `.defaultStarter` and not runtime-evaluated.
    var triggersFired: Set<String>

    // MARK: - Cosmetics (player-wide unlocks, driven by lifetime XP)
    var unlockedItems: Set<String>
    var activeBackground: String

    // MARK: - Revival session state
    /// True while the player is actively coding to revive a runaway pet.
    /// About the session, not about any specific creature.
    var isReviving: Bool
    var revivalSessionStart: Date?

    // MARK: - Schema version
    /// Persisted schema version. Starts at 2 for v2. Future schema migrations
    /// read this to decide how to decode.
    var schemaVersion: Int

    // MARK: - Convenience accessors

    /// The currently active Kodomon. Crashes if `activeKodomonID` doesn't
    /// correspond to an entry in the collection — this should never happen
    /// in normal operation because every code path that removes or changes
    /// the active must update both fields atomically.
    var activeKodomon: KodomonState {
        get {
            guard let k = collection.first(where: { $0.id == activeKodomonID }) else {
                fatalError("PlayerState.activeKodomon: no Kodomon with id \(activeKodomonID) in collection of \(collection.count)")
            }
            return k
        }
        set {
            guard let idx = collection.firstIndex(where: { $0.id == activeKodomonID }) else {
                fatalError("PlayerState.activeKodomon setter: no Kodomon with id \(activeKodomonID) in collection")
            }
            collection[idx] = newValue
        }
    }

    /// The head of the pending-egg queue, if any. This is the egg currently
    /// incubating and shown on the widget.
    var headPendingEgg: PendingEgg? {
        pendingEggs.first
    }
}

// MARK: - Initial state for fresh installs

extension PlayerState {
    /// Build a brand-new PlayerState for a first-time install. Callers still
    /// need to set up the starter Kodomon and add it to `collection`, then
    /// point `activeKodomonID` at it. See StateStore or AppDelegate bootstrap.
    static func initial(starter: KodomonState) -> PlayerState {
        let now = Date()
        return PlayerState(
            lifetimeXP: 0,
            totalCommits: 0,
            totalSessionMins: 0,
            totalLinesWritten: 0,
            biggestCommitLines: 0,
            currentStreak: 0,
            longestStreak: 0,
            lastActiveDate: now,
            lastMidnightReset: Calendar.current.startOfDay(for: now),
            todayXP: 0,
            todaySessionMins: 0,
            todayFileTypes: [],
            todayFilesWritten: [],
            todayIsActive: false,
            todayCommitCount: 0,
            activeEvent: nil,
            activeEventExpiry: nil,
            activeKodomonID: starter.id,
            collection: [starter],
            pendingEggs: [],
            triggersArmedAt: now,
            triggersFired: [],
            unlockedItems: [],
            activeBackground: "none",
            isReviving: false,
            revivalSessionStart: nil,
            schemaVersion: 2
        )
    }
}
