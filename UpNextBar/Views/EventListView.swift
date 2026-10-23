import SwiftUI

struct EventListView: View {
    @Environment(AppModel.self) private var model
    @State private var showPast = false
    @State private var eventToDelete: Event?

    var body: some View {
        VStack(spacing: 0) {
            header
            if model.store.events.isEmpty {
                EmptyStateView { model.route = .newEvent }
            } else {
                timeline
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if !model.store.events.isEmpty {
                AddButton { model.route = .newEvent }
                    .padding(18)
            }
        }
        .alert(
            "Delete event?",
            isPresented: Binding(get: { eventToDelete != nil }, set: { if !$0 { eventToDelete = nil } }),
            presenting: eventToDelete
        ) { event in
            Button("Delete", role: .destructive) { model.delete(id: event.id) }
            Button("Cancel", role: .cancel) {}
        } message: { event in
            Text("“\(event.title)” will be removed.")
        }
    }

    private var header: some View {
        SheetHeader("UpNext") {
            Color.clear.frame(width: 30, height: 30)
        } trailing: {
            CircleIconButton("slider.horizontal.3", help: "Settings") { model.route = .settings }
        }
    }

    private var timeline: some View {
        let upcoming = model.upcoming
        let past = model.past

        return ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(upcoming.enumerated()), id: \.element.id) { index, item in
                    if index > 0 {
                        TimelineConnector(gap: upcoming[index - 1].day.days(until: item.day))
                            .padding(.trailing, 12)
                    }
                    card(item, isPast: false)
                }

                if upcoming.isEmpty {
                    Text("Nothing ahead. Add something to look forward to!")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 40)
                }

                if !past.isEmpty {
                    pastHeader(count: past.count)
                    if showPast {
                        ForEach(past) { item in
                            card(item, isPast: true)
                                .padding(.bottom, 18)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 90)
        }
        .scrollIndicators(.never)
    }

    private func card(_ item: TimelineItem, isPast: Bool) -> some View {
        Button {
            model.route = .editEvent(item.event.id)
        } label: {
            EventCardView(item: item, isPast: isPast)
                .padding(.trailing, 12)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
        .contextMenu {
            Button("Edit", systemImage: "pencil") { model.route = .editEvent(item.event.id) }
            Divider()
            Button("Delete", systemImage: "trash", role: .destructive) { eventToDelete = item.event }
        }
    }

    private func pastHeader(count: Int) -> some View {
        Button {
            withAnimation(.snappy) { showPast.toggle() }
        } label: {
            HStack {
                Text("Past")
                    .font(.subheadline.weight(.semibold))
                Text(count, format: .number)
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(Theme.field, in: Capsule())
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .rotationEffect(.degrees(showPast ? 90 : 0))
            }
            .foregroundStyle(.secondary)
            .padding(.vertical, 10)
            .padding(.horizontal, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.top, 28)
        .padding(.bottom, showPast ? 14 : 0)
    }
}

private struct AddButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.primary)
                .frame(width: 52, height: 52)
                .background(Theme.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(.primary, lineWidth: 2.5)
                )
                .shadow(color: .black.opacity(0.18), radius: 8, y: 3)
        }
        .buttonStyle(PressableButtonStyle())
        .keyboardShortcut("n", modifiers: .command)
        .help(Text("New event"))
        .accessibilityLabel(Text("New event"))
    }
}

private struct EmptyStateView: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "binoculars.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("No events yet")
                .font(.system(.title3, design: .rounded).weight(.bold))
            Text("Birthdays, payments, trips — add anything you don't want to miss.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button(action: onAdd) {
                Label("Add event", systemImage: "plus")
                    .padding(.horizontal, 8)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut("n", modifiers: .command)
            .padding(.top, 6)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
