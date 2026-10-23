import Foundation
import Observation

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: Self { self }
}

/// Interface languages the app ships. Raw values are localization codes.
enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case ukrainian = "uk"
    var id: Self { self }

    /// The language as it is written in that language, so it reads the same in any interface.
    var nativeName: String {
        switch self {
        case .english: "English"
        case .ukrainian: "Українська"
        }
    }
}

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

    /// Show one-off events that already happened above the upcoming ones.
    var showPastEvents: Bool {
        didSet { defaults.set(showPastEvents, forKey: Keys.showPastEvents) }
    }

    var appearance: AppearanceMode {
        didSet { defaults.set(appearance.rawValue, forKey: Keys.appearance) }
    }

    /// Stored as the app's own `AppleLanguages`, which Foundation reads only at launch.
    var language: AppLanguage {
        didSet { defaults.set([language.rawValue], forKey: Keys.appleLanguages) }
    }

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard, bundle: Bundle = .main) {
        self.defaults = defaults
        reminderHour = defaults.object(forKey: Keys.reminderHour) as? Int ?? 9
        showNextEventInMenuBar = defaults.bool(forKey: Keys.showNextEventInMenuBar)
        showPastEvents = defaults.bool(forKey: Keys.showPastEvents)
        appearance = defaults.string(forKey: Keys.appearance).flatMap(AppearanceMode.init) ?? .system
        language = bundle.preferredLocalizations.first.flatMap(AppLanguage.init) ?? .english
    }

    private enum Keys {
        static let reminderHour = "reminderHour"
        static let showNextEventInMenuBar = "showNextEventInMenuBar"
        static let showPastEvents = "showPastEvents"
        static let appearance = "appearance"
        static let appleLanguages = "AppleLanguages"
    }
}
