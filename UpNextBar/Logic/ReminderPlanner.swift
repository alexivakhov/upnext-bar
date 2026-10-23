import Foundation

struct PlannedReminder: Equatable, Sendable {
    let identifier: String
    let eventID: UUID
    let occurrence: CalendarDay
    let fireDate: Date
}

/// Decides which notifications should be pending right now.
///
/// macOS keeps at most 64 pending notifications per app, so only the next few
/// reminders per event are scheduled; the app re-plans on every change, at midnight
/// and after waking from sleep, which keeps the window moving forward.
enum ReminderPlanner {
    static func plan(
        for events: [Event],
        hour: Int,
        now: Date,
        timeZone: TimeZone = .current,
        perEventLimit: Int = 3,
        totalLimit: Int = 60
    ) -> [PlannedReminder] {
        let today = CalendarDay(now, timeZone: timeZone)
        var reminders: [PlannedReminder] = []

        for event in events {
            guard let daysBefore = event.reminder.daysBefore,
                  var index = Schedule.firstIndex(of: event.date, recurrence: event.recurrence, onOrAfter: today)
            else { continue }

            var planned = 0
            while planned < perEventLimit {
                let occurrence = Schedule.occurrence(index, of: event.date, recurrence: event.recurrence)
                let fireDate = occurrence.adding(days: -daysBefore).date(at: hour, in: timeZone)
                if fireDate > now {
                    reminders.append(PlannedReminder(
                        identifier: "\(event.id.uuidString)-\(occurrence.year)-\(occurrence.month)-\(occurrence.day)",
                        eventID: event.id,
                        occurrence: occurrence,
                        fireDate: fireDate
                    ))
                    planned += 1
                }
                if event.recurrence == .never { break }
                index += 1
            }
        }

        return Array(reminders.sorted { $0.fireDate < $1.fireDate }.prefix(totalLimit))
    }
}
