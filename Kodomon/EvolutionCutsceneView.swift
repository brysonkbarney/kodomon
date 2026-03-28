import SwiftUI

struct EvolutionCutsceneView: View {
    let fromStage: Stage
    let toStage: Stage
    let petHue: Double
    let onComplete: () -> Void

    @State private var phase: Int = 0
    @State private var shakeOffset: CGFloat = 0
    @State private var flashOpacity: Double = 0
    @State private var spriteScale: CGFloat = 0.3
    @State private var spriteOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var sparkles: [(x: CGFloat, y: CGFloat, delay: Double)] = []
    @State private var sparkleOpacity: Double = 0
    @State private var bgDim: Double = 0

    var body: some View {
        ZStack {
            // Dim background
            Color.black.opacity(bgDim)
                .frame(width: 240, height: 380)

            // Old sprite shaking (phase 0)
            if phase == 0 {
                PixelSpriteView(
                    stage: fromStage,
                    pixelSize: 4,
                    evolveProgress: 0.99,
                    petHue: petHue
                )
                .offset(x: shakeOffset)
            }

            // White flash
            Color.white.opacity(flashOpacity)
                .frame(width: 240, height: 380)

            // New sprite appearing (phase 2+)
            if phase >= 2 {
                PixelSpriteView(
                    stage: toStage,
                    pixelSize: 4,
                    petHue: petHue
                )
                .scaleEffect(spriteScale)
                .opacity(spriteOpacity)
            }

            // Sparkle particles
            if phase >= 3 {
                ForEach(0..<sparkles.count, id: \.self) { i in
                    let s = sparkles[i]
                    SparklePixel(hue: petHue)
                        .position(x: s.x, y: s.y)
                        .opacity(sparkleOpacity)
                }
            }

            // Stage name text
            if phase >= 3 {
                VStack(spacing: 4) {
                    Spacer()

                    Text(toStage.displayName)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.8), radius: 4)

                    Text(evolutionVerb)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                        .shadow(color: .black.opacity(0.6), radius: 2)

                    Spacer()
                        .frame(height: 40)
                }
                .opacity(textOpacity)
            }
        }
        .frame(width: 240, height: 380)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .allowsHitTesting(false)
        .onAppear { startCutscene() }
    }

    private var evolutionVerb: String {
        switch toStage {
        case .kobito: return "hatched!"
        case .kani: return "evolved!"
        case .kamisama: return "ascended!"
        default: return ""
        }
    }

    private func startCutscene() {
        // Generate sparkle positions
        sparkles = (0..<12).map { _ in
            (
                x: CGFloat.random(in: 40...200),
                y: CGFloat.random(in: 80...280),
                delay: Double.random(in: 0...0.3)
            )
        }

        // Phase 0: Violent shaking (0-0.8s)
        phase = 0
        withAnimation(.easeIn(duration: 0.3)) { bgDim = 0.4 }
        withAnimation(
            .easeInOut(duration: 0.05)
            .repeatCount(16, autoreverses: true)
        ) {
            shakeOffset = 6
        }

        // Phase 1: White flash (0.8s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            phase = 1
            withAnimation(.easeIn(duration: 0.15)) {
                flashOpacity = 1.0
                bgDim = 0.8
            }
        }

        // Phase 2: New sprite appears (1.2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            phase = 2
            withAnimation(.easeOut(duration: 0.1)) {
                flashOpacity = 0
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                spriteScale = 1.0
                spriteOpacity = 1.0
            }
        }

        // Phase 3: Text + sparkles (1.8s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            phase = 3
            withAnimation(.easeOut(duration: 0.4)) {
                textOpacity = 1.0
                sparkleOpacity = 1.0
            }
        }

        // Phase 4: Fade sparkles (2.8s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            withAnimation(.easeIn(duration: 0.5)) {
                sparkleOpacity = 0
            }
        }

        // Phase 5: Fade out everything (3.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.easeIn(duration: 0.5)) {
                textOpacity = 0
                bgDim = 0
                spriteOpacity = 0
            }
        }

        // Complete (4.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            onComplete()
        }
    }
}

struct SparklePixel: View {
    let hue: Double
    @State private var offset: CGFloat = 0
    @State private var rotation: Double = 0

    var body: some View {
        Rectangle()
            .fill(Color(hue: hue, saturation: 0.6, brightness: 0.95))
            .frame(width: 4, height: 4)
            .rotationEffect(.degrees(rotation))
            .offset(y: offset)
            .onAppear {
                withAnimation(
                    .easeOut(duration: Double.random(in: 0.8...1.5))
                ) {
                    offset = CGFloat.random(in: -30 ... -10)
                    rotation = Double.random(in: -180...180)
                }
            }
    }
}
