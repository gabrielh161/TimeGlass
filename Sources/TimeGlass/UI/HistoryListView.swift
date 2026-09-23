import SwiftUI
import SwiftData

struct HistoryListView: View {
    let tracker: TimeTracker
    let projects: [Project]
    let activeEntry: TimeEntry?
    @State private var pendingDeleteID: PersistentIdentifier?
    @State private var sessionsProject: Project?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Verlauf")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            ForEach(projects) { project in
                row(for: project)
            }
        }
        .sheet(item: $sessionsProject) { project in
            SessionListView(tracker: tracker, project: project)
        }
    }

    @ViewBuilder
    private func row(for project: Project) -> some View {
        let isActive = activeEntry?.project?.id == project.id
        HStack {
            Circle()
                .fill(ProjectColor.color(for: project))
                .frame(width: 8, height: 8)
            Text(project.name)
                .lineLimit(1)
                .contentShape(Rectangle())
                .onTapGesture { sessionsProject = project }
            if notTouchedThisWeek(project) {
                Image(systemName: "moon.zzz")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .help("Diese Woche noch nicht bearbeitet")
            }
            Spacer()
            Group {
                if isActive, let entry = activeEntry {
                    TimelineView(.periodic(from: entry.start, by: 1)) { context in
                        Text(DurationFormatting.format(tracker.totalSeconds(for: project, since: SummaryPeriod.today.startDate(), now: context.date)))
                    }
                } else {
                    Text(DurationFormatting.format(tracker.totalSeconds(for: project, since: SummaryPeriod.today.startDate())))
                }
            }
            .monospacedDigit()
            .foregroundStyle(.secondary)
            .contentShape(Rectangle())
            .onTapGesture(count: 2) { sessionsProject = project }

            if pendingDeleteID == project.id {
                Button("Abbrechen") { pendingDeleteID = nil }
                    .buttonStyle(.borderless)
                Button(role: .destructive) {
                    tracker.delete(project)
                    pendingDeleteID = nil
                } label: {
                    Image(systemName: "checkmark")
                }
                .buttonStyle(.borderless)
            } else if isActive {
                PulsingDot(size: 6)
                Button {
                    pendingDeleteID = project.id
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.borderless)
            } else {
                Button {
                    tracker.restart(project)
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
                .buttonStyle(.borderless)
                Button {
                    pendingDeleteID = project.id
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.borderless)
            }
        }
    }

    /// True if the project has tracked history at all, but none of it falls within the
    /// current calendar week - i.e. it's been idle, not merely brand new.
    private func notTouchedThisWeek(_ project: Project) -> Bool {
        guard !project.entries.isEmpty else { return false }
        let weekStart = SummaryPeriod.week.startDate()
        return !project.entries.contains { $0.start >= weekStart }
    }
}
