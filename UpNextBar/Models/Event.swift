import Foundation

struct Event: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var title: String
    /// The first (or only) occurrence. Recurring events repeat from this day.
    var date: CalendarDay
    /// Last day of a multi-day event; nil for a single-day one. Recurring events keep the same length.
    var endDate: CalendarDay?
    /// SF Symbol name.
    var icon: String
    var color: EventColor
    var recurrence: Recurrence
    var reminder: ReminderOption
    var comment: String

    init(
        id: UUID = UUID(),
        title: String = "",
        date: CalendarDay,
        endDate: CalendarDay? = nil,
        icon: String = EventIcon.default,
        color: EventColor = .green,
        recurrence: Recurrence = .never,
        reminder: ReminderOption = .none,
        comment: String = ""
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.endDate = endDate
        self.icon = icon
        self.color = color
        self.recurrence = recurrence
        self.reminder = reminder
        self.comment = comment
    }

    /// Days an occurrence lasts beyond its first day.
    var duration: Int {
        endDate.map { max(0, date.days(until: $0)) } ?? 0
    }

    /// The first occurrence on or after `day`, or nil for a one-off event that has passed.
    func nextOccurrence(onOrAfter day: CalendarDay) -> CalendarDay? {
        Schedule.nextOccurrence(of: date, recurrence: recurrence, onOrAfter: day)
    }

    // Lenient decoding: fields added later or values this build doesn't know about
    // (e.g. a new colour) fall back to defaults instead of failing the whole file.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        date = try container.decode(CalendarDay.self, forKey: .date)
        endDate = try? container.decodeIfPresent(CalendarDay.self, forKey: .endDate)
        icon = (try? container.decode(String.self, forKey: .icon)) ?? EventIcon.default
        color = (try? container.decode(EventColor.self, forKey: .color)) ?? .green
        recurrence = (try? container.decode(Recurrence.self, forKey: .recurrence)) ?? .never
        reminder = (try? container.decode(ReminderOption.self, forKey: .reminder)) ?? .none
        comment = (try? container.decode(String.self, forKey: .comment)) ?? ""
    }
}

enum EventColor: String, Codable, CaseIterable, Sendable {
    case pink, orange, yellow, green, teal, blue, indigo, purple
}

enum Recurrence: String, Codable, CaseIterable, Sendable {
    case never, daily, weekly, monthly, yearly
}

enum ReminderOption: String, Codable, CaseIterable, Sendable {
    case none, sameDay, dayBefore

    /// How many days before the occurrence the notification fires; nil when there is no reminder.
    var daysBefore: Int? {
        switch self {
        case .none: nil
        case .sameDay: 0
        case .dayBefore: 1
        }
    }
}

enum EventIcon {
    static let `default` = "star.fill"

    /// Shown directly in the editor.
    static let featured = [
        "star.fill", "gift.fill", "birthday.cake.fill", "creditcard.fill", "airplane", "gamecontroller.fill",
        "film.fill", "music.note", "sportscourt.fill", "heart.fill", "fork.knife", "books.vertical.fill",
    ]

    /// Shown behind "More…".
    static let all = featured + [
        "party.popper.fill", "balloon.2.fill", "trophy.fill", "flag.fill", "bell.fill", "calendar",
        "clock.fill", "house.fill", "car.fill", "bicycle", "tram.fill", "suitcase.fill",
        "beach.umbrella.fill", "tent.fill", "mountain.2.fill", "globe.europe.africa.fill", "sun.max.fill", "snowflake",
        "leaf.fill", "pawprint.fill", "figure.run", "dumbbell.fill", "stethoscope", "pills.fill",
        "cart.fill", "bag.fill", "banknote.fill", "briefcase.fill", "graduationcap.fill", "building.columns.fill",
        "doc.text.fill", "ticket.fill", "theatermasks.fill", "popcorn.fill", "tv.fill", "camera.fill",
        "paintpalette.fill", "hammer.fill", "wrench.and.screwdriver.fill", "bolt.fill", "drop.fill", "flame.fill",
        "phone.fill", "envelope.fill", "person.2.fill", "figure.2.and.child.holdinghands", "cup.and.saucer.fill", "wineglass.fill",
    ]
}
