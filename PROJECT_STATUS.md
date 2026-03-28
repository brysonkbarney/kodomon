# Kodomon — Project Status

## What's Built

### Phase 1 — App Skeleton (DONE)
- NSWindow with borderless, transparent background
- Menubar icon (tortoise)
- Dock icon
- Draggable window, position saved between launches
- No title bar, clean floating card

### Phase 2 — Hooks + Event Watcher (DONE)
- Shell hooks read JSON from stdin (session-start, file-event, session-stop, git-commit)
- Hooks installed into `~/.claude/settings.json`
- `ActivityWatcher` monitors `~/.kodomon/events.jsonl` via DispatchSource
- Parses JSONL into typed `ActivityEvent` enums
- Publishes via Combine

### Phase 3 — Pet Engine (DONE)
- `PetState` — single Codable struct, persisted to `~/.kodomon/state.json`
- `XPCalculator` — commit tiers, daily cap (900), diminishing returns, streak/mood multipliers
- `PetEngine` — consumes events, applies XP, manages streaks, decay, evolution checks
- Midnight timer with sleep/wake handling (checks missed midnights on wake)
- Decay system: -3% (1 day), -8% (3 days), -15% (7 days), ran away (14 days)
- Session time tracking (+2 XP/min, 120 min/day cap)
- File write XP: +3 per unique file/day (repeated edits = no XP)
- Random event engine: 30% daily chance, 4 stages of events
- Log rotation for events.jsonl
- Pet naming (prompted on first launch, rename from menubar)

### Phase 4 — Sprites + UI (DONE)
- Pixel art sprites at ~20px resolution: Tamago (egg), Kobito (blob), Kani (crab)
- Kamisama placeholder (uses Kani sprite)
- Random pet hue assigned at birth — eggs stay peach, hatched creatures get unique color
- Constrained to 6 good color ranges (red, orange, green, blue, purple, pink)
- Egg crack progression: 4 stages (50%, 65%, 80%, 90%) with horizontal crack lines
- Kobito animations: eyes look around (left/right/up), blink, hop with squish on landing
- Kani animation: side-to-side waddle
- Kamisama animation: slow float
- Tamago animation: still → occasional nudge → rocking → frantic shake (by XP progress)
- Widget card: pixel art background fills top, cream stats panel at bottom
- Red accent stripe separator
- Pet name in red (top left of stats), mood heart (top right)
- Stage name, segmented XP bar with current/target, streak + day count
- Drop shadow on sprite for contrast against backgrounds

### Phase 4.5 — Backgrounds (DONE)
- 4 pixel art backgrounds as PNG image assets: Tokyo Night, Sakura, Mount Fuji, Torii Gate
- Image asset loading system with fallback to code-drawn backgrounds
- Background switching via Debug menu
- Backgrounds fill edge-to-edge (no cream gap at top)

### Phase 5 — Evolution Cutscene (DONE, has a bug)
- Violent shake of old sprite → white flash → new sprite springs in → stage name + sparkles
- 4-second choreographed sequence
- Debug menu: Test Evolution button
- **BUG: cutscene content overflows the card bounds during animation — tried clipShape, masksToBounds, overlay, fixed frame, none worked. Needs investigation.**

### Dev Tools + Infrastructure (DONE)
- `.gitignore` for Swift/Xcode
- `.swiftlint.yml` + `.swiftformat` configs
- SwiftLint, SwiftFormat, xcbeautify installed
- `run.sh` — build and launch from terminal
- `CLAUDE.md` — project context for Claude Code
- `STYLE_GUIDE.md` — visual design reference
- `LICENSE` — MIT
- Debug menu: switch stages, set XP %, switch backgrounds, add XP, test evolution, reset state
- Memory files for cross-conversation context

## XP Balance (Current)

| Stage | XP Needed | Active Days | Streak Required |
|---|---|---|---|
| Tamago (egg) | 0 | 0 | — |
| Kobito (blob) | 3,000 | 5 | 3-day |
| Kani (crab) | 20,000 | 21 | 7-day |
| Kamisama (god) | 100,000 | 60 | 14-day |

