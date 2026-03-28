import Foundation
import Combine

@MainActor
class PetEngine: ObservableObject {
    @Published var state: PetState
    private let watcher: ActivityWatcher
    private var cancellables = Set<AnyCancellable>()
    private var midnightTimer: Timer?
    private var decayTimer: Timer?
    private var activeSessions: [String: Date] = [:]

    init(watcher: ActivityWatcher) {
        self.watcher = watcher
        self.state = StateStore.load()

        NSLog("[Kodomon] Engine init — stage: %@, XP: %.0f", state.stage.rawValue, state.totalXP)

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

        switch event {
        case .sessionStart(let sessionId, _, let timestamp):
            markActive()
            activeSessions[sessionId] = timestamp

            if !state.todayIsActive {
                let xp = XPCalculator.applyMultipliers(
                    rawXP: 10,
                    todaySessionMins: state.todaySessionMins,
                    streak: state.currentStreak,
                    mood: state.mood,
                    todayXP: state.todayXP
                )
                addXP(xp)
                addMood(15)
                state.todayIsActive = true
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
                    mood: state.mood,
                    todayXP: state.todayXP
                )
                addXP(xp)
                NSLog("[Kodomon] Session %@ ended — %d min, +%.0f XP", sessionId, cappedMins, xp)
            }

        case .fileWrite(let path, _):
            markActive()

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
                    todayXP: state.todayXP
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
                    todayXP: state.todayXP
                )
                addXP(xp)
            }
            addMood(isNewFile ? 4 : 1)

        case .gitCommit(_, let added, let removed, _, _):
            markActive()

            let rawXP = XPCalculator.commitXP(linesAdded: added, linesRemoved: removed)
            let xp = XPCalculator.applyMultipliers(
                rawXP: rawXP,
                todaySessionMins: state.todaySessionMins,
                streak: state.currentStreak,
                mood: state.mood,
                todayXP: state.todayXP
            )
            addXP(xp)
            addMood(8)

            state.totalCommits += 1
            let totalLines = added + removed
            state.totalLinesWritten += added
            if totalLines > state.biggestCommitLines {
                state.biggestCommitLines = totalLines
            }
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

        state.totalXP += xp
        state.todayXP += xp
        state.lifetimeXP += xp
        checkEvolution()
    }

    private func addMood(_ amount: Double) {
        state.mood = min(100, max(0, state.mood + amount))
    }

    private func markActive() {
        state.lastActiveDate = Date()
    }

    // MARK: - Evolution

    private func checkEvolution() {
        guard let next = state.stage.nextStage else { return }

        if state.totalXP >= next.xpThreshold
            && state.activeDays >= next.requiredActiveDays
            && state.currentStreak >= next.requiredStreak {
            state.stage = next
            state.stageReachedDate = Date()
            state.mood = min(100, state.mood + 30)
            NSLog("[Kodomon] EVOLVED to %@!", next.displayName)
        }
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
            state.stage = prev
            state.stageReachedDate = Date()
            state.mood = max(0, state.mood - 20)
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

        for _ in 0..<missedDays {
            performMidnightReset()
        }
    }

    private func performMidnightReset() {
        if state.todayIsActive {
            state.activeDays += 1
            state.currentStreak += 1
            state.longestStreak = max(state.longestStreak, state.currentStreak)
        } else {
            state.currentStreak = 0
            applyDecay()
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

        checkDeEvolution()
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

        if hours >= 2 && hours < 8 {
            state.neglectState = .hungry
        } else if hours >= 8 {
            state.neglectState = .tired
        }

        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 9 && hour <= 22 && hours >= 1 {
            addMood(-2)
        }

        save()
    }

    private func applyDecay() {
        let daysMissed = Calendar.current.dateComponents(
            [.day], from: state.lastActiveDate, to: Date()
        ).day ?? 0

        switch daysMissed {
        case 1:
            state.totalXP *= 0.97
            state.neglectState = .sad
            addMood(-20)
        case 2...6:
            state.totalXP *= 0.92
            state.neglectState = .sick
            addMood(-25)
        case 7...13:
            state.totalXP *= 0.85
            state.neglectState = .critical
            addMood(-30)
        case 14...:
            state.neglectState = .ranAway
            state.mood = 0
        default:
            break
        }

        state.totalXP = max(0, state.totalXP)
        addMood(-15)
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
        // Truncate after processing — events are already consumed
        try? "".write(to: path, atomically: true, encoding: .utf8)
        NSLog("[Kodomon] Events log rotated")
    }

    // MARK: - Persistence

    private func save() {
        StateStore.save(state)
    }
}
