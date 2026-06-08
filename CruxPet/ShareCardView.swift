import SwiftUI

struct ShareCardView: View {
    let pet: PetModel
    let customization: PetCustomization

    private var appearance: SlimeAppearance { pet.slimeAppearance.applying(customization) }
    private var tierColor: Color { Color(hex: appearance.isRainbow ? "#A8DADC" : appearance.bodyHex) }
    private var expProgress: Double { min(pet.expInCurrentLevel / max(pet.expNeededThisLevel, 1), 1) }

    private var tierLabel: String {
        switch pet.level {
        case 1...9:   return "Newbie"
        case 10...19: return "Bronze"
        case 20...29: return "Silver"
        case 30...49: return "Gold"
        case 50...79: return "Diamond"
        case 80...99: return "Legend"
        default:      return "Cosmos"
        }
    }

    private var tierIcon: String {
        appearance.crownType == .none ? "🌱" : appearance.crownType.symbol
    }

    private var tierStars: Int {
        switch pet.level {
        case 1...9:   return 1
        case 10...19: return 2
        case 20...29: return 3
        case 30...49: return 4
        default:      return 5
        }
    }

    // 오늘 활동량 기반 멘트
    private var activityMessage: String {
        let score = pet.todayCommitCount + pet.todayPomodoroCount * 2
        switch score {
        case 0:      return "오늘은 좀 쉬어도 괜찮아 😴"
        case 1...3:  return "슬슬 달리는 중 🚶"
        case 4...8:  return "오늘도 열일 중! 🔥"
        case 9...15: return "완전 집중 모드 돌입 ⚡️"
        default:     return "오늘 너무한 거 아니야?! 💥"
        }
    }

    // 조건 달성 뱃지 (최대 3개)
    private var earnedBadges: [(emoji: String, label: String)] {
        var badges: [(String, String)] = []
        if pet.todayCommitCount >= 10      { badges.append(("💣", "커밋 폭탄")) }
        else if pet.todayCommitCount >= 5  { badges.append(("⚡️", "커밋러")) }
        if pet.todayPomodoroCount >= 5     { badges.append(("🧠", "집중 괴물")) }
        else if pet.todayPomodoroCount >= 3 { badges.append(("🍅", "포모마스터")) }
        if pet.level >= 30                 { badges.append(("👑", "고수")) }
        else if pet.level >= 10            { badges.append(("🌟", "중수")) }
        if Int(pet.totalExp) >= 10_000     { badges.append(("💎", "만 EXP")) }
        return Array(badges.prefix(3))
    }

    // 배경 장식용 ✦ 위치 (고정 시드)
    private let sparklePositions: [(x: CGFloat, y: CGFloat, size: CGFloat, opacity: Double)] = [
        (0.08, 0.06, 10, 0.35), (0.88, 0.10, 7,  0.25), (0.78, 0.28, 5,  0.20),
        (0.05, 0.38, 6,  0.20), (0.93, 0.50, 8,  0.28), (0.12, 0.72, 5,  0.18),
        (0.82, 0.76, 9,  0.22), (0.55, 0.92, 6,  0.18), (0.30, 0.88, 7,  0.20),
    ]

