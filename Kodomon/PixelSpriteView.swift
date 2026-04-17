import SwiftUI

// Pixel colors — shorthand for sprite grids
enum P: Int {
    case n = 0  // clear (none)
    case B = 1  // body
    case D = 2  // dark outline
    case E = 3  // eye black
    case L = 4  // light highlight
    case C = 5  // crack line
    case W = 6  // white (eye highlight)

    // Base colors (default peach) — use color(hue:) for tinted version
    func color(hue: Double = 0.07) -> Color {
        switch self {
        case .n: return .clear
        case .E: return Color(red: 0.08, green: 0.08, blue: 0.08)
        case .W: return Color(red: 0.95, green: 0.95, blue: 0.95)
        case .B: return Color(hue: hue, saturation: 0.50, brightness: 0.82)
        case .D: return Color(hue: hue, saturation: 0.55, brightness: 0.50)
        case .L: return Color(hue: hue, saturation: 0.35, brightness: 0.92)
        case .C: return Color(hue: hue, saturation: 0.55, brightness: 0.40)
        }
    }
}

// Shorthand aliases
private let x = P.n  // clear
private let B = P.B  // body
private let D = P.D  // dark
private let E = P.E  // eye
private let L = P.L  // light
private let C = P.C  // crack
private let W = P.W  // white

struct SpriteData {

    // ── Tamago (egg) ~16x20 ──
    static let tamago: [[P]] = [
        [x,x,x,x,x,x,D,D,D,D,x,x,x,x,x,x],
        [x,x,x,x,D,D,L,L,L,L,D,D,x,x,x,x],
        [x,x,x,D,L,L,L,L,L,L,L,L,D,x,x,x],
        [x,x,D,L,L,B,B,B,B,B,B,L,L,D,x,x],
        [x,x,D,L,B,B,B,B,B,B,B,B,L,D,x,x],
        [x,D,L,B,B,B,B,B,B,B,B,B,B,L,D,x],
        [x,D,B,B,B,B,B,B,B,B,B,B,B,B,D,x],
        [x,D,B,B,B,B,B,B,B,B,B,B,B,B,D,x],
        [D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D],
        [D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D],
        [D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D],
        [D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D],
        [D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D],
        [D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D],
        [x,D,B,B,B,B,B,B,B,B,B,B,B,B,D,x],
        [x,D,B,B,B,B,B,B,B,B,B,B,B,B,D,x],
        [x,x,D,B,B,B,B,B,B,B,B,B,B,D,x,x],
        [x,x,D,D,B,B,B,B,B,B,B,B,D,D,x,x],
        [x,x,x,D,D,D,B,B,B,B,D,D,D,x,x,x],
        [x,x,x,x,x,D,D,D,D,D,D,x,x,x,x,x],
    ]

    // Crack stage 1 (50-65%) — small horizontal crack on the right side
    static let tamagoCrack1: [[P]] = [
        [x,x,x,x,x,x,D,D,D,D,x,x,x,x,x,x],
        [x,x,x,x,D,D,L,L,L,L,D,D,x,x,x,x],
        [x,x,x,D,L,L,L,L,L,L,L,L,D,x,x,x],
        [x,x,D,L,L,B,B,B,B,B,B,L,L,D,x,x],
        [x,x,D,L,B,B,B,B,B,B,B,B,L,D,x,x],
        [x,D,L,B,B,B,B,B,B,B,B,B,B,L,D,x],
        [x,D,B,B,B,B,B,B,B,B,B,B,B,B,D,x],
        [x,D,B,B,B,B,B,B,B,B,B,B,B,B,D,x],
        [D,B,B,B,B,B,B,B,C,C,C,B,B,B,B,D],
        [D,B,B,B,B,B,B,B,B,B,B,C,B,B,B,D],
        [D,B,B,B,B,B,B,B,B,B,B,B,C,C,B,D],
        [D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D],
        [D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D],
        [D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D],
        [x,D,B,B,B,B,B,B,B,B,B,B,B,B,D,x],
        [x,D,B,B,B,B,B,B,B,B,B,B,B,B,D,x],
        [x,x,D,B,B,B,B,B,B,B,B,B,B,D,x,x],
        [x,x,D,D,B,B,B,B,B,B,B,B,D,D,x,x],
        [x,x,x,D,D,D,B,B,B,B,D,D,D,x,x,x],
        [x,x,x,x,x,D,D,D,D,D,D,x,x,x,x,x],
    ]

    // Crack stage 2 (65-80%) — right crack + new crack branching left
    static let tamagoCrack2: [[P]] = [
        [x,x,x,x,x,x,D,D,D,D,x,x,x,x,x,x],
        [x,x,x,x,D,D,L,L,L,L,D,D,x,x,x,x],
        [x,x,x,D,L,L,L,L,L,L,L,L,D,x,x,x],
        [x,x,D,L,L,B,B,B,B,B,B,L,L,D,x,x],
        [x,x,D,L,B,B,B,B,B,B,B,B,L,D,x,x],
        [x,D,L,B,B,B,B,B,B,B,B,B,B,L,D,x],
        [x,D,B,B,B,B,B,B,B,B,B,B,B,B,D,x],
        [x,D,B,B,B,B,B,B,B,B,B,B,B,B,D,x],
        [D,B,B,B,B,B,B,C,C,C,C,B,B,B,B,D],
        [D,B,B,B,B,B,C,B,B,B,B,C,B,B,B,D],
        [D,B,B,B,B,C,C,B,B,B,B,B,C,C,B,D],
        [D,B,B,B,C,B,B,B,B,B,B,B,B,B,B,D],
        [D,B,B,C,C,B,B,B,B,B,B,B,B,B,B,D],
        [D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D],
        [x,D,B,B,B,B,B,B,B,B,B,B,B,B,D,x],
        [x,D,B,B,B,B,B,B,B,B,B,B,B,B,D,x],
        [x,x,D,B,B,B,B,B,B,B,B,B,B,D,x,x],
        [x,x,D,D,B,B,B,B,B,B,B,B,D,D,x,x],
        [x,x,x,D,D,D,B,B,B,B,D,D,D,x,x,x],
        [x,x,x,x,x,D,D,D,D,D,D,x,x,x,x,x],
    ]

