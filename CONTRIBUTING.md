# Contributing to Kodomon

Thanks for wanting to help build Kodomon! Here's everything you need to know.

## How contributions work

Kodomon is open source, but you can't push directly to the main repo. Instead, you **fork** the repo, make changes in your fork, and open a **Pull Request (PR)** for review. The maintainer (Bryson) reviews and merges your PR.

This is the standard open source workflow — it keeps the main repo safe while letting anyone contribute.

## Getting started

### 1. Fork the repo

Go to [github.com/brysonkbarney/kodomon](https://github.com/brysonkbarney/kodomon) and click the **Fork** button (top right). This creates your own copy at `github.com/YOUR_USERNAME/kodomon`.

### 2. Clone your fork

```bash
git clone https://github.com/YOUR_USERNAME/kodomon.git
cd kodomon
```

### 3. Open in Xcode

```bash
open Kodomon.xcodeproj
```

Xcode will resolve the Sparkle SPM dependency automatically. Wait for it to finish (you'll see a loading indicator in the status bar).

### 4. Build and run

- Select **Kodomon** scheme and **My Mac** as the destination
- Press **Cmd+R** to build and run
- The debug build includes a **Debug** menu in the menubar dropdown with tools for testing (set XP, change stage, test evolution, etc.)

### 5. Install hooks (if you haven't already)

If you don't have Kodomon installed yet, run the install script to set up Claude Code hooks:

```bash
curl -fsSL https://kodomon.app/install.sh | bash
```

Or if you just want the hooks without installing the release build:

```bash
mkdir -p ~/.kodomon/hooks
cp Kodomon/Hooks/*.sh ~/.kodomon/hooks/
chmod +x ~/.kodomon/hooks/*.sh
touch ~/.kodomon/events.jsonl
```

Then add the hooks to `~/.claude/settings.json` manually (see the install script for the exact JSON structure).

## Making changes

### 1. Create a branch

```bash
git checkout -b my-feature
```

Name it something descriptive like `fix-streak-bug` or `add-new-accessory`.

### 2. Make your changes

Edit files, build, test. See the **Project structure** section below for where things live.

### 3. Test your changes

- Build and run in Debug mode (Cmd+R)
- Use the Debug menu to test different states (XP levels, stages, neglect states)
- Test evolution by setting XP/days/streak to just below thresholds, then triggering an event
- Test with a fresh state: delete `~/.kodomon/state.json` and relaunch
- Make sure existing state files still load (backward compatibility)

### 4. Commit and push

```bash
git add -A
git commit -m "Short description of what you changed"
git push origin my-feature
```

### 5. Open a Pull Request

Go to your fork on GitHub. You'll see a banner saying "my-feature had recent pushes." Click **Compare & pull request**.

Write a clear description:
- What you changed and why
- How to test it
- Any screenshots if it's a UI change

## Project structure

Everything is in `Kodomon/` (flat structure, no subdirectories except Hooks):

### Core engine
- `PetEngine.swift` — All game logic. Events, XP, streaks, decay, evolution, neglect.
- `PetState.swift` — The data model. Single source of truth, persisted to JSON.
- `XPCalculator.swift` — XP formulas, multipliers, diminishing returns.
- `StateStore.swift` — Reads/writes `~/.kodomon/state.json` (atomic writes).

### Event pipeline
- `ActivityWatcher.swift` — DispatchSource file watcher on `~/.kodomon/events.jsonl`.
- `ActivityEvent.swift` — JSONL parsing into typed Swift enums.
- `Hooks/*.sh` — Shell scripts that Claude Code runs on events. Write JSONL.

### UI
- `PetWidgetView.swift` — Main floating widget (the pet card).
- `PixelSpriteView.swift` — Pixel art sprite renderer (all 4 stages + animations).
- `PixelBackgroundView.swift` — Background themes.
- `AccessoryRenderer.swift` — Pixel art accessories (hats, shoes, etc.).
- `MenuPanelView.swift` — Stats panel, customize tab, info tab.
- `LeaderboardView.swift` — In-app leaderboard UI.
- `EvolutionCutsceneView.swift` — Evolution animation.
- `DeEvolutionView.swift` — De-evolution animation.
- `WelcomeView.swift` — First-launch name picker.
- `ShareCardView.swift` — PNG export share card.

### Systems
- `RandomEventEngine.swift` — Random daily events (coding storm, good vibes, etc.).
- `UnlockSystem.swift` — Accessory and background unlocks by XP threshold.
- `NotificationManager.swift` — macOS notifications for neglect, streaks, evolution.
- `LeaderboardService.swift` — Opt-in leaderboard sync to Supabase.
- `UpdateChecker.swift` — Sparkle auto-update wrapper.
- `NameGenerator.swift` — Random Japanese pet name generator.

### App lifecycle
- `KodomonApp.swift` — @main entry point.
- `AppDelegate.swift` — Window setup, menubar, sleep/wake, debug menu.

## Key concepts

### Data flow
```
Claude Code → shell hooks → ~/.kodomon/events.jsonl → ActivityWatcher → PetEngine → PetState → SwiftUI
```

### XP sources
- Git commits: +25-800 XP (tiered by size)
- Session time: +2 XP/min (capped 120 min/day)
- File writes: +3 XP per unique file/day
- Lines of code: +1 XP per 10 lines
- First activity of day: +10 XP
- Variety bonus: +20 XP for 3+ file types

### Evolution gates
| Stage | XP | Active Days | Streak |
|-------|-----|-------------|--------|
| Kobito | 1,000 | 2 | 2 |
| Kani | 10,000 | 5 | 5 |
| Kamisama | 30,000 | 14 | 10 |

### State persistence
- All state is in `~/.kodomon/state.json` (single JSON file, atomic writes)
- Every field in `PetState` uses `decodeIfPresent` with a default — old state files always load safely
- If you add a new field, always add it with `decodeIfPresent` and a sensible default in the decoder

## Rules for contributions

### Do
- Keep data 100% local (the only network calls are opt-in leaderboard and Sparkle updates)
- Add `decodeIfPresent` with defaults for any new PetState fields
- Test with a fresh install AND an existing state file
- Keep the pixel art style consistent
- Use the existing color system (`KodomonColors`)

### Don't
- Don't add telemetry, analytics, or tracking
- Don't add required network calls (everything must work offline)
- Don't break backward compatibility with existing state.json files
- Don't change the release process (only the maintainer ships releases)
- Don't commit secrets, keys, or credentials

## Ideas for contributions

Here are some things that would be great to add:

- **New accessories** — pixel art items (hats, glasses, weapons, pets)
- **New backgrounds** — themed pixel art backgrounds
- **New random events** — luckyCommit, flowState, bugInvasion, ancientBug (defined but not implemented)
- **Sound effects** — optional sounds for XP gains, evolution, notifications
- **Widget themes** — dark mode, different card styles
- **Codex CLI support** — hooks for OpenAI's Codex CLI (has a similar hooks system)
- **Better sprites** — animations, idle behaviors, mood-based expressions
- **Statistics page** — graphs of XP over time, coding patterns

## Questions?

Open an issue on GitHub or reach out to [@brysonbarney5](https://x.com/brysonbarney5) on Twitter.