    var body: some View {
        ZStack {
            // 배경 그라데이션
            LinearGradient(
                colors: [tierColor.opacity(0.45), tierColor.opacity(0.1), tierColor.opacity(0.22)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // 장식 원
            GeometryReader { geo in
                Circle()
                    .fill(tierColor.opacity(0.18))
                    .frame(width: 200)
                    .offset(x: geo.size.width * 0.42, y: -55)
                Circle()
                    .fill(tierColor.opacity(0.10))
                    .frame(width: 130)
                    .offset(x: -45, y: geo.size.height * 0.52)
                Circle()
                    .fill(tierColor.opacity(0.08))
                    .frame(width: 80)
                    .offset(x: geo.size.width * 0.76, y: geo.size.height * 0.70)

                // 반짝임 ✦ 장식
                ForEach(sparklePositions.indices, id: \.self) { i in
                    let s = sparklePositions[i]
                    Text("✦")
                        .font(.system(size: s.size))
                        .foregroundStyle(tierColor.opacity(s.opacity))
                        .position(x: geo.size.width * s.x, y: geo.size.height * s.y)
                }
            }

            VStack(spacing: 0) {
                // 티어 배지 + 별
                VStack(spacing: 6) {
                    HStack(spacing: 4) {
                        Text(tierIcon)
                            .font(.system(size: 13))
                        Text(tierLabel)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(tierColor)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.35), in: Capsule())

                    // 티어 별
                    HStack(spacing: 3) {
                        ForEach(0..<5, id: \.self) { i in
                            Text(i < tierStars ? "★" : "☆")
                                .font(.system(size: 11))
                                .foregroundStyle(i < tierStars ? tierColor : tierColor.opacity(0.3))
                        }
                    }
                }
                .padding(.top, 20)

                // 슬라임 + 글로우
                ZStack {
                    Circle()
                        .fill(tierColor.opacity(0.3))
                        .frame(width: 120)
                        .blur(radius: 22)
                    SlimeView(appearance: appearance, accessory: customization.accessory)
                        .scaleEffect(2.2)
                        .frame(width: (appearance.size + 32) * 2.2,
                               height: (appearance.size + 40) * 2.2)
                }
                .padding(.top, 8)

                // 레벨 배지
                Text("Lv. \(pet.level)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(tierColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(tierColor.opacity(0.18), in: Capsule())
                    .padding(.top, 10)

                // 이름
                Text(customization.name)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .padding(.top, 3)

                // 오늘의 한마디
                Text(activityMessage)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.22), in: Capsule())
                    .padding(.top, 6)

                // EXP 바
                VStack(spacing: 5) {
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.secondary.opacity(0.15))
                        Capsule()
                            .fill(LinearGradient(
                                colors: [tierColor, tierColor.opacity(0.65)],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(width: 210 * expProgress)
                    }
                    .frame(width: 210, height: 9)

                    HStack(spacing: 6) {
                        Text("\(Int(pet.expInCurrentLevel)) / \(Int(pet.expNeededThisLevel)) EXP")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text("총 \(formattedExp(pet.totalExp))")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.top, 12)

                // 스탯 카드
                HStack(spacing: 10) {
                    statCard(icon: "arrow.triangle.branch", value: "\(pet.todayCommitCount)",
                             label: "오늘 커밋", color: .blue)
                    statCard(icon: "timer", value: "\(pet.todayPomodoroCount)",
                             label: "오늘 포모도로", color: .orange)
                }
                .padding(.top, 14)

                // 스트릭
                if pet.streakDays > 0 {
                    HStack(spacing: 5) {
                        Text("🔥")
                            .font(.system(size: 13))
                        Text("\(pet.streakDays)일 연속 활동 중")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(streakColor)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(streakColor.opacity(0.13), in: Capsule())
                    .padding(.top, 8)
                }

                // 획득 뱃지 (있을 때만)
                if !earnedBadges.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(earnedBadges.indices, id: \.self) { i in
                            HStack(spacing: 3) {
                                Text(earnedBadges[i].emoji)
                                    .font(.system(size: 11))
                                Text(earnedBadges[i].label)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(.primary.opacity(0.75))
                            }
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(.white.opacity(0.3), in: Capsule())
                        }
                    }
                    .padding(.top, 10)
                }

                Spacer(minLength: 0)

                // 푸터
                HStack {
                    Text(formattedDate)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Text("CruxPet 🐾")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 16)
            }
        }
        .frame(width: 300, height: 460)
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }

    private func statCard(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(label)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(width: 128)
        .background(.white.opacity(0.28), in: RoundedRectangle(cornerRadius: 14))
    }

    private var streakColor: Color {
        switch pet.streakDays {
        case 1...6:   return .orange
        case 7...13:  return .red
        case 14...29: return .purple
        default:      return .yellow
        }
    }

    private func formattedExp(_ exp: Double) -> String {
        let n = Int(exp)
        if n >= 1000 { return "\(n / 1000),\(String(format: "%03d", n % 1000)) EXP" }
        return "\(n) EXP"
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy.MM.dd"
        return f.string(from: Date())
    }
}