    // Crack stage 3 (80-90%) — cracks reach edges, new crack up top
    static let tamagoCrack3: [[P]] = [
        [x,x,x,x,x,x,D,D,D,D,x,x,x,x,x,x],
        [x,x,x,x,D,D,L,L,L,L,D,D,x,x,x,x],
        [x,x,x,D,L,L,L,L,L,L,L,L,D,x,x,x],
        [x,x,D,L,L,B,B,B,B,B,B,L,L,D,x,x],
        [x,x,D,L,B,B,B,B,B,B,B,B,L,D,x,x],
        [x,D,L,B,B,B,B,C,C,C,B,B,B,L,D,x],
        [x,D,B,B,B,B,B,B,B,B,C,B,B,B,D,x],
        [x,D,B,B,B,B,B,B,B,B,B,C,C,B,D,x],
        [D,B,B,B,B,B,C,C,C,C,C,B,B,B,B,D],
        [D,B,B,B,B,C,B,B,B,B,B,C,B,B,B,D],
        [D,B,B,B,C,C,B,B,B,B,B,B,C,C,B,D],
        [D,B,B,C,B,B,B,B,B,B,B,B,B,B,C,D],
        [D,B,C,C,B,B,B,B,B,B,B,B,B,B,B,D],
        [D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D],
        [x,D,B,B,B,B,B,B,B,B,B,B,B,B,D,x],
        [x,D,B,B,B,B,B,B,B,B,B,B,B,B,D,x],
        [x,x,D,B,B,B,B,B,B,B,B,B,B,D,x,x],
        [x,x,D,D,B,B,B,B,B,B,B,B,D,D,x,x],
        [x,x,x,D,D,D,B,B,B,B,D,D,D,x,x,x],
        [x,x,x,x,x,D,D,D,D,D,D,x,x,x,x,x],
    ]

    // Crack stage 4 (90%+) — shell breaking apart, chip missing at top
    static let tamagoCrack4: [[P]] = [
        [x,x,x,x,x,x,D,D,D,D,x,x,x,x,x,x],
        [x,x,x,x,D,D,L,L,x,x,D,D,x,x,x,x],
        [x,x,x,D,L,L,L,C,x,x,C,L,D,x,x,x],
        [x,x,D,L,L,B,C,B,B,B,B,L,L,D,x,x],
        [x,x,D,L,B,C,B,B,B,B,B,B,L,D,x,x],
        [x,D,L,B,B,B,B,C,C,C,B,B,B,L,D,x],
        [x,D,B,B,B,B,B,B,B,B,C,B,B,B,D,x],
        [x,D,B,B,B,B,B,B,B,B,B,C,C,B,D,x],
        [D,B,B,B,B,B,C,C,C,C,C,B,B,B,B,D],
        [D,B,B,B,B,C,B,B,B,B,B,C,B,B,B,D],
        [D,B,B,B,C,C,B,B,B,B,B,B,C,C,B,D],
        [D,B,B,C,B,B,B,B,B,B,B,B,B,B,C,D],
        [D,B,C,C,B,B,B,B,B,B,B,B,B,B,B,D],
        [D,C,B,B,B,B,B,B,B,B,B,B,B,B,B,D],
        [x,D,B,B,B,B,B,B,B,B,B,B,B,B,D,x],
        [x,D,B,B,B,B,B,B,B,B,B,B,B,B,D,x],
        [x,x,D,B,B,B,B,B,B,B,B,B,B,D,x,x],
        [x,x,D,D,B,B,B,B,B,B,B,B,D,D,x,x],
        [x,x,x,D,D,D,B,B,B,B,D,D,D,x,x,x],
        [x,x,x,x,x,D,D,D,D,D,D,x,x,x,x,x],
    ]

    // ── Kobito (blob with big eyes) ~20x14 ──
    // Eyes center
    static let kobito: [[P]] = [
        [x,x,x,x,x,x,D,D,D,D,D,D,D,D,x,x,x,x,x,x],
        [x,x,x,x,D,D,B,B,B,B,B,B,B,B,D,D,x,x,x,x],
        [x,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,x],
        [x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x],
        [x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x],
        [x,D,B,B,B,E,E,E,B,B,B,B,E,E,E,B,B,B,D,x],
        [D,B,B,B,B,E,E,E,B,B,B,B,E,E,E,B,B,B,B,D],
        [D,B,B,B,B,E,W,E,B,B,B,B,E,W,E,B,B,B,B,D],
        [D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D],
        [x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x],
        [x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x],
        [x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x],
        [x,x,x,D,D,B,B,B,B,B,B,B,B,B,B,D,D,x,x,x],
        [x,x,x,x,x,D,D,D,D,D,D,D,D,D,D,x,x,x,x,x],
    ]

