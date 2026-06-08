import Foundation
import Observation

enum EmotionState: Equatable {
    case normal, happy, excited, sleepy
}

enum CrownType: Int {
    case none, bronze, silver, gold, diamond, constellation
    var symbol: String {
        switch self {
        case .none:           return ""
        case .bronze:         return "🥉"
        case .silver:         return "🥈"
        case .gold:           return "👑"
        case .diamond:        return "💎"
        case .constellation:  return "✨"
        }
    }
}

struct SlimeAppearance {
    let bodyHex: String
    let size: CGFloat
    let crownType: CrownType
    let sparkleCount: Int
    let hasHalo: Bool
    let isRainbow: Bool
    let isPearl: Bool
}

@Observable
class PetModel {
    private(set) var totalExp: Double = 0
    private(set) var todayCommitCount: Int = 0
    private(set) var todayPomodoroCount: Int = 0
    private(set) var showCritical: Bool = false
    private(set) var showLevelUp: Bool = false
    var pendingLevelUp: Int = 0
    private(set) var streakDays: Int = 0
    var pendingStreakMilestone: Int = 0
    private(set) var emotion: EmotionState = .normal
    private var lastActivityDate: Date = .distantPast
    private var emotionTimer: Timer?

    var level: Int { PetModel.levelForExp(totalExp) }
    var expInCurrentLevel: Double { totalExp - PetModel.totalExpAtLevelStart(level) }
    var expNeededThisLevel: Double { PetModel.expNeededForLevel(level) }
    var slimeAppearance: SlimeAppearance { PetModel.appearance(for: level) }

    private var passiveTimer: Timer?
    private static let passiveExpPerMinute: Double = 1.0
    private static let passiveMaxCatchupMinutes: Double = 8 * 60  // 최대 8시간치 보정

    init() {
        totalExp = UserDefaults.standard.double(forKey: "cruxpet.totalExp")
        todayCommitCount = UserDefaults.standard.integer(forKey: "cruxpet.commitCount")
        todayPomodoroCount = UserDefaults.standard.integer(forKey: "cruxpet.pomodoroCount")
        streakDays = UserDefaults.standard.integer(forKey: "cruxpet.streakDays")
        let savedActivity = UserDefaults.standard.double(forKey: "cruxpet.lastActivityTime")
        if savedActivity > 0 { lastActivityDate = Date(timeIntervalSince1970: savedActivity) }
        resetDailyCountsIfNeeded()
        awardPassiveCatchupExp()
        startPassiveTimer()
        updateEmotion()
        startEmotionTimer()
    }

    @MainActor func gainPassiveExp() {
        let gained = Int(PetModel.passiveExpPerMinute.rounded())
        totalExp += Double(gained)
        persist()
    }

    @MainActor func gainCommitExp() {
        let prevLevel = level
        let (gained, isCrit) = PetModel.computeGain(base: 15, level: level)
        totalExp += Double(gained)
        todayCommitCount += 1
        if isCrit { triggerCritical() }
        if level > prevLevel { triggerLevelUp(level) }
        updateStreak()
        triggerExcitement()
        persist()
    }

    @MainActor func gainPomodoroExp() {
        let prevLevel = level
        let (gained, isCrit) = PetModel.computeGain(base: 50, level: level)
        totalExp += Double(gained)
        todayPomodoroCount += 1
        if isCrit { triggerCritical() }
        if level > prevLevel { triggerLevelUp(level) }
        updateStreak()
        triggerExcitement()
        persist()
    }

    // MARK: - Pure static logic (테스트 가능)

    // 포켓몬 Medium Fast 스타일 3차 다항식:
    // 저레벨 증가폭 ≈ 5, 고레벨 증가폭 ≈ 3n² / 10 (제곱 비례 가속)
    static func expNeededForLevel(_ level: Int) -> Double {
        let n = Double(level)
        return floor(n * n * n / 10 + n * 5)
    }

    static func totalExpAtLevelStart(_ level: Int) -> Double {
        guard level > 1 else { return 0 }
        return (1..<level).reduce(0.0) { $0 + expNeededForLevel($1) }
    }

    static func levelForExp(_ totalExp: Double) -> Int {
        var level = 1
        var accumulated = 0.0
        while true {
            let needed = expNeededForLevel(level)
            if accumulated + needed > totalExp { return level }
            accumulated += needed
            level += 1
        }
    }

    static func computeGain(base: Double, level: Int) -> (gained: Int, isCritical: Bool) {
        let jitter = Double.random(in: 0.8...1.2)
        let isCritical = Double.random(in: 0..<1) < 0.1
        let mult = isCritical ? 2.0 : 1.0
        let gained = Int((base * sqrt(Double(level)) * jitter * mult).rounded())
        return (gained, isCritical)
    }

