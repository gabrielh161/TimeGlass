import SwiftUI

/// Small settings sheet for the handful of preferences TimeGlass exposes (daily goal, menu
/// bar behaviour, sound, countdown mode, reminders).
struct SettingsView: View {
    @Bindable var settings: AppSettings
    let onDone: () -> Void

    @State private var dailyGoalText: String = ""
    @State private var forgotToStopText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Einstellungen").font(.headline)
                Spacer()
                Button("Fertig") { commitTextFields(); onDone() }
                    .buttonStyle(.borderless)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Tagesziel (Stunden)").font(.caption.weight(.bold)).foregroundStyle(.secondary)
                TextField("z.B. 8", text: $dailyGoalText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(commitTextFields)
            }

            Toggle("Restzeit statt vergangener Zeit anzeigen", isOn: $settings.showRemainingTime)
            Toggle("Kompaktmodus (nur Icon in der Menüleiste)", isOn: $settings.compactMode)
            Toggle("Countdown-Modus (gegen Projekt-Budget zählen)", isOn: $settings.countdownMode)
            Toggle("Sound bei Start/Stop", isOn: $settings.soundEnabled)
            Toggle("Morgen-Erinnerung, falls kein Timer läuft", isOn: $settings.morningReminderEnabled)
            Toggle("Projektvorschlag anhand aktiver App", isOn: $settings.frontmostAppSuggestionEnabled)

            VStack(alignment: .leading, spacing: 4) {
                Text("„Vergessen zu stoppen?“ nach (Stunden)").font(.caption.weight(.bold)).foregroundStyle(.secondary)
                TextField("z.B. 3", text: $forgotToStopText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(commitTextFields)
            }
        }
        .font(.callout)
        .padding(18)
        .frame(width: 300)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
        .onAppear {
            dailyGoalText = String(settings.dailyGoalHours)
            forgotToStopText = String(settings.forgotToStopHours)
        }
    }

    private func commitTextFields() {
        if let goal = Double(dailyGoalText.replacingOccurrences(of: ",", with: ".")), goal > 0 {
            settings.dailyGoalHours = goal
        }
        if let hours = Double(forgotToStopText.replacingOccurrences(of: ",", with: ".")), hours > 0 {
            settings.forgotToStopHours = hours
        }
    }
}
