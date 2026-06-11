import CoreLocation
import Foundation
import Observation

enum TimeOfDay: Equatable {
    case dawn, morning, daytime, evening, night

    static func from(hour: Int) -> TimeOfDay {
        switch hour {
        case 0...4:   return .dawn
        case 5...8:   return .morning
        case 9...17:  return .daytime
        case 18...21: return .evening
        default:      return .night
        }
    }

    static func current() -> TimeOfDay {
        from(hour: Calendar.current.component(.hour, from: Date()))
    }
}

enum EnvironmentAccessory: String, Equatable {
    case moon, sun, sunset, star, sunglasses, umbrella, scarf, coat

    var emoji: String {
        switch self {
        case .moon:       return "🌙"
        case .sun:        return "🌤"
        case .sunset:     return "🌇"
        case .star:       return "⭐"
        case .sunglasses: return "🕶️"
        case .umbrella:   return "☂️"
        case .scarf:      return "🧣"
        case .coat:       return "🧥"
        }
    }
}

@Observable
@MainActor
class EnvironmentModel: NSObject, CLLocationManagerDelegate {
    private(set) var currentAccessories: [EnvironmentAccessory] = []

    private let locationManager = CLLocationManager()
    private var cachedWMOCode: Int? = nil
    private var cachedTemp: Double? = nil
    private var updateTimer: Timer?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        restoreCache()
    }

    // MARK: - Pure static logic (테스트 가능)

    nonisolated static func timeAccessory(for time: TimeOfDay) -> EnvironmentAccessory? {
        switch time {
        case .dawn:    return .moon
        case .morning: return .sun
        case .evening: return .sunset
        case .night:   return .star
        case .daytime: return nil
        }
    }

    nonisolated static func weatherAccessory(wmoCode: Int?, temp: Double?) -> EnvironmentAccessory? {
        guard let wmo = wmoCode else { return nil }
        switch wmo {
        case 71...77, 85...86: return .scarf
        case 51...67, 80...82: return .umbrella
        case 0...1:
            if let t = temp, t < 0 { return .coat }
            return .sunglasses
        default:
            if let t = temp, t < 0 { return .coat }
            return nil
        }
    }

    // MARK: - Internal update

    func updateAccessories() {
        var result: [EnvironmentAccessory] = []
        if let ta = EnvironmentModel.timeAccessory(for: TimeOfDay.current()) {
            result.append(ta)
        }
        if let wa = EnvironmentModel.weatherAccessory(wmoCode: cachedWMOCode, temp: cachedTemp) {
            result.append(wa)
        }
        currentAccessories = result
    }

    // MARK: - Cache persistence

    private func restoreCache() {
        let lastFetch = UserDefaults.standard.double(forKey: "cruxpet.env.lastFetch")
        guard lastFetch > 0, Date().timeIntervalSince1970 - lastFetch < 30 * 60 else { return }
        if let wmo = UserDefaults.standard.object(forKey: "cruxpet.env.wmoCode") as? Int {
            cachedWMOCode = wmo
            cachedTemp = UserDefaults.standard.double(forKey: "cruxpet.env.temp")
        }
        updateAccessories()
    }

    private func saveCache(wmo: Int, temp: Double) {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "cruxpet.env.lastFetch")
        UserDefaults.standard.set(wmo, forKey: "cruxpet.env.wmoCode")
        UserDefaults.standard.set(temp, forKey: "cruxpet.env.temp")
    }

    // MARK: - Stubs (Task 5에서 구현)

    func startUpdating() {
        guard updateTimer == nil else { return }
        updateAccessories()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.updateAccessories() }
        }
    }

    // CLLocationManagerDelegate stubs
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {}
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {}
}
