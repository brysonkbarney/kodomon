# Kodomon (コードモン)

A desktop Kodomon that grows when you code.

Kodomon is a macOS widget — a virtual companion powered by your real Claude Code activity. Earn XP from commits, file edits, and coding sessions. Keep a daily streak to evolve. Neglect it and it runs away.

100% local. No accounts. No telemetry. Open source. Optional global leaderboard.

## Install

```bash
curl -fsSL https://kodomon.app/install.sh | bash
```

Requires **macOS 14+** and [Claude Code](https://claude.ai/claude-code).

Or download the latest `.dmg` from [Releases](https://github.com/brysonkbarney/kodomon/releases).

## How it works

```
Code with Claude Code → hooks fire → Kodomon gains XP → evolve & unlock
```

**4 evolution stages:** Tamago (egg) → Kobito → Kani → Kamisama

Each stage is gated by XP + active days + a consecutive streak. Consistency beats grinding — you can't rush to max stage.

## Features

- **XP from real activity** — commits (tiered 25-800 XP by size), file edits, session time, lines written
- **Streak multiplier** — 1.0x → 2.0x at 30+ day streak
- **Mood system** — happy Kodomon = 1.3x XP, sad Kodomon = 0.6x
- **Diminishing returns** — XP rate drops after 90 / 180 / 270 min (no hard cap)
- **Random events** — Coding Storm (2x XP), Code Drought (0.5x), Good Vibes (+30 mood)
- **Decay & revival** — miss days → Kodomon gets sick → 7 days absent = runs away → code 30 min to revive
- **10 unlockable accessories** — pixel art hats, sunglasses, katana, boots
- **4 pixel art backgrounds** — Tokyo Night, Sakura, Mount Fuji, Torii Gate
- **Share card** — export a PNG of your Kodomon with stats
- **Floating widget** — stays on top across all desktops, draggable
- **Menubar icon** — stats, customization
- **Notifications** — streak warnings, evolution alerts, neglect reminders
- **Global leaderboard** — opt-in, see how your Kodomon compares at [kodomon.app/leaderboard](https://kodomon.app/leaderboard)
- **Auto-updates** — Sparkle checks for new versions in the background

## Privacy

All game data stays on your machine. Activity is tracked via Claude Code hooks writing to `~/.kodomon/events.jsonl`. State lives in `~/.kodomon/state.json`.

**Leaderboard (opt-in only):** If you choose to join the leaderboard, your pet name, XP, stage, streak, active days, and cosmetic loadout are synced once daily. No code, file paths, personal data, or machine info is ever sent. You can opt out anytime from the leaderboard panel.

**Auto-updates:** Sparkle checks `kodomon.app/appcast.xml` once every 24 hours for new versions. No telemetry is sent.

## Tech stack

Swift, SwiftUI, AppKit, macOS 14+. Single JSON state file. No database. No server (except opt-in leaderboard via Supabase Edge Functions).

## Contributing

[Issues](https://github.com/brysonkbarney/kodomon/issues) and PRs welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for setup instructions and [CLAUDE.md](CLAUDE.md) for architecture details.

## License

MIT
