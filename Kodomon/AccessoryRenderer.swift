import SwiftUI

// Accessory pixel colors
enum A: Int {
    case n = 0  // clear
    case R = 1  // red/accent
    case G = 2  // gold
    case K = 3  // black
    case W = 4  // white
    case P = 5  // pink
    case S = 6  // steel/silver
    case D = 7  // dark brown
    case H = 8  // hoodie grey
    case Bl = 9 // blue
    case Ye = 10 // yellow
    case Gr = 11 // green

    var color: Color {
        switch self {
        case .n: return .clear
        case .R: return Color(red: 0.85, green: 0.21, blue: 0.20)
        case .G: return Color(red: 0.90, green: 0.75, blue: 0.20)
        case .K: return Color(red: 0.10, green: 0.10, blue: 0.10)
        case .W: return Color(red: 0.95, green: 0.95, blue: 0.95)
        case .P: return Color(red: 0.95, green: 0.60, blue: 0.70)
        case .S: return Color(red: 0.70, green: 0.72, blue: 0.75)
        case .D: return Color(red: 0.35, green: 0.22, blue: 0.15)
        case .H: return Color(red: 0.35, green: 0.35, blue: 0.40)
        case .Bl: return Color(red: 0.20, green: 0.40, blue: 0.85)
        case .Ye: return Color(red: 0.95, green: 0.85, blue: 0.20)
        case .Gr: return Color(red: 0.20, green: 0.70, blue: 0.25)
        }
    }
}

private let o = A.n

struct AccessoryData {
    let pixels: [[A]]
    // Offset from sprite top-center, per stage
    let offsets: [Stage: (x: Int, y: Int)]
}

struct AccessoryRenderer {

    // MARK: - Tiny Headband
    static let tinyHeadband = AccessoryData(
        pixels: [
            [R,R,R,R,R,R,R,R,R,R,R,R,R,R],
            [o,R,R,R,R,R,R,R,R,R,R,R,R,o],
        ],
        offsets: [
            .kobito: (x: 0, y: 0),
            .kani: (x: 0, y: 0),
            .kamisama: (x: 0, y: 4),
        ]
    )

    // MARK: - Pixel Crown
    static let pixelCrown = AccessoryData(
        pixels: [
            [o,G,o,o,o,G,o,o,o,G,o],
            [o,G,G,o,o,G,o,o,G,G,o],
            [G,G,G,G,G,G,G,G,G,G,G],
            [o,G,G,G,G,G,G,G,G,G,o],
        ],
        offsets: [
            .kobito: (x: 0, y: -4),
            .kani: (x: 0, y: -4),
            .kamisama: (x: 0, y: -1),
        ]
    )

    // MARK: - Pixel Sunglasses
    static let pixelSunglasses = AccessoryData(
        pixels: [
            [K,K,K,K,K,o,o,o,o,K,K,K,K,K],
            [K,K,K,K,K,K,K,K,K,K,K,K,K,K],
            [o,K,K,W,K,o,o,o,o,K,W,K,K,o],
        ],
        offsets: [
            .kobito: (x: 0, y: 5),
            .kani: (x: 0, y: 5),
            .kamisama: (x: 0, y: 8),
        ]
    )

    // MARK: - Top Hat
    static let topHat = AccessoryData(
        pixels: [
            [o,o,o,K,K,K,K,K,o,o,o],
            [o,o,o,K,K,K,K,K,o,o,o],
            [o,o,o,K,K,K,K,K,o,o,o],
            [o,o,o,K,K,K,K,K,o,o,o],
            [o,o,o,K,R,R,K,K,o,o,o],
            [o,K,K,K,K,K,K,K,K,K,o],
        ],
        offsets: [
            .kobito: (x: 0, y: -6),
            .kani: (x: 0, y: -6),
            .kamisama: (x: 0, y: -3),
        ]
    )



    // MARK: - Golden Crown
    static let goldenCrown = AccessoryData(
        pixels: [
            [o,G,o,o,G,o,o,o,G,o,o,G,o],
            [o,G,G,o,G,G,o,G,G,o,G,G,o],
            [G,G,G,G,G,G,G,G,G,G,G,G,G],
            [G,R,G,G,G,R,G,R,G,G,G,R,G],
            [G,G,G,G,G,G,G,G,G,G,G,G,G],
        ],
        offsets: [
            .kobito: (x: 0, y: -5),
            .kani: (x: 0, y: -5),
            .kamisama: (x: 0, y: -2),
        ]
    )

