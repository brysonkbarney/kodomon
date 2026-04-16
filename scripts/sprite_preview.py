#!/usr/bin/env python3
"""
sprite_preview.py — standalone preview tool for Kodomon pixel sprites.

Renders sprites from the same [[P]] enum grid format used in SpriteData
(Kodomon/PixelSpriteView.swift), with the same hue-tinted palette, and
writes the result to an HTML file that auto-opens in your browser.
Sprites are laid out side by side in a flex grid so evolution stages or
species comparisons can sit next to each other.

Usage:
    python3 scripts/sprite_preview.py [sprite_name ...] [--hue H]

Examples:
    python3 scripts/sprite_preview.py                              # all drafts
    python3 scripts/sprite_preview.py kozuchi_kobito                # one sprite
    python3 scripts/sprite_preview.py kozuchi_kobito kozuchi_kani   # side by side
    python3 scripts/sprite_preview.py fukuron_kobito --hue 0.57     # blue tint

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


# ── Animation frame generators ────────────────────────────────────────────
# Mechanical eye variants (blink, look left/right) are generated from the
# base sprite + eye metadata. Only unique action frames need manual art.

def _deep_copy(sprite: list[list[int]]) -> list[list[int]]:
    return [row[:] for row in sprite]

def gen_look_left(base: list[list[int]], w_positions: list[tuple[int, int]]) -> list[list[int]]:
    """Shift every W highlight 1 pixel left. Only shifts onto E pixels.
    Processes left-to-right so adjacent W pairs shift correctly."""
    s = _deep_copy(base)
    for r, c in sorted(w_positions, key=lambda p: p[1]):
        if c > 0 and s[r][c] == W and s[r][c - 1] == E:
            s[r][c] = E
            s[r][c - 1] = W
    return s

def gen_look_right(base: list[list[int]], w_positions: list[tuple[int, int]]) -> list[list[int]]:
    """Shift every W highlight 1 pixel right. Only shifts onto E pixels.
    Processes right-to-left so adjacent W pairs shift correctly."""
    s = _deep_copy(base)
    for r, c in sorted(w_positions, key=lambda p: -p[1]):
        if c < len(s[r]) - 1 and s[r][c] == W and s[r][c + 1] == E:
            s[r][c] = E
            s[r][c + 1] = W
    return s

def gen_blink(base: list[list[int]], eye_rows: list[int], blink_row: int) -> list[list[int]]:
    """Close eyes: clear upper eye rows to body, leave blink_row as E-only line."""
    s = _deep_copy(base)
    for r in eye_rows:
        if r == blink_row:
            # Replace W with E on the blink row (thin closed-eye line)
            for c in range(len(s[r])):
                if s[r][c] == W:
                    s[r][c] = E
        else:
            # Clear non-blink eye rows: E and W become B
            for c in range(len(s[r])):
                if s[r][c] in (E, W):
                    s[r][c] = B
    return s

# Eye metadata per species/stage: (w_positions, eye_rows, blink_row)
# w_positions = list of (row, col) where W highlights sit in the base sprite
# eye_rows = all rows that contain eye pixels (E or W)
# blink_row = which row keeps E pixels when blinking (the "closed eye" line)
EYE_META: dict[str, tuple[list[tuple[int, int]], list[int], int]] = {}

def _register_eyes(name: str, w_pos: list[tuple[int, int]], eye_rows: list[int], blink_row: int):
    EYE_META[name] = (w_pos, eye_rows, blink_row)

# Species whose eyes are too small or embedded in masks for look-direction
# to look good. They get blink only, no left/right.
NO_LOOK = {"tanuki_kobito", "tanuki_kani", "fukuron_kobito", "fukuron_kani"}

def generate_anim_frames(sprites: dict[str, list[list[int]]]):
    """Auto-generate _left, _right, _blink variants for all registered sprites."""
    for name, (w_pos, eye_rows, blink_row) in EYE_META.items():
        if name not in sprites:
            continue
        base = sprites[name]
        sprites[f"{name}_blink"] = gen_blink(base, eye_rows, blink_row)
        if name not in NO_LOOK:
            sprites[f"{name}_left"] = gen_look_left(base, w_pos)
            sprites[f"{name}_right"] = gen_look_right(base, w_pos)


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

    # Kozuchi — Kamisama stage (33×20). The legendary deity form adds
    # TWO new features beyond Kani: a 3-point CROWN on top of the mallet
    # head, and FOUR arms total (upper pair at grid edges cols 0-2 and
    # 30-32, lower pair at inner cols 10-12 and 20-22) like a multi-
    # armed buddhist deity wielding a ceremonial mallet. Handle widened
    # to 5-wide (D,B,B,B,D at cols 14-18) so it sits perfectly centered
    # on the odd 33-col grid. Head is now 29 cols wide × 8 rows tall
    # with L highlights on the upper edges.
    "kozuchi_kamisama": [
        [n,n,n,n,n,n,n,n,n,n,D,n,n,n,n,n,D,n,n,n,n,n,D,n,n,n,n,n,n,n,n,n,n],   # crown tips (3)
        [n,n,n,n,n,n,n,n,n,D,B,D,n,n,n,D,B,D,n,n,n,D,B,D,n,n,n,n,n,n,n,n,n],   # crown bodies
        [n,n,D,D,D,D,D,D,D,D,B,D,D,D,D,D,B,D,D,D,D,D,B,D,D,D,D,D,D,D,D,n,n],   # crowns merge w/ head top
        [n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n],   # head top
        [n,n,D,L,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,L,D,n,n],   # head w/ highlights
        [n,n,D,B,B,B,B,B,B,E,E,E,B,B,B,B,B,B,B,B,B,E,E,E,B,B,B,B,B,B,D,n,n],   # eyes top
        [n,n,D,B,B,B,B,B,B,E,W,E,B,B,B,B,B,B,B,B,B,E,W,E,B,B,B,B,B,B,D,n,n],   # eye highlights
        [n,n,D,B,B,B,B,B,B,E,E,E,B,B,B,B,B,B,B,B,B,E,E,E,B,B,B,B,B,B,D,n,n],   # eyes bottom
        [n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n],   # head below eyes
        [n,n,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,n,n],   # head bottom (flat)
        [D,D,D,n,n,n,n,n,n,n,n,n,n,n,D,B,B,B,D,n,n,n,n,n,n,n,n,n,n,n,D,D,D],   # upper arms top + handle
        [D,B,D,n,n,n,n,n,n,n,n,n,n,n,D,B,B,B,D,n,n,n,n,n,n,n,n,n,n,n,D,B,D],   # upper arms + handle
        [D,D,D,n,n,n,n,n,n,n,n,n,n,n,D,B,B,B,D,n,n,n,n,n,n,n,n,n,n,n,D,D,D],   # upper arms bot + handle
        [n,n,n,n,n,n,n,n,n,n,n,n,n,n,D,B,B,B,D,n,n,n,n,n,n,n,n,n,n,n,n,n,n],   # handle spacer
        [n,n,n,n,n,n,n,n,n,n,D,D,D,n,D,B,B,B,D,n,D,D,D,n,n,n,n,n,n,n,n,n,n],   # lower arms top + handle
        [n,n,n,n,n,n,n,n,n,n,D,B,D,n,D,B,B,B,D,n,D,B,D,n,n,n,n,n,n,n,n,n,n],   # lower arms + handle
        [n,n,n,n,n,n,n,n,n,n,D,D,D,n,D,B,B,B,D,n,D,D,D,n,n,n,n,n,n,n,n,n,n],   # lower arms bot + handle
        [n,n,n,n,n,n,n,n,n,n,n,n,D,B,B,B,B,B,B,B,D,n,n,n,n,n,n,n,n,n,n,n,n],   # base widens
        [n,n,n,n,n,n,n,n,n,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,n,n,n,n,n,n,n,n,n],   # base plate
        [n,n,n,n,n,n,n,n,n,D,B,B,D,n,n,n,n,n,n,n,D,B,B,D,n,n,n,n,n,n,n,n,n],   # feet
    ],

    # Kozuchi — Kani stage. Scaled-up T-mallet (24×20) with two small
    # hammer-fist arms sticking out from the handle, plus a bigger base
    # with two feet. Everything is now symmetric around col 11.5 — the
    # head is 20 cols wide (even so it centers cleanly), arms sit at the
    # outermost cols 0-2 and 21-23, handle is 4 cols wide at cols 10-13,
    # base trapezoid widens symmetrically, feet are mirrored around center.
    "kozuchi_kani": [
        [n,n,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,n,n],   # flat top (20-wide head)
        [n,n,D,L,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,L,D,n,n],   # head + side highlights
        [n,n,D,L,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,L,D,n,n],
        [n,n,D,L,B,B,B,E,E,E,B,B,B,B,E,E,E,B,B,B,L,D,n,n],   # eyes row 1
        [n,n,D,B,B,B,B,E,E,E,B,B,B,B,E,E,E,B,B,B,B,D,n,n],   # eyes row 2
        [n,n,D,B,B,B,B,E,W,E,B,B,B,B,E,W,E,B,B,B,B,D,n,n],   # eyes row 3 w/ highlights
        [n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n],
        [n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n],
        [n,n,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,n,n],   # head bottom
        [D,D,D,n,n,n,n,n,n,n,D,B,B,D,n,n,n,n,n,n,n,D,D,D],   # arm tops + handle top
        [D,B,D,n,n,n,n,n,n,n,D,B,B,D,n,n,n,n,n,n,n,D,B,D],   # arm fists + handle
        [D,B,D,n,n,n,n,n,n,n,D,B,B,D,n,n,n,n,n,n,n,D,B,D],
        [D,D,D,n,n,n,n,n,n,n,D,B,B,D,n,n,n,n,n,n,n,D,D,D],   # arm bottoms
        [n,n,n,n,n,n,n,n,n,n,D,B,B,D,n,n,n,n,n,n,n,n,n,n],   # handle continues
        [n,n,n,n,n,n,n,n,n,D,B,B,B,B,D,n,n,n,n,n,n,n,n,n],   # base widens (6)
        [n,n,n,n,n,n,n,n,D,B,B,B,B,B,B,D,n,n,n,n,n,n,n,n],   # base widens (8)
        [n,n,n,n,n,n,n,D,B,B,B,B,B,B,B,B,D,n,n,n,n,n,n,n],   # base widens (10)
        [n,n,n,n,n,n,D,D,D,D,D,D,D,D,D,D,D,D,n,n,n,n,n,n],   # base plate (12 wide)
        [n,n,n,n,n,n,D,B,B,D,n,n,n,n,D,B,B,D,n,n,n,n,n,n],   # feet
        [n,n,n,n,n,n,D,D,D,D,n,n,n,n,D,D,D,D,n,n,n,n,n,n],   # feet bottom
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

    # Fukuron — Kamisama stage (33×20). Night-owl deity form. Kani
    # evolved to add floating wings; Kamisama now adds a 5-POINT
    # FEATHERED CROWN on top (instead of just 2 ear tufts), a wider
    # 3-wide beak, and larger 4×3 rounded eyes with double W highlights.
    # Wings stay as floating D,B,D tubes at cols 0-2 and 30-32 with
    # visible gaps separating them from the body — the pattern that
    # worked for Kani. Talons at the bottom are 4-wide each, matching
    # Kozuchi Kamisama's foot style.
    "fukuron_kamisama": [
        [n,n,n,n,D,n,n,n,n,n,D,n,n,n,n,n,D,n,n,n,n,n,D,n,n,n,n,n,D,n,n,n,n],   # 5 crest tips
        [n,n,n,D,B,D,n,n,n,D,B,D,n,n,n,D,B,D,n,n,n,D,B,D,n,n,n,D,B,D,n,n,n],   # crest bodies
        [n,n,D,D,B,D,D,D,D,D,B,D,D,D,D,D,B,D,D,D,D,D,B,D,D,D,D,D,B,D,D,n,n],   # crest merges w/ head
        [n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n],   # head top
        [n,n,D,L,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,L,D,n,n],   # head w/ highlights
        [n,n,D,B,B,B,B,B,B,n,E,E,n,B,B,B,B,B,B,B,n,E,E,n,B,B,B,B,B,B,D,n,n],   # eyes top (rounded)
        [n,n,D,B,B,B,B,B,B,E,W,W,E,B,B,B,B,B,B,B,E,W,W,E,B,B,B,B,B,B,D,n,n],   # eye highlights
        [n,n,D,B,B,B,B,B,B,n,E,E,n,B,B,D,D,D,B,B,n,E,E,n,B,B,B,B,B,B,D,n,n],   # eyes bot + 3-wide beak
        [n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n],   # head below
        [n,n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n,n],   # head bottom taper
        [n,n,n,n,n,n,n,D,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,D,n,n,n,n,n,n,n],   # NARROW NECK
        [n,n,n,n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n,n,n,n],   # body starts
        [D,D,D,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,D,D,D],   # wings + body
        [D,B,D,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,D,B,D],   # wings continue
        [D,B,D,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,D,B,D],
        [D,D,D,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,D,D,D],   # wings end
        [n,n,n,n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n,n,n,n],   # body narrows
        [n,n,n,n,n,n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n,n,n,n,n,n],   # body narrow
        [n,n,n,n,n,n,n,n,n,n,D,B,B,D,n,n,n,n,n,D,B,B,D,n,n,n,n,n,n,n,n,n,n],   # talons
        [n,n,n,n,n,n,n,n,n,n,D,D,D,D,n,n,n,n,n,D,D,D,D,n,n,n,n,n,n,n,n,n,n],   # talons bottom
    ],

    # Fukuron — Kani stage. The evolution adds a NEW feature that Kobito
    # doesn't have: detached floating wings on the sides (3-wide D,B,D
    # tubes at cols 0-2 and 21-23) clearly separated from the body by
    # visible empty gaps at cols 3 and 20 — same "floating appendage"
    # pattern Kozuchi Kani uses for its hammer-fist arms. Rest of the
    # creature (tufts, head, eyes, neck, body, feet) stays proportional
    # to Kobito so the evolution feels additive, not just "bigger".
    "fukuron_kani": [
        [n,n,n,n,n,n,n,D,n,n,n,n,n,n,n,n,D,n,n,n,n,n,n,n],   # ear tuft tips
        [n,n,n,n,n,n,D,B,D,n,n,n,n,n,n,D,B,D,n,n,n,n,n,n],   # tuft tubes
        [n,n,n,n,n,D,B,B,B,D,n,n,n,n,D,B,B,B,D,n,n,n,n,n],   # tufts widen
        [n,n,D,D,D,D,B,B,B,D,D,D,D,D,D,B,B,B,D,D,D,D,n,n],   # tufts merge w/ head
        [n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n],   # head top
        [n,n,D,B,B,n,E,E,n,B,B,B,B,B,B,n,E,E,n,B,B,D,n,n],   # eye top (rounded)
        [n,n,D,B,B,E,W,W,E,B,B,B,B,B,B,E,W,W,E,B,B,D,n,n],   # eye middle w/ highlights
        [n,n,D,B,B,n,E,E,n,B,B,D,D,B,B,n,E,E,n,B,B,D,n,n],   # eye bottom + beak
        [n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n],   # head below eyes
        [n,n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n,n],   # head bottom taper
        [n,n,n,n,n,D,D,B,B,B,B,B,B,B,B,B,B,D,D,n,n,n,n,n],   # NARROW NECK
        [n,n,n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n,n,n],   # body starts
        [D,D,D,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,D,D,D],   # wing tops + body
        [D,B,D,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,D,B,D],   # wing tubes (floating)
        [D,B,D,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,D,B,D],
        [D,D,D,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,D,D,D],   # wing bottoms
        [n,n,n,n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n,n,n,n],   # body taper
        [n,n,n,n,n,n,D,B,B,B,B,B,B,B,B,B,B,D,n,n,n,n,n,n],   # body narrow
        [n,n,n,n,n,n,D,B,B,D,n,n,n,n,D,B,B,D,n,n,n,n,n,n],   # feet
        [n,n,n,n,n,n,D,D,D,D,n,n,n,n,D,D,D,D,n,n,n,n,n,n],   # feet bottom
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

    # Tanuki — Kamisama stage (33×20). Deity form. Evolves Kani's
    # lighter-belly idea into a two-feature Kamisama: a FOREHEAD GEM
    # (3-wide D,W,D pattern centered at col 16 between ears and mask)
    # for a divine bindi mark, and a BIGGER LAYERED BELLY — the L
    # oval is now 11 wide at its smallest and widens to 15 L's at
    # the center row for a glowing multi-layer "inner light" effect.
    # Mask is widened to 7 cells (2 D's on each side of each eye,
    # up from 1 at Kani) for a heavier bandit look.
    "tanuki_kamisama": [
        [n,n,n,n,n,n,D,D,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,D,D,n,n,n,n,n,n],   # ear tips
        [n,n,n,n,n,D,B,B,D,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,D,B,B,D,n,n,n,n,n],   # ears 4-wide
        [n,n,n,n,D,B,B,B,B,D,n,n,n,n,n,n,n,n,n,n,n,n,n,D,B,B,B,B,D,n,n,n,n],   # ears 6-wide
        [n,n,n,D,B,B,B,B,B,B,D,n,n,n,n,n,n,n,n,n,n,n,D,B,B,B,B,B,B,D,n,n,n],   # ears 8-wide
        [n,n,D,D,B,B,B,B,B,B,D,D,D,D,D,D,D,D,D,D,D,D,D,B,B,B,B,B,B,D,D,n,n],   # ears merge w/ head
        [n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,D,W,D,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n],   # head w/ FOREHEAD GEM
        [n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n],   # head clean
        [n,n,D,L,B,B,B,B,D,D,D,D,D,D,D,B,B,B,D,D,D,D,D,D,D,B,B,B,B,L,D,n,n],   # mask top (7-wide)
        [n,n,D,B,B,B,B,B,D,D,E,W,E,D,D,B,B,B,D,D,E,W,E,D,D,B,B,B,B,B,D,n,n],   # eyes in mask
        [n,n,D,B,B,B,B,B,D,D,D,D,D,D,D,B,B,B,D,D,D,D,D,D,D,B,B,B,B,B,D,n,n],   # mask bottom
        [n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n],   # head below mask
        [n,n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n,n],   # head bottom taper
        [n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n],   # body widens
        [D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D],   # body full width
        [D,B,B,B,B,B,B,B,B,B,B,L,L,L,L,L,L,L,L,L,L,L,B,B,B,B,B,B,B,B,B,B,D],   # belly starts (11 wide)
        [D,B,B,B,B,B,B,B,B,L,L,L,L,L,L,L,L,L,L,L,L,L,L,L,L,B,B,B,B,B,B,B,D],   # belly widest (15)
        [D,B,B,B,B,B,B,B,B,B,B,L,L,L,L,L,L,L,L,L,L,L,B,B,B,B,B,B,B,B,B,B,D],   # belly narrows back
        [n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n],   # body narrows
        [n,n,n,n,n,n,n,n,n,D,B,B,D,n,n,n,n,n,n,n,D,B,B,D,n,n,n,n,n,n,n,n,n],   # feet
        [n,n,n,n,n,n,n,n,n,D,D,D,D,n,n,n,n,n,n,n,D,D,D,D,n,n,n,n,n,n,n,n,n],   # feet bottom
    ],

    # Tanuki — Kani stage. The evolution adds a LIGHTER BELLY PATCH (L
    # pixels forming an oval in the middle of the body) — tanukis are
    # iconic for their pale underside, and no other Kodomon species has
    # an internal lighter-toned pattern inside its body. The body also
    # grows rounder and wider than the head, reaching the full grid
    # width (cols 0 and 23) at the midsection for a drum-belly look.
    "tanuki_kani": [
        [n,n,n,n,n,D,D,n,n,n,n,n,n,n,n,n,n,D,D,n,n,n,n,n],   # ear tips
        [n,n,n,n,D,B,B,D,n,n,n,n,n,n,n,n,D,B,B,D,n,n,n,n],   # ears 4 wide
        [n,n,n,D,B,B,B,B,D,n,n,n,n,n,n,D,B,B,B,B,D,n,n,n],   # ears 6 wide
        [n,n,D,B,B,B,B,B,D,D,D,D,D,D,D,D,B,B,B,B,B,D,n,n],   # ears merge w/ head
        [n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n],   # head top
        [n,n,D,L,B,D,D,D,D,D,B,B,B,B,D,D,D,D,D,B,L,D,n,n],   # mask top
        [n,n,D,B,B,D,E,W,E,D,B,B,B,B,D,E,W,E,D,B,B,D,n,n],   # eyes in mask
        [n,n,D,B,B,D,D,D,D,D,B,B,B,B,D,D,D,D,D,B,B,D,n,n],   # mask bottom
        [n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n],   # head below mask
        [n,n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n,n],   # head bottom
        [n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n],   # body widens
        [D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D],   # body full width
        [D,B,B,B,B,B,B,B,L,L,L,L,L,L,L,L,B,B,B,B,B,B,B,D],   # belly starts (L)
        [D,B,B,B,B,B,B,L,L,L,L,L,L,L,L,L,L,B,B,B,B,B,B,D],   # belly wider
        [D,B,B,B,B,B,B,L,L,L,L,L,L,L,L,L,L,B,B,B,B,B,B,D],   # belly widest
        [D,B,B,B,B,B,B,B,L,L,L,L,L,L,L,L,B,B,B,B,B,B,B,D],   # belly narrows
        [n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n],   # body narrows
        [n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n],   # body tapers
        [n,n,n,n,n,n,D,B,B,D,n,n,n,n,D,B,B,D,n,n,n,n,n,n],   # feet
        [n,n,n,n,n,n,D,D,D,D,n,n,n,n,D,D,D,D,n,n,n,n,n,n],   # feet bottom
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

    # Kirimaru — Kamisama stage (33×20). The legendary gem form adds
    # FOUR NEW FEATURES beyond Kani: (1) a detached FLOATING CROWN
    # SHARD above the main diamond — a tiny 3-row gem separated by a
    # full row gap, (2) TWO DETACHED ORBITING SHARDS on the left and
    # right sides, also separated by a clear gap — like lesser gems
    # circling the main crystal, (3) an INNER FOREHEAD GEM — a 3-wide
    # D,W,D jewel inset above the cyclops eye suggesting a third-eye
    # power source, (4) a bigger 5-wide cyclops eye with a W,W,W
    # tri-highlight center (up from the 6×3 two-W gem-glint at Kani).
    # Single eye preserved — Kirimaru is still a cyclops, just a
    # divine one now.
    "kirimaru_kamisama": [
        [n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,D,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n],   # crown tip
        [n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,D,B,D,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n],   # crown body
        [n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n],   # GAP (detached)
        [n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,D,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n],   # main top
        [n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,D,B,D,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n],
        [n,n,n,n,n,n,n,n,n,n,n,n,n,n,D,B,B,B,D,n,n,n,n,n,n,n,n,n,n,n,n,n,n],
        [n,n,n,n,n,n,n,n,n,n,n,n,n,D,B,B,B,B,B,D,n,n,n,n,n,n,n,n,n,n,n,n,n],
        [n,n,n,n,n,n,n,n,n,n,n,n,D,B,B,B,B,B,B,B,D,n,n,n,n,n,n,n,n,n,n,n,n],
        [n,n,n,n,n,n,n,n,n,n,n,D,B,B,B,D,W,D,B,B,B,D,n,n,n,n,n,n,n,n,n,n,n],   # FOREHEAD GEM (D,W,D)
        [n,n,n,n,n,n,n,n,n,n,D,B,B,B,B,B,B,B,B,B,B,B,D,n,n,n,n,n,n,n,n,n,n],
        [n,n,D,n,n,n,n,n,n,D,B,B,B,B,E,E,E,E,E,B,B,B,B,D,n,n,n,n,n,n,D,n,n],   # eye top + L/R shard tips
        [n,D,B,D,n,n,n,n,D,B,B,B,B,B,E,W,W,W,E,B,B,B,B,B,D,n,n,n,n,D,B,D,n],   # eye mid + widest + shards
        [D,B,B,B,D,n,n,n,n,D,B,B,B,B,E,E,E,E,E,B,B,B,B,D,n,n,n,n,D,B,B,B,D],   # eye bot + shards widest
        [n,D,B,D,n,n,n,n,n,n,D,B,B,B,B,B,B,B,B,B,B,B,D,n,n,n,n,n,n,D,B,D,n],   # shards narrow
        [n,n,D,n,n,n,n,n,n,n,n,D,B,B,B,B,B,B,B,B,B,D,n,n,n,n,n,n,n,n,D,n,n],   # shard tips
        [n,n,n,n,n,n,n,n,n,n,n,n,D,B,B,B,B,B,B,B,D,n,n,n,n,n,n,n,n,n,n,n,n],
        [n,n,n,n,n,n,n,n,n,n,n,n,n,D,B,B,B,B,B,D,n,n,n,n,n,n,n,n,n,n,n,n,n],
        [n,n,n,n,n,n,n,n,n,n,n,n,n,n,D,B,B,B,D,n,n,n,n,n,n,n,n,n,n,n,n,n,n],
        [n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,D,B,D,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n],
        [n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,D,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n],   # main bottom
    ],

    # Kirimaru — Kani stage. Structural evolution: Kobito was a diamond
    # with only a top point and a FLAT BASE. Kani has a FULL DIAMOND with
    # both top and bottom points, symmetric top-to-bottom, like a true cut
    # gem. The cyclops eye doubles in size from 3×3 to 6×3 with double
    # W highlights in the middle suggesting a "gem glint". Widest at
    # rows 9-10 (20 cols wide). All perfectly symmetric around col 11.5.
    "kirimaru_kani": [
        [n,n,n,n,n,n,n,n,n,n,n,D,D,n,n,n,n,n,n,n,n,n,n,n],   # top point
        [n,n,n,n,n,n,n,n,n,n,D,B,B,D,n,n,n,n,n,n,n,n,n,n],
        [n,n,n,n,n,n,n,n,n,D,B,B,B,B,D,n,n,n,n,n,n,n,n,n],
        [n,n,n,n,n,n,n,n,D,B,B,B,B,B,B,D,n,n,n,n,n,n,n,n],
        [n,n,n,n,n,n,n,D,B,B,B,B,B,B,B,B,D,n,n,n,n,n,n,n],
        [n,n,n,n,n,n,D,B,B,B,B,B,B,B,B,B,B,D,n,n,n,n,n,n],
        [n,n,n,n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n,n,n,n],
        [n,n,n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n,n,n],
        [n,n,n,D,B,B,B,B,B,n,E,E,E,E,n,B,B,B,B,B,D,n,n,n],   # eye top (rounded)
        [n,n,D,B,B,B,B,B,B,E,E,W,W,E,E,B,B,B,B,B,B,D,n,n],   # WIDEST + eye mid
        [n,n,D,B,B,B,B,B,B,n,E,E,E,E,n,B,B,B,B,B,B,D,n,n],   # widest + eye bot
        [n,n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n,n],   # narrowing
        [n,n,n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n,n,n],
        [n,n,n,n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n,n,n,n],
        [n,n,n,n,n,n,D,B,B,B,B,B,B,B,B,B,B,D,n,n,n,n,n,n],
        [n,n,n,n,n,n,n,D,B,B,B,B,B,B,B,B,D,n,n,n,n,n,n,n],
        [n,n,n,n,n,n,n,n,D,B,B,B,B,B,B,D,n,n,n,n,n,n,n,n],
        [n,n,n,n,n,n,n,n,n,D,B,B,B,B,D,n,n,n,n,n,n,n,n,n],
        [n,n,n,n,n,n,n,n,n,n,D,B,B,D,n,n,n,n,n,n,n,n,n,n],
        [n,n,n,n,n,n,n,n,n,n,n,D,D,n,n,n,n,n,n,n,n,n,n,n],   # bottom point
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

    # Houou — Kamisama stage (33×20). Legendary dragon deity form — all
    # connected, no floating pieces. Three new features vs Kani:
    # (1) FOUR HORNS (up from 2) forming a full dragon crown,
    # (2) L-HIGHLIGHT MANE on head edges — glowing energy aura,
    # (3) DRAGON PEARL (5-wide W orb) held between the whiskers —
    # classic Japanese dragon motif. Head fills cols 2-30 (29 wide).
    # Inner whiskers end short to frame the pearl; outer pair still
    # curves down to the bottom corners.
    "houou_kamisama": [
        [n,n,n,n,n,n,n,n,n,D,n,n,n,D,n,n,n,n,n,D,n,n,n,D,n,n,n,n,n,n,n,n,n],   # 4 horn tips
        [n,n,n,n,n,n,n,n,D,B,D,n,D,B,D,n,n,n,D,B,D,n,D,B,D,n,n,n,n,n,n,n,n],   # horn tubes
        [n,n,D,D,D,D,D,D,D,B,D,D,D,B,D,D,D,D,D,B,D,D,D,B,D,D,D,D,D,D,D,n,n],   # horns merge head top
        [n,n,D,L,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,L,D,n,n],   # head + L MANE highlights
        [n,n,D,B,B,B,B,B,B,B,E,E,E,B,B,B,B,B,B,B,E,E,E,B,B,B,B,B,B,B,D,n,n],   # eyes top
        [n,n,D,B,B,B,B,B,B,B,E,W,E,B,B,B,B,B,B,B,E,W,E,B,B,B,B,B,B,B,D,n,n],   # eye highlights
        [n,n,D,B,B,B,B,B,B,B,E,E,E,B,B,B,B,B,B,B,E,E,E,B,B,B,B,B,B,B,D,n,n],   # eyes bottom
        [n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,D,D,D,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n],   # beak
        [n,n,D,L,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,L,D,n,n],   # head mid + L MANE
        [n,n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n,n],   # head taper
        [n,n,n,n,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,n,n,n,n],   # head bottom (flat)
        [n,n,n,n,n,n,n,n,D,B,D,n,D,B,D,n,n,n,D,B,D,n,D,B,D,n,n,n,n,n,n,n,n],   # 4 whiskers start
        [n,n,n,n,n,n,n,D,B,D,n,n,D,B,D,n,n,n,D,B,D,n,n,D,B,D,n,n,n,n,n,n,n],   # outer shift, inner hold
        [n,n,n,n,n,n,D,B,D,n,n,n,n,D,n,D,W,D,n,D,n,n,n,n,D,B,D,n,n,n,n,n,n],   # inner taper, PEARL top
        [n,n,n,n,n,D,B,D,n,n,n,n,n,n,D,W,W,W,D,n,n,n,n,n,n,D,B,D,n,n,n,n,n],   # PEARL widest (5)
        [n,n,n,n,D,B,D,n,n,n,n,n,n,n,n,D,W,D,n,n,n,n,n,n,n,n,D,B,D,n,n,n,n],   # pearl bot
        [n,n,n,D,B,D,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,D,B,D,n,n,n],   # outer continue
        [n,n,D,B,D,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,D,B,D,n,n],
        [n,D,B,D,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,D,B,D,n],
        [D,B,D,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,D,B,D],   # outer reach corners
    ],

    # Houou — Kani stage. The evolution adds TWO HORNS on top of the head
    # AND TWO MORE WHISKERS for 4 total. The outer pair still curves all
    # the way to the bottom corners of the grid (like a long dragon
    # beard), while the inner pair hangs straight down from the head
    # bottom as shorter 3-wide tubes, tapering to 2-wide tips at row 15.
    # The 4 whiskers together make Houou feel like a fuller, more
    # anatomically rich dragon than Kobito's 2-whisker version.
    "houou_kani": [
        [n,n,n,n,n,n,D,n,n,n,n,n,n,n,n,n,n,D,n,n,n,n,n,n],   # horn tips
        [n,n,n,n,n,D,B,D,n,n,n,n,n,n,n,n,D,B,D,n,n,n,n,n],   # horn tubes
        [n,n,n,n,D,B,B,B,D,n,n,n,n,n,n,D,B,B,B,D,n,n,n,n],   # horns widen
        [n,n,D,D,D,B,B,B,D,D,D,D,D,D,D,D,B,B,B,D,D,D,n,n],   # horns merge w/ head
        [n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n],   # head top
        [n,n,D,B,B,B,E,E,E,B,B,B,B,B,B,E,E,E,B,B,B,D,n,n],   # eyes top
        [n,n,D,B,B,B,E,W,E,B,B,B,B,B,B,E,W,E,B,B,B,D,n,n],   # eye highlights
        [n,n,D,B,B,B,E,E,E,B,B,B,B,B,B,E,E,E,B,B,B,D,n,n],   # eyes bottom
        [n,n,D,B,B,B,B,B,B,B,B,D,D,B,B,B,B,B,B,B,B,D,n,n],   # beak
        [n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n],   # head mid
        [n,n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n,n],   # head bottom taper
        [n,n,n,n,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,n,n,n,n],   # head bottom
        [n,n,n,n,D,B,D,n,D,B,D,n,n,D,B,D,n,D,B,D,n,n,n,n],   # 4 whiskers start
        [n,n,n,D,B,B,D,n,D,B,D,n,n,D,B,D,n,D,B,B,D,n,n,n],   # outer widens
        [n,n,D,B,B,D,n,n,D,B,D,n,n,D,B,D,n,n,D,B,B,D,n,n],   # outer shifts left/right
        [n,D,B,B,D,n,n,n,n,D,D,n,n,D,D,n,n,n,n,D,B,B,D,n],   # inner tapers to tips
        [D,B,B,D,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,D,B,B,D],   # outer reach corners
        [D,B,D,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,D,B,D],   # outer narrows
        [D,D,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,D,D],   # outer 2-wide tips
        [D,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,D],   # outer final fade
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

# ── Eye metadata registration ────────────────────────────────────────────
# Format: _register_eyes("sprite_name", [(row,col)...W positions], [eye_rows], blink_row)

# Kozuchi — hammer. W at (4,5) and (4,14). Eyes span rows 2-4.
_register_eyes("kozuchi_kobito", [(4,5),(4,14)], [2,3,4], 4)
# Kozuchi Kani — W at (5,8) and (5,15). Eyes span rows 3-5.
_register_eyes("kozuchi_kani", [(5,8),(5,15)], [3,4,5], 5)

# Tanuki — single-row eyes in mask. W at (5,5) and (5,12).
_register_eyes("tanuki_kobito", [(5,5),(5,12)], [5], 5)
# Tanuki Kani — W at (6,7) and (6,16). Single eye row.
_register_eyes("tanuki_kani", [(6,7),(6,16)], [6], 6)

# Fukuron — owl, 2-wide W highlights per eye. W at (5,5),(5,6),(5,11),(5,12).
_register_eyes("fukuron_kobito", [(5,5),(5,6),(5,11),(5,12)], [4,5,6], 5)
# Fukuron Kani — W at (6,6),(6,7),(6,16),(6,17). Eyes span rows 5-7.
_register_eyes("fukuron_kani", [(6,6),(6,7),(6,16),(6,17)], [5,6,7], 6)

# Kirimaru — cyclops. W at (7,9) in kobito.
_register_eyes("kirimaru_kobito", [(7,9)], [6,7,8], 7)
# Kirimaru Kani — W at (9,11) and (9,12).
_register_eyes("kirimaru_kani", [(9,11),(9,12)], [8,9,10], 9)

# Houou — dragon. W at (4,7) and (4,13). Eyes span rows 3-4.
_register_eyes("houou_kobito", [(4,7),(4,13)], [3,4], 4)
# Houou Kani — W at (6,7) and (6,16). Eyes span rows 5-7.
_register_eyes("houou_kani", [(6,7),(6,16)], [5,6,7], 6)

# ── Unique action frames (manually designed) ─────────────────────────────

# Kozuchi Kobito slam — handle gone, head smashed directly onto wide base
SPRITES["kozuchi_kobito_slam"] = [
    [n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n],   # blank
    [n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n],   # blank
    [n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n],   # blank
    [n,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,n],   # flat top
    [D,L,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,L,D],   # head w/ highlights
    [D,L,B,B,E,E,E,B,B,B,B,B,B,E,E,E,B,B,L,D],   # eyes
    [D,B,B,B,E,E,E,B,B,B,B,B,B,E,E,E,B,B,B,D],
    [D,B,B,B,E,W,E,B,B,B,B,B,B,E,W,E,B,B,B,D],
    [D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D],
    [n,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,n],   # head bottom = base top
    [n,n,n,n,n,D,B,B,B,B,B,B,B,B,D,n,n,n,n,n],   # base flares wide
    [n,n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n,n],   # base widest
    [n,n,n,D,D,D,D,D,D,D,D,D,D,D,D,D,D,n,n,n],   # base cap
    [n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n],   # blank
]

# Tanuki Kobito belly drum — belly L patch widens for the "drum" pose
SPRITES["tanuki_kobito_drum"] = [
    [n,n,n,n,n,D,D,D,D,D,D,D,D,D,D,n,n,n,n,n],   # head top
    [n,n,n,D,D,B,B,B,B,B,B,B,B,B,B,D,D,n,n,n],
    [n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n],
    [n,n,D,B,B,B,B,D,D,D,D,D,B,B,B,B,B,D,n,n],   # mask top
    [n,n,D,B,B,B,B,D,E,D,D,E,D,B,B,B,B,D,n,n],   # eyes — squinted (D not W)
    [n,n,D,B,B,B,B,D,D,D,D,D,B,B,B,B,B,D,n,n],   # mask bottom
    [n,n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n,n],
    [n,n,n,n,D,B,B,B,B,B,B,B,B,B,B,D,n,n,n,n],
    [n,n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n,n],   # body widens (puffed)
    [n,n,D,B,B,B,L,L,L,L,L,L,L,L,B,B,B,D,n,n],   # belly WIDER (8 L's)
    [n,n,D,B,B,B,B,L,L,L,L,L,L,B,B,B,B,D,n,n],   # belly
    [n,n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n,n],
    [n,n,n,n,n,n,n,D,B,D,D,B,D,n,n,n,n,n,n,n],   # feet
    [n,n,n,n,n,n,n,D,D,D,D,D,D,n,n,n,n,n,n,n],
]

# Fukuron Kobito wing flap — wings raised higher (L highlights shift up)
SPRITES["fukuron_kobito_flap"] = [
    [n,n,n,n,D,D,n,n,n,n,n,n,n,n,D,D,n,n,n,n],   # ear tufts
    [n,n,n,n,D,B,D,D,D,D,D,D,D,D,B,D,n,n,n,n],   # head top + tufts
    [n,n,D,L,D,B,B,B,B,B,B,B,B,B,B,D,L,D,n,n],   # wings UP (L above head)
    [n,D,B,L,D,B,B,B,B,B,B,B,B,B,B,D,L,B,D,n],   # wings UP continued
    [D,B,B,D,D,B,E,E,E,B,B,E,E,E,B,D,D,B,B,D],   # eyes top + wings
    [D,B,D,n,D,B,E,W,E,B,B,E,W,E,B,D,n,D,B,D],   # eye highlights + wing gap
    [n,D,n,n,D,B,E,E,E,B,B,E,E,E,B,D,n,n,D,n],   # eyes bottom + wings down
    [n,n,n,n,D,B,B,B,D,D,D,B,B,B,B,D,n,n,n,n],   # beak
    [n,n,n,n,D,B,B,B,B,B,B,B,B,B,B,D,n,n,n,n],
    [n,n,n,n,n,D,B,B,B,B,B,B,B,B,D,n,n,n,n,n],
    [n,n,n,n,n,n,D,B,B,B,B,B,B,D,n,n,n,n,n,n],
    [n,n,n,n,n,n,D,D,D,D,D,D,D,D,n,n,n,n,n,n],   # body bottom
    [n,n,n,n,n,n,D,B,D,n,n,D,B,D,n,n,n,n,n,n],   # talons
    [n,n,n,n,n,n,D,D,D,n,n,D,D,D,n,n,n,n,n,n],
]

# Kirimaru Kobito pulse — inner body glows (B pixels near center become L)
SPRITES["kirimaru_kobito_pulse"] = [
    [n,n,n,n,n,n,n,n,n,D,D,n,n,n,n,n,n,n,n,n],   # top point
    [n,n,n,n,n,n,n,n,D,B,B,D,n,n,n,n,n,n,n,n],
    [n,n,n,n,n,n,n,D,B,B,B,B,D,n,n,n,n,n,n,n],
    [n,n,n,n,n,n,D,B,B,L,L,B,B,D,n,n,n,n,n,n],   # inner glow starts
    [n,n,n,n,n,D,B,B,L,L,L,L,B,B,D,n,n,n,n,n],
    [n,n,n,n,D,B,B,L,L,L,L,L,L,B,B,D,n,n,n,n],   # glow widens
    [n,n,n,D,B,B,L,L,E,E,E,L,L,B,B,B,D,n,n,n],   # eye top in glow
    [n,n,D,B,B,L,L,L,E,W,E,L,L,L,B,B,B,D,n,n],   # eye highlight
    [n,D,B,B,L,L,L,L,E,E,E,L,L,L,L,B,B,B,D,n],   # eye bottom
    [D,B,B,L,L,L,L,L,L,L,L,L,L,L,L,L,B,B,B,D],   # widest — full glow
    [n,D,B,B,L,L,L,L,L,L,L,L,L,L,L,B,B,B,D,n],
    [n,n,D,B,B,L,L,L,L,L,L,L,L,B,B,B,B,D,n,n],
    [n,n,n,D,B,B,B,L,L,L,L,L,B,B,B,B,D,n,n,n],
    [n,n,n,n,D,D,D,D,D,D,D,D,D,D,D,D,n,n,n,n],   # flat base
]

# Houou Kobito roar — beak opens wider (D gap becomes bigger opening)
SPRITES["houou_kobito_roar"] = [
    [n,n,n,n,n,D,D,D,D,D,D,D,D,D,D,n,n,n,n,n],   # head top
    [n,n,n,D,D,B,B,B,B,B,B,B,B,B,B,D,D,n,n,n],
    [n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n],
    [n,D,B,B,B,B,E,E,B,B,B,B,E,E,B,B,B,B,D,n],   # eyes
    [n,D,L,B,B,B,E,W,B,B,B,B,E,W,B,B,B,L,D,n],   # eye highlights
    [n,D,B,B,B,B,B,B,D,D,D,D,B,B,B,B,B,B,D,n],   # beak WIDE OPEN (4 D's)
    [n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n],
    [n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n],
    [n,n,n,D,D,D,D,D,D,D,D,D,D,D,D,D,D,n,n,n],   # head bottom
    [n,n,n,D,B,D,n,n,n,n,n,n,n,n,D,B,D,n,n,n],   # whiskers wider apart
    [n,n,D,B,B,D,n,n,n,n,n,n,n,n,D,B,B,D,n,n],
    [n,D,B,B,D,n,n,n,n,n,n,n,n,n,n,D,B,B,D,n],
    [D,B,B,D,n,n,n,n,n,n,n,n,n,n,n,n,D,B,B,D],
    [n,D,D,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,D,D],
]

# ── Kani unique action frames ─────────────────────────────────────────────

# Kozuchi Kani slam — handle gone, head sits on wide base, arms flail up
SPRITES["kozuchi_kani_slam"] = [
    [n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n],   # blank
    [n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n],   # blank
    [n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n],   # blank
    [D,D,D,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,D,D,D],   # arms up!
    [D,B,D,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,D,B,D],
    [D,D,D,n,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,n,D,D,D],   # head top + arm bases
    [n,n,n,n,D,L,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n,n,n],   # head
    [n,n,n,n,D,L,B,E,E,E,B,B,B,E,E,E,B,B,B,D,n,n,n,n],   # eyes
    [n,n,n,n,D,B,B,E,E,E,B,B,B,E,E,E,B,B,B,D,n,n,n,n],
    [n,n,n,n,D,B,B,E,W,E,B,B,B,E,W,E,B,B,B,D,n,n,n,n],
    [n,n,n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n,n,n],
    [n,n,n,n,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,n,n,n,n],   # head bottom
    [n,n,n,n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n,n,n,n],   # base flares
    [n,n,n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n,n,n],   # base wide
    [n,n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n,n],   # base widest
    [n,n,n,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,n,n,n],   # base plate
    [n,n,n,n,n,D,B,B,D,n,n,n,n,n,n,D,B,B,D,n,n,n,n,n],   # feet
    [n,n,n,n,n,D,D,D,D,n,n,n,n,n,n,D,D,D,D,n,n,n,n,n],
    [n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n],
    [n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n],
]

# Tanuki Kani belly drum — belly L patch widens, eyes squint
SPRITES["tanuki_kani_drum"] = [
    [n,n,n,n,n,D,D,n,n,n,n,n,n,n,n,n,n,D,D,n,n,n,n,n],   # ear tips
    [n,n,n,n,D,B,B,D,n,n,n,n,n,n,n,n,D,B,B,D,n,n,n,n],
    [n,n,n,D,B,B,B,B,D,n,n,n,n,n,n,D,B,B,B,B,D,n,n,n],
    [n,n,D,B,B,B,B,B,D,D,D,D,D,D,D,D,B,B,B,B,B,D,n,n],
    [n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n],
    [n,n,D,L,B,D,D,D,D,D,B,B,B,B,D,D,D,D,D,B,L,D,n,n],   # mask
    [n,n,D,B,B,D,E,D,E,D,B,B,B,B,D,E,D,E,D,B,B,D,n,n],   # squinted eyes (D not W)
    [n,n,D,B,B,D,D,D,D,D,B,B,B,B,D,D,D,D,D,B,B,D,n,n],
    [n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n],
    [n,n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n,n],
    [n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n],
    [D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D],
    [D,B,B,B,B,L,L,L,L,L,L,L,L,L,L,L,L,L,L,B,B,B,B,D],   # belly WIDER
    [D,B,B,B,B,B,L,L,L,L,L,L,L,L,L,L,L,L,B,B,B,B,B,D],
    [D,B,B,B,B,B,L,L,L,L,L,L,L,L,L,L,L,L,B,B,B,B,B,D],
    [D,B,B,B,B,L,L,L,L,L,L,L,L,L,L,L,L,L,L,B,B,B,B,D],   # belly still wide
    [n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n],
    [n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n],
    [n,n,n,n,n,n,D,B,B,D,n,n,n,n,D,B,B,D,n,n,n,n,n,n],
    [n,n,n,n,n,n,D,D,D,D,n,n,n,n,D,D,D,D,n,n,n,n,n,n],
]

# Fukuron Kani wing flap — wings raised up (D,B,D tubes shift up 2 rows)
SPRITES["fukuron_kani_flap"] = [
    [n,n,n,n,n,n,n,D,n,n,n,n,n,n,n,n,D,n,n,n,n,n,n,n],   # ear tufts
    [n,n,n,n,n,n,D,B,D,n,n,n,n,n,n,D,B,D,n,n,n,n,n,n],
    [n,n,n,n,n,D,B,B,B,D,n,n,n,n,D,B,B,B,D,n,n,n,n,n],
    [n,n,D,D,D,D,B,B,B,D,D,D,D,D,D,B,B,B,D,D,D,D,n,n],
    [n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n],
    [n,n,D,B,B,n,E,E,n,B,B,B,B,B,B,n,E,E,n,B,B,D,n,n],
    [n,n,D,B,B,E,W,W,E,B,B,B,B,B,B,E,W,W,E,B,B,D,n,n],
    [n,n,D,B,B,n,E,E,n,B,B,D,D,B,B,n,E,E,n,B,B,D,n,n],
    [n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n],
    [n,n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n,n],
    [D,D,D,n,n,D,D,B,B,B,B,B,B,B,B,B,B,D,D,n,n,D,D,D],   # wings UP (shifted)
    [D,B,D,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,D,B,D],
    [D,B,D,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,D,B,D],
    [D,D,D,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,D,D,D],
    [n,n,n,n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n,n,n,n],
    [n,n,n,n,n,n,D,B,B,B,B,B,B,B,B,B,B,D,n,n,n,n,n,n],
    [n,n,n,n,n,n,n,D,B,B,B,B,B,B,B,B,D,n,n,n,n,n,n,n],
    [n,n,n,n,n,n,n,D,D,D,D,D,D,D,D,D,D,n,n,n,n,n,n,n],
    [n,n,n,n,n,n,D,B,B,D,n,n,n,n,D,B,B,D,n,n,n,n,n,n],
    [n,n,n,n,n,n,D,D,D,D,n,n,n,n,D,D,D,D,n,n,n,n,n,n],
]

# Kirimaru Kani pulse — inner diamond glows with L highlights
SPRITES["kirimaru_kani_pulse"] = [
    [n,n,n,n,n,n,n,n,n,n,n,D,D,n,n,n,n,n,n,n,n,n,n,n],
    [n,n,n,n,n,n,n,n,n,n,D,B,B,D,n,n,n,n,n,n,n,n,n,n],
    [n,n,n,n,n,n,n,n,n,D,B,L,L,B,D,n,n,n,n,n,n,n,n,n],   # glow starts
    [n,n,n,n,n,n,n,n,D,B,L,L,L,L,B,D,n,n,n,n,n,n,n,n],
    [n,n,n,n,n,n,n,D,B,L,L,L,L,L,L,B,D,n,n,n,n,n,n,n],
    [n,n,n,n,n,n,D,B,L,L,L,L,L,L,L,L,B,D,n,n,n,n,n,n],
    [n,n,n,n,n,D,B,L,L,L,L,L,L,L,L,L,L,B,D,n,n,n,n,n],
    [n,n,n,n,D,B,L,L,L,L,L,L,L,L,L,L,L,L,B,D,n,n,n,n],
    [n,n,n,D,B,L,L,L,L,n,E,E,E,E,n,L,L,L,L,B,D,n,n,n],   # eye in glow
    [n,n,D,B,L,L,L,L,L,E,E,W,W,E,E,L,L,L,L,L,B,D,n,n],   # widest
    [n,n,D,B,L,L,L,L,L,n,E,E,E,E,n,L,L,L,L,L,B,D,n,n],
    [n,n,n,D,B,L,L,L,L,L,L,L,L,L,L,L,L,L,L,B,D,n,n,n],
    [n,n,n,n,D,B,L,L,L,L,L,L,L,L,L,L,L,L,B,D,n,n,n,n],
    [n,n,n,n,n,D,B,L,L,L,L,L,L,L,L,L,L,B,D,n,n,n,n,n],
    [n,n,n,n,n,n,D,B,L,L,L,L,L,L,L,L,B,D,n,n,n,n,n,n],
    [n,n,n,n,n,n,n,D,B,L,L,L,L,L,L,B,D,n,n,n,n,n,n,n],
    [n,n,n,n,n,n,n,n,D,B,L,L,L,L,B,D,n,n,n,n,n,n,n,n],
    [n,n,n,n,n,n,n,n,n,D,B,L,L,B,D,n,n,n,n,n,n,n,n,n],
    [n,n,n,n,n,n,n,n,n,n,D,B,B,D,n,n,n,n,n,n,n,n,n,n],
    [n,n,n,n,n,n,n,n,n,n,n,D,D,n,n,n,n,n,n,n,n,n,n,n],
]

# Houou Kani roar — beak wider, whiskers spread more
SPRITES["houou_kani_roar"] = [
    [n,n,n,n,n,n,D,n,n,n,n,n,n,n,n,n,n,D,n,n,n,n,n,n],   # horns
    [n,n,n,n,n,D,B,D,n,n,n,n,n,n,n,n,D,B,D,n,n,n,n,n],
    [n,n,n,n,D,B,B,B,D,n,n,n,n,n,n,D,B,B,B,D,n,n,n,n],
    [n,n,D,D,D,B,B,B,D,D,D,D,D,D,D,D,B,B,B,D,D,D,n,n],
    [n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n],
    [n,n,D,B,B,B,E,E,E,B,B,B,B,B,B,E,E,E,B,B,B,D,n,n],
    [n,n,D,B,B,B,E,W,E,B,B,B,B,B,B,E,W,E,B,B,B,D,n,n],
    [n,n,D,B,B,B,E,E,E,B,B,B,B,B,B,E,E,E,B,B,B,D,n,n],
    [n,n,D,B,B,B,B,B,B,B,D,D,D,D,B,B,B,B,B,B,B,D,n,n],   # beak WIDE (4 D's)
    [n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n],
    [n,n,n,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,n,n,n],
    [n,n,n,n,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,n,n,n,n],
    [n,n,n,D,B,D,n,n,D,B,D,n,n,D,B,D,n,n,D,B,D,n,n,n],   # whiskers spread wider
    [n,n,D,B,B,D,n,n,D,B,D,n,n,D,B,D,n,n,D,B,B,D,n,n],
    [n,D,B,B,D,n,n,n,n,D,D,n,n,D,D,n,n,n,n,D,B,B,D,n],
    [D,B,B,D,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,D,B,B,D],
    [D,B,D,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,D,B,D],
    [D,D,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,D,D],
    [D,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,D],
    [n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n],
]

# Generate mechanical variants (blink, and look for species that support it)
generate_anim_frames(SPRITES)


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
    .grid {{
      display: flex;
      flex-wrap: wrap;
      gap: 32px;
      align-items: flex-start;
    }}
    .sprite-group {{
      display: flex;
      flex-direction: column;
      align-items: flex-start;
    }}
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
  <div class="grid">{parts}</div>
</body>
</html>"""


