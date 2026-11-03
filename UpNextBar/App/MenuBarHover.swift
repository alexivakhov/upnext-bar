import AppKit
import SwiftUI

/// Shows the month calendar while the pointer rests on the menu bar icon, without a click.
///
/// `MenuBarExtra` has no hover hook, so this finds the status item's button and compares the
/// pointer position with its frame. It deliberately doesn't touch the button itself (no tracking
/// area, no popover anchored to it), so a click still opens the regular popup on its own. The
/// calendar is a separate non-activating panel that stays up while the pointer is over the icon
/// or the panel and closes shortly after it leaves.
@MainActor
final class MenuBarHover {
    private let model: AppModel
    private var button: NSStatusBarButton?
    private var panel: NSPanel?
    private var pending: Task<Void, Never>?
    private var monitors: [Any] = []
    /// Set by a click on the icon; keeps the calendar away until the pointer leaves it.
    private var isSuppressed = false

    private let showDelay: Duration = .milliseconds(250)
    private let hideDelay: Duration = .milliseconds(200)

    init(model: AppModel) {
        self.model = model
        guard !AppModel.isRunningTests else { return }
        Task { await attachWhenButtonExists() }
    }

    // MARK: - Finding the status item

    /// The status item is created by SwiftUI shortly after launch, so look for it until it appears.
    private func attachWhenButtonExists() async {
        for _ in 0..<50 {
            if let found = Self.findStatusButton() {
                button = found
                startMonitoring()
                return
            }
            try? await Task.sleep(for: .milliseconds(200))
        }
    }

    private static func findStatusButton() -> NSStatusBarButton? {
        for window in NSApp.windows {
            if let button = window.contentView.flatMap(statusButton(in:)) { return button }
        }
        return nil
    }

    private static func statusButton(in view: NSView) -> NSStatusBarButton? {
        if let button = view as? NSStatusBarButton { return button }
        for subview in view.subviews {
            if let button = statusButton(in: subview) { return button }
        }
        return nil
    }

    /// The icon's frame in screen coordinates.
    private var buttonFrame: NSRect? {
        guard let button, let window = button.window else { return nil }
        return window.convertToScreen(button.convert(button.bounds, to: nil))
    }

    // MARK: - Pointer tracking

    private func startMonitoring() {
        // Global monitors see events for other apps' windows, local ones for ours (the popup, the calendar).
        let moved: NSEvent.EventTypeMask = .mouseMoved
        let clicked: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown]
        if let monitor = NSEvent.addGlobalMonitorForEvents(matching: moved, handler: { [weak self] _ in
            Task { @MainActor in self?.pointerMoved() }
        }) { monitors.append(monitor) }
        if let monitor = NSEvent.addLocalMonitorForEvents(matching: moved, handler: { [weak self] event in
            self?.pointerMoved()
            return event
        }) { monitors.append(monitor) }
        for handler in [{ [weak self] in self?.pointerPressed() }] as [@MainActor () -> Void] {
            if let monitor = NSEvent.addGlobalMonitorForEvents(matching: clicked, handler: { _ in
                Task { @MainActor in handler() }
            }) { monitors.append(monitor) }
            if let monitor = NSEvent.addLocalMonitorForEvents(matching: clicked, handler: { event in
                handler()
                return event
            }) { monitors.append(monitor) }
        }
    }

    private func pointerMoved() {
        guard let buttonFrame else { return }
        let location = NSEvent.mouseLocation
        let overButton = buttonFrame.contains(location)
        if !overButton { isSuppressed = false }

        // The area between the icon and the calendar counts as hovered too, so crossing the gap doesn't close it.
        let hovered = panel.map { buttonFrame.union($0.frame).insetBy(dx: -2, dy: -2).contains(location) } ?? overButton

        if hovered {
            if panel == nil, overButton, !isSuppressed { scheduleShow() } else { pending?.cancel() }
        } else if panel != nil {
            scheduleHide()
        } else {
            pending?.cancel()
        }
    }

    private func pointerPressed() {
        guard let buttonFrame else { return }
        if buttonFrame.contains(NSEvent.mouseLocation) { isSuppressed = true }
        closeNow()
    }

    private func scheduleShow() {
        schedule(after: showDelay) { [self] in
            guard let buttonFrame, buttonFrame.contains(NSEvent.mouseLocation), !isSuppressed else { return }
            show()
        }
    }

    private func scheduleHide() {
        schedule(after: hideDelay) { [self] in closeNow() }
    }

    /// Replaces any scheduled action; running the same one twice in a row keeps the first timer.
    private func schedule(after delay: Duration, _ action: @escaping @MainActor () -> Void) {
        pending?.cancel()
        pending = Task {
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            action()
        }
    }

    // MARK: - Panel

    private func show() {
        guard panel == nil, let button, let buttonFrame else { return }
        // The button is highlighted while the regular popup is open; don't stack the calendar on it.
        guard !button.isHighlighted else { return }

        model.refreshTodayIfNeeded()
        let host = NSHostingView(rootView: MonthCalendarView().environment(model))
        let size = host.fittingSize

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentView = host
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]

        let screen = NSScreen.screens.first { $0.frame.intersects(buttonFrame) } ?? NSScreen.main
        var origin = NSPoint(x: buttonFrame.midX - size.width / 2, y: buttonFrame.minY - size.height - 6)
        if let visible = screen?.visibleFrame {
            origin.x = min(max(origin.x, visible.minX + 8), visible.maxX - size.width - 8)
        }
        panel.setFrameOrigin(origin)
        panel.orderFrontRegardless()
        self.panel = panel
    }

    private func closeNow() {
        pending?.cancel()
        panel?.orderOut(nil)
        panel = nil
    }
}
