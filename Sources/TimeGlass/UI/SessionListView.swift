import SwiftUI

struct SessionListView: View {
    let tracker: TimeTracker
    let project: Project

    @State private var entries: [TimeEntry] = []
    @State private var showingAddForm = false
    @State private var newStart = Date()
    @State private var newEnd = Date()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(project.name).font(.headline)
                Spacer()
                Button("Fertig") { dismiss() }
                    .buttonStyle(.borderless)
            }

            if entries.isEmpty {
                Text("Keine Sitzungen in den letzten 7 Tagen.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(entries) { entry in
                        row(for: entry)
                    }
                }
            }

            Divider()

            if showingAddForm {
                addForm
            } else {
                Button {
                    newStart = Date()
                    newEnd = Date()
                    showingAddForm = true
                } label: {
                    Label("Sitzung hinzufügen", systemImage: "plus")
                }
                .buttonStyle(.pill)
            }
        }
        .padding(18)
        .frame(width: 320)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
        .onAppear(perform: reload)
    }

    private func reload() {
        let since = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        entries = tracker.entries(for: project, since: since)
    }

    @ViewBuilder
    private func row(for entry: TimeEntry) -> some View {
        HStack(spacing: 8) {
            DatePicker(
                "Start",
                selection: Binding(
                    get: { entry.start },
                    set: { newValue in
                        if tracker.updateEntry(entry, start: newValue, end: entry.end) {
                            reload()
                        }
                    }
                ),
                displayedComponents: [.date, .hourAndMinute]
            )
            .labelsHidden()

            if let end = entry.end {
                Text("–").foregroundStyle(.secondary)
                DatePicker(
                    "Ende",
                    selection: Binding(
                        get: { end },
                        set: { newValue in
                            if tracker.updateEntry(entry, start: entry.start, end: newValue) {
                                reload()
                            }
                        }
                    ),
                    displayedComponents: [.date, .hourAndMinute]
                )
                .labelsHidden()
            } else {
                PulsingDot()
                Text("läuft")
                    .foregroundStyle(.green)
            }

            Spacer()

            Button {
                tracker.deleteEntry(entry)
                reload()
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.borderless)
        }
        .font(.caption)
    }

    private var addForm: some View {
        VStack(alignment: .leading, spacing: 8) {
            DatePicker("Start", selection: $newStart, displayedComponents: [.date, .hourAndMinute])
            DatePicker("Ende", selection: $newEnd, displayedComponents: [.date, .hourAndMinute])
            HStack {
                Button("Abbrechen") { showingAddForm = false }
                    .buttonStyle(.borderless)
                Spacer()
                Button("Hinzufügen") {
                    if tracker.addManualEntry(to: project, start: newStart, end: newEnd) {
                        showingAddForm = false
                        reload()
                    }
                }
                .buttonStyle(.pill)
                .disabled(newEnd <= newStart)
            }
        }
        .font(.caption)
    }
}
