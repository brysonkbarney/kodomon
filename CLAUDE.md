# Kodomon (コードモン)

A macOS desktop widget — a Tamagotchi-style virtual pet crab that lives and grows from real Claude Code activity. Built in Swift, 100% local, open source MIT.

## Tech stack

- **Swift**, macOS 14+ (Sonoma), AppKit App Delegate lifecycle
- **SwiftUI** views hosted in `NSHostingView`
- **NSPanel** for the floating widget (not a dock window)
- **Combine** for reactive data flow
- **DispatchSource** for file watching (`~/.kodomon/events.jsonl`)
- **UserNotifications** for neglect alerts
- **Sparkle** (SPM) for auto-updates
- No CoreData, no SQLite — single JSON state file at `~/.kodomon/state.json`
- No server, no network (except optional opt-in leaderboard later)
- LSUIElement = YES (no dock icon, menubar only)

## Architecture — 4 layers

1. **Hooks (shell scripts)** — installed into `~/.claude/settings.json` and git hooks. Fire on SessionStart, PostToolUse (Write/Edit), Stop, and git post-commit. Write JSON lines to `~/.kodomon/events.jsonl`.
2. **Watcher (Swift)** — `DispatchSource` monitors the JSONL file. Parses new lines into typed `ActivityEvent` enums. Publishes via Combine `PassthroughSubject`.
3. **Engine (Swift)** — Pure `ObservableObject`, no UI deps. Consumes events, applies XP math (daily cap, diminishing returns, streak multiplier, mood multiplier), decay, evolution checks, random events. Persists `PetState` to JSON.
4. **UI (SwiftUI)** — `NSPanel` floating widget + menubar icon. Renders pet sprite, XP bar, mood indicator. Right-click context menu.

## Project structure

```
Kodomon/
  App/
    AppDelegate.swift         # NSPanel setup, menubar item, lifecycle
    KodomonApp.swift          # @main entry, @NSApplicationDelegateAdaptor
  Watcher/
    ActivityWatcher.swift     # DispatchSource watcher for JSONL
    GitWatcher.swift          # git event watching
    EventParser.swift         # JSONL → typed ActivityEvent
  Engine/
    PetEngine.swift           # Core ObservableObject, all game logic
    XPCalculator.swift        # XP rules, diminishing returns, caps
    DecayManager.swift        # Time-based decay, neglect states
    MoodEngine.swift          # Mood score, modifiers
    EventEngine.swift         # Random event system
    StreakTracker.swift        # Streak calculation, multipliers
  UI/
    PetWidgetView.swift       # Main floating NSPanel SwiftUI view
    PetSpriteView.swift       # Pixel art / animation renderer
    StatsView.swift           # XP bar, mood, streak display
    MenuBarView.swift         # Menubar icon + popover
    ShareCardView.swift       # Wrapped card, PNG export
    NotificationManager.swift
  Persistence/
    PetState.swift            # Codable struct — single source of truth
    StateStore.swift          # Read/write ~/.kodomon/state.json
  Hooks/                      # Shell scripts, not Swift
    install-hooks.sh
    kodomon-claude-event.sh
    kodomon-git-commit.sh
```

## Key design rules

- **Consistency beats intensity.** Day gates cannot be bypassed. Commits are the primary XP driver, not lines of code.
- **Lines of code are nearly negligible as XP** — Claude Code writes thousands of lines per session. Raw line count gives ~1 XP per 50 lines. Commits represent intentional decisions.
- **No daily XP cap.** Diminishing returns after 90 min (60% rate), then 25% after 180 min. Heavy coders earn more — day gates prevent rushing.
- **Streak multiplier:** 1.0x → 1.2x (3d) → 1.5x (7d) → 1.8x (14d) → 2.0x (30+d). Breaks on zero-activity day.
- **Evolution stages:** Tamago (0 XP) → Kobito (800 XP, 2 days, 2-day streak) → Kani (5000 XP, 10 days, 5-day streak) → Kamisama (15000 XP, 21 days, 10-day streak).
- **File write XP:** only unique files per day get +3 XP. Repeated edits to the same file give no XP (just +1 mood). This prevents Claude Code's rapid edits from inflating XP.
- **Session time XP:** +2 XP per active minute, capped at 120 min/day (240 XP max). Calculated from SessionStart/Stop hook timestamps.
- **Decay:** miss 1 day = -3% XP. 2-4 days = -8%. 5-6 days = -15%. 7+ days = pet runs away (revival mechanic: code 30 min to bring it back one stage lower).

## Data flow

```
Claude Code → shell hooks → ~/.kodomon/events.jsonl → ActivityWatcher → PetEngine → PetState → SwiftUI
```

## Build phases

1. Skeleton — NSPanel, menubar icon, no dock icon, doesn't crash
2. Hooks + watcher — shell scripts, JSONL filling, Swift reads events
3. Pet engine — PetState, XP math, streaks, decay
4. Sprite + basic UI — pixel crab, XP bar, mood dot
5. Animations + notifications
6. Evolution + unlockables
7. Polish + social (share card, random events, Sparkle, v1.0)

## Reference docs

- `Kodomon GDD.tsx` — full game design document (XP tables, evolution gates, decay rules, mood, events, unlockables, social features)
- `Kodomon Architecture.tsx` — detailed technical architecture with code skeletons
- `Lila Agents Website.md` — reference for similar app (Lil Agents)

## Conventions

- All data stays local. No telemetry, no accounts, no cloud sync.
- Atomic writes for state.json to prevent corruption.
- Handle sleep/wake for timers (midnight reset, decay) — check elapsed time on wake, don't rely on timers firing through sleep.
- Buffer incomplete JSONL lines when reading from events file.
- Thread safety: serialize PetState mutations via @MainActor or explicit dispatch.