def render_animated_html(anim_groups: list[tuple[str, list[tuple[str, list[list[int]]]]]], hue: float) -> str:
    """Render animated sprite groups. Each group is (label, [(frame_name, sprite)...]).
    JavaScript cycles through the frames to create a live animation."""
    import json as _json
    pal = palette(hue)
    pixel_size = 16

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
    .grid {{
      display: flex;
      flex-wrap: wrap;
      gap: 40px;
      align-items: flex-start;
    }}
    .anim-group {{
      display: flex;
      flex-direction: column;
      align-items: center;
    }}
    .anim-label {{
      font-size: 14px;
      color: #f5f0e1;
      margin-bottom: 8px;
      font-weight: bold;
    }}
    .frame-label {{
      font-size: 10px;
      color: #d83632;
      margin-top: 6px;
      height: 14px;
    }}
    .anim-canvas {{
      position: relative;
      background: #1a1a1a;
      border-radius: 8px;
      box-shadow: 0 4px 16px rgba(0,0,0,0.5);
      padding: 20px;
    }}
    .anim-frame {{
      display: none;
    }}
    .anim-frame.active {{
      display: inline-grid;
      gap: 0;
    }}
    .pixel {{
      width: {pixel_size}px;
      height: {pixel_size}px;
      box-sizing: border-box;
    }}
    """

    groups_html = []
    anim_data = []  # [(group_id, frame_count, schedule)]

    for gidx, (label, frames) in enumerate(anim_groups):
        gid = f"g{gidx}"
        frames_html = []
        for fidx, (fname, sprite) in enumerate(frames):
            rows = len(sprite)
            cols = len(sprite[0]) if sprite else 0
            cells = []
            for row in sprite:
                for code in row:
                    color = pal.get(code, "magenta")
                    cells.append(f'<div class="pixel" style="background:{color}"></div>')
            grid_template = f"repeat({cols}, {pixel_size}px)"
            active = " active" if fidx == 0 else ""
            frames_html.append(
                f'<div class="anim-frame{active}" id="{gid}_f{fidx}" '
                f'style="grid-template-columns:{grid_template}" '
                f'data-name="{fname}">'
                f'{"".join(cells)}</div>'
            )

        groups_html.append(f"""
        <div class="anim-group">
          <div class="anim-label">{label}</div>
          <div class="anim-canvas" id="{gid}">
            {''.join(frames_html)}
          </div>
          <div class="frame-label" id="{gid}_label">{frames[0][0]}</div>
        </div>
        """)

        # Build animation schedule: base(2s) → look_left(0.8s) → base(1s) →
        # look_right(0.8s) → base(1.5s) → blink(0.12s) → base(2s) → action(0.8s)
        schedule = []
        frame_map = {fname: idx for idx, (fname, _) in enumerate(frames)}
        base_idx = 0
        schedule.append((base_idx, 1500))
        if f"{label}_left" in frame_map:
            schedule.append((frame_map[f"{label}_left"], 800))
        schedule.append((base_idx, 800))
        if f"{label}_right" in frame_map:
            schedule.append((frame_map[f"{label}_right"], 800))
        schedule.append((base_idx, 1200))
        if f"{label}_blink" in frame_map:
            schedule.append((frame_map[f"{label}_blink"], 120))
        schedule.append((base_idx, 1500))
        # Unique action frame (anything not base/left/right/blink)
        for fname, idx in frame_map.items():
            if fname not in (label, f"{label}_left", f"{label}_right", f"{label}_blink"):
                schedule.append((idx, 800))
                schedule.append((base_idx, 500))
        schedule.append((base_idx, 1000))

        anim_data.append((gid, len(frames), schedule))

    script = """
    <script>
    const anims = %s;
    anims.forEach(([gid, frameCount, schedule]) => {
      let step = 0;
      function tick() {
        const [frameIdx, duration] = schedule[step];
        // Hide all frames, show current
        for (let i = 0; i < frameCount; i++) {
          const el = document.getElementById(gid + '_f' + i);
          el.classList.toggle('active', i === frameIdx);
        }
        // Update label
        const activeFrame = document.getElementById(gid + '_f' + frameIdx);
        document.getElementById(gid + '_label').textContent = activeFrame.dataset.name;
        step = (step + 1) %% schedule.length;
        setTimeout(tick, duration);
      }
      tick();
    });
    </script>
    """ % _json.dumps([(gid, fc, sched) for gid, fc, sched in anim_data])

    return f"""<!doctype html>
