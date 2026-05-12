import SwiftUI

struct ActivityFeedView: View {
    let gameId: Int
    @State private var events: [APISubmission] = []
    @State private var loading = true
    @State private var error: String?

    var body: some View {
        Group {
            if loading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if events.isEmpty {
                ContentUnavailableView("Nothing yet", systemImage: "sparkles", description: Text("Submissions will appear here."))
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(events) { event in
                            ActivityCard(event: event)
                        }
                    }
                    .padding()
                }
            }
        }
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        loading = true
        do {
            let res = try await APIClient.shared.activity(gameId: gameId)
            events = res.events
            error = nil
        } catch {
            self.error = error.userMessage
        }
        loading = false
    }
}

struct ActivityCard: View {
    let event: APISubmission

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle().fill(Color(hex: event.teamColor)).frame(width: 12, height: 12)
                Text(event.teamName).font(.subheadline.bold())
                Text("·").foregroundStyle(.secondary)
                Text(event.user.name).font(.subheadline).foregroundStyle(.secondary)
                Spacer()
                Text("+\(event.pointsAwarded)").font(.subheadline.bold()).foregroundStyle(.orange)
            }
            if let url = event.photoUrl, let imageURL = URL(string: url) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty: ProgressView().frame(height: 240).frame(maxWidth: .infinity)
                    case .success(let img): img.resizable().scaledToFill().frame(maxWidth: .infinity, maxHeight: 320).clipped()
                    case .failure: Color.secondary.opacity(0.1).frame(height: 240).overlay(Image(systemName: "photo"))
                    @unknown default: EmptyView()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            Text(event.missionTitle).font(.headline)
            if let caption = event.caption, !caption.isEmpty {
                Text(caption).font(.body).foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
    }
}
