import Foundation
import Observation

/// Persists events as a JSON file in Application Support.
@MainActor
@Observable
final class EventStore {
    private(set) var events: [Event] = []
    private(set) var lastError: String?

    @ObservationIgnored private let fileURL: URL

    init(fileURL: URL = EventStore.defaultFileURL) {
        self.fileURL = fileURL
        load()
    }

    nonisolated static var defaultFileURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("UpNextBar", isDirectory: true)
            .appendingPathComponent("events.json")
    }

    func event(withID id: UUID) -> Event? {
        events.first { $0.id == id }
    }

    func upsert(_ event: Event) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
        } else {
            events.append(event)
        }
        save()
    }

    func delete(id: UUID) {
        events.removeAll { $0.id == id }
        save()
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            events = try JSONDecoder().decode(EventsFile.self, from: data).events
        } catch {
            // Move the unreadable file aside so the next save doesn't overwrite the user's data.
            let backup = fileURL.deletingPathExtension()
                .appendingPathExtension("corrupt-\(Int(Date().timeIntervalSince1970)).json")
            try? FileManager.default.moveItem(at: fileURL, to: backup)
            lastError = error.localizedDescription
        }
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(EventsFile(events: events)).write(to: fileURL, options: .atomic)
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }
}

/// On-disk format. `version` leaves room for migrations.
private struct EventsFile: Codable {
    var version = 1
    var events: [Event]
}
