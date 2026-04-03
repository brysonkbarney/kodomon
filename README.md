# Kodomon (コードモン)

A macOS desktop widget — a Tamagotchi-style virtual pet crab that lives and grows from your real Claude Code activity. 100% local, open source, no accounts.

## How it works

Code with Claude Code. Your pet gains XP from commits, file edits, and session time. Keep a daily streak to level up. Neglect it and it gets sad. Abandon it and it runs away.

**4 evolution stages:** Tamago (egg) -> Kobito -> Kani (crab) -> Kamisama (god)

Each stage requires XP + active days + a streak to unlock. Consistency beats grinding.

## Install

```bash
curl -fsSL https://kodomon.app/install.sh | bash
```

Requires macOS 14+ and [Claude Code](https://claude.ai/claude-code).

The installer downloads the app, installs Claude Code hooks, and launches Kodomon. Your pet appears as a floating widget on your desktop.

## Features

- **XP from real activity** — commits (tiered by size), file edits, session time, lines written
- **Streak multiplier** — 1.0x to 2.0x at 30+ day streak
- **Mood system** — happy pet = 1.3x XP, sad pet = 0.6x
- **Diminishing returns** — no daily cap, but XP rate drops after 90/180/270 min
- **Random events** — Coding Storm (2x XP), Code Drought (0.5x), Good Vibes (+30 mood)
- **Decay** — miss days and your pet gets sad, sick, then runs away (revivable)
- **Unlockable accessories** — 10 pixel art items (hats, sunglasses, katana, boots)
- **4 pixel art backgrounds** — Tokyo Night, Sakura, Mount Fuji, Torii Gate
- **Share card** — export a PNG of your pet with stats
- **Floating widget** — stays on top across all spaces, draggable
- **Menubar icon** — quick access to stats, customization, rename
- **Notifications** — streak warnings, evolution alerts, neglect reminders

## Privacy

All data stays on your machine. No accounts, no telemetry, no network requests. Activity is tracked via Claude Code hooks writing to `~/.kodomon/events.jsonl`. Pet state lives in `~/.kodomon/state.json`.

## Tech stack

Swift, SwiftUI, AppKit, macOS 14+. No database — single JSON state file. No server. See [CLAUDE.md](CLAUDE.md) for architecture details.

## License

MIT