    // Eyes looking left
    static let kobitoLeft: [[P]] = [
        [x,x,x,x,x,x,D,D,D,D,D,D,D,D,x,x,x,x,x,x],
        [x,x,x,x,D,D,B,B,B,B,B,B,B,B,D,D,x,x,x,x],
        [x,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,x],
        [x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x],
        [x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x],
        [x,D,B,B,B,E,E,E,B,B,B,B,E,E,E,B,B,B,D,x],
        [D,B,B,B,B,E,E,E,B,B,B,B,E,E,E,B,B,B,B,D],
        [D,B,B,B,B,W,E,E,B,B,B,B,W,E,E,B,B,B,B,D],
        [D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D],
        [x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x],
        [x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x],
        [x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x],
        [x,x,x,D,D,B,B,B,B,B,B,B,B,B,B,D,D,x,x,x],
        [x,x,x,x,x,D,D,D,D,D,D,D,D,D,D,x,x,x,x,x],
    ]

    // Eyes looking right
    static let kobitoRight: [[P]] = [
        [x,x,x,x,x,x,D,D,D,D,D,D,D,D,x,x,x,x,x,x],
        [x,x,x,x,D,D,B,B,B,B,B,B,B,B,D,D,x,x,x,x],
        [x,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,x],
        [x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x],
        [x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x],
        [x,D,B,B,B,E,E,E,B,B,B,B,E,E,E,B,B,B,D,x],
        [D,B,B,B,B,E,E,E,B,B,B,B,E,E,E,B,B,B,B,D],
        [D,B,B,B,B,E,E,W,B,B,B,B,E,E,W,B,B,B,B,D],
        [D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D],
        [x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x],
        [x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x],
        [x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x],
        [x,x,x,D,D,B,B,B,B,B,B,B,B,B,B,D,D,x,x,x],
        [x,x,x,x,x,D,D,D,D,D,D,D,D,D,D,x,x,x,x,x],
    ]

    // Eyes looking up
    static let kobitoUp: [[P]] = [
        [x,x,x,x,x,x,D,D,D,D,D,D,D,D,x,x,x,x,x,x],
        [x,x,x,x,D,D,B,B,B,B,B,B,B,B,D,D,x,x,x,x],
        [x,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,x],
        [x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x],
        [x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x],
        [x,D,B,B,B,E,W,E,B,B,B,B,E,W,E,B,B,B,D,x],
        [D,B,B,B,B,E,E,E,B,B,B,B,E,E,E,B,B,B,B,D],
        [D,B,B,B,B,E,E,E,B,B,B,B,E,E,E,B,B,B,B,D],
        [D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D],
        [x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x],
        [x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x],
        [x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x],
        [x,x,x,D,D,B,B,B,B,B,B,B,B,B,B,D,D,x,x,x],
        [x,x,x,x,x,D,D,D,D,D,D,D,D,D,D,x,x,x,x,x],
    ]

    // Blink — eyes closed
    static let kobitoBlink: [[P]] = [
        [x,x,x,x,x,x,D,D,D,D,D,D,D,D,x,x,x,x,x,x],
        [x,x,x,x,D,D,B,B,B,B,B,B,B,B,D,D,x,x,x,x],
        [x,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,x],
        [x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x],
        [x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x],
        [x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x],
        [D,B,B,B,B,E,E,E,B,B,B,B,E,E,E,B,B,B,B,D],
        [D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D],
        [D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D],
        [x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x],
        [x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x],
        [x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x],
        [x,x,x,D,D,B,B,B,B,B,B,B,B,B,B,D,D,x,x,x],
        [x,x,x,x,x,D,D,D,D,D,D,D,D,D,D,x,x,x,x,x],
    ]

    // Squished (landing from hop)
    static let kobitoSquish: [[P]] = [
        [x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x],
        [x,x,x,x,x,D,D,D,D,D,D,D,D,D,D,x,x,x,x,x],
        [x,x,x,D,D,B,B,B,B,B,B,B,B,B,B,D,D,x,x,x],
        [x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x],
        [x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x],
        [D,B,B,B,B,E,E,E,B,B,B,B,E,E,E,B,B,B,B,D],
        [D,B,B,B,B,E,E,E,B,B,B,B,E,E,E,B,B,B,B,D],
        [D,B,B,B,B,E,W,E,B,B,B,B,E,W,E,B,B,B,B,D],
        [D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D],
        [x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x],
        [x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x],
        [x,x,x,D,D,D,B,B,B,B,B,B,B,B,D,D,D,x,x,x],
        [x,x,x,x,x,x,D,D,D,D,D,D,D,D,x,x,x,x,x,x],
        [x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x],
    ]

    // ── Kani — same cute Kobito face, just add arms + legs ──
    static let kani: [[P]] = [
        [x,x,x,x,x,x,x,x,D,D,D,D,D,D,D,D,x,x,x,x,x,x,x,x],
        [x,x,x,x,x,x,D,D,B,B,B,B,B,B,B,B,D,D,x,x,x,x,x,x],
        [x,x,x,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,x,x,x],
        [x,x,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,x,x],
        [x,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,x],
        [x,x,x,D,B,B,B,E,E,E,B,B,B,B,E,E,E,B,B,B,D,x,x,x],
        [x,x,D,B,B,B,B,E,E,E,B,B,B,B,E,E,E,B,B,B,B,D,x,x],
        [x,x,D,B,B,B,B,E,W,E,B,B,B,B,E,W,E,B,B,B,B,D,x,x],
        [x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x],
        [x,x,x,D,B,B,B,B,B,B,B,D,D,B,B,B,B,B,B,B,D,x,x,x],
        [x,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,x],
        [x,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,x],
        [x,D,D,B,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,B,D,D,x],
        [D,B,B,D,x,D,B,B,B,B,B,B,B,B,B,B,B,B,D,x,D,B,B,D],
        [D,B,D,x,x,x,D,D,B,B,B,B,B,B,B,B,D,D,x,x,x,D,B,D],
        [x,D,x,x,x,x,x,D,B,B,B,B,B,B,B,B,D,x,x,x,x,x,D,x],
        [x,x,x,x,x,x,x,D,B,B,D,D,D,D,B,B,D,x,x,x,x,x,x,x],
        [x,x,x,x,x,x,D,B,B,D,x,x,x,x,D,B,B,D,x,x,x,x,x,x],
        [x,x,x,x,x,x,D,B,B,D,x,x,x,x,D,B,B,D,x,x,x,x,x,x],
        [x,x,x,x,x,x,D,D,D,D,x,x,x,x,D,D,D,D,x,x,x,x,x,x],
    ]

