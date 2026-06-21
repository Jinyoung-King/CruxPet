import SwiftUI

struct CustomizeView: View {
    let current: PetCustomization
    let petLevel: Int
    let onSave: (PetCustomization) -> Void
    let onCancel: () -> Void

    @Environment(\.checkForUpdates) private var checkForUpdates
    @State private var draft: PetCustomization

    init(current: PetCustomization, petLevel: Int,
         onSave: @escaping (PetCustomization) -> Void,
         onCancel: @escaping () -> Void) {
        self.current = current
        self.petLevel = petLevel
        self.onSave = onSave
        self.onCancel = onCancel
        _draft = State(initialValue: current)
    }

    private var previewAppearance: SlimeAppearance {
        PetModel.appearance(for: petLevel).applying(draft)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // 실시간 미리보기
                ZStack {
                    PixelBackgroundView()
                    Circle()
                        .fill(Color.blue.opacity(0.06))
                        .frame(width: 100, height: 100)
                        .blur(radius: 14)
                    PetView(
                        petType: draft.petType,
                        appearance: previewAppearance,
                        level: petLevel,
                        emotion: .normal,
                        isPomodoroActive: false,
                        isWandering: false
                    )
                }
                .frame(height: 130)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // 펫 종류
                VStack(alignment: .leading, spacing: 6) {
                    Text("펫 종류").font(.caption.bold()).foregroundStyle(.secondary)
                    HStack(spacing: 5) {
                        ForEach(PetType.allCases, id: \.self) { type in
                            let isUnlocked = petLevel >= type.unlockLevel
                            let isSelected = draft.petType == type
                            Button {
                                if isUnlocked { draft.petType = type }
                            } label: {
                                VStack(spacing: 2) {
                                    Text(isUnlocked ? type.emoji : "🔒")
                                        .font(.system(size: 15))
                                    Text(isUnlocked ? type.displayName : "Lv.\(type.unlockLevel)~")
                                        .font(.system(size: 9))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 5)
                                .background(isUnlocked && isSelected ? Color.blue : Color.clear)
                                .foregroundStyle(isUnlocked && isSelected ? .white : (isUnlocked ? .primary : .secondary))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            isUnlocked && !isSelected ? Color.secondary.opacity(0.35) : Color.clear,
                                            lineWidth: 1
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(!isUnlocked)
                        }
                    }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(.primary.opacity(0.04)))

                // 이름
                VStack(alignment: .leading, spacing: 4) {
                    Text("이름").font(.caption.bold()).foregroundStyle(.secondary)
                    TextField(draft.petType.defaultName, text: $draft.name)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)
                        .onChange(of: draft.name) { _, new in
                            if new.count > 10 { draft.name = String(new.prefix(10)) }
                        }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(.primary.opacity(0.04)))

                // 색상
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("색상").font(.caption.bold()).foregroundStyle(.secondary)
                        Spacer()
                        Toggle("레벨 색 사용", isOn: Binding(
                            get: { !draft.useCustomColor },
                            set: { draft.useCustomColor = !$0 }
                        ))
                        .toggleStyle(.checkbox)
                        .font(.caption2)
                    }
                    HStack(spacing: 6) {
                        ForEach(PetCustomization.presetColors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 22, height: 22)
                                .overlay(
                                    Circle().stroke(Color.white, lineWidth: draft.customColorHex == hex && draft.useCustomColor ? 2 : 0)
                                )
                                .opacity(draft.useCustomColor ? 1.0 : 0.4)
                                .onTapGesture {
                                    draft.customColorHex = hex
                                    draft.useCustomColor = true
                                }
                        }
                    }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(.primary.opacity(0.04)))

                // 설정
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("포모도로 시간").font(.caption.bold()).foregroundStyle(.secondary)
                        HStack(spacing: 6) {
                            ForEach([15, 25, 50], id: \.self) { min in
                                Button("\(min)분") { draft.pomodoroMinutes = min }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                    .tint(draft.pomodoroMinutes == min ? .blue : .secondary)
                            }
                        }
                    }
                    Divider()
                    VStack(alignment: .leading, spacing: 6) {
                        Text("일일 목표").font(.caption.bold()).foregroundStyle(.secondary)
                        HStack {
                            Label("커밋", systemImage: "bolt.fill").font(.caption2).foregroundStyle(.secondary)
                            Spacer()
                            Stepper(value: $draft.dailyCommitGoal, in: 1...20) {
                                Text("\(draft.dailyCommitGoal)회").font(.caption2)
                            }
                        }
                        HStack {
                            Label("포모도로", systemImage: "timer").font(.caption2).foregroundStyle(.secondary)
                            Spacer()
                            Stepper(value: $draft.dailyPomodoroGoal, in: 1...10) {
                                Text("\(draft.dailyPomodoroGoal)회").font(.caption2)
                            }
                        }
                    }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(.primary.opacity(0.04)))

                // 버튼
                HStack(spacing: 8) {
                    Button("취소", action: onCancel)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    Button("저장") { onSave(draft) }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                }
                .padding(.top, 4)
                Button(action: checkForUpdates) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 10))
                        Text("업데이트 확인")
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
        }
        .frame(width: 220, height: 650)
    }
}
