import SwiftUI
import Observation

private struct ToastData: Equatable {
    let icon: String
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
                Label("포모도로 기법", systemImage: "timer")
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

private struct DailyGoalView: View {
    let todayCommits: Int
    let todayPomodoros: Int
    let commitGoal: Int
    let pomodoroGoal: Int
    var onTap: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            goalRow("bolt.fill", "커밋",  current: todayCommits,   goal: commitGoal)
            goalRow("timer", "포모", current: todayPomodoros, goal: pomodoroGoal)
        }
    }

    private func goalRow(_ icon: String, _ label: String, current: Int, goal: Int) -> some View {
        let done = current >= goal
        let ratio: CGFloat = goal > 0 ? min(CGFloat(current) / CGFloat(goal), 1.0) : 0
        return HStack(spacing: 6) {
            HStack(spacing: 3) {
                Image(systemName: icon).font(.system(size: 9))
                Text(label)
            }
            .font(.system(size: 10))
            .foregroundStyle(.secondary)
            .frame(width: 40, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.15))
                    Capsule()
                        .fill(done ? Color.green.opacity(0.6) : Color.blue.opacity(0.5))
                        .frame(width: geo.size.width * ratio)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: current)
                }
            }
            .frame(height: 8)
            HStack(spacing: 2) {
                Text("\(current)/\(goal)")
                    .font(.system(size: 9))
                    .foregroundStyle(done ? .green : .secondary)
                if done {
                    Image(systemName: "checkmark").font(.system(size: 9)).foregroundStyle(.green)
                }
            }
            .frame(width: 36, alignment: .trailing)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(done ? Color.green.opacity(0.07) : Color.clear)
        )
        .animation(.easeInOut(duration: 0.3), value: done)
        .onTapGesture { onTap() }
    }
}

