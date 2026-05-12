import SwiftUI

struct JoinGameView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var code = ""
    @State private var isJoining = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 56))
                        .foregroundStyle(Color.accentColor)
                    Text("Join a game")
                        .font(.title2.bold())
                    Text("Enter the code your host shared.")
                        .foregroundStyle(.secondary)
                }
                TextField("ABC123", text: $code)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(.system(.title, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .padding(16)
                    .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)

                if let error { Text(error).foregroundStyle(.red).font(.footnote) }

                Button {
                    Task {
                        isJoining = true
                        error = nil
                        if let game = await appState.joinGame(code: code.uppercased()) {
                            dismiss()
                            print("Joined \(game.title)")
                        } else {
                            error = appState.errorMessage ?? "Could not join."
                        }
                        isJoining = false
                    }
                } label: {
                    HStack {
                        if isJoining { ProgressView().tint(.white) }
                        Text("Join").bold()
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(code.count < 4 || isJoining)
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 40)
            .navigationTitle("Join game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
            }
        }
    }
}
