# Kodomon Style Guide

The visual identity of Kodomon is **Japanese 8-bit / Tamagotchi-inspired pixel art** — minimal, cute, chunky. The charm is in the simplicity. This document is the single reference for all UI and art decisions.

---

## Core Aesthetic

**One sentence:** A kawaii pixel crab that looks like it lives inside a Tamagotchi, themed with Japanese cultural motifs — torii gate red, cream washi paper.

**References:**
- Tamagotchi Connection (2004) — sprite resolution and simplicity
- Famicom/NES era pixel art — color discipline
- Japanese hanafuda cards — share card proportions and motif

---

## Sprite

### Resolution & Style
- **~16px wide**, minimal chunky pixel art
- **Front-facing** — the crab looks at you, eyes forward
- **Super minimal kawaii** — boxy body, dot eyes, thin mouth line, tiny claws poking up on top, stubby legs underneath
- Pixels should be clearly visible when rendered on screen
- No anti-aliasing, no gradients, no sub-pixel rendering

### Color
- **Body**: Warm peach/salmon/terracotta — `#C48A6A` range
- **Eyes**: Black — `#1A1A1A`
- **Mouth/detail**: Darker shade of body — `#A06B4A` range
- **Highlight** (optional): Lighter peach — `#D9A882` range
- **3-4 colors max per sprite**
- Crab color is **consistent across all evolution stages** — always the same peach/salmon

### Evolution Stage Differences
The sprite stays minimal at every stage. Stages are differentiated by **effects and accessories**, not detail:

| Stage | Sprite | What changes |
|---|---|---|
| Tamago (egg) | Simple egg shape, no limbs, faint pulse | Smallest, most minimal |
| Kobito (baby crab) | The reference crab — boxy body, dot eyes, tiny claws, stubby legs | First "alive" form |
| Kani (full crab) | Same minimal style, slightly wider stance | Unlocks accessories, background themes |
| Kamisama (god crab) | Same minimal style | Pixel particle aura (purple/gold orbiting squares), subtle float animation |

---

## Color Palette

### Theme — "Japanese Morning"
Warm, nostalgic, Japanese packaging / bento box energy.

| Role | Color | Hex |
|---|---|---|
| Background | Warm cream / washi paper | `#F5F0E1` |
| Primary accent | Vermillion / torii gate red | `#D83632` |
| Secondary accent | Deep red | `#E24B4A` |
| Text (primary) | Dark charcoal | `#2A2A2A` |
| Text (secondary) | Warm grey | `#6B6560` |
| Border / divider | Light warm grey | `#D6D0C4` |

### Accent Palette
Functional colors for streak badges, mood indicators, stage colors:

| Name | Hex | Usage |
|---|---|---|
| Purple | `#7F77DD` | Kamisama, streaks, primary brand |
| Teal | `#1D9E75` | Positive events, health, Kobito |
| Coral | `#D85A30` | Kani, warnings, fire/streak |
| Amber | `#BA7517` | Caution, medium alerts |
| Red | `#E24B4A` | Danger, decay, critical |
| Grey | `#5F5E5A` | Neutral, disabled, Tamago |

---

## Typography

### Font
- **Pixel font for everything** — English and Japanese
- **Bundled font**: k8x12 or Misaki Gothic (free, covers EN + JP kanji in pixel style)
- No system fonts — the entire app reads as a retro game UI

