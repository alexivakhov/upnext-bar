import SwiftUI

struct EventListView: View {
    @Environment(AppModel.self) private var model
    @State private var eventToDelete: Event?

    var body: some View {
        VStack(spacing: 0) {
            header
            if model.isFilterVisible && !model.store.events.isEmpty {
                FilterPanel()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
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
        .confirmation(
            "Delete event?",
            message: Text("“\(eventToDelete?.title ?? "")” will be removed."),
            actionTitle: "Delete",
            isPresented: Binding(get: { eventToDelete != nil }, set: { if !$0 { eventToDelete = nil } })
        ) {
            if let event = eventToDelete { model.delete(id: event.id) }
        }
    }

    private var header: some View {
        SheetHeader("UpNext") {
            if model.store.events.isEmpty {
                Color.clear.frame(width: 30, height: 30)
            } else {
                CircleIconButton(
                    "line.3.horizontal.decrease",
                    help: "Filter",
                    isActive: model.filter.isActive
                ) {
                    withAnimation(.snappy(duration: 0.2)) { model.isFilterVisible.toggle() }
                }
            }
        } trailing: {
            CircleIconButton("slider.horizontal.3", help: "Settings") { model.route = .settings }
        }
    }

    private var timeline: some View {
        let upcoming = model.upcoming
        // Oldest first, so the timeline reads top to bottom through today.
        let past = model.settings.showPastEvents ? Array(model.past.reversed()) : []
        let items = past + upcoming

        if items.isEmpty && model.filter.isActive {
            return AnyView(NoMatchesView())
        }

        return AnyView(ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        if index > 0 {
                            let previous = items[index - 1]
                            TimelineConnector(
                                gap: previous.day.days(until: item.day),
                                today: index == past.count ? model.today : nil
                            )
                            .padding(.trailing, 12)
                            .id(Self.connectorID(before: item))
                        }
                        card(item, isPast: index < past.count)
                    }

                    if upcoming.isEmpty && !model.filter.isActive {
                        Text("Nothing ahead. Add something to look forward to!")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 40)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 90)
            }
            .scrollIndicators(.never)
            .onAppear { scrollToToday(proxy, past: past, upcoming: upcoming) }
            .onChange(of: model.settings.showPastEvents) { scrollToToday(proxy, past: past, upcoming: upcoming) }
        })
    }

    private static func connectorID(before item: TimelineItem) -> String { "connector-\(item.id)" }

    /// Past events sit above; start at the today marker so upcoming ones are in view.
    private func scrollToToday(_ proxy: ScrollViewProxy, past: [TimelineItem], upcoming: [TimelineItem]) {
        guard !past.isEmpty, let first = upcoming.first else { return }
        proxy.scrollTo(Self.connectorID(before: first), anchor: .top)
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

private struct FilterPanel: View {
    @Environment(AppModel.self) private var model
    @FocusState private var searchFocused: Bool

    var body: some View {
        @Bindable var model = model
        let icons = EventFilter.availableIcons(in: model.store.events)

        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Event name", text: $model.filter.query)
                    .textFieldStyle(.plain)
                    .focused($searchFocused)
                if !model.filter.query.isEmpty {
                    Button { model.filter.query = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("Clear"))
                }
            }
            .padding(10)
            .background(Theme.field, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            if icons.count > 1 {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 40, maximum: 44), spacing: 6)], spacing: 6) {
                    ForEach(icons, id: \.self) { icon in
                        let isSelected = model.filter.icons.contains(icon)
                        Button {
                            if isSelected { model.filter.icons.remove(icon) } else { model.filter.icons.insert(icon) }
                        } label: {
                            Image(systemName: icon)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(isSelected ? Color.accentColor : .primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                                .background(
                                    isSelected ? Color.accentColor.opacity(0.18) : .clear,
                                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                                )
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                    }
                }
            }

            if model.filter.isActive {
                Button("Clear") { model.filter = EventFilter() }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .onAppear { searchFocused = true }
        .overlay(alignment: .bottom) { Divider().opacity(0.5) }
    }
}

private struct NoMatchesView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text("No matching events")
                .font(.system(.title3, design: .rounded).weight(.bold))
            Button("Clear") { model.filter = EventFilter() }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
