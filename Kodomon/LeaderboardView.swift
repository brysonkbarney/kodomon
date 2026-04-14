import SwiftUI

struct LeaderboardView: View {
    @ObservedObject var engine: PetEngine
    @ObservedObject var leaderboard = LeaderboardService.shared
    @State private var sortBy = "total_xp"

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !leaderboard.isOptedIn {
                optInPrompt
            } else {
                leaderboardContent
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .onAppear {
            if leaderboard.isOptedIn {
                leaderboard.fetch(sort: sortBy)
            }
        }
    }

    // MARK: - Opt-in prompt

    private var optInPrompt: some View {
        VStack(spacing: 12) {
            Text("Leaderboard")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(KodomonColors.accent)

            Text("Join the global leaderboard to see how your Kodomon compares!")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(KodomonColors.textSecondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 4) {
                infoRow("Shows your pet name, XP, streak, and stage")
                infoRow("Your sprite and accessories are visible")
                infoRow("No personal data, code, or files are sent")
                infoRow("You can opt out anytime")
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(KodomonColors.border.opacity(0.2))
            )

            Button(action: {
                leaderboard.optIn()
                leaderboard.sync(player: engine.player, force: true)
                // Delay fetch so the sync has time to write to DB
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    leaderboard.fetch(sort: sortBy)
                }
            }) {
                Text("Join Leaderboard")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(KodomonColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
        }
    }

    private func infoRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
                .font(.system(size: 9))
                .foregroundColor(KodomonColors.teal)
            Text(text)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(KodomonColors.textPrimary)
        }
    }

    // MARK: - Leaderboard content

    private var leaderboardContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("Leaderboard")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(KodomonColors.accent)
                Spacer()
                Button(action: { leaderboard.optOut() }) {
                    Text("Leave")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(KodomonColors.textSecondary)
                }
                .buttonStyle(.plain)
                Button(action: {
                    leaderboard.sync(player: engine.player, force: true)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        leaderboard.fetch(sort: sortBy)
                    }
                }) {
                    Text("↻")
                        .font(.system(size: 14))
                        .foregroundColor(KodomonColors.textSecondary)
                }
                .buttonStyle(.plain)
            }

            // Sort picker
            HStack(spacing: 0) {
                sortButton("XP", "total_xp")
                sortButton("Streak", "current_streak")
                sortButton("Days", "active_days")
                sortButton("Lines", "lines_written")
            }
            .background(KodomonColors.border.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            Text("Updated daily at midnight")
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(KodomonColors.textSecondary)

            // Entries
            if leaderboard.entries.isEmpty {
                Text("Loading...")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(KodomonColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(Array(leaderboard.entries.enumerated()), id: \.element.id) { index, entry in
                    leaderboardRow(rank: index + 1, entry: entry)
                }
            }

        }
    }

    private func sortButton(_ label: String, _ key: String) -> some View {
        Text(label)
            .font(.system(size: 9, weight: .semibold, design: .monospaced))
            .foregroundColor(sortBy == key ? .white : KodomonColors.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 26)
            .background(sortBy == key ? KodomonColors.accent : Color.clear)
            .contentShape(Rectangle())
            .onTapGesture {
                sortBy = key
                leaderboard.fetch(sort: key)
            }
    }

    private func leaderboardRow(rank: Int, entry: LeaderboardEntry) -> some View {
        let isMe = entry.pet_name == engine.activeKodomon.name

        return HStack(alignment: .center, spacing: 8) {
            // Rank
            Text("#\(rank)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(rank <= 3 ? KodomonColors.accent : KodomonColors.textSecondary)
                .frame(width: 28, alignment: .center)

            // Sprite
            let stage = Stage(rawValue: entry.stage) ?? .tamago
            PixelSpriteView(
                stage: stage,
                pixelSize: 1,
                evolveProgress: 0,
                petHue: entry.pet_hue,
                isStatic: true,
                equippedAccessories: entry.equipped_accessories,
                neglectState: .none
            )
            .frame(width: 32, height: 40)
            .scaleEffect(0.8)

            // Name + stage
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.pet_name)
                    .font(.system(size: 10, weight: isMe ? .bold : .medium, design: .monospaced))
                    .foregroundColor(isMe ? KodomonColors.accent : KodomonColors.textPrimary)
                    .lineLimit(1)
                Text(stage.displayName)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(KodomonColors.textSecondary)
            }

            Spacer()

            // Stat value based on sort
            VStack(alignment: .trailing, spacing: 1) {
                Text(statValue(for: entry))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(KodomonColors.textPrimary)
                Text(statLabel)
                    .font(.system(size: 7, design: .monospaced))
                    .foregroundColor(KodomonColors.textSecondary)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(isMe ? KodomonColors.accent.opacity(0.08) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private func statValue(for entry: LeaderboardEntry) -> String {
        switch sortBy {
        case "current_streak": return "\(entry.current_streak)d"
        case "active_days": return "\(entry.active_days)"
        case "lines_written": return "\(entry.lines_written)"
        default: return "\(Int(entry.total_xp))"
        }
    }

    private var statLabel: String {
        switch sortBy {
        case "current_streak": return "streak"
        case "active_days": return "days"
        case "lines_written": return "lines"
        default: return "XP"
        }
    }
}
