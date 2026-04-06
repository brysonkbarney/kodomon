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
    var onMenuTap: (() -> Void)?
    @State private var showXPPopup: Bool = false
    @State private var xpPopupOffset: CGFloat = 0
    @State private var xpPopupOpacity: Double = 0
    @State private var lastXP: Double = 0

    /// When an evolution is pending, show the OLD stage sprite until the cutscene plays.
    /// The underlying state.stage is already the new stage (for correct XP math).
    private var displayStage: Stage {
        if let fromRaw = engine.state.pendingEvolutionFrom,
           let from = Stage(rawValue: fromRaw) {
            return from
        }
        return engine.state.stage
    }

    private var neglectSaturation: Double {
        switch engine.state.neglectState {
        case .none: return 1.0
        case .tired: return 0.7
        case .sad: return 0.5
        case .sick: return 0.3
        case .critical: return 0.1
        case .ranAway: return 0.0
        }
    }

    private var neglectOpacity: Double {
        switch engine.state.neglectState {
        case .critical: return 0.7
        case .sick: return 0.8
        default: return 1.0
        }
    }

    private var spritePixelSize: CGFloat {
        switch displayStage {
        case .tamago: return 4
        case .kobito: return 4
        case .kani: return 4
        case .kamisama: return 4
        }
    }

    private var xpProgress: Double {
        guard let next = displayStage.nextStage else { return 1.0 }
        let current = displayStage.xpThreshold
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
        switch displayStage {
        case .tamago: return KodomonColors.textSecondary
        case .kobito: return KodomonColors.teal
        case .kani: return KodomonColors.coral
        case .kamisama: return KodomonColors.purple
        }
    }

    var body: some View {
        ZStack {
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

                    // Pet sprite — hidden during cutscenes
                    if engine.evolutionEvent == nil && engine.deEvolutionEvent == nil {
                        if engine.state.neglectState == .ranAway {
                            if engine.state.isReviving {
                                // Revival in progress
                                VStack(spacing: 8) {
                                    PixelSpriteView(stage: .tamago, pixelSize: 3, isStatic: true)
                                        .opacity(0.5)
                                    Text("Reviving...")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(KodomonColors.accent)
                                    if let start = engine.state.revivalSessionStart {
                                        let elapsed = Int(Date().timeIntervalSince(start) / 60)
                                        Text("\(min(elapsed, 30))/30 min")
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(KodomonColors.textSecondary)
                                    }
                                    Text("Keep coding!")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(KodomonColors.textSecondary.opacity(0.6))
                                }
                            } else {
                                // Pet is gone
                                VStack(spacing: 8) {
                                    Text("「さようなら…」")
                                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                                        .foregroundColor(KodomonColors.textSecondary)
                                    Text("Kodomon has left.")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(KodomonColors.textSecondary.opacity(0.6))
                                    Text("Code for 30 min to bring it back")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(KodomonColors.accent.opacity(0.7))
                                }
                            }
                        } else {
                            PixelSpriteView(
                                stage: displayStage,
                                pixelSize: spritePixelSize,
                                evolveProgress: xpProgress,
                                petHue: engine.state.petHue,
                                equippedAccessories: engine.state.equippedAccessories,
                                neglectState: engine.state.neglectState
                            )
                            .saturation(neglectSaturation)
                            .opacity(neglectOpacity)
                            .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 0)
                            .padding(.bottom, 4)
                            .overlay(alignment: .top) {
                                // XP popup
                                if showXPPopup {
                                    Text("+XP")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundColor(KodomonColors.teal)
                                        .offset(y: xpPopupOffset)
                                        .opacity(xpPopupOpacity)
                                }
                            }
                        }
                    }
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
                        Text(displayStage.displayName)
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
                                if let next = displayStage.nextStage {
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
                            Button(action: { onMenuTap?() }) {
                                Text("≡")
                                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                                    .foregroundColor(KodomonColors.textSecondary)
                            }
                            .buttonStyle(.plain)
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

            // Evolution cutscenes — inside the main container
            if let evo = engine.evolutionEvent {
                EvolutionCutsceneView(
                    fromStage: evo.from,
                    toStage: evo.to,
                    petHue: engine.state.petHue
                ) {
                    engine.clearEvolutionEvent()
                }
                .frame(width: 240, height: 380)
            }
            if let deEvo = engine.deEvolutionEvent {
                DeEvolutionView(
                    fromStage: deEvo.from,
                    toStage: deEvo.to,
                    petHue: engine.state.petHue
                ) {
                    engine.clearDeEvolutionEvent()
                }
                .frame(width: 240, height: 380)
            }
        }
        .frame(width: 240, height: 380)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
        .onTapGesture {
            engine.triggerPendingEvolution()
        }
        .onChange(of: engine.state.totalXP) {
            if engine.state.totalXP > lastXP && lastXP > 0 {
                triggerXPPopup()
            }
            lastXP = engine.state.totalXP
        }
        .onAppear {
            lastXP = engine.state.totalXP
            // Delay cutscene trigger so the widget is fully visible first
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                engine.triggerPendingEvolution()
            }
        }
    }

    private func triggerXPPopup() {
        showXPPopup = true
        xpPopupOffset = 0
        xpPopupOpacity = 1.0

        withAnimation(.easeOut(duration: 0.8)) {
            xpPopupOffset = -20
        }
        withAnimation(.easeIn(duration: 0.4).delay(0.5)) {
            xpPopupOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showXPPopup = false
        }
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
