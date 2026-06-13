import XCTest
@testable import CruxPet

@MainActor
final class PetInteractionModelTests: XCTestCase {

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "cruxpet.lastFedAt")
        UserDefaults.standard.removeObject(forKey: "cruxpet.totalExp")
    }

    func testCanFeedInitially() {
        let m = PetInteractionModel()
        XCTAssertTrue(m.canFeed)
    }

    func testCooldownRemainingInitiallyZero() {
        let m = PetInteractionModel()
        XCTAssertEqual(m.cooldownRemaining, 0)
    }

    func testCanFeedFalseAfterFeeding() {
        let m = PetInteractionModel()
        let pet = PetModel()
        m.feed(pet: pet)
        XCTAssertFalse(m.canFeed)
    }

    func testCooldownRemainingAfterFeeding() {
        let m = PetInteractionModel()
        let pet = PetModel()
        m.feed(pet: pet)
        XCTAssertGreaterThan(m.cooldownRemaining, 29 * 60)
        XCTAssertLessThanOrEqual(m.cooldownRemaining, 30 * 60)
    }

    func testCooldownPersistsAcrossReinit() {
        let m1 = PetInteractionModel()
        let pet = PetModel()
        m1.feed(pet: pet)
        let m2 = PetInteractionModel()
        XCTAssertFalse(m2.canFeed)
    }

    func testCanFeedTrueAfterCooldownElapsed() {
        let past = Date(timeIntervalSinceNow: -(31 * 60))
        UserDefaults.standard.set(past.timeIntervalSince1970, forKey: "cruxpet.lastFedAt")
        let m = PetInteractionModel()
        XCTAssertTrue(m.canFeed)
    }

    func testFeedDoesNothingWhenOnCooldown() {
        let m = PetInteractionModel()
        let pet = PetModel()
        m.feed(pet: pet)
        let expAfterFirst = pet.totalExp
        m.feed(pet: pet)
        XCTAssertEqual(pet.totalExp, expAfterFirst)
    }
}
