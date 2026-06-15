// CruxPet/StatsView.swift
import SwiftUI
import Charts

struct StatsView: View {
    let pet: PetModel
    let history: ActivityHistoryModel

    @State private var isExpanded = false

    private var last7: [DailyActivity] {
        history.last7Days(todayCommits: pet.todayCommitCount, todayPomodoros: pet.todayPomodoroCount)
    }

    private struct BarEntry: Identifiable {
        let id = UUID()
        let dayLabel: String
        let value: Int
        let series: String
    }

    private var barData: [BarEntry] {
        last7.flatMap { day in
            let label = shortLabel(day.dateString)
            return [
                BarEntry(dayLabel: label, value: day.commits,   series: "커밋"),
                BarEntry(dayLabel: label, value: day.pomodoros, series: "포모도로")
            ]
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack {
                    Text("📊 주간 스탯").font(.caption.bold())
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                Chart(barData) { entry in
                    BarMark(
                        x: .value("날짜", entry.dayLabel),
                        y: .value("횟수", entry.value)
                    )
                    .foregroundStyle(by: .value("종류", entry.series))
                }
                .chartForegroundStyleScale([
                    "커밋":    Color.blue.opacity(0.75),
                    "포모도로": Color.orange.opacity(0.75)
                ])
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel().font(.system(size: 8))
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 3)) { _ in
                        AxisValueLabel().font(.system(size: 8))
                        AxisGridLine()
                    }
                }
                .chartLegend(position: .bottom, alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        legendDot(color: .blue.opacity(0.75),   label: "커밋")
                        legendDot(color: .orange.opacity(0.75), label: "포모도로")
                    }
                }
                .frame(height: 90)

                let weekCommits   = last7.reduce(0) { $0 + $1.commits }
                let weekPomodoros = last7.reduce(0) { $0 + $1.pomodoros }

                HStack(spacing: 4) {
                    summaryCell("🔥", "\(pet.streakDays)", "연속")
                    summaryCell("⚡", "\(weekCommits)",   "커밋/주")
                    summaryCell("🍅", "\(weekPomodoros)", "뽀모/주")
                }
            }
        }
    }

    private func shortLabel(_ ds: String) -> String {
        let parts = ds.split(separator: "-")
        guard parts.count == 3 else { return ds }
        return "\(Int(parts[1]) ?? 0)/\(Int(parts[2]) ?? 0)"
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 3) {
            RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 10, height: 8)
            Text(label).font(.system(size: 9)).foregroundStyle(.secondary)
        }
    }

    private func summaryCell(_ emoji: String, _ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(emoji).font(.system(size: 12))
            Text(value).font(.system(size: 11, weight: .bold))
            Text(label).font(.system(size: 8)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
    }
}

#Preview {
    let history = ActivityHistoryModel()
    let pet = PetModel()
    return StatsView(pet: pet, history: history)
        .padding()
        .frame(width: 220)
}
