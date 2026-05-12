import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            GamesListView()
                .tabItem { Label("Games", systemImage: "gamecontroller.fill") }
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    LabeledContent("Name", value: appState.currentUser?.name ?? "—")
                    LabeledContent("Email", value: appState.currentUser?.emailAddress ?? "—")
                }
                Section("Backend") {
                    Text(APIClient.shared.baseURL.absoluteString).font(.caption).foregroundStyle(.secondary)
                }
                Section {
                    Button(role: .destructive) {
                        Task { await appState.logout() }
                    } label: {
                        Label("Log out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}
