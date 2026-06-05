import XCTest
@testable import CruxPet

final class PetCustomizationTests: XCTestCase {

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "cruxpet.customization")
    }

    func testDefaultValues() {
        let c = PetCustomization()
        XCTAssertEqual(c.name, "Crux")
        XCTAssertFalse(c.useCustomColor)
        XCTAssertEqual(c.customColorHex, "#7EC8E3")
        XCTAssertEqual(c.accessory, "")
        XCTAssertEqual(c.pomodoroMinutes, 25)
    }

    func testSaveAndLoad() {
        var c = PetCustomization()
        c.name = "TestSlime"
        c.useCustomColor = true
        c.customColorHex = "#EF5350"
        c.accessory = "🎩"
        c.pomodoroMinutes = 50
        c.save()

        let loaded = PetCustomization.load()
        XCTAssertEqual(loaded.name, "TestSlime")
        XCTAssertTrue(loaded.useCustomColor)
        XCTAssertEqual(loaded.customColorHex, "#EF5350")
        XCTAssertEqual(loaded.accessory, "🎩")
        XCTAssertEqual(loaded.pomodoroMinutes, 50)
    }

    func testLoadReturnsDefaultWhenNotSaved() {
        let c = PetCustomization.load()
        XCTAssertEqual(c.name, "Crux")
        XCTAssertEqual(c.pomodoroMinutes, 25)
    }
}
