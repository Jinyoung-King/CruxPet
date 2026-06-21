import Foundation

struct PetCustomization: Codable {
    var petNames: [PetType: String] = Dictionary(uniqueKeysWithValues: PetType.allCases.map { ($0, $0.defaultName) })
    var useCustomColor: Bool = false
    var customColorHex: String = "#7EC8E3"
    var pomodoroMinutes: Int = 25
    var petType: PetType = .slime
    var dailyCommitGoal: Int = 5
    var dailyPomodoroGoal: Int = 4

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
        case petNames, name, useCustomColor, customColorHex, pomodoroMinutes, petType, dailyCommitGoal, dailyPomodoroGoal
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        useCustomColor   = try container.decodeIfPresent(Bool.self,                 forKey: .useCustomColor)   ?? false
        customColorHex   = try container.decodeIfPresent(String.self,               forKey: .customColorHex)   ?? "#7EC8E3"
        pomodoroMinutes  = try container.decodeIfPresent(Int.self,                  forKey: .pomodoroMinutes)  ?? 25
        petType          = try container.decodeIfPresent(PetType.self,              forKey: .petType)          ?? .slime
        dailyCommitGoal  = try container.decodeIfPresent(Int.self,                  forKey: .dailyCommitGoal)  ?? 5
        dailyPomodoroGoal = try container.decodeIfPresent(Int.self,                 forKey: .dailyPomodoroGoal) ?? 4
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
        try container.encode(pomodoroMinutes, forKey: .pomodoroMinutes)
        try container.encode(petType,         forKey: .petType)
        try container.encode(dailyCommitGoal,  forKey: .dailyCommitGoal)
        try container.encode(dailyPomodoroGoal, forKey: .dailyPomodoroGoal)
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
