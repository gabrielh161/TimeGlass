import SwiftUI

/// Compact daily-goal progress ring + label shown in the popover, reusing the same "daily
/// goal" concept (AppSettings.dailyGoalHours) that drives the menu bar icon ring.
struct GoalProgressView: View {
    let tracker: TimeTracker
    let projects: [Project]
    let settings: AppSettings

    var body: some View {
        let goalSeconds = settings.dailyGoalHours * 3600
        TimelineView(.periodic(from: .now, by: 30)) { context in
            let todaySeconds = tracker.totalSecondsAcrossProjects(projects, since: SummaryPeriod.today.startDate(), now: context.date)
            let progress = goalSeconds > 0 ? min(todaySeconds / goalSeconds, 1) : 0
            let reached = goalSeconds > 0 && todaySeconds >= goalSeconds
            HStack(spacing: 10) {
                ZStack {
                    Circle().stroke(.secondary.opacity(0.25), lineWidth: 3)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(reached ? Color.green : Color.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 22, height: 22)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Tagesziel")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                    Text("\(DurationFormatting.format(todaySeconds)) von \(DurationFormatting.formatHours(settings.dailyGoalHours))")
                        .font(.caption)
                        .foregroundStyle(reached ? .green : .primary)
                }
                Spacer()
            }
        }
    }
}
