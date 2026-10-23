import Foundation

/// An event placed on the timeline at a specific occurrence.
struct TimelineItem: Identifiable, Hashable, Sendable {
    let event: Event
    let day: CalendarDay
    /// Negative for past events.
    let daysLeft: Int

    var id: UUID { event.id }
}

enum Timeline {
    /// Events with an occurrence today or later, soonest first.
    static func upcoming(_ events: [Event], today: CalendarDay) -> [TimelineItem] {
        events
            .compactMap { event in
                event.nextOccurrence(onOrAfter: today).map {
                    TimelineItem(event: event, day: $0, daysLeft: today.days(until: $0))
                }
            }
            .sorted { ($0.day, $0.event.title.lowercased()) < ($1.day, $1.event.title.lowercased()) }
    }

    /// One-off events that have already happened, most recent first.
    static func past(_ events: [Event], today: CalendarDay) -> [TimelineItem] {
        events
            .filter { $0.recurrence == .never && $0.date < today }
            .map { TimelineItem(event: $0, day: $0.date, daysLeft: today.days(until: $0.date)) }
            .sorted { $0.day > $1.day }
    }
}
