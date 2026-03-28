# Kodomon (コードモン)

A macOS desktop widget — a Tamagotchi-style virtual pet crab that lives and grows from your real Claude Code activity. The more consistently you code, the healthier and more powerful it becomes. Stop coding and it gets sick. Abandon it and it runs away.

Open source, MIT license. 100% local — no server, no account, no data leaves the machine.

---

## What we're building

A floating macOS widget (not a dock app) that sits anywhere on screen. The pet is a pixel art crab inspired by the Claude crab mascot. It has four evolution stages, a full XP and decay system, mood states, random events, and a shareable stats card.

The pet feeds on real coding signals:
- Claude Code session time
- Git commits (sized by lines changed)
- Files written/edited
- Coding streaks and consistency

**Target:** ~3 months of consistent daily coding to reach max evolution.

---

## Tech stack

- **Swift**, macOS 14+ (Sonoma), AppKit App Delegate lifecycle
- **SwiftUI** views hosted in `NSHostingView`
- **NSPanel** for the floating widget (not a dock window)
- **Combine** for reactive data flow
- **FSEvents / DispatchSource** for file watching
- **UserNotifications** for neglect alerts
- **Sparkle** for auto-updates
- No CoreData, no SQLite — single JSON state file
- No server, no network (except optional opt-in leaderboard later)

---

## Project structure

```
Kodomon/
  App/
    AppDelegate.swift        # NSPanel setup, menubar item, app lifecycle
    KodomonApp.swift         # @main entry, @NSApplicationDelegateAdaptor
  Watcher/
    ActivityWatcher.swift    # FSEvents watcher on ~/.kodomon/events.jsonl
    GitWatcher.swift         # watches git-events written by hook
    EventParser.swift        # parses raw JSONL → typed ActivityEvent
  Engine/
    PetEngine.swift          # core ObservableObject, all game logic
    XPCalculator.swift       # XP rules, diminishing returns, daily cap
    DecayManager.swift       # time-based decay, neglect states
    MoodEngine.swift         # mood score and modifiers
    EventEngine.swift        # random event system
    StreakTracker.swift       # streak calculation and multipliers
  UI/
    PetWidgetView.swift      # main floating NSPanel SwiftUI view
    PetSpriteView.swift      # pixel art / animation renderer
    StatsView.swift          # XP bar, mood, streak display
    MenuBarView.swift        # menubar icon + popover
    ShareCardView.swift      # Wrapped-style card, PNG export
    NotificationManager.swift
  Persistence/
    PetState.swift           # Codable struct — single source of truth
    StateStore.swift         # read/write ~/.kodomon/state.json
  Hooks/                     # shell scripts, not Swift
    install-hooks.sh         # run once on first launch
    session-start.sh         # Claude Code SessionStart hook
    file-event.sh            # Claude Code PostToolUse hook
    session-stop.sh          # Claude Code Stop hook
    git-commit.sh            # git post-commit hook
```

---

## How data flows

```
Claude Code activity
        │
        ▼
Shell hooks (session-start.sh, file-event.sh, git-commit.sh)
        │  write one JSON line each
        ▼
~/.kodomon/events.jsonl   ← append-only event log
        │
        ▼
ActivityWatcher (DispatchSource .write event)
        │  reads new lines, parses to ActivityEvent
        ▼
PetEngine (ObservableObject)
        │  applies XP math, decay, mood, streak
        ▼
PetState (Codable struct)
        │  saved to ~/.kodomon/state.json after every change
        ▼
SwiftUI views (PetWidgetView)
        │  renders sprite, XP bar, mood, animations
        ▼
User sees their crab reacting to their code
```

---

## Layer 1 — Claude Code hooks

