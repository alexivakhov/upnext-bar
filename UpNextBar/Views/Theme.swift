import AppKit
import SwiftUI

enum Theme {
    static let width: CGFloat = 380
    static let height: CGFloat = 600
    static let cardRadius: CGFloat = 22

    static let background = Color(nsColor: .windowBackgroundColor)
    /// Fill for text fields, grids and secondary buttons.
    static let field = Color.primary.opacity(0.06)
    static let badgeFill = Color(light: 0xFFFFFF, dark: 0x2C2C30)
}

extension Color {
    /// A colour that follows the light/dark appearance. Values are 0xRRGGBB.
    init(light: UInt32, dark: UInt32) {
        self.init(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return NSColor(hex: isDark ? dark : light)
        })
    }
}

private extension NSColor {
    convenience init(hex: UInt32) {
        self.init(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

// MARK: - Presentation of model values

extension EventColor: Identifiable {
    var id: Self { self }

    var color: Color {
        switch self {
        case .pink: Color(light: 0xF5506E, dark: 0xE0445F)
        case .orange: Color(light: 0xF76B45, dark: 0xE25D39)
        case .yellow: Color(light: 0xF2AE22, dark: 0xD99A16)
        case .green: Color(light: 0x16C24A, dark: 0x13A841)
        case .teal: Color(light: 0x22C4A2, dark: 0x1CAA8C)
        case .blue: Color(light: 0x22AEE0, dark: 0x1D97C4)
        case .indigo: Color(light: 0x5677C9, dark: 0x4C69B5)
        case .purple: Color(light: 0x7350E3, dark: 0x6544CC)
        }
    }

    var name: LocalizedStringKey {
        switch self {
        case .pink: "Pink"
        case .orange: "Orange"
        case .yellow: "Yellow"
        case .green: "Green"
        case .teal: "Teal"
        case .blue: "Blue"
        case .indigo: "Indigo"
        case .purple: "Purple"
        }
    }
}

extension Recurrence: Identifiable {
    var id: Self { self }

    var title: LocalizedStringKey {
        switch self {
        case .never: "Never"
        case .daily: "Daily"
        case .weekly: "Weekly"
        case .monthly: "Monthly"
        case .yearly: "Yearly"
        }
    }
}

extension ReminderOption: Identifiable {
    var id: Self { self }

    var title: LocalizedStringKey {
        switch self {
        case .none: "None"
        case .sameDay: "On the day"
        case .dayBefore: "Day before"
        }
    }
}

extension CalendarDay {
    /// "4 November 2026" in the user's language.
    var formatted: String {
        date().formatted(.dateTime.day().month(.wide).year())
    }
}

/// Wording for "how far away" an event is.
enum Countdown {
    static func caption(daysLeft: Int) -> LocalizedStringKey {
        daysLeft >= 0 ? "Happening" : "Happened"
    }

    static func phrase(daysLeft: Int) -> Text {
        switch daysLeft {
        case 0: Text("today")
        case 1: Text("tomorrow")
        case -1: Text("yesterday")
        case 2...: Text("in \(daysLeft) days")
        default: Text("\(-daysLeft) days ago")
        }
    }

    /// Compact form for the menu bar.
    static func short(daysLeft: Int) -> String {
        daysLeft == 0 ? String(localized: "Today") : String(localized: "\(daysLeft) d")
    }
}
