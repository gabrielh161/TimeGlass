import Foundation
import UserNotifications

/// Wraps the two local notifications TimeGlass sends: a "did you forget to stop?" nudge after a
/// session has run continuously for a while, and an optional once-a-day morning reminder to
/// start tracking when nothing is running yet.
@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()
    private let forgotToStopID = "forgot-to-stop"
    private let morningReminderID = "morning-reminder"
    private let lastMorningReminderKey = "lastMorningReminderDate"

    private init() {}

    func requestAuthorizationIfNeeded() {
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    /// Schedules (replacing any pending one) a notification to fire `hours` after now, asking
    /// whether `projectName`'s timer was forgotten. Call again on every start; cancel on
    /// stop/pause.
    func scheduleForgotToStop(projectName: String, hours: Double) {
        center.removePendingNotificationRequests(withIdentifiers: [forgotToStopID])
        guard hours > 0 else { return }
        let content = UNMutableNotificationContent()
        content.title = "Läuft \(projectName) noch?"
        content.body = "Der Timer läuft seit über \(DurationFormatting.formatHours(hours)). Vergessen zu stoppen?"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: hours * 3600, repeats: false)
        let request = UNNotificationRequest(identifier: forgotToStopID, content: content, trigger: trigger)
        center.add(request)
    }

    func cancelForgotToStop() {
        center.removePendingNotificationRequests(withIdentifiers: [forgotToStopID])
    }

    /// Sends "Timer starten?" at most once per calendar day, meant to be called on the first
    /// unlock while no timer is running.
    func maybeSendMorningReminder(defaults: UserDefaults = .standard, now: Date = .now, calendar: Calendar = .current) {
        let today = calendar.startOfDay(for: now)
        if let last = defaults.object(forKey: lastMorningReminderKey) as? Date,
           calendar.isDate(last, inSameDayAs: today) {
            return
        }
        defaults.set(today, forKey: lastMorningReminderKey)

        let content = UNMutableNotificationContent()
        content.title = "Timer starten?"
        content.body = "Heute läuft noch kein Projekt."
        content.sound = .default
        let request = UNNotificationRequest(identifier: morningReminderID, content: content, trigger: nil)
        center.add(request)
    }
}