On first launch, Kodomon installs shell hooks into `~/.claude/settings.json`. These fire asynchronously (don't slow Claude Code down) and append a single JSON line to `~/.kodomon/events.jsonl`.

**~/.claude/settings.json additions:**
```json
{
  "hooks": {
    "SessionStart": [{"hooks": [{"type": "command", "command": "~/.kodomon/hooks/session-start.sh", "async": true}]}],
    "PostToolUse": [{"matcher": "Write|Edit|MultiEdit", "hooks": [{"type": "command", "command": "~/.kodomon/hooks/file-event.sh", "async": true}]}],
    "Stop": [{"hooks": [{"type": "command", "command": "~/.kodomon/hooks/session-stop.sh", "async": true}]}]
  }
}
```

**Each hook writes one line like:**
```jsonl
{"type":"session_start","ts":1711234567,"session_id":"abc123","cwd":"/my/project"}
{"type":"file_write","ts":1711234570,"file":"/project/src/app.ts","lines_added":42,"lines_removed":5}
{"type":"session_stop","ts":1711236000,"session_id":"abc123","duration_secs":1433}
{"type":"git_commit","ts":1711234900,"hash":"a1b2c3","lines_added":127,"lines_removed":30,"files":3}
```

Git commits are captured via a global git hook (`git config --global core.hooksPath`).

---

## Layer 2 — Activity watcher

`ActivityWatcher` uses `DispatchSource.makeFileSystemObjectSource` with `.write` eventMask to watch `~/.kodomon/events.jsonl`. When new bytes appear it reads only the new lines (tracks byte offset), parses them into typed `ActivityEvent` enums, and publishes via a Combine `PassthroughSubject`.

```swift
enum ActivityEvent {
  case sessionStart(sessionId: String, cwd: String, timestamp: Date)
  case sessionStop(sessionId: String, durationSecs: Int, timestamp: Date)
  case fileWrite(filePath: String, linesAdded: Int, linesRemoved: Int, timestamp: Date)
  case gitCommit(hash: String, linesAdded: Int, linesRemoved: Int, files: Int, timestamp: Date)
}
```

---

## Layer 3 — Pet engine

`PetEngine` is the heart of the app. It's a pure Swift `ObservableObject` with no UI dependencies. It subscribes to `ActivityWatcher`, applies all game rules, and publishes `PetState`.

**Key responsibilities:**
- Apply XP from events (with daily cap, diminishing returns, streak multiplier, mood multiplier)
- Midnight timer — resets daily XP, updates streak, checks active day
- Decay manager — runs every 30 min, applies XP decay if neglected
- Evolution checker — checks stage gate conditions after every XP update
- De-evolution — if XP drops below stage floor (with 3-day grace period)
- Random events — 30% daily chance, modifies state
- Unlock checker — evaluates cosmetic/achievement unlock conditions
- Saves state after every meaningful change

**PetState (the single source of truth):**
```swift
struct PetState: Codable {
  var daysAlive: Int
  var activeDays: Int          // days with qualifying activity
  var createdAt: Date
  var totalXP: Double
  var todayXP: Double          // resets midnight
  var todaySessionMins: Int    // for diminishing returns
  var lifetimeXP: Double       // never decays, for share card
  var stage: Stage             // egg, kobito, kani, kamisama
  var currentStreak: Int
  var longestStreak: Int
  var mood: Double             // 0-100
  var neglectState: NeglectState
  var equippedAccessories: [String]
  var unlockedItems: Set<String>
  var activeBackground: String
  var totalCommits: Int
  var totalLinesWritten: Int
  var biggestCommitLines: Int
  var lastActiveDate: Date
}
```

---

## Layer 4 — UI

The widget is a floating `NSPanel` — transparent background, no title bar, draggable, always on top, follows across all Spaces.

```swift
panel = NSPanel(
  contentRect: NSRect(x: 0, y: 200, width: 160, height: 180),
  styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
  backing: .buffered, defer: false
)
panel.level = .floating
panel.collectionBehavior = [.canJoinAllSpaces, .stationary]
panel.isMovableByWindowBackground = true
panel.backgroundColor = .clear
panel.isOpaque = false
```

**What the user sees:**
- Pixel art crab sprite (idle animation loop)
- Thin XP progress bar at the bottom
- Mood indicator dot (colour = mood state)
- Right-click menu: stats, settings, share card, quit
- Position is saved to UserDefaults and restored on relaunch

There's also a menubar icon (no dock icon — `LSUIElement = YES` in Info.plist) that shows a quick stats popover and settings.

---

## Game design — the key rules

### XP sources
| Action | XP |
|---|---|
| Claude Code active minute | +2 XP (capped at 120 min/day) |
| Small commit (1–25 lines) | +25 XP |
| Medium commit (26–100 lines) | +60 XP |
| Large commit (101–300 lines) | +150 XP |
| Huge commit (301–500 lines) | +350 XP |
| Legendary commit (500+ lines) | +500–800 XP |
| 50 lines written (saved) | +1 XP (passive, nearly negligible) |
| Bug fixed (error → clear) | +15 XP |
| New file created | +10 XP |
| Variety bonus (3+ file types) | +20 XP |
| First code of the day | +10 XP |

**Daily cap: 900 XP.** Diminishing returns kick in after 90 min of session time (60% rate), then 25% after 180 min.

**Streak multiplier:** 1.0x → 1.2x (3 days) → 1.5x (7 days) → 1.8x (14 days) → 2.0x (30+ days)

### Evolution stages
All gates require BOTH the XP threshold AND the minimum active days AND the streak at time of evolution. You cannot rush past day gates.

| Stage | XP needed | Active days | Streak required |
|---|---|---|---|
| Tamago (egg) | 0 | day 0 | — |
| Kobito (baby crab) | 500 XP | 5 days | 3-day streak |
| Kani (full crab) | 4000 XP | 21 days | 7-day streak |
| Kamisama (god crab) | 18000 XP | 60 days | 14-day streak |

### Decay and neglect
- Miss 1 day → -3% total XP, pet looks sad
- Miss 3 days → -8% XP/day, pet looks sick
- Miss 7+ days → -15% XP/day, can trigger de-evolution
- Miss 14 days → pet "runs away" (revival mechanic: code for 30 min to get it back, comes back one stage lower)

### Mood system
Mood (0–100) acts as an XP multiplier. Happy = 1.15x, Ecstatic = 1.3x, Stressed = 0.85x, Miserable = 0.6x. Mood is affected by commits, fixing bugs, breaking streaks, long inactivity.

---

## File persistence

Everything lives in `~/.kodomon/`:
```
~/.kodomon/
  state.json       # PetState — read on launch, written atomically after changes
  events.jsonl     # append-only hook event log
  stats.json       # lifetime stats that never reset
  hooks/           # the shell scripts
```

`StateStore` uses `.atomic` write option to prevent corruption. If state.json is missing or corrupt, `PetState.initial()` starts fresh.

---

## Build order

Build in phases — each phase produces something you can see and test:

1. **Skeleton** — NSPanel floats, menubar icon, no dock icon, app doesn't crash
2. **Hooks + watcher** — shell hooks installed, events.jsonl fills up, Swift reads and logs them
3. **Pet engine** — PetState persists, XP ticks up from real coding activity, streak tracks correctly
4. **Sprite + basic UI** — pixel crab renders, XP bar moves, first magic moment
5. **Animations + notifications** — idle loop, commit reaction, neglect notifications
6. **Evolution + unlockables** — stage gates, cutscene, de-evolution, accessories
7. **Polish + social** — share card PNG export, random events, Sparkle updates, ship v1.0

---

## Installation & distribution

Kodomon is not on the App Store. It distributes via a single curl command:

```bash
curl -fsSL https://kodomon.app/install.sh | bash
```

The install script lives at `scripts/install.sh` in the repo and is hosted at `kodomon.app/install.sh`. It does the following in order:

1. Check macOS 14+ (exit with friendly error if not)
2. Fetch the latest release version from GitHub Releases API
3. Download the `.dmg` from that release
4. Mount the `.dmg`, copy `Kodomon.app` to `/Applications`, unmount
5. Run `~/.kodomon/hooks/install-hooks.sh` to wire up Claude Code hooks
6. Set up global git hook via `git config --global core.hooksPath ~/.kodomon/git-hooks/`
7. Launch the app

**Expected output:**
```
Downloading Kodomon v1.0...        ✓
Installing to /Applications...     ✓
Installing Claude Code hooks...    ✓
Installing git hooks...            ✓

Your Kodomon is hatching... open Claude Code to feed it 🦀
```

**Distribution flow:**
- App is built in Xcode → exported as `.dmg`
- `.dmg` is uploaded to GitHub Releases (tagged, e.g. `v1.0.0`)
- Sparkle (`appcast.xml` in repo root) handles auto-updates for existing installs
- `install.sh` always pulls the latest release tag from the GitHub API

**No App Store, no sandboxing** — sandboxing would block file watching on `~/.kodomon/` and the hook installer. Distributed unsigned for v1, basic notarization added before wider release so Gatekeeper doesn't block it.

---

## What to reference

- **Lil Agents** (https://github.com/ryanstephen/lil-agents) — the closest existing app. Study how it builds the NSPanel, uses HEVC video with alpha for animations, and sets up the AppDelegate. 100% Swift, same macOS target.
- **Claude Code hooks docs** (https://code.claude.com/docs/en/hooks) — the SessionStart, PostToolUse, Stop hook events and their JSON payloads.
- **Sparkle** (https://sparkle-project.org) — add via Swift Package Manager for auto-updates.

---

## Design principles

- **Consistency beats intensity.** A daily coder beats a weekend grinder. Day gates cannot be bypassed.
- **Absence has real cost.** XP decays. Long gaps trigger de-evolution. The stakes are real.
- **100% local.** No telemetry, no accounts, no cloud sync. Open source and auditable.
- **Japanese aesthetic.** Evolution names in Japanese (Tamago, Kobito, Kani, Kamisama). Notifications in Japanese first. Pixel art inspired by Claude's crab mascot.
- **Lines of code are not the metric.** Claude Code writes thousands of lines per session — raw line count is nearly negligible as XP. Commits and session time are the real signals.
