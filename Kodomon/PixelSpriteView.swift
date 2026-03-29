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

    // ── Kamisama (placeholder — same as Kani for now, user said TBD) ──
    static let kamisama: [[P]] = kani

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
    let stage: Stage
    let pixelSize: CGFloat
    let evolveProgress: Double
    let petHue: Double

    @State private var wiggleAngle: Double = 0
    @State private var bobOffset: CGFloat = 0
    @State private var slideOffset: CGFloat = 0
    @State private var scaleX: CGFloat = 1.0
    @State private var scaleY: CGFloat = 1.0
    @State private var currentFrame: [[P]]? = nil
    @State private var animationTimers: [Timer] = []

    init(stage: Stage, pixelSize: CGFloat = 3, evolveProgress: Double = 0, petHue: Double = 0.07) {
        self.stage = stage
        self.pixelSize = pixelSize
        self.evolveProgress = evolveProgress
        self.petHue = petHue
    }

    var body: some View {
        let grid = currentFrame ?? SpriteData.sprite(for: stage, evolveProgress: evolveProgress)
        let rows = grid.count
        let cols = grid.first?.count ?? 0
        let activeHue = stage == .tamago ? 0.07 : petHue

        Canvas { context, _ in
            for row in 0..<rows {
                for col in 0..<cols {
                    let pixel = grid[row][col]
                    guard pixel != .n else { continue }

                    let rect = CGRect(
                        x: CGFloat(col) * pixelSize,
                        y: CGFloat(row) * pixelSize,
                        width: pixelSize,
                        height: pixelSize
                    )
                    context.fill(Path(rect), with: .color(pixel.color(hue: activeHue)))
                }
            }
        }
        .frame(
            width: CGFloat(cols) * pixelSize,
            height: CGFloat(rows) * pixelSize
        )
        .scaleEffect(x: scaleX, y: scaleY, anchor: .bottom)
        .rotationEffect(.degrees(wiggleAngle))
        .offset(x: slideOffset, y: bobOffset)
        .onAppear { startAnimations() }
        .onChange(of: evolveProgress) { startAnimations() }
        .onChange(of: stage) { startAnimations() }
    }

    private func startAnimations() {
        // Cancel all previous timers
        for timer in animationTimers { timer.invalidate() }
        animationTimers = []
        wiggleAngle = 0
        bobOffset = 0
        slideOffset = 0
        scaleX = 1.0
        scaleY = 1.0
        currentFrame = nil

        switch stage {
        case .tamago:
            animateTamago()
        case .kobito:
            animateKobito()
        case .kani:
            animateKani()
        case .kamisama:
            animateKamisama()
        }
    }

    private func addTimer(_ interval: TimeInterval, _ block: @escaping () -> Void) {
        let t = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            DispatchQueue.main.async { block() }
        }
        animationTimers.append(t)
    }

    private func animateTamago() {
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
                    withAnimation(.easeInOut(duration: 0.15)) { wiggleAngle = -2 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.easeInOut(duration: 0.2)) { wiggleAngle = 0 }
                    }
                }
            }
        } else if evolveProgress > 0.2 {
            addTimer(3.0) {
                withAnimation(.easeInOut(duration: 0.15)) { wiggleAngle = 2.5 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.easeInOut(duration: 0.15)) { wiggleAngle = -2 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.easeInOut(duration: 0.2)) { wiggleAngle = 0 }
                    }
                }
            }
        }
    }

    private func animateKobito() {
        currentFrame = SpriteData.kobito

        addTimer(2.0) {
            let frames = [SpriteData.kobito, SpriteData.kobitoLeft, SpriteData.kobitoRight, SpriteData.kobitoUp, SpriteData.kobito]
            currentFrame = frames.randomElement()!
        }

        addTimer(3.5) {
            currentFrame = SpriteData.kobitoBlink
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { currentFrame = SpriteData.kobito }
        }

        addTimer(4.0) {
            withAnimation(.easeOut(duration: 0.15)) { bobOffset = -8 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeIn(duration: 0.1)) { bobOffset = 0 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    currentFrame = SpriteData.kobitoSquish
                    withAnimation(.easeOut(duration: 0.08)) { scaleX = 1.1; scaleY = 0.9 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                        currentFrame = SpriteData.kobito
                        withAnimation(.easeInOut(duration: 0.1)) { scaleX = 1.0; scaleY = 1.0 }
                    }
                }
            }
        }
    }

    private func animateKani() {
        currentFrame = SpriteData.kani

        // Look around
        addTimer(2.5) {
            let frames = [SpriteData.kani, SpriteData.kaniLeft, SpriteData.kaniRight, SpriteData.kani]
            currentFrame = frames.randomElement()!
        }

        // Blink
        addTimer(4.0) {
            currentFrame = SpriteData.kaniBlink
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { currentFrame = SpriteData.kani }
        }

        // Wave arm occasionally
        addTimer(6.0) {
            currentFrame = SpriteData.kaniWave
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { currentFrame = SpriteData.kani }
        }

        // Walk side to side — waddle while moving
        addTimer(5.0) {
            let direction: CGFloat = Bool.random() ? 1 : -1
            let target = direction * 30

            // Start walking with waddle
            withAnimation(.easeInOut(duration: 0.8)) { slideOffset = target }
            // Waddle steps during the walk
            withAnimation(.easeInOut(duration: 0.1).repeatCount(8, autoreverses: true)) { wiggleAngle = 4 * direction }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                wiggleAngle = 0
                // Pause at destination
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    // Walk back with waddle
                    withAnimation(.easeInOut(duration: 0.8)) { slideOffset = 0 }
                    withAnimation(.easeInOut(duration: 0.1).repeatCount(8, autoreverses: true)) { wiggleAngle = -4 * direction }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        wiggleAngle = 0
                    }
                }
            }
        }
    }

    private func animateKamisama() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) { bobOffset = -4 }
    }
}
