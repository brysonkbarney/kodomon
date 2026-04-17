import Foundation
import UserNotifications

@MainActor
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {

    // MARK: - Singleton

    static let shared = NotificationManager()

    // MARK: - Constants

    private static let notificationTitle = "Kodomon"

    // MARK: - Notification Identifiers

    private enum Identifier: String {
        case tired            = "kodomon.tired"
        case sick             = "kodomon.sick"
        case critical         = "kodomon.critical"
        case streakWarning    = "kodomon.streakWarning"
        case evolutionReady   = "kodomon.evolutionReady"
        case petRanAway       = "kodomon.petRanAway"
        case eggDiscovered    = "kodomon.eggDiscovered"
        case eggReady         = "kodomon.eggReady"
        case eggHatched       = "kodomon.eggHatched"
    }

    // MARK: - Init

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: - Permission

    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if let error {
                NSLog("[Kodomon] Notification permission error: %@", error.localizedDescription)
            } else {
                NSLog("[Kodomon] Notification permission granted: %@", granted ? "yes" : "no")
            }
        }
    }

    // MARK: - Public Triggers

    /// Tired: 8 hours with no activity.
    func sendTiredNotification(petName: String = "") {
        let name = petName.isEmpty ? "Your Kodomon" : petName
        deliver(
            identifier: .tired,
            body: "「ねむい…」 \(name) misses you."
        )
    }

    /// Sick: 2-4 missed days.
    func sendSickNotification(petName: String = "") {
        let name = petName.isEmpty ? "Your Kodomon" : petName
        deliver(
            identifier: .sick,
            body: "「だいじょうぶ？」 \(name) is getting sick. Come back soon."
        )
    }

    /// Critical: 5+ missed days, pet is about to run away.
    func sendCriticalNotification(petName: String = "") {
        let name = petName.isEmpty ? "Your Kodomon" : petName
        deliver(
            identifier: .critical,
            body: "「たすけて…！」 \(name) is in critical condition. Come back before it's too late!"
        )
    }

    /// Streak about to break: fires at 11:30 PM if streak >= 3.
    func scheduleStreakWarning(currentStreak: Int, petName: String = "") {
        guard currentStreak >= 3 else { return }
        let name = petName.isEmpty ? "Your Kodomon" : petName

        let content = UNMutableNotificationContent()
        content.title = Self.notificationTitle
        content.body = "「がんばって！」 Your coding streak ends at midnight! Keep going for \(name)!"
        content.sound = .default

        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        dateComponents.hour = 23
        dateComponents.minute = 30

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: Identifier.streakWarning.rawValue,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                NSLog("[Kodomon] Failed to schedule streak warning: %@", error.localizedDescription)
            } else {
                NSLog("[Kodomon] Streak warning scheduled for 11:30 PM")
            }
        }
    }

    /// Immediate streak warning for testing
    func sendStreakWarningNow(petName: String = "") {
        let name = petName.isEmpty ? "Your Kodomon" : petName
        deliver(
            identifier: .streakWarning,
            body: "「がんばって！」 Your coding streak ends at midnight! Keep going for \(name)!"
        )
    }

    /// Cancel the pending streak warning (e.g. user was active today).
    func cancelStreakWarning() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [Identifier.streakWarning.rawValue]
        )
    }

    /// Evolution ready: Kodomon meets all thresholds for the next stage.
    func sendEvolutionReadyNotification(petName: String = "") {
        let name = petName.isEmpty ? "Your Kodomon" : petName
        deliver(
            identifier: .evolutionReady,
            body: "「もうすぐ…！」 \(name) feels something changing!"
        )
    }

    /// Pet ran away: 7+ days of neglect.
    func sendPetRanAwayNotification(petName: String = "") {
        let name = petName.isEmpty ? "Your Kodomon" : petName
        deliver(
            identifier: .petRanAway,
            body: "「さようなら…」 \(name) has left."
        )
    }

    /// Egg discovered: a species trigger just fired, a new egg is incubating.
    /// Intentionally does NOT reveal the species — the reveal is the hatch
    /// notification. Keeps the "what did I get?" surprise.
    func sendEggDiscoveredNotification() {
        deliver(
            identifier: .eggDiscovered,
            body: "「たまご！」 A mysterious egg appeared in your collection. Keep coding to hatch it!"
        )
    }

    /// Egg ready: the head egg has met all incubation requirements and is
    /// waiting for the player to tap Hatch.
    func sendEggReadyNotification() {
        deliver(
            identifier: .eggReady,
            body: "「準備完了！」 Your egg is ready to hatch! Open the Kodex to reveal it."
        )
    }

    /// Egg hatched: the head of the pending-egg queue finished incubation and
    /// just produced a new Kodomon in the collection.
    func sendEggHatchedNotification(speciesName: String, kodomonName: String) {
        deliver(
            identifier: .eggHatched,
            body: "「はじめまして！」 \(kodomonName) the \(speciesName) hatched! Check your collection."
        )
    }

    // MARK: - Delivery

    private func deliver(identifier: Identifier, body: String) {
        let content = UNMutableNotificationContent()
        content.title = Self.notificationTitle
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: identifier.rawValue,
            content: content,
            trigger: nil // deliver immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                NSLog("[Kodomon] Failed to send notification: %@", error.localizedDescription)
            } else {
                NSLog("[Kodomon] Notification sent: %@", identifier.rawValue)
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Show notifications even when the app is in the foreground.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
