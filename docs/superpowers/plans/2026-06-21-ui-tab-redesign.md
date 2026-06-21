# UI Tab Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the single long-scroll main view with a 3-tab layout (홈 / 포모도로 / 스탯) and resize the window from 220px to 280×400px.

**Architecture:** Single file changed: `CruxPet/ContentView.swift`. The existing section computed vars are kept unchanged — only their placement inside the new `TabView` changes. The persistent footer (share/settings/quit) moves below the `TabView`.

**Tech Stack:** SwiftUI TabView (native macOS tab style)

---

### Task 1: Replace main VStack with TabView in ContentView.swift

**Files:**
- Modify: `CruxPet/ContentView.swift:218-268`

No tests needed — pure structural UI change, verified by build success and visual inspection.

- [ ] **Step 1: Replace the else-branch VStack with TabView**

In `CruxPet/ContentView.swift`, find and replace the entire `else` branch (lines 218–265) plus the `.frame(width: 220)` modifier.

**Find this block** (lines 218–265 + 268):

```swift
            } else {
                VStack(spacing: 10) {
                    characterSection
                    goalSection
                    expSection
                    statsSection
                    questSection
                    achievementSection
                    pomodoroSection
                    activitySection
                    Divider()
                    HStack(spacing: 0) {
                        Button(action: { showSharePreview = true }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 14))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        Button {
                            showCustomize = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 14))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        Button {
                            confirmQuit()
                        } label: {
                            Image(systemName: "power")
                                .font(.system(size: 14))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                    Text("v\(version)")
                        .font(.system(size: 9))
                        .foregroundStyle(.quaternary)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 2)
                }
                }
                .padding(12)
            }
```

**Replace with:**

```swift
            } else {
                VStack(spacing: 0) {
                    TabView {
                        ScrollView {
                            VStack(spacing: 10) {
                                characterSection
                                goalSection
                            }
                            .padding(12)
                        }
                        .tabItem { Label("홈", systemImage: "pawprint.fill") }

                        pomodoroSection
                            .padding(12)
                            .tabItem { Label("포모도로", systemImage: "timer") }

                        ScrollView {
                            VStack(spacing: 10) {
                                expSection
                                statsSection
                                questSection
                                achievementSection
                                activitySection
                            }
                            .padding(12)
                        }
                        .tabItem { Label("스탯", systemImage: "chart.bar.fill") }
                    }

                    Divider()
                    HStack(spacing: 0) {
                        Button(action: { showSharePreview = true }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 14))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        Button {
                            showCustomize = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 14))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        Button {
                            confirmQuit()
                        } label: {
                            Image(systemName: "power")
                                .font(.system(size: 14))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                        Text("v\(version)")
                            .font(.system(size: 9))
                            .foregroundStyle(.quaternary)
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 2)
                    }
                }
            }
```

- [ ] **Step 2: Update the window frame**

In the same file, find:

```swift
        .frame(width: 220)
```

Replace with:

```swift
        .frame(width: 280, height: 400)
```

- [ ] **Step 3: Build to verify no errors**

```bash
cd /Users/jiny/dev/CruxPet
xcodebuild -scheme CruxPet -destination 'platform=macOS' build 2>&1 | grep -E "error:|Build succeeded"
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add CruxPet/ContentView.swift
git commit -m "feat: redesign main UI with 3-tab layout (홈/포모도로/스탯)"
```
