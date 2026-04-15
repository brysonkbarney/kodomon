#!/usr/bin/env python3
"""
sprite_preview.py — standalone preview tool for Kodomon pixel sprites.

Renders sprites from the same [[P]] enum grid format used in SpriteData
(Kodomon/PixelSpriteView.swift), with the same hue-tinted palette, and
writes the result to an HTML file that auto-opens in your browser.

Usage:
    python3 scripts/sprite_preview.py [sprite_name] [hue]

Examples:
    python3 scripts/sprite_preview.py               # all drafts
    python3 scripts/sprite_preview.py kozuchi_kobito
    python3 scripts/sprite_preview.py kozuchi_kobito 0.57   # blue tint

Drafts are stored in the SPRITES dict below. Add or edit them to iterate;
no dependencies beyond the Python stdlib.
"""

import colorsys
import os
import subprocess
import sys

# Pixel codes — same semantics as the Swift `P` enum
# n = none (transparent)
# B = body
# D = dark outline
# E = eye (black)
# L = light highlight
# C = crack
# W = white (eye highlight)
n, B, D, E, L, C, W = 0, 1, 2, 3, 4, 5, 6


def palette(hue: float) -> dict[int, str]:
    """Map pixel codes to CSS rgba colors, matching P.color(hue:) in Swift."""
    def hsb(h, s, v) -> str:
        r, g, b = colorsys.hsv_to_rgb(h, s, v)
        return f"rgb({int(r*255)},{int(g*255)},{int(b*255)})"

    return {
        n: "transparent",
        B: hsb(hue, 0.50, 0.82),   # body
        D: hsb(hue, 0.55, 0.50),   # dark outline
        L: hsb(hue, 0.35, 0.92),   # light highlight
        C: hsb(hue, 0.55, 0.40),   # crack
        E: "rgb(20,20,20)",        # eye black
        W: "rgb(242,242,242)",     # eye highlight
    }


# ── Sprite drafts ─────────────────────────────────────────────────────────
# Each sprite is a 2D list (rows of columns) of pixel codes.

