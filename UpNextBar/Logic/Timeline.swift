import Foundation

/// An event placed on the timeline at a specific occurrence.
struct TimelineItem: Identifiable, Hashable, Sendable {
    let event: Event
    let day: CalendarDay
    /// Last day of this occurrence when it spans several days.
    let endDay: CalendarDay?
    /// Negative for past events and for ones that have started but not finished.
    let daysLeft: Int
    /// Started on an earlier day and still going on today.
    let isOngoing: Bool

    var id: UUID { event.id }

    init(event: Event, day: CalendarDay, today: CalendarDay) {
        self.event = event
        self.day = day
        endDay = event.duration > 0 ? day.adding(days: event.duration) : nil
        daysLeft = today.days(until: day)
        isOngoing = daysLeft < 0 && (endDay ?? day) >= today
    }
}

enum Timeline {
    /// Events with an occurrence going on today or starting later, soonest first.
    static func upcoming(_ events: [Event], today: CalendarDay) -> [TimelineItem] {
        events
            .compactMap { event in
                let start = Schedule.activeOccurrence(of: event.date, recurrence: event.recurrence, duration: event.duration, on: today)
                    ?? event.nextOccurrence(onOrAfter: today)
                return start.map { TimelineItem(event: event, day: $0, today: today) }
            }
            .sorted { ($0.day, $0.event.title.lowercased()) < ($1.day, $1.event.title.lowercased()) }
    }

    /// One-off events that have already ended, most recent first.
    static func past(_ events: [Event], today: CalendarDay) -> [TimelineItem] {
        events
            .filter { $0.recurrence == .never && $0.date.adding(days: $0.duration) < today }
            .map { TimelineItem(event: $0, day: $0.date, today: today) }
            .sorted { $0.day > $1.day }
    }
}
