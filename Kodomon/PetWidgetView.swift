import SwiftUI

struct PetWidgetView: View {
    @EnvironmentObject var engine: PetEngine

    private var spriteEmoji: String {
        switch engine.state.stage {
        case .tamago: return "🥚"
        case .kobito: return "🦀"
        case .kani: return "🦞"
        case .kamisama: return "👑"
        }
    }

    private var xpProgress: Double {
        guard let next = engine.state.stage.nextStage else { return 1.0 }
        let current = engine.state.stage.xpThreshold
        let needed = next.xpThreshold - current
        let progress = (engine.state.totalXP - current) / needed
        return min(max(progress, 0), 1.0)
    }

    private var moodColor: Color {
        switch engine.state.mood {
        case 80...100: return Color(red: 0.5, green: 0.47, blue: 0.87)
        case 60..<80: return Color(red: 0.11, green: 0.62, blue: 0.46)
        case 40..<60: return Color(red: 0.55, green: 0.55, blue: 0.5)
        case 20..<40: return Color(red: 0.73, green: 0.46, blue: 0.09)
        default: return Color(red: 0.89, green: 0.29, blue: 0.29)
        }
    }

    var body: some View {
        ZStack {
            Color.clear

            VStack(spacing: 6) {
                // Mood dot
                HStack {
                    Spacer()
                    Circle()
                        .fill(moodColor)
                        .frame(width: 8, height: 8)
                }
                .padding(.horizontal, 12)

                // Pet sprite
                Text(spriteEmoji)
                    .font(.system(size: 56))

                // Stage name
                Text(engine.state.stage.displayName)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))

                // XP info
                Text("\(Int(engine.state.totalXP)) XP")
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))

                // XP bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.15))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(red: 0.5, green: 0.47, blue: 0.87))
                            .frame(width: geo.size.width * xpProgress, height: 6)
                            .animation(.easeInOut(duration: 0.5), value: xpProgress)
                    }
                }
                .frame(height: 6)
                .padding(.horizontal, 16)

                // Streak
                if engine.state.currentStreak > 0 {
                    Text("🔥 \(engine.state.currentStreak)d streak")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
        }
        .frame(width: 160, height: 180)
    }
}
