import SwiftUI

struct DeEvolutionView: View {
    let fromStage: Stage
    let toStage: Stage
    let petHue: Double
    let onComplete: () -> Void

    @State private var phase: Int = 0
    @State private var shakeOffset: CGFloat = 0
    @State private var flashOpacity: Double = 0
    @State private var spriteOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var bgDim: Double = 0
    @State private var spriteScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            Color.black.opacity(bgDim)
                .frame(width: 240, height: 380)

            // Old sprite shrinking away
            if phase < 2 {
                PixelSpriteView(
                    stage: fromStage,
                    pixelSize: 4,
                    petHue: petHue,
                    isStatic: true
                )
                .scaleEffect(spriteScale)
                .offset(x: shakeOffset)
                .saturation(phase >= 1 ? 0.3 : 1.0)
            }

            // Grey flash
            Color(red: 0.3, green: 0.3, blue: 0.3).opacity(flashOpacity)
                .frame(width: 240, height: 380)

            // New (lower) sprite
            if phase >= 2 {
                PixelSpriteView(
                    stage: toStage,
                    pixelSize: 4,
                    petHue: petHue,
                    isStatic: true
                )
                .opacity(spriteOpacity)
            }

            // Sad text
            if phase >= 2 {
                VStack(spacing: 4) {
                    Spacer()

                    Text(toStage.displayName)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.8), radius: 4)

                    Text("de-evolved...")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
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
        .onAppear { startCutscene() }
    }

    private func startCutscene() {
        // Phase 0: Dim + sad shake
        withAnimation(.easeIn(duration: 0.5)) { bgDim = 0.5 }
        withAnimation(.easeInOut(duration: 0.08).repeatCount(12, autoreverses: true)) {
            shakeOffset = 4
        }

        // Phase 1: Desaturate + shrink
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            phase = 1
            withAnimation(.easeIn(duration: 0.8)) {
                spriteScale = 0.5
                bgDim = 0.7
            }
        }

        // Grey flash
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeIn(duration: 0.2)) { flashOpacity = 0.5 }
        }

        // Phase 2: New sprite fades in
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            phase = 2
            withAnimation(.easeOut(duration: 0.1)) { flashOpacity = 0 }
            withAnimation(.easeOut(duration: 0.5)) {
                spriteOpacity = 1.0
                textOpacity = 1.0
            }
        }

        // Fade out
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.8) {
            withAnimation(.easeIn(duration: 0.5)) {
                textOpacity = 0
                bgDim = 0
                spriteOpacity = 0
            }
        }

        // Complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.3) {
            onComplete()
        }
    }
}
