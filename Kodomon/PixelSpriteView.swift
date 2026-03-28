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

    var color: Color {
        switch self {
        case .n: return .clear
        case .B: return Color(red: 0.85, green: 0.68, blue: 0.55)
        case .D: return Color(red: 0.62, green: 0.45, blue: 0.35)
        case .E: return Color(red: 0.08, green: 0.08, blue: 0.08)
        case .L: return Color(red: 0.92, green: 0.78, blue: 0.66)
        case .C: return Color(red: 0.50, green: 0.36, blue: 0.27)
        case .W: return Color(red: 0.95, green: 0.95, blue: 0.95)
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

    // Cracking egg — >50% toward Kobito
    static let tamagoCracking: [[P]] = [
        [x,x,x,x,x,x,D,D,D,D,x,x,x,x,x,x],
        [x,x,x,x,D,D,L,L,L,L,D,D,x,x,x,x],
        [x,x,x,D,L,L,L,L,L,L,L,L,D,x,x,x],
        [x,x,D,L,L,B,B,B,B,B,B,L,L,D,x,x],
        [x,x,D,L,B,B,B,B,B,B,B,B,L,D,x,x],
        [x,D,L,B,B,B,B,B,B,B,B,B,B,L,D,x],
        [x,D,B,B,B,B,B,B,B,B,B,B,B,B,D,x],
        [x,D,B,B,B,B,B,B,B,C,B,B,B,B,D,x],
        [D,B,B,B,B,B,B,B,C,B,B,B,B,B,B,D],
        [D,B,B,B,B,B,B,C,B,B,B,B,B,B,B,D],
        [D,B,B,B,B,B,C,B,C,B,B,B,B,B,B,D],
        [D,B,B,B,B,C,B,B,B,C,B,B,B,B,B,D],
        [D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D],
        [D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D],
        [x,D,B,B,B,B,B,B,B,B,B,B,B,B,D,x],
        [x,D,B,B,B,B,B,B,B,B,B,B,B,B,D,x],
        [x,x,D,B,B,B,B,B,B,B,B,B,B,D,x,x],
        [x,x,D,D,B,B,B,B,B,B,B,B,D,D,x,x],
        [x,x,x,D,D,D,B,B,B,B,D,D,D,x,x,x],
        [x,x,x,x,x,D,D,D,D,D,D,x,x,x,x,x],
    ]

    // Heavy cracks — >80% toward Kobito
    static let tamagoHatching: [[P]] = [
        [x,x,x,x,x,x,D,D,D,D,x,x,x,x,x,x],
        [x,x,x,x,D,D,L,L,C,L,D,D,x,x,x,x],
        [x,x,x,D,L,L,L,C,L,L,L,L,D,x,x,x],
        [x,x,D,L,L,B,C,B,B,C,B,L,L,D,x,x],
        [x,x,D,L,B,C,B,B,C,B,B,B,L,D,x,x],
        [x,D,L,B,C,B,B,C,B,B,B,B,B,L,D,x],
        [x,D,B,B,B,B,C,B,B,B,C,B,B,B,D,x],
        [x,D,B,B,B,B,B,B,B,C,B,B,B,B,D,x],
        [D,B,B,B,C,B,B,B,C,B,B,C,B,B,B,D],
        [D,B,B,C,B,B,B,C,B,B,C,B,B,B,B,D],
        [D,B,B,B,B,B,C,B,C,B,B,B,B,B,B,D],
        [D,B,B,B,B,C,B,B,B,C,B,B,C,B,B,D],
        [D,B,B,B,C,B,B,B,B,B,C,B,B,B,B,D],
        [D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D],
        [x,D,B,B,B,B,B,B,B,B,B,B,B,B,D,x],
        [x,D,B,B,B,B,B,B,B,B,B,B,B,B,D,x],
        [x,x,D,B,B,B,B,B,B,B,B,B,B,D,x,x],
        [x,x,D,D,B,B,B,B,B,B,B,B,D,D,x,x],
        [x,x,x,D,D,D,B,B,B,B,D,D,D,x,x,x],
        [x,x,x,x,x,D,D,D,D,D,D,x,x,x,x,x],
    ]

    // ── Kobito (blob with big eyes) ~20x14 ──
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

    // ── Kani (crab with claws and legs) ~20x20 ──
    static let kani: [[P]] = [
        [x,x,D,D,x,x,x,x,x,x,x,x,x,x,x,x,x,x,D,D],
        [x,D,B,B,D,x,x,x,x,x,x,x,x,x,x,x,x,D,B,D],
        [x,D,B,D,x,x,x,x,x,x,x,x,x,x,x,x,x,x,D,x],
        [x,x,D,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,D,x],
        [x,x,D,x,x,D,D,D,D,D,D,D,D,D,D,x,x,x,D,x],
        [x,x,x,x,D,B,B,B,B,B,B,B,B,B,B,D,x,x,x,x],
        [x,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,x],
        [x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x],
        [x,x,D,B,B,B,E,E,B,B,B,B,E,E,B,B,B,D,x,x],
        [x,x,D,B,B,B,E,E,B,B,B,B,E,E,B,B,B,D,x,x],
        [x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x],
        [x,x,D,B,B,B,B,D,D,D,D,D,D,B,B,B,B,D,x,x],
        [x,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,x],
        [x,x,x,D,B,B,B,B,B,B,B,B,B,B,B,B,D,x,x,x],
        [x,x,x,x,D,B,B,B,B,B,B,B,B,B,B,D,x,x,x,x],
        [x,x,x,x,D,D,B,B,B,B,B,B,B,B,D,D,x,x,x,x],
        [x,x,x,x,D,D,D,B,B,B,B,B,B,D,D,D,x,x,x,x],
        [x,x,x,D,B,D,x,D,B,D,D,B,D,x,D,B,D,x,x,x],
        [x,x,x,D,D,x,x,D,D,x,x,D,D,x,x,D,D,x,x,x],
    ]

    // ── Kamisama (placeholder — same as Kani for now, user said TBD) ──
    static let kamisama: [[P]] = kani

    static func sprite(for stage: Stage, evolveProgress: Double = 0) -> [[P]] {
        switch stage {
        case .tamago:
            if evolveProgress > 0.8 { return tamagoHatching }
            if evolveProgress > 0.5 { return tamagoCracking }
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

    @State private var wiggleAngle: Double = 0
    @State private var bobOffset: CGFloat = 0

    init(stage: Stage, pixelSize: CGFloat = 3, evolveProgress: Double = 0) {
        self.stage = stage
        self.pixelSize = pixelSize
        self.evolveProgress = evolveProgress
    }

    var body: some View {
        let grid = SpriteData.sprite(for: stage, evolveProgress: evolveProgress)
        let rows = grid.count
        let cols = grid.first?.count ?? 0

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
                    context.fill(Path(rect), with: .color(pixel.color))
                }
            }
        }
        .frame(
            width: CGFloat(cols) * pixelSize,
            height: CGFloat(rows) * pixelSize
        )
        .rotationEffect(.degrees(wiggleAngle))
        .offset(y: bobOffset)
        .onAppear { startAnimations() }
        .onChange(of: evolveProgress) { startAnimations() }
        .onChange(of: stage) { startAnimations() }
    }

    private func startAnimations() {
        wiggleAngle = 0
        bobOffset = 0

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

    private func animateTamago() {
        if evolveProgress > 0.8 {
            withAnimation(.easeInOut(duration: 0.12).repeatForever(autoreverses: true)) {
                wiggleAngle = 5
            }
        } else if evolveProgress > 0.5 {
            withAnimation(.easeInOut(duration: 0.25).repeatForever(autoreverses: true)) {
                wiggleAngle = 3
            }
        } else if evolveProgress > 0.2 {
            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                DispatchQueue.main.async {
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
    }

    private func animateKobito() {
        // Hop: quick up then down
        Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
            DispatchQueue.main.async {
                withAnimation(.easeOut(duration: 0.12)) { bobOffset = -6 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    withAnimation(.easeIn(duration: 0.12)) { bobOffset = 0 }
                }
            }
        }
    }

    private func animateKani() {
        // Waddle side to side
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.2)) { wiggleAngle = 3 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.easeInOut(duration: 0.2)) { wiggleAngle = -3 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.easeInOut(duration: 0.15)) { wiggleAngle = 0 }
                    }
                }
            }
        }
    }

    private func animateKamisama() {
        // Slow majestic float
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            bobOffset = -4
        }
    }
}