SPRITES: dict[str, list[list[int]]] = {

    # Reference: the existing Tamago Crab kobito sprite from PixelSpriteView.swift
    # Kept here as a visual reference so new species can be compared side by side.
    "tamago_crab_kobito": [
        [n,n,n,n,n,n,D,D,D,D,D,D,D,D,n,n,n,n,n,n],
        [n,n,n,n,D,D,B,B,B,B,B,B,B,B,D,D,n,n,n,n],
        [n,n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n,n],
        [n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n],
        [n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n],
        [n,D,B,B,B,E,E,E,B,B,B,B,E,E,E,B,B,B,D,n],
        [D,B,B,B,B,E,E,E,B,B,B,B,E,E,E,B,B,B,B,D],
        [D,B,B,B,B,E,W,E,B,B,B,B,E,W,E,B,B,B,B,D],
        [D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D],
        [n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n],
        [n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n],
        [n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n],
        [n,n,n,D,D,B,B,B,B,B,B,B,B,B,B,D,D,n,n,n],
        [n,n,n,n,n,D,D,D,D,D,D,D,D,D,D,n,n,n,n,n],
    ],

    # Draft #2: Kozuchi (committer) — Kobito stage. Full T-mallet silhouette.
    # Flat-topped rectangular mallet head, thin vertical handle, small flared
    # base. Clearly NOT a rounded blob — the silhouette reads as a tool first.
    "kozuchi_kobito": [
        [n,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,n],   # flat top of head
        [D,L,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,L,D],   # head w/ side highlights
        [D,L,B,B,E,E,E,B,B,B,B,B,B,E,E,E,B,B,L,D],   # eyes row 1
        [D,B,B,B,E,E,E,B,B,B,B,B,B,E,E,E,B,B,B,D],   # eyes row 2
        [D,B,B,B,E,W,E,B,B,B,B,B,B,E,W,E,B,B,B,D],   # eyes row 3 w/ highlight
        [D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D],   # head middle
        [n,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,n],   # flat bottom of head
        [n,n,n,n,n,n,n,n,D,B,B,D,n,n,n,n,n,n,n,n],   # thin handle
        [n,n,n,n,n,n,n,n,D,B,B,D,n,n,n,n,n,n,n,n],
        [n,n,n,n,n,n,n,n,D,B,B,D,n,n,n,n,n,n,n,n],
        [n,n,n,n,n,n,n,n,D,B,B,D,n,n,n,n,n,n,n,n],
        [n,n,n,n,n,n,n,D,B,B,B,B,D,n,n,n,n,n,n,n],   # base widens
        [n,n,n,n,n,n,D,B,B,B,B,B,B,D,n,n,n,n,n,n],   # base flares
        [n,n,n,n,n,n,D,D,D,D,D,D,D,D,n,n,n,n,n,n],   # base cap
    ],

    # Draft #5: Fukuron (night owl) — Kobito stage.
    # Snowman-with-wings silhouette: small head on top, narrow neck, body
    # flares out wider than the head forming wing-like side protrusions.
    # Eyes are 4 wide × 3 tall rounded rectangles with corners trimmed.
    "fukuron_kobito": [
        [n,n,n,n,n,n,D,n,n,n,n,n,n,D,n,n,n,n,n,n],   # ear tuft tips
        [n,n,n,n,n,D,B,D,n,n,n,n,D,B,D,n,n,n,n,n],   # ear tuft bases
        [n,n,n,n,D,B,B,D,D,D,D,D,D,B,B,D,n,n,n,n],   # tufts meet head
        [n,n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n,n],   # head top
        [n,n,D,B,n,E,E,n,B,B,n,E,E,n,B,B,D,n,n,n],   # eyes top (rounded)
        [n,n,D,B,E,W,W,E,B,B,E,W,W,E,B,B,D,n,n,n],   # eye highlights
        [n,n,D,B,n,E,E,n,D,D,n,E,E,n,B,B,D,n,n,n],   # eyes bottom + beak
        [n,n,n,D,B,B,B,B,B,B,B,B,B,B,B,D,n,n,n,n],   # head bottom
        [n,n,n,n,D,D,B,B,B,B,B,B,D,D,n,n,n,n,n,n],   # NARROW NECK
        [n,D,D,B,B,B,B,B,B,B,B,B,B,B,B,D,D,n,n,n],   # body starts
        [D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n],   # body widest (wings)
        [n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n,n],   # body
        [n,n,D,B,B,B,B,B,B,B,B,B,B,B,D,n,n,n,n,n],   # body taper
        [n,n,n,D,B,B,D,n,n,n,n,D,B,B,D,n,n,n,n,n],   # small feet
    ],

    # Draft #6: Tanuki (polyglot) — Kobito stage.
    # Round ears, wide head tapering to a narrower body (teardrop shape),
    # and a signature DARK MASK BAND across the eye area — iconic tanuki
    # bandit-face that no other Kodomon has. Silhouette: wide top, tapers
    # down to small feet.
    "tanuki_kobito": [
        [n,n,D,D,n,n,n,n,n,n,n,n,n,n,D,D,n,n,n,n],   # ear tips
        [n,D,B,B,D,n,n,n,n,n,n,n,n,D,B,B,D,n,n,n],   # ear bases
        [n,D,B,B,B,D,D,D,D,D,D,D,D,B,B,B,D,n,n,n],   # ears meet head
        [D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n],   # wide head
        [D,L,B,D,D,D,D,D,B,B,D,D,D,D,D,B,L,D,n,n],   # mask top
        [D,B,B,D,E,W,E,D,B,B,D,E,W,E,D,B,B,D,n,n],   # eyes in mask
        [D,B,B,D,D,D,D,D,B,B,D,D,D,D,D,B,B,D,n,n],   # mask bottom
        [D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n],   # body top
        [D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n],
        [n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n,n],   # taper
        [n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n,n],
        [n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n,n,n],
        [n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n,n,n],
        [n,n,n,D,B,B,D,n,n,n,n,D,B,B,D,n,n,n,n,n],   # small feet
    ],

    # Draft #7: Kirimaru (refactorer) — Kobito stage.
    # Angular DIAMOND silhouette (point at top, widest in the middle,
    # narrows to a flat base), with a single CYCLOPS eye dead center —
    # a refactorer sees everything. Different from every other species
    # which all have two eyes.
    "kirimaru_kobito": [
        [n,n,n,n,n,n,n,n,n,D,D,n,n,n,n,n,n,n,n,n],   # top point
        [n,n,n,n,n,n,n,n,D,B,B,D,n,n,n,n,n,n,n,n],
        [n,n,n,n,n,n,n,D,B,B,B,B,D,n,n,n,n,n,n,n],
        [n,n,n,n,n,n,D,B,B,B,B,B,B,D,n,n,n,n,n,n],
        [n,n,n,n,n,D,B,B,B,B,B,B,B,B,D,n,n,n,n,n],
        [n,n,n,n,D,B,B,B,B,B,B,B,B,B,B,D,n,n,n,n],
        [n,n,n,D,B,B,B,B,E,E,E,B,B,B,B,B,D,n,n,n],   # eye top
        [n,n,D,B,B,B,B,B,E,W,E,B,B,B,B,B,B,D,n,n],   # cyclops w/ highlight
        [n,D,B,B,B,B,B,B,E,E,E,B,B,B,B,B,B,B,D,n],   # eye bottom
        [D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D],   # widest
        [n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n],
        [n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n],
        [n,n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n,n],
        [n,n,n,n,D,D,D,D,D,D,D,D,D,D,D,D,n,n,n,n],   # flat base
    ],

    # Draft #11: Houou (legendary graduation) — Kobito stage.
    # Dragon head with LONG WHISKERS trailing down and out. Head lives in
    # the top 9 rows with eyes + beak. Below the head, the bottom 5 rows
    # are mostly empty space with two curving whiskers extending diagonally
    # from the jaw to the bottom corners of the grid. The whiskers are a
    # classic Japanese dragon feature, and the empty space between them
    # creates a silhouette no other species has — the creature physically
    # extends beyond where its "body" ends.
    "houou_kobito": [
        [n,n,n,n,n,D,D,D,D,D,D,D,D,D,D,n,n,n,n,n],   # head top
        [n,n,n,D,D,B,B,B,B,B,B,B,B,B,B,D,D,n,n,n],
        [n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n],
        [n,D,B,B,B,B,E,E,B,B,B,B,E,E,B,B,B,B,D,n],   # eyes
        [n,D,L,B,B,B,E,W,B,B,B,B,E,W,B,B,B,L,D,n],   # eye highlights
        [n,D,B,B,B,B,B,B,B,D,D,B,B,B,B,B,B,B,D,n],   # beak
        [n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n],
        [n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n],
        [n,n,n,D,D,D,D,D,D,D,D,D,D,D,D,D,D,n,n,n],   # head bottom
        [n,n,n,D,B,D,n,n,n,n,n,n,n,n,D,B,D,n,n,n],   # whiskers start hanging
        [n,n,D,B,B,D,n,n,n,n,n,n,n,n,D,B,B,D,n,n],   # whiskers curve outward
        [n,D,B,B,D,n,n,n,n,n,n,n,n,n,n,D,B,B,D,n],
        [D,B,B,D,n,n,n,n,n,n,n,n,n,n,n,n,D,B,B,D],   # whiskers reach corners
        [n,D,D,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,D,D],   # whisker tips fade out
    ],
}


