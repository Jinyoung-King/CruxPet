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

@Observable
class SparkleDelegate: NSObject, SPUUpdaterDelegate {
    var updateAvailable = false

    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        updateAvailable = true
    }
}

// Intercepts right-click on the status bar button and shows a context menu.
// SwiftUI's MenuBarExtra doesn't expose NSStatusItem, so we find the
// NSStatusBarButton by scanning NSApp.windows for the NSStatusBarWindow.
class StatusItemRightClickHandler: NSObject {
    private let updaterController: SPUStandardUpdaterController
    private weak var button: NSStatusBarButton?
    private var originalAction: Selector?
    private var originalTarget: AnyObject?
    private var installed = false

    init(updaterController: SPUStandardUpdaterController) {
        self.updaterController = updaterController
    }

    func install() {
        guard !installed, let button = findStatusBarButton() else { return }
        installed = true
        self.button = button
        originalAction = button.action
        originalTarget = button.target as AnyObject?
        button.target = self
        button.action = #selector(handleClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showContextMenu(from: sender)
        } else {
            // Forward left-click to SwiftUI's original handler
            if let target = originalTarget, let action = originalAction {
                _ = target.perform(action, with: sender)
            }
        }
    }

    private func showContextMenu(from button: NSStatusBarButton) {
        let menu = NSMenu()
        let item = NSMenuItem(
            title: "업데이트 확인",
            action: #selector(SPUStandardUpdaterController.checkForUpdates(_:)),
            keyEquivalent: ""
        )
        item.target = updaterController
        menu.addItem(item)
        menu.popUp(positioning: nil,
                   at: NSPoint(x: 0, y: button.bounds.height + 4),
                   in: button)
    }

    private func findStatusBarButton() -> NSStatusBarButton? {
        for window in NSApp.windows {
            let className = String(describing: type(of: window))
            guard className.contains("StatusBar") else { continue }
            if let button = findButton(in: window.contentView) { return button }
        }
        return nil
    }

    private func findButton(in view: NSView?) -> NSStatusBarButton? {
        guard let view = view else { return nil }
        if let b = view as? NSStatusBarButton { return b }
        for sub in view.subviews {
            if let b = findButton(in: sub) { return b }
        }
        return nil
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
    @State private var pet = PetModel()
    @State private var pomodoro = PomodoroTimer()
    @State private var watcher = EventWatcher()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environment(pet)
                .environment(pomodoro)
                .environment(watcher)
            if sparkleDelegate.updateAvailable {
                Divider()
                Button("🆕 업데이트 설치") {
                    updaterController.updater.checkForUpdates()
                }
            }
        } label: {
            Group {
                switch pomodoro.state {
                case .running:
                    Image(systemName: "timer")
                        .symbolEffect(.variableColor.iterative, options: .repeating)
                case .paused:
                    Image(systemName: "timer")
                default:
                    Image(systemName: pet.emotion == .sleepy ? "zzz" : "pawprint.fill")
                }
            }
            .onAppear { startServices() }
        }
        .menuBarExtraStyle(.window)
    }

    private func startServices() {
        watcher.onCommit = { pet.gainCommitExp() }
        pomodoro.onComplete = {
            watcher.appendPomodoro()
            pet.gainPomodoroExp()
            sendPomodoroNotification()
        }
        watcher.start()
        // Retry with delays — the NSStatusBarWindow may not exist yet on first onAppear
        for delay in [0.1, 0.3, 0.8] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                rightClickHandler.install()
            }
        }
    }

    private func sendPomodoroNotification() {
        let content = UNMutableNotificationContent()
        content.title = "포모도로 완료! 🍅"
        content.body = "EXP 획득! 슬라임이 기뻐해요."
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
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
