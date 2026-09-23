import SwiftUI
import SwiftData
import AppKit

struct PopoverView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<TimeEntry> { $0.end == nil })
    private var activeEntries: [TimeEntry]
    @Query(sort: \Project.createdAt, order: .reverse)
    private var projects: [Project]
    @State private var settings = AppSettings.shared
    @State private var showingSettings = false
    @State private var showingInsights = false

    var body: some View {
        let tracker = TimeTracker(context: modelContext)
        VStack(alignment: .leading, spacing: 15) {
            HeaderView(tracker: tracker, activeEntry: activeEntries.first, projects: projects, settings: settings)
            Divider()
            GoalProgressView(tracker: tracker, projects: projects, settings: settings)
            Divider()
            HistoryListView(tracker: tracker, projects: projects, activeEntry: activeEntries.first)
            Divider()
            SummaryView(tracker: tracker, projects: projects)
            Divider()
            HStack {
                Button("Beenden") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.borderless)
                Spacer()
                Button {
                    showingInsights = true
                } label: {
                    Image(systemName: "chart.bar.xaxis")
                }
                .buttonStyle(.borderless)
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(18)
        .frame(width: 320)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
        .sheet(isPresented: $showingSettings) {
            SettingsView(settings: settings)
        }
        .sheet(isPresented: $showingInsights) {
            InsightsView(tracker: tracker, projects: projects)
        }
    }
}
