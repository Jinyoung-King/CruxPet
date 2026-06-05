import SwiftUI
import Observation
import UserNotifications

struct ContentView: View {
    @State private var pet = PetModel()
    @State private var pomodoro = PomodoroTimer()
    @State private var watcher = EventWatcher()

    var body: some View {
        VStack(spacing: 10) {
            characterSection
            expSection
            pomodoroSection
            activitySection
            Divider()
            Button("종료") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .font(.caption)
        }
        .padding(12)
        .frame(width: 200)
        .onAppear { setupWatcher() }
    }

    // MARK: - Sections

    private var characterSection: some View {
        VStack(spacing: 2) {
            ZStack {
                SlimeView(
                    appearance: pet.slimeAppearance,
                    isPomodoroActive: pomodoro.state == .running
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
            Text("Lv. \(pet.level)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }

    private var expSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Label("EXP", systemImage: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(pet.expInCurrentLevel)) / \(Int(pet.expNeededThisLevel))")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue.gradient)
                        .frame(width: geo.size.width * min(pet.expInCurrentLevel / max(pet.expNeededThisLevel, 1), 1))
                        .animation(.spring(duration: 0.4), value: pet.expInCurrentLevel)
                }
            }
            .frame(height: 8)
            Text("Lv.\(pet.level + 1)까지 \(Int(pet.expNeededThisLevel - pet.expInCurrentLevel)) EXP")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private var pomodoroSection: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: "timer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("포모도로")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(pomodoro.displayTime)
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundStyle(pomodoro.state == .running ? .primary : .secondary)
            HStack(spacing: 8) {
                Group {
                    switch pomodoro.state {
                    case .idle:
                        Button("▶ 시작") { pomodoro.start() }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                    case .running:
                        Button("⏸ 일시정지") { pomodoro.pause() }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        Button("↺") { pomodoro.reset() }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    case .paused:
                        Button("▶ 계속") { pomodoro.resume() }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        Button("↺") { pomodoro.reset() }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    case .completed:
                        Button("↺ 다시") { pomodoro.reset() }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                    }
                }
            }
        }
        .padding(8)
        .background(Color.blue.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
    }

    private var activitySection: some View {
        HStack {
            Label("\(pet.todayCommitCount)회", systemImage: "externaldrive")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer()
            Label("\(pet.todayPomodoroCount)회", systemImage: "timer")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Setup

    private func setupWatcher() {
        watcher.onCommit = { pet.gainCommitExp() }
        // watcher.onPomodoro is intentionally NOT set:
        // Pomodoro EXP is granted directly in onComplete to avoid
        // double-counting when appendPomodoro() writes and poll() reads it back.
        watcher.start()
        pomodoro.onComplete = {
            watcher.appendPomodoro()   // record only — EXP granted below
            pet.gainPomodoroExp()
            sendPomodoroNotification()
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
}
