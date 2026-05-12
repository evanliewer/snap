import SwiftUI

struct TeamsView: View {
    let game: APIGame
    @EnvironmentObject var appState: AppState
    @State private var teams: [APITeam] = []
    @State private var loading = true
    @State private var joining: Int?
    @State private var error: String?

    var body: some View {
        Group {
            if loading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if teams.isEmpty {
                ContentUnavailableView("No teams yet", systemImage: "person.2", description: Text("Your host will add teams."))
            } else {
                List {
                    ForEach(teams) { team in
                        HStack {
                            Circle().fill(Color(hex: team.color)).frame(width: 16, height: 16)
                            VStack(alignment: .leading) {
                                Text(team.name).font(.headline)
                                Text("\(team.memberCount) players · \(team.points) pts").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if currentTeamId == team.id {
                                Label("Your team", systemImage: "checkmark").font(.caption).foregroundStyle(.green)
                            } else {
                                Button {
                                    Task { await join(team) }
                                } label: {
                                    if joining == team.id { ProgressView() } else { Text("Join").bold() }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .task { await load() }
        .refreshable { await load() }
    }

    private var currentTeamId: Int? {
        appState.joinedGames.first(where: { $0.id == game.id })?.membership?.teamId ?? appState.joinedGames.first(where: { $0.id == game.id })?.teamId
    }

    private func load() async {
        loading = true
        do {
            let res = try await APIClient.shared.teams(gameId: game.id)
            teams = res.teams
            error = nil
        } catch {
            self.error = error.userMessage
        }
        loading = false
    }

    private func join(_ team: APITeam) async {
        joining = team.id
        do {
            _ = try await APIClient.shared.joinTeam(gameId: game.id, teamId: team.id)
            await appState.refreshGames()
            await load()
        } catch {
            self.error = error.userMessage
        }
        joining = nil
    }
}
