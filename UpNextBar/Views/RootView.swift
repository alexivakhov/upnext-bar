import SwiftUI

/// Content of the menu bar popup. Screens are swapped in place, like pushing in a navigation stack.
struct RootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ZStack {
            switch model.route {
            case .list:
                EventListView()
                    .transition(.move(edge: .leading).combined(with: .opacity))
            case .newEvent:
                EventEditorView(event: nil, today: model.today)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .editEvent(let id):
                EventEditorView(event: model.store.event(withID: id), today: model.today)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .settings:
                SettingsView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .frame(width: Theme.width, height: Theme.height)
        .background(Theme.background)
        .animation(.snappy(duration: 0.28), value: model.route)
        .onAppear { model.refreshTodayIfNeeded() }
    }
}
