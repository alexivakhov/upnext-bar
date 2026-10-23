import AppKit
import SwiftUI
import UserNotifications

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @State private var launchAtLogin = LaunchAtLogin.isEnabled
    @State private var launchAtLoginError: String?

    var body: some View {
        @Bindable var settings = model.settings

        VStack(spacing: 0) {
            SheetHeader("Settings") {
                CircleIconButton("chevron.left", help: "Back") { model.route = .list }
                    .keyboardShortcut(.cancelAction)
            } trailing: {
                Color.clear.frame(width: 30, height: 30)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    SettingsGroup("General") {
                        SettingsRow("Launch at login", icon: "power", tint: .green) {
                            Toggle("Launch at login", isOn: $launchAtLogin)
                        }
                        if let launchAtLoginError {
                            Text(launchAtLoginError)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding(.leading, 48)
                        }
                        SettingsRow("Show next event in menu bar", icon: "menubar.rectangle", tint: .blue) {
                            Toggle("Show next event in menu bar", isOn: $settings.showNextEventInMenuBar)
                        }
                        SettingsRow("Show past events", icon: "clock.arrow.circlepath", tint: .gray) {
                            Toggle("Show past events", isOn: $settings.showPastEvents)
                        }
                    }

                    SettingsGroup("Reminders") {
                        SettingsRow("Reminder time", icon: "bell.fill", tint: .orange) {
                            Picker("Reminder time", selection: $settings.reminderHour) {
                                ForEach(0..<24, id: \.self) { hour in
                                    Text(hourLabel(hour)).tag(hour)
                                }
                            }
                            .labelsHidden()
                            .fixedSize()
                        }
                        SettingsRow("Notifications", icon: "app.badge.fill", tint: .pink) {
                            notificationStatus
                        }
                    }

                    SettingsGroup("App") {
                        SettingsRow("Appearance", icon: "circle.lefthalf.filled", tint: .indigo) {
                            Picker("Appearance", selection: $settings.appearance) {
                                ForEach(AppearanceMode.allCases) { mode in
                                    Label(mode.title, systemImage: mode.icon)
                                        .labelStyle(.iconOnly)
                                        .help(Text(mode.title))
                                        .tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            .fixedSize()
                        }
                        SettingsRow("Language", icon: "globe", tint: .teal) {
                            Picker("Language", selection: languageSelection) {
                                ForEach(AppLanguage.allCases) { language in
                                    Text(verbatim: language.nativeName).tag(language)
                                }
                            }
                            .fixedSize()
                        }
                        Text("UpNext Bar restarts to switch the language.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 48)
                        SettingsRow("Version", icon: "info.circle.fill", tint: .purple) {
                            Text(appVersion).foregroundStyle(.secondary)
                        }
                    }

                    Button(role: .destructive) {
                        NSApp.terminate(nil)
                    } label: {
                        Label("Quit UpNext Bar", systemImage: "power")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .keyboardShortcut("q", modifiers: .command)
                }
                .padding(16)
            }
            .scrollIndicators(.never)
        }
        .toggleStyle(.switch)
        .onChange(of: launchAtLogin) { _, enabled in
            do {
                try LaunchAtLogin.setEnabled(enabled)
                launchAtLoginError = nil
            } catch {
                launchAtLoginError = error.localizedDescription
                launchAtLogin = LaunchAtLogin.isEnabled
            }
        }
        .onChange(of: settings.reminderHour) {
            model.rescheduleReminders()
        }
        .onChange(of: settings.appearance) {
            model.applyAppearance()
        }
        .task { await model.refreshNotificationStatus() }
        // The user may come back from System Settings with this screen still open.
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            Task { await model.refreshNotificationStatus() }
        }
    }

    private var languageSelection: Binding<AppLanguage> {
        Binding(get: { model.settings.language }, set: { model.changeLanguage(to: $0) })
    }

    @ViewBuilder
    private var notificationStatus: some View {
        switch model.notificationStatus {
        case .authorized, .provisional:
            HStack(spacing: 6) {
                if model.bannersEnabled {
                    Label("On", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Label("Banners off", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
                CircleIconButton("arrow.up.forward", help: "Open Settings…") {
                    model.openNotificationSettings()
                }
            }
        case .denied:
            Button("Open Settings…") {
                model.openNotificationSettings()
            }
        default:
            Button("Allow") {
                Task {
                    await model.requestNotificationsIfNeeded()
                    model.rescheduleReminders()
                }
            }
        }
    }

    private func hourLabel(_ hour: Int) -> String {
        model.today.date(at: hour).formatted(date: .omitted, time: .shortened)
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }
}

private struct SettingsGroup<Content: View>: View {
    let title: LocalizedStringKey
    let content: Content

    init(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            VStack(alignment: .leading, spacing: 4) {
                content
            }
            .padding(10)
            .background(Theme.field, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

/// A row with a coloured rounded icon, a title and a trailing control.
private struct SettingsRow<Trailing: View>: View {
    let title: LocalizedStringKey
    let icon: String
    let tint: Color
    let trailing: Trailing

    init(_ title: LocalizedStringKey, icon: String, tint: Color, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.icon = icon
        self.tint = tint
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            Text(title)
                .font(.body.weight(.medium))
            Spacer(minLength: 8)
            trailing
                .labelsHidden()
        }
        .frame(minHeight: 40)
    }
}
