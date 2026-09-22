import SwiftUI

struct HeaderView: View {
    let tracker: TimeTracker
    let activeEntry: TimeEntry?
    @State private var projectName: String = ""

    var body: some View {
        if let entry = activeEntry, let project = entry.project {
            runningView(entry: entry, projectName: project.name)
        } else {
            idleView
        }
    }

    private func runningView(entry: TimeEntry, projectName: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Läuft", systemImage: "circle.fill")
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
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
    }

    private var idleView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Neues Projekt")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            HStack {
                TextField("Projekt eingeben…", text: $projectName)
                    .textFieldStyle(.roundedBorder)
                Button("Start") {
                    tracker.start(projectNamed: projectName)
                    projectName = ""
                }
                .buttonStyle(.borderedProminent)
                .disabled(projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}