# ── HTML rendering ────────────────────────────────────────────────────────

def render_html(sprites_to_show: list[tuple[str, list[list[int]]]], hue: float) -> str:
    """Return an HTML document rendering the given sprites."""
    pal = palette(hue)
    pixel_size = 20  # display px per pixel

    style = f"""
    body {{
      background: #2a2a2a;
      color: #f5f0e1;
      font-family: -apple-system, monospace;
      padding: 40px;
      margin: 0;
    }}
    h1 {{ color: #d83632; font-size: 18px; margin: 0 0 8px 0; }}
    .meta {{ color: #888; font-size: 11px; margin-bottom: 30px; }}
    .sprite-group {{ margin-bottom: 50px; }}
    .sprite-name {{
      font-size: 14px;
      color: #f5f0e1;
      margin-bottom: 12px;
      font-weight: bold;
    }}
    .sprite {{
      display: inline-grid;
      gap: 0;
      padding: 20px;
      background: #1a1a1a;
      border-radius: 8px;
      box-shadow: 0 4px 16px rgba(0,0,0,0.5);
    }}
    .pixel {{
      width: {pixel_size}px;
      height: {pixel_size}px;
      box-sizing: border-box;
    }}
    .dim {{
      display: inline-block;
      margin-top: 8px;
      font-size: 10px;
      color: #888;
    }}
    """

    def sprite_html(name: str, sprite: list[list[int]]) -> str:
        rows = len(sprite)
        cols = len(sprite[0]) if sprite else 0
        cells = []
        for row in sprite:
            for code in row:
                color = pal.get(code, "magenta")  # magenta = unknown code
                cells.append(f'<div class="pixel" style="background:{color}"></div>')
        grid_template = f"repeat({cols}, {pixel_size}px)"
        return f"""
        <div class="sprite-group">
          <div class="sprite-name">{name}</div>
          <div class="sprite" style="grid-template-columns:{grid_template}">
            {''.join(cells)}
          </div>
          <div class="dim">{cols}×{rows}</div>
        </div>
        """

    parts = "".join(sprite_html(n, s) for n, s in sprites_to_show)
    return f"""<!doctype html>
<html>
<head><meta charset="utf-8"><title>Kodomon sprite preview</title>
<style>{style}</style></head>
<body>
  <h1>Kodomon Sprite Preview</h1>
  <div class="meta">hue = {hue:.2f} — edit scripts/sprite_preview.py to add drafts</div>
  {parts}
</body>
</html>"""


def main() -> None:
    args = sys.argv[1:]
    sprite_name = args[0] if len(args) >= 1 else None
    hue = float(args[1]) if len(args) >= 2 else 0.07  # default peach

    if sprite_name:
        if sprite_name not in SPRITES:
            print(f"unknown sprite '{sprite_name}'. available:")
            for k in SPRITES:
                print(f"  {k}")
            sys.exit(1)
        sprites_to_show = [(sprite_name, SPRITES[sprite_name])]
    else:
        sprites_to_show = list(SPRITES.items())

    html = render_html(sprites_to_show, hue)
    out = "/tmp/kodomon_sprite_preview.html"
    with open(out, "w") as f:
        f.write(html)
    print(f"wrote {out}")
    subprocess.run(["open", out], check=False)


if __name__ == "__main__":
    main()
