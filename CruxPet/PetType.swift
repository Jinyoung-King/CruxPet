import Foundation

enum PetType: String, Codable, CaseIterable {
    case slime, cat, dog, ghost

    var unlockLevel: Int {
        switch self {
        case .slime: return 0
        case .cat:   return 15
        case .dog:   return 25
        case .ghost: return 35
        }
    }

    var displayName: String {
        switch self {
        case .slime: return "슬라임"
        case .cat:   return "고양이"
        case .dog:   return "강아지"
        case .ghost: return "유령"
        }
    }

    var emoji: String {
        switch self {
        case .slime: return "🟢"
        case .cat:   return "🐱"
        case .dog:   return "🐶"
        case .ghost: return "👻"
        }
    }
}
