import Foundation
import Testing
@testable import UpNextBar

private func day(_ year: Int, _ month: Int, _ day: Int) -> CalendarDay {
    CalendarDay(year: year, month: month, day: day)
}

struct CalendarDayTests {
    @Test func daysBetween() {
        #expect(day(2026, 10, 23).days(until: day(2026, 11, 4)) == 12)
        #expect(day(2026, 11, 4).days(until: day(2026, 10, 23)) == -12)
        #expect(day(2026, 12, 31).days(until: day(2027, 1, 1)) == 1)
    }

    @Test func daysBetweenIgnoresDaylightSavingChange() {
        // Europe/Kyiv switches to winter time on 25 Oct 2026.
        #expect(day(2026, 10, 24).days(until: day(2026, 10, 26)) == 2)
    }

    @Test func roundTripsThroughLocalDate() {
        let kyiv = TimeZone(identifier: "Europe/Kyiv")!
        let honolulu = TimeZone(identifier: "Pacific/Honolulu")!
        let original = day(2026, 3, 29)
        #expect(CalendarDay(original.date(in: kyiv), timeZone: kyiv) == original)
        #expect(CalendarDay(original.date(at: 23, in: honolulu), timeZone: honolulu) == original)
    }
}

struct ScheduleTests {
    @Test func oneOffEvent() {
        let anchor = day(2026, 11, 5)
        #expect(Schedule.nextOccurrence(of: anchor, recurrence: .never, onOrAfter: day(2026, 10, 23)) == anchor)
        #expect(Schedule.nextOccurrence(of: anchor, recurrence: .never, onOrAfter: anchor) == anchor)
        #expect(Schedule.nextOccurrence(of: anchor, recurrence: .never, onOrAfter: day(2026, 11, 6)) == nil)
    }

    @Test func daily() {
        let anchor = day(2026, 1, 1)
        #expect(Schedule.nextOccurrence(of: anchor, recurrence: .daily, onOrAfter: day(2026, 10, 23)) == day(2026, 10, 23))
    }

    @Test func weekly() {
        let anchor = day(2026, 10, 1) // Thursday
        #expect(Schedule.nextOccurrence(of: anchor, recurrence: .weekly, onOrAfter: day(2026, 10, 8)) == day(2026, 10, 8))
        #expect(Schedule.nextOccurrence(of: anchor, recurrence: .weekly, onOrAfter: day(2026, 10, 9)) == day(2026, 10, 15))
    }

    @Test func monthlyKeepsDayOfMonth() {
        let anchor = day(2026, 1, 4)
        #expect(Schedule.nextOccurrence(of: anchor, recurrence: .monthly, onOrAfter: day(2026, 10, 23)) == day(2026, 11, 4))
        #expect(Schedule.nextOccurrence(of: anchor, recurrence: .monthly, onOrAfter: day(2026, 11, 4)) == day(2026, 11, 4))
    }

    @Test func monthlyOnThe31stClampsWithoutDrifting() {
        let anchor = day(2026, 1, 31)
        #expect(Schedule.nextOccurrence(of: anchor, recurrence: .monthly, onOrAfter: day(2026, 2, 1)) == day(2026, 2, 28))
        #expect(Schedule.nextOccurrence(of: anchor, recurrence: .monthly, onOrAfter: day(2026, 3, 1)) == day(2026, 3, 31))
        #expect(Schedule.nextOccurrence(of: anchor, recurrence: .monthly, onOrAfter: day(2026, 4, 1)) == day(2026, 4, 30))
    }

    @Test func yearlyOnLeapDay() {
        let anchor = day(2024, 2, 29)
        #expect(Schedule.nextOccurrence(of: anchor, recurrence: .yearly, onOrAfter: day(2026, 10, 23)) == day(2027, 2, 28))
        #expect(Schedule.nextOccurrence(of: anchor, recurrence: .yearly, onOrAfter: day(2027, 3, 1)) == day(2028, 2, 29))
    }

