import SwiftUI

struct MissionsListView: View {
    let gameId: Int
    @State private var missions: [APIMission] = []
    @State private var categories: [MissionCategory] = []
    @State private var loading = true
    @State private var error: String?

    var body: some View {
        Group {
            if loading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error {
                ContentUnavailableView("Couldn't load missions", systemImage: "exclamationmark.triangle", description: Text(error))
            } else if missions.isEmpty {
                ContentUnavailableView("No missions yet", systemImage: "list.bullet")
            } else {
                List {
                    ForEach(groupedSections, id: \.title) { section in
                        SwiftUI.Section {
                            ForEach(section.missions) { m in
                                NavigationLink {
                                    MissionDetailView(mission: m) { updated in
                                        if let idx = missions.firstIndex(where: { $0.id == updated.id }) {
                                            missions[idx] = updated
                                        }
                                    }
                                } label: {
                                    MissionRow(mission: m)
                                }
                            }
                        } header: {
                            HStack {
                                if let color = section.color {
                                    Circle().fill(Color(hex: color)).frame(width: 10, height: 10)
                                }
                                Text(section.title)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .task { await load() }
        .refreshable { await load() }
    }

    private var groupedSections: [(title: String, color: String?, missions: [APIMission])] {
        let byCategory = Dictionary(grouping: missions) { $0.categoryId ?? -1 }
        var sections: [(String, String?, [APIMission])] = []
        for cat in categories {
            if let items = byCategory[cat.id], !items.isEmpty {
                sections.append((cat.name, cat.color, items.sorted { $0.position < $1.position }))
            }
        }
        if let uncategorized = byCategory[-1], !uncategorized.isEmpty {
            sections.append(("Other missions", nil, uncategorized.sorted { $0.position < $1.position }))
        }
        return sections
    }

    private func load() async {
        loading = true
        do {
            let res = try await APIClient.shared.missions(gameId: gameId)
            missions = res.missions
            categories = res.categories
            error = nil
        } catch {
            self.error = error.userMessage
        }
        loading = false
    }
}

struct MissionRow: View {
    let mission: APIMission
    var body: some View {
        HStack {
            Image(systemName: mission.completedByTeam ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(mission.completedByTeam ? .green : .secondary)
                .imageScale(.large)
            VStack(alignment: .leading, spacing: 4) {
                Text(mission.title).font(.headline)
                HStack(spacing: 6) {
                    Label("\(mission.points) pts", systemImage: "star.fill").font(.caption).foregroundStyle(.orange)
                    Text(mission.missionType.uppercased()).font(.caption2).padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.15), in: Capsule())
                    if mission.requiresLocation {
                        Image(systemName: "location.fill").font(.caption2).foregroundStyle(.blue)
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

extension Color {
    init(hex: String) {
        var hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hex.hasPrefix("#") { hex.removeFirst() }
        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)
        self = Color(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}
