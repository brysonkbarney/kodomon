# Kodomon (コードモン)

A macOS desktop widget — a Tamagotchi-style virtual pet that lives and grows from real Claude Code activity. Built in Swift, 100% local, open source MIT.

## Tech stack

- **Swift**, macOS 14+ (Sonoma), AppKit App Delegate lifecycle
- **SwiftUI** views hosted in `NSHostingView`
- **NSWindow** for the floating widget (not a dock window)
- **Combine** for reactive data flow
- **DispatchSource** for file watching (`~/.kodomon/events.jsonl`)
- **UserNotifications** for neglect alerts
- **Sparkle** (SPM) for auto-updates
- No CoreData, no SQLite — single JSON state file at `~/.kodomon/state.json`
- No server, no network
- LSUIElement = YES (no dock icon, menubar only)

## Architecture — 4 layers

1. **Hooks (shell scripts)** — installed into `~/.claude/settings.json`. Fire on SessionStart, PostToolUse (Write/Edit/Bash), and Stop. Write JSON lines to `~/.kodomon/events.jsonl`.
2. **Watcher (Swift)** — `DispatchSource` monitors the JSONL file. Parses new lines into typed `ActivityEvent` enums. Publishes via Combine `PassthroughSubject`.
3. **Engine (Swift)** — Pure `ObservableObject`, no UI deps. Consumes events, applies XP math (diminishing returns, streak multiplier, mood multiplier), decay, evolution checks, random events. Persists `PetState` to JSON.
4. **UI (SwiftUI)** — Floating widget + menubar icon. Renders pet sprite, XP bar, mood indicator.

## Project structure

```
Kodomon/
  KodomonApp.swift              # @main entry, @NSApplicationDelegateAdaptor
  AppDelegate.swift             # NSWindow setup, menubar item, lifecycle
  PetEngine.swift               # Core ObservableObject, all game logic
  PetState.swift                # Codable struct — single source of truth
  StateStore.swift              # Read/write ~/.kodomon/state.json
  ActivityWatcher.swift         # DispatchSource watcher for JSONL
  ActivityEvent.swift           # JSONL → typed ActivityEvent enum
  XPCalculator.swift            # XP rules, diminishing returns, caps
  RandomEventEngine.swift       # Random event system
  UnlockSystem.swift            # Accessory unlocks
  PetWidgetView.swift           # Main floating widget SwiftUI view
  PixelSpriteView.swift         # Pixel art sprite renderer
  PixelBackgroundView.swift     # Background themes
  AccessoryRenderer.swift       # Pixel art accessories
  MenuPanelView.swift           # Stats panel window
  ShareCardView.swift           # PNG export share card
  EvolutionCutsceneView.swift   # Evolution animation
  DeEvolutionView.swift         # De-evolution animation
  WelcomeView.swift             # First-launch name picker
  LoadingView.swift             # Loading transition
  NameGenerator.swift           # Random Japanese name generator
  NotificationManager.swift     # Neglect/streak/evolution alerts
  UpdateChecker.swift           # Sparkle auto-update wrapper
  Hooks/
    session-start.sh            # SessionStart hook
    session-stop.sh             # Stop hook
    file-event.sh               # PostToolUse (Write/Edit) hook
    bash-event.sh               # PostToolUse (Bash) — captures git commits
    install-hooks.sh            # Hook installer
scripts/
  install.sh                    # curl installer (downloads DMG + hooks)
  release.sh                    # DMG + appcast build helper
```

## Key design rules

- **Consistency beats intensity.** Day gates cannot be bypassed. Commits are the primary XP driver, not lines of code.
- **Lines of code are nearly negligible as XP** — Claude Code writes thousands of lines per session. Raw line count gives ~1 XP per 10 lines. Commits represent intentional decisions.
- **No daily XP cap.** Diminishing returns after 90 min (75% rate), 180 min (50%), then 35%. Heavy coders earn more — day gates prevent rushing.
- **Streak multiplier:** 1.0x → 1.2x (3d) → 1.5x (7d) → 1.8x (14d) → 2.0x (30+d). Breaks on zero-activity day.
- **Evolution stages:** Tamago (0 XP) → Kobito (1000 XP, 2 days, 2-day streak) → Kani (10000 XP, 5 days, 5-day streak) → Kamisama (30000 XP, 14 days, 10-day streak).
- **File write XP:** only unique files per day get +3 XP. Repeated edits to the same file give no XP (just +1 mood). This prevents Claude Code's rapid edits from inflating XP.
- **Session time XP:** +2 XP per active minute, capped at 120 min/day (240 XP max). Calculated from SessionStart/Stop hook timestamps.
- **Decay:** miss 1 day = -3% XP. 2-4 days = -8%. 5-6 days = -15%. 7+ days = pet runs away (revival mechanic: code 30 min to bring it back one stage lower).

## Data flow

```
Claude Code → shell hooks → ~/.kodomon/events.jsonl → ActivityWatcher → PetEngine → PetState → SwiftUI
```

## Release process

One command does everything:

```
./scripts/release.sh v1.0.9
```

This automatically:
1. Bumps version in `Info.plist` + `project.pbxproj` (all 4 values)
2. Builds Release binary
3. Creates DMG
4. Signs DMG with EdDSA key and generates `appcast.xml`
5. Copies appcast to `kodomon.app` repo
6. Commits + pushes both repos
7. Creates GitHub release with DMG

Version format: `v1.0.X` where X is the build number (must increment each release).

**Sparkle keys:** Private key is in macOS Keychain (export with `generate_keys -x`). Public key is in Info.plist (`SUPublicEDKey`). Appcast is hosted at `https://kodomon.app/appcast.xml`.

## Working in worktrees

This repo is often worked from Claude Code worktrees at `.claude/worktrees/*` (gitignored — don't `git add -f` them).

- **`release.sh` must run from the primary checkout** at `/Users/bryson/Documents/GitHub/kodomon` on `main`, never from a worktree. The script uses `git add -A` broadly.
- Before running `release.sh`, verify `git status` on main is clean except for expected version-bump files.
- After the release, inspect the release commit diff — it should only touch `Info.plist`, `project.pbxproj`, and `appcast.xml`. Anything else means `git add -A` grabbed something unexpected.

## Conventions

- All data stays local. No telemetry, no accounts, no cloud sync.
- Atomic writes for state.json to prevent corruption.
- Handle sleep/wake for timers (midnight reset, decay) — check elapsed time on wake, don't rely on timers firing through sleep.
- Buffer incomplete JSONL lines when reading from events file.
- Thread safety: serialize PetState mutations via @MainActor or explicit dispatch.
