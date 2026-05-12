import SwiftUI

struct JoinGameView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var code: String
    @State private var isJoining = false
    @State private var error: String?
    @State private var showScanner = false

    init(prefilledCode: String? = nil) {
        _code = State(initialValue: prefilledCode ?? "")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 56))
                        .foregroundStyle(Color.accentColor)
                    Text("Join a game")
                        .font(.title2.bold())
                    Text("Scan your host's QR code, or type the join code.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button {
                    showScanner = true
                } label: {
                    Label("Scan QR code", systemImage: "qrcode.viewfinder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .padding(.horizontal)

                HStack {
                    Rectangle().fill(.secondary.opacity(0.3)).frame(height: 1)
                    Text("or").foregroundStyle(.secondary).font(.caption)
                    Rectangle().fill(.secondary.opacity(0.3)).frame(height: 1)
                }
                .padding(.horizontal, 32)

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
                    Task { await submit() }
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
            .padding(.top, 32)
            .navigationTitle("Join game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
            }
            .sheet(isPresented: $showScanner) {
                QRScannerSheet(onCode: { scanned in
                    code = scanned
                    showScanner = false
                    Task { await submit() }
                })
            }
            .task {
                if !code.isEmpty && appState.errorMessage == nil { await submit() }
            }
        }
    }

    private func submit() async {
        guard !isJoining else { return }
        isJoining = true
        error = nil
        if let _ = await appState.joinGame(code: code.uppercased()) {
            dismiss()
        } else {
            error = appState.errorMessage ?? "Could not join."
        }
        isJoining = false
    }
}

struct QRScannerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onCode: (String) -> Void
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ZStack {
                QRScannerView(
                    onScan: { raw in
                        let code: String
                        if let url = URL(string: raw), let extracted = SnapDeepLink.code(from: url) {
                            code = extracted
                        } else {
                            code = raw.uppercased()
                        }
                        onCode(code)
                    },
                    onError: { msg in error = msg }
                )
                .ignoresSafeArea()

                VStack {
                    Spacer()
                    if let error {
                        Text(error)
                            .font(.footnote)
                            .padding(8)
                            .background(.ultraThinMaterial, in: Capsule())
                            .padding(.bottom, 20)
                    } else {
                        Label("Point at a Snap join QR", systemImage: "viewfinder")
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(.ultraThinMaterial, in: Capsule())
                            .padding(.bottom, 20)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
