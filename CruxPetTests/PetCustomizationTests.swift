import XCTest
@testable import CruxPet

final class PetCustomizationTests: XCTestCase {

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "cruxpet.customization")
    }

    // MARK: - AccessorySlot

    func testAccessorySlotItems() {
        XCTAssertEqual(AccessorySlot.head.items,  ["🎩", "👒", "🎀", "👑", "🪖", "🎓", "🪄"])
        XCTAssertEqual(AccessorySlot.face.items,  ["👓", "🕶️", "🥸", "😷", "🎭"])
        XCTAssertEqual(AccessorySlot.body.items,  ["⭐", "🌸", "💎", "🍀", "🎸", "🎮", "🏆", "🎯"])
        XCTAssertEqual(AccessorySlot.aura.items,  ["🔥", "⚡", "❄️", "🌊", "✨", "🌈"])
    }

    func testAccessorySlotAllCasesCount() {
        XCTAssertEqual(AccessorySlot.allCases.count, 4)
    }

    // MARK: - PetCustomization defaults

    func testDefaultValues() {
        let c = PetCustomization()
        XCTAssertEqual(c.name, "Crux")
        XCTAssertFalse(c.useCustomColor)
        XCTAssertEqual(c.customColorHex, "#7EC8E3")
        XCTAssertTrue(c.accessories.isEmpty)
        XCTAssertEqual(c.pomodoroMinutes, 25)
    }

    // MARK: - Save / Load

    func testSaveAndLoad() {
        var c = PetCustomization()
        c.name = "TestSlime"
        c.useCustomColor = true
        c.customColorHex = "#EF5350"
        c.accessories = [.head: "🎩", .aura: "🔥"]
        c.pomodoroMinutes = 50
        c.save()

        let loaded = PetCustomization.load()
        XCTAssertEqual(loaded.name, "TestSlime")
        XCTAssertTrue(loaded.useCustomColor)
        XCTAssertEqual(loaded.customColorHex, "#EF5350")
        XCTAssertEqual(loaded.accessories[.head], "🎩")
        XCTAssertEqual(loaded.accessories[.aura], "🔥")
        XCTAssertNil(loaded.accessories[.face])
        XCTAssertEqual(loaded.pomodoroMinutes, 50)
    }

    func testLoadReturnsDefaultWhenNotSaved() {
        let c = PetCustomization.load()
        XCTAssertEqual(c.name, "Crux")
        XCTAssertTrue(c.accessories.isEmpty)
        XCTAssertEqual(c.pomodoroMinutes, 25)
    }

    func testOldDataMigration() {
        // 구버전 데이터 (accessory: String) 는 accessories 키가 없어
        // Codable 기본값인 빈 딕셔너리로 디코딩되어야 한다.
        let oldJSON = """
        {"name":"OldSlime","useCustomColor":false,"customColorHex":"#7EC8E3",
         "accessory":"🎩","pomodoroMinutes":25}
        """.data(using: .utf8)!
        UserDefaults.standard.set(oldJSON, forKey: "cruxpet.customization")

        let c = PetCustomization.load()
        XCTAssertEqual(c.name, "OldSlime")
        XCTAssertTrue(c.accessories.isEmpty)   // accessory 필드 무시, 기본값
    }

    // MARK: - petType

    func testDefaultPetType() {
        let c = PetCustomization()
        XCTAssertEqual(c.petType, .slime)
    }

    func testPetTypeSaveAndLoad() {
        var c = PetCustomization()
        c.petType = .cat
        c.save()
        let loaded = PetCustomization.load()
        XCTAssertEqual(loaded.petType, .cat)
    }

    func testOldDataDefaultsToPetTypeSlime() {
        let oldJSON = """
        {"name":"OldSlime","useCustomColor":false,"customColorHex":"#7EC8E3","pomodoroMinutes":25}
        """.data(using: .utf8)!
        UserDefaults.standard.set(oldJSON, forKey: "cruxpet.customization")
        let c = PetCustomization.load()
        XCTAssertEqual(c.petType, .slime)
    }

    // MARK: - Daily Goals

    func testDailyGoalDefaults() {
        let c = PetCustomization()
        XCTAssertEqual(c.dailyCommitGoal, 5)
        XCTAssertEqual(c.dailyPomodoroGoal, 4)
    }

    func testDailyGoalRoundTrip() throws {
        var c = PetCustomization()
        c.dailyCommitGoal = 8
        c.dailyPomodoroGoal = 3
        let data = try JSONEncoder().encode(c)
        let decoded = try JSONDecoder().decode(PetCustomization.self, from: data)
        XCTAssertEqual(decoded.dailyCommitGoal, 8)
        XCTAssertEqual(decoded.dailyPomodoroGoal, 3)
    }

    func testDailyGoalDefaultsOnOldData() {
        let oldJSON = """
        {"name":"Crux","useCustomColor":false,"customColorHex":"#7EC8E3","pomodoroMinutes":25}
        """.data(using: .utf8)!
        UserDefaults.standard.set(oldJSON, forKey: "cruxpet.customization")
        let c = PetCustomization.load()
        XCTAssertEqual(c.dailyCommitGoal, 5)
        XCTAssertEqual(c.dailyPomodoroGoal, 4)
    }
}
