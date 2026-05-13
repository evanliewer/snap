import SwiftUI

struct LeaderboardView: View {
    let gameId: Int
    @State private var teams: [LeaderboardResponse.LeaderboardTeam] = []
    @State private var totalMissions: Int = 0
    @State private var loading = true
    @State private var error: String?

    var body: some View {
        Group {
            if loading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if teams.isEmpty {
                ContentUnavailableView("No teams yet", systemImage: "person.3", description: error.map { Text($0) } ?? Text("Teams appear as players join."))
            } else {
                List {
                    ForEach(Array(teams.enumerated()), id: \.element.id) { idx, team in
                        VStack(spacing: 6) {
                            HStack {
                                Text("\(idx + 1)")
                                    .font(.system(.title3, design: .rounded).bold())
                                    .frame(width: 32)
                                    .foregroundStyle(idx == 0 ? .orange : .secondary)
                                Circle().fill(Color(hex: team.color)).frame(width: 18, height: 18)
                                VStack(alignment: .leading) {
                                    Text(team.name).font(.headline)
                                    Text("\(team.submissions) submissions · \(team.missionsCompleted ?? 0)/\(totalMissions) missions")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(team.points)")
                                    .font(.system(.title2, design: .rounded).bold())
                                    .foregroundStyle(Color.accentColor)
                                    .contentTransition(.numericText(value: Double(team.points)))
                            }
                            if let pct = team.completionPct, totalMissions > 0 {
                                ProgressView(value: Double(pct), total: 100)
                                    .tint(Color(hex: team.color))
                            }
                        }
                        .padding(.vertical, 6)
                        .id(team.id)
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: teams.map(\.id))
            }
        }
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        loading = true
        do {
            let res = try await APIClient.shared.leaderboard(gameId: gameId)
            teams = res.teams
            totalMissions = res.totalMissions ?? 0
            error = nil
        } catch {
            self.error = error.userMessage
        }
        loading = false
    }
}
