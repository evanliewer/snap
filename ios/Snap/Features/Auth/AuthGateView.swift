import SwiftUI

struct AuthGateView: View {
    @State private var mode: Mode = .login
    enum Mode { case login, signup }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [.accentColor.opacity(0.9), .purple.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                VStack(spacing: 24) {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "camera.aperture")
                            .font(.system(size: 56, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Snap")
                            .font(.system(size: 42, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Photo scavenger hunts for every crew.")
                            .font(.callout)
                            .foregroundStyle(.white.opacity(0.85))
                    }

                    Picker("Mode", selection: $mode) {
                        Text("Log in").tag(Mode.login)
                        Text("Sign up").tag(Mode.signup)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 32)
                    .colorScheme(.dark)

                    Group {
                        switch mode {
                        case .login: LoginView()
                        case .signup: SignupView()
                        }
                    }
                    .padding(20)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 24)

                    Spacer()
                    APIBaseURLView()
                }
                .padding(.vertical, 32)
            }
        }
    }
}

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 12) {
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .textFieldStyle(.roundedBorder)
            SecureField("Password", text: $password)
                .textContentType(.password)
                .textFieldStyle(.roundedBorder)
            if let err = appState.errorMessage {
                Text(err).font(.footnote).foregroundStyle(.red)
            }
            Button {
                Task {
                    isLoading = true
                    await appState.login(email: email, password: password)
                    isLoading = false
                }
            } label: {
                HStack {
                    if isLoading { ProgressView().tint(.white) }
                    Text("Log in").bold()
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(email.isEmpty || password.isEmpty || isLoading)
        }
    }
}

struct SignupView: View {
    @EnvironmentObject var appState: AppState
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 12) {
            TextField("Your name", text: $name)
                .textContentType(.name)
                .textFieldStyle(.roundedBorder)
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .textFieldStyle(.roundedBorder)
            SecureField("Password (min 8 chars)", text: $password)
                .textContentType(.newPassword)
                .textFieldStyle(.roundedBorder)
            if let err = appState.errorMessage {
                Text(err).font(.footnote).foregroundStyle(.red)
            }
            Button {
                Task {
                    isLoading = true
                    await appState.signup(name: name, email: email, password: password)
                    isLoading = false
                }
            } label: {
                HStack {
                    if isLoading { ProgressView().tint(.white) }
                    Text("Create account").bold()
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(name.isEmpty || email.isEmpty || password.count < 8 || isLoading)
        }
    }
}

struct APIBaseURLView: View {
    @State private var url: String = APIClient.shared.baseURL.absoluteString
    @State private var showing = false

    var body: some View {
        VStack {
            Button("API: \(url)") { showing = true }
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
        }
        .sheet(isPresented: $showing) {
            NavigationStack {
                Form {
                    Section("Backend base URL") {
                        TextField("https://…", text: $url)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                    }
                    Section {
                        Button("Save") {
                            APIClient.shared.setBaseURL(url)
                            showing = false
                        }
                    }
                }
                .navigationTitle("API settings")
            }
        }
    }
}
