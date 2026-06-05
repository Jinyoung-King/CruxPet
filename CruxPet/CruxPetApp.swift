import SwiftUI
import UserNotifications

@main
struct CruxPetApp: App {
    init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    var body: some Scene {
        MenuBarExtra("CruxPet", systemImage: "pawprint.fill") {
            ContentView()
        }
        .menuBarExtraStyle(.window)
    }
}
