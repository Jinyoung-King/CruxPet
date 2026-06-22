import SwiftUI

struct CustomizeView: View {
    let current: PetCustomization
    let petLevel: Int
    let onSave: (PetCustomization) -> Void
    let onCancel: () -> Void

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
        VStack(spacing: 0) {
            // 미리보기
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
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            ScrollView {
                VStack(spacing: 0) {
                    // 펫 종류
                    VStack(alignment: .leading, spacing: 8) {
                        Text("펫 종류").font(.caption).foregroundStyle(.secondary)
                        HStack(spacing: 4) {
                            ForEach(PetType.allCases, id: \.self) { type in
                                let isUnlocked = petLevel >= type.unlockLevel
                                let isSelected = draft.petType == type
                                Button {
                                    if isUnlocked { draft.petType = type }
                                } label: {
                                    VStack(spacing: 2) {
                                        Text(isUnlocked ? type.emoji : "🔒")
                                            .font(.system(size: 16))
                                        Text(isUnlocked ? type.displayName : "Lv.\(type.unlockLevel)")
                                            .font(.system(size: 9))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(isUnlocked && isSelected ? Color.blue : Color.secondary.opacity(0.08))
                                    .foregroundStyle(isUnlocked && isSelected ? Color.white : (isUnlocked ? Color.primary : Color.secondary.opacity(0.4)))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                                .disabled(!isUnlocked)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)

                    Divider().padding(.horizontal, 14)

                    // 이름
                    HStack(spacing: 10) {
                        Text("이름").font(.caption).foregroundStyle(.secondary)
                            .frame(width: 44, alignment: .leading)
                        TextField(draft.petType.defaultName, text: $draft.name)
                            .textFieldStyle(.roundedBorder)
                            .font(.callout)
                            .onChange(of: draft.name) { _, new in
                                if new.count > 10 { draft.name = String(new.prefix(10)) }
                            }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)

                    Divider().padding(.horizontal, 14)

                    // 색상
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("색상").font(.caption).foregroundStyle(.secondary)
                            Spacer()
                            Toggle("레벨 색", isOn: Binding(
                                get: { !draft.useCustomColor },
                                set: { draft.useCustomColor = !$0 }
                            ))
                            .toggleStyle(.checkbox)
                            .font(.caption2)
                        }
                        HStack(spacing: 8) {
                            ForEach(PetCustomization.presetColors, id: \.self) { hex in
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 24, height: 24)
                                    .overlay(Circle().stroke(Color.white, lineWidth: draft.customColorHex == hex && draft.useCustomColor ? 2.5 : 0))
                                    .overlay(Circle().stroke(Color.primary.opacity(0.1), lineWidth: 1))
                                    .opacity(draft.useCustomColor ? 1.0 : 0.35)
                                    .onTapGesture {
                                        draft.customColorHex = hex
                                        draft.useCustomColor = true
                                    }
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)

                    Divider().padding(.horizontal, 14)

                    // 포모도로 시간
                    HStack {
                        Text("포모도로").font(.caption).foregroundStyle(.secondary)
                            .frame(width: 52, alignment: .leading)
                        Spacer()
                        HStack(spacing: 4) {
                            ForEach([15, 25, 50], id: \.self) { min in
                                Button("\(min)분") { draft.pomodoroMinutes = min }
                                    .buttonStyle(.bordered)
                                    .controlSize(.mini)
                                    .tint(draft.pomodoroMinutes == min ? .blue : .secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)

                    Divider().padding(.horizontal, 14)

                    // 일일 목표
                    VStack(alignment: .leading, spacing: 10) {
                        Text("일일 목표").font(.caption).foregroundStyle(.secondary)
                        HStack {
                            Label("커밋", systemImage: "bolt.fill")
                                .font(.caption).foregroundStyle(.secondary)
                            Spacer()
                            Stepper(value: $draft.dailyCommitGoal, in: 1...20) {
                                Text("\(draft.dailyCommitGoal)회").font(.caption)
                            }
                        }
                        HStack {
                            Label("포모도로", systemImage: "timer")
                                .font(.caption).foregroundStyle(.secondary)
                            Spacer()
                            Stepper(value: $draft.dailyPomodoroGoal, in: 1...10) {
                                Text("\(draft.dailyPomodoroGoal)회").font(.caption)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                }
            }

            Divider()

            // 취소 / 저장
            HStack {
                Button("취소", action: onCancel)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                Spacer()
                Button("저장") { onSave(draft) }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .frame(width: 220, height: 560)
    }
}
