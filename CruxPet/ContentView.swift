import SwiftUI
import Observation
import UserNotifications

private struct ToastData: Equatable {
    let emoji: String
    let title: String
    let subtitle: String
}

private struct PomodoroInfoButton: View {
    @State private var showPopover = false

    var body: some View {
        Button {
            showPopover.toggle()
        } label: {
            Image(systemName: "info.circle")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showPopover, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 6) {
                Text("🍅 포모도로 기법")
                    .font(.caption.bold())
                Text("25분 집중 → 5분 휴식을 반복하는\n시간 관리 방법.\n1980년대 Francesco Cirillo가\n토마토 모양 타이머로 개발했어요.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .frame(width: 180)
        }
    }
}

struct ContentView: View {
    @Environment(PetModel.self) private var pet
    @Environment(PomodoroTimer.self) private var pomodoro
    @Environment(EventWatcher.self) private var watcher
    @State private var customization = PetCustomization.load()
    @State private var showCustomize = false
    @State private var showQuitConfirm = false
    @State private var toast: ToastData? = nil

    var body: some View {
        let _ = watcher.pendingCommit  // @Observable 변경 추적 등록
        Group {
            if showCustomize {
                CustomizeView(
                    current: customization,
                    petLevel: pet.level,
                    onSave: { newCustomization in
                        customization = newCustomization
                        customization.save()
                        pomodoro.setDuration(newCustomization.pomodoroMinutes)
                        showCustomize = false
                    },
                    onCancel: { showCustomize = false }
                )
            } else {
                VStack(spacing: 10) {
                    characterSection
                    expSection
                    pomodoroSection
                    activitySection
                    Divider()
                    HStack(spacing: 0) {
                        Button(action: shareCard) {
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
                            showQuitConfirm = true
                        } label: {
                            Image(systemName: "power")
                                .font(.system(size: 14))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .alert("CruxPet 종료", isPresented: $showQuitConfirm) {
                            Button("종료", role: .destructive) { NSApplication.shared.terminate(nil) }
                            Button("취소", role: .cancel) {}
                        } message: {
                            Text("슬라임이 잠들어요. 정말 종료할까요?")
                        }
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
        }
        .frame(width: 200)
        .background(.ultraThinMaterial)
        .animation(.easeInOut(duration: 0.15), value: showCustomize)
        .overlay(alignment: .top) {
            if let toast {
                toastView(toast)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
            }
        }
        .animation(.spring(duration: 0.4), value: toast != nil)
        .onAppear {
            setupWatcher()
            watcher.pollNow()
        }
        .onChange(of: watcher.pendingCommit) { _, hasPending in
            if hasPending {
                watcher.pendingCommit = false
                showToast(ToastData(emoji: "⚡️", title: "커밋 감지!", subtitle: "EXP를 획득했어요"))
            }
        }
    }

    // MARK: - Sections

    private var characterSection: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.06))
                    .frame(width: 90, height: 90)
                    .blur(radius: 14)
                SlimeView(
                    appearance: pet.slimeAppearance.applying(customization),
                    isPomodoroActive: pomodoro.state == .running,
                    accessory: customization.accessory
                )
                if pet.showCritical {
                    Text("💥 CRITICAL!")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.orange)
                        .offset(y: -pet.slimeAppearance.size * 0.8)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: pet.showCritical)
            HStack(spacing: 5) {
                Text("Lv.\(pet.level)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue, in: Capsule())
                Text(customization.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var expSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label("EXP", systemImage: "star.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(pet.expInCurrentLevel)) / \(Int(pet.expNeededThisLevel))")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.tertiary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.15))
                    Capsule()
                        .fill(LinearGradient(
                            colors: [Color(hue: 0.6, saturation: 0.8, brightness: 0.9),
                                     Color(hue: 0.72, saturation: 0.8, brightness: 0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: geo.size.width * min(pet.expInCurrentLevel / max(pet.expNeededThisLevel, 1), 1))
                        .animation(.spring(duration: 0.4), value: pet.expInCurrentLevel)
                }
            }
            .frame(height: 10)
            Text("다음 레벨까지 \(Int(pet.expNeededThisLevel - pet.expInCurrentLevel)) EXP")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private var pomodoroSection: some View {
        let isRunning = pomodoro.state == .running
        let accent: Color = isRunning ? .orange : .blue
        return VStack(spacing: 7) {
            HStack(spacing: 4) {
                Image(systemName: isRunning ? "flame.fill" : "timer")
                    .font(.caption)
                    .foregroundStyle(isRunning ? .orange : .secondary)
                Text(isRunning ? "집중 중" : "포모도로")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isRunning ? .orange : .secondary)
                PomodoroInfoButton()
            }
            Text(pomodoro.displayTime)
                .font(.system(size: 30, weight: .bold, design: .monospaced))
                .foregroundStyle(isRunning ? .primary : .secondary)
                .animation(.none, value: pomodoro.displayTime)
            HStack(spacing: 8) {
                Group {
                    switch pomodoro.state {
                    case .idle:
                        Button("▶  시작") { pomodoro.start() }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                    case .running:
                        Button("⏸  일시정지") { pomodoro.pause() }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        Button("↺") { pomodoro.reset() }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    case .paused:
                        Button("▶  계속") { pomodoro.resume() }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        Button("↺") { pomodoro.reset() }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    case .completed:
                        Button("↺  다시") { pomodoro.reset() }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                    }
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(accent.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(accent.opacity(0.2), lineWidth: 1)
                )
        )
        .animation(.easeInOut(duration: 0.25), value: isRunning)
    }

    private var activitySection: some View {
        HStack(spacing: 8) {
            statChip(value: pet.todayCommitCount, icon: "arrow.triangle.branch", label: "오늘 커밋")
            statChip(value: pet.todayPomodoroCount, icon: "timer", label: "오늘 포모도로")
        }
    }

    private func statChip(value: Int, icon: String, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 1) {
                Text("\(value)회")
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.primary)
                Text(label)
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Toast

    private func toastView(_ data: ToastData) -> some View {
        HStack(spacing: 8) {
            Text(data.emoji)
                .font(.title3)
            VStack(alignment: .leading, spacing: 1) {
                Text(data.title)
                    .font(.caption.weight(.bold))
                Text(data.subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
    }

    private func showToast(_ data: ToastData) {
        withAnimation { toast = data }
        Task {
            try? await Task.sleep(for: .seconds(3))
            withAnimation { toast = nil }
        }
    }

    // MARK: - Setup

    private func setupWatcher() {
        if pomodoro.state == .idle {
            pomodoro.setDuration(customization.pomodoroMinutes)
        }
        watcher.onCommit = {
            pet.gainCommitExp()
        }
        watcher.start()
        pomodoro.onComplete = {
            watcher.appendPomodoro()
            pet.gainPomodoroExp()
            sendPomodoroNotification()
            showToast(ToastData(emoji: "🍅", title: "포모도로 완료!", subtitle: "EXP를 획득했어요 ✨"))
        }
    }

    private func shareCard() {
        let card = ShareCardView(pet: pet, customization: customization)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 2.0
        guard let image = renderer.nsImage else { return }
        let picker = NSSharingServicePicker(items: [image])
        if let button = NSApp.keyWindow?.contentView?.subviews.first {
            picker.show(relativeTo: .zero, of: button, preferredEdge: .minY)
        } else {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.writeObjects([image])
        }
    }

    private func sendPomodoroNotification() {
        let content = UNMutableNotificationContent()
        content.title = "포모도로 완료! 🍅"
        content.body = "EXP 획득! 슬라임이 기뻐해요."
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}

#Preview {
    ContentView()
        .environment(PetModel())
        .environment(PomodoroTimer())
        .environment(EventWatcher())
}