    static func appearance(for level: Int) -> SlimeAppearance {
        switch level {
        case 1...2:
            return SlimeAppearance(bodyHex: "#7EC8E3", size: 24, crownType: .none,          sparkleCount: 0,  hasHalo: false, isRainbow: false, isPearl: false)
        case 3...4:
            return SlimeAppearance(bodyHex: "#4FC3F7", size: 24, crownType: .none,          sparkleCount: 0,  hasHalo: false, isRainbow: false, isPearl: false)
        case 5...7:
            return SlimeAppearance(bodyHex: "#66BB6A", size: 32, crownType: .none,          sparkleCount: 0,  hasHalo: false, isRainbow: false, isPearl: false)
        case 8...9:
            return SlimeAppearance(bodyHex: "#FFEE58", size: 32, crownType: .none,          sparkleCount: 0,  hasHalo: false, isRainbow: false, isPearl: false)
        case 10...14:
            return SlimeAppearance(bodyHex: "#FFA726", size: 32, crownType: .bronze,        sparkleCount: 0,  hasHalo: false, isRainbow: false, isPearl: false)
        case 15...19:
            return SlimeAppearance(bodyHex: "#EF5350", size: 32, crownType: .bronze,        sparkleCount: 1,  hasHalo: false, isRainbow: false, isPearl: false)
        case 20...24:
            return SlimeAppearance(bodyHex: "#7E57C2", size: 40, crownType: .silver,        sparkleCount: 2,  hasHalo: false, isRainbow: false, isPearl: false)
        case 25...29:
            return SlimeAppearance(bodyHex: "#AB47BC", size: 40, crownType: .silver,        sparkleCount: 3,  hasHalo: false, isRainbow: false, isPearl: false)
        case 30...39:
            return SlimeAppearance(bodyHex: "#000000", size: 40, crownType: .gold,          sparkleCount: 4,  hasHalo: false, isRainbow: true,  isPearl: false)
        case 40...49:
            return SlimeAppearance(bodyHex: "#000000", size: 48, crownType: .gold,          sparkleCount: 6,  hasHalo: false, isRainbow: true,  isPearl: false)
        case 50...59:
            return SlimeAppearance(bodyHex: "#FFD700", size: 48, crownType: .diamond,       sparkleCount: 8,  hasHalo: false, isRainbow: false, isPearl: false)
        case 60...79:
            return SlimeAppearance(bodyHex: "#E0E0E0", size: 48, crownType: .diamond,       sparkleCount: 10, hasHalo: false, isRainbow: false, isPearl: false)
        case 80...99:
            return SlimeAppearance(bodyHex: "#F48FB1", size: 56, crownType: .diamond,       sparkleCount: 10, hasHalo: true,  isRainbow: false, isPearl: false)
        default:
            return SlimeAppearance(bodyHex: "#000000", size: 56, crownType: .constellation, sparkleCount: 10, hasHalo: true,  isRainbow: true,  isPearl: true)
        }
    }

    // MARK: - Private

    private func awardPassiveCatchupExp() {
        let lastTimestamp = UserDefaults.standard.double(forKey: "cruxpet.lastPassiveTime")
        let now = Date().timeIntervalSince1970
        UserDefaults.standard.set(now, forKey: "cruxpet.lastPassiveTime")
        guard lastTimestamp > 0 else { return }
        let elapsedMinutes = min((now - lastTimestamp) / 60, PetModel.passiveMaxCatchupMinutes)
        guard elapsedMinutes >= 1 else { return }
        let gained = Int((elapsedMinutes * PetModel.passiveExpPerMinute).rounded())
        totalExp += Double(gained)
        persist()
    }

    private func startPassiveTimer() {
        passiveTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.gainPassiveExp()
                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "cruxpet.lastPassiveTime")
            }
        }
    }

    private func triggerCritical() {
        showCritical = true
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(0.8))
            self?.showCritical = false
        }
    }

    private func triggerLevelUp(_ newLevel: Int) {
        pendingLevelUp = newLevel
        showLevelUp = true
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(2))
            self?.showLevelUp = false
        }
    }

    private func triggerExcitement() {
        lastActivityDate = Date()
        emotion = .excited
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(3))
            guard let self, self.emotion == .excited else { return }
            self.emotion = .happy
        }
    }

    private func updateEmotion() {
        guard emotion != .excited else { return }
        let minutes = Date().timeIntervalSince(lastActivityDate) / 60
        emotion = minutes < 10 ? .happy : minutes < 45 ? .normal : .sleepy
    }

    private func startEmotionTimer() {
        emotionTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.updateEmotion() }
        }
    }

    private func updateStreak() {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let today = fmt.string(from: Date())
        let lastDate = UserDefaults.standard.string(forKey: "cruxpet.streakDate") ?? ""
        guard lastDate != today else { return }

        let yesterday = fmt.string(from: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
        streakDays = (lastDate == yesterday) ? streakDays + 1 : 1
        UserDefaults.standard.set(today, forKey: "cruxpet.streakDate")

        let milestones = [3, 7, 14, 30, 60, 100]
        if milestones.contains(streakDays) {
            pendingStreakMilestone = streakDays
        }
    }

    private func persist() {
        UserDefaults.standard.set(totalExp,          forKey: "cruxpet.totalExp")
        UserDefaults.standard.set(todayCommitCount,  forKey: "cruxpet.commitCount")
        UserDefaults.standard.set(todayPomodoroCount,forKey: "cruxpet.pomodoroCount")
        UserDefaults.standard.set(streakDays,        forKey: "cruxpet.streakDays")
        UserDefaults.standard.set(lastActivityDate.timeIntervalSince1970, forKey: "cruxpet.lastActivityTime")
    }

    private func resetDailyCountsIfNeeded() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = Substring(formatter.string(from: Date()))
        let stored = UserDefaults.standard.string(forKey: "cruxpet.todayDate") ?? ""
        if stored != today {
            todayCommitCount = 0
            todayPomodoroCount = 0
            UserDefaults.standard.set(String(today), forKey: "cruxpet.todayDate")
            persist()
        }
    }
}

extension SlimeAppearance {
    func applying(_ customization: PetCustomization) -> SlimeAppearance {
        guard customization.useCustomColor else { return self }
        return SlimeAppearance(
            bodyHex: customization.customColorHex,
            size: size, crownType: crownType,
            sparkleCount: sparkleCount,
            hasHalo: hasHalo, isRainbow: false, isPearl: isPearl
        )
    }
}