    @Test func futureAnchorIsFirstOccurrence() {
        let anchor = day(2027, 5, 10)
        for recurrence in Recurrence.allCases {
            #expect(Schedule.nextOccurrence(of: anchor, recurrence: recurrence, onOrAfter: day(2026, 10, 23)) == anchor)
        }
    }
}

struct TimelineTests {
    @Test func splitsUpcomingAndPast() {
        let today = day(2026, 10, 23)
        let birthday = Event(title: "Birthday", date: day(2000, 11, 1), recurrence: .yearly)
        let concert = Event(title: "Concert", date: day(2026, 10, 25))
        let trip = Event(title: "Trip", date: day(2026, 9, 1))

        let upcoming = Timeline.upcoming([birthday, concert, trip], today: today)
        #expect(upcoming.map(\.event.title) == ["Concert", "Birthday"])
        #expect(upcoming.map(\.daysLeft) == [2, 9])

        let past = Timeline.past([birthday, concert, trip], today: today)
        #expect(past.map(\.event.title) == ["Trip"])
        #expect(past.first?.daysLeft == -52)
    }
}

struct ReminderPlannerTests {
    private let kyiv = TimeZone(identifier: "Europe/Kyiv")!

    @Test func dayBeforeFiresAtConfiguredHour() {
        let now = day(2026, 10, 23).date(at: 8, in: kyiv)
        let event = Event(title: "Game", date: day(2026, 11, 5), reminder: .dayBefore)
        let plan = ReminderPlanner.plan(for: [event], hour: 9, now: now, timeZone: kyiv)
        #expect(plan.count == 1)
        #expect(plan.first?.fireDate == day(2026, 11, 4).date(at: 9, in: kyiv))
    }

    @Test func skipsReminderWhoseTimeHasPassed() {
        let now = day(2026, 11, 5).date(at: 10, in: kyiv)
        let event = Event(title: "Game", date: day(2026, 11, 5), reminder: .sameDay)
        #expect(ReminderPlanner.plan(for: [event], hour: 9, now: now, timeZone: kyiv).isEmpty)
    }

    @Test func recurringEventsGetSeveralUpcomingReminders() {
        let now = day(2026, 10, 23).date(at: 12, in: kyiv)
        let event = Event(title: "Pay", date: day(2026, 1, 4), recurrence: .monthly, reminder: .sameDay)
        let plan = ReminderPlanner.plan(for: [event], hour: 9, now: now, timeZone: kyiv, perEventLimit: 3)
        #expect(plan.map(\.occurrence) == [day(2026, 11, 4), day(2026, 12, 4), day(2027, 1, 4)])
    }

    @Test func noReminderMeansNoNotification() {
        let event = Event(title: "Quiet", date: day(2026, 12, 1))
        #expect(ReminderPlanner.plan(for: [event], hour: 9, now: .now).isEmpty)
    }

    @Test func respectsTotalLimit() {
        let events = (0..<30).map { Event(title: "\($0)", date: day(2026, 1, 1), recurrence: .daily, reminder: .sameDay) }
        let plan = ReminderPlanner.plan(for: events, hour: 9, now: day(2026, 10, 23).date(in: kyiv), timeZone: kyiv, totalLimit: 60)
        #expect(plan.count == 60)
    }
}

@MainActor
struct EventStoreTests {
    @Test func persistsAcrossInstances() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("events.json")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let event = Event(title: "Zelda", date: day(2026, 11, 5), icon: "gamecontroller.fill", color: .purple, reminder: .dayBefore)
        EventStore(fileURL: url).upsert(event)

        let reloaded = EventStore(fileURL: url)
        #expect(reloaded.events == [event])

        reloaded.delete(id: event.id)
        #expect(EventStore(fileURL: url).events.isEmpty)
    }

    @Test func unknownValuesFallBackToDefaults() throws {
        let json = """
        {"id":"\(UUID().uuidString)","title":"Old","date":{"year":2026,"month":1,"day":2},"color":"chartreuse"}
        """
        let event = try JSONDecoder().decode(Event.self, from: Data(json.utf8))
        #expect(event.color == .green)
        #expect(event.recurrence == .never)
        #expect(event.icon == EventIcon.default)
    }
}