    // MARK: - Devil Horns
    static let devilHorns = AccessoryData(
        pixels: [
            [R,o,o,o,o,o,o,o,o,o,o,R],
            [R,R,o,o,o,o,o,o,o,o,R,R],
            [o,R,R,o,o,o,o,o,o,R,R,o],
            [o,o,R,o,o,o,o,o,o,R,o,o],
        ],
        offsets: [
            .kobito: (x: 0, y: -3),
            .kani: (x: 0, y: -3),
            .kamisama: (x: 0, y: 0),
        ]
    )

    // MARK: - Rice Hat (kasa)
    static let riceHat = AccessoryData(
        pixels: [
            [o,o,o,o,o,o,o,D,o,o,o,o,o,o,o],
            [o,o,o,o,o,o,D,G,D,o,o,o,o,o,o],
            [o,o,o,o,o,D,G,G,G,D,o,o,o,o,o],
            [o,o,o,o,D,G,G,G,G,G,D,o,o,o,o],
            [o,o,o,D,G,G,G,G,G,G,G,D,o,o,o],
            [o,o,D,G,G,G,G,G,G,G,G,G,D,o,o],
            [o,D,G,G,G,G,G,G,G,G,G,G,G,D,o],
            [D,G,G,G,G,G,G,G,G,G,G,G,G,G,D],
        ],
        offsets: [
            .kobito: (x: 0, y: -8),
            .kani: (x: 0, y: -8),
            .kamisama: (x: 0, y: -5),
        ]
    )

    // MARK: - Katana (big, off to the right side)
    static let katana = AccessoryData(
        pixels: [
            [o,o,o,W,W],
            [o,o,o,S,S],
            [o,o,o,S,S],
            [o,o,o,S,S],
            [o,o,o,S,S],
            [o,o,o,S,S],
            [o,o,o,S,S],
            [o,o,o,S,S],
            [o,o,o,S,S],
            [o,o,o,S,S],
            [o,o,o,S,S],
            [o,o,o,S,S],
            [o,o,o,S,S],
            [o,o,o,S,S],
            [o,o,o,S,S],
            [o,o,o,S,S],
            [o,o,G,G,G],
            [o,G,G,G,G],
            [o,o,G,G,G],
            [o,o,D,D,o],
            [o,o,D,D,o],
            [o,o,D,D,o],
            [o,o,D,D,o],
            [o,o,D,D,o],
            [o,o,D,D,o],
            [o,o,D,D,o],
            [o,o,R,R,o],
        ],
        offsets: [
            .kobito: (x: 8, y: -10),
            .kani: (x: 10, y: -8),
            .kamisama: (x: 13, y: -6),
        ]
    )

    // MARK: - Propeller Hat (classic rainbow propeller)
    static let propellerHat = AccessoryData(
        pixels: [
            [o,o,o,o,o,o,K,o,o,o,o,o,o],
            [o,o,o,o,o,R,K,aG,o,o,o,o,o],
            [R,R,R,R,R,o,K,o,aG,aG,aG,aG,aG],
            [o,o,o,o,o,aB,K,aY,o,o,o,o,o],
            [aB,aB,aB,aB,aB,o,K,o,aY,aY,aY,aY,aY],
            [o,o,o,o,K,K,K,K,K,o,o,o,o],
            [o,o,o,K,K,K,K,K,K,K,o,o,o],
            [o,o,K,K,K,K,K,K,K,K,K,o,o],
        ],
        offsets: [
            .kobito: (x: 0, y: -8),
            .kani: (x: 0, y: -8),
            .kamisama: (x: 0, y: -5),
        ]
    )

