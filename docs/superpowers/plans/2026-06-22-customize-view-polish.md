# CustomizeView Design Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `CustomizeView` visually consistent with the home screen — enhanced pet preview with pixel background/blur, styled section panels replacing bare dividers, and unified 8pt corner radii throughout.

**Architecture:** Single file change: `CruxPet/CustomizeView.swift` (225 lines). Task 1 enhances the pet preview. Task 2 replaces the two `Divider()` views with panel-wrapped sections and updates `cornerRadius: 6` → `8` everywhere in the file.

**Tech Stack:** SwiftUI, macOS 14.6, `PixelBackgroundView` (no-arg struct, already in the project)

---

### Task 1: Enhance pet preview with PixelBackgroundView + blur

**Files:**
- Modify: `CruxPet/CustomizeView.swift` (lines 31–40)

**Context:** The current preview is a bare `PetView` at 80pt height. The home screen wraps the pet in a ZStack with `PixelBackgroundView()` and a blue blur circle. We replicate that pattern here at 130pt, clipped with a rounded rect.

- [ ] **Step 1: Replace the pet preview block**

In `CruxPet/CustomizeView.swift`, find lines 31–40:

```swift
                // 실시간 미리보기
                PetView(
                    petType: draft.petType,
                    appearance: previewAppearance,
                    level: petLevel,
                    emotion: .normal,
                    accessories: draft.accessories,
                    isPomodoroActive: false,
                    isWandering: false
                )
                .frame(height: 80)
```

Replace with:

```swift
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
                        accessories: draft.accessories,
                        isPomodoroActive: false,
                        isWandering: false
                    )
                }
                .frame(height: 130)
                .clipShape(RoundedRectangle(cornerRadius: 8))
```

- [ ] **Step 2: Build to verify no errors**

```bash
cd /Users/jiny/dev/CruxPet
xcodebuild -scheme CruxPet -destination 'platform=macOS' build 2>&1 | grep -E "error:|Build succeeded"
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add CruxPet/CustomizeView.swift
git commit -m "feat: enhance CustomizeView pet preview with pixel background"
```

---

### Task 2: Replace Dividers with panel backgrounds + update corner radii

**Files:**
- Modify: `CruxPet/CustomizeView.swift` (lines 42–198)

**Context:** Two bare `Divider()` views (lines 42, 79) separate sections visually. We remove them and wrap each section in a subtle panel. Five sections become four independent panels plus one combined settings panel (pomodoro + daily goals). All `cornerRadius: 6` → `8` throughout.

- [ ] **Step 1: Rewrite the sections block (lines 42–198)**

In `CruxPet/CustomizeView.swift`, find the entire block from line 42 to line 198:

```swift
                Divider()

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
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
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

                Divider()

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

                    // 슬롯 탭 바
                    HStack(spacing: 4) {
                        ForEach(AccessorySlot.allCases, id: \.self) { slot in
                            Text(slot.label)
                                .font(.system(size: 10))
                                .lineLimit(1)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .frame(maxWidth: .infinity)
                                .background(selectedSlot == slot ? Color.blue.opacity(0.15) : Color.secondary.opacity(0.08),
                                            in: RoundedRectangle(cornerRadius: 6))
                                .overlay(RoundedRectangle(cornerRadius: 6)
                                    .stroke(selectedSlot == slot ? Color.blue.opacity(0.4) : Color.clear, lineWidth: 1))
                                .onTapGesture { selectedSlot = slot }
                        }
                    }

                    // 선택된 슬롯의 아이템 그리드
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 6) {
                        ForEach(selectedSlot.items, id: \.self) { emoji in
                            Text(emoji)
                                .font(.title3)
                                .frame(width: 32, height: 32)
                                .background(draft.accessories[selectedSlot] == emoji ? Color.blue.opacity(0.2) : Color.secondary.opacity(0.1),
                                            in: RoundedRectangle(cornerRadius: 6))
                                .onTapGesture {
                                    if draft.accessories[selectedSlot] == emoji {
                                        draft.accessories.removeValue(forKey: selectedSlot)
                                    } else {
                                        draft.accessories[selectedSlot] = emoji
                                    }
                                }
                        }
                        Text("✕")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 32, height: 32)
                            .background(draft.accessories[selectedSlot] == nil ? Color.blue.opacity(0.2) : Color.secondary.opacity(0.1),
                                        in: RoundedRectangle(cornerRadius: 6))
                            .onTapGesture { draft.accessories.removeValue(forKey: selectedSlot) }
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

                // 일일 목표
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
```

Replace with:

```swift
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

                // 악세서리
                VStack(alignment: .leading, spacing: 6) {
                    Text("악세서리").font(.caption.bold()).foregroundStyle(.secondary)

                    // 슬롯 탭 바
                    HStack(spacing: 4) {
                        ForEach(AccessorySlot.allCases, id: \.self) { slot in
                            Text(slot.label)
                                .font(.system(size: 10))
                                .lineLimit(1)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .frame(maxWidth: .infinity)
                                .background(selectedSlot == slot ? Color.blue.opacity(0.15) : Color.secondary.opacity(0.08),
                                            in: RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedSlot == slot ? Color.blue.opacity(0.4) : Color.clear, lineWidth: 1))
                                .onTapGesture { selectedSlot = slot }
                        }
                    }

                    // 선택된 슬롯의 아이템 그리드
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 6) {
                        ForEach(selectedSlot.items, id: \.self) { emoji in
                            Text(emoji)
                                .font(.title3)
                                .frame(width: 32, height: 32)
                                .background(draft.accessories[selectedSlot] == emoji ? Color.blue.opacity(0.2) : Color.secondary.opacity(0.1),
                                            in: RoundedRectangle(cornerRadius: 8))
                                .onTapGesture {
                                    if draft.accessories[selectedSlot] == emoji {
                                        draft.accessories.removeValue(forKey: selectedSlot)
                                    } else {
                                        draft.accessories[selectedSlot] = emoji
                                    }
                                }
                        }
                        Text("✕")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 32, height: 32)
                            .background(draft.accessories[selectedSlot] == nil ? Color.blue.opacity(0.2) : Color.secondary.opacity(0.1),
                                        in: RoundedRectangle(cornerRadius: 8))
                            .onTapGesture { draft.accessories.removeValue(forKey: selectedSlot) }
                    }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(.primary.opacity(0.04)))

                // 설정 (포모도로 시간 + 일일 목표)
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
```

- [ ] **Step 2: Build to verify no errors**

```bash
cd /Users/jiny/dev/CruxPet
xcodebuild -scheme CruxPet -destination 'platform=macOS' build 2>&1 | grep -E "error:|Build succeeded"
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add CruxPet/CustomizeView.swift
git commit -m "feat: add section panels and unified corner radii to CustomizeView"
```