private struct AchievementsView: View {
    let achievementModel: AchievementModel
    let pet: PetModel
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 3) {
                        Image(systemName: "chevron.left")
                            .font(.caption.weight(.semibold))
                        Text("뒤로")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                Spacer()
                Text("업적")
                    .font(.caption.weight(.semibold))
                Spacer()
                Label("\(achievementModel.claimedCount)개 달성", systemImage: "sparkles")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            ScrollView {
                VStack(spacing: 4) {
                    ForEach(achievementModel.visibleAchievements(for: pet)) { achievement in
                        achievementRow(achievement)
                    }
                }
                .padding(12)
            }
        }
        .frame(width: 280, height: 400)
    }

    private func achievementRow(_ achievement: Achievement) -> some View {
        let claimed = achievementModel.isClaimed(achievement)
        let (cur, total) = achievementModel.progress(for: achievement, pet: pet)

        return HStack(spacing: 8) {
            Image(systemName: achievement.sfSymbol)
                .font(.caption)
                .symbolRenderingMode(.multicolor)
            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.title)
                    .font(.caption.weight(claimed ? .regular : .medium))
                    .foregroundStyle(claimed ? .secondary : .primary)
                if claimed {
                    Label("달성!", systemImage: "checkmark.seal.fill")
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
}

struct ContentView: View {
    @Environment(PetModel.self) private var pet
    @Environment(PomodoroTimer.self) private var pomodoro
    @Environment(EventWatcher.self) private var watcher
    @Environment(PetInteractionModel.self) private var interaction
    @Environment(ActivityHistoryModel.self) private var history
    @State private var customization = PetCustomization.load()
    @State private var showCustomize = false
    @State private var selectedTab = 0
    @State private var toast: ToastData? = nil
    @State private var questsModel = QuestModel()
    @State private var isQuestExpanded = false
    @State private var isStatsExpanded = false
    @State private var achievementModel = AchievementModel()
    @State private var showAchievements = false
    @State private var activityDays: Set<String> = []
    @State private var companionModel = CompanionModel()
    @State private var showSharePreview = false

    var body: some View {
        let _ = watcher.pendingCommit  // @Observable 변경 추적 등록
        Group {
            if showAchievements {
                AchievementsView(
                    achievementModel: achievementModel,
                    pet: pet,
                    onBack: { showAchievements = false }
                )
            } else if showSharePreview {
                sharePreviewSection
            } else if showCustomize {
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
                VStack(spacing: 0) {
                    TabView(selection: $selectedTab) {
                        ScrollView {
                            VStack(spacing: 10) {
                                characterSection
                                goalSection
                            }
                            .padding(12)
                        }
                        .tabItem { Label("홈", systemImage: "pawprint.fill") }
                        .tag(0)

                        pomodoroSection
                            .tabItem { Label("포모도로", systemImage: "timer") }
                            .tag(1)

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
                        .tag(2)
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
        }
        .frame(width: 280, height: 400)
        .background(.ultraThinMaterial)
        .animation(.easeInOut(duration: 0.15), value: showCustomize)
        .animation(.easeInOut(duration: 0.15), value: showSharePreview)
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
            refreshActivityDays()
            checkCompanionUnlocks()
        }
        .onChange(of: watcher.pendingCommit) { _, hasPending in
            if hasPending {
                watcher.pendingCommit = false
                showToast(ToastData(icon: "bolt.fill", title: "커밋 감지!", subtitle: "EXP를 획득했어요"))
            }
        }
        .onChange(of: pet.pendingLevelUp) { _, newLevel in
            guard newLevel > 0 else { return }
            pet.pendingLevelUp = 0
            showToast(ToastData(icon: "party.popper", title: "레벨 업! Lv.\(newLevel)",
                                subtitle: "슬라임이 성장했어요"))
            checkAchievements()
        }
        .onChange(of: pet.pendingStreakMilestone) { _, milestone in
            guard milestone > 0 else { return }
            pet.pendingStreakMilestone = 0
            let (icon, subtitle) = streakMilestoneMessage(milestone)
            showToast(ToastData(icon: icon, title: "\(milestone)일 연속 달성!", subtitle: subtitle))
        }
        .onChange(of: pet.todayPomodoroCount) { old, new in
            if new > old {
                showToast(ToastData(icon: "timer", title: "포모도로 완료!", subtitle: "EXP를 획득했어요"))
            }
            if questsModel.claimCompleted(pet: pet) {
                showToast(ToastData(icon: "party.popper", title: "퀘스트 올클리어!", subtitle: "+100 EXP 보너스 지급!"))
            }
            refreshActivityDays()
        }
        .onChange(of: pet.todayCommitCount) { _, _ in
            if questsModel.claimCompleted(pet: pet) {
                showToast(ToastData(icon: "party.popper", title: "퀘스트 올클리어!", subtitle: "+100 EXP 보너스 지급!"))
            }
            refreshActivityDays()
        }
        .onChange(of: pet.totalCommitCount) { _, _ in
            checkAchievements()
            checkCompanionUnlocks()
        }
        .onChange(of: pet.totalPomodoroCount) { _, _ in
            checkAchievements()
            checkCompanionUnlocks()
        }
        .onChange(of: pet.questClearCount) { _, _ in
            checkAchievements()
            checkCompanionUnlocks()
        }
        .onChange(of: pet.streakDays) { _, _ in
            checkAchievements()
            checkCompanionUnlocks()
        }
        .onChange(of: pet.level) { _, _ in
            checkAchievements()
            checkCompanionUnlocks()
        }
        .onChange(of: pet.hasNightOwlCommit) { _, val in
            if val { checkCompanionUnlocks() }
        }
    }

    private func streakMilestoneMessage(_ days: Int) -> (String, String) {
        switch days {
        case 3:   return ("flame.fill", "3일 연속! 습관이 만들어지고 있어요")
        case 7:   return ("flame.fill", "일주일 개근! 대단한데요?")
        case 14:  return ("figure.strengthtraining.traditional", "2주 연속! 이제 루틴이 됐네요")
        case 30:  return ("crown.fill", "한 달 연속!! 진짜 레전드")
        case 60:  return ("diamond.fill", "두 달 연속... 미쳤다")
        default:  return ("star.fill", "무려 \(days)일 연속! 전설의 개발자")
        }
    }

    // MARK: - Sections

    private var characterSection: some View {
        VStack(spacing: 6) {
            ZStack {
                PixelBackgroundView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Circle()
                    .fill(Color.blue.opacity(0.06))
                    .frame(width: 135, height: 135)
                    .blur(radius: 14)
                PetView(
                    petType: customization.petType,
                    appearance: pet.slimeAppearance.applying(customization),
                    level: pet.level,
                    emotion: pomodoro.state == .running ? .normal : pet.emotion,
                    accessories: customization.accessories,
                    isPomodoroActive: pomodoro.state == .running,
                    isWandering: pomodoro.state != .running
                )
                .scaleEffect(interaction.isTapped ? 1.875 : 1.5)
                .offset(y: pet.showJump ? -22 : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.4), value: pet.showJump)
                .offset(y: pet.showPomoComplete ? -28 : 0)
                .animation(.spring(response: 0.35, dampingFraction: 0.3), value: pet.showPomoComplete)
                .animation(.spring(response: 0.25, dampingFraction: 0.4), value: interaction.isTapped)
                .onTapGesture { interaction.tap(pet: pet) }
                if interaction.showParticles {
                    ParticleOverlayView()
                }
                if pet.showCritical {
                    Label("CRITICAL!", systemImage: "bolt.circle.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.orange)
                        .offset(y: -pet.slimeAppearance.size * 0.8)
                        .transition(.opacity)
                }
                if pet.showLevelUp {
                    Label("LEVEL UP!", systemImage: "party.popper")
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
                if pet.showLevelUp {
                    LevelUpParticleView()
                        .id(pet.level)
                        .transition(.opacity)
                }
                if pet.isIdleSleeping {
                    ZzzOverlayView()
                        .transition(.opacity)
                }
            }
            .frame(height: 220)
            .clipped()
            .animation(.easeInOut(duration: 0.2), value: pet.showCritical)
            .animation(.spring(duration: 0.4), value: pet.showLevelUp)
            treatButton
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
                streakCalendar
                    .transition(.opacity)
            }
            if !companionModel.unlockedCompanions.isEmpty {
                companionRow
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.35), value: pet.streakDays)
        .animation(.spring(duration: 0.4), value: companionModel.unlockedIDs)
    }

    private var treatButton: some View {
        Button {
            interaction.feed(pet: pet)
        } label: {
            HStack(spacing: 3) {
                Image(systemName: interaction.isEating ? "face.smiling.fill" : "gift.fill")
                    .font(.system(size: 13))
                if !interaction.canFeed {
                    Text("\(max(1, Int(interaction.cooldownRemaining / 60)))분")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!interaction.canFeed)
        .opacity(interaction.canFeed ? 1.0 : 0.45)
    }

    private var streakBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: "flame.fill")
                .font(.system(size: 11))
                .foregroundStyle(.orange)
            Text("\(pet.streakDays)일 연속")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(streakColor)
            if pet.streakMultiplier > 1.0 {
                Text("×\(String(format: "%.1f", pet.streakMultiplier))")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(streakColor.opacity(0.8))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(streakColor.opacity(0.12), in: Capsule())
    }

    private var streakCalendar: some View {
        let days = last7Days()
        let todayStr = days.last ?? ""
        return HStack(spacing: 0) {
            ForEach(days, id: \.self) { dateStr in
                let isActive = activityDays.contains(dateStr)
                let isToday = dateStr == todayStr
                VStack(spacing: 3) {
                    Text(weekdayLabel(for: dateStr))
                        .font(.system(size: 8, weight: isToday ? .bold : .regular))
                        .foregroundStyle(isToday ? streakColor : Color.secondary.opacity(0.5))
                    Image(systemName: isActive ? "circle.fill" : "circle")
                        .font(.system(size: 8))
                        .foregroundStyle(isActive ? streakColor : Color.secondary.opacity(0.3))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 4)
    }

    private var companionRow: some View {
        HStack(spacing: 8) {
            ForEach(companionModel.unlockedCompanions) { companion in
                CompanionSlimeView(companion: companion)
            }
        }
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

    private var goalSection: some View {
        DailyGoalView(
            todayCommits: pet.todayCommitCount,
            todayPomodoros: pet.todayPomodoroCount,
            commitGoal: customization.dailyCommitGoal,
            pomodoroGoal: customization.dailyPomodoroGoal,
            onTap: { withAnimation(.easeInOut(duration: 0.2)) { isStatsExpanded = true; selectedTab = 2 } }
        )
    }

    private var statsSection: some View {
        StatsView(pet: pet, history: history, isExpanded: $isStatsExpanded)
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
                    Label("\(questsModel.claimedCount)/\(questsModel.todayQuests.count)", systemImage: "checkmark.circle.fill")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.green)
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
        Button(action: { showAchievements = true }) {
            HStack {
                Image(systemName: "trophy.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("업적")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Label("\(achievementModel.claimedCount)개 달성", systemImage: "sparkles")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.tertiary)
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
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


    private var pomodoroSection: some View {
        let isRunning = pomodoro.state == .running
        let isBreak = pomodoro.state == .shortBreak || pomodoro.state == .longBreak
        let isCompleted = pomodoro.state == .completed
        let accent: Color = isRunning ? .orange : isCompleted ? .green : isBreak ? .teal : .blue
        let headerIcon: String = isRunning ? "flame.fill" : isCompleted ? "checkmark.circle.fill" : isBreak ? "cup.and.saucer.fill" : "timer"
        let headerText: String = {
            switch pomodoro.state {
            case .running:    return "집중 중"
            case .completed:  return "포모도로 완료"
            case .shortBreak: return "☕ 짧은 휴식"
            case .longBreak:  return "🛋 긴 휴식"
            default:          return "포모도로"
            }
        }()
        return VStack(spacing: 16) {
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: headerIcon)
                    .font(.caption)
                    .foregroundStyle(accent)
                Text(headerText)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(accent)
                if pomodoro.state == .idle || pomodoro.state == .paused {
                    PomodoroInfoButton()
                }
            }
            Text(pomodoro.displayTime)
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundStyle(isRunning || isCompleted || isBreak ? .primary : .secondary)
                .animation(.none, value: pomodoro.displayTime)
            if pomodoro.sessionCount > 0 {
                Label("× \(pomodoro.sessionCount)", systemImage: "timer")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                Group {
                    switch pomodoro.state {
                    case .idle:
                        Button("▶  시작") { pomodoro.start() }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.regular)
                    case .running:
                        Button("⏸  일시정지") { pomodoro.pause() }
                            .buttonStyle(.bordered)
                            .controlSize(.regular)
                        Button("↺") { pomodoro.reset() }
                            .buttonStyle(.bordered)
                            .controlSize(.regular)
                    case .paused:
                        Button("▶  계속") { pomodoro.resume() }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.regular)
                        Button("↺") { pomodoro.reset() }
                            .buttonStyle(.bordered)
                            .controlSize(.regular)
                    case .completed:
                        Button("☕  휴식 시작") { pomodoro.startBreak() }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                            .controlSize(.regular)
                        Button("↺") { pomodoro.reset() }
                            .buttonStyle(.bordered)
                            .controlSize(.regular)
                    case .shortBreak, .longBreak:
                        Button("건너뛰기") { pomodoro.skipBreak() }
                            .buttonStyle(.bordered)
                            .controlSize(.regular)
                    }
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.25), value: pomodoro.state)
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
            Image(systemName: data.icon)
                .font(.title3)
                .symbolRenderingMode(.multicolor)
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
            showToast(ToastData(icon: "trophy.fill", title: "업적 달성! \(newOnes[0].title)", subtitle: "새 업적을 달성했어요"))
        } else {
            showToast(ToastData(icon: "trophy.fill", title: "업적 \(newOnes.count)개 달성!", subtitle: "새 업적을 달성했어요"))
        }
    }

    // MARK: - Setup

    private func refreshActivityDays() {
        activityDays = watcher.activityDays(last: 7)
    }

    private func last7Days() -> [String] {
        let calendar = Calendar.current
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = calendar.timeZone
        return (0..<7).reversed().map { i in
            fmt.string(from: calendar.date(byAdding: .day, value: -i, to: Date())!)
        }
    }

    private func weekdayLabel(for dateStr: String) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        guard let date = fmt.date(from: dateStr) else { return "" }
        let labels = ["일", "월", "화", "수", "목", "금", "토"]
        return labels[Calendar.current.component(.weekday, from: date) - 1]
    }

    private func setupWatcher() {
        if pomodoro.state == .idle {
            pomodoro.setDuration(customization.pomodoroMinutes)
        }
        questsModel.refreshIfNeeded()
        questsModel.claimCompleted(pet: pet)
        achievementModel.claimCompleted(pet: pet)
    }

    @MainActor
    private func checkCompanionUnlocks() {
        let newOnes = companionModel.checkUnlocks(
            level: pet.level,
            streakDays: pet.streakDays,
            claimedAchievementCount: achievementModel.claimedCount,
            hasNightOwlCommit: pet.hasNightOwlCommit,
            totalPomodoroCount: pet.totalPomodoroCount
        )
        for companion in newOnes {
            showToast(ToastData(icon: "pawprint.fill", title: "\(companion.name) 등장!",
                                subtitle: "새 친구를 얻었어요"))
        }
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

    private var sharePreviewSection: some View {
        let scale: CGFloat = 196.0 / 300.0
        return VStack(spacing: 12) {
            HStack {
                Button(action: { showSharePreview = false }) {
                    HStack(spacing: 3) {
                        Image(systemName: "chevron.left")
                            .font(.caption.weight(.semibold))
                        Text("뒤로")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                Spacer()
                Text("공유 카드 미리보기")
                    .font(.caption.weight(.semibold))
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            ShareCardView(pet: pet, customization: customization)
                .scaleEffect(scale, anchor: .top)
                .frame(width: 300 * scale, height: 560 * scale)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.15), radius: 6, y: 2)

            HStack(spacing: 8) {
                Button("취소") { showSharePreview = false }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                Button("공유하기") { shareCard(); showSharePreview = false }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
            }
            .padding(.bottom, 12)
        }
        .frame(width: 280)
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

private struct ZzzOverlayView: View {
    @State private var floated = false

    private let sizes: [CGFloat] = [8, 11, 14]
    private let xTargets: [CGFloat] = [10, 20, 32]
    private let yTargets: [CGFloat] = [-18, -32, -48]

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Text("z")
                    .font(.system(size: sizes[i], weight: .bold, design: .rounded))
                    .foregroundStyle(.indigo.opacity(0.7))
                    .offset(
                        x: floated ? xTargets[i] : 0,
                        y: floated ? yTargets[i] : 0
                    )
                    .opacity(floated ? 0 : 0.85)
                    .animation(
                        .easeOut(duration: 1.4)
                            .delay(Double(i) * 0.5)
                            .repeatForever(autoreverses: false),
                        value: floated
                    )
            }
        }
        .onAppear { floated = true }
    }
}

private struct LevelUpParticleView: View {
    @State private var floated = false

    private let xOffsets: [CGFloat] = [-55, -35, -15, -5, 5, 15, 35, 55]
    private let yOffsets: [CGFloat] = [-70, -80, -85, -88, -88, -85, -80, -70]

    var body: some View {
        ZStack {
            ForEach(xOffsets.indices, id: \.self) { i in
                Image(systemName: "sparkle")
                    .font(.system(size: 14))
                    .foregroundStyle(.yellow)
                    .offset(x: floated ? xOffsets[i] : 0,
                            y: floated ? yOffsets[i] : 0)
                    .opacity(floated ? 0 : 1)
                    .animation(
                        .easeOut(duration: 0.9).delay(Double(i) * 0.07),
                        value: floated
                    )
            }
        }
        .onAppear { floated = true }
    }
}

private struct ParticleOverlayView: View {
    @State private var floated = false

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Image(systemName: "heart.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.red)
                    .offset(x: CGFloat(i - 1) * 10, y: floated ? -40 : 0)
                    .opacity(floated ? 0 : 1)
                    .animation(.easeOut(duration: 0.8).delay(Double(i) * 0.1), value: floated)
            }
        }
        .onAppear { floated = true }
    }
}

#Preview {
    ContentView()
        .environment(PetModel())
        .environment(PomodoroTimer())
        .environment(EventWatcher())
        .environment(PetInteractionModel())
        .environment(ActivityHistoryModel())
}
