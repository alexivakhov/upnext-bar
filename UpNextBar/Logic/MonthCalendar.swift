import Foundation

/// One square of the month grid.
struct MonthCell: Hashable, Sendable {
    let day: CalendarDay
    let isInMonth: Bool
    let isToday: Bool
    /// Events going on this day, in the order they start, then by title.
    let events: [Event]
}

/// The weeks of one month, laid out for a calendar grid, with the events that fall on each day.
struct MonthCalendar: Sendable {
    let month: CalendarDay
    let weeks: [[MonthCell]]

    /// - Parameters:
    ///   - day: any day of the month to show.
    ///   - firstWeekday: 1 = Sunday … 7 = Saturday, as in `Calendar.firstWeekday`.
    init(containing day: CalendarDay, events: [Event], today: CalendarDay, firstWeekday: Int) {
        let first = day.firstOfMonth
        let last = day.lastOfMonth
        month = first

        let leading = (first.weekday - firstWeekday + 7) % 7
        let trailing = (firstWeekday + 6 - last.weekday + 7) % 7
        let start = first.adding(days: -leading)
        let total = leading + day.daysInMonth + trailing

        let byDay = Self.eventsByDay(events, from: start, through: start.adding(days: total - 1))
        let cells = (0..<total).map { offset -> MonthCell in
            let cellDay = start.adding(days: offset)
            return MonthCell(
                day: cellDay,
                isInMonth: cellDay.month == first.month && cellDay.year == first.year,
                isToday: cellDay == today,
                events: byDay[cellDay] ?? []
            )
        }
        weeks = stride(from: 0, to: cells.count, by: 7).map { Array(cells[$0..<$0 + 7]) }
    }

    /// Every occurrence that touches `[from, through]`, spread over the days it covers.
    private static func eventsByDay(_ events: [Event], from: CalendarDay, through: CalendarDay) -> [CalendarDay: [Event]] {
        var result: [CalendarDay: [Event]] = [:]
        for event in events {
            // An occurrence starting up to `duration` days earlier can still reach into the range.
            var index = Schedule.firstIndex(of: event.date, recurrence: event.recurrence, onOrAfter: from.adding(days: -event.duration))
            while let current = index {
                let start = Schedule.occurrence(current, of: event.date, recurrence: event.recurrence)
                if start > through { break }
                for offset in 0...event.duration {
                    let covered = start.adding(days: offset)
                    if covered >= from && covered <= through { result[covered, default: []].append(event) }
                }
                index = event.recurrence == .never ? nil : current + 1
            }
        }
        return result.mapValues { $0.sorted { ($0.date, $0.title.lowercased()) < ($1.date, $1.title.lowercased()) } }
    }
}
