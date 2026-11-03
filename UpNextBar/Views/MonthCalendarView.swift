import SwiftUI

/// The current month with each event's icon on the days it takes place. Shown when hovering the menu bar icon.
struct MonthCalendarView: View {
    @Environment(AppModel.self) private var model

    private static let width: CGFloat = 308

    var body: some View {
        let calendar = Self.calendar
        let month = MonthCalendar(
            containing: model.today,
            events: model.store.events,
            today: model.today,
            firstWeekday: calendar.firstWeekday
        )

        VStack(spacing: 10) {
            Text(month.month.date().formatted(.dateTime.month(.wide).year()))
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)

            Grid(horizontalSpacing: 2, verticalSpacing: 2) {
                GridRow {
                    ForEach(Self.weekdayHeaders(calendar), id: \.index) { header in
                        Text(header.symbol)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                ForEach(month.weeks.indices, id: \.self) { week in
                    GridRow {
                        ForEach(month.weeks[week], id: \.day) { cell in
                            DayCell(cell: cell)
                        }
                    }
                }
            }
        }
        .padding(14)
        .frame(width: Self.width)
        .background(Theme.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(.separator)
        }
    }

    private static var calendar: Calendar {
        var calendar = Calendar.current
        calendar.locale = .current
        return calendar
    }

    /// Narrow weekday symbols starting from the user's first day of the week.
    private static func weekdayHeaders(_ calendar: Calendar) -> [(index: Int, symbol: String)] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        return (0..<7).map { offset in
            let index = (calendar.firstWeekday - 1 + offset) % 7
            return (offset, symbols[index])
        }
    }
}

private struct DayCell: View {
    let cell: MonthCell

    var body: some View {
        VStack(spacing: 2) {
            Text("\(cell.day.day)")
                .font(.system(size: 13, weight: cell.isToday ? .bold : .medium, design: .rounded))
                .foregroundStyle(cell.isToday ? Color.white : Color.primary)
                .frame(width: 22, height: 22)
                .background {
                    if cell.isToday { Circle().fill(Color.accentColor) }
                }
            markers
                .frame(height: 14)
        }
        .frame(maxWidth: .infinity, minHeight: 42)
        .opacity(cell.isInMonth ? 1 : 0.3)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var markers: some View {
        let events = cell.events
        if events.count <= 2 {
            HStack(spacing: 2) {
                ForEach(events) { event in
                    Image(systemName: event.icon)
                        .foregroundStyle(event.color.color)
                }
            }
            .font(.system(size: 11))
        } else if let first = events.first {
            HStack(spacing: 1) {
                Image(systemName: first.icon)
                    .foregroundStyle(first.color.color)
                Text("+\(events.count - 1)")
                    .foregroundStyle(.secondary)
            }
            .font(.system(size: 10, weight: .semibold))
        }
    }
}