### Usage
| Context | Treatment |
|---|---|
| Stage names | Pixel font, kanji + romaji (e.g. `蟹 KANI`) |
| Stats / numbers | Pixel font, small size |
| Notifications (in-app) | Pixel font in speech bubble |
| Notifications (macOS) | System font (native notification, can't control) |
| Share card | Pixel font throughout |
| Menu items | Pixel font |

---

## Widget

### Frame
**TBD — experiment with both:**
- Option A: Tamagotchi egg shell frame (rounded border, visible "screen" area, decorative buttons)
- Option B: Borderless / transparent (sprite floats on desktop)
- May become a user preference / customizable setting

### HUD (below or around the pet)
Retro game style, all pixel-rendered:
- **XP bar**: Pixel-segmented progress bar (filled segments vs empty)
- **Mood**: Pixel heart icon, color-coded to mood state
- **Streak**: Pixel flame icon + day count in pixel numbers

### Context Menu (right-click)
- **Pixel art styled** — pixel border, pixel font, not native macOS menu
- Items: Stats, Settings, Share Card, Quit
- Cursor highlight = color fill on selected row

---

## Menubar Icon
- **Tiny ~16x16 pixel crab** matching the sprite style
- Subtle mood changes:
  - Happy: normal colors
  - Sad: greyed out
  - Ecstatic: tiny sparkle pixel

---

## Animation

### Frame Count
- **4-6 frames per state**
- Idle loop: 4 frames (~250ms each) — subtle bob or shift
- Commit reaction: 5-6 frames — anticipation, jump, peak, fall, land, settle
- Neglect poses: 2-3 frames per state — slow, listless

### Evolution Cutscene (~2-3 seconds)
1. Screen flash (white)
2. Old sprite dissolves — pixels scatter outward
3. New sprite assembles — pixels fly inward
4. Stage name + kanji appears: 「蟹 KANI」
5. Brief pixel sparkle burst
6. Return to normal idle

### Key Animation States
| State | Animation |
|---|---|
| Idle | 4-frame bob/shift loop |
| Commit received | Jump + land (5-6 frames) |
| Hungry | Slow blink, droopy eyes (2 frames) |
| Tired | Yawning loop (3 frames) |
| Sick | Shivering, X eyes (3 frames) |
| Critical | Barely twitching, flat (2 frames) |
| Ecstatic | Bouncing, pixel sparkles |
| Evolution | Full cutscene (see above) |

---

## Neglect States

Visual degradation through **desaturation + pose changes**:

| State | Trigger | Visual |
|---|---|---|
| Hungry | 2h no activity | Slight desaturation, droopy eyes, slow blink |
| Tired | 8h no activity | More grey, yawning pose, occasional sigh frame |
| Sick | 3 missed days | Very grey, shivering, X eyes, pixel sweat drops |
| Critical | 7+ missed days | Nearly greyscale, flat on ground, barely twitching |
| Ran away | 14 missed days | **Pet gone.** Empty widget. Tiny pixel farewell note: 「さようなら…」 XP bar and mood indicator removed. Just emptiness. |

---

## Accessories

- **Pixel overlays** layered on top of the sprite
- Same pixel art style and scale as the crab
- At ~16px, accessories are 2-4 pixels (a hat = 3-4 pixels on the head, sunglasses = 2 pixels over eyes)
- Must be readable at the chunky scale — silhouette matters more than detail

| Slot | Examples |
|---|---|
| Head | Tiny headband, sakura crown, pixel crown |
| Face | Pixel sunglasses (2px wide) |
| Body | Dev hoodie (recolors body), Anthropic pin (1-2px) |
| Claws | Golden claws (recolor claw pixels) |
| Held | Katana (line of pixels beside body), ramen bowl |

---

## Backgrounds

**Pixel art scenes** matching the sprite's pixel grid and aesthetic:

| Theme | Visual | Unlock |
|---|---|---|
| Tokyo night | Pixel cityscape, neon signs, stars, pixel moon | Default |
| Sakura season | Pixel cherry blossom tree, falling petal pixels | Kani + spring |
| Deep sea | Pixel ocean floor, bubble pixels, bioluminescent glow | Kamisama |
| Terminal green | Green-on-black pixel terminal/matrix look | 50 consecutive days |
| Cyberpunk city | Dense pixel neon cityscape | 100-day streak |
| Tatami room | Pixel tatami mat pattern, sliding door | 30 days at Kani+ |

All backgrounds are static (no animation). Animation may be added later as enhancement.

---

## Particle Effects

- **Chunky pixel particles only** — square sparkles, pixel stars, blocky bursts
- No smooth glow, no bloom, no soft effects
- All particles are hard-edged pixel squares

| Effect | Description |
|---|---|
| Commit celebration | Square pixel burst outward from crab, 4-6 particles |
| Evolution sparkle | Pixel stars scatter outward, then inward |
| Kamisama aura | Orbiting pixel squares in purple (`#7F77DD`) and gold (`#BA7517`) |
| XP gain | Tiny pixel numbers float upward (+25 XP) |
| Streak fire | 2-3 pixel flame particles near streak icon |

---

## Events & Notifications

### In-app (on widget)
- **Pixel speech bubble** pops up from the crab
- Pixel border, pixel font text inside
- Japanese text for event names (e.g. 「コーディングストーム!」)
- Auto-dismisses after ~4 seconds

### System notifications (macOS native)
- Used for serious alerts only: neglect, streak about to break, evolution ready
- Pet sprite as notification icon
- Japanese text first, English context below (e.g. 「お腹すいた…」 Kodomon is getting hungry.)

---

## Share Card — "Kodomon Wrapped"

### Style
- **Japanese postcard / hanafuda card** proportions
- Cream background (`#F5F0E1`) + vermillion red accents (`#D83632`)
- All text in pixel font

### Layout
| Element | Detail |
|---|---|
| Header | 「コードモン」 KODOMON in pixel font |
| Pet sprite | Current stage, full size, with equipped accessories |
| Stage name | Kanji + romaji (e.g. 蟹 KANI) |
| Days alive | e.g. 84日目 |
| Total XP | Lifetime accumulated |
| Longest streak | e.g. 23日連続 |
| Biggest commit | e.g. 847行 |
| Date | Subtle, e.g. 2026年3月 |
| Branding | Small kodomon.app in pixel font |

### Variants
- **Portrait** (mobile share / Instagram story)
- **Landscape** (Twitter/X card)
- Both generated as PNG via SwiftUI `ImageRenderer`

---

## Achievement Badges

- **16x16 pixel art icons** matching the overall sprite aesthetic
- Displayed as a collectable grid in the stats panel

| Badge | Pixel icon concept |
|---|---|
| First Hatch | Pixel egg cracking |
| Marathoner | Pixel clock / hourglass |
| Survivor | Pixel heart with crack |
| Legendary | Pixel crown |
| Night Owl | Pixel moon + stars |
| 10k Club | Pixel code brackets |

---

## Sound

**No sound.** Kodomon is a silent desktop companion. All feedback is purely visual.

---

## Summary of Key Principles

1. **Simplicity is the brand.** The crab is ~16px of chunky kawaii. Don't add detail — add effects.
2. **Japanese cultural identity.** Torii red, cream washi, kanji, hanafuda cards. Not generic retro — specifically Japanese retro.
3. **Warm Japanese palette.** Cream washi paper, torii gate red, warm tones throughout.
4. **Pixel discipline.** Everything on the pixel grid. No anti-aliasing, no gradients, no smooth edges. If it's in the app, it's pixel art.
5. **Emotion through constraint.** 3-4 colors, ~16px, 4-6 frames. The limitations create the charm.
