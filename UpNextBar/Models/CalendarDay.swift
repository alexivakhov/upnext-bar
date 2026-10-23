import Foundation

/// A calendar date without a time or time zone, e.g. "23 October 2026".
///
/// Events are all-day, so storing a `Date` would let a time zone or DST change shift
/// them to a neighbouring day. All arithmetic runs in a fixed UTC Gregorian calendar;
/// conversion to a real moment happens only for display and for scheduling notifications.
struct CalendarDay: Codable, Hashable, Comparable, Sendable {
    var year: Int
    var month: Int
    var day: Int

    init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    /// The day `date` falls on in `timeZone`.
    init(_ date: Date, timeZone: TimeZone = .current) {
        let components = Self.gregorian(in: timeZone).dateComponents([.year, .month, .day], from: date)
        self.init(year: components.year!, month: components.month!, day: components.day!)
    }

    static func today(in timeZone: TimeZone = .current) -> CalendarDay {
        CalendarDay(Date(), timeZone: timeZone)
    }

    /// The moment this day starts (or `hour` o'clock on it) in `timeZone`.
    func date(at hour: Int = 0, in timeZone: TimeZone = .current) -> Date {
        let components = DateComponents(year: year, month: month, day: day, hour: hour)
        return Self.gregorian(in: timeZone).date(from: components)!
    }

    func adding(days: Int) -> CalendarDay {
        adding(DateComponents(day: days))
    }

    func adding(_ components: DateComponents) -> CalendarDay {
        CalendarDay(Self.utc.date(byAdding: components, to: utcDate)!, timeZone: Self.utc.timeZone)
    }

    /// Whole days from `self` to `other`; negative when `other` is earlier.
    func days(until other: CalendarDay) -> Int {
        Self.utc.dateComponents([.day], from: utcDate, to: other.utcDate).day!
    }

    /// Whole months or years (`component`) from `self` to `other`.
    func elapsed(_ component: Calendar.Component, until other: CalendarDay) -> Int {
        Self.utc.dateComponents([component], from: utcDate, to: other.utcDate).value(for: component) ?? 0
    }

    static func < (lhs: CalendarDay, rhs: CalendarDay) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    private var utcDate: Date {
        Self.utc.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private static let utc = gregorian(in: TimeZone(identifier: "UTC")!)

    private static func gregorian(in timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }
}
