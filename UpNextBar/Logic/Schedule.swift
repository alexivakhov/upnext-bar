import Foundation

/// Occurrence arithmetic for recurring events.
///
/// Every occurrence is computed from the anchor date rather than from the previous
/// occurrence, so a monthly event on the 31st lands on Feb 28 and then returns to Mar 31
/// instead of drifting to the 28th forever.
enum Schedule {
    /// The occurrence with the given zero-based index.
    static func occurrence(_ index: Int, of anchor: CalendarDay, recurrence: Recurrence) -> CalendarDay {
        switch recurrence {
        case .never: anchor
        case .daily: anchor.adding(days: index)
        case .weekly: anchor.adding(days: 7 * index)
        case .monthly: anchor.adding(DateComponents(month: index))
        case .yearly: anchor.adding(DateComponents(year: index))
        }
    }

    /// Index of the first occurrence on or after `day`, or nil when there is none.
    static func firstIndex(of anchor: CalendarDay, recurrence: Recurrence, onOrAfter day: CalendarDay) -> Int? {
        if day <= anchor { return 0 }
        switch recurrence {
        case .never:
            return nil
        case .daily:
            return anchor.days(until: day)
        case .weekly:
            return (anchor.days(until: day) + 6) / 7
        case .monthly, .yearly:
            // Clamping to shorter months makes the elapsed count approximate, so step from just below it.
            let component: Calendar.Component = recurrence == .monthly ? .month : .year
            var index = max(0, anchor.elapsed(component, until: day) - 1)
            while occurrence(index, of: anchor, recurrence: recurrence) < day {
                index += 1
            }
            return index
        }
    }

    /// Up to `count` consecutive occurrences starting with the first one on or after `day`.
    static func occurrences(of anchor: CalendarDay, recurrence: Recurrence, onOrAfter day: CalendarDay, count: Int) -> [CalendarDay] {
        guard let first = firstIndex(of: anchor, recurrence: recurrence, onOrAfter: day) else { return [] }
        let last = recurrence == .never ? first : first + count - 1
        return (first...last).map { occurrence($0, of: anchor, recurrence: recurrence) }
    }

    static func nextOccurrence(of anchor: CalendarDay, recurrence: Recurrence, onOrAfter day: CalendarDay) -> CalendarDay? {
        firstIndex(of: anchor, recurrence: recurrence, onOrAfter: day).map {
            occurrence($0, of: anchor, recurrence: recurrence)
        }
    }
}
