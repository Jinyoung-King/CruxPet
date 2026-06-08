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

    var body: some View {
        ZStack {
            // 배경
            LinearGradient(
                colors: [tierColor.opacity(0.45), tierColor.opacity(0.1), tierColor.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // 장식 원
            GeometryReader { geo in
                Circle()
                    .fill(tierColor.opacity(0.18))
                    .frame(width: 200)
                    .offset(x: geo.size.width * 0.45, y: -50)
                Circle()
                    .fill(tierColor.opacity(0.1))
                    .frame(width: 130)
                    .offset(x: -40, y: geo.size.height * 0.55)
                Circle()
                    .fill(tierColor.opacity(0.08))
                    .frame(width: 80)
                    .offset(x: geo.size.width * 0.78, y: geo.size.height * 0.72)
            }

            VStack(spacing: 0) {
                // 티어 배지
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
                .padding(.top, 22)

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
                .padding(.top, 10)

                // 레벨 배지
                Text("Lv. \(pet.level)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(tierColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(tierColor.opacity(0.18), in: Capsule())
                    .padding(.top, 12)

                // 이름
                Text(customization.name)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .padding(.top, 4)

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
                .padding(.top, 14)

                // 스탯 카드 2개
                HStack(spacing: 10) {
                    statCard(icon: "arrow.triangle.branch", value: "\(pet.todayCommitCount)",
                             label: "오늘 커밋", color: .blue)
                    statCard(icon: "timer", value: "\(pet.todayPomodoroCount)",
                             label: "오늘 포모도로", color: .orange)
                }
                .padding(.top, 16)

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
        .frame(width: 300, height: 420)
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
