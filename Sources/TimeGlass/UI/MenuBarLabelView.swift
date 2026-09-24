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
                        icon(tint: goalReached ? .green : tint, progress: progress, filled: true)
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
                icon(tint: goalReached ? .green : .primary, progress: progress, filled: false)
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

    /// Menu bar icon: always a fully opaque SF Symbol as the base (so there is never a blank/
    /// invisible icon), tinted by project color while running or neutral while idle. The goal
    /// progress ring is layered on top only once there is real progress to show (>0), so it
    /// can never be the *only* thing drawn - a fully transparent ring at 0% progress used to be
    /// the entire icon and was invisible in the menu bar.
    private func icon(tint: Color, progress: Double, filled: Bool) -> some View {
        ZStack {
            Image(systemName: filled ? "timer.circle.fill" : "timer")
                .font(.system(size: filled ? 15 : 13, weight: .medium))
                .foregroundStyle(tint)
            if progress > 0 {
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(tint, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 18, height: 18)
            }
        }
        .frame(width: 18, height: 18)
    }
}
