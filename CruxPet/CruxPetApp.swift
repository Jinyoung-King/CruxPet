import SwiftUI
import UserNotifications
import Sparkle

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

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true, updaterDelegate: sparkleDelegate, userDriverDelegate: nil
        )
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        if !UserDefaults.standard.bool(forKey: "cruxpet.hookInstalled") {
            CruxPetApp.installGitHook()
            UserDefaults.standard.set(true, forKey: "cruxpet.hookInstalled")
        }
    }
    @State private var pet = PetModel()
    @State private var pomodoro = PomodoroTimer()
    @State private var watcher = EventWatcher()


    var body: some Scene {
        MenuBarExtra("CruxPet", systemImage: "pawprint.fill") {
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
        }
        .menuBarExtraStyle(.window)
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
