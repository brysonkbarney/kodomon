# Kodomon v2 — Collection & Discovery System

## Core Concept

Kodomon's game loop stays the same. You code, your pet grows, the widget reflects your activity. The v2 change: you can **discover new species** by hitting specific coding milestones, and build a **collection**. Only one Kodomon is active at a time — the active one earns species XP from your coding. You choose which one to raise.

The fun is collecting. No new traits, no bonuses, no min-max. Each species is its own pixel-art personality evolving through the same 4 stages.

**Extensibility is a first-class goal.** Adding species #7 and beyond must be a one-file change: drop an entry into the species catalog, ship the sprite bundle, done. No branching edits across 8 files, no enum-switch statements to grow.

---

## What stays exactly the same

- Hooks (`session-start.sh`, `session-stop.sh`, `file-event.sh`, `bash-event.sh`) — with **one** small addition documented below
- ActivityWatcher / JSONL pipeline
- PetEngine math: XP rules, diminishing returns, streak multiplier, mood, decay, day gates
- Random events (Inspired / Exhausted / etc.), revival mechanic, neglect alerts
- Backgrounds and accessories, unlocked from **lifetime XP** as today
- Share card and leaderboard concepts — the formats get small updates, but the idea is the same
- `XPCalculator` stays pure, `UnlockSystem` stays import-safe (both take values as params, not state)
- `~/.kodomon/state.json` stays readable by v1 — **v2 writes a new file at `~/.kodomon/state.v2.json`**

## What's new

- A collection of species you can own, starting with Tamago crab
- Each species has its own per-creature XP, stage, mood, and evolution clock
- New species are discovered through specific coding milestones (not RNG, not XP gates)
- An egg appears on the widget when you hit a trigger, and hatches at Tamago→Kobito-equivalent difficulty (scaled by rarity)
- Only the active Kodomon earns species XP and experiences decay — switching is a real choice
- Collection panel with silhouettes for undiscovered species — zero hints until you earn them
- One new hook line in `bash-event.sh` to capture git commit stats (for the Refactorer trigger)
- A **data-driven species catalog** so adding new species is trivial

---

## Species catalog — the data-driven registry

This is the core extensibility pattern. Every species is defined as a single catalog entry. Adding species #7 in v1.1 means appending one entry and dropping in sprites — no switch statements to update, no branching logic to edit.

```swift
enum Rarity: String, Codable, CaseIterable {
    case common, uncommon, rare, legendary

    /// Evolution XP multiplier applied on top of v1 Tamago crab base gates
    var evolutionScale: Double {
        switch self {
        case .common:    return 1.0   // 1k / 10k / 30k
        case .uncommon:  return 1.2   // 1.2k / 12k / 36k
        case .rare:      return 1.5   // 1.5k / 15k / 45k
        case .legendary: return 2.0   // 2k / 20k / 60k
        }
    }

    /// Hatch requirements, same shape as Tamago→Kobito in v1
    var hatchXP: Double {
        switch self {
        case .common: return 1000; case .uncommon: return 1200
        case .rare: return 1500;   case .legendary: return 2000
        }
    }
    var hatchActiveDays: Int {
        switch self {
        case .common, .uncommon: return 2
        case .rare, .legendary: return 3
        }
    }
    var hatchStreak: Int {
        switch self {
        case .common, .uncommon, .rare: return 2
        case .legendary: return 3
        }
    }
}

/// How a species is unlocked. Each case carries its own parameters so new
/// triggers are added by extending this enum (not by touching PetEngine).
enum SpeciesTrigger: Codable {
    case defaultStarter                              // Tamago crab
    case commitsInDay(count: Int)                    // Committer (10)
    case distinctExtensionsInDay(count: Int)         // Polyglot (5)
    case sessionCrossesMidnight                      // Night owl
    case commitDeletionsExceedInsertions             // Refactorer
    case anyKodomonReachesStage(Stage)               // Graduation (Kamisama)
}

/// Full definition of a species. All species data lives in one place.
struct SpeciesDefinition: Codable {
    let id: String               // STABLE string ID, persisted in state.json. Never rename.
    let displayName: String      // User-facing name ("Committer")
    let rarity: Rarity
    let spriteBundle: String     // Key into sprite registry (e.g. "committer")
    let trigger: SpeciesTrigger
    let earnedDescription: String // "How you earned this" copy, shown after unlock
}

enum SpeciesCatalog {
    static let all: [SpeciesDefinition] = [
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

    static func definition(forID id: String) -> SpeciesDefinition? {
        all.first { $0.id == id }
    }
}
```

