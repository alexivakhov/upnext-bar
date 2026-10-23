import SwiftUI
import UserNotifications

struct EventEditorView: View {
    @Environment(AppModel.self) private var model

    private let isNew: Bool
    @State private var draft: Event
    @State private var showDatePicker = false
    @State private var showAllIcons = false
    @State private var confirmDelete = false
    @FocusState private var titleFocused: Bool

    init(event: Event?, today: CalendarDay) {
        isNew = event == nil
        _draft = State(initialValue: event ?? Event(date: today))
    }

    private var tint: Color { draft.color.color }
    private var trimmedTitle: String { draft.title.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmedTitle.isEmpty }

    var body: some View {
        let title: LocalizedStringKey = isNew ? "New event" : "Edit event"
        let saveTitle: LocalizedStringKey = isNew ? "Add" : "Save"

        VStack(spacing: 0) {
            SheetHeader(title) {
                CircleIconButton("xmark", help: "Cancel") { model.route = .list }
                    .keyboardShortcut(.cancelAction)
            } trailing: {
                Button(action: save) {
                    Text(saveTitle).padding(.horizontal, 4)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .tint(tint)
                .disabled(!canSave)
                .keyboardShortcut(.defaultAction)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    nameSection
                    dateSection
                    iconSection
                    colorSection
                    reminderSection
                    if !isNew { deleteButton }
                }
                .padding(16)
            }
            .scrollIndicators(.never)
        }
        .onAppear { if isNew { titleFocused = true } }
        .confirmation(
            "Delete event?",
            message: Text("“\(draft.title)” will be removed."),
            actionTitle: "Delete",
            isPresented: $confirmDelete
        ) {
            model.delete(id: draft.id)
            model.route = .list
        }
        .task { await model.refreshNotificationStatus() }
    }

    // MARK: - Sections

    private var nameSection: some View {
        FieldSection("Name") {
            TextField("Birthday, trip, payment…", text: $draft.title)
                .textFieldStyle(.plain)
                .font(.title3.weight(.medium))
                .padding(12)
                .background(Theme.field, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .focused($titleFocused)
                .onSubmit(save)
        }
    }

    private var dateSection: some View {
        FieldSection("Date") {
            HStack {
                Button {
                    showDatePicker.toggle()
                } label: {
                    Text(draft.date.formatted)
                        .font(.headline)
                        .foregroundStyle(tint)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showDatePicker, arrowEdge: .bottom) {
                    DatePicker("Date", selection: dateBinding, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .padding(12)
                }

                Spacer()

                Picker(selection: $draft.recurrence) {
                    ForEach(Recurrence.allCases) { recurrence in
                        Text(recurrence.title).tag(recurrence)
                    }
                } label: {
                    Image(systemName: "repeat")
                }
                .pickerStyle(.menu)
                .fixedSize()
                .help(Text("Repeat"))
            }

            if let followingDates {
                followingDates
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)
            }
        }
    }

    /// For a repeating event, the two occurrences after the date shown above, or the next two when that date has passed.
    private var followingDates: Text? {
        guard draft.recurrence != .never else { return nil }
        let today = model.today
        let dates = Schedule.occurrences(of: draft.date, recurrence: draft.recurrence, onOrAfter: today, count: 3)
        let style = Date.FormatStyle.dateTime.day(.twoDigits).month(.twoDigits).year(.twoDigits)
        if draft.date >= today {
            let list = dates.dropFirst().map { $0.date().formatted(style) }.joined(separator: ", ")
            return Text("Then \(list)…")
        } else {
            let list = dates.prefix(2).map { $0.date().formatted(style) }.joined(separator: ", ")
            return Text("Next: \(list)…")
        }
    }

    private var iconSection: some View {
        FieldSection("Icon") {
            VStack(alignment: .trailing, spacing: 8) {
                IconGrid(icons: visibleIcons, selection: $draft.icon, tint: tint, columns: 6)
                    .padding(8)
                    .background(Theme.field, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                Button("More…") { showAllIcons = true }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .popover(isPresented: $showAllIcons, arrowEdge: .bottom) {
                        ScrollView {
                            IconGrid(icons: EventIcon.all, selection: iconSelectionClosingPopover, tint: tint, columns: 7)
                                .padding(10)
                        }
                        .frame(width: 330, height: 300)
                    }
            }
        }
    }

    private var colorSection: some View {
        FieldSection("Color") {
            HStack(spacing: 0) {
                ForEach(EventColor.allCases) { color in
                    Button {
                        draft.color = color
                    } label: {
                        Circle()
                            .fill(color.color.gradient)
                            .frame(width: 30, height: 30)
                            .padding(4)
                            .overlay {
                                if draft.color == color {
                                    Circle().strokeBorder(.primary, lineWidth: 2.5)
                                }
                            }
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .help(Text(color.name))
                    .accessibilityLabel(Text(color.name))
                    .accessibilityAddTraits(draft.color == color ? .isSelected : [])
                }
            }
        }
    }

    private var reminderSection: some View {
        FieldSection("Reminder") {
            VStack(alignment: .leading, spacing: 8) {
                Picker("Reminder", selection: $draft.reminder) {
                    ForEach(ReminderOption.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                if draft.reminder != .none {
                    if model.notificationStatus == .denied || !model.bannersEnabled {
                        VStack(alignment: .leading, spacing: 4) {
                            Label(
                                model.notificationStatus == .denied
                                    ? "Notifications are turned off for UpNext Bar in System Settings."
                                    : "Banners are off for UpNext Bar, so reminders won't pop up on screen.",
                                systemImage: "exclamationmark.triangle.fill"
                            )
                            .foregroundStyle(.orange)
                            Button("Open Settings…") { model.openNotificationSettings() }
                                .buttonStyle(.link)
                        }
                        .font(.caption)
                    } else {
                        Text("Notification at \(reminderTime). You can change the time in Settings.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .task { await model.refreshNotificationStatus() }
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            confirmDelete = true
        } label: {
            Label("Delete event", systemImage: "trash")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .padding(.top, 8)
    }

    // MARK: - Helpers

    /// The featured icons, with the current choice swapped in if it came from "More…".
    private var visibleIcons: [String] {
        var icons = EventIcon.featured
        if !icons.contains(draft.icon) {
            icons[icons.count - 1] = draft.icon
        }
        return icons
    }

    private var iconSelectionClosingPopover: Binding<String> {
        Binding(
            get: { draft.icon },
            set: { draft.icon = $0; showAllIcons = false }
        )
    }

    private var dateBinding: Binding<Date> {
        Binding(
            get: { draft.date.date() },
            set: { draft.date = CalendarDay($0) }
        )
    }

    private var reminderTime: String {
        draft.date.date(at: model.settings.reminderHour).formatted(date: .omitted, time: .shortened)
    }

    private func save() {
        guard canSave else { return }
        draft.title = trimmedTitle
        model.save(draft)
        model.route = .list
    }
}

private struct IconGrid: View {
    let icons: [String]
    @Binding var selection: String
    let tint: Color
    let columns: Int

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: columns), spacing: 6) {
            ForEach(icons, id: \.self) { icon in
                let isSelected = icon == selection
                Button {
                    selection = icon
                } label: {
                    Image(systemName: icon)
                        .font(.system(size: 19, weight: .medium))
                        .foregroundStyle(isSelected ? tint : .primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(
                            isSelected ? tint.opacity(0.18) : .clear,
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}
