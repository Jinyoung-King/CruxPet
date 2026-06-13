import XCTest
@testable import CruxPet

final class PetTypeTests: XCTestCase {

    func testAllCasesCount() {
        XCTAssertEqual(PetType.allCases.count, 4)
    }

    func testUnlockLevels() {
        XCTAssertEqual(PetType.slime.unlockLevel, 0)
        XCTAssertEqual(PetType.cat.unlockLevel, 15)
        XCTAssertEqual(PetType.dog.unlockLevel, 25)
        XCTAssertEqual(PetType.ghost.unlockLevel, 35)
    }

    func testUnlockLevelOrdering() {
        let levels = PetType.allCases.map(\.unlockLevel)
        for i in 0..<levels.count - 1 {
            XCTAssertLessThanOrEqual(levels[i], levels[i + 1])
        }
    }

    func testDisplayNames() {
        XCTAssertEqual(PetType.slime.displayName, "슬라임")
        XCTAssertEqual(PetType.cat.displayName, "고양이")
        XCTAssertEqual(PetType.dog.displayName, "강아지")
        XCTAssertEqual(PetType.ghost.displayName, "유령")
    }

    func testCodableRoundTrip() throws {
        for petType in PetType.allCases {
            let encoded = try JSONEncoder().encode(petType)
            let decoded = try JSONDecoder().decode(PetType.self, from: encoded)
            XCTAssertEqual(decoded, petType)
        }
    }
}
