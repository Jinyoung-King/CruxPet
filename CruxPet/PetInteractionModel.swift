import Foundation
import Observation

@MainActor @Observable
class PetInteractionModel {
    private(set) var isTapped = false
    private(set) var showParticles = false
    private(set) var isEating = false
    private(set) var lastFedAt: Date?

    let feedCooldownMinutes = 30

    var canFeed: Bool {
        guard let last = lastFedAt else { return true }
        return Date().timeIntervalSince(last) >= Double(feedCooldownMinutes * 60)
    }

    var cooldownRemaining: TimeInterval {
        guard let last = lastFedAt, !canFeed else { return 0 }
        return Double(feedCooldownMinutes * 60) - Date().timeIntervalSince(last)
    }

    private static let lastFedKey = "cruxpet.lastFedAt"

    init() {
        if let ts = UserDefaults.standard.object(forKey: Self.lastFedKey) as? Double {
            lastFedAt = Date(timeIntervalSince1970: ts)
        }
    }

    func tap(pet: PetModel) {
        isTapped = true
        showParticles = true
        pet.setTemporaryEmotion(.happy, duration: 2.0)
        Task {
            try? await Task.sleep(for: .milliseconds(300))
            isTapped = false
        }
        Task {
            try? await Task.sleep(for: .milliseconds(900))
            showParticles = false
        }
    }

    func feed(pet: PetModel) {
        guard canFeed else { return }
        lastFedAt = Date()
        UserDefaults.standard.set(lastFedAt!.timeIntervalSince1970, forKey: Self.lastFedKey)
        pet.gainTreatExp()
        pet.setTemporaryEmotion(.excited, duration: 1.5)
        isEating = true
        Task {
            try? await Task.sleep(for: .milliseconds(1500))
            isEating = false
        }
    }
}