    // Kani — eyes looking left
    static let kaniLeft: [[P]] = [
        [x,x,x,x,x,x,x,x,D,D,D,D,D,D,D,D,x,x,x,x,x,x,x,x],
        [x,x,x,x,x,x,D,D,B,B,B,B,B,B,B,B,D,D,x,x,x,x,x,x],
        [x,x,x,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,x,x,x],
        [x,x,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,x,x],
        [x,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,x],
        [x,x,x,D,B,B,B,E,E,E,B,B,B,B,E,E,E,B,B,B,D,x,x,x],
        [x,x,D,B,B,B,B,E,E,E,B,B,B,B,E,E,E,B,B,B,B,D,x,x],
        [x,x,D,B,B,B,B,W,E,E,B,B,B,B,W,E,E,B,B,B,B,D,x,x],
        [x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x],
        [x,x,x,D,B,B,B,B,B,B,B,D,D,B,B,B,B,B,B,B,D,x,x,x],
        [x,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,x],
        [x,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,x],
        [x,D,D,B,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,B,D,D,x],
        [D,B,B,D,x,D,B,B,B,B,B,B,B,B,B,B,B,B,D,x,D,B,B,D],
        [D,B,D,x,x,x,D,D,B,B,B,B,B,B,B,B,D,D,x,x,x,D,B,D],
        [x,D,x,x,x,x,x,D,B,B,B,B,B,B,B,B,D,x,x,x,x,x,D,x],
        [x,x,x,x,x,x,x,D,B,B,D,D,D,D,B,B,D,x,x,x,x,x,x,x],
        [x,x,x,x,x,x,D,B,B,D,x,x,x,x,D,B,B,D,x,x,x,x,x,x],
        [x,x,x,x,x,x,D,B,B,D,x,x,x,x,D,B,B,D,x,x,x,x,x,x],
        [x,x,x,x,x,x,D,D,D,D,x,x,x,x,D,D,D,D,x,x,x,x,x,x],
    ]

    // Kani — eyes looking right
    static let kaniRight: [[P]] = [
        [x,x,x,x,x,x,x,x,D,D,D,D,D,D,D,D,x,x,x,x,x,x,x,x],
        [x,x,x,x,x,x,D,D,B,B,B,B,B,B,B,B,D,D,x,x,x,x,x,x],
        [x,x,x,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,x,x,x],
        [x,x,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,x,x],
        [x,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,x],
        [x,x,x,D,B,B,B,E,E,E,B,B,B,B,E,E,E,B,B,B,D,x,x,x],
        [x,x,D,B,B,B,B,E,E,E,B,B,B,B,E,E,E,B,B,B,B,D,x,x],
        [x,x,D,B,B,B,B,E,E,W,B,B,B,B,E,E,W,B,B,B,B,D,x,x],
        [x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x],
        [x,x,x,D,B,B,B,B,B,B,B,D,D,B,B,B,B,B,B,B,D,x,x,x],
        [x,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,x],
        [x,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,x],
        [x,D,D,B,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,B,D,D,x],
        [D,B,B,D,x,D,B,B,B,B,B,B,B,B,B,B,B,B,D,x,D,B,B,D],
        [D,B,D,x,x,x,D,D,B,B,B,B,B,B,B,B,D,D,x,x,x,D,B,D],
        [x,D,x,x,x,x,x,D,B,B,B,B,B,B,B,B,D,x,x,x,x,x,D,x],
        [x,x,x,x,x,x,x,D,B,B,D,D,D,D,B,B,D,x,x,x,x,x,x,x],
        [x,x,x,x,x,x,D,B,B,D,x,x,x,x,D,B,B,D,x,x,x,x,x,x],
        [x,x,x,x,x,x,D,B,B,D,x,x,x,x,D,B,B,D,x,x,x,x,x,x],
        [x,x,x,x,x,x,D,D,D,D,x,x,x,x,D,D,D,D,x,x,x,x,x,x],
    ]

    // Kani — blink
    static let kaniBlink: [[P]] = [
        [x,x,x,x,x,x,x,x,D,D,D,D,D,D,D,D,x,x,x,x,x,x,x,x],
        [x,x,x,x,x,x,D,D,B,B,B,B,B,B,B,B,D,D,x,x,x,x,x,x],
        [x,x,x,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,x,x,x],
        [x,x,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,x,x],
        [x,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,x],
        [x,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,x],
        [x,x,D,B,B,B,B,E,E,E,B,B,B,B,E,E,E,B,B,B,B,D,x,x],
        [x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x],
        [x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x],
        [x,x,x,D,B,B,B,B,B,B,B,D,D,B,B,B,B,B,B,B,D,x,x,x],
        [x,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,x],
        [x,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,x],
        [x,D,D,B,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,B,D,D,x],
        [D,B,B,D,x,D,B,B,B,B,B,B,B,B,B,B,B,B,D,x,D,B,B,D],
        [D,B,D,x,x,x,D,D,B,B,B,B,B,B,B,B,D,D,x,x,x,D,B,D],
        [x,D,x,x,x,x,x,D,B,B,B,B,B,B,B,B,D,x,x,x,x,x,D,x],
        [x,x,x,x,x,x,x,D,B,B,D,D,D,D,B,B,D,x,x,x,x,x,x,x],
        [x,x,x,x,x,x,D,B,B,D,x,x,x,x,D,B,B,D,x,x,x,x,x,x],
        [x,x,x,x,x,x,D,B,B,D,x,x,x,x,D,B,B,D,x,x,x,x,x,x],
        [x,x,x,x,x,x,D,D,D,D,x,x,x,x,D,D,D,D,x,x,x,x,x,x],
    ]

