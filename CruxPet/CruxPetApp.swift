import SwiftUI
import UserNotifications

@main
struct CruxPetApp: App {
    init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        if !UserDefaults.standard.bool(forKey: "cruxpet.hookInstalled") {
            Self.installGitHook()
            UserDefaults.standard.set(true, forKey: "cruxpet.hookInstalled")
        }
    }

    var body: some Scene {
        MenuBarExtra("CruxPet", systemImage: "pawprint.fill") {
            ContentView()
        }
        .menuBarExtraStyle(.window)
    }

    private static func installGitHook() {
        let home = NSHomeDirectory()
        let fm = FileManager.default

        let hooksDir = "\(home)/.config/git/hooks"
        let hookFile = "\(hooksDir)/post-commit"
        let eventsDir = "\(home)/.cruxpet"
        let eventsFile = "\(eventsDir)/events.json"
        let hookLine = #"echo "{\"type\":\"commit\",\"timestamp\":$(date +%s)}" >> "$HOME/.cruxpet/events.json""#

        try? fm.createDirectory(atPath: hooksDir, withIntermediateDirectories: true)
        try? fm.createDirectory(atPath: eventsDir, withIntermediateDirectories: true)
        if !fm.fileExists(atPath: eventsFile) { fm.createFile(atPath: eventsFile, contents: nil) }

        if !fm.fileExists(atPath: hookFile) {
            try? "#!/bin/sh\n\(hookLine)\n".write(toFile: hookFile, atomically: true, encoding: .utf8)
        } else if let existing = try? String(contentsOfFile: hookFile, encoding: .utf8),
                  !existing.contains("cruxpet") {
            if let handle = FileHandle(forWritingAtPath: hookFile) {
                handle.seekToEndOfFile()
                handle.write("\n# CruxPet\n\(hookLine)\n".data(using: .utf8)!)
                handle.closeFile()
            }
        }

        try? fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: hookFile)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["config", "--global", "core.hooksPath", hooksDir]
        try? process.run()
        process.waitUntilExit()
    }
}
