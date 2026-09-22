import SwiftUI

struct HeaderView: View {
    let tracker: TimeTracker
    let activeEntry: TimeEntry?
    let projects: [Project]
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
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                PulsingDot()
                Text("Läuft")
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(.green)
            HStack {
                Text(projectName).font(.headline)
                Spacer()
                TimelineView(.periodic(from: entry.start, by: 1)) { context in
                    Text(DurationFormatting.format(context.date.timeIntervalSince(entry.start)))
                        .font(.system(.title2, design: .monospaced))
                        .monospacedDigit()
                }
            }
            Button("Stop") {
                tracker.stopActiveEntry()
            }
            .buttonStyle(.pill(tint: .red))
        }
    }

    private var idleView: some View {
        VStack(alignment: .leading, spacing: 10) {
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
