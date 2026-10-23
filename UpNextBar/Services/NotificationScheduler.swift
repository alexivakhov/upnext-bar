import Foundation
import UserNotifications

@MainActor
final class NotificationScheduler {
    private let delegate = NotificationDelegate()

    func installDelegate() {
        UNUserNotificationCenter.current().delegate = delegate
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }

    /// Replaces every pending notification with `plan`.
    func replacePending(with plan: [PlannedReminder], events: [UUID: Event]) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        for reminder in plan {
            if Task.isCancelled { return }
            guard let event = events[reminder.eventID] else { continue }

            let content = UNMutableNotificationContent()
            content.title = event.title
            content.body = Self.body(for: event.reminder, occurrence: reminder.occurrence)
            content.sound = .default
            content.threadIdentifier = event.id.uuidString

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: reminder.fireDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: reminder.identifier, content: content, trigger: trigger))
        }
    }

    private static func body(for reminder: ReminderOption, occurrence: CalendarDay) -> String {
        let date = occurrence.date().formatted(.dateTime.day().month(.wide).year())
        switch reminder {
        case .dayBefore: return String(localized: "Tomorrow · \(date)")
        case .sameDay, .none: return String(localized: "Today · \(date)")
        }
    }
}

/// Shows banners even while the popup is open (the app is frontmost then).
private final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }
}
