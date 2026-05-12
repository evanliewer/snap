import SwiftUI

struct NewGameView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var input = GameInput.empty()
    @State private var setSchedule = false
    @State private var startsAt = Date()
    @State private var endsAt = Date().addingTimeInterval(60 * 60 * 24)
    @State private var saving = false
    @State private var error: String?

    var onCreated: ((APIGame) -> Void)?

    var body: some View {
        NavigationStack {
            Form {
                Section("Game") {
                    TextField("Title", text: $input.title)
                    TextField("Description (optional)", text: Binding(get: { input.description ?? "" }, set: { input.description = $0.isEmpty ? nil : $0 }), axis: .vertical)
                        .lineLimit(2...4)
                }
                Section("Schedule") {
                    Toggle("Set schedule", isOn: $setSchedule)
                    if setSchedule {
                        DatePicker("Starts at", selection: $startsAt)
                        DatePicker("Ends at", selection: $endsAt)
                    }
                }
                Section("Settings") {
                    Toggle("Allow video submissions", isOn: $input.allowVideo)
                    Toggle("Show leaderboard to players", isOn: $input.showLeaderboard)
                    Toggle("Auto-approve submissions", isOn: $input.autoApprove)
                }
                if let error {
                    Section { Text(error).foregroundStyle(.red).font(.footnote) }
                }
            }
            .navigationTitle("New game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await save() }
                    } label: {
                        if saving { ProgressView() } else { Text("Create").bold() }
                    }
                    .disabled(input.title.isEmpty || saving)
                }
            }
        }
    }

    private func save() async {
        saving = true
        defer { saving = false }
        error = nil
        if setSchedule {
            input.startsAt = startsAt
            input.endsAt = endsAt
        } else {
            input.startsAt = nil
            input.endsAt = nil
        }
        do {
            let game = try await APIClient.shared.createGame(input: input)
            await appState.refreshGames()
            onCreated?(game)
            dismiss()
        } catch {
            self.error = error.userMessage
        }
    }
}