    // Kani — right arm waving up
    static let kaniWave: [[P]] = [
        [x,x,x,x,x,x,x,x,D,D,D,D,D,D,D,D,x,x,x,x,x,x,x,x],
        [x,x,x,x,x,x,D,D,B,B,B,B,B,B,B,B,D,D,x,x,x,x,x,x],
        [x,x,x,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,x,x,x],
        [x,x,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,x,x],
        [x,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,D,D,x],
        [x,x,x,D,B,B,B,E,E,E,B,B,B,B,E,E,E,B,B,B,D,B,B,D],
        [x,x,D,B,B,B,B,E,E,E,B,B,B,B,E,E,E,B,B,B,B,D,B,D],
        [x,x,D,B,B,B,B,E,W,E,B,B,B,B,E,W,E,B,B,B,B,D,D,x],
        [x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x],
        [x,x,x,D,B,B,B,B,B,B,B,D,D,B,B,B,B,B,B,B,D,x,x,x],
        [x,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,x],
        [x,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,x],
        [x,D,D,B,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,x,x],
        [D,B,B,D,x,D,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,x,x,x],
        [D,B,D,x,x,x,D,D,B,B,B,B,B,B,B,B,D,D,x,x,x,x,x,x],
        [x,D,x,x,x,x,x,D,B,B,B,B,B,B,B,B,D,x,x,x,x,x,x,x],
        [x,x,x,x,x,x,x,D,B,B,D,D,D,D,B,B,D,x,x,x,x,x,x,x],
        [x,x,x,x,x,x,D,B,B,D,x,x,x,x,D,B,B,D,x,x,x,x,x,x],
        [x,x,x,x,x,x,D,B,B,D,x,x,x,x,D,B,B,D,x,x,x,x,x,x],
        [x,x,x,x,x,x,D,D,D,D,x,x,x,x,D,D,D,D,x,x,x,x,x,x],
    ]

    // ── Kamisama — god form: horns, third eye, long body, 6 arms (33 wide) ──
    static let kamisama: [[P]] = [
        [x,x,x,x,D,D,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,D,D,x,x,x,x],
        [x,x,x,x,x,D,B,D,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,D,B,D,x,x,x,x,x],
        [x,x,x,x,x,D,B,D,x,x,D,D,D,D,D,D,D,D,D,D,D,D,D,x,x,D,B,D,x,x,x,x,x],
        [x,x,x,x,x,x,D,B,D,D,B,B,B,B,B,B,B,B,B,B,B,B,B,D,D,B,D,x,x,x,x,x,x],
        [x,x,x,x,x,x,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,x,x,x,x,x,x,x],
        [x,x,x,x,x,x,x,D,B,B,B,B,B,B,B,B,W,B,B,B,B,B,B,B,D,x,x,x,x,x,x,x,x],
        [x,x,x,x,x,x,D,B,B,B,B,B,B,B,B,W,E,W,B,B,B,B,B,B,B,D,x,x,x,x,x,x,x],
        [x,x,x,x,x,x,D,B,B,B,B,B,B,B,B,B,W,B,B,B,B,B,B,B,B,D,x,x,x,x,x,x,x],
        [x,x,x,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,x,x,x,x],
        [x,x,x,x,x,D,B,B,B,B,E,E,E,B,B,B,B,B,B,B,E,E,E,B,B,B,D,x,x,x,x,x,x],
        [x,x,x,x,x,D,B,B,B,B,E,E,E,B,B,B,B,B,B,B,E,E,E,B,B,B,D,x,x,x,x,x,x],
        [x,x,x,x,x,D,B,B,B,B,E,W,E,B,B,B,B,B,B,B,E,W,E,B,B,B,D,x,x,x,x,x,x],
        [x,x,x,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,x,x,x,x],
        [x,x,x,x,x,x,D,B,B,B,B,B,B,B,B,D,D,D,B,B,B,B,B,B,B,D,x,x,x,x,x,x,x],
        [x,x,x,x,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,x,x,x,x,x],
        [D,B,D,D,B,B,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,B,B,D,D,B,D,x],
        [D,B,B,B,B,B,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,B,B,B,B,B,D,x],
        [x,D,B,D,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,D,B,D,x,x],
        [x,x,x,x,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,x,x,x,x,x],
        [D,B,D,D,B,B,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,B,B,D,D,B,D,x],
        [D,B,B,B,B,B,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,B,B,B,B,B,D,x],
        [x,D,B,D,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,D,B,D,x,x],
        [x,x,x,x,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,x,x,x,x,x],
        [D,B,D,D,B,B,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,B,B,D,D,B,D,x],
        [D,B,B,B,B,B,B,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,B,B,B,B,B,B,D,x],
        [x,D,B,D,x,x,x,x,D,D,B,B,B,B,B,B,B,B,B,B,B,B,D,D,x,x,x,x,D,B,D,x,x],
        [x,x,x,x,x,x,x,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,x,x,x,x,x,x,x,x],
        [x,x,x,x,x,x,x,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,x,x,x,x,x,x,x,x],
        [x,x,x,x,x,x,x,x,x,D,B,B,B,B,D,D,D,D,D,B,B,B,D,x,x,x,x,x,x,x,x,x,x],
        [x,x,x,x,x,x,x,x,D,B,B,B,D,D,x,x,x,x,D,D,B,B,B,D,x,x,x,x,x,x,x,x,x],
        [x,x,x,x,x,x,x,D,B,B,B,D,x,x,x,x,x,x,x,x,D,B,B,B,D,x,x,x,x,x,x,x,x],
        [x,x,x,x,x,x,x,D,B,B,B,D,x,x,x,x,x,x,x,x,D,B,B,B,D,x,x,x,x,x,x,x,x],
        [x,x,x,x,x,x,x,D,D,D,D,D,x,x,x,x,x,x,x,x,D,D,D,D,D,x,x,x,x,x,x,x,x],
    ]