### Adding a new species (v1.1+ workflow)

1. Add a new `SpeciesDefinition` entry to `SpeciesCatalog.all`
2. Drop a 4-stage sprite bundle into the sprite assets
3. If the trigger type is new, add a case to `SpeciesTrigger` + one evaluation branch
4. Ship

That's it. No edits to PetEngine's core loop, no collection UI changes (the UI iterates `SpeciesCatalog.all`), no menu panel changes, no leaderboard changes. Existing users get the new species available on update — their `triggersArmedAt` is already past, so they can discover it with any qualifying post-install activity.

### Stable string IDs are non-negotiable

Persisted state must store species by the stable string `id` (`"tamago_crab"`, not a Swift enum case), because:
- Future versions can remove species from the catalog without breaking existing saves (the state just holds an unknown ID, which we render as a "??? species" slot until fixed)
- Renaming a species in the UI doesn't require a migration — only the `displayName` changes
- Hot-fixing a broken species definition over the air (via a shipped Swift update) doesn't touch the save format

---

## The 6 species

| # | Species | Trigger | Rarity |
|---|---|---|---|
| 1 | **Tamago crab** | Default — everyone starts here | Common |
| 2 | **Committer** | First day you make 10+ commits | Common |
| 3 | **Polyglot** | First day you touch 5+ distinct file extensions | Common |
| 4 | **Night owl** | First session that starts before midnight and ends after | Uncommon |
| 5 | **Refactorer** | First commit where deletions > insertions | Rare |
| 6 | **Graduation** | First time any of your Kodomon reaches Kamisama. One-time ever. | Legendary |

### Trigger detection — how each one works

All trigger checks run inside `PetEngine`, driven by the catalog's `SpeciesTrigger` case. A single evaluation function dispatches on the case:

```swift
func evaluateTrigger(_ trigger: SpeciesTrigger, against player: PlayerState, event: ActivityEvent) -> Bool { ... }
```

- **`commitsInDay(count: 10)`**: `player.todayCommitCount >= 10`. See midnight-rollover rule below.
- **`distinctExtensionsInDay(count: 5)`**: `player.todayFileTypes.count >= 5`. Extension extracted from the `file-event.sh` path.
- **`sessionCrossesMidnight`**: when a `SessionStop` event fires, compare it to the `SessionStart` for the same session ID; if they straddle local midnight, fire.
- **`commitDeletionsExceedInsertions`**: `bash-event.sh` extension — after a git commit, run `git show --numstat HEAD` and emit `insertions`/`deletions` in the JSONL event. PetEngine checks `deletions > insertions`.
- **`anyKodomonReachesStage(.kamisama)`**: purely internal — fires the moment a Kodomon's `stage` transitions to Kamisama inside PetEngine's evolution logic. **One-time ever.**
- **`defaultStarter`**: not runtime-evaluated; used during first-launch bootstrap to create the starter Kodomon.

### Triggers are post-install only (no retroactive)

Each `PlayerState` has `triggersArmedAt: Date`, set at v2 install. Only events with `event.timestamp >= player.triggersArmedAt` count toward trigger evaluation. Historical 10-commit days or past midnight sessions do NOT retroactively grant eggs.

**Clock skew safety**: use `max(triggersArmedAt, firstEventSeenAfterArming)` as the effective cutoff. Protects against NTP adjustments, timezone travel, or manual clock changes that would otherwise make post-arming events look pre-arming.

### Graduation edge case on migration

If an existing v1 player already has a Kamisama crab at v2 install, Graduation does **not** fire retroactively. It only fires on the *act of evolving* to stage 4 after arming. The player would need to raise some other species to Kamisama. Call this out in release notes.

### Midnight rollover rule for day-scoped triggers

`todayCommitCount`, `todayFileTypes`, `todayFilesWritten`, `todayXP` all reset at local midnight (`lastMidnightReset`). This creates a nasty edge case: if you commit 9 times before midnight and 1 after, `todayCommitCount` resets and Committer never fires.

**Rule**: day-scoped triggers evaluate against the post-reset counters for the *current local day only*. A 9-before / 1-after split does not trigger Committer — you need 10 in the same calendar day. This is intentional: it matches Kodomon's "consistency = daily cadence" ethos, and it's simple to reason about.

