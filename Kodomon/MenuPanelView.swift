import SwiftUI

struct MenuPanelView: View {
    @ObservedObject var engine: PetEngine
    @Binding var isShowing: Bool
    @State private var tab: MenuTab = .stats
    @State private var showingLeaderboard = false

    enum MenuTab: String, CaseIterable {
        case stats = "Stats"
        case kodex = "Kodex"
        case customize = "Style"
        case info = "Info"
    }

    var body: some View {
        VStack(spacing: 0) {
            if showingLeaderboard {
                // Back button
                HStack {
                    Button(action: { showingLeaderboard = false }) {
                        HStack(spacing: 4) {
                            Text("←")
                                .font(.system(size: 12, weight: .bold))
                            Text("Back")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                        }
                        .foregroundColor(KodomonColors.accent)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                ScrollView {
                    LeaderboardView(engine: engine)
                }
                .padding(.top, 8)
            } else {
                // Tab bar — full area clickable
                HStack(spacing: 0) {
                    ForEach(MenuTab.allCases, id: \.self) { t in
                        Text(t.rawValue)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(tab == t ? .white : KodomonColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 32)
                            .background(tab == t ? KodomonColors.accent : Color.clear)
                            .contentShape(Rectangle())
                            .onTapGesture { tab = t }
                    }
                }
                .background(KodomonColors.border.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(.horizontal, 16)
                .padding(.top, 12)

                // Content
                ScrollView {
                    switch tab {
                    case .stats:
                        StatsTab(engine: engine, showingLeaderboard: $showingLeaderboard)
                    case .kodex:
                        KodexTab(engine: engine)
                    case .customize:
                        CustomizeTab(engine: engine)
                    case .info:
                        InfoTab()
                    }
                }
                .padding(.top, 8)
            }
        }
    }
}

// MARK: - Stats Tab

struct StatsTab: View {
    @ObservedObject var engine: PetEngine
    @Binding var showingLeaderboard: Bool

    private var xpProgress: Double {
        let kodomon = engine.activeKodomon
        guard let next = kodomon.stage.nextStage else { return 1.0 }
        let rarity = kodomon.rarity
        let current = rarity.xpThreshold(for: kodomon.stage)
        let needed = rarity.xpThreshold(for: next) - current
        guard needed > 0 else { return 1.0 }
        let progress = (kodomon.speciesXP - current) / needed
        return min(max(progress, 0), 1.0)
    }

    var body: some View {
        let kodomon = engine.activeKodomon
        let rarity = kodomon.rarity
        VStack(alignment: .leading, spacing: 10) {
            // Pet name + stage
            HStack {
                Text(kodomon.name.isEmpty ? "Kodomon" : kodomon.name)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(KodomonColors.accent)
                Spacer()
                Text(kodomon.stage.displayName)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(KodomonColors.textSecondary)
            }

            // XP bar
            VStack(spacing: 4) {
                PixelXPBar(
                    progress: xpProgress,
                    color: KodomonColors.purple
                )
                HStack {
                    Text("\(Int(kodomon.speciesXP)) XP")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(KodomonColors.textPrimary)
                    Spacer()
                    if let next = kodomon.stage.nextStage {
                        Text("\(Int(rarity.xpThreshold(for: next))) to \(next.displayName)")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(KodomonColors.textSecondary)
                    } else {
                        Text("MAX")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(KodomonColors.purple)
                    }
                }
            }

            // Evolution requirements
            if let next = kodomon.stage.nextStage {
                let nextXPThreshold = rarity.xpThreshold(for: next)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Evolve to \(next.displayName)")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(KodomonColors.textSecondary)

                    evolveReq(
                        met: kodomon.speciesXP >= nextXPThreshold,
                        label: "XP",
                        value: "\(Int(kodomon.speciesXP))/\(Int(nextXPThreshold))"
                    )
                    evolveReq(
                        met: kodomon.activeDays >= next.requiredActiveDays,
                        label: "Active days",
                        value: "\(kodomon.activeDays)/\(next.requiredActiveDays)"
                    )
                    evolveReq(
                        met: engine.player.currentStreak >= next.requiredStreak,
                        label: "Streak",
                        value: "\(engine.player.currentStreak)/\(next.requiredStreak)"
                    )
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(KodomonColors.border.opacity(0.2))
                )
            }

            Divider()

            statRow("Days Alive", "\(kodomon.daysAlive)")
            statRow("Active Days", "\(kodomon.activeDays)")
            statRow("Code Streak", "\(engine.player.currentStreak)d")
            statRow("Best Streak", "\(engine.player.longestStreak)d")
            statRow("Mood", "\(Int(kodomon.mood))/100")

            Divider()

            statRow("Today's XP", "+\(Int(engine.player.todayXP))")
            statRow("Session Time", "\(engine.player.totalSessionMins / 60)h \(engine.player.totalSessionMins % 60)m")
            statRow("Lifetime XP", "\(Int(engine.player.lifetimeXP))")
            statRow("Total Commits", "\(engine.player.totalCommits)")
            statRow("Lines Written", "\(engine.player.totalLinesWritten)")

            Divider()

            // Collection size. Full egg / species details live in the
            // Collection tab — this is just a summary on the Stats page.
            let totalSpecies = SpeciesCatalog.all.count
            let discovered = engine.player.collection.count
            statRow("Collection", "\(discovered)/\(totalSpecies)")

            if let event = engine.player.activeEvent {
                Divider()
                HStack {
                    Text("Active Event")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(KodomonColors.textSecondary)
                    Spacer()
                    Text(event.displayName)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(KodomonColors.accent)
                }
            }

            Divider()

            Button(action: {
                showingLeaderboard = true
            }) {
                HStack {
                    Text("Leaderboard")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                    Spacer()
                    Text("→")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(KodomonColors.accent)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private func evolveReq(met: Bool, label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(met ? "✓" : "✗")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(met ? KodomonColors.teal : KodomonColors.textSecondary)
                .frame(width: 12)
            Text(label)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(met ? KodomonColors.textPrimary : KodomonColors.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(met ? KodomonColors.teal : KodomonColors.textSecondary)
        }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(KodomonColors.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(KodomonColors.textPrimary)
        }
    }

}

// MARK: - Kodex Tab

struct KodexTab: View {
    @ObservedObject var engine: PetEngine

    /// Species ID currently being hovered over in the grid. Nil means the
    /// cursor isn't over any cell — the details panel falls back to the
    /// currently active Kodomon's species.
    @State private var hoveredSpeciesID: String? = nil

    /// The species whose details are shown in the detail panel below.
    /// Hovering takes priority; otherwise show the active Kodomon's species.
    private var detailSpecies: SpeciesDefinition? {
        if let id = hoveredSpeciesID {
            return SpeciesCatalog.definition(forID: id)
        }
        return SpeciesCatalog.definition(forID: engine.activeKodomon.speciesID)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Incubating egg at the very top — it's the most urgent thing
            if !engine.player.pendingEggs.isEmpty {
                incubatingEggSection
                Divider()
            }

            // Pokedex header
            HStack(alignment: .firstTextBaseline) {
                Text("KODEX")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(KodomonColors.accent)
                Spacer()
                Text("\(engine.player.collection.count)/\(SpeciesCatalog.all.count) discovered")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(KodomonColors.textSecondary)
            }

            // 3×2 grid of species cells
            speciesGrid

            // Hover-driven details panel below the grid
            detailPanel
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    // MARK: Incubating egg

    private var incubatingEggSection: some View {
        let isReady = engine.headEggIsReady
        let progress = engine.headEggProgress
        let pct = Int(progress * 100)
        let queueExtra = engine.player.pendingEggs.count - 1

        return VStack(alignment: .leading, spacing: 8) {
            Text("Incubating Egg")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(KodomonColors.textPrimary)

            HStack {
                Text("◓")
                    .font(.system(size: 24))
                    .foregroundColor(isReady ? KodomonColors.accent : KodomonColors.textSecondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("???")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(KodomonColors.textPrimary)
                    Text(isReady ? "Ready to hatch!" : "\(pct)% incubated")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(isReady ? KodomonColors.accent : KodomonColors.textSecondary)
                }
                Spacer()
            }

            PixelXPBar(
                progress: progress,
                color: isReady ? KodomonColors.accent : KodomonColors.teal
            )

            Button(action: {
                engine.hatchHeadEggIfReady()
            }) {
                Text(isReady ? "Hatch" : "Keep coding...")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(isReady ? .white : KodomonColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(isReady ? KodomonColors.accent : KodomonColors.border.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .disabled(!isReady)

            if queueExtra > 0 {
                Text("\(queueExtra) more egg\(queueExtra == 1 ? "" : "s") waiting in queue")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(KodomonColors.textSecondary)
            }
        }
    }

    // MARK: Grid

    private var speciesGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(SpeciesCatalog.all.enumerated()), id: \.element.id) { index, species in
                speciesCell(species: species, zukanNumber: index + 1)
            }
        }
    }

    private func speciesCell(species: SpeciesDefinition, zukanNumber: Int) -> some View {
        let unlocked = engine.player.collection.contains { $0.speciesID == species.id }
        let kodomon = engine.player.collection.first { $0.speciesID == species.id }
        let isActive = kodomon?.id == engine.player.activeKodomonID
        let isHovered = hoveredSpeciesID == species.id

        return VStack(spacing: 4) {
            // Zukan number badge
            HStack {
                Text(String(format: "#%03d", zukanNumber))
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(KodomonColors.textSecondary.opacity(0.7))
                Spacer()
                if isActive {
                    Circle()
                        .fill(KodomonColors.accent)
                        .frame(width: 6, height: 6)
                }
            }

            // Sprite box — shows the actual pixel sprite for unlocked
            // species at their current stage, tinted with the Kodomon's
            // own hue. Locked species show a question-mark silhouette.
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(KodomonColors.background.opacity(0.8))
                if unlocked, let k = kodomon {
                    PixelSpriteView(
                        stage: k.stage,
                        pixelSize: 1,
                        evolveProgress: 0,
                        petHue: k.hue,
                        isStatic: true,
                        equippedAccessories: [],
                        neglectState: .none
                    )
                    .scaleEffect(1.2)
                } else {
                    Circle()
                        .fill(KodomonColors.textSecondary.opacity(0.25))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text("?")
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundColor(KodomonColors.textSecondary.opacity(0.5))
                        )
                }
            }
            .frame(height: 54)

            // Name label
            Text(unlocked ? species.displayName : "???")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(unlocked ? KodomonColors.textPrimary : KodomonColors.textSecondary.opacity(0.6))
                .lineLimit(1)
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? KodomonColors.accent.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isActive ? KodomonColors.accent
                        : (isHovered ? KodomonColors.accent.opacity(0.5) : KodomonColors.border.opacity(0.3)),
                    lineWidth: isActive ? 2 : 1
                )
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            hoveredSpeciesID = hovering ? species.id : (hoveredSpeciesID == species.id ? nil : hoveredSpeciesID)
        }
    }

    // MARK: Detail panel

    @ViewBuilder
    private var detailPanel: some View {
        if let species = detailSpecies {
            let unlocked = engine.player.collection.contains { $0.speciesID == species.id }
            let kodomon = engine.player.collection.first { $0.speciesID == species.id }
            let isActive = kodomon?.id == engine.player.activeKodomonID

            VStack(alignment: .leading, spacing: 8) {
                if unlocked, let k = kodomon {
                    // Bigger sprite preview at the top of the detail panel
                    HStack {
                        Spacer()
                        PixelSpriteView(
                            stage: k.stage,
                            pixelSize: 2,
                            evolveProgress: 0,
                            petHue: k.hue,
                            isStatic: true,
                            equippedAccessories: k.equippedAccessories,
                            neglectState: .none
                        )
                        .frame(height: 72)
                        Spacer()
                    }
                    .padding(.bottom, 4)

                    HStack(alignment: .firstTextBaseline) {
                        Text(species.displayName)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(KodomonColors.accent)
                        Text("— \(k.stage.displayName)")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(KodomonColors.textSecondary)
                        Spacer()
                        if isActive {
                            Text("DEPLOYED")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(KodomonColors.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        }
                    }

                    Text("\"\(k.name)\"")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(KodomonColors.textPrimary)

                    Text("\(Int(k.speciesXP)) species XP")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(KodomonColors.textSecondary)

                    Text(species.earnedDescription)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(KodomonColors.textSecondary.opacity(0.8))
                        .padding(.top, 2)

                    if !isActive {
                        Button(action: {
                            engine.setActive(kodomonID: k.id)
                        }) {
                            Text("Deploy \(k.name)")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(KodomonColors.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                } else {
                    // Locked species — stays fully mysterious
                    HStack {
                        Text("???")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(KodomonColors.textSecondary)
                        Spacer()
                    }
                    Text("Undiscovered species")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(KodomonColors.textSecondary.opacity(0.7))
                    Text("Keep coding. You'll find it eventually.")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(KodomonColors.textSecondary.opacity(0.5))
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(KodomonColors.border.opacity(0.15))
            )
        }
    }

    // MARK: Helpers

    private func hueColor(_ hue: Double) -> Color {
        Color(hue: hue, saturation: 0.75, brightness: 0.85)
    }
}

// MARK: - Customize Tab

struct CustomizeTab: View {
    @ObservedObject var engine: PetEngine

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Backgrounds
            Text("Backgrounds")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(KodomonColors.textPrimary)

            ForEach(UnlockSystem.backgrounds) { bg in
                let unlocked = bg.xpRequired <= engine.player.lifetimeXP
                let selected = engine.player.activeBackground == bg.id

                HStack {
                    Text(bg.displayName)
                        .font(.system(size: 10, weight: selected ? .bold : .medium, design: .monospaced))
                        .foregroundColor(unlocked ? KodomonColors.textPrimary : KodomonColors.textSecondary.opacity(0.5))
                    Spacer()
                    if selected {
                        Text("✓")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(KodomonColors.accent)
                    } else if !unlocked {
                        Text("\(Int(bg.xpRequired)) XP")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(KodomonColors.textSecondary.opacity(0.5))
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(selected ? KodomonColors.accent.opacity(0.1) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .contentShape(Rectangle())
                .onTapGesture {
                    if unlocked {
                        engine.player.activeBackground = bg.id
                        StateStore.save(engine.player)
                    }
                }
            }

            Divider()

            // Accessories
            Text("Accessories")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(KodomonColors.textPrimary)

            ForEach(UnlockSystem.accessories) { acc in
                let unlocked = acc.xpRequired <= engine.player.lifetimeXP
                let equipped = engine.activeKodomon.equippedAccessories.contains(acc.id)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(acc.displayName)
                            .font(.system(size: 10, weight: equipped ? .bold : .medium, design: .monospaced))
                            .foregroundColor(unlocked ? KodomonColors.textPrimary : KodomonColors.textSecondary.opacity(0.5))
                        Text(acc.description)
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(KodomonColors.textSecondary.opacity(0.7))
                    }
                    Spacer()
                    if equipped {
                        Text("✓")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(KodomonColors.accent)
                    } else if !unlocked {
                        Text("\(Int(acc.xpRequired)) XP")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(KodomonColors.textSecondary.opacity(0.5))
                    }
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 8)
                .background(equipped ? KodomonColors.accent.opacity(0.1) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .contentShape(Rectangle())
                .onTapGesture {
                    if unlocked {
                        var kodomon = engine.activeKodomon
                        if equipped {
                            kodomon.equippedAccessories.removeAll { $0 == acc.id }
                        } else {
                            let sameSlot = UnlockSystem.accessories.filter { $0.slot == acc.slot }.map { $0.id }
                            kodomon.equippedAccessories.removeAll { sameSlot.contains($0) }
                            kodomon.equippedAccessories.append(acc.id)
                        }
                        engine.activeKodomon = kodomon
                        StateStore.save(engine.player)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

// MARK: - Info Tab

struct InfoTab: View {
    private let rules: [(icon: String, text: String)] = [
        ("▲", "Code with Claude to earn XP"),
        ("♥", "Code daily to build your streak"),
        ("★", "Evolve through 4 stages"),
        ("◆", "Unlock backgrounds and accessories with XP"),
        ("✦", "Stop coding and your Kodomon gets sad"),
        ("◆", "Miss 7+ days and your Kodomon runs away"),
        ("♥", "Streaks multiply your XP earnings"),
        ("★", "Mood affects your XP rate"),
    ]

    private let xpSources: [(source: String, xp: String)] = [
        ("Git commit", "+25-800 XP"),
        ("Session time", "+2 XP/min"),
        ("Unique file edit", "+3 XP"),
        ("First code of day", "+10 XP"),
        ("Variety bonus (3+ types)", "+20 XP"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How It Works")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(KodomonColors.textPrimary)

            ForEach(0..<rules.count, id: \.self) { i in
                HStack(alignment: .top, spacing: 8) {
                    Text(rules[i].icon)
                        .font(.system(size: 10))
                        .foregroundColor(KodomonColors.accent)
                        .frame(width: 14)
                    Text(rules[i].text)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(KodomonColors.textPrimary)
                }
            }

            Divider()

            Text("XP Sources")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(KodomonColors.textPrimary)

            ForEach(0..<xpSources.count, id: \.self) { i in
                HStack {
                    Text(xpSources[i].source)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(KodomonColors.textSecondary)
                    Spacer()
                    Text(xpSources[i].xp)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(KodomonColors.teal)
                }
            }

            Divider()

            Text("Streak Multiplier")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(KodomonColors.textPrimary)

            VStack(alignment: .leading, spacing: 3) {
                streakRow("1-2 days", "1.0x")
                streakRow("3-6 days", "1.2x")
                streakRow("7-13 days", "1.5x")
                streakRow("14-29 days", "1.8x")
                streakRow("30+ days", "2.0x")
            }

            Divider()

            Text("Mood Multiplier")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(KodomonColors.textPrimary)

            VStack(alignment: .leading, spacing: 3) {
                moodRow("80-100", "1.3x XP", "Ecstatic")
                moodRow("60-79", "1.15x XP", "Happy")
                moodRow("40-59", "1.0x XP", "Neutral")
                moodRow("20-39", "0.85x XP", "Stressed")
                moodRow("0-19", "0.6x XP", "Miserable")
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private func moodRow(_ range: String, _ multiplier: String, _ label: String) -> some View {
        HStack {
            Text(range)
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(KodomonColors.textSecondary)
                .frame(width: 40, alignment: .leading)
            Text(multiplier)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(KodomonColors.textPrimary)
                .frame(width: 50, alignment: .leading)
            Text(label)
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(KodomonColors.textSecondary)
        }
    }

    private func streakRow(_ days: String, _ mult: String) -> some View {
        HStack {
            Text(days)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(KodomonColors.textSecondary)
            Spacer()
            Text(mult)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(KodomonColors.purple)
        }
    }
}
