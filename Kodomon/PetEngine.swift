import Foundation
import Combine

@MainActor
class PetEngine: ObservableObject {
    @Published var player: PlayerState
    @Published var evolutionEvent: (from: Stage, to: Stage)? = nil
    @Published var deEvolutionEvent: (from: Stage, to: Stage)? = nil
    private let watcher: ActivityWatcher
    private var cancellables = Set<AnyCancellable>()
    private var midnightTimer: Timer?
    private var decayTimer: Timer?
    private var activeSessions: [String: Date] = [:]
    private var lastCreditedTime: [String: Date] = [:]

    // MARK: - Convenience accessors

    /// The currently active Kodomon. Get and set both route through
    /// `player.collection` so writes fire the `@Published` update on `player`.
    var activeKodomon: KodomonState {
        get { player.activeKodomon }
        set { player.activeKodomon = newValue }
    }

    deinit {
        midnightTimer?.invalidate()
        decayTimer?.invalidate()
    }

    init(watcher: ActivityWatcher) {
        self.watcher = watcher
        self.player = StateStore.load()

        NSLog("[Kodomon] Engine init — stage: %@, species XP: %.0f, lifetime XP: %.0f",
              activeKodomon.stage.rawValue, activeKodomon.speciesXP, player.lifetimeXP)

        restoreActiveSessions()
        checkMissedMidnights()

        watcher.eventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleEvent(event)
            }
            .store(in: &cancellables)

