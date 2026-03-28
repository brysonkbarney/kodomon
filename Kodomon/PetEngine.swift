import Foundation
import Combine

@MainActor
class PetEngine: ObservableObject {
    @Published var state: PetState
    private let watcher: ActivityWatcher
    private var cancellables = Set<AnyCancellable>()
    private var midnightTimer: Timer?
    private var decayTimer: Timer?

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

        scheduleMidnightReset()
        startDecayTimer()
    }

    // MARK: - Event Handling

    private func handleEvent(_ event: ActivityEvent) {
        NSLog("[Kodomon] Handling event")

        switch event {
        case .sessionStart(_, _, _):
            markActive()
            addMood(15)
            if !state.todayIsActive {
                let xp = XPCalculator.applyMultipliers(
                    rawXP: 10,
                    todaySessionMins: state.todaySessionMins,
                    streak: state.currentStreak,
                    mood: state.mood,
                    todayXP: state.todayXP
                )
                addXP(xp)
                state.todayIsActive = true
            }

        case .sessionStop(_, _):
            break

        case .fileWrite(let path, _):
            markActive()

            let ext = (path as NSString).pathExtension.lowercased()
            if !ext.isEmpty {
                state.todayFileTypes.insert(ext)
            }

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

            let xp = XPCalculator.applyMultipliers(
                rawXP: 10,
                todaySessionMins: state.todaySessionMins,
                streak: state.currentStreak,
                mood: state.mood,
                todayXP: state.todayXP
            )
            addXP(xp)
            addMood(8)

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
        state.totalXP += amount
        state.todayXP += amount
        state.lifetimeXP += amount
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
        state.todayIsActive = false

        let moodDelta = (50 - state.mood) * 0.3
        state.mood += moodDelta

        state.lastMidnightReset = Calendar.current.startOfDay(for: Date())

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

    // MARK: - Persistence

    private func save() {
        StateStore.save(state)
    }
}
