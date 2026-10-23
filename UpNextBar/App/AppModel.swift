import AppKit
import Observation
import UserNotifications

/// App-wide state: data, settings, navigation inside the popup and reminder scheduling.
@MainActor
@Observable
final class AppModel {
    enum Route: Equatable {
        case list
        case newEvent
        case editEvent(UUID)
        case settings
    }

    let store: EventStore
    let settings: AppSettings
    var route: Route = .list
    private(set) var today: CalendarDay = .today()
    private(set) var notificationStatus: UNAuthorizationStatus = .notDetermined
    /// False when notifications are allowed but their style is "None", so nothing pops up on screen.
    private(set) var bannersEnabled = true

    @ObservationIgnored private let scheduler = NotificationScheduler()
    @ObservationIgnored private var observers: [NSObjectProtocol] = []
    @ObservationIgnored private var rescheduleTask: Task<Void, Never>?

    /// Unit tests run inside the app; keep them away from real notifications.
    static let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

    init() {
        store = EventStore()
        settings = AppSettings()
        guard !Self.isRunningTests else { return }
        applyAppearance()
        scheduler.installDelegate()
        observeSystemChanges()
        Task { await bootstrap() }
    }

    var upcoming: [TimelineItem] { Timeline.upcoming(store.events, today: today) }
    var past: [TimelineItem] { Timeline.past(store.events, today: today) }

    // MARK: - Editing

    func save(_ event: Event) {
        store.upsert(event)
        Task {
            if event.reminder != .none { await requestNotificationsIfNeeded() }
            rescheduleReminders()
        }
    }

    func delete(id: UUID) {
        store.delete(id: id)
        rescheduleReminders()
    }

    // MARK: - Reminders

    func rescheduleReminders() {
        guard !Self.isRunningTests else { return }
        let plan = ReminderPlanner.plan(for: store.events, hour: settings.reminderHour, now: .now)
        let events = Dictionary(uniqueKeysWithValues: store.events.map { ($0.id, $0) })
        let previous = rescheduleTask
        rescheduleTask = Task {
            // Let a superseded run stop first so its late additions can't survive our cleanup.
            previous?.cancel()
            await previous?.value
            await scheduler.replacePending(with: plan, events: events)
        }
    }

    func refreshNotificationStatus() async {
        let current = await scheduler.currentSettings()
        notificationStatus = current.status
        bannersEnabled = current.alertStyle != .none
    }

    /// Opens UpNext Bar's page in System Settings › Notifications.
    func openNotificationSettings() {
        let id = Bundle.main.bundleIdentifier ?? ""
        if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension?id=\(id)") {
            NSWorkspace.shared.open(url)
        }
    }

    func requestNotificationsIfNeeded() async {
        await refreshNotificationStatus()
        guard notificationStatus == .notDetermined else { return }
        _ = await scheduler.requestAuthorization()
        await refreshNotificationStatus()
    }

    // MARK: - Appearance and language

    func applyAppearance() {
        NSApplication.shared.appearance = switch settings.appearance {
        case .system: nil
        case .light: NSAppearance(named: .aqua)
        case .dark: NSAppearance(named: .darkAqua)
        }
    }

    /// Saves the language and restarts the app, since bundles pick their localization only at launch.
    func changeLanguage(to language: AppLanguage) {
        guard language != settings.language else { return }
        settings.language = language
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, configuration: configuration) { _, _ in
            Task { @MainActor in NSApp.terminate(nil) }
        }
    }

    /// Called when the popup opens, in case a day boundary passed unnoticed.
    func refreshTodayIfNeeded() {
        if CalendarDay.today() != today { systemTimeChanged() }
    }

    private func systemTimeChanged() {
        today = .today()
        rescheduleReminders()
    }

    private func bootstrap() async {
        await refreshNotificationStatus()
        if store.events.contains(where: { $0.reminder != .none }) {
            await requestNotificationsIfNeeded()
        }
        rescheduleReminders()
    }

    private func observeSystemChanges() {
        let handler: @Sendable (Notification) -> Void = { [weak self] _ in
            Task { @MainActor in self?.systemTimeChanged() }
        }
        for name in [Notification.Name.NSCalendarDayChanged, .NSSystemTimeZoneDidChange, .NSSystemClockDidChange] {
            observers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main, using: handler))
        }
        observers.append(NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main, using: handler
        ))
    }
}
