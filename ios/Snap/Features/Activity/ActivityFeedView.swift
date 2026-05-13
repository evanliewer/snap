import SwiftUI

struct ActivityFeedView: View {
    let gameId: Int
    @State private var events: [APISubmission] = []
    @State private var loading = true
    @State private var error: String?
    @State private var liveConnected = false
    @State private var cable: CableClient<ActivityChannelMessage>?
    @State private var teamFilter: Int?
    @State private var statusFilter: String?

    private var teamOptions: [(id: Int, name: String, color: String)] {
        var seen: Set<Int> = []
        return events.compactMap { e in
            guard !seen.contains(e.teamId) else { return nil }
            seen.insert(e.teamId)
            return (e.teamId, e.teamName, e.teamColor)
        }
        .sorted { $0.name < $1.name }
    }

    private var filtered: [APISubmission] {
        events.filter { e in
            (teamFilter == nil || e.teamId == teamFilter!) &&
            (statusFilter == nil || e.status == statusFilter!)
        }
    }

    var body: some View {
        Group {
            if loading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if events.isEmpty {
                ContentUnavailableView("Nothing yet", systemImage: "sparkles", description: Text("Submissions will appear here."))
            } else {
                ScrollView {
                    HStack(spacing: 8) {
                        if liveConnected {
                            Label("Live", systemImage: "dot.radiowaves.left.and.right")
                                .font(.caption.bold())
                                .padding(.horizontal, 10).padding(.vertical, 4)
                                .background(.green.opacity(0.15), in: Capsule())
                                .foregroundStyle(.green)
                        }
                        Spacer()
                        Menu {
                            Section("Team") {
                                Button("All teams") { teamFilter = nil }
                                ForEach(teamOptions, id: \.id) { opt in
                                    Button(opt.name) { teamFilter = opt.id }
                                }
                            }
                            Section("Status") {
                                Button("Any status") { statusFilter = nil }
                                Button("Approved") { statusFilter = "approved" }
                                Button("Pending")  { statusFilter = "pending" }
                                Button("Rejected") { statusFilter = "rejected" }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "line.3.horizontal.decrease")
                                if teamFilter != nil || statusFilter != nil {
                                    Circle().fill(Color.accentColor).frame(width: 6, height: 6)
                                }
                            }
                            .font(.caption.bold())
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.1), in: Capsule())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)

                    LazyVStack(spacing: 16) {
                        ForEach(filtered) { event in
                            if let idx = events.firstIndex(where: { $0.id == event.id }) {
                                ActivityCard(event: $events[idx], gameId: gameId)
                            }
                        }
                        if filtered.isEmpty {
                            Text("No matching submissions.")
                                .font(.footnote).foregroundStyle(.secondary)
                                .padding(.vertical, 24)
                        }
                    }
                    .padding()
                    .animation(.spring(response: 0.35), value: filtered.map(\.id))
                }
            }
        }
        .task { await load() }
        .refreshable { await load() }
        .onAppear { connectCable() }
        .onDisappear { cable?.disconnect(); cable = nil; liveConnected = false }
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

    private func connectCable() {
        guard cable == nil, let token = APIClient.shared.token else { return }
        let client = CableClient<ActivityChannelMessage>(
            baseURL: APIClient.shared.baseURL,
            token: token,
            channel: "ActivityChannel",
            params: ["game_id": gameId]
        ) { msg in
            handle(message: msg)
        }
        cable = client
        client.connect()
        liveConnected = true
    }

    private func handle(message: ActivityChannelMessage) {
        switch message.type {
        case "submission.created":
            // Prepend if not already there
            if !events.contains(where: { $0.id == message.submission.id }) {
                events.insert(message.submission, at: 0)
            }
        case "submission.updated":
            if let idx = events.firstIndex(where: { $0.id == message.submission.id }) {
                events[idx] = message.submission
            } else {
                events.insert(message.submission, at: 0)
            }
        default:
            break
        }
    }
}

struct ActivityCard: View {
    @Binding var event: APISubmission
    let gameId: Int
    @State private var showComments = false
    @State private var showProfile = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle().fill(Color(hex: event.teamColor)).frame(width: 12, height: 12)
                Text(event.teamName).font(.subheadline.bold())
                Text("·").foregroundStyle(.secondary)
                Button { showProfile = true } label: {
                    Text(event.user.name).font(.subheadline).foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
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
            HStack {
                ReactionBar(submission: $event)
                Spacer()
                Button {
                    showComments = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left")
                        Text("\(event.commentCount ?? 0)").font(.caption)
                    }
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.08), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showComments) {
            CommentsSheet(submission: event, onCountChanged: { event.commentCount = $0 })
        }
        .sheet(isPresented: $showProfile) {
            PlayerProfileView(gameId: gameId, userId: event.user.id)
        }
    }
}