<html>
<head><meta charset="utf-8"><title>Kodomon Animation Preview</title>
<style>{style}</style></head>
<body>
  <h1>Kodomon Animation Preview</h1>
  <div class="meta">hue = {hue:.2f} — live animation cycle</div>
  <div class="grid">{''.join(groups_html)}</div>
  {script}
</body>
</html>"""


def main() -> None:
    args = sys.argv[1:]
    hue = 0.07  # default peach
    sprite_names: list[str] = []
    animate = False

    i = 0
    while i < len(args):
        arg = args[i]
        if arg == "--animate":
            animate = True
            i += 1
            continue
        if arg == "--hue" and i + 1 < len(args):
            hue = float(args[i + 1])
            i += 2
            continue
        if arg in SPRITES:
            sprite_names.append(arg)
            i += 1
            continue
        # Back-compat: a bare float as the last arg was the old hue syntax.
        try:
            hue = float(arg)
            i += 1
            continue
        except ValueError:
            pass
        print(f"unknown argument '{arg}'. available sprites:")
        for k in SPRITES:
            print(f"  {k}")
        sys.exit(1)

    if animate:
        # Build animation groups from base sprite names.
        # Each base name gets all its variants grouped together.
        if not sprite_names:
            # Default: animate all base sprites that have registered eyes
            sprite_names = list(EYE_META.keys())

        groups = []
        for base_name in sprite_names:
            if base_name not in SPRITES:
                continue
            frames = [(base_name, SPRITES[base_name])]
            # Collect known variants
            for suffix in ["_left", "_right", "_blink", "_slam", "_drum", "_flap", "_pulse", "_roar"]:
                key = f"{base_name}{suffix}"
                if key in SPRITES:
                    frames.append((key, SPRITES[key]))
            groups.append((base_name, frames))

        html = render_animated_html(groups, hue)
    else:
        if sprite_names:
            sprites_to_show = [(n, SPRITES[n]) for n in sprite_names]
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
