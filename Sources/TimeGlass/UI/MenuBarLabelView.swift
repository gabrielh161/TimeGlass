import SwiftUI
import SwiftData

struct MenuBarLabelView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<TimeEntry> { $0.end == nil })
    private var activeEntries: [TimeEntry]
    @Query(sort: \Project.createdAt, order: .reverse)
    private var projects: [Project]
    @State private var settings = AppSettings.shared

    var body: some View {
        let tracker = TimeTracker(context: modelContext)
        let goalSeconds = settings.dailyGoalHours * 3600

        Group {
            if let entry = activeEntries.first, let project = entry.project {
                let tint = ProjectColor.color(for: project)
                TimelineView(.periodic(from: entry.start, by: 1)) { context in
                    let todaySeconds = tracker.totalSecondsAcrossProjects(projects, since: SummaryPeriod.today.startDate(), now: context.date)
                    let goalReached = goalSeconds > 0 && todaySeconds >= goalSeconds
                    let progress = goalSeconds > 0 ? min(todaySeconds / goalSeconds, 1) : 0
                    HStack(spacing: 4) {
                        goalRing(tint: goalReached ? .green : tint, progress: progress)
                        if !settings.compactMode {
                            Text(runningLabel(entry: entry, project: project, todaySeconds: todaySeconds, goalSeconds: goalSeconds, now: context.date))
                        }
                    }
                }
            } else {
                // Idle: icon-only regardless of compact mode, as before - there is no running
                // session to label. The ring still reflects today's goal progress / completion.
                let todaySeconds = tracker.totalSecondsAcrossProjects(projects, since: SummaryPeriod.today.startDate())
                let goalReached = goalSeconds > 0 && todaySeconds >= goalSeconds
                let progress = goalSeconds > 0 ? min(todaySeconds / goalSeconds, 1) : 0
                goalRing(tint: goalReached ? .green : .secondary, progress: progress)
            }
        }
    }

    private func runningLabel(entry: TimeEntry, project: Project, todaySeconds: TimeInterval, goalSeconds: Double, now: Date) -> String {
        if settings.showRemainingTime, goalSeconds > 0 {
            let remaining = max(goalSeconds - todaySeconds, 0)
            return "\(project.name) · noch \(DurationFormatting.format(remaining))"
        }
        let elapsed = now.timeIntervalSince(entry.start)
        return "\(project.name) · \(DurationFormatting.format(elapsed))"
    }

    /// Small ring baked into the menu bar icon: its color reflects the running project (or a
    /// neutral secondary tone when idle), it fills up as today's goal progress, and turns
    /// green once the daily goal is reached.
    private func goalRing(tint: Color, progress: Double) -> some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.28), lineWidth: 2)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(tint, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Circle()
                .fill(tint)
                .frame(width: 4, height: 4)
        }
        .frame(width: 13, height: 13)
    }
}
