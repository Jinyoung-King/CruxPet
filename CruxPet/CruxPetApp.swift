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
        guard let iconRect = iconRectInAppKitCoords(),
              iconRect.contains(NSEvent.mouseLocation) else { return }
        DispatchQueue.main.async { [weak self] in self?.showContextMenu(near: iconRect) }
    }

    private func showContextMenu(near rect: NSRect) {
        let menu = NSMenu()
        let item = NSMenuItem(
            title: "업데이트 확인",
            action: #selector(SPUStandardUpdaterController.checkForUpdates(_:)),
            keyEquivalent: ""
        )
        item.target = updaterController
        menu.addItem(item)
        menu.popUp(positioning: nil, at: NSPoint(x: rect.minX, y: rect.minY), in: nil)
    }

    private func iconRectInAppKitCoords() -> NSRect? {
        let axApp = AXUIElementCreateApplication(pid_t(ProcessInfo.processInfo.processIdentifier))
        var menuBar: CFTypeRef?
        guard AXUIElementCopyAttributeValue(axApp, "AXExtrasMenuBar" as CFString, &menuBar) == .success,
              let mb = menuBar else { return nil }
        var children: CFTypeRef?
        guard AXUIElementCopyAttributeValue(mb as! AXUIElement, kAXChildrenAttribute as CFString, &children) == .success,
              let first = (children as? [AXUIElement])?.first else { return nil }
        var posRef: CFTypeRef?, sizeRef: CFTypeRef?
        AXUIElementCopyAttributeValue(first, kAXPositionAttribute as CFString, &posRef)
        AXUIElementCopyAttributeValue(first, kAXSizeAttribute as CFString, &sizeRef)
        var pos = CGPoint.zero, size = CGSize.zero
        if let p = posRef { AXValueGetValue(p as! AXValue, .cgPoint, &pos) }
        if let s = sizeRef { AXValueGetValue(s as! AXValue, .cgSize, &size) }
        let screenH = NSScreen.main?.frame.height ?? 0
        return NSRect(x: pos.x, y: screenH - pos.y - size.height, width: size.width, height: size.height)
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
        updaterController.updater.checkForUpdatesInBackground()
        for delay in [0.1, 0.3, 0.8] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.rightClickHandler.install()
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