    // ── Neglect frames — modify eyes on any base sprite ──

    /// Half-closed eyes (hungry/tired) — strip eye highlights for a tired look.
    /// Works universally: replaces all W (eye highlight) pixels with E so the
    /// eyes lose their shine and appear half-closed/unfocused.
    static func withDroopyEyes(_ base: [[P]]) -> [[P]] {
        var grid = base
        for row in 0..<grid.count {
            for col in 0..<grid[row].count {
                if grid[row][col] == .W {
                    grid[row][col] = .E
                }
            }
        }
        return grid
    }

    /// X eyes (sick) — break up the eye shape into an X-like pattern.
    /// Works universally: removes all W highlights, then replaces alternating
    /// E pixels with B (body) using a checkerboard rule to create a fragmented,
    /// sick-looking eye pattern on any sprite.
    static func withXEyes(_ base: [[P]]) -> [[P]] {
        var grid = base
        for row in 0..<grid.count {
            for col in 0..<grid[row].count {
                if grid[row][col] == .W {
                    grid[row][col] = .B
                } else if grid[row][col] == .E && (row + col) % 2 != 0 {
                    grid[row][col] = .B
                }
            }
        }
        return grid
    }

    /// Flat eyes (critical) — remove eyes entirely for the most severe state.
    /// Works universally: replaces ALL W and E pixels with B, completely
    /// erasing the eyes from any sprite.
    static func withFlatEyes(_ base: [[P]]) -> [[P]] {
        var grid = base
        for row in 0..<grid.count {
            for col in 0..<grid[row].count {
                if grid[row][col] == .W || grid[row][col] == .E {
                    grid[row][col] = .B
                }
            }
        }
        return grid
    }

    /// Get the right neglect frame for a given stage and neglect state
    static func neglectSprite(for stage: Stage, neglectState: NeglectState) -> [[P]]? {
        let base: [[P]]
        switch stage {
        case .tamago: return nil  // egg doesn't show neglect eyes
        case .kobito: base = kobito
        case .kani: base = kani
        case .kamisama: base = kamisama
        }

        switch neglectState {
        case .tired, .sad:
            return withDroopyEyes(base)
        case .sick:
            return withXEyes(base)
        case .critical:
            return withFlatEyes(base)
        default:
            return nil
        }
    }

    /// Apply neglect eye changes to any frame
    static func applyNeglect(_ base: [[P]], neglectState: NeglectState) -> [[P]] {
        switch neglectState {
        case .tired, .sad:
            return withDroopyEyes(base)
        case .sick:
            return withXEyes(base)
        case .critical:
            return withFlatEyes(base)
        default:
            return base
        }
    }

    static func sprite(for stage: Stage, evolveProgress: Double = 0) -> [[P]] {
        switch stage {
        case .tamago:
            if evolveProgress > 0.9 { return tamagoCrack4 }
            if evolveProgress > 0.8 { return tamagoCrack3 }
            if evolveProgress > 0.65 { return tamagoCrack2 }
            if evolveProgress > 0.5 { return tamagoCrack1 }
            return tamago
        case .kobito: return kobito
        case .kani: return kani
        case .kamisama: return kamisama
        }
    }
}

struct PixelSpriteView: View {
    let speciesID: String
    let stage: Stage
    let pixelSize: CGFloat
    let evolveProgress: Double
    let petHue: Double
    let isStatic: Bool
    let equippedAccessories: [String]
    let neglectState: NeglectState

    @State private var wiggleAngle: Double = 0
    @State private var bobOffset: CGFloat = 0
    @State private var slideOffset: CGFloat = 0
    @State private var scaleX: CGFloat = 1.0
    @State private var scaleY: CGFloat = 1.0
    @State private var currentFrame: [[P]]? = nil
    @State private var animationTimers: [Timer] = []
    @State private var animationGeneration: Int = 0

    /// Resolved sprite set for the active species.
    private var sprites: SpeciesSpriteSet? {
        SpriteRegistry.sprites(forSpeciesID: speciesID)
    }

    init(speciesID: String = "tamago_crab", stage: Stage, pixelSize: CGFloat = 3, evolveProgress: Double = 0, petHue: Double = 0.07, isStatic: Bool = false, equippedAccessories: [String] = [], neglectState: NeglectState = .none) {
        self.speciesID = speciesID
        self.stage = stage
        self.pixelSize = pixelSize
        self.evolveProgress = evolveProgress
        self.petHue = petHue
        self.isStatic = isStatic
        self.equippedAccessories = equippedAccessories
        self.neglectState = neglectState
    }

