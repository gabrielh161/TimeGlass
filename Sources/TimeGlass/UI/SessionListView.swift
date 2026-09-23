import SwiftUI

struct SessionListView: View {
    let tracker: TimeTracker
    let project: Project

    @State private var entries: [TimeEntry] = []
    @State private var showingAddForm = false
    @State private var showingEditSheet = false
    @State private var newStart = Date()
    @State private var newEnd = Date()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(ProjectColor.color(for: project))
                    .frame(width: 10, height: 10)
                Text(project.name).font(.headline)
                Spacer()
                Button {
                    showingEditSheet = true
                } label: {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.borderless)
                Button("Fertig") { dismiss() }
                    .buttonStyle(.borderless)
            }

            if let budget = project.budgetHours {
                let trackedHours = tracker.totalSeconds(for: project, since: .distantPast) / 3600
                if trackedHours > budget {
                    Label("Budget von \(DurationFormatting.formatHours(budget)) überschritten (\(DurationFormatting.formatHours(trackedHours)) getrackt)", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }

            if entries.isEmpty {
                Text("Keine Sitzungen in den letzten 7 Tagen.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Doppelklick auf eine Zeit, um sie zu ändern.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
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
        .sheet(isPresented: $showingEditSheet) {
            ProjectEditSheet(tracker: tracker, project: project)
        }
    }

    private func reload() {
        let since = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        entries = tracker.entries(for: project, since: since)
    }

    @ViewBuilder
    private func row(for entry: TimeEntry) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 8) {
                EditableTimeText(value: entry.start, tint: ProjectColor.color(for: project)) { newValue in
                    if tracker.updateEntry(entry, start: newValue, end: entry.end) {
                        reload()
                    }
                }

                if let end = entry.end {
                    Text("–").foregroundStyle(.secondary)
                    EditableTimeText(value: end, tint: ProjectColor.color(for: project)) { newValue in
                        if tracker.updateEntry(entry, start: entry.start, end: newValue) {
                            reload()
                        }
                    }
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

            EditableNoteText(note: entry.note, tint: ProjectColor.color(for: project)) { newNote in
                tracker.updateNote(entry, note: newNote)
                reload()
            }
            .padding(.leading, 2)
        }
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