    // MARK: - Sneakers (per-stage for different feet spacing)
    static let sneakersKobito: [[A]] = [
        [R,R,R,o,o,o,o,o,o,R,R,R],
        [R,W,R,R,o,o,o,o,R,R,W,R],
    ]
    static let sneakersKani: [[A]] = [
        [o,R,R,R,o,o,o,o,o,o,R,R,R,o],
        [R,R,W,R,R,o,o,o,o,R,R,W,R,R],
    ]
    static let sneakersKamisama: [[A]] = [
        // cols 7-11 and 20-24 on 33-wide grid, centered in accessory = need 33 wide
        [o,o,o,o,o,o,o,R,R,R,R,o,o,o,o,o,o,o,o,o,R,R,R,R,o,o,o,o,o,o,o,o,o],
        [o,o,o,o,o,o,R,R,W,R,R,R,o,o,o,o,o,o,o,R,R,R,W,R,R,o,o,o,o,o,o,o,o],
    ]
    static let sneakers = AccessoryData(
        pixels: sneakersKobito,
        offsets: [
            .kobito: (x: 0, y: 12),
            .kani: (x: 0, y: 18),
            .kamisama: (x: 0, y: 30),
        ]
    )

    // MARK: - Boots (brown, chunky, per-stage)
    static let bootsKobito: [[A]] = [
        [D,D,D,o,o,o,o,o,o,D,D,D],
        [D,D,D,D,o,o,o,o,D,D,D,D],
    ]
    static let bootsKani: [[A]] = [
        [o,D,D,D,o,o,o,o,o,o,D,D,D,o],
        [D,D,D,D,D,o,o,o,o,D,D,D,D,D],
    ]
    static let bootsKamisama: [[A]] = [
        [o,o,o,o,o,o,o,D,D,D,D,o,o,o,o,o,o,o,o,o,D,D,D,D,o,o,o,o,o,o,o,o,o],
        [o,o,o,o,o,o,D,D,D,D,D,D,o,o,o,o,o,o,o,D,D,D,D,D,D,o,o,o,o,o,o,o,o],
    ]
    static let boots = AccessoryData(
        pixels: bootsKobito,
        offsets: [
            .kobito: (x: 0, y: 12),
            .kani: (x: 0, y: 18),
            .kamisama: (x: 0, y: 30),
        ]
    )

    // MARK: - Lookup

    static func data(for id: String, stage: Stage = .kobito) -> AccessoryData? {
        switch id {
        case "tiny_headband": return tinyHeadband
        case "pixel_sunglasses": return pixelSunglasses
        case "top_hat": return topHat
        case "golden_crown": return goldenCrown
        case "devil_horns": return devilHorns
        case "rice_hat": return riceHat
        case "katana": return katana
        case "propeller_hat": return propellerHat
        case "sneakers":
            switch stage {
            case .kani: return AccessoryData(pixels: sneakersKani, offsets: sneakers.offsets)
            case .kamisama: return AccessoryData(pixels: sneakersKamisama, offsets: sneakers.offsets)
            default: return sneakers
            }
        case "boots":
            switch stage {
            case .kani: return AccessoryData(pixels: bootsKani, offsets: boots.offsets)
            case .kamisama: return AccessoryData(pixels: bootsKamisama, offsets: boots.offsets)
            default: return boots
            }
        default: return nil
        }
    }

    // MARK: - Render

    static func render(
        accessoryId: String,
        stage: Stage,
        pixelSize: CGFloat,
        in context: GraphicsContext,
        spriteWidth: Int,
        spriteHeight: Int,
        padX: CGFloat = 0,
        padY: CGFloat = 0
    ) {
        guard let data = data(for: accessoryId, stage: stage) else { return }
        guard let offset = data.offsets[stage] ?? data.offsets[.kobito] else { return }

        let centerX = padX + CGFloat(spriteWidth) * pixelSize / 2
        let accWidth = CGFloat(data.pixels.first?.count ?? 0)

        let startX = centerX - (accWidth * pixelSize / 2) + CGFloat(offset.x) * pixelSize
        let startY = padY + CGFloat(offset.y) * pixelSize

        for row in 0..<data.pixels.count {
            for col in 0..<data.pixels[row].count {
                let pixel = data.pixels[row][col]
                guard pixel != .n else { continue }

                let rect = CGRect(
                    x: startX + CGFloat(col) * pixelSize,
                    y: startY + CGFloat(row) * pixelSize,
                    width: pixelSize,
                    height: pixelSize
                )
                context.fill(Path(rect), with: .color(pixel.color))
            }
        }
    }
}

// Shorthand for accessory grids
private let R = A.R
private let G = A.G
private let K = A.K
private let W = A.W
private let aP = A.P
private let S = A.S
private let D = A.D
private let H = A.H
private let aB = A.Bl
private let aY = A.Ye
private let aG = A.Gr
