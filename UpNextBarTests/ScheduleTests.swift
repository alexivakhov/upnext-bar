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

    @Test func consecutiveOccurrences() {
        let today = day(2026, 10, 23)
        #expect(Schedule.occurrences(of: day(2026, 11, 5), recurrence: .weekly, onOrAfter: today, count: 3)
            == [day(2026, 11, 5), day(2026, 11, 12), day(2026, 11, 19)])
        #expect(Schedule.occurrences(of: day(2026, 1, 31), recurrence: .monthly, onOrAfter: today, count: 3)
            == [day(2026, 10, 31), day(2026, 11, 30), day(2026, 12, 31)])
        #expect(Schedule.occurrences(of: day(2026, 11, 5), recurrence: .never, onOrAfter: today, count: 3) == [day(2026, 11, 5)])
        #expect(Schedule.occurrences(of: day(2026, 1, 5), recurrence: .never, onOrAfter: today, count: 3).isEmpty)
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

struct EventFilterTests {
    private let events = [
        Event(title: "Pay: iCloud+", date: day(2026, 11, 7), icon: "creditcard.fill"),
        Event(title: "Game: Zelda", date: day(2026, 11, 5), icon: "gamecontroller.fill"),
        Event(title: "Pay: Netflix", date: day(2026, 11, 9), icon: "tv.fill"),
    ]

    @Test func inactiveFilterMatchesEverything() {
        let filter = EventFilter(query: "  ")
        #expect(!filter.isActive)
        #expect(events.allSatisfy(filter.matches))
    }

    @Test func matchesNameIgnoringCase() {
        let filter = EventFilter(query: "pAY")
        #expect(events.filter(filter.matches).map(\.title) == ["Pay: iCloud+", "Pay: Netflix"])
    }

    @Test func matchesAnyPickedIcon() {
        let filter = EventFilter(icons: ["tv.fill", "gamecontroller.fill"])
        #expect(events.filter(filter.matches).count == 2)
    }

    @Test func combinesNameAndIcons() {
        let filter = EventFilter(query: "pay", icons: ["tv.fill"])
        #expect(events.filter(filter.matches).map(\.title) == ["Pay: Netflix"])
    }

    @Test func availableIconsFollowEditorOrder() {
        #expect(EventFilter.availableIcons(in: events) == ["creditcard.fill", "gamecontroller.fill", "tv.fill"])
    }

    @Test func commentDecodesLeniently() throws {
        let json = #"{"id":"\#(UUID().uuidString)","title":"A","date":{"year":2026,"month":11,"day":5}}"#
        let event = try JSONDecoder().decode(Event.self, from: Data(json.utf8))
        #expect(event.comment == "")
    }
}

struct MultiDayEventTests {
    private let today = day(2026, 11, 6)

    @Test func durationFollowsEndDate() {
        #expect(Event(date: day(2026, 11, 5), endDate: day(2026, 11, 8)).duration == 3)
        #expect(Event(date: day(2026, 11, 5)).duration == 0)
    }

    @Test func ongoingEventStaysUpcomingUntilItEnds() {
        let trip = Event(title: "Trip", date: day(2026, 11, 5), endDate: day(2026, 11, 7))
        let item = Timeline.upcoming([trip], today: today).first
        #expect(item?.day == day(2026, 11, 5))
        #expect(item?.isOngoing == true)
        #expect(Timeline.upcoming([trip], today: day(2026, 11, 8)).isEmpty)
        #expect(Timeline.past([trip], today: today).isEmpty)
        #expect(Timeline.past([trip], today: day(2026, 11, 8)).count == 1)
    }

    @Test func recurringEventCountsItsCurrentOccurrenceAsOngoing() {
        let event = Event(date: day(2026, 1, 5), endDate: day(2026, 1, 7), recurrence: .monthly)
        let item = Timeline.upcoming([event], today: day(2026, 11, 6)).first
        #expect(item?.day == day(2026, 11, 5))
        #expect(item?.endDay == day(2026, 11, 7))
        #expect(Timeline.upcoming([event], today: day(2026, 11, 8)).first?.day == day(2026, 12, 5))
    }
}