    // Extra padding above sprite for accessories (crowns, hats)
    private let accPaddingTop: CGFloat = 8
    private let accPaddingSide: CGFloat = 4

    var body: some View {
        let baseFrame = currentFrame ?? spriteForCurrentStage()
        let grid = SpriteData.applyNeglect(baseFrame, neglectState: neglectState)
        let rows = grid.count
        let cols = grid.first?.count ?? 0
        let speciesHue = SpeciesCatalog.all.first(where: { $0.id == speciesID })?.fixedHue ?? petHue
        let activeHue = stage == .tamago ? 0.07 : speciesHue
        let padTop = accPaddingTop * pixelSize
        let padSide = accPaddingSide * pixelSize

        Canvas { context, _ in
            // Draw sprite offset by padding
            for row in 0..<rows {
                for col in 0..<cols {
                    let pixel = grid[row][col]
                    guard pixel != .n else { continue }

                    let rect = CGRect(
                        x: padSide + CGFloat(col) * pixelSize,
                        y: padTop + CGFloat(row) * pixelSize,
                        width: pixelSize,
                        height: pixelSize
                    )
                    context.fill(Path(rect), with: .color(pixel.color(hue: activeHue)))
                }
            }

            // Render equipped accessories (offset by same padding)
            for accId in equippedAccessories {
                AccessoryRenderer.render(
                    accessoryId: accId,
                    stage: stage,
                    pixelSize: pixelSize,
                    in: context,
                    spriteWidth: cols,
                    spriteHeight: rows,
                    padX: padSide,
                    padY: padTop
                )
            }
        }
        .frame(
            width: CGFloat(cols) * pixelSize + padSide * 2,
            height: CGFloat(rows) * pixelSize + padTop
        )
        .scaleEffect(x: scaleX, y: scaleY, anchor: .bottom)
        .rotationEffect(.degrees(wiggleAngle))
        .offset(x: slideOffset, y: bobOffset)
        .onAppear { if !isStatic { startAnimations() } }
        .onChange(of: evolveProgress) { if !isStatic { startAnimations() } }
        .onChange(of: stage) { if !isStatic { startAnimations() } }
        .onDisappear {
            for timer in animationTimers { timer.invalidate() }
            animationTimers = []
        }
    }

    /// Resolve the base sprite for the current species + stage.
    private func spriteForCurrentStage() -> [[P]] {
        if stage == .tamago {
            return SpriteData.sprite(for: stage, evolveProgress: evolveProgress)
        }
        guard let ss = sprites else {
            return SpriteData.sprite(for: stage, evolveProgress: evolveProgress)
        }
        switch stage {
        case .tamago: return SpriteData.tamago
        case .kobito: return ss.kobito
        case .kani: return ss.kani
        case .kamisama: return ss.kamisama
        }
    }

    private func startAnimations() {
        // Cancel all previous timers
        for timer in animationTimers { timer.invalidate() }
        animationTimers = []
        // Increment generation so stale asyncAfter closures become no-ops
        animationGeneration += 1
        let gen = animationGeneration
        // Reset all animations explicitly to stop repeatForever
        withAnimation(.linear(duration: 0.01)) {
            wiggleAngle = 0
            bobOffset = 0
            slideOffset = 0
            scaleX = 1.0
            scaleY = 1.0
        }
        currentFrame = nil

        // Neglect animations override normal ones
        switch neglectState {
        case .sick:
            // Shivering
            withAnimation(.easeInOut(duration: 0.06).repeatForever(autoreverses: true)) {
                wiggleAngle = 2
            }
            return
        case .critical:
            // Barely twitching, squished down
            scaleY = 0.7
            addTimer(3.0) {
                withAnimation(.easeInOut(duration: 0.05).repeatCount(3, autoreverses: true)) {
                    wiggleAngle = 1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    guard gen == self.animationGeneration else { return }
                    wiggleAngle = 0
                }
            }
            return
        case .tired, .sad:
            // Slow, listless — run normal animations but slower
            break
        default:
            break
        }

        if stage == .tamago {
            animateTamago(gen: gen)
            return
        }
        guard let ss = sprites else { return }
        switch stage {
        case .tamago: return // unreachable
        case .kobito: animateKobito(ss, gen: gen)
        case .kani: animateKani(ss, gen: gen)
        case .kamisama: animateKamisama(ss, gen: gen)
        }
    }

