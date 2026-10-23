import SwiftUI

struct EventCardView: View {
    let item: TimelineItem
    var isPast = false

    var body: some View {
        let tint = item.event.color.color

        VStack(alignment: .leading, spacing: 1) {
            Text(item.event.title)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .padding(.bottom, 4)
            Text(Countdown.caption(daysLeft: item.daysLeft))
                .font(.caption.weight(.medium))
                .opacity(0.85)
            Countdown.phrase(daysLeft: item.daysLeft)
                .font(.system(size: 19, weight: .bold, design: .rounded))
            Text(item.day.formatted)
                .font(.callout.weight(.medium))
                .opacity(0.9)
            if item.event.recurrence != .never {
                RecurrenceChip(recurrence: item.event.recurrence, tint: tint)
                    .padding(.top, 8)
            }
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
        .saturation(isPast ? 0.35 : 1)
        .opacity(isPast ? 0.8 : 1)
        .accessibilityElement(children: .combine)
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

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "repeat")
            Text(recurrence.title)
        }
        .font(.subheadline.weight(.bold))
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.white.opacity(0.92), in: Capsule())
    }
}

/// The short line between two cards; shows the number of days between them.
struct TimelineConnector: View {
    let gap: Int

    var body: some View {
        ZStack {
            if gap <= 1 {
                Capsule().fill(.quaternary).frame(width: 5, height: 22)
            } else {
                VStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { _ in
                        Capsule().fill(.quaternary).frame(width: 5, height: 6)
                    }
                }
                Text(gap, format: .number)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(.quaternary, lineWidth: 1.5))
                    .offset(x: 26)
                    .help(Text("\(gap) days between events"))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 34)
    }
}
