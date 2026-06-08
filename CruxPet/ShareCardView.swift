import SwiftUI

struct ShareCardView: View {
    let pet: PetModel
    let customization: PetCustomization

    private var appearance: SlimeAppearance { pet.slimeAppearance.applying(customization) }
    private var tierColor: Color { Color(hex: appearance.isRainbow ? "#A8DADC" : appearance.bodyHex) }

    var body: some View {
        ZStack {
            // 배경 그라데이션
            LinearGradient(
                colors: [tierColor.opacity(0.35), tierColor.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 12) {
                // 슬라임
                SlimeView(appearance: appearance, accessory: customization.accessory)
                    .frame(width: appearance.size + 32, height: appearance.size + 40)

                // 레벨
                Text("Lv. \(pet.level) · \(customization.name)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                // EXP 바
                VStack(spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.secondary.opacity(0.2))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(tierColor.opacity(0.8))
                                .frame(width: geo.size.width * min(pet.expInCurrentLevel / max(pet.expNeededThisLevel, 1), 1))
                        }
                    }
                    .frame(height: 8)
                    Text("\(Int(pet.totalExp)) EXP 누적")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 180)

                // 오늘 활동
                HStack(spacing: 16) {
                    Label("\(pet.todayCommitCount) commits", systemImage: "externaldrive.fill")
                    Label("\(pet.todayPomodoroCount) pomodoros", systemImage: "timer")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                // 워터마크
                Text("CruxPet 🐾")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(20)
        }
        .frame(width: 260, height: 320)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