    private func addTimer(_ interval: TimeInterval, _ block: @escaping () -> Void) {
        let t = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            DispatchQueue.main.async { block() }
        }
        animationTimers.append(t)
    }

    private func animateTamago(gen: Int) {
        if evolveProgress > 0.9 {
            withAnimation(.easeInOut(duration: 0.08).repeatForever(autoreverses: true)) { wiggleAngle = 6 }
        } else if evolveProgress > 0.8 {
            withAnimation(.easeInOut(duration: 0.12).repeatForever(autoreverses: true)) { wiggleAngle = 4 }
        } else if evolveProgress > 0.65 {
            withAnimation(.easeInOut(duration: 0.2).repeatForever(autoreverses: true)) { wiggleAngle = 3 }
        } else if evolveProgress > 0.5 {
            addTimer(2.0) {
                withAnimation(.easeInOut(duration: 0.15)) { wiggleAngle = 2.5 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    guard gen == self.animationGeneration else { return }
                    withAnimation(.easeInOut(duration: 0.15)) { wiggleAngle = -2 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        guard gen == self.animationGeneration else { return }
                        withAnimation(.easeInOut(duration: 0.2)) { wiggleAngle = 0 }
                    }
                }
            }
        } else if evolveProgress > 0.2 {
            addTimer(3.0) {
                withAnimation(.easeInOut(duration: 0.15)) { wiggleAngle = 2.5 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    guard gen == self.animationGeneration else { return }
                    withAnimation(.easeInOut(duration: 0.15)) { wiggleAngle = -2 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        guard gen == self.animationGeneration else { return }
                        withAnimation(.easeInOut(duration: 0.2)) { wiggleAngle = 0 }
                    }
                }
            }
        }
    }

    private func animateKobito(_ ss: SpeciesSpriteSet, gen: Int) {
        currentFrame = ss.kobito

        // Look around (only species with look frames)
        addTimer(2.0) {
            var frames: [[[P]]] = [ss.kobito]
            if let left = ss.kobitoLeft { frames.append(left) }
            if let right = ss.kobitoRight { frames.append(right) }
            // Tamago has an extra "up" frame
            if speciesID == "tamago_crab" { frames.append(TamagoCrabSprites.kobitoUp) }
            frames.append(ss.kobito)
            currentFrame = frames.randomElement()!
        }

        // Blink
        addTimer(3.5) {
            currentFrame = ss.kobitoBlink
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                guard gen == self.animationGeneration else { return }
                currentFrame = ss.kobito
            }
        }

        // Hop + squish/action
        addTimer(4.0) {
            withAnimation(.easeOut(duration: 0.15)) { bobOffset = -8 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                guard gen == self.animationGeneration else { return }
                withAnimation(.easeIn(duration: 0.1)) { bobOffset = 0 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    guard gen == self.animationGeneration else { return }
                    // Use species action frame if available, else tamago_crab squish
                    let squishFrame = ss.kobitoAction ?? (speciesID == "tamago_crab" ? TamagoCrabSprites.kobitoSquish : nil)
                    if let squish = squishFrame {
                        currentFrame = squish
                        withAnimation(.easeOut(duration: 0.08)) { scaleX = 1.1; scaleY = 0.9 }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                        guard gen == self.animationGeneration else { return }
                        currentFrame = ss.kobito
                        withAnimation(.easeInOut(duration: 0.1)) { scaleX = 1.0; scaleY = 1.0 }
                    }
                }
            }
        }
    }

    private func animateKani(_ ss: SpeciesSpriteSet, gen: Int) {
        currentFrame = ss.kani

        // Look around (only species with look frames)
        addTimer(2.5) {
            var frames: [[[P]]] = [ss.kani]
            if let left = ss.kaniLeft { frames.append(left) }
            if let right = ss.kaniRight { frames.append(right) }
            frames.append(ss.kani)
            currentFrame = frames.randomElement()!
        }

        // Blink
        addTimer(4.0) {
            currentFrame = ss.kaniBlink
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                guard gen == self.animationGeneration else { return }
                currentFrame = ss.kani
            }
        }

        // Unique action (wave, slam, drum, flap, pulse, roar)
        if let action = ss.kaniAction {
            addTimer(6.0) {
                currentFrame = action
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    guard gen == self.animationGeneration else { return }
                    currentFrame = ss.kani
                }
            }
        }

        // Walk side to side — waddle while moving
        addTimer(5.0) {
            let direction: CGFloat = Bool.random() ? 1 : -1
            let target = direction * 30

            withAnimation(.easeInOut(duration: 0.8)) { slideOffset = target }
            withAnimation(.easeInOut(duration: 0.1).repeatCount(8, autoreverses: true)) { wiggleAngle = 4 * direction }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                guard gen == self.animationGeneration else { return }
                wiggleAngle = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    guard gen == self.animationGeneration else { return }
                    withAnimation(.easeInOut(duration: 0.8)) { slideOffset = 0 }
                    withAnimation(.easeInOut(duration: 0.1).repeatCount(8, autoreverses: true)) { wiggleAngle = -4 * direction }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        guard gen == self.animationGeneration else { return }
                        wiggleAngle = 0
                    }
                }
            }
        }
    }

    private func animateKamisama(_ ss: SpeciesSpriteSet, gen: Int) {
        currentFrame = ss.kamisama
        // Slow majestic float
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) { bobOffset = -8 }

        // Subtle breathing scale
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            scaleX = 1.02
            scaleY = 1.02
        }

        // Power surge — less frequent, bigger movement
        addTimer(14.0) {
            // Vibrate with energy
            withAnimation(.easeInOut(duration: 0.04).repeatCount(10, autoreverses: true)) {
                wiggleAngle = 3
            }
            // Scale up + surge high
            withAnimation(.easeOut(duration: 0.3)) {
                scaleX = 1.1
                scaleY = 1.1
                bobOffset = -25
            }

            // Settle back
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                guard gen == self.animationGeneration else { return }
                withAnimation(.easeInOut(duration: 0.5)) {
                    wiggleAngle = 0
                    scaleX = 1.02
                    scaleY = 1.02
                }
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                    bobOffset = -8
                }
            }
        }

        // Arm flail — rapid rock back and forth like waving all arms
        addTimer(10.0) {
            withAnimation(.easeInOut(duration: 0.1).repeatCount(6, autoreverses: true)) {
                wiggleAngle = 8
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                guard gen == self.animationGeneration else { return }
                withAnimation(.easeInOut(duration: 0.15)) { wiggleAngle = 0 }
            }
        }

        // Drift far to one side
        addTimer(7.0) {
            let direction: CGFloat = Bool.random() ? 1 : -1
            withAnimation(.easeInOut(duration: 1.2)) { slideOffset = direction * 25 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                guard gen == self.animationGeneration else { return }
                withAnimation(.easeInOut(duration: 1.2)) { slideOffset = 0 }
            }
        }
    }
}
