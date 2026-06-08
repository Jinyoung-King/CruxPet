import Foundation
import Observation

struct PetEvent {
    let type: String
    let timestamp: Double
}

@MainActor @Observable
class EventWatcher {
    private var pollTimer: Timer?
    private let eventsURL = URL(fileURLWithPath: NSHomeDirectory())
        .appendingPathComponent(".cruxpet/events.json")
    var onCommit: (() -> Void)?
    var onPomodoro: (() -> Void)?
    var pendingCommit = false

    func start() {
        guard pollTimer == nil else { return }
        createEventsFileIfNeeded()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.poll()
            }
        }
    }

    func stop() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    func appendPomodoro() {
        let entry = "{\"type\":\"pomodoro\",\"timestamp\":\(Date().timeIntervalSince1970)}\n"
        if let data = entry.data(using: .utf8) {
            if let handle = try? FileHandle(forWritingTo: eventsURL) {
                handle.seekToEndOfFile()
                handle.write(data)
                handle.closeFile()
            }
        }
    }

    // MARK: - Pure static logic (테스트 가능)

    nonisolated static func parseLines(_ content: String) -> [PetEvent] {
        content.split(separator: "\n", omittingEmptySubsequences: true)
            .compactMap { line -> PetEvent? in
                guard let data = line.data(using: .utf8),
                      let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let type = obj["type"] as? String,
                      let ts = obj["timestamp"] as? Double else { return nil }
                return PetEvent(type: type, timestamp: ts)
            }
    }

    nonisolated static func filterNew(events: [PetEvent], after lastProcessed: Double) -> [PetEvent] {
        events.filter { $0.timestamp > lastProcessed }
    }

    // MARK: - Private

    private func poll() {
        guard let content = try? String(contentsOf: eventsURL, encoding: .utf8) else { return }
        let lastProcessed = UserDefaults.standard.double(forKey: "cruxpet.lastProcessed")
        let newEvents = EventWatcher.filterNew(
            events: EventWatcher.parseLines(content),
            after: lastProcessed
        )
        guard !newEvents.isEmpty else { return }

        let maxTs = newEvents.map(\.timestamp).max() ?? lastProcessed
        UserDefaults.standard.set(maxTs, forKey: "cruxpet.lastProcessed")

        for event in newEvents {
            switch event.type {
            case "commit":   pendingCommit = true; onCommit?()
            case "pomodoro": onPomodoro?()
            default: break
            }
        }
    }

    private func createEventsFileIfNeeded() {
        let dir = eventsURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        if !FileManager.default.fileExists(atPath: eventsURL.path) {
            FileManager.default.createFile(atPath: eventsURL.path, contents: nil)
        }
    }
}
