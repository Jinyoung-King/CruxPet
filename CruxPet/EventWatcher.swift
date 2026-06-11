import Foundation
import Observation
import UserNotifications

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
        poll()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.poll()
            }
        }
    }

    func pollNow() {
        poll()
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

    nonisolated static func activityDays(from content: String, last n: Int, relativeTo date: Date = Date()) -> Set<String> {
        let calendar = Calendar.current
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = calendar.timeZone

        var validDays = Set<String>()
        for i in 0..<n {
            if let d = calendar.date(byAdding: .day, value: -i, to: date) {
                validDays.insert(fmt.string(from: d))
            }
        }

        let events = parseLines(content)
        return Set(events.compactMap { event -> String? in
            let dateStr = fmt.string(from: Date(timeIntervalSince1970: event.timestamp))
            return validDays.contains(dateStr) ? dateStr : nil
        })
    }

    nonisolated func activityDays(last n: Int) -> Set<String> {
        guard let content = try? String(contentsOf: eventsURL, encoding: .utf8) else { return [] }
        return EventWatcher.activityDays(from: content, last: n)
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
            case "commit":   pendingCommit = true; sendCommitNotification(); onCommit?()
            case "pomodoro": onPomodoro?()
            default: break
            }
        }
    }

    private func sendCommitNotification() {
        let content = UNMutableNotificationContent()
        content.title = "커밋 감지! ⚡️"
        content.body = "EXP를 획득했어요."
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func createEventsFileIfNeeded() {
        let dir = eventsURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        if !FileManager.default.fileExists(atPath: eventsURL.path) {
            FileManager.default.createFile(atPath: eventsURL.path, contents: nil)
        }
    }
}
