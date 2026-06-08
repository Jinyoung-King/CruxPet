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
        ScrollView {
            VStack(spacing: 12) {
                // 실시간 미리보기
                SlimeView(appearance: previewAppearance, accessory: draft.accessory)
                    .frame(height: 80)

                Divider()

                // 이름
                VStack(alignment: .leading, spacing: 4) {
                    Text("이름").font(.caption.bold()).foregroundStyle(.secondary)
                    TextField("슬라임 이름", text: $draft.name)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)
                        .onChange(of: draft.name) { _, new in
                            if new.count > 10 { draft.name = String(new.prefix(10)) }
                        }
                }

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

                // 악세서리
                VStack(alignment: .leading, spacing: 6) {
                    Text("악세서리").font(.caption.bold()).foregroundStyle(.secondary)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 6) {
                        ForEach(PetCustomization.accessories, id: \.self) { emoji in
                            Text(emoji)
                                .font(.title3)
                                .frame(width: 32, height: 32)
                                .background(draft.accessory == emoji ? Color.blue.opacity(0.2) : Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                                .onTapGesture { draft.accessory = draft.accessory == emoji ? "" : emoji }
                        }
                        Text("✕")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 32, height: 32)
                            .background(draft.accessory.isEmpty ? Color.blue.opacity(0.2) : Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                            .onTapGesture { draft.accessory = "" }
                    }
                }

                // 포모도로 시간
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
            }
            .padding(12)
        }
        .frame(width: 200, height: 380)
    }
}
