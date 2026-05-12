import SwiftUI

struct PlayerProfileView: View {
    let gameId: Int
    let userId: Int

    @State private var profile: PlayerProfile?
    @State private var loading = true
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                if loading {
                    ProgressView().padding(.top, 40)
                } else if let profile {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [Color(hex: profile.team?.color ?? "#4F46E5"), .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 96, height: 96)
                            Text(String(profile.user.name.first ?? Character("?"))).font(.system(size: 40, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                        }
                        Text(profile.user.name).font(.title2.bold())
                        if let team = profile.team {
                            Label(team.name, systemImage: "person.2.fill")
                                .padding(.horizontal, 10).padding(.vertical, 4)
                                .background(Color(hex: team.color).opacity(0.2), in: Capsule())
                                .foregroundStyle(Color(hex: team.color))
                        }
                        HStack(spacing: 24) {
                            stat("Points", value: "\(profile.totalPoints)")
                            stat("Submissions", value: "\(profile.submissionCount)")
                        }
                        Divider().padding(.vertical, 8)
                        if profile.submissions.isEmpty {
                            ContentUnavailableView("No submissions yet", systemImage: "tray")
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 6)], spacing: 6) {
                                ForEach(profile.submissions) { sub in
                                    if let urlString = sub.photoUrl, let url = URL(string: urlString) {
                                        AsyncImage(url: url) { phase in
                                            switch phase {
                                            case .success(let img): img.resizable().scaledToFill()
                                            default: Color.secondary.opacity(0.15)
                                            }
                                        }
                                        .frame(height: 110)
                                        .clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    } else {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.secondary.opacity(0.15))
                                            .frame(height: 110)
                                            .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                } else if let error {
                    ContentUnavailableView("Couldn't load profile", systemImage: "exclamationmark.triangle", description: Text(error))
                }
            }
            .navigationTitle("Player")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task { await load() }
    }

    private func stat(_ label: String, value: String) -> some View {
        VStack {
            Text(value).font(.system(.title2, design: .rounded).bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }

    private func load() async {
        loading = true
        defer { loading = false }
        do { profile = try await APIClient.shared.playerProfile(gameId: gameId, userId: userId) }
        catch { self.error = error.userMessage }
    }
}
