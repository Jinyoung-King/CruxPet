import Foundation

struct PetCustomization: Codable {
    var name: String = "Crux"
    var useCustomColor: Bool = false
    var customColorHex: String = "#7EC8E3"
    var accessory: String = ""
    var pomodoroMinutes: Int = 25

    static let presetColors: [String] = [
        "#7EC8E3", "#EF5350", "#66BB6A",
        "#FFA726", "#AB47BC", "#FFD700", "#F48FB1"
    ]

    static let accessories: [String] = [
        "🎩", "👒", "🎀", "👓", "⭐", "🌸", "🔥", "💎", "🍀"
    ]

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: "cruxpet.customization")
    }

    static func load() -> PetCustomization {
        guard let data = UserDefaults.standard.data(forKey: "cruxpet.customization"),
              let c = try? JSONDecoder().decode(PetCustomization.self, from: data)
        else { return PetCustomization() }
        return c
    }
}
