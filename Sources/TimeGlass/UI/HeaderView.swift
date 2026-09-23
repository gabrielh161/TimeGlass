import SwiftUI

struct HeaderView: View {
    let tracker: TimeTracker
    let activeEntry: TimeEntry?
    let projects: [Project]
    let settings: AppSettings
    @State private var projectName: String = ""

    var body: some View {
        Group {
            if let entry = activeEntry, let project = entry.project {
                runningView(entry: entry, projectName: project.name)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                idleView
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: activeEntry?.id)
    }

    private func runningView(entry: TimeEntry, projectName: String) -> some View {
        let project = entry.project
        let tint = project.map { ProjectColor.color(for: $0) } ?? .accentColor
        let countdownBudget = (settings.countdownMode ? project?.budgetHours : nil)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                PulsingDot()
                Text("Läuft")
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(.green)
            HStack {
                Circle()
                    .fill(tint)
                    .frame(width: 10, height: 10)
                Text(projectName).font(.headline)
                Spacer()
                if let project, let budget = countdownBudget {
                    TimelineView(.periodic(from: entry.start, by: 1)) { context in
                        let remaining = budget * 3600 - tracker.totalSeconds(for: project, since: .distantPast, now: context.date)
                        Text(remaining > 0 ? DurationFormatting.format(remaining) : "Budget voll")
                            .font(.system(.title2, design: .monospaced))
                            .monospacedDigit()
                            .foregroundStyle(remaining > 0 ? tint : .red)
                    }
                } else {
                    EditableElapsedTimeText(start: entry.start, tint: tint) { newStart in
                        tracker.updateEntry(entry, start: newStart, end: nil)
                    }
                    .foregroundStyle(tint)
                }
            }
            HStack(spacing: 8) {
                Button {
                    tracker.pause()
                } label: {
                    Label("Pause", systemImage: "pause.fill")
                }
                .buttonStyle(.pill(tint: .orange))
                Button("Stop") {
                    tracker.stopActiveEntry()
                }
                .buttonStyle(.pill(tint: .red))
            }
        }
    }

    private var idleView: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let last = tracker.mostRecentProject(), last.name != projectName {
                Button {
                    tracker.restart(last)
                } label: {
                    Label("Fortsetzen: \(last.name)", systemImage: "play.fill")
                }
                .buttonStyle(.pill(tint: ProjectColor.color(for: last)))
            }
            Text("Neues Projekt")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            HStack {
                TextField("Projekt eingeben…", text: $projectName)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        guard !projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                        tracker.start(projectNamed: projectName)
                        projectName = ""
                    }
                Button("Start") {
                    tracker.start(projectNamed: projectName)
                    projectName = ""
                }
                .buttonStyle(.pill)
                .disabled(projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            if !suggestions.isEmpty {
                HStack(spacing: 6) {
                    ForEach(suggestions) { project in
                        Button(project.name) {
                            projectName = project.name
                        }
                        .buttonStyle(.borderless)
                        .font(.caption)
                    }
                }
            }
        }
    }

    private var suggestions: [Project] {
        let trimmed = projectName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return Array(
            projects
                .filter {
                    $0.name.localizedCaseInsensitiveContains(trimmed)
                        && $0.name.localizedCaseInsensitiveCompare(trimmed) != .orderedSame
                }
                .prefix(3)
        )
    }
}
