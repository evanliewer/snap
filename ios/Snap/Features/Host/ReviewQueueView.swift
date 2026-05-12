import SwiftUI

struct ReviewQueueView: View {
    let game: APIGame

    @State private var filter: Filter = .pending
    @State private var submissions: [APISubmission] = []
    @State private var loading = true
    @State private var error: String?
    @State private var workingIDs: Set<Int> = []
    @State private var editing: APISubmission?

    enum Filter: String, CaseIterable { case pending = "pending", approved = "approved", rejected = "rejected" }

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $filter) {
                ForEach(Filter.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 8)
            .onChange(of: filter) { _, _ in Task { await load() } }

            if loading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if submissions.isEmpty {
                ContentUnavailableView(
                    "Nothing \(filter.rawValue)",
                    systemImage: filter == .pending ? "tray" : "checkmark.seal",
                    description: Text(emptyMessage)
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(submissions) { sub in
                            ReviewCard(
                                submission: sub,
                                isBusy: workingIDs.contains(sub.id),
                                onApprove: { Task { await review(sub, status: "approved", points: sub.pointsAwarded > 0 ? sub.pointsAwarded : nil) } },
                                onReject:  { Task { await review(sub, status: "rejected", points: 0) } },
                                onDelete:  { Task { await delete(sub) } },
                                onCustomize: { editing = sub }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }
            }

            if let error {
                Text(error).font(.footnote).foregroundStyle(.red).padding(.horizontal)
            }
        }
        .task { await load() }
        .refreshable { await load() }
        .sheet(item: $editing, onDismiss: { Task { await load() } }) { sub in
            ReviewEditorView(submission: sub)
        }
    }

    private var emptyMessage: String {
        switch filter {
        case .pending:  return "All caught up. New submissions show up here as they come in."
        case .approved: return "No approved submissions yet."
        case .rejected: return "No rejected submissions."
        }
    }

    private func load() async {
        loading = true
        defer { loading = false }
        do {
            let res = try await APIClient.shared.submissions(gameId: game.id, status: filter.rawValue)
            submissions = res.submissions
            error = nil
        } catch { self.error = error.userMessage }
    }

    private func review(_ sub: APISubmission, status: String, points: Int?) async {
        workingIDs.insert(sub.id)
        defer { workingIDs.remove(sub.id) }
        do {
            _ = try await APIClient.shared.reviewSubmission(id: sub.id, status: status, pointsAwarded: points)
            await load()
        } catch { self.error = error.userMessage }
    }

    private func delete(_ sub: APISubmission) async {
        workingIDs.insert(sub.id)
        defer { workingIDs.remove(sub.id) }
        do {
            try await APIClient.shared.deleteSubmission(id: sub.id)
            await load()
        } catch { self.error = error.userMessage }
    }
}

struct ReviewCard: View {
    let submission: APISubmission
    let isBusy: Bool
    let onApprove: () -> Void
    let onReject: () -> Void
    let onDelete: () -> Void
    let onCustomize: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle().fill(Color(hex: submission.teamColor)).frame(width: 12, height: 12)
                Text(submission.teamName).font(.subheadline.bold())
                Text("·").foregroundStyle(.secondary)
                Text(submission.user.name).font(.subheadline).foregroundStyle(.secondary)
                Spacer()
                StatusPill(status: submission.status)
            }
            Text(submission.missionTitle).font(.headline)
            if let caption = submission.caption, !caption.isEmpty {
                Text(caption).font(.body).foregroundStyle(.secondary)
            }
            if let urlString = submission.photoUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty: ProgressView().frame(height: 220).frame(maxWidth: .infinity)
                    case .success(let img): img.resizable().scaledToFill().frame(maxWidth: .infinity, maxHeight: 320).clipped()
                    case .failure: Color.secondary.opacity(0.1).frame(height: 220).overlay(Image(systemName: "photo"))
                    @unknown default: EmptyView()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            HStack(spacing: 8) {
                if submission.status != "approved" {
                    Button { onApprove() } label: {
                        Label("Approve", systemImage: "checkmark").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .disabled(isBusy)
                }
                if submission.status != "rejected" {
                    Button { onReject() } label: {
                        Label("Reject", systemImage: "xmark").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .disabled(isBusy)
                }
                Menu {
                    Button { onCustomize() } label: { Label("Set custom points / note", systemImage: "slider.horizontal.3") }
                    Button(role: .destructive) { onDelete() } label: { Label("Delete submission", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .frame(width: 44, height: 36)
                        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
                }
                .disabled(isBusy)
            }

            HStack(spacing: 12) {
                Label("\(submission.pointsAwarded) pts", systemImage: "star.fill").font(.caption).foregroundStyle(.orange)
                if let createdAt = submission.createdAt {
                    Label(createdAt.formatted(.relative(presentation: .named)), systemImage: "clock").font(.caption).foregroundStyle(.secondary)
                }
            }
            if isBusy { ProgressView().padding(.top, 4) }
        }
        .padding(14)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct ReviewEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let submission: APISubmission

    @State private var status: String
    @State private var points: Int
    @State private var notes: String
    @State private var saving = false
    @State private var error: String?

    init(submission: APISubmission) {
        self.submission = submission
        _status = State(initialValue: submission.status)
        _points = State(initialValue: submission.pointsAwarded)
        _notes  = State(initialValue: "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Decision") {
                    Picker("Status", selection: $status) {
                        Text("Approved").tag("approved")
                        Text("Pending").tag("pending")
                        Text("Rejected").tag("rejected")
                    }
                }
                Section("Points") {
                    Stepper("Award: \(points)", value: $points, in: 0...10000, step: 25)
                }
                Section("Note (optional)") {
                    TextField("e.g. close enough — half credit", text: $notes, axis: .vertical).lineLimit(2...5)
                }
                if let error { Text(error).foregroundStyle(.red).font(.footnote) }
            }
            .navigationTitle("Review submission")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button { Task { await save() } } label: {
                        if saving { ProgressView() } else { Text("Save").bold() }
                    }
                    .disabled(saving)
                }
            }
        }
    }

    private func save() async {
        saving = true
        defer { saving = false }
        do {
            _ = try await APIClient.shared.reviewSubmission(
                id: submission.id,
                status: status,
                pointsAwarded: points,
                reviewNotes: notes.isEmpty ? nil : notes
            )
            dismiss()
        } catch { self.error = error.userMessage }
    }
}
