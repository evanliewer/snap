import SwiftUI

struct GameDetailView: View {
    let game: APIGame
    @State private var section: Section = .missions
    @State private var showAdmin = false
    enum Section: String, CaseIterable { case missions = "Missions", leaderboard = "Leaderboard", activity = "Activity", teams = "Teams" }

    var isAdmin: Bool { (game.role ?? "") == "admin" || (game.membership?.role ?? "") == "admin" }

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $section) {
                ForEach(Section.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding()

            switch section {
            case .missions:    MissionsListView(gameId: game.id)
            case .leaderboard: LeaderboardView(gameId: game.id)
            case .activity:    ActivityFeedView(gameId: game.id)
            case .teams:       TeamsView(game: game)
            }
        }
        .navigationTitle(game.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isAdmin {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdmin = true } label: { Image(systemName: "wrench.and.screwdriver") }
                }
            }
        }
        .sheet(isPresented: $showAdmin) { GameAdminView(game: game) }
    }
}
