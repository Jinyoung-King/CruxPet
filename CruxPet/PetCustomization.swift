import Foundation

enum AccessorySlot: String, CaseIterable, Codable {
    case head, face, body, aura

    var label: String {
        switch self {
        case .head: return "머리"
        case .face: return "얼굴"
        case .body: return "몸"
        case .aura: return "오라"
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
    var petNames: [PetType: String] = Dictionary(uniqueKeysWithValues: PetType.allCases.map { ($0, $0.defaultName) })
    var useCustomColor: Bool = false
    var customColorHex: String = "#7EC8E3"
    var accessories: [AccessorySlot: String] = [:]
    var pomodoroMinutes: Int = 25
    var petType: PetType = .slime

    var name: String {
        get { petNames[petType, default: petType.defaultName] }
        set { petNames[petType] = newValue }
    }

    static let presetColors: [String] = [
        "#7EC8E3", "#EF5350", "#66BB6A",
        "#FFA726", "#AB47BC", "#FFD700", "#F48FB1"
    ]

    init() {}

    enum CodingKeys: String, CodingKey {
        case petNames, name, useCustomColor, customColorHex, accessories, pomodoroMinutes, petType
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        useCustomColor   = try container.decodeIfPresent(Bool.self,                 forKey: .useCustomColor)   ?? false
        customColorHex   = try container.decodeIfPresent(String.self,               forKey: .customColorHex)   ?? "#7EC8E3"
        accessories      = try container.decodeIfPresent([AccessorySlot: String].self, forKey: .accessories)   ?? [:]
        pomodoroMinutes  = try container.decodeIfPresent(Int.self,                  forKey: .pomodoroMinutes)  ?? 25
        petType          = try container.decodeIfPresent(PetType.self,              forKey: .petType)          ?? .slime
        if let rawNames = try container.decodeIfPresent([String: String].self, forKey: .petNames) {
            petNames = Dictionary(uniqueKeysWithValues: rawNames.compactMap { key, val in
                PetType(rawValue: key).map { ($0, val) }
            })
        } else {
            // Migrate from legacy single-name format
            petNames = Dictionary(uniqueKeysWithValues: PetType.allCases.map { ($0, $0.defaultName) })
            if let legacyName = try container.decodeIfPresent(String.self, forKey: .name) {
                petNames[petType] = legacyName
            }
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let rawNames = Dictionary(uniqueKeysWithValues: petNames.map { ($0.key.rawValue, $0.value) })
        try container.encode(rawNames,        forKey: .petNames)
        try container.encode(useCustomColor,  forKey: .useCustomColor)
        try container.encode(customColorHex,  forKey: .customColorHex)
        try container.encode(accessories,     forKey: .accessories)
        try container.encode(pomodoroMinutes, forKey: .pomodoroMinutes)
        try container.encode(petType,         forKey: .petType)
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
