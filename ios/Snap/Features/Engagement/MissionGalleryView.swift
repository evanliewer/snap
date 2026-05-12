import SwiftUI

struct MissionGalleryView: View {
    let mission: APIMission

    @State private var scope: Scope = .all
    @State private var submissions: [APISubmission] = []
    @State private var loading = true
    @State private var error: String?
    enum Scope: String, CaseIterable { case all = "All teams", team = "My team" }

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $scope) {
                ForEach(Scope.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding()
            .onChange(of: scope) { _, _ in Task { await load() } }

            if loading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if submissions.isEmpty {
                ContentUnavailableView("Nothing here yet", systemImage: "photo.stack",
                    description: Text(scope == .team ? "Your team hasn't submitted." : "No approved submissions yet."))
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], spacing: 8) {
                        ForEach($submissions) { $sub in
                            NavigationLink {
                                ActivityDetailView(submission: $sub)
                            } label: {
                                GalleryTile(submission: sub)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
        }
        .navigationTitle(mission.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        loading = true
        defer { loading = false }
        do {
            let res = try await APIClient.shared.missionSubmissions(missionId: mission.id, scope: scope == .team ? "team" : "all")
            submissions = res.submissions
            error = nil
        } catch { self.error = error.userMessage }
    }
}

struct GalleryTile: View {
    let submission: APISubmission
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let urlString = submission.photoUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img): img.resizable().scaledToFill()
                    default: Color.secondary.opacity(0.15)
                    }
                }
                .frame(height: 140)
                .clipped()
            }
            LinearGradient(colors: [.black.opacity(0.6), .clear], startPoint: .bottom, endPoint: .top).frame(height: 60).frame(maxHeight: .infinity, alignment: .bottom)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Circle().fill(Color(hex: submission.teamColor)).frame(width: 8, height: 8)
                    Text(submission.teamName).font(.caption2.bold())
                    if let total = submission.reactionTotal, total > 0 {
                        Spacer()
                        Image(systemName: "heart.fill").font(.caption2).foregroundStyle(.red)
                        Text("\(total)").font(.caption2)
                    }
                }
                .foregroundStyle(.white)
            }
            .padding(8)
        }
        .frame(height: 140)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

/// Reused detail view from activity card style.
struct ActivityDetailView: View {
    @Binding var submission: APISubmission
    @State private var showComments = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let urlString = submission.photoUrl, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img): img.resizable().scaledToFit()
                        default: Color.secondary.opacity(0.15).frame(height: 280)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                HStack(spacing: 8) {
                    Circle().fill(Color(hex: submission.teamColor)).frame(width: 10, height: 10)
                    Text(submission.teamName).font(.subheadline.bold())
                    Text("·").foregroundStyle(.secondary)
                    Text(submission.user.name).font(.subheadline).foregroundStyle(.secondary)
                    Spacer()
                    StatusPill(status: submission.status)
                }
                if let caption = submission.caption, !caption.isEmpty {
                    Text(caption).font(.body)
                }
                ReactionBar(submission: $submission)
                Button {
                    showComments = true
                } label: {
                    Label("\(submission.commentCount ?? 0) comments", systemImage: "bubble.left")
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .navigationTitle(submission.missionTitle)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showComments) {
            CommentsSheet(submission: submission, onCountChanged: { submission.commentCount = $0 })
        }
    }
}
