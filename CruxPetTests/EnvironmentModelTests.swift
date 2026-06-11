import XCTest
@testable import CruxPet

final class EnvironmentModelTests: XCTestCase {

    // MARK: - TimeOfDay

    func testTimeOfDay_dawn() {
        XCTAssertEqual(TimeOfDay.from(hour: 0), .dawn)
        XCTAssertEqual(TimeOfDay.from(hour: 3), .dawn)
        XCTAssertEqual(TimeOfDay.from(hour: 4), .dawn)
    }

    func testTimeOfDay_morning() {
        XCTAssertEqual(TimeOfDay.from(hour: 5), .morning)
        XCTAssertEqual(TimeOfDay.from(hour: 8), .morning)
    }

    func testTimeOfDay_daytime() {
        XCTAssertEqual(TimeOfDay.from(hour: 9), .daytime)
        XCTAssertEqual(TimeOfDay.from(hour: 17), .daytime)
    }

    func testTimeOfDay_evening() {
        XCTAssertEqual(TimeOfDay.from(hour: 18), .evening)
        XCTAssertEqual(TimeOfDay.from(hour: 21), .evening)
    }

    func testTimeOfDay_night() {
        XCTAssertEqual(TimeOfDay.from(hour: 22), .night)
        XCTAssertEqual(TimeOfDay.from(hour: 23), .night)
    }

    // MARK: - timeAccessory

    func testTimeAccessory_dawn_returnsMoon() {
        XCTAssertEqual(EnvironmentModel.timeAccessory(for: .dawn), .moon)
    }

    func testTimeAccessory_morning_returnsSun() {
        XCTAssertEqual(EnvironmentModel.timeAccessory(for: .morning), .sun)
    }

    func testTimeAccessory_daytime_returnsNil() {
        XCTAssertNil(EnvironmentModel.timeAccessory(for: .daytime))
    }

    func testTimeAccessory_evening_returnsSunset() {
        XCTAssertEqual(EnvironmentModel.timeAccessory(for: .evening), .sunset)
    }

    func testTimeAccessory_night_returnsStar() {
        XCTAssertEqual(EnvironmentModel.timeAccessory(for: .night), .star)
    }

    // MARK: - weatherAccessory

    func testWeatherAccessory_clear_returnsSunglasses() {
        XCTAssertEqual(EnvironmentModel.weatherAccessory(wmoCode: 0, temp: 20), .sunglasses)
        XCTAssertEqual(EnvironmentModel.weatherAccessory(wmoCode: 1, temp: 20), .sunglasses)
    }

    func testWeatherAccessory_cloudy_returnsNil() {
        XCTAssertNil(EnvironmentModel.weatherAccessory(wmoCode: 2, temp: 15))
        XCTAssertNil(EnvironmentModel.weatherAccessory(wmoCode: 3, temp: 15))
    }

    func testWeatherAccessory_rain_returnsUmbrella() {
        XCTAssertEqual(EnvironmentModel.weatherAccessory(wmoCode: 51, temp: 10), .umbrella)
        XCTAssertEqual(EnvironmentModel.weatherAccessory(wmoCode: 80, temp: 10), .umbrella)
    }

    func testWeatherAccessory_snow_returnsScarf() {
        XCTAssertEqual(EnvironmentModel.weatherAccessory(wmoCode: 71, temp: -2), .scarf)
        XCTAssertEqual(EnvironmentModel.weatherAccessory(wmoCode: 85, temp: 0), .scarf)
    }

    func testWeatherAccessory_freezing_returnsCoat() {
        XCTAssertEqual(EnvironmentModel.weatherAccessory(wmoCode: 0, temp: -1), .coat)
    }

    func testWeatherAccessory_nil_wmo_returnsNil() {
        XCTAssertNil(EnvironmentModel.weatherAccessory(wmoCode: nil, temp: nil))
    }
}
