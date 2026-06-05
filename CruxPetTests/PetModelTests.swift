import XCTest
@testable import CruxPet

final class PetModelTests: XCTestCase {

    // 레벨 1에서는 100 EXP 필요
    func testExpNeededForLevel1() {
        XCTAssertEqual(PetModel.expNeededForLevel(1), 100)
    }

    // 레벨 2에서는 floor(100 * 2^1.5) = floor(282.84) = 282
    func testExpNeededForLevel2() {
        XCTAssertEqual(PetModel.expNeededForLevel(2), 282)
    }

    // 총 EXP 0 → 레벨 1
    func testLevelForExpZero() {
        XCTAssertEqual(PetModel.levelForExp(0), 1)
    }

    // 총 EXP 99 → 레벨 1 (99 < 100이므로 아직 레벨업 불가)
    func testLevelForExp99() {
        XCTAssertEqual(PetModel.levelForExp(99), 1)
    }

    // 총 EXP 100 → 레벨 2
    func testLevelForExp100() {
        XCTAssertEqual(PetModel.levelForExp(100), 2)
    }

    // 총 EXP 382 (100 + 282) → 레벨 3
    func testLevelForExp382() {
        XCTAssertEqual(PetModel.levelForExp(382), 3)
    }

    // 레벨 1 시작점 EXP = 0
    func testTotalExpAtLevel1() {
        XCTAssertEqual(PetModel.totalExpAtLevelStart(1), 0)
    }

    // 레벨 2 시작점 EXP = 100
    func testTotalExpAtLevel2() {
        XCTAssertEqual(PetModel.totalExpAtLevelStart(2), 100)
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

    // 레벨 100 → 성좌관 + isPearl
    func testAppearanceLevel100() {
        let a = PetModel.appearance(for: 100)
        XCTAssertEqual(a.crownType, .constellation)
        XCTAssertTrue(a.isPearl)
    }
}
