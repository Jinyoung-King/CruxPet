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
    private var cachedLat: Double? = nil
    private var cachedLon: Double? = nil
    private var updateTimer: Timer?
    private var weatherTimer: Timer?
    private var isFetching = false

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
        // 좌표는 만료 없이 영구 복원 (위치 권한 팝업 방지)
        if let lat = UserDefaults.standard.object(forKey: "cruxpet.env.lat") as? Double,
           let lon = UserDefaults.standard.object(forKey: "cruxpet.env.lon") as? Double {
            cachedLat = lat
            cachedLon = lon
        }
        // 날씨 데이터는 30분 이내만 복원
        let lastFetch = UserDefaults.standard.double(forKey: "cruxpet.env.lastFetch")
        guard lastFetch > 0, Date().timeIntervalSince1970 - lastFetch < 30 * 60 else { return }
        if let wmo = UserDefaults.standard.object(forKey: "cruxpet.env.wmoCode") as? Int {
            cachedWMOCode = wmo
            cachedTemp = UserDefaults.standard.object(forKey: "cruxpet.env.temp") as? Double
        }
        updateAccessories()
    }

    private func saveCache(wmo: Int, temp: Double, lat: Double, lon: Double) {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "cruxpet.env.lastFetch")
        UserDefaults.standard.set(wmo, forKey: "cruxpet.env.wmoCode")
        UserDefaults.standard.set(temp, forKey: "cruxpet.env.temp")
        UserDefaults.standard.set(lat, forKey: "cruxpet.env.lat")
        UserDefaults.standard.set(lon, forKey: "cruxpet.env.lon")
    }

    // MARK: - Updating

    func startUpdating() {
        guard updateTimer == nil else { return }
        updateAccessories()
        requestLocationUpdate()
        // 60초마다 시간대 갱신
        updateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.updateAccessories() }
        }
        // 30분마다 날씨 갱신
        weatherTimer = Timer.scheduledTimer(withTimeInterval: 30 * 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.requestLocationUpdate() }
        }
    }

    private func requestLocationUpdate() {
        guard !isFetching else { return }
        let lastFetch = UserDefaults.standard.double(forKey: "cruxpet.env.lastFetch")
        let elapsed = Date().timeIntervalSince1970 - lastFetch
        guard elapsed > 30 * 60 else { return }

        // 좌표가 이미 있으면 위치 권한 요청 없이 날씨만 직접 갱신
        if let lat = cachedLat, let lon = cachedLon {
            Task { await fetchWeather(lat: lat, lon: lon) }
            return
        }

        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .authorized, .authorizedAlways:
            locationManager.requestLocation()
        default:
            break
        }
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManager(_ manager: CLLocationManager,
                                      didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        let lat = loc.coordinate.latitude
        let lon = loc.coordinate.longitude
        Task { @MainActor [weak self] in
            await self?.fetchWeather(lat: lat, lon: lon)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                      didFailWithError error: Error) {
        // 위치 실패 시 날씨 반응 없이 시간 반응만 유지 (currentAccessories는 그대로)
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .authorized || status == .authorizedAlways {
            Task { @MainActor [weak self] in self?.requestLocationUpdate() }
        }
    }

    // MARK: - Weather fetch

    private func fetchWeather(lat: Double, lon: Double) async {
        isFetching = true
        defer { isFetching = false }
        let urlString = "https://api.open-meteo.com/v1/forecast"
            + "?latitude=\(lat)&longitude=\(lon)"
            + "&current=weather_code,temperature_2m"
        guard let url = URL(string: urlString),
              let (data, _) = try? await URLSession.shared.data(from: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let current = json["current"] as? [String: Any],
              let wmo = current["weather_code"] as? Int,
              let temp = current["temperature_2m"] as? Double
        else { return }

        cachedLat = lat
        cachedLon = lon
        cachedWMOCode = wmo
        cachedTemp = temp
        saveCache(wmo: wmo, temp: temp, lat: lat, lon: lon)
        updateAccessories()
    }
}
