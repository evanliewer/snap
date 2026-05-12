import SwiftUI

struct ReactionBar: View {
    @Binding var submission: APISubmission
    var onChange: ((APISubmission) -> Void)? = nil

    private let kinds: [(kind: String, emoji: String)] = [
        ("heart", "❤️"),
        ("laugh", "😂"),
        ("wow", "😮"),
        ("fire", "🔥"),
        ("clap", "👏")
    ]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(kinds, id: \.kind) { item in
                let mine = submission.myReactions?.contains(item.kind) ?? false
                let count = submission.reactionCounts?[item.kind] ?? 0
                Button {
                    Task { await toggle(item.kind) }
                } label: {
                    HStack(spacing: 4) {
                        Text(item.emoji).font(.system(size: 16))
                        if count > 0 { Text("\(count)").font(.caption.bold()).foregroundStyle(mine ? Color.accentColor : .secondary) }
                    }
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(mine ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.08), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func toggle(_ kind: String) async {
        let mineNow = submission.myReactions?.contains(kind) ?? false
        do {
            let payload: ReactionsPayload
            if mineNow {
                payload = try await APIClient.shared.removeReaction(submissionId: submission.id, kind: kind)
            } else {
                payload = try await APIClient.shared.addReaction(submissionId: submission.id, kind: kind)
            }
            submission.reactionCounts = payload.counts
            submission.reactionTotal = payload.counts.values.reduce(0, +)
            submission.myReactions = payload.mine
            onChange?(submission)
        } catch {
            print("[ReactionBar] toggle failed: \(error)")
        }
    }
}
