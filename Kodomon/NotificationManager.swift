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
        case hungry           = "kodomon.hungry"
        case tired            = "kodomon.tired"
        case streakWarning    = "kodomon.streakWarning"
        case evolutionReady   = "kodomon.evolutionReady"
        case petRanAway       = "kodomon.petRanAway"
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

    /// Hungry: 2 hours with no activity.
    func sendHungryNotification(petName: String = "") {
        let name = petName.isEmpty ? "Your Kodomon" : petName
        deliver(
            identifier: .hungry,
            body: "「お腹すいた…」 \(name) is getting hungry."
        )
    }

    /// Tired: 8 hours with no activity.
    func sendTiredNotification(petName: String = "") {
        let name = petName.isEmpty ? "Your Kodomon" : petName
        deliver(
            identifier: .tired,
            body: "「ねむい…」 \(name) misses you."
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

        var dateComponents = DateComponents()
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

    /// Pet ran away: 14+ days of neglect.
    func sendPetRanAwayNotification(petName: String = "") {
        let name = petName.isEmpty ? "Your Kodomon" : petName
        deliver(
            identifier: .petRanAway,
            body: "「さようなら…」 \(name) has left."
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
