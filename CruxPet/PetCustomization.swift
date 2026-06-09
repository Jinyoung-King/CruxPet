import Foundation

enum AccessorySlot: String, CaseIterable, Codable {
    case head, face, body, aura

    var label: String {
        switch self {
        case .head: return "🎩 머리"
        case .face: return "👓 얼굴"
        case .body: return "💎 몸"
        case .aura: return "🔥 오라"
        }
    }

    var items: [String] {
        switch self {
        case .head: return ["🎩", "👒", "🎀", "👑", "🪖", "🎓", "🪄"]
        case .face: return ["👓", "🕶️", "🥸", "😷", "🎭"]
        case .body: return ["⭐", "🌸", "💎", "🍀", "🎸", "🎮", "🏆", "🎯"]
        case .aura: return ["🔥", "⚡", "❄️", "🌊", "✨", "🌈"]
        }
    }
}

struct PetCustomization: Codable {
    var name: String = "Crux"
    var useCustomColor: Bool = false
    var customColorHex: String = "#7EC8E3"
    var accessories: [String: String] = [:]
    var pomodoroMinutes: Int = 25

    static let presetColors: [String] = [
        "#7EC8E3", "#EF5350", "#66BB6A",
        "#FFA726", "#AB47BC", "#FFD700", "#F48FB1"
    ]

    init() {}

    enum CodingKeys: String, CodingKey {
        case name, useCustomColor, customColorHex, accessories, pomodoroMinutes
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Crux"
        useCustomColor = try container.decodeIfPresent(Bool.self, forKey: .useCustomColor) ?? false
        customColorHex = try container.decodeIfPresent(String.self, forKey: .customColorHex) ?? "#7EC8E3"
        accessories = try container.decodeIfPresent([String: String].self, forKey: .accessories) ?? [:]
        pomodoroMinutes = try container.decodeIfPresent(Int.self, forKey: .pomodoroMinutes) ?? 25
        // Note: old "accessory" field is intentionally ignored for migration
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(useCustomColor, forKey: .useCustomColor)
        try container.encode(customColorHex, forKey: .customColorHex)
        try container.encode(accessories, forKey: .accessories)
        try container.encode(pomodoroMinutes, forKey: .pomodoroMinutes)
    }

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
