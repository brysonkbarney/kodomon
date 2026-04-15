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


def main() -> None:
    args = sys.argv[1:]
    hue = 0.07  # default peach
    sprite_names: list[str] = []

    i = 0
    while i < len(args):
        arg = args[i]
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
