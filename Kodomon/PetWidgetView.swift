import SwiftUI

// Style guide colors
struct KodomonColors {
    static let background = Color(red: 0.96, green: 0.94, blue: 0.88)  // #F5F0E1 warm cream
    static let accent = Color(red: 0.85, green: 0.21, blue: 0.20)      // #D83632 torii red
    static let textPrimary = Color(red: 0.16, green: 0.16, blue: 0.16) // #2A2A2A
    static let textSecondary = Color(red: 0.42, green: 0.40, blue: 0.38) // #6B6560
    static let border = Color(red: 0.84, green: 0.82, blue: 0.77)      // #D6D0C4
    static let purple = Color(red: 0.50, green: 0.47, blue: 0.87)      // #7F77DD
    static let teal = Color(red: 0.11, green: 0.62, blue: 0.46)        // #1D9E75
    static let coral = Color(red: 0.85, green: 0.35, blue: 0.19)       // #D85A30
    static let amber = Color(red: 0.73, green: 0.46, blue: 0.09)       // #BA7517
    static let red = Color(red: 0.89, green: 0.29, blue: 0.29)         // #E24B4A
}

struct PetWidgetView: View {
    @EnvironmentObject var engine: PetEngine

    private var xpProgress: Double {
        guard let next = engine.state.stage.nextStage else { return 1.0 }
        let current = engine.state.stage.xpThreshold
        let needed = next.xpThreshold - current
        let progress = (engine.state.totalXP - current) / needed
        return min(max(progress, 0), 1.0)
    }

    private var moodColor: Color {
        switch engine.state.mood {
        case 80...100: return KodomonColors.purple
        case 60..<80: return KodomonColors.teal
        case 40..<60: return KodomonColors.textSecondary
        case 20..<40: return KodomonColors.amber
        default: return KodomonColors.red
        }
    }

    private var stageColor: Color {
        switch engine.state.stage {
        case .tamago: return KodomonColors.textSecondary
        case .kobito: return KodomonColors.teal
        case .kani: return KodomonColors.coral
        case .kamisama: return KodomonColors.purple
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Scene area — background + sprite
            ZStack(alignment: .bottom) {
                    // Background — uses image asset if available, falls back to code-drawn
                    if let bgImage = NSImage(named: engine.state.activeBackground) {
                        Image(nsImage: bgImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 240, height: 240)
                            .clipped()
                    } else if let theme = BackgroundTheme(rawValue: engine.state.activeBackground) {
                        PixelBackgroundView(theme: theme, width: 220, height: 190)
                    } else {
                        KodomonColors.background
                    }

                    // Pet sprite — with shadow for contrast against any background
                    PixelSpriteView(
                        stage: engine.state.stage,
                        pixelSize: 4,
                        evolveProgress: xpProgress,
                        petHue: engine.state.petHue
                    )
                    .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 0)
                    .padding(.bottom, 4)
                }
                .frame(width: 240, height: 240)
                .clipped()
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 12, bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0, topTrailingRadius: 12
                    )
                )

                // Stats panel with cream background
                VStack(spacing: 0) {
                    // Red accent stripe
                    KodomonColors.accent
                        .frame(height: 2)

                    VStack(spacing: 6) {
                        // Header row
                        HStack {
                            Text(engine.state.petName.isEmpty ? "KODOMON" : engine.state.petName)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(KodomonColors.accent)
                            Spacer()
                            HStack(spacing: 2) {
                                Text("♥")
                                    .font(.system(size: 9))
                                    .foregroundColor(moodColor)
                                Text("\(Int(engine.state.mood))")
                                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                                    .foregroundColor(KodomonColors.textSecondary)
                            }
                        }

                        // Stage name
                        Text(engine.state.stage.displayName)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(KodomonColors.textSecondary)

                        // XP bar
                        VStack(spacing: 3) {
                            PixelXPBar(progress: xpProgress, color: stageColor)

                            HStack {
                                Text("\(Int(engine.state.totalXP)) XP")
                                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                                    .foregroundColor(KodomonColors.textSecondary)
                                Spacer()
                                if let next = engine.state.stage.nextStage {
                                    Text("\(Int(next.xpThreshold))")
                                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                                        .foregroundColor(KodomonColors.border)
                                }
                            }
                        }

                        // Bottom stats row
                        HStack {
                            HStack(spacing: 3) {
                                Text("▲")
                                    .font(.system(size: 8))
                                    .foregroundColor(KodomonColors.coral)
                                Text("\(engine.state.currentStreak)d streak")
                                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                                    .foregroundColor(KodomonColors.textSecondary)
                            }
                            Spacer()
                            Text("Day \(engine.state.daysAlive)")
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundColor(KodomonColors.textSecondary)
                        }

                        // Active event
                        if let event = engine.state.activeEvent {
                            HStack {
                                Rectangle()
                                    .fill(KodomonColors.accent)
                                    .frame(width: 3)
                                Text(event.displayName)
                                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                                    .foregroundColor(KodomonColors.accent)
                                Spacer()
                            }
                            .frame(height: 16)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                }
                .background(KodomonColors.background)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0, bottomLeadingRadius: 12,
                        bottomTrailingRadius: 12, topTrailingRadius: 0
                    )
                )
            }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(KodomonColors.border, lineWidth: 1)
        )
        .frame(width: 240, height: 380)
    }
}

// Pixel-segmented XP bar
struct PixelXPBar: View {
    let progress: Double
    let color: Color
    let segments: Int = 20

    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<segments, id: \.self) { i in
                let filled = Double(i) / Double(segments) < progress
                Rectangle()
                    .fill(filled ? color : KodomonColors.border.opacity(0.5))
                    .frame(height: 4)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: progress)
    }
}