**Implementation detail**: midnight-rollover logic must run *before* trigger evaluation on any event that crosses the boundary. Order-of-operations:

1. On event arrival, check if the event's day differs from `lastMidnightReset`
2. If yes, run midnight rollover (reset today-counters, advance streak, decay if applicable)
3. Apply the event to the now-current day's counters
4. Evaluate triggers against the updated counters

Committer fires at the moment the 10th in-day commit is processed, not at end-of-day.

---

## Evolution system — same shape, scaled XP

Every species uses the same 4-stage Tamago→Kobito→Kani→Kamisama ladder. Rarity only scales the XP gates (see `Rarity.evolutionScale`):

| Rarity | Stage 2 | Stage 3 | Stage 4 | Total to Kamisama |
|---|---|---|---|---|
| Common | 1,000 | 10,000 | 30,000 | 30,000 |
| Uncommon | 1,200 | 12,000 | 36,000 | 36,000 |
| Rare | 1,500 | 15,000 | 45,000 | 45,000 |
| Legendary | 2,000 | 20,000 | 60,000 | 60,000 |

Day gates and streak gates from v1 (2 / 5 / 14 active days; 2 / 5 / 10-day streak) apply uniformly. Rarity only scales the XP number.

**Stage names** ("Tamago", "Kobito", "Kani", "Kamisama") are shared across all species. Each species has its own visual for each stage.

---

## XP system — two layers

### Lifetime XP (player-wide)
Exactly like today. Every hook event contributes. Used for:
- Backgrounds, accessories, and every other cosmetic unlock
- Leaderboard ranking
- Never resets, never decays (same rule as v1)

### Species XP (per-creature)
New layer. Only the **active** Kodomon earns species XP from coding. Each event contributes to **both** lifetime XP (always) *and* to the active species' XP (only the active one).

```
coding event → lifetime XP (always, same as v1)
             → species XP of the currently active Kodomon
```

### Key clarification on v1 migration
In v1, `totalXP` and `lifetimeXP` live on the same struct and normally increment in parallel — **but random events and decay only touch `totalXP`, not `lifetimeXP`.** For players who've hit decay or random events, the two numbers have drifted.

