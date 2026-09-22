import SwiftUI
import SwiftData
import AppKit

struct PopoverView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<TimeEntry> { $0.end == nil })
    private var activeEntries: [TimeEntry]
    @Query(sort: \Project.createdAt, order: .reverse)
    private var projects: [Project]

    var body: some View {
        let tracker = TimeTracker(context: modelContext)
        VStack(alignment: .leading, spacing: 15) {
            HeaderView(tracker: tracker, activeEntry: activeEntries.first, projects: projects)
            Divider()
            HistoryListView(tracker: tracker, projects: projects, activeEntry: activeEntries.first)
            Divider()
            SummaryView(tracker: tracker, projects: projects)
            Divider()
            Button("Beenden") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.borderless)
        }
        .padding(18)
        .frame(width: 320)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }
}
