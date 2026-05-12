import SwiftUI

struct TemplatesPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    let gameId: Int

    @State private var templates: [GameTemplateSummary] = []
    @State private var loading = true
    @State private var applying: String?
    @State private var error: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Adds a set of categories and missions to this game. Doesn't remove what's already there.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                if loading {
                    ProgressView()
                } else {
                    ForEach(templates) { t in
                        Section(t.title) {
                            Text(t.description).font(.footnote).foregroundStyle(.secondary)
                            HStack(spacing: 6) {
                                ForEach(t.categories, id: \.self) { c in
                                    HStack(spacing: 4) {
                                        Circle().fill(Color(hex: c.color ?? "#10B981")).frame(width: 8, height: 8)
                                        Text(c.name).font(.caption2)
                                    }
                                    .padding(.horizontal, 6).padding(.vertical, 3)
                                    .background(Color.secondary.opacity(0.08), in: Capsule())
                                }
                            }
                            Text("\(t.missionCount) missions").font(.caption).foregroundStyle(.secondary)
                            Button {
                                Task { await apply(t.slug) }
                            } label: {
                                HStack {
                                    if applying == t.slug { ProgressView() }
                                    Text(applying == t.slug ? "Adding…" : "Add to this game")
                                        .bold()
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(applying != nil)
                        }
                    }
                }
                if let error { Text(error).foregroundStyle(.red).font(.footnote) }
            }
            .navigationTitle("Start from a template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
            .task { await load() }
        }
    }

    private func load() async {
        loading = true
        defer { loading = false }
        do {
            templates = try await APIClient.shared.gameTemplates().templates
            error = nil
        } catch { self.error = error.userMessage }
    }

    private func apply(_ slug: String) async {
        applying = slug
        defer { applying = nil }
        error = nil
        do {
            _ = try await APIClient.shared.applyTemplate(gameId: gameId, slug: slug)
            await appState.refreshGames()
            dismiss()
        } catch { self.error = error.userMessage }
    }
}
