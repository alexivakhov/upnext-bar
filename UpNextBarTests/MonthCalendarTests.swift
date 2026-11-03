import Foundation
import Testing
@testable import UpNextBar

private func day(_ year: Int, _ month: Int, _ day: Int) -> CalendarDay {
    CalendarDay(year: year, month: month, day: day)
}

struct MonthCalendarTests {
    // November 2026 starts on a Sunday and has 30 days.
    private let today = day(2026, 11, 3)

    @Test func weekdayAndMonthLength() {
        #expect(day(2026, 11, 1).weekday == 1)
        #expect(day(2026, 11, 7).weekday == 7)
        #expect(day(2026, 11, 15).daysInMonth == 30)
        #expect(day(2028, 2, 10).lastOfMonth == day(2028, 2, 29))
    }

    @Test func gridStartsOnFirstWeekday() {
        let sunday = MonthCalendar(containing: today, events: [], today: today, firstWeekday: 1)
        #expect(sunday.weeks.count == 5)
        #expect(sunday.weeks.first?.first?.day == day(2026, 11, 1))
        #expect(sunday.weeks.last?.last?.day == day(2026, 12, 5))

        let monday = MonthCalendar(containing: today, events: [], today: today, firstWeekday: 2)
        #expect(monday.weeks.first?.first?.day == day(2026, 10, 26))
        #expect(monday.weeks.first?.first?.isInMonth == false)
        #expect(monday.weeks.allSatisfy { $0.count == 7 })
    }

    @Test func marksToday() {
        let calendar = MonthCalendar(containing: today, events: [], today: today, firstWeekday: 1)
        #expect(calendar.weeks.flatMap { $0 }.filter(\.isToday).map(\.day) == [today])
    }

    @Test func placesOneOffAndRecurringEvents() {
        let game = Event(title: "Game", date: day(2026, 11, 5))
        let rent = Event(title: "Rent", date: day(2026, 1, 20), recurrence: .monthly)
        let old = Event(title: "Old", date: day(2026, 9, 5))
        let calendar = MonthCalendar(containing: today, events: [game, rent, old], today: today, firstWeekday: 1)
        let cells = Dictionary(uniqueKeysWithValues: calendar.weeks.flatMap { $0 }.map { ($0.day, $0.events.map(\.title)) })
        #expect(cells[day(2026, 11, 5)] == ["Game"])
        #expect(cells[day(2026, 11, 20)] == ["Rent"])
        #expect(cells[day(2026, 9, 5)] == nil)
        #expect(cells.values.flatMap { $0 }.count == 2)
    }

    @Test func multiDayEventCoversEveryDayEvenFromPreviousMonth() {
        let trip = Event(title: "Trip", date: day(2026, 10, 30), endDate: day(2026, 11, 2))
        let calendar = MonthCalendar(containing: today, events: [trip], today: today, firstWeekday: 1)
        let marked = calendar.weeks.flatMap { $0 }.filter { !$0.events.isEmpty }.map(\.day)
        #expect(marked == [day(2026, 11, 1), day(2026, 11, 2)])
    }

    @Test func recurringMultiDayEventStartedBeforeTheMonthStillShows() {
        let camp = Event(title: "Camp", date: day(2025, 10, 30), endDate: day(2025, 11, 2), recurrence: .yearly)
        let calendar = MonthCalendar(containing: today, events: [camp], today: today, firstWeekday: 1)
        let marked = calendar.weeks.flatMap { $0 }.filter { !$0.events.isEmpty }.map(\.day)
        #expect(marked == [day(2026, 11, 1), day(2026, 11, 2)])
    }

    @Test func eventsOnTheSameDayAreOrderedByTitle() {
        let b = Event(title: "b", date: day(2026, 11, 9))
        let a = Event(title: "A", date: day(2026, 11, 9))
        let calendar = MonthCalendar(containing: today, events: [b, a], today: today, firstWeekday: 1)
        let cell = calendar.weeks.flatMap { $0 }.first { $0.day == day(2026, 11, 9) }
        #expect(cell?.events.map(\.title) == ["A", "b"])
    }
}
