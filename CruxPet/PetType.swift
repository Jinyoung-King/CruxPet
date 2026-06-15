import SwiftUI

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

    var defaultName: String {
        switch self {
        case .slime: return "Crux"
        case .cat:   return "냥이"
        case .dog:   return "뭉치"
        case .ghost: return "유령"
        }
    }
}

struct PetView: View {
    let petType: PetType
    let appearance: SlimeAppearance
    let level: Int
    let emotion: EmotionState
    let environmentAccessories: [EnvironmentAccessory]
    let accessories: [AccessorySlot: String]
    let isPomodoroActive: Bool
    let isWandering: Bool

    var body: some View {
        switch petType {
        case .slime:
            SlimeView(
                appearance: appearance,
                isPomodoroActive: isPomodoroActive,
                accessories: accessories,
                isWandering: isWandering,
                emotion: emotion,
                environmentAccessories: environmentAccessories
            )
        case .cat:
            CatView(
                level: level,
                emotion: emotion,
                accessories: accessories,
                isPomodoroActive: isPomodoroActive,
                isWandering: isWandering
            )
        case .dog:
            DogView(
                level: level,
                emotion: emotion,
                accessories: accessories,
                isPomodoroActive: isPomodoroActive,
                isWandering: isWandering
            )
        case .ghost:
            GhostView(
                level: level,
                emotion: emotion,
                accessories: accessories,
                isPomodoroActive: isPomodoroActive,
                isWandering: isWandering,
                environmentAccessories: environmentAccessories
            )
        }
    }
}
