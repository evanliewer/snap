import SwiftUI

struct CommentsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let submission: APISubmission
    var onCountChanged: ((Int) -> Void)? = nil

    @State private var comments: [APIComment] = []
    @State private var loading = true
    @State private var draft: String = ""
    @State private var sending = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if loading {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if comments.isEmpty {
                    ContentUnavailableView("No comments yet", systemImage: "bubble.left", description: Text("Be the first to say something."))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 10) {
                            ForEach(comments) { c in
                                CommentRow(comment: c, onDelete: { Task { await delete(c) } })
                            }
                        }
                        .padding()
                    }
                }
                Divider()
                HStack(spacing: 8) {
                    TextField("Add a comment…", text: $draft, axis: .vertical)
                        .lineLimit(1...4)
                        .textFieldStyle(.roundedBorder)
                    Button {
                        Task { await send() }
                    } label: {
                        if sending { ProgressView() } else { Image(systemName: "paperplane.fill") }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty || sending)
                }
                .padding(10)
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
            .task { await load() }
        }
    }

    private func load() async {
        loading = true
        defer { loading = false }
        do {
            comments = try await APIClient.shared.comments(submissionId: submission.id).comments
            onCountChanged?(comments.count)
        } catch { self.error = error.userMessage }
    }

    private func send() async {
        let body = draft.trimmingCharacters(in: .whitespaces)
        guard !body.isEmpty else { return }
        sending = true
        defer { sending = false }
        do {
            let c = try await APIClient.shared.addComment(submissionId: submission.id, body: body)
            comments.append(c)
            draft = ""
            onCountChanged?(comments.count)
        } catch { self.error = error.userMessage }
    }

    private func delete(_ c: APIComment) async {
        do {
            try await APIClient.shared.deleteComment(id: c.id)
            comments.removeAll { $0.id == c.id }
            onCountChanged?(comments.count)
        } catch { self.error = error.userMessage }
    }
}

struct CommentRow: View {
    let comment: APIComment
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(comment.user.name).font(.subheadline.bold())
                Spacer()
                if let date = comment.createdAt {
                    Text(date.formatted(.relative(presentation: .named))).font(.caption2).foregroundStyle(.secondary)
                }
            }
            Text(comment.body).font(.body)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
        .contextMenu {
            Button(role: .destructive) { onDelete() } label: { Label("Delete", systemImage: "trash") }
        }
    }
}