        clearExpiredEvent()
        scheduleMidnightReset()
        startDecayTimer()
    }

    // MARK: - Wake from sleep

    func handleWake() {
        checkMissedMidnights()
        clearExpiredEvent()
        updateNeglectState()
        scheduleMidnightReset()
    }

    // MARK: - Event Handling

    private func handleEvent(_ event: ActivityEvent) {
        NSLog("[Kodomon] Handling event")

        // Revival mechanic — if pet ran away, start revival session
        if activeKodomon.neglectState == .ranAway {
            if !player.isReviving {
                player.isReviving = true
                player.revivalSessionStart = Date()
                NSLog("[Kodomon] Revival session started — code for 30 min to bring pet back")
            } else if let start = player.revivalSessionStart {
                let minutes = Date().timeIntervalSince(start) / 60
                if minutes >= 30 {
                    revivePet()
                }
            }
            save()
            return  // Don't process normal XP while reviving
        }

        switch event {
        case .sessionStart(let sessionId, _, let timestamp):
            let wasActive = player.todayIsActive
            markActive()
            activeSessions[sessionId] = timestamp
            lastCreditedTime[sessionId] = timestamp
            persistActiveSessions()

            // First-activity-of-day bonus (only on session start)
            if !wasActive {
                let xp = XPCalculator.applyMultipliers(
                    rawXP: 10,
                    todaySessionMins: player.todaySessionMins,
                    streak: player.currentStreak,
                    mood: activeKodomon.mood
                )
                addXP(xp)
                addMood(15)
            }

        case .sessionStop(let sessionId, let timestamp):
            // Use lastCreditedTime to calculate only NEW minutes since last stop
            let creditFrom = lastCreditedTime[sessionId] ?? activeSessions[sessionId]
            if let from = creditFrom {
                let minutes = Int(timestamp.timeIntervalSince(from) / 60)
                let cappedMins = max(0, min(minutes, 120 - player.todaySessionMins))
                if cappedMins > 0 {
                    player.todaySessionMins += cappedMins
                    player.totalSessionMins += cappedMins
                    let rawXP = XPCalculator.sessionXP(minutes: cappedMins)
                    let xp = XPCalculator.applyMultipliers(
                        rawXP: rawXP,
                        todaySessionMins: player.todaySessionMins,
                        streak: player.currentStreak,
                        mood: activeKodomon.mood
                    )
                    addXP(xp)
                    NSLog("[Kodomon] Session %@ — +%d min, +%.0f XP", sessionId, cappedMins, xp)
                }
                lastCreditedTime[sessionId] = timestamp
                persistActiveSessions()
            } else {
                NSLog("[Kodomon] Session %@ stop with no matching start — skipped", sessionId)
            }

        case .fileWrite(let path, let linesWritten, _):
            markActive()
            player.totalLinesWritten += linesWritten

            // Track file type for variety bonus
            let ext = (path as NSString).pathExtension.lowercased()
            if !ext.isEmpty {
                player.todayFileTypes.insert(ext)
            }

            // Variety bonus: first time hitting 3+ file types today
            if player.todayFileTypes.count == 3 {
                let xp = XPCalculator.applyMultipliers(
                    rawXP: 20,
                    todaySessionMins: player.todaySessionMins,
                    streak: player.currentStreak,
                    mood: activeKodomon.mood
                )
                addXP(xp)
                addMood(6)
            }

            // Only give XP for unique files per day
            let isNewFile = !player.todayFilesWritten.contains(path)
            player.todayFilesWritten.insert(path)

            if isNewFile {
                let xp = XPCalculator.applyMultipliers(
                    rawXP: 3,
                    todaySessionMins: player.todaySessionMins,
                    streak: player.currentStreak,
                    mood: activeKodomon.mood
                )
                addXP(xp)
            }
            addMood(isNewFile ? 4 : 1)

            // Lines of code XP (~1 XP per 10 lines)
            let linesRawXP = XPCalculator.linesXP(linesWritten: linesWritten)
            if linesRawXP > 0 {
                let linesXP = XPCalculator.applyMultipliers(
                    rawXP: linesRawXP,
                    todaySessionMins: player.todaySessionMins,
                    streak: player.currentStreak,
                    mood: activeKodomon.mood
                )
                addXP(linesXP)
            }

        case .gitCommit(let linesAdded, let linesRemoved, _, _):
            markActive()
            player.totalCommits += 1
            player.todayCommitCount += 1

            let totalLines = linesAdded + linesRemoved
            player.biggestCommitLines = max(player.biggestCommitLines, totalLines)

            addMood(8)

            // Tiered commit XP based on size; flat 25 if no diff stats available
            let rawXP = totalLines > 0
                ? XPCalculator.commitXP(linesAdded: linesAdded, linesRemoved: linesRemoved)
                : 25.0
            let xp = XPCalculator.applyMultipliers(
                rawXP: rawXP,
                todaySessionMins: player.todaySessionMins,
                streak: player.currentStreak,
                mood: activeKodomon.mood
            )
            addXP(xp)
        }

        // Clear neglect state on any activity
        var kodomon = activeKodomon
        kodomon.neglectState = .none
        activeKodomon = kodomon

        // Evaluate species-discovery triggers against this event.
        // Only post-arming events count — historical activity never fires triggers.
        evaluateTriggers(for: event)

        save()
        NSLog("[Kodomon] State saved — species XP: %.0f, mood: %.0f",
              activeKodomon.speciesXP, activeKodomon.mood)
    }

    // MARK: - XP & Mood

    private func addXP(_ amount: Double) {
        guard amount > 0 else { return }
        var xp = amount

        // Active event modifiers
        if let event = player.activeEvent,
           let expiry = player.activeEventExpiry,
           Date() < expiry {
            switch event {
            case .codingStorm: xp *= 2.0
            case .kaniFestival: xp *= 3.0
            case .codeDrought: xp *= 0.5
            default: break
            }
        }

        let oldLifetimeXP = player.lifetimeXP

        // Credit both layers: species XP (active Kodomon only) + lifetime XP (always)
        var kodomon = activeKodomon
        kodomon.speciesXP += xp
        activeKodomon = kodomon

        player.todayXP += xp
        player.lifetimeXP += xp

        // Head of the pending egg queue accumulates incubation XP alongside
        // the active Kodomon's species XP. Only the head incubates.
        // Hatching is NOT automatic — the user must explicitly click Hatch
        // in the Collection tab once the egg reaches the ready state.
        if !player.pendingEggs.isEmpty {
            player.pendingEggs[0].incubationXP += xp
        }

        checkEvolution()
        checkNewUnlocks(oldXP: oldLifetimeXP, newXP: player.lifetimeXP)
    }

    private func addMood(_ amount: Double) {
        var kodomon = activeKodomon
        kodomon.mood = min(100, max(0, kodomon.mood + amount))
        activeKodomon = kodomon
    }

    private func checkNewUnlocks(oldXP: Double, newXP: Double) {
        let unlocks = UnlockSystem.checkNewUnlocks(oldXP: oldXP, newXP: newXP)
        for bg in unlocks.backgrounds {
            player.unlockedItems.insert(bg.id)
        }
        for acc in unlocks.accessories {
            player.unlockedItems.insert(acc.id)
        }
    }

    private func markActive() {
        NotificationManager.shared.cancelStreakWarning()
        let now = Date()
        player.lastActiveDate = now

        // Mark the day as active on ANY coding event, not just sessionStart
        if !player.todayIsActive {
            player.todayIsActive = true
        }

        // Bump the active Kodomon's per-creature clock so decay math stays correct
        var kodomon = activeKodomon
        kodomon.lastActiveWhileEquipped = now
        activeKodomon = kodomon
    }

    // MARK: - Evolution

    private func checkEvolution() {
        let kodomon = activeKodomon
        guard let next = kodomon.stage.nextStage else { return }
        let rarity = kodomon.rarity
        let xpThreshold = rarity.xpThreshold(for: next)

        if kodomon.speciesXP >= xpThreshold
            && kodomon.activeDays >= next.requiredActiveDays
            && player.currentStreak >= next.requiredStreak {
            let from = kodomon.stage
            var updated = kodomon
            updated.stage = next
            updated.stageReachedDate = Date()
            updated.mood = min(100, updated.mood + 30)
            // Save as pending — cutscene plays when the user interacts with the widget
            updated.pendingEvolutionFrom = from.rawValue
            updated.pendingEvolutionTo = next.rawValue
            activeKodomon = updated

            // Notification fires immediately so the user knows to come back
            NotificationManager.shared.sendEvolutionReadyNotification(petName: updated.name)
            LeaderboardService.shared.sync(player: player, force: true)
            NSLog("[Kodomon] EVOLVED to %@ (pending cutscene)", next.displayName)

            // Evolution-based species triggers (e.g. Graduation on first Kamisama)
            fireStageReachedTriggersIfNeeded(stage: next)
        }
    }

    /// Triggers the pending evolution cutscene. Called when the user taps the widget
    /// or the window comes to foreground. No-op if there is no pending evolution.
    func triggerPendingEvolution() {
        let kodomon = activeKodomon
        guard let fromRaw = kodomon.pendingEvolutionFrom,
              let toRaw = kodomon.pendingEvolutionTo,
              let from = Stage(rawValue: fromRaw),
              let to = Stage(rawValue: toRaw) else { return }

        evolutionEvent = (from: from, to: to)
        var updated = kodomon
        updated.pendingEvolutionFrom = nil
        updated.pendingEvolutionTo = nil
        activeKodomon = updated
        save()
    }

    func clearEvolutionEvent() {
        evolutionEvent = nil
    }

    func clearDeEvolutionEvent() {
        deEvolutionEvent = nil
    }

    private func revivePet() {
        let kodomon = activeKodomon
        // Come back one stage lower
        let returnStage = kodomon.stage.previousStage ?? .tamago
        let rarity = kodomon.rarity

        // Set XP to midpoint of return stage's range (but 0 if returning to tamago)
        let midXP: Double
        if returnStage == .tamago {
            midXP = 0
        } else if let next = returnStage.nextStage {
            midXP = (rarity.xpThreshold(for: returnStage) + rarity.xpThreshold(for: next)) / 2
        } else {
            midXP = rarity.xpThreshold(for: returnStage)
        }

        let fromStage = kodomon.stage
        var updated = kodomon
        updated.stage = returnStage
        updated.speciesXP = midXP
        updated.neglectState = .none
        updated.hasRevived = true
        updated.mood = 50
        activeKodomon = updated

        player.isReviving = false
        player.revivalSessionStart = nil
        player.currentStreak = 0
        player.lastActiveDate = Date()

        // Show evolution event (revival feels like a rebirth)
        evolutionEvent = (from: fromStage, to: returnStage)

        NotificationManager.shared.sendEvolutionReadyNotification(petName: updated.name)
        NSLog("[Kodomon] Pet revived as %@! species XP: %.0f", returnStage.displayName, midXP)
        save()
    }

    private func checkDeEvolution() {
        let kodomon = activeKodomon
        guard let prev = kodomon.stage.previousStage else { return }
        let rarity = kodomon.rarity

        if let reached = kodomon.stageReachedDate {
            let daysSinceEvolution = Calendar.current.dateComponents(
                [.day], from: reached, to: Date()
            ).day ?? 0
            if daysSinceEvolution < 3 { return }
        }

        if kodomon.speciesXP < rarity.deEvolveFloor(for: kodomon.stage) {
            let from = kodomon.stage
            var updated = kodomon
            updated.stage = prev
            updated.stageReachedDate = Date()
            updated.mood = max(0, updated.mood - 20)
            activeKodomon = updated
            deEvolutionEvent = (from: from, to: prev)
            NSLog("[Kodomon] DE-EVOLVED to %@", prev.displayName)
        }
    }

    // MARK: - Midnight Reset

    private func scheduleMidnightReset() {
        midnightTimer?.invalidate()

        let cal = Calendar.current
        guard let tomorrow = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: Date())) else { return }
        let interval = tomorrow.timeIntervalSinceNow

        midnightTimer = Timer.scheduledTimer(withTimeInterval: max(1, interval), repeats: false) { [weak self] _ in
            self?.performMidnightReset()
            self?.scheduleMidnightReset()
        }
    }

    private func checkMissedMidnights() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let lastReset = player.lastMidnightReset

        let missedDays = cal.dateComponents([.day], from: lastReset, to: today).day ?? 0
        if missedDays <= 0 { return }

        // Credit the day that was in progress when we missed midnight
        if player.todayIsActive {
            var kodomon = activeKodomon
            kodomon.activeDays += 1
            activeKodomon = kodomon

            player.currentStreak += 1
            player.longestStreak = max(player.longestStreak, player.currentStreak)

            // Incubation active-days clock advances only on player-active days.
            // Hatching stays manual — no auto-hatch on day rollover either.
            if !player.pendingEggs.isEmpty {
                player.pendingEggs[0].incubationActiveDays += 1
            }
        }

        // Any gap days (days with zero activity) reset the streak and apply decay
        // If user was active yesterday and only 1 midnight missed, there's no gap
        let gapDays = player.todayIsActive ? missedDays - 1 : missedDays
        if gapDays > 0 {
            player.currentStreak = 0
            applyDecay(daysMissed: gapDays)
        }

        // Apply mood regression toward 50 (same as performMidnightReset)
        var kodomon = activeKodomon
        for _ in 0..<missedDays {
            let moodDelta = (50 - kodomon.mood) * 0.3
            kodomon.mood = min(100, max(0, kodomon.mood + moodDelta))
        }
        kodomon.daysAlive += missedDays
        activeKodomon = kodomon

        player.todayXP = 0
        player.todaySessionMins = 0
        player.todayFileTypes = []
        player.todayFilesWritten = []
        player.todayIsActive = false
        player.todayCommitCount = 0
        player.lastMidnightReset = today
        checkEvolution()
        checkDeEvolution()
        LeaderboardService.shared.sync(player: player, force: true)
        save()
    }

    private func performMidnightReset() {
        if player.todayIsActive {
            var kodomon = activeKodomon
            kodomon.activeDays += 1
            activeKodomon = kodomon

            player.currentStreak += 1
            player.longestStreak = max(player.longestStreak, player.currentStreak)

            // Incubation active-days clock advances only on player-active days.
            // Hatching stays manual — no auto-hatch on day rollover.
            if !player.pendingEggs.isEmpty {
                player.pendingEggs[0].incubationActiveDays += 1
            }
        } else {
            player.currentStreak = 0
            applyDecay(daysMissed: 1)
        }

        var kodomon = activeKodomon
        kodomon.daysAlive += 1
        let moodDelta = (50 - kodomon.mood) * 0.3
        kodomon.mood += moodDelta
        activeKodomon = kodomon

        player.todayXP = 0
        player.todaySessionMins = 0
        player.todayFileTypes = []
        player.todayFilesWritten = []
        player.todayIsActive = false
        player.todayCommitCount = 0

        player.lastMidnightReset = Calendar.current.startOfDay(for: Date())

        // Schedule streak warning if applicable
        if player.currentStreak >= 3 {
            NotificationManager.shared.scheduleStreakWarning(currentStreak: player.currentStreak, petName: activeKodomon.name)
        }

        // Clear yesterday's event, roll for today
        player.activeEvent = nil
        player.activeEventExpiry = nil
        if let event = RandomEventEngine.rollDailyEvent(
            currentStreak: player.currentStreak,
            stage: activeKodomon.stage
        ) {
            player.activeEvent = event
            // Most events last all day, timed ones get specific expiry
            switch event {
            case .codingStorm:
                player.activeEventExpiry = Date().addingTimeInterval(3600) // 60 min
            case .flowState:
                player.activeEventExpiry = Date().addingTimeInterval(2700) // 45 min
            default:
                player.activeEventExpiry = Calendar.current.date(
                    byAdding: .day, value: 1,
                    to: Calendar.current.startOfDay(for: Date())
                )
            }
            var target = activeKodomon
            RandomEventEngine.applyEvent(event, to: &target)
            activeKodomon = target
        }

        checkEvolution()
        checkDeEvolution()
        rotateEventsLog()
        save()

        LeaderboardService.shared.sync(player: player, force: true)
        NSLog("[Kodomon] Midnight reset — Day %d, Streak: %d", activeKodomon.daysAlive, player.currentStreak)
    }

    // MARK: - Decay

    private func startDecayTimer() {
        decayTimer = Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { [weak self] _ in
            self?.updateNeglectState()
        }
    }

    private func updateNeglectState() {
        let kodomon = activeKodomon
        let elapsed = Date().timeIntervalSince(player.lastActiveDate)
        let hours = elapsed / 3600
        let oldState = kodomon.neglectState

        let daysMissed = Calendar.current.dateComponents([.day], from: player.lastActiveDate, to: Date()).day ?? 0
        var updated = kodomon
        if daysMissed >= 7 {
            updated.neglectState = .ranAway
            updated.mood = 0
        } else if daysMissed >= 5 {
            updated.neglectState = .critical
        } else if daysMissed >= 2 {
            updated.neglectState = .sick
        } else if daysMissed >= 1 {
            updated.neglectState = .sad
        } else if hours >= 8 {
            updated.neglectState = .tired
        }
        activeKodomon = updated

        // Send notifications on state transitions
        if updated.neglectState != oldState {
            switch updated.neglectState {
            case .tired:
                NotificationManager.shared.sendTiredNotification(petName: updated.name)
            case .sick:
                NotificationManager.shared.sendSickNotification(petName: updated.name)
            case .critical:
                NotificationManager.shared.sendCriticalNotification(petName: updated.name)
            case .ranAway:
                NotificationManager.shared.sendPetRanAwayNotification(petName: updated.name)
            case .sad, .none:
                break
            }
        }

        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 9 && hour <= 22 && hours >= 1 {
            addMood(-1)
        }

        save()
    }

    private func applyDecay(daysMissed: Int) {
        var kodomon = activeKodomon
        switch daysMissed {
        case 1:
            kodomon.speciesXP *= 0.97
            kodomon.neglectState = .sad
            kodomon.mood = max(0, kodomon.mood - 20)
        case 2...4:
            kodomon.speciesXP *= 0.92
            kodomon.neglectState = .sick
            kodomon.mood = max(0, kodomon.mood - 25)
            NotificationManager.shared.sendSickNotification(petName: kodomon.name)
        case 5...6:
            kodomon.speciesXP *= 0.85
            kodomon.neglectState = .critical
            kodomon.mood = max(0, kodomon.mood - 30)
            NotificationManager.shared.sendCriticalNotification(petName: kodomon.name)
        case 7...:
            kodomon.neglectState = .ranAway
            kodomon.mood = 0
            NotificationManager.shared.sendPetRanAwayNotification(petName: kodomon.name)
        default:
            break
        }

        kodomon.speciesXP = max(0, kodomon.speciesXP)
        activeKodomon = kodomon
    }

    // MARK: - Events

    private func clearExpiredEvent() {
        if let expiry = player.activeEventExpiry, Date() >= expiry {
            player.activeEvent = nil
            player.activeEventExpiry = nil
            save()
        }
    }

    // MARK: - JSONL log rotation

    private func rotateEventsLog() {
        let path = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".kodomon/events.jsonl").path
        // Truncate in place to preserve the file inode — atomic write replaces
        // the inode which breaks the DispatchSource file watcher
        if let fh = FileHandle(forWritingAtPath: path) {
            fh.truncateFile(atOffset: 0)
            fh.closeFile()
        }
        watcher.resetOffset()
        NSLog("[Kodomon] Events log rotated")
    }

    // MARK: - Species triggers (Phase 2)

    /// Evaluate every species-discovery trigger against the given event and
    /// fire any that match. Respects `triggersArmedAt` — events with
    /// timestamps earlier than arming never fire triggers (protects against
    /// historical activity on v1 migration and against clock-skew edge cases).
    private func evaluateTriggers(for event: ActivityEvent) {
        let eventTimestamp = timestamp(of: event)
        guard eventTimestamp >= player.triggersArmedAt else { return }

        for species in SpeciesCatalog.all {
            guard !player.triggersFired.contains(species.id) else { continue }
            if triggerMatches(species.trigger, event: event) {
                fireTrigger(for: species)
            }
        }
    }

    /// Check whether a species trigger matches the given event.
    /// `.defaultStarter` and `.anyKodomonReachesStage` are never matched
    /// here — starter is bootstrap-only, graduation is evaluated in
    /// `fireStageReachedTriggersIfNeeded` during evolution.
    private func triggerMatches(_ trigger: SpeciesTrigger, event: ActivityEvent) -> Bool {
        switch trigger {
        case .defaultStarter, .anyKodomonReachesStage:
            return false

        case .commitsInDay(let count):
            if case .gitCommit = event {
                return player.todayCommitCount >= count
            }
            return false

        case .distinctExtensionsInDay(let count):
            if case .fileWrite = event {
                return player.todayFileTypes.count >= count
            }
            return false

        case .sessionCrossesMidnight:
            if case .sessionStop(let sessionId, let stopTime) = event,
               let startTime = activeSessions[sessionId] {
                return sessionStraddlesMidnight(start: startTime, end: stopTime)
            }
            return false

        case .commitDeletionsExceedInsertions:
            if case .gitCommit(let linesAdded, let linesRemoved, _, _) = event {
                // Must have actually deleted something — an empty commit shouldn't count.
                return linesRemoved > linesAdded && linesRemoved > 0
            }
            return false
        }
    }

    /// Fire evolution-stage triggers for all species that watch for this
    /// stage transition. Currently only `.anyKodomonReachesStage(.kamisama)`
    /// matters (Graduation), but the loop is data-driven so future species
    /// can plug in without more case analysis.
    private func fireStageReachedTriggersIfNeeded(stage: Stage) {
        guard Date() >= player.triggersArmedAt else { return }

        for species in SpeciesCatalog.all {
            guard !player.triggersFired.contains(species.id) else { continue }
            if case .anyKodomonReachesStage(let target) = species.trigger, target == stage {
                fireTrigger(for: species)
            }
        }
    }

    /// Record that a species trigger has fired, append a new pending egg
    /// to the queue, and notify the user. The notification deliberately
    /// does NOT reveal the species — that reveal is saved for hatching.
    private func fireTrigger(for species: SpeciesDefinition) {
        player.triggersFired.insert(species.id)
        let egg = PendingEgg.newlyTriggered(speciesID: species.id)
        player.pendingEggs.append(egg)
        NSLog("[Kodomon] Trigger fired: %@ — egg queued (%d in queue)",
              species.displayName, player.pendingEggs.count)
        NotificationManager.shared.sendEggDiscoveredNotification()
    }

    /// Whether the head of the pending-egg queue meets all rarity-scaled
    /// hatching requirements. UI reads this to decide whether to show an
    /// active "Hatch" button.
    var headEggIsReady: Bool {
        guard let head = player.pendingEggs.first else { return false }
        guard let species = head.species else { return false }
        let rarity = species.rarity
        return head.incubationXP >= rarity.hatchXP
            && head.incubationActiveDays >= rarity.hatchActiveDays
            && player.currentStreak >= rarity.hatchStreak
    }

    /// Fractional incubation progress (0.0 to 1.0) for the head egg, using
    /// the minimum of all three dimensions (XP, active days, streak) so the
    /// bar only advances when every requirement is progressing. UI-ready —
    /// rarity-agnostic so it doesn't leak what's in the egg.
    var headEggProgress: Double {
        guard let head = player.pendingEggs.first else { return 0 }
        guard let species = head.species else { return 0 }
        let rarity = species.rarity
        let xpFrac = min(1.0, head.incubationXP / rarity.hatchXP)
        let daysFrac = rarity.hatchActiveDays == 0
            ? 1.0
            : min(1.0, Double(head.incubationActiveDays) / Double(rarity.hatchActiveDays))
        let streakFrac = rarity.hatchStreak == 0
            ? 1.0
            : min(1.0, Double(player.currentStreak) / Double(rarity.hatchStreak))
        return min(xpFrac, daysFrac, streakFrac)
    }

    /// Swap the active Kodomon to the one with the given id. The old active
    /// is frozen in place; the new active starts earning species XP from the
    /// next event. No-op if the id isn't in the collection or is already
    /// active. Bumps the new active's `lastActiveWhileEquipped` timestamp so
    /// decay math starts fresh from the moment of the swap.
    func setActive(kodomonID: UUID) {
        guard kodomonID != player.activeKodomonID else { return }
        guard let idx = player.collection.firstIndex(where: { $0.id == kodomonID }) else {
            NSLog("[Kodomon] setActive: id %@ not in collection", kodomonID.uuidString)
            return
        }
        let oldName = activeKodomon.name
        player.activeKodomonID = kodomonID
        player.collection[idx].lastActiveWhileEquipped = Date()
        NSLog("[Kodomon] Deployed %@ (was %@)", player.collection[idx].name, oldName)
        save()
    }

    /// User-initiated hatch of the head egg. No-op if the queue is empty
    /// or the head isn't ready yet. Called by the Kodex tab's Hatch
    /// button — hatching is never automatic.
    func hatchHeadEggIfReady() {
        guard headEggIsReady else { return }
        guard let head = player.pendingEggs.first,
              let species = head.species else {
            // Stale entry (species was removed in a future version) —
            // drop it so the queue isn't blocked forever.
            if !player.pendingEggs.isEmpty {
                NSLog("[Kodomon] Dropping pending egg with unknown speciesID")
                player.pendingEggs.removeFirst()
                save()
            }
            return
        }
        hatchHeadEgg(species: species)
        save()
    }

    /// Pop the head of the queue and create the new Kodomon in the collection.
    private func hatchHeadEgg(species: SpeciesDefinition) {
        player.pendingEggs.removeFirst()

        let name = NameGenerator.names.randomElement() ?? "Kodomon"
        let newKodomon = KodomonState.fresh(speciesID: species.id, name: name)
        player.collection.append(newKodomon)

        NSLog("[Kodomon] Egg hatched: %@ the %@ (collection size %d)",
              newKodomon.name, species.displayName, player.collection.count)
        NotificationManager.shared.sendEggHatchedNotification(
            speciesName: species.displayName,
            kodomonName: newKodomon.name
        )
    }

    // MARK: - Trigger helpers

    /// Extract a timestamp from any ActivityEvent case.
    private func timestamp(of event: ActivityEvent) -> Date {
        switch event {
        case .sessionStart(_, _, let ts): return ts
        case .sessionStop(_, let ts): return ts
        case .fileWrite(_, _, let ts): return ts
        case .gitCommit(_, _, _, let ts): return ts
        }
    }

    /// True if a session's start and stop straddle local midnight
    /// (start before midnight, end at/after midnight of the same rollover).
    private func sessionStraddlesMidnight(start: Date, end: Date) -> Bool {
        let cal = Calendar.current
        // The midnight boundary that falls between start and end, if any.
        // Walk forward from the start day's next midnight and check.
        guard let nextMidnight = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: start)) else {
            return false
        }
        return start < nextMidnight && end >= nextMidnight
    }

    // MARK: - Debug affordances

    #if DEBUG
    /// Force-fire the discovery trigger for a given species id — useful to
    /// test the pending-egg pipeline without waiting for a real match.
    /// No-op if the species is already in `triggersFired` or if the id is
    /// unknown. Respects the same side effects as a natural trigger fire.
    func debugForceFireTrigger(speciesID: String) {
        guard let species = SpeciesCatalog.definition(forID: speciesID) else {
            NSLog("[Kodomon] debugForceFireTrigger: unknown species %@", speciesID)
            return
        }
        guard !player.triggersFired.contains(species.id) else {
            NSLog("[Kodomon] debugForceFireTrigger: %@ already fired", species.id)
            return
        }
        fireTrigger(for: species)
        save()
    }

    /// Instantly hatch the head of the pending-egg queue, bypassing
    /// rarity-scaled incubation requirements. No-op if the queue is empty.
    func debugInstantHatchHeadEgg() {
        guard let head = player.pendingEggs.first else {
            NSLog("[Kodomon] debugInstantHatchHeadEgg: queue empty")
            return
        }
        guard let species = head.species else {
            NSLog("[Kodomon] debugInstantHatchHeadEgg: unknown species %@", head.speciesID)
            player.pendingEggs.removeFirst()
            save()
            return
        }
        hatchHeadEgg(species: species)
        save()
    }
    #endif

    // MARK: - Persistence

    private func save() {
        StateStore.save(player)
    }

    private func persistActiveSessions() {
        let dict = activeSessions.mapValues { $0.timeIntervalSince1970 }
        UserDefaults.standard.set(dict, forKey: "kodomonActiveSessions")
        let credited = lastCreditedTime.mapValues { $0.timeIntervalSince1970 }
        UserDefaults.standard.set(credited, forKey: "kodomonLastCreditedTime")
    }

    private func restoreActiveSessions() {
        guard let dict = UserDefaults.standard.dictionary(forKey: "kodomonActiveSessions") as? [String: Double] else { return }
        let cutoff = Date().addingTimeInterval(-86400) // 24h
        let restored = dict.mapValues { Date(timeIntervalSince1970: $0) }
            .filter { $0.value > cutoff }
        activeSessions = restored
        if let credited = UserDefaults.standard.dictionary(forKey: "kodomonLastCreditedTime") as? [String: Double] {
            lastCreditedTime = credited.mapValues { Date(timeIntervalSince1970: $0) }
                .filter { restored.keys.contains($0.key) }
        }
        if restored.count != dict.count {
            NSLog("[Kodomon] Pruned %d stale session(s)", dict.count - restored.count)
            persistActiveSessions()
        }
        NSLog("[Kodomon] Restored %d active session(s)", activeSessions.count)
    }
}
