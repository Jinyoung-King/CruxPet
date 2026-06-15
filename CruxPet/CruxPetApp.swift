import SwiftUI
import UserNotifications
import Sparkle

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}

class StatusItemRightClickHandler: NSObject {
    private let updaterController: SPUStandardUpdaterController
    private var eventMonitor: Any?

    init(updaterController: SPUStandardUpdaterController) {
        self.updaterController = updaterController
    }

    func install() {
        guard eventMonitor == nil else { return }
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .rightMouseDown) { [weak self] _ in
            self?.handleGlobalRightClick()
        }
    }

    deinit {
        if let m = eventMonitor { NSEvent.removeMonitor(m) }
    }

    private func handleGlobalRightClick() {
        let loc = NSEvent.mouseLocation
        guard let frame = statusItemFrame(), frame.contains(loc) else { return }
        DispatchQueue.main.async { [weak self] in self?.showContextMenu(at: loc) }
    }

    private func statusItemFrame() -> NSRect? {
        NSApp.windows
            .first { NSStringFromClass(type(of: $0)).contains("StatusBar") }?
            .frame
    }

    private func showContextMenu(at point: NSPoint) {
        let menu = NSMenu()
        let item = NSMenuItem(
            title: "업데이트 확인",
            action: #selector(SPUStandardUpdaterController.checkForUpdates(_:)),
            keyEquivalent: ""
        )
        item.target = updaterController
        menu.addItem(item)
        menu.popUp(positioning: nil, at: point, in: nil)
    }
}

private struct CheckForUpdatesKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}
extension EnvironmentValues {
    var checkForUpdates: () -> Void {
        get { self[CheckForUpdatesKey.self] }
        set { self[CheckForUpdatesKey.self] = newValue }
    }
}

@Observable
class SparkleDelegate: NSObject, SPUUpdaterDelegate {
    var updateAvailable = false

    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        updateAvailable = true
    }
}


@main
struct CruxPetApp: App {
    private let sparkleDelegate = SparkleDelegate()
    private let updaterController: SPUStandardUpdaterController
    private let notificationDelegate = NotificationDelegate()
    private let rightClickHandler: StatusItemRightClickHandler

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true, updaterDelegate: sparkleDelegate, userDriverDelegate: nil
        )
        rightClickHandler = StatusItemRightClickHandler(updaterController: updaterController)
        let center = UNUserNotificationCenter.current()
        center.delegate = notificationDelegate
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
        if !UserDefaults.standard.bool(forKey: "cruxpet.hookInstalled") {
            CruxPetApp.installGitHook()
            UserDefaults.standard.set(true, forKey: "cruxpet.hookInstalled")
        }
    }
    @State private var history = ActivityHistoryModel()  // pet보다 먼저 — 어제 데이터 캡처 타이밍 보장
    @State private var pet = PetModel()
    @State private var pomodoro = PomodoroTimer()
    @State private var watcher = EventWatcher()
    @State private var environment = EnvironmentModel()
    @State private var interaction = PetInteractionModel()

    var body: some Scene {
        MenuBarExtra {
            let updater = updaterController.updater
            ContentView()
                .environment(pet)
                .environment(pomodoro)
                .environment(watcher)
                .environment(environment)
                .environment(interaction)
                .environment(history)
                .environment(\.checkForUpdates, { updater.checkForUpdates() })
        } label: {
            Group {
                if sparkleDelegate.updateAvailable {
                    Image(systemName: "exclamationmark.circle.fill")
                } else {
                    switch pomodoro.state {
                    case .running:
                        Image(systemName: "timer")
                            .symbolEffect(.variableColor.iterative, options: .repeating)
                    case .paused:
                        Image(systemName: "timer")
                    case .shortBreak, .longBreak:
                        Image(systemName: "cup.and.saucer.fill")
                    default:
                        Image(systemName: pet.emotion == .sleepy ? "zzz" : "pawprint.fill")
                    }
                }
            }
            .onAppear { startServices() }
        }
        .menuBarExtraStyle(.window)
    }

    private func startServices() {
        watcher.onCommit = {
            pet.gainCommitExp()
            Self.cancelStreakReminder()
        }
        pomodoro.onComplete = {
            watcher.appendPomodoro()
            pet.gainPomodoroExp()
            sendPomodoroNotification()
            Self.cancelStreakReminder()
        }
        pomodoro.breakComplete = {
            sendBreakCompleteNotification()
        }
        watcher.start()
        updaterController.updater.checkForUpdatesInBackground()
        rightClickHandler.install()
        environment.startUpdating()
        scheduleStreakReminderIfNeeded()
    }

    private func sendBreakCompleteNotification() {
        let content = UNMutableNotificationContent()
        content.title = "CruxPet 🍅"
        content.body = "집중 시작!"
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func sendPomodoroNotification() {
        let content = UNMutableNotificationContent()
        content.title = "포모도로 완료! 🍅"
        content.body = "EXP 획득! 슬라임이 기뻐해요."
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func scheduleStreakReminderIfNeeded() {
        guard pet.todayCommitCount == 0, pet.todayPomodoroCount == 0 else { return }
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 20
        components.minute = 0
        guard let fireDate = calendar.date(from: components), fireDate > Date() else { return }
        let content = UNMutableNotificationContent()
        content.title = "CruxPet 🐾"
        content.body = "오늘 아직 활동이 없어요. 펫이 기다리고 있어요!"
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate),
            repeats: false
        )
        let request = UNNotificationRequest(identifier: "streak.reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private static func cancelStreakReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["streak.reminder"])
    }

    private static func installGitHook() {
        let script = #"""
            set -e
            HOOKS_DIR="$HOME/.config/git/hooks"
            HOOK_FILE="$HOOKS_DIR/post-commit"
            HOOK_LINE='echo "{\"type\":\"commit\",\"timestamp\":$(date +%s)}" >> "$HOME/.cruxpet/events.json"'
            mkdir -p "$HOOKS_DIR" "$HOME/.cruxpet"
            touch "$HOME/.cruxpet/events.json"
            if [ ! -f "$HOOK_FILE" ]; then
                printf '#!/bin/sh\n%s\n' "$HOOK_LINE" > "$HOOK_FILE"
            elif ! grep -qF "cruxpet" "$HOOK_FILE"; then
                printf '\n# CruxPet\n%s\n' "$HOOK_LINE" >> "$HOOK_FILE"
            fi
            chmod +x "$HOOK_FILE"
            git config --global core.hooksPath "$HOOKS_DIR"
        """#
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", script]
        try? process.run()
        process.waitUntilExit()
    }
}
