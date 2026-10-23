import SwiftUI

@main
struct UpNextBarApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            RootView()
                .environment(model)
        } label: {
            MenuBarLabel(model: model)
        }
        .menuBarExtraStyle(.window)
    }
}

private struct MenuBarLabel: View {
    let model: AppModel

    var body: some View {
        if model.settings.showNextEventInMenuBar, let next = model.upcoming.first {
            HStack(spacing: 4) {
                Image(systemName: next.event.icon)
                Text(Countdown.short(daysLeft: next.daysLeft))
            }
        } else {
            Image(systemName: "binoculars.fill")
        }
    }
}