**Migration rule**: seed the migrated crab's `speciesXP` from v1's `totalXP` (it drove stage progression in v1, and it's what should drive continued stage progression in v2). Seed `PlayerState.lifetimeXP` from v1's `lifetimeXP` (it drove unlocks in v1, and it continues to drive unlocks in v2). These two numbers will legitimately differ for long-running players — that's correct, not a bug.

---

## Per-species state — each Kodomon has its own clocks

Each `KodomonState` carries its own:
- `speciesID: String` — the stable catalog ID (`"committer"`, `"night_owl"`)
- `speciesXP: Double` — progress toward next stage, decays only while active
- `stage: Stage`
- `stageReachedDate: Date?`
- `daysAlive: Int` — counted from **its own hatch date**, not from player install
- `activeDays: Int` — counted per-species, only days this Kodomon was actually active
- `lastActiveWhileEquipped: Date` — **critical for decay correctness**; timestamp of the last day this Kodomon was the active pet
- `mood: Double`
- `neglectState: NeglectState`
- `hue: Double`
- `name: String`
- `equippedAccessories: [String]`
- `hasRevived: Bool` — **per-creature survivor badge**; earned if this specific Kodomon was ever revived
- `pendingEvolutionFrom: String?` / `pendingEvolutionTo: String?` — cutscene queue, per creature
- `caughtDate: Date`

### Why each species needs its own clocks

A freshly hatched Refactorer must not instantly evolve because the player's overall `activeDays` is 50. Every new Kodomon starts its clock from zero on hatch day.

### Why `lastActiveWhileEquipped` matters for decay

Decay is computed from days since the Kodomon was last *actively earning XP as the equipped pet* — not from the player's last coding day. Otherwise:
- Player swaps Kodomon A out for Kodomon B on Monday
- Player codes Tue/Wed/Thu with B active
- On Thu night's rollover, decay check runs against player's `lastActiveDate` and applies to... whichever is currently active (B)? Or A (which has been frozen since Monday)?

The rule: **decay only applies to the currently active Kodomon, and only counts days since *that Kodomon's own* `lastActiveWhileEquipped`.** Inactive Kodomon are fully frozen — `lastActiveWhileEquipped` stops advancing the moment they're swapped out.

### Inactive = fully frozen

Explicitly, for all Kodomon **not** currently active:
- No species XP earned
- No decay
- No mood drift
- No neglect state progression
- No "ran away"
- `daysAlive` / `activeDays` / `lastActiveWhileEquipped` clocks all paused
- No neglect notifications sent for them

Only the active Kodomon can run away, get sad, evolve, de-evolve, or fire notifications. When an inactive one is swapped back in, it picks up exactly where it left off.

### Revival applies only to the active

The v1 revival mechanic (pet runs away after 7+ missed days, code 30 min to bring it back a stage lower) applies only to the **currently active** Kodomon. `isReviving`, `revivalSessionStart` live on `PlayerState` (they're about the current session, not a specific creature). `hasRevived` is per-creature — the survivor badge belongs to the pet that was actually revived.

---

## Egg discovery flow

1. **Trigger fires** — a post-install event satisfies the catalog trigger
2. **Egg appears on the widget** — a small pixel egg rolls into the scene next to your active Kodomon. No intrusive notification.
3. **Hatch incubation** — the egg accumulates incubation XP from the active Kodomon's coding sessions, with requirements scaled by rarity (see table below)
4. **Hatching animation** — once requirements are met, tapping the egg plays an evolution-style cutscene and reveals the new species at Stage 1 (Tamago)
5. **Naming** — new Kodomon gets a random Japanese name from `NameGenerator` by default. Player can rename anytime from the collection panel — **no forced modal**, doesn't interrupt coding flow
6. **Added to collection** — the new Kodomon is saved as **inactive**. Player chooses if/when to swap it in.

### Hatch requirements by rarity

| Rarity | Hatch XP | Active days | Streak |
|---|---|---|---|
| Common | 1,000 | 2 | 2 |
| Uncommon | 1,200 | 2 | 2 |
| Rare | 1,500 | 3 | 2 |
| Legendary | 2,000 | 3 | 3 |

Hatch XP is accumulated **incubation XP**, which comes from the active Kodomon's coding sessions during incubation. Each coding event grants species XP to the active Kodomon *and* incubation XP to the pending egg. The egg is not a separate Kodomon; it's a pending arrival that shares in your activity.

The common egg hatch effort is intentionally identical to v1's Tamago→Kobito — if that felt good to earn, this will too.

### Edge case: trigger fires while no active Kodomon is healthy

There are two "no active" scenarios:
- **Active Kodomon has run away** (`neglectState == .ranAway`) — trigger still fires, egg enters the queue, but incubation is **paused** until the player revives the active pet. Incubation XP from the revival session counts normally once revival succeeds.
- **During first-launch bootstrap, before the starter Kodomon exists** — can't happen. The default Tamago crab is created synchronously during the first launch flow, before any events are processed.

### Edge case: active Kodomon runs away during incubation

Incubation is paused the moment `neglectState == .ranAway`. When the player revives the active pet (or swaps to a healthy Kodomon), incubation resumes from where it left off. No incubation XP is lost; the egg is also frozen during a runaway state.

### Multiple eggs queue up

If you trigger two eggs before the first hatches (e.g. Committer AND Polyglot on the same day), they queue. **Only one egg incubates at a time.** The next appears on the widget once the current hatches. Keeps the widget uncluttered and the incubation math unambiguous.

### Pending evolution cutscenes vs pending eggs

Both queues need to coexist:
- **Pending evolution** belongs to a specific Kodomon (`pendingEvolutionFrom/To` lives on `KodomonState`). If Kodomon A has a pending cutscene when swapped out, the cutscene still plays the next time A is active.
- **Pending eggs** are player-wide, FIFO. Only the head of the queue is visible on the widget.

The widget prioritizes: (1) active Kodomon's pending evolution cutscene, (2) hatching egg animation, (3) normal idle rendering. No two overlapping animations.

---

## Collection UI

New panel accessed from the menubar menu or a button on the stats panel.

- **Grid of species slots** — one slot per entry in `SpeciesCatalog.all`, so it automatically grows when new species ship
- **Unlocked slot** shows: sprite at current stage, species `displayName`, current stage, species XP bar, caught date, pet name, "Set as active" button, and a **"How you earned this:"** line with `SpeciesDefinition.earnedDescription`
- **Locked slot** shows: **pure silhouette**. No name, no hint, no description. Just a shadow and a question mark. No spoilers.
- Small indicator (crown or glow) on the currently active slot
- Tapping a locked slot just bounces it — no tooltip, no modal

The widget layout itself doesn't change. The collection is a separate view.

---

## Menu panel — two XP bars

The current stats panel shows one XP number and stage. In v2, the player has **two** numbers that move independently:

- **Active Kodomon's species XP** — bar with stage label, `"450 / 1000 to Kobito"`
- **Lifetime XP** — bar with next unlock label, `"12,350 / 15,000 to next background"`

Two clearly labeled progress bars, stacked, with tiny helper text: *"This grows your Kodomon"* / *"This unlocks cosmetics"*. Remove the single-number ambiguity from v1.

Also display: active Kodomon's name, species, and per-creature `daysAlive` and `activeDays`. (No player-wide `daysAlive`/`activeDays` anymore — those only make sense per-creature in v2.)

---

## Leaderboard

Sorted by **lifetime XP** (unchanged from today). Each row now displays the **active** Kodomon's species and stage alongside the player name:

```
1. @brysonkb  — Kamisama Refactorer   184,200 XP
2. @someone   — Kani Committer         92,800 XP
3. @another   — Kobito Tamago crab     18,300 XP
```

### Server protocol change (flag)

`LeaderboardService.swift` currently uploads `total_xp` and assumes one pet per row. v2 must upload:
- `lifetime_xp` (sort key)
- `active_species_id` (stable string: `"refactorer"`, `"tamago_crab"`)
- `active_stage`
- `active_pet_name`

**Server compatibility plan**: during v2 ramp, the server needs to accept both old (v1 `total_xp`) and new (v2 `lifetime_xp` + species fields) payloads for at least one release. v1 users on an old build should still appear in the leaderboard with their crab. Coordinate with the kodomon.app backend before shipping v2.

No collection-count sort axis — that would incentivize catching for catching's sake.

---

## Share card

`ShareCardView.swift` currently reads `state.petName`, `state.stage`, `state.petHue`, `state.totalXP`. All of these move.

v2 share card:
- Renders the **currently active** Kodomon (species, stage, name, hue, accessories, background)
- Shows **species XP** for the "XP" stat (labeled as such — not ambiguous "total XP")
- Optional small line: **"Lifetime XP: 12,350"** so the cosmetic/leaderboard metric is still visible
- Filename on export: `Kodomon-\(activeKodomon.name)-\(activeKodomon.speciesID).png` — species ID in the filename prevents collisions when the player has two Kodomon with the same name

---

## State refactor

### Split `PetState` into `PlayerState` + `[KodomonState]`

```swift
struct PlayerState: Codable {
    // Identity + lifetime progress (player-wide, never reset)
    var lifetimeXP: Double
    var totalCommits: Int
    var totalSessionMins: Int
    var totalLinesWritten: Int
    var biggestCommitLines: Int

    // Streaks & activity (player-wide)
    var currentStreak: Int
    var longestStreak: Int
    var lastActiveDate: Date        // player's last coding day (for streak math)
    var lastMidnightReset: Date

    // Today buffers (player-wide, reset at midnight)
    var todayXP: Double
    var todaySessionMins: Int
    var todayFileTypes: Set<String>
    var todayFilesWritten: Set<String>
    var todayIsActive: Bool
    var todayCommitCount: Int        // NEW for Committer trigger

    // Random event state (player-wide)
    var activeEvent: RandomEvent?
    var activeEventExpiry: Date?

    // Collection
    var activeKodomonID: UUID
    var collection: [KodomonState]
    var pendingEggs: [PendingEgg]   // FIFO queue; head is the visible/incubating egg

    // Trigger bookkeeping
    var triggersArmedAt: Date
    var triggersFired: Set<String>   // set of fired species IDs, e.g. ["committer", "polyglot"]

    // Cosmetics (player-wide unlocks, driven by lifetime XP)
    var unlockedItems: Set<String>
    var activeBackground: String

    // Revival session state (player-wide — about the current session, not a specific creature)
    var isReviving: Bool
    var revivalSessionStart: Date?

    // Schema versioning for future migrations
    var schemaVersion: Int           // starts at 2 for v2
}

struct KodomonState: Codable {
    var id: UUID
    var speciesID: String            // STABLE catalog ID (e.g. "tamago_crab")
    var name: String
    var hue: Double
    var speciesXP: Double
    var stage: Stage
    var stageReachedDate: Date?
    var daysAlive: Int               // counted from caughtDate (hatch date), not player install
    var activeDays: Int              // counted only while this Kodomon was the equipped active
    var lastActiveWhileEquipped: Date  // for correct per-creature decay
    var mood: Double
    var neglectState: NeglectState
    var equippedAccessories: [String]
    var caughtDate: Date
    var hasRevived: Bool             // per-creature survivor badge

    // Evolution cutscene queue, per-creature — plays next time this is active
    var pendingEvolutionFrom: String?
    var pendingEvolutionTo: String?
}

struct PendingEgg: Codable {
    var speciesID: String            // stable catalog ID
    var incubationXP: Double
    var incubationActiveDays: Int    // counted only during active, non-runaway days
    var triggeredDate: Date
}
```

### Complete field mapping v1 → v2

| v1 `PetState` field | v2 destination | Notes |
|---|---|---|
| `petName` | `KodomonState.name` (existing crab) | |
| `petHue` | `KodomonState.hue` (existing crab) | |
| `daysAlive` | `KodomonState.daysAlive` (existing crab) | |
| `activeDays` | `KodomonState.activeDays` (existing crab) | |
| `createdAt` | `KodomonState.caughtDate` (existing crab) | |
| `totalXP` | `KodomonState.speciesXP` (existing crab) | **Seeds species XP, not lifetime XP** |
| `todayXP` | `PlayerState.todayXP` | |
| `todaySessionMins` | `PlayerState.todaySessionMins` | |
| `lifetimeXP` | `PlayerState.lifetimeXP` | |
| `stage` | `KodomonState.stage` (existing crab) | |
| `currentStreak` | `PlayerState.currentStreak` | |
| `longestStreak` | `PlayerState.longestStreak` | |
| `mood` | `KodomonState.mood` (existing crab) | |
| `neglectState` | `KodomonState.neglectState` (existing crab) | |
| `equippedAccessories` | `KodomonState.equippedAccessories` (existing crab) | |
| `unlockedItems` | `PlayerState.unlockedItems` | |
| `activeBackground` | `PlayerState.activeBackground` | |
| `totalCommits` | `PlayerState.totalCommits` | |
| `totalSessionMins` | `PlayerState.totalSessionMins` | |
| `totalLinesWritten` | `PlayerState.totalLinesWritten` | |
| `biggestCommitLines` | `PlayerState.biggestCommitLines` | |
| `lastActiveDate` | `PlayerState.lastActiveDate` AND `KodomonState.lastActiveWhileEquipped` (existing crab) | Same value, both fields |
| `stageReachedDate` | `KodomonState.stageReachedDate` (existing crab) | |
| `lastMidnightReset` | `PlayerState.lastMidnightReset` | |
| `todayFileTypes` | `PlayerState.todayFileTypes` | |
| `todayFilesWritten` | `PlayerState.todayFilesWritten` | |
| `todayIsActive` | `PlayerState.todayIsActive` | |
| `activeEvent` | `PlayerState.activeEvent` | **Must not be dropped** |
| `activeEventExpiry` | `PlayerState.activeEventExpiry` | **Must not be dropped** |
| `isReviving` | `PlayerState.isReviving` | |
| `revivalSessionStart` | `PlayerState.revivalSessionStart` | |
| `hasRevived` | `KodomonState.hasRevived` (existing crab) | Moves to per-creature |
| `pendingEvolutionFrom/To` | `KodomonState.pendingEvolutionFrom/To` (existing crab) | Moves to per-creature |

### Migration procedure

On first v2 launch, the `StateStore` looks at `~/.kodomon/`:

1. **If `state.v2.json` exists** → load it directly. No migration.
2. **Else if `state.json` exists** → migrate:
   1. Read the v1 `PetState` using the existing decoder (already has `decodeIfPresent` fallbacks)
   2. Build `PlayerState` per the mapping table above
   3. Build a single `KodomonState` with `speciesID = "tamago_crab"` for the existing crab per the mapping table above
   4. Set that crab as `activeKodomonID`
   5. Set `triggersArmedAt = Date()` — historical events never retroactively trigger anything
   6. Set `triggersFired = []`, `pendingEggs = []`
   7. Set `schemaVersion = 2`
   8. Write to `state.v2.json` atomically
   9. **Leave `state.json` untouched** — acts as a rollback breadcrumb for Sparkle v2→v1 downgrades
3. **Else (fresh install)** → run the existing `WelcomeView` flow to name the first crab, create a `KodomonState` for it with `speciesID = "tamago_crab"`, and write `state.v2.json`. (Fresh installs keep the naming ceremony; only future species auto-name on hatch.)

### Why bump the file name to `state.v2.json`

If a user rolls back v2 → v1 via Sparkle, v1 will read `state.json`. If we'd overwritten `state.json` with the v2 schema, v1's `decodeIfPresent` would fall back to zeros for every unknown field and the player would lose their crab silently. By writing v2 to a new filename and leaving v1's file untouched, a rollback restores the pre-v2 state exactly. Lossy rollback is still possible (post-v2 XP doesn't make it back into `state.json`), but the crab survives.

`state.json` remains the v1 breadcrumb forever — we never delete it. On future v2 launches, we use `state.v2.json`.

### Migration testing requirement

Phase 1 is not complete until there's a unit test that round-trips **at least 20 canned v1 `state.json` samples** through the migration and asserts every mapped field survives. Samples should include:
- Fresh crab (stage 1, minimal state)
- Mid-game crab (Kobito, accessories equipped, streak 5)
- Late-game crab (Kamisama, hasRevived=true, lots of unlocks)
- Edge cases: empty petName, zero XP, future `stageReachedDate`, `activeEvent` set, `neglectState=sick`

---

## Hook changes — only one

Only `bash-event.sh` needs a change. After a git commit event, extend the hook to run:

```sh
git show --numstat HEAD 2>/dev/null
```

Parse the output to get total insertions and deletions, include them in the JSONL event:

```json
{"type":"commit","timestamp":"...","sha":"...","insertions":42,"deletions":87}
```

PetEngine reads the new fields and fires the Refactorer trigger when `deletions > insertions`. No other hook changes.

**Backward compat**: the v1 engine will ignore the new fields (existing `decodeIfPresent` behavior), so running v2 hooks on a v1 binary is safe during rollout.

---

## First-launch flow for fresh installs

Preserve the existing `WelcomeView` naming ceremony for the **Tamago crab starter**. New users still get the "name your first Kodomon" moment as a welcome ritual. This is deliberately inconsistent with the auto-name rule for hatched eggs — the first crab is special.

`AppDelegate` first-launch check currently reads `engine.state.petName.isEmpty`. In v2, it becomes:

```swift
if engine.state.collection.isEmpty { // fresh install, run WelcomeView }
```

---

## Notifications

`NotificationManager` already takes `petName: String` as a parameter (it doesn't read `PetState` directly), so the refactor is mechanical: pass `engine.activeKodomon.name` instead of `engine.state.petName`.

**Rule**: only the **active** Kodomon fires notifications. Inactive Kodomon are frozen and do not send neglect alerts, streak reminders, or evolution nudges. Otherwise a player with 6 Kodomon would get 6 neglect alerts simultaneously.

---

## Notes on components that don't need changes

- **`XPCalculator`**: pure functions, takes values as params — no change needed
- **`UnlockSystem`**: import-safe, takes `lifetimeXP` as param — no change needed
- **`RandomEventEngine`**: currently mutates `state.mood` and `state.totalXP`; in v2 it mutates `PlayerState.activeEvent` and the active Kodomon's mood/speciesXP. Same logic, new targets.
- **`AccessoryRenderer`**: pure pixel data — no change needed
- **`PixelSpriteView`**: takes `stage`, `petHue`, `equippedAccessories`, `neglectState`, `evolveProgress` as explicit params — safe, just wire from active Kodomon
- **Hook scripts**: only `bash-event.sh` changes (one line)

---

## What we're NOT doing

- No traits, bonuses, or per-species min-maxing — every species plays by identical game rules
- No catch mechanic, no failed catches, no RNG drops
- No passive XP for inactive Kodomon — frozen means frozen
- No hints for locked species in the collection panel — pure silhouettes only
- No trading, no releasing
- No per-species decay/mood rules (same rules for all species)
- No collection-count axis on the leaderboard
- No shinies in v2 (could add later if the base loop lands)
- No retroactive trigger evaluation — post-install events only
- No splitting `state.json` across multiple files — one file, one atomic write

---

## Priority order

### Phase 0 — Species catalog scaffolding (no logic change)
1. Add `Rarity`, `SpeciesTrigger`, `SpeciesDefinition`, `SpeciesCatalog` as pure types
2. No integration yet — just compiles and has unit tests for catalog lookup and rarity math
3. This is a prerequisite because `KodomonState.speciesID` can't be validated without the catalog

### Phase 1 — State refactor + migration
1. Add `PlayerState` + `KodomonState` + `PendingEgg` types
2. Rewrite `StateStore` to load/save the new schema to `state.v2.json`, with v1 fallback migration
3. Rewrite `PetEngine` internal storage — keep the public API where possible (widget + views shouldn't care)
4. Port all v1 field access to either `player` or `activeKodomon` accessors
5. Unit test: 20+ v1 state samples migrate cleanly
6. Manual test: install v2 over a real v1 install, verify existing crab unchanged
7. **Do not ship** until phase 2 is done — a phase-1-only build is visually identical to v1 and has no user value

### Phase 2 — Trigger detection
1. Wire trigger evaluation into PetEngine on every event
2. Add `triggersArmedAt` set at v2 install
3. Implement the 5 post-install triggers (Committer, Polyglot, Night owl, Refactorer, Graduation)
4. Update `bash-event.sh` to emit insertions/deletions
5. Unit tests for each trigger: fires exactly once, fires only post-arming, day-rollover cases

### Phase 3 — Pending-egg pipeline
1. `PendingEgg` queue in `PlayerState`, egg XP accumulates from active coding
2. Widget shows head-of-queue egg animation
3. Hatch cutscene reuses the existing evolution cutscene path
4. Queue advances FIFO

### Phase 4 — Collection UI
1. Silhouette grid, unlocked slot details, "How you earned this" line
2. Set-active button + swap logic
3. First-time collection panel onboarding card

### Phase 5 — Menu panel + leaderboard + share card refactor
1. Two XP bars in menu panel
2. `LeaderboardService` updates + backend coordination for new payload
3. `ShareCardView` refactor for active Kodomon

### Phase 6 — Sprites & polish
1. New pixel art for 5 new species × 4 stages (~20 sprites)
2. Per-species egg art
3. Hatch animation variants
4. Collection transitions

### Can ship species incrementally

Because of the catalog pattern, a v2.0 release could ship with just the 6 base species, and v2.1 could add a 7th with no schema migration. That's the whole point of Phase 0 being a prerequisite — it unblocks future content drops.

---

## Resolved decisions (from design discussion)

- ✅ 6 species total (Tamago crab + 5 new)
- ✅ Same 4-stage evolution, scaled XP by rarity (+20 / +50 / +100%)
- ✅ Hatch requirements scaled by rarity (common matches v1 Tamago→Kobito exactly)
- ✅ No traits — collection is the reward
- ✅ Locked species show pure silhouettes with zero hints
- ✅ Unlocked species show a "How you earned this" trigger description
- ✅ Triggers are post-install only, never retroactive
- ✅ Graduation is one-time ever, even on migration for existing Kamisama crabs
- ✅ Inactive Kodomon are fully frozen (no decay, no mood, no neglect, no notifications)
- ✅ Each Kodomon has its own clocks (daysAlive, activeDays, lastActiveWhileEquipped) from hatch date
- ✅ Accessories + backgrounds stay player-wide, unlock from lifetime XP
- ✅ Leaderboard still sorts by lifetime XP, shows active species/stage next to name
- ✅ Hatch naming uses random default (rename from collection); fresh-install Tamago keeps WelcomeView
- ✅ Multiple pending eggs queue FIFO, one at a time
- ✅ `state.v2.json` is a new file; `state.json` stays as v1 rollback breadcrumb
- ✅ `SpeciesCatalog` is a data-driven registry with stable string IDs for persistence
- ✅ `hasRevived` moves to per-creature (KodomonState)
- ✅ Random event state (`activeEvent`, `activeEventExpiry`) is player-wide
- ✅ `totalXP` (v1) seeds `speciesXP` (v2) on migration; `lifetimeXP` stays `lifetimeXP`
- ✅ `LeaderboardService` payload changes — requires backend coordination
- ✅ `ShareCardView` export filename includes species ID to prevent name collisions
- ✅ Midnight rollover runs before trigger evaluation; day-scoped triggers don't span calendar days

No open questions remain. Ready for implementation, starting with Phase 0.
