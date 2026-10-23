import Foundation
import Observation

@MainActor
@Observable
final class AppSettings {
    /// Hour of day (0–23) at which reminders fire.
    var reminderHour: Int {
        didSet { defaults.set(reminderHour, forKey: Keys.reminderHour) }
    }

    /// Show the next event's icon and countdown next to the menu bar icon.
    var showNextEventInMenuBar: Bool {
        didSet { defaults.set(showNextEventInMenuBar, forKey: Keys.showNextEventInMenuBar) }
    }

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        reminderHour = defaults.object(forKey: Keys.reminderHour) as? Int ?? 9
        showNextEventInMenuBar = defaults.bool(forKey: Keys.showNextEventInMenuBar)
    }

    private enum Keys {
        static let reminderHour = "reminderHour"
        static let showNextEventInMenuBar = "showNextEventInMenuBar"
    }
}