Daily cap: 900 XP. Typical day (~2hr coding): 300-500 XP.

## Known Bugs
1. **Evolution cutscene overflows card** — the animation (sparkles, text, sprites) visually extends beyond the card's rounded rectangle during the cutscene. Multiple clipping approaches haven't fixed it.

## What's Left

### Must Have (v1.0)
- [ ] **Fix evolution cutscene overflow** — the card expands during cutscene
- [ ] **Kamisama sprite** — god crab design (currently placeholder, same as Kani)
- [ ] **Notifications** — macOS UserNotifications for hungry, streak warnings, evolution alerts (Japanese text first, English context)
- [ ] **Install script** — `curl -fsSL https://kodomon.app/install.sh | bash` for distribution
- [ ] **Kani animations** — currently only waddles, could do more (claw snaps, looking around)
- [ ] **App icon** — currently using default macOS app icon

### Nice to Have (v1.1+)
- [ ] Share card PNG export (Kodomon Wrapped) — SwiftUI ImageRenderer
- [ ] Settings panel — background picker, quiet hours, theme selection
- [ ] Sparkle auto-update integration
- [ ] More backgrounds (Terminal Green, Cyberpunk City, Tatami Room, Deep Sea)
- [ ] Accessories/unlockables system (hats, sunglasses, etc.)
- [ ] Achievement badges
- [ ] Leaderboard (opt-in, ranked by days alive)
- [ ] Revival mechanic (30 min coding to bring back ran-away pet)
- [ ] Sound toggle (optional chirp sounds)

## File Structure
```
kodomon/
  CLAUDE.md                    # Project context for Claude Code
  STYLE_GUIDE.md               # Visual design reference
  PROJECT_STATUS.md            # This file
  LICENSE                      # MIT
  .gitignore
  .swiftlint.yml
  .swiftformat
  run.sh                       # Build + launch script
  Kodomon GDD.tsx              # Game design document (React component)
  Kodomon Architecture.tsx     # Technical architecture doc (React component)
  Lila Agents Website.md       # Reference doc
  Kodomon.xcodeproj/           # Xcode project
  Kodomon/
    AppDelegate.swift           # Window setup, menubar, debug menu, sleep/wake
    KodomonApp.swift            # @main entry point
    ActivityEvent.swift         # Event type definitions
    ActivityWatcher.swift       # JSONL file watcher
    PetEngine.swift             # Core game logic
    PetState.swift              # State struct + Stage/NeglectState enums
    StateStore.swift            # JSON persistence
    XPCalculator.swift          # XP math
    RandomEventEngine.swift     # Daily random events
    PetWidgetView.swift         # Main card UI
    PixelSpriteView.swift       # Pixel art sprite renderer + animation
    PixelBackgroundView.swift   # Code-drawn background fallbacks
    EvolutionCutsceneView.swift # Evolution animation sequence
    Info.plist
    Assets.xcassets/
      tokyoNight.imageset/      # Background PNG
      sakura.imageset/          # Background PNG
      mountFuji.imageset/       # Background PNG
      toriiGate.imageset/       # Background PNG
    Hooks/
      session-start.sh
      file-event.sh
      session-stop.sh
      git-commit.sh
      install-hooks.sh
```

## Git History
- `f00e515` Initial commit
- `61ce391` Add working Kodomon app — Phases 1-3 complete
- `6df3246` Rebalance XP, fix hooks, add session tracking and random events
- `c3577de` Add pixel art sprites, redesigned widget card, pet naming
- `ef17e7c` Improve egg crack progression — 4 stages with natural horizontal cracks
- `d9d0976` Add pixel art backgrounds, random pet colors, sprite contrast
- `3d28979` Add Kobito eye animations, fix card layout, remove top gap
- `c09030c` Add evolution cutscene with flash, shake, and sparkle particles
