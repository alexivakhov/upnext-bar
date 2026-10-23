import SwiftUI

struct EventCardView: View {
    let item: TimelineItem
    var isPast = false

    var body: some View {
        let tint = item.event.color.color

        VStack(alignment: .leading, spacing: 1) {
            // Room for two title lines and a fixed date row keep every card the same height.
            Text(item.event.title)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.leading)
                .padding(.bottom, 4)
            Text(Countdown.caption(daysLeft: item.daysLeft))
                .font(.caption.weight(.medium))
                .opacity(0.85)
            Countdown.phrase(daysLeft: item.daysLeft)
                .font(.system(size: 19, weight: .bold, design: .rounded))
            dateRow
                .frame(height: 24)
        }
        .foregroundStyle(.white)
        .padding(.vertical, 16)
        .padding(.leading, 18)
        .padding(.trailing, 52)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .fill(tint.gradient)
                .overlay {
                    SymbolPattern(symbol: item.event.icon)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
                }
        }
        .overlay(alignment: .topTrailing) {
            IconBadge(symbol: item.event.icon, tint: tint)
                .offset(x: 12, y: -12)
        }
        .saturation(isPast ? 0.7 : 1)
        .opacity(isPast ? 0.5 : 1)
        .accessibilityElement(children: .combine)
    }

    private var dateRow: some View {
        let date = Text(item.day.formatted)
            .font(.callout.weight(.medium))
            .opacity(0.9)
        let recurrence = item.event.recurrence
        let tint = item.event.color.color

        return ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                date
                Spacer(minLength: 0)
                if recurrence != .never { RecurrenceChip(recurrence: recurrence, tint: tint) }
            }
            HStack(spacing: 8) {
                date
                Spacer(minLength: 0)
                if recurrence != .never { RecurrenceChip(recurrence: recurrence, tint: tint, compact: true) }
            }
        }
    }
}

/// The round icon that overlaps the card's top-right corner.
struct IconBadge: View {
    let symbol: String
    let tint: Color

    var body: some View {
        ZStack {
            Circle().fill(Theme.background)
            Circle().fill(Theme.badgeFill).padding(5)
            Circle().fill(tint.opacity(0.16)).padding(5)
            Circle().strokeBorder(tint, lineWidth: 3).padding(5)
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tint)
        }
        .frame(width: 56, height: 56)
    }
}

private struct RecurrenceChip: View {
    let recurrence: Recurrence
    let tint: Color
    /// Icon only, for when the date leaves no room for the word.
    var compact = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "repeat")
            if !compact { Text(recurrence.title) }
        }
        .font(.caption.weight(.bold))
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.white.opacity(0.92), in: Capsule())
        .help(Text(recurrence.title))
    }
}

/// The short line between two cards with the number of days between them.
/// Between the last past event and the first upcoming one it also marks today.
struct TimelineConnector: View {
    let gap: Int
    var today: CalendarDay?

    var body: some View {
        HStack(spacing: 10) {
            Group {
                if let today {
                    HStack(spacing: 6) {
                        VStack(alignment: .trailing, spacing: 0) {
                            Text("Today")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(today.date().formatted(.dateTime.day().month(.wide)))
                                .font(.caption.weight(.bold))
                        }
                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.bold))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)

            line

            Group {
                if gap > 0 {
                    Text(gap, format: .number)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(.quaternary, lineWidth: 1.5))
                        .help(Text("\(gap) days between events"))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: today == nil ? 34 : 48)
    }

    @ViewBuilder
    private var line: some View {
        if gap <= 1 && today == nil {
            Capsule().fill(.quaternary).frame(width: 5, height: 22)
        } else {
            VStack(spacing: 4) {
                ForEach(0..<(today == nil ? 3 : 5), id: \.self) { _ in
                    Capsule().fill(.quaternary).frame(width: 5, height: 6)
                }
            }
        }
    }
}
