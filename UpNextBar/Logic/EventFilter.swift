import Foundation

/// The popup's filter: events must match the name text and, when icons are picked, use one of them.
struct EventFilter: Equatable, Sendable {
    var query = ""
    var icons: Set<String> = []

    private var trimmedQuery: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }

    var isActive: Bool { !trimmedQuery.isEmpty || !icons.isEmpty }

    func matches(_ event: Event) -> Bool {
        if !icons.isEmpty && !icons.contains(event.icon) { return false }
        let query = trimmedQuery
        return query.isEmpty || event.title.localizedStandardContains(query)
    }

    func apply(to items: [TimelineItem]) -> [TimelineItem] {
        isActive ? items.filter { matches($0.event) } : items
    }

    /// Icons in use, in the order the editor offers them, so the filter shows only choices that can match.
    static func availableIcons(in events: [Event]) -> [String] {
        let used = Set(events.map(\.icon))
        let known = EventIcon.all.filter(used.contains)
        let custom = used.subtracting(known).sorted()
        return known + custom
    }
}
