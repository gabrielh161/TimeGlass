import SwiftUI

/// Small sheet to edit the extended attributes of a project: client, hourly rate,
/// tags and a budget in hours. Reachable from the session list.
struct ProjectEditSheet: View {
    let tracker: TimeTracker
    let project: Project

    @State private var clientName: String = ""
    @State private var hourlyRateText: String = ""
    @State private var tagsText: String = ""
    @State private var budgetHoursText: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(ProjectColor.color(for: project))
                    .frame(width: 10, height: 10)
                Text(project.name).font(.headline)
                Spacer()
                Button("Fertig") { save(); dismiss() }
                    .buttonStyle(.borderless)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Kunde").font(.caption.weight(.bold)).foregroundStyle(.secondary)
                TextField("Kein Kunde", text: $clientName)
                    .textFieldStyle(.roundedBorder)
                if !tracker.allClients().isEmpty {
                    HStack(spacing: 6) {
                        ForEach(tracker.allClients(), id: \.persistentModelID) { client in
                            Button(client.name) { clientName = client.name }
                                .buttonStyle(.borderless)
                                .font(.caption2)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Stundensatz (€)").font(.caption.weight(.bold)).foregroundStyle(.secondary)
                TextField("z.B. 45", text: $hourlyRateText)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Tags (kommagetrennt)").font(.caption.weight(.bold)).foregroundStyle(.secondary)
                TextField("z.B. Kundenarbeit, Admin", text: $tagsText)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Budget (Stunden)").font(.caption.weight(.bold)).foregroundStyle(.secondary)
                TextField("z.B. 20", text: $budgetHoursText)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .padding(18)
        .frame(width: 300)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
        .onAppear {
            clientName = project.client?.name ?? ""
            hourlyRateText = project.hourlyRate.map { String($0) } ?? ""
            tagsText = project.tags.joined(separator: ", ")
            budgetHoursText = project.budgetHours.map { String($0) } ?? ""
        }
    }

    private func save() {
        tracker.setClient(for: project, named: clientName)
        let rate = Double(hourlyRateText.replacingOccurrences(of: ",", with: "."))
        let budget = Double(budgetHoursText.replacingOccurrences(of: ",", with: "."))
        let tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        tracker.updateProjectAttributes(project, hourlyRate: rate, tags: tags, budgetHours: budget)
    }
}
