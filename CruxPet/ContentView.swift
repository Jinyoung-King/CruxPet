import SwiftUI
import Observation

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
    @State private var toast: ToastData? = nil
    @State private var questsModel = QuestModel()
    @State private var isQuestExpanded = false
    @State private var achievementModel = AchievementModel()
    @State private var isAchievementExpanded = false

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
                    questSection
                    achievementSection
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
        }
        .frame(width: 220)
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
        .onChange(of: pet.pendingLevelUp) { _, newLevel in
            guard newLevel > 0 else { return }
            pet.pendingLevelUp = 0
            showToast(ToastData(emoji: "🎉", title: "레벨 업! Lv.\(newLevel)",
                                subtitle: "슬라임이 성장했어요 ✨"))
            checkAchievements()
        }
        .onChange(of: pet.pendingStreakMilestone) { _, milestone in
            guard milestone > 0 else { return }
            pet.pendingStreakMilestone = 0
            let (emoji, subtitle) = streakMilestoneMessage(milestone)
            showToast(ToastData(emoji: emoji, title: "\(milestone)일 연속 달성!", subtitle: subtitle))
        }
        .onChange(of: pet.todayPomodoroCount) { old, new in
            if new > old {
                showToast(ToastData(emoji: "🍅", title: "포모도로 완료!", subtitle: "EXP를 획득했어요 ✨"))
            }
            if questsModel.claimCompleted(pet: pet) {
                showToast(ToastData(emoji: "🎉", title: "퀘스트 올클리어!", subtitle: "+100 EXP 보너스 지급!"))
            }
        }
        .onChange(of: pet.todayCommitCount) { _, _ in
            if questsModel.claimCompleted(pet: pet) {
                showToast(ToastData(emoji: "🎉", title: "퀘스트 올클리어!", subtitle: "+100 EXP 보너스 지급!"))
            }
        }
        .onChange(of: pet.totalCommitCount) { _, _ in
            checkAchievements()
        }
        .onChange(of: pet.totalPomodoroCount) { _, _ in
            checkAchievements()
        }
        .onChange(of: pet.questClearCount) { _, _ in
            checkAchievements()
        }
        .onChange(of: pet.streakDays) { _, _ in
            checkAchievements()
        }
        .onChange(of: pet.level) { _, _ in
            checkAchievements()
        }
    }

    private func streakMilestoneMessage(_ days: Int) -> (String, String) {
        switch days {
        case 3:   return ("🔥", "3일 연속! 습관이 만들어지고 있어요")
        case 7:   return ("🔥", "일주일 개근! 대단한데요?")
        case 14:  return ("💪", "2주 연속! 이제 루틴이 됐네요")
        case 30:  return ("👑", "한 달 연속!! 진짜 레전드")
        case 60:  return ("💎", "두 달 연속... 미쳤다")
        default:  return ("🌟", "무려 \(days)일 연속! 전설의 개발자")
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
                    accessory: "", // TODO: Task 2 - update with accessories slot logic
                    isWandering: pomodoro.state != .running,
                    emotion: pomodoro.state == .running ? .normal : pet.emotion
                )
                if pet.showCritical {
                    Text("💥 CRITICAL!")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.orange)
                        .offset(y: -pet.slimeAppearance.size * 0.8)
                        .transition(.opacity)
                }
                if pet.showLevelUp {
                    Text("🎉 LEVEL UP!")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            LinearGradient(colors: [.purple, .pink],
                                           startPoint: .leading, endPoint: .trailing),
                            in: Capsule()
                        )
                        .shadow(color: .purple.opacity(0.4), radius: 6, y: 2)
                        .offset(y: -pet.slimeAppearance.size * 1.1)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: pet.showCritical)
            .animation(.spring(duration: 0.4), value: pet.showLevelUp)
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
            if pet.streakDays > 0 {
                streakBadge
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.35), value: pet.streakDays)
    }

    private var streakBadge: some View {
        HStack(spacing: 3) {
            Text("🔥")
                .font(.system(size: 11))
            Text("\(pet.streakDays)일 연속")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(streakColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(streakColor.opacity(0.12), in: Capsule())
    }

    private var streakColor: Color {
        switch pet.streakDays {
        case 1...6:   return .orange
        case 7...13:  return .red
        case 14...29: return .purple
        default:      return .yellow
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

    private var questSection: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) { isQuestExpanded.toggle() }
            }) {
                HStack {
                    Image(systemName: "list.bullet.clipboard")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("일일 퀘스트")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("✅ \(questsModel.claimedCount)/\(questsModel.todayQuests.count)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.tertiary)
                    Image(systemName: isQuestExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            if isQuestExpanded {
                VStack(spacing: 4) {
                    ForEach(questsModel.todayQuests) { quest in
                        questRow(quest)
                    }
                }
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var achievementSection: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) { isAchievementExpanded.toggle() }
            }) {
                HStack {
                    Image(systemName: "trophy.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("업적")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("✨ \(achievementModel.claimedCount)개 달성")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.tertiary)
                    Image(systemName: isAchievementExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            if isAchievementExpanded {
                VStack(spacing: 4) {
                    ForEach(achievementModel.visibleAchievements(for: pet)) { achievement in
                        achievementRow(achievement)
                    }
                }
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func questRow(_ quest: Quest) -> some View {
        let claimed = questsModel.isClaimed(quest)
        let (cur, total) = questsModel.progress(for: quest, pet: pet)

        return HStack(spacing: 8) {
            Image(systemName: claimed ? "checkmark.circle.fill" : "circle")
                .font(.caption)
                .foregroundStyle(claimed ? .green : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(quest.description)
                    .font(.caption.weight(claimed ? .regular : .medium))
                    .foregroundStyle(claimed ? .secondary : .primary)

                if claimed {
                    Text("+\(quest.expReward) EXP")
                        .font(.system(size: 9))
                        .foregroundStyle(.green.opacity(0.7))
                } else {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.secondary.opacity(0.15))
                            Capsule()
                                .fill(questsModel.isCompleted(quest, pet: pet)
                                      ? Color.green.opacity(0.7)
                                      : Color.blue.opacity(0.5))
                                .frame(width: total > 0
                                       ? geo.size.width * min(CGFloat(cur) / CGFloat(total), 1)
                                       : 0)
                        }
                    }
                    .frame(height: 4)

                    Text(progressLabel(quest))
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()
            if !claimed {
                Text(quest.difficulty == .easy ? "보통" : "어려움")
                    .font(.system(size: 8))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.secondary.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))
    }

    private func progressLabel(_ quest: Quest) -> String {
        switch quest.type {
        case .commit(let n):
            return "\(min(pet.todayCommitCount, n))/\(n)"
        case .pomodoro(let n):
            return "\(min(pet.todayPomodoroCount, n))/\(n)"
        case .combo(let c, let p):
            return "커밋 \(min(pet.todayCommitCount, c))/\(c) · 포모도로 \(min(pet.todayPomodoroCount, p))/\(p)"
        case .streak(let n):
            return "\(min(pet.streakDays, n))/\(n)일"
        }
    }

    private func achievementRow(_ achievement: Achievement) -> some View {
        let claimed = achievementModel.isClaimed(achievement)
        let (cur, total) = achievementModel.progress(for: achievement, pet: pet)

        return HStack(spacing: 8) {
            Text(achievement.emoji)
                .font(.caption)

            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.title)
                    .font(.caption.weight(claimed ? .regular : .medium))
                    .foregroundStyle(claimed ? .secondary : .primary)

                if claimed {
                    Text("🎉 달성!")
                        .font(.system(size: 9))
                        .foregroundStyle(.green.opacity(0.7))
                } else if case .special(let kind) = achievement.type {
                    Text(specialConditionText(kind))
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                } else {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.secondary.opacity(0.15))
                            Capsule()
                                .fill(Color.orange.opacity(0.5))
                                .frame(width: total > 0
                                       ? geo.size.width * min(CGFloat(cur) / CGFloat(total), 1)
                                       : 0)
                        }
                    }
                    .frame(height: 4)

                    Text("\(cur)/\(total)")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.secondary.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))
    }

    private func specialConditionText(_ kind: SpecialKind) -> String {
        switch kind {
        case .nightOwl:  return "자정(00:00~03:59) 커밋"
        case .sprinter:  return "하루 커밋 5회"
        case .focusKing: return "하루 포모도로 3회"
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

    private func checkAchievements() {
        let newOnes = achievementModel.claimCompleted(pet: pet)
        guard !newOnes.isEmpty else { return }
        if newOnes.count == 1 {
            showToast(ToastData(emoji: "🏆", title: "업적 달성! \(newOnes[0].title)", subtitle: "새 업적을 달성했어요"))
        } else {
            showToast(ToastData(emoji: "🏆", title: "업적 \(newOnes.count)개 달성!", subtitle: "새 업적을 달성했어요"))
        }
    }

    // MARK: - Setup

    private func setupWatcher() {
        if pomodoro.state == .idle {
            pomodoro.setDuration(customization.pomodoroMinutes)
        }
        questsModel.refreshIfNeeded()
        questsModel.claimCompleted(pet: pet)
        achievementModel.claimCompleted(pet: pet)
    }

    private func confirmQuit() {
        let alert = NSAlert()
        alert.messageText = "CruxPet 종료"
        alert.informativeText = "슬라임이 잠들어요. 정말 종료할까요?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "취소")
        alert.addButton(withTitle: "종료")
        if alert.runModal() == .alertSecondButtonReturn {
            NSApplication.shared.terminate(nil)
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

}

#Preview {
    ContentView()
        .environment(PetModel())
        .environment(PomodoroTimer())
        .environment(EventWatcher())
}
