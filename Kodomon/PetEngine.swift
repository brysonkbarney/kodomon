import Foundation
import Combine

@MainActor
class PetEngine: ObservableObject {
    @Published var state: PetState
    @Published var evolutionEvent: (from: Stage, to: Stage)? = nil
    @Published var deEvolutionEvent: (from: Stage, to: Stage)? = nil
    private let watcher: ActivityWatcher
    private var cancellables = Set<AnyCancellable>()
    private var midnightTimer: Timer?
    private var decayTimer: Timer?
    private var activeSessions: [String: Date] = [:]

    deinit {
        midnightTimer?.invalidate()
        decayTimer?.invalidate()
    }

    init(watcher: ActivityWatcher) {
        self.watcher = watcher
        self.state = StateStore.load()

        NSLog("[Kodomon] Engine init — stage: %@, XP: %.0f", state.stage.rawValue, state.totalXP)

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
        if state.neglectState == .ranAway {
            if !state.isReviving {
                state.isReviving = true
                state.revivalSessionStart = Date()
                NSLog("[Kodomon] Revival session started — code for 30 min to bring pet back")
            } else if let start = state.revivalSessionStart {
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
            let wasActive = state.todayIsActive
            markActive()
            activeSessions[sessionId] = timestamp
            persistActiveSessions()

            // First-activity-of-day bonus (only on session start)
            if !wasActive {
                let xp = XPCalculator.applyMultipliers(
                    rawXP: 10,
                    todaySessionMins: state.todaySessionMins,
                    streak: state.currentStreak,
                    mood: state.mood
                )
                addXP(xp)
                addMood(15)
            }

        case .sessionStop(let sessionId, let timestamp):
            if let startTime = activeSessions.removeValue(forKey: sessionId) {
                let minutes = Int(timestamp.timeIntervalSince(startTime) / 60)
                let cappedMins = max(0, min(minutes, 120 - state.todaySessionMins))
                state.todaySessionMins += cappedMins

                let rawXP = XPCalculator.sessionXP(minutes: cappedMins)
                let xp = XPCalculator.applyMultipliers(
                    rawXP: rawXP,
                    todaySessionMins: state.todaySessionMins,
                    streak: state.currentStreak,
                    mood: state.mood
                )
                addXP(xp)
                persistActiveSessions()
                NSLog("[Kodomon] Session %@ ended — %d min, +%.0f XP", sessionId, cappedMins, xp)
            } else {
                NSLog("[Kodomon] Session %@ stop with no matching start — skipped", sessionId)
            }

        case .fileWrite(let path, let linesWritten, _):
            markActive()
            state.totalLinesWritten += linesWritten

            // Track file type for variety bonus
            let ext = (path as NSString).pathExtension.lowercased()
            if !ext.isEmpty {
                state.todayFileTypes.insert(ext)
            }

            // Variety bonus: first time hitting 3+ file types today
            if state.todayFileTypes.count == 3 {
                let xp = XPCalculator.applyMultipliers(
                    rawXP: 20,
                    todaySessionMins: state.todaySessionMins,
                    streak: state.currentStreak,
                    mood: state.mood,
                )
                addXP(xp)
                addMood(6)
            }

            // Only give XP for unique files per day
            let isNewFile = !state.todayFilesWritten.contains(path)
            state.todayFilesWritten.insert(path)

            if isNewFile {
                let xp = XPCalculator.applyMultipliers(
                    rawXP: 3,
                    todaySessionMins: state.todaySessionMins,
                    streak: state.currentStreak,
                    mood: state.mood,
                )
                addXP(xp)
            }
            addMood(isNewFile ? 4 : 1)

            // Lines of code XP (~1 XP per 10 lines)
            let linesRawXP = XPCalculator.linesXP(linesWritten: linesWritten)
            if linesRawXP > 0 {
                let linesXP = XPCalculator.applyMultipliers(
                    rawXP: linesRawXP,
                    todaySessionMins: state.todaySessionMins,
                    streak: state.currentStreak,
                    mood: state.mood,
                )
                addXP(linesXP)
            }

        case .gitCommit(let linesAdded, let linesRemoved, _, _):
            markActive()
            state.totalCommits += 1

            let totalLines = linesAdded + linesRemoved
            state.biggestCommitLines = max(state.biggestCommitLines, totalLines)

            addMood(8)

            // Tiered commit XP based on size; flat 25 if no diff stats available
            let rawXP = totalLines > 0
                ? XPCalculator.commitXP(linesAdded: linesAdded, linesRemoved: linesRemoved)
                : 25.0
            let xp = XPCalculator.applyMultipliers(
                rawXP: rawXP,
                todaySessionMins: state.todaySessionMins,
                streak: state.currentStreak,
                mood: state.mood
            )
            addXP(xp)
        }

        state.neglectState = .none
        save()
        NSLog("[Kodomon] State saved — XP: %.0f, mood: %.0f", state.totalXP, state.mood)
    }

    // MARK: - XP & Mood

    private func addXP(_ amount: Double) {
        guard amount > 0 else { return }
        var xp = amount

        // Active event modifiers
        if let event = state.activeEvent,
           let expiry = state.activeEventExpiry,
           Date() < expiry {
            switch event {
            case .codingStorm: xp *= 2.0
            case .kaniFestival: xp *= 3.0
            case .codeDrought: xp *= 0.5
            default: break
            }
        }

        let oldLifetimeXP = state.lifetimeXP
        state.totalXP += xp
        state.todayXP += xp
        state.lifetimeXP += xp
        checkEvolution()
        checkNewUnlocks(oldXP: oldLifetimeXP, newXP: state.lifetimeXP)
    }

    private func addMood(_ amount: Double) {
        state.mood = min(100, max(0, state.mood + amount))
    }

    private func checkNewUnlocks(oldXP: Double, newXP: Double) {
        let unlocks = UnlockSystem.checkNewUnlocks(oldXP: oldXP, newXP: newXP)
        for bg in unlocks.backgrounds {
            state.unlockedItems.insert(bg.id)
        }
        for acc in unlocks.accessories {
            state.unlockedItems.insert(acc.id)
        }
    }

    private func markActive() {
        NotificationManager.shared.cancelStreakWarning()
        state.lastActiveDate = Date()

        // Mark the day as active on ANY coding event, not just sessionStart
        if !state.todayIsActive {
            state.todayIsActive = true
        }
    }

    // MARK: - Evolution

    private func checkEvolution() {
        guard let next = state.stage.nextStage else { return }

        if state.totalXP >= next.xpThreshold
            && state.activeDays >= next.requiredActiveDays
            && state.currentStreak >= next.requiredStreak {
            let from = state.stage
            state.stage = next
            state.stageReachedDate = Date()
            state.mood = min(100, state.mood + 30)

            // Save as pending — cutscene plays when the user interacts with the widget
            state.pendingEvolutionFrom = from.rawValue
            state.pendingEvolutionTo = next.rawValue

            // Notification fires immediately so the user knows to come back
            NotificationManager.shared.sendEvolutionReadyNotification(petName: state.petName)
            NSLog("[Kodomon] EVOLVED to %@ (pending cutscene)", next.displayName)
        }
    }

    /// Triggers the pending evolution cutscene. Called when the user taps the widget
    /// or the window comes to foreground. No-op if there is no pending evolution.
    func triggerPendingEvolution() {
        guard let fromRaw = state.pendingEvolutionFrom,
              let toRaw = state.pendingEvolutionTo,
              let from = Stage(rawValue: fromRaw),
              let to = Stage(rawValue: toRaw) else { return }

        evolutionEvent = (from: from, to: to)
        state.pendingEvolutionFrom = nil
        state.pendingEvolutionTo = nil
        save()
    }

    func clearEvolutionEvent() {
        evolutionEvent = nil
    }

    func clearDeEvolutionEvent() {
        deEvolutionEvent = nil
    }

    private func revivePet() {
        // Come back one stage lower
        let returnStage = state.stage.previousStage ?? .tamago

        // Set XP to midpoint of return stage's range (but 0 if returning to tamago)
        let midXP: Double
        if returnStage == .tamago {
            midXP = 0
        } else if let next = returnStage.nextStage {
            midXP = (returnStage.xpThreshold + next.xpThreshold) / 2
        } else {
            midXP = returnStage.xpThreshold
        }

        let fromStage = state.stage
        state.stage = returnStage
        state.totalXP = midXP
        state.neglectState = .none
        state.isReviving = false
        state.revivalSessionStart = nil
        state.hasRevived = true
        state.mood = 50
        state.currentStreak = 0
        state.lastActiveDate = Date()

        // Show evolution event (revival feels like a rebirth)
        evolutionEvent = (from: fromStage, to: returnStage)

        NotificationManager.shared.sendEvolutionReadyNotification(petName: state.petName)
        NSLog("[Kodomon] Pet revived as %@! XP: %.0f", returnStage.displayName, midXP)
        save()
    }

    private func checkDeEvolution() {
        guard let prev = state.stage.previousStage else { return }

        if let reached = state.stageReachedDate {
            let daysSinceEvolution = Calendar.current.dateComponents(
                [.day], from: reached, to: Date()
            ).day ?? 0
            if daysSinceEvolution < 3 { return }
        }

        if state.totalXP < state.stage.deEvolveFloor {
            let from = state.stage
            state.stage = prev
            state.stageReachedDate = Date()
            addMood(-20)
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
        let lastReset = state.lastMidnightReset

        let missedDays = cal.dateComponents([.day], from: lastReset, to: today).day ?? 0
        if missedDays <= 0 { return }

        // Credit the day that was in progress when we missed midnight
        if state.todayIsActive {
            state.activeDays += 1
            state.currentStreak += 1
            state.longestStreak = max(state.longestStreak, state.currentStreak)
        }

        // Any gap days (days with zero activity) reset the streak and apply decay
        // If user was active yesterday and only 1 midnight missed, there's no gap
        let gapDays = state.todayIsActive ? missedDays - 1 : missedDays
        if gapDays > 0 {
            state.currentStreak = 0
            applyDecay(daysMissed: gapDays)
        }

        // Apply mood regression toward 50 (same as performMidnightReset)
        for _ in 0..<missedDays {
            let moodDelta = (50 - state.mood) * 0.3
            state.mood = min(100, max(0, state.mood + moodDelta))
        }

        state.daysAlive += missedDays
        state.todayXP = 0
        state.todaySessionMins = 0
        state.todayFileTypes = []
        state.todayFilesWritten = []
        state.todayIsActive = false
        state.lastMidnightReset = today
        checkEvolution()
        checkDeEvolution()
        save()
    }

    private func performMidnightReset() {
        if state.todayIsActive {
            state.activeDays += 1
            state.currentStreak += 1
            state.longestStreak = max(state.longestStreak, state.currentStreak)
        } else {
            state.currentStreak = 0
            applyDecay(daysMissed: 1)
        }

        state.daysAlive += 1
        state.todayXP = 0
        state.todaySessionMins = 0
        state.todayFileTypes = []
        state.todayFilesWritten = []
        state.todayIsActive = false

        let moodDelta = (50 - state.mood) * 0.3
        state.mood += moodDelta

        state.lastMidnightReset = Calendar.current.startOfDay(for: Date())

        // Schedule streak warning if applicable
        if state.currentStreak >= 3 {
            NotificationManager.shared.scheduleStreakWarning(currentStreak: state.currentStreak, petName: state.petName)
        }

        // Clear yesterday's event, roll for today
        state.activeEvent = nil
        state.activeEventExpiry = nil
        if let event = RandomEventEngine.rollDailyEvent(
            currentStreak: state.currentStreak,
            stage: state.stage
        ) {
            state.activeEvent = event
            // Most events last all day, timed ones get specific expiry
            switch event {
            case .codingStorm:
                state.activeEventExpiry = Date().addingTimeInterval(3600) // 60 min
            case .flowState:
                state.activeEventExpiry = Date().addingTimeInterval(2700) // 45 min
            default:
                state.activeEventExpiry = Calendar.current.date(
                    byAdding: .day, value: 1,
                    to: Calendar.current.startOfDay(for: Date())
                )
            }
            RandomEventEngine.applyEvent(event, to: &state)
        }

        checkEvolution()
        checkDeEvolution()
        rotateEventsLog()
        save()

        NSLog("[Kodomon] Midnight reset — Day %d, Streak: %d", state.daysAlive, state.currentStreak)
    }

    // MARK: - Decay

    private func startDecayTimer() {
        decayTimer = Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { [weak self] _ in
            self?.updateNeglectState()
        }
    }

    private func updateNeglectState() {
        let elapsed = Date().timeIntervalSince(state.lastActiveDate)
        let hours = elapsed / 3600
        let oldState = state.neglectState

        let daysMissed = Calendar.current.dateComponents([.day], from: state.lastActiveDate, to: Date()).day ?? 0
        if daysMissed >= 7 {
            state.neglectState = .ranAway
            state.mood = 0
        } else if daysMissed >= 5 {
            state.neglectState = .critical
        } else if daysMissed >= 2 {
            state.neglectState = .sick
        } else if daysMissed >= 1 {
            state.neglectState = .sad
        } else if hours >= 8 {
            state.neglectState = .tired
        }

        // Send notifications on state transitions
        if state.neglectState != oldState {
            switch state.neglectState {
            case .tired:
                NotificationManager.shared.sendTiredNotification(petName: state.petName)
            case .sick:
                NotificationManager.shared.sendSickNotification(petName: state.petName)
            case .critical:
                NotificationManager.shared.sendCriticalNotification(petName: state.petName)
            case .ranAway:
                NotificationManager.shared.sendPetRanAwayNotification(petName: state.petName)
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
        switch daysMissed {
        case 1:
            state.totalXP *= 0.97
            state.neglectState = .sad
            addMood(-20)
        case 2...4:
            state.totalXP *= 0.92
            state.neglectState = .sick
            addMood(-25)
            NotificationManager.shared.sendSickNotification(petName: state.petName)
        case 5...6:
            state.totalXP *= 0.85
            state.neglectState = .critical
            addMood(-30)
            NotificationManager.shared.sendCriticalNotification(petName: state.petName)
        case 7...:
            state.neglectState = .ranAway
            state.mood = 0
            NotificationManager.shared.sendPetRanAwayNotification(petName: state.petName)
        default:
            break
        }

        state.totalXP = max(0, state.totalXP)
    }

    // MARK: - Events

    private func clearExpiredEvent() {
        if let expiry = state.activeEventExpiry, Date() >= expiry {
            state.activeEvent = nil
            state.activeEventExpiry = nil
            save()
        }
    }

    // MARK: - JSONL log rotation

    private func rotateEventsLog() {
        let path = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".kodomon/events.jsonl")
        try? "".write(to: path, atomically: true, encoding: .utf8)
        watcher.resetOffset()
        NSLog("[Kodomon] Events log rotated")
    }

    // MARK: - Persistence

    private func save() {
        StateStore.save(state)
    }

    private func persistActiveSessions() {
        let dict = activeSessions.mapValues { $0.timeIntervalSince1970 }
        UserDefaults.standard.set(dict, forKey: "kodomonActiveSessions")
    }

    private func restoreActiveSessions() {
        guard let dict = UserDefaults.standard.dictionary(forKey: "kodomonActiveSessions") as? [String: Double] else { return }
        let cutoff = Date().addingTimeInterval(-86400) // 24h
        let restored = dict.mapValues { Date(timeIntervalSince1970: $0) }
            .filter { $0.value > cutoff }
        activeSessions = restored
        if restored.count != dict.count {
            NSLog("[Kodomon] Pruned %d stale session(s)", dict.count - restored.count)
            persistActiveSessions()
        }
        NSLog("[Kodomon] Restored %d active session(s)", activeSessions.count)
    }
}
