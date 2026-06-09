import XCTest
@testable import CruxPet

final class PetModelTests: XCTestCase {

    // 레벨 1에서는 floor(1³/10 + 1*5) = 5 EXP 필요
    func testExpNeededForLevel1() {
        XCTAssertEqual(PetModel.expNeededForLevel(1), 5)
    }

    // 레벨 2에서는 floor(8/10 + 10) = 10 EXP 필요
    func testExpNeededForLevel2() {
        XCTAssertEqual(PetModel.expNeededForLevel(2), 10)
    }

    // 총 EXP 0 → 레벨 1
    func testLevelForExpZero() {
        XCTAssertEqual(PetModel.levelForExp(0), 1)
    }

    // 총 EXP 4 → 레벨 1 (4 < 5이므로 아직 레벨업 불가)
    func testLevelForExp4() {
        XCTAssertEqual(PetModel.levelForExp(4), 1)
    }

    // 총 EXP 5 → 레벨 2 (5 >= expNeeded(1)=5)
    func testLevelForExp5() {
        XCTAssertEqual(PetModel.levelForExp(5), 2)
    }

    // 총 EXP 15 (5 + 10) → 레벨 3
    func testLevelForExp15() {
        XCTAssertEqual(PetModel.levelForExp(15), 3)
    }

    // 레벨 1 시작점 EXP = 0
    func testTotalExpAtLevel1() {
        XCTAssertEqual(PetModel.totalExpAtLevelStart(1), 0)
    }

    // 레벨 2 시작점 EXP = 5 (expNeeded(1))
    func testTotalExpAtLevel2() {
        XCTAssertEqual(PetModel.totalExpAtLevelStart(2), 5)
    }

    // 레벨 3 시작점 EXP = 15 (expNeeded(1) + expNeeded(2) = 5 + 10)
    func testTotalExpAtLevel3() {
        XCTAssertEqual(PetModel.totalExpAtLevelStart(3), 15)
    }

    // computeGain: 결과가 base*√level*0.8 ~ base*√level*1.2*2 범위 안에 있어야 함
    func testComputeGainRange() {
        let level = 10
        let base = 15.0
        let minExpected = Int((base * sqrt(Double(level)) * 0.8).rounded())
        let maxExpected = Int((base * sqrt(Double(level)) * 1.2 * 2.0).rounded())
        for _ in 0..<100 {
            let (gained, _) = PetModel.computeGain(base: base, level: level)
            XCTAssertGreaterThanOrEqual(gained, minExpected)
            XCTAssertLessThanOrEqual(gained, maxExpected)
        }
    }

    // 크리티컬은 gained가 non-crit 최솟값보다 크거나 같아야 함
    func testComputeGainCritical() {
        var sawCritical = false
        for _ in 0..<1000 {
            let (_, isCrit) = PetModel.computeGain(base: 50, level: 1)
            if isCrit { sawCritical = true; break }
        }
        XCTAssertTrue(sawCritical, "1000번 중 크리티컬이 한 번도 안 나오면 실패")
    }

    // 레벨 1 → 파랑 슬라임
    func testAppearanceLevel1() {
        let a = PetModel.appearance(for: 1)
        XCTAssertEqual(a.size, 24)
        XCTAssertEqual(a.crownType, .none)
        XCTAssertEqual(a.sparkleCount, 0)
        XCTAssertFalse(a.isRainbow)
    }

    // 레벨 10 → 동관
    func testAppearanceLevel10() {
        let a = PetModel.appearance(for: 10)
        XCTAssertEqual(a.crownType, .bronze)
    }

    // 레벨 30 → 무지개 + 금관
    func testAppearanceLevel30() {
        let a = PetModel.appearance(for: 30)
        XCTAssertTrue(a.isRainbow)
        XCTAssertEqual(a.crownType, .gold)
    }

    // 레벨 80 → 후광 있음
    func testAppearanceLevel80HasHalo() {
        let a = PetModel.appearance(for: 80)
        XCTAssertTrue(a.hasHalo)
        XCTAssertEqual(a.crownType, .diamond)
    }

    // 레벨 100 → 성좌관 + isPearl
    func testAppearanceLevel100() {
        let a = PetModel.appearance(for: 100)
        XCTAssertEqual(a.crownType, .constellation)
        XCTAssertTrue(a.isPearl)
    }

    func testApplyingKeepsLevelColorWhenUseCustomColorFalse() {
        let base = PetModel.appearance(for: 1)   // bodyHex = #7EC8E3
        var c = PetCustomization()
        c.useCustomColor = false
        c.customColorHex = "#EF5350"
        let result = base.applying(c)
        XCTAssertEqual(result.bodyHex, base.bodyHex)
        XCTAssertEqual(result.isRainbow, base.isRainbow)
    }

    func testApplyingOverridesColorWhenUseCustomColorTrue() {
        let base = PetModel.appearance(for: 1)
        var c = PetCustomization()
        c.useCustomColor = true
        c.customColorHex = "#EF5350"
        let result = base.applying(c)
        XCTAssertEqual(result.bodyHex, "#EF5350")
        XCTAssertFalse(result.isRainbow)
    }

    // MARK: - isNightOwlHour

    func testIsNightOwlHour_midnight() {
        var c = DateComponents(); c.year = 2026; c.month = 6; c.day = 9; c.hour = 0; c.minute = 0
        XCTAssertTrue(PetModel.isNightOwlHour(Calendar.current.date(from: c)!))
    }

    func testIsNightOwlHour_3am() {
        var c = DateComponents(); c.year = 2026; c.month = 6; c.day = 9; c.hour = 3; c.minute = 59
        XCTAssertTrue(PetModel.isNightOwlHour(Calendar.current.date(from: c)!))
    }

    func testIsNightOwlHour_4am() {
        var c = DateComponents(); c.year = 2026; c.month = 6; c.day = 9; c.hour = 4; c.minute = 0
        XCTAssertFalse(PetModel.isNightOwlHour(Calendar.current.date(from: c)!))
    }

    func testIsNightOwlHour_noon() {
        var c = DateComponents(); c.year = 2026; c.month = 6; c.day = 9; c.hour = 12; c.minute = 0
        XCTAssertFalse(PetModel.isNightOwlHour(Calendar.current.date(from: c)!))
    }
}
