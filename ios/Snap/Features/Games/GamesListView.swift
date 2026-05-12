import SwiftUI

struct GamesListView: View {
    @EnvironmentObject var appState: AppState
    @State private var showJoinSheet = false
    @State private var showNewGameSheet = false

    var hostedGames: [APIGame] { appState.joinedGames.filter { ($0.role ?? "") == "admin" } }
    var playedGames: [APIGame] { appState.joinedGames.filter { ($0.role ?? "") != "admin" } }

    var body: some View {
        NavigationStack {
            List {
                if appState.joinedGames.isEmpty {
                    ContentUnavailableView {
                        Label("No games yet", systemImage: "gamecontroller")
                    } description: {
                        Text("Join a game with a code, or host your own.")
                    } actions: {
                        Button("Join game") { showJoinSheet = true }.buttonStyle(.borderedProminent)
                        Button("Host a new game") { showNewGameSheet = true }
                    }
                } else {
                    if !hostedGames.isEmpty {
                        Section("Hosting") {
                            ForEach(hostedGames) { game in
                                NavigationLink(value: game) { GameRow(game: game) }
                            }
                        }
                    }
                    if !playedGames.isEmpty {
                        Section(hostedGames.isEmpty ? "" : "Playing") {
                            ForEach(playedGames) { game in
                                NavigationLink(value: game) { GameRow(game: game) }
                            }
                        }
                    }
                }
            }
            .navigationTitle("My games")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button { showJoinSheet = true } label: { Label("Join with code", systemImage: "qrcode.viewfinder") }
                        Button { showNewGameSheet = true } label: { Label("Host a new game", systemImage: "plus.circle") }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .refreshable {
                await appState.refreshGames()
            }
            .navigationDestination(for: APIGame.self) { game in
                GameDetailView(game: game)
            }
            .sheet(isPresented: $showJoinSheet) { JoinGameView() }
            .sheet(isPresented: $showNewGameSheet) { NewGameView() }
        }
    }
}

struct GameRow: View {
    let game: APIGame
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(colors: [.accentColor, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                Image(systemName: "camera.fill").foregroundStyle(.white)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(game.title).font(.headline)
                HStack(spacing: 6) {
                    StatusPill(status: game.status)
                    Text(game.joinCode).font(.caption.monospaced()).foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct StatusPill: View {
    let status: String
    var body: some View {
        Text(status.uppercased())
            .font(.caption2.bold())
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(background, in: Capsule())
            .foregroundStyle(foreground)
    }
    private var background: Color {
        switch status {
        case "active": return .green.opacity(0.2)
        case "ended": return .gray.opacity(0.2)
        case "scheduled": return .blue.opacity(0.2)
        default: return .secondary.opacity(0.2)
        }
    }
    private var foreground: Color {
        switch status {
        case "active": return .green
        case "ended": return .secondary
        case "scheduled": return .blue
        default: return .secondary
        }
    }
}
