import SwiftUI
import PhotosUI

struct GameAdminView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let game: APIGame
    @State private var section: Section = .teams
    enum Section: String, CaseIterable { case teams = "Teams", categories = "Categories", missions = "Missions", review = "Review", settings = "Settings" }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $section) {
                    ForEach(Section.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding()

                switch section {
                case .teams:      TeamsAdminView(gameId: game.id)
                case .categories: CategoriesAdminView(gameId: game.id)
                case .missions:   MissionsAdminView(game: game)
                case .review:     ReviewQueueView(game: game)
                case .settings:   GameSettingsAdminView(game: game) { dismiss() }
                }
            }
            .navigationTitle("Admin: \(game.title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}

// MARK: - Teams admin

struct TeamsAdminView: View {
    let gameId: Int
    @State private var teams: [APITeam] = []
    @State private var loading = true
    @State private var error: String?
    @State private var editing: APITeam?
    @State private var creating = false

    var body: some View {
        List {
            if loading {
                ProgressView()
            } else if teams.isEmpty {
                ContentUnavailableView("No teams yet", systemImage: "person.2", description: Text("Add a team so players can compete."))
            } else {
                ForEach(teams) { team in
                    Button {
                        editing = team
                    } label: {
                        HStack {
                            Circle().fill(Color(hex: team.color)).frame(width: 18, height: 18)
                            VStack(alignment: .leading) {
                                Text(team.name).foregroundStyle(.primary).fontWeight(.medium)
                                Text("\(team.memberCount) players · \(team.points) pts").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            Task { await delete(team) }
                        } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
            if let error { Text(error).foregroundStyle(.red).font(.footnote) }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { creating = true } label: { Image(systemName: "plus") }
            }
        }
        .task { await load() }
        .refreshable { await load() }
        .sheet(isPresented: $creating, onDismiss: { Task { await load() } }) {
            TeamEditorView(gameId: gameId, team: nil)
        }
        .sheet(item: $editing, onDismiss: { Task { await load() } }) { t in
            TeamEditorView(gameId: gameId, team: t)
        }
    }

    private func load() async {
        loading = true
        do {
            teams = try await APIClient.shared.teams(gameId: gameId).teams
            error = nil
        } catch { self.error = error.userMessage }
        loading = false
    }

    private func delete(_ team: APITeam) async {
        do { try await APIClient.shared.deleteTeam(gameId: gameId, teamId: team.id); await load() }
        catch { self.error = error.userMessage }
    }
}

struct TeamEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let gameId: Int
    let team: APITeam?

    @State private var input: TeamInput
    @State private var saving = false
    @State private var error: String?

    init(gameId: Int, team: APITeam?) {
        self.gameId = gameId
        self.team = team
        _input = State(initialValue: team.map(TeamInput.from) ?? TeamInput.empty())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Team name", text: $input.name)
                    ColorPickerRow(label: "Color", color: $input.color)
                }
                if let error { Text(error).foregroundStyle(.red).font(.footnote) }
            }
            .navigationTitle(team == nil ? "New team" : "Edit team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await save() }
                    } label: { if saving { ProgressView() } else { Text("Save").bold() } }
                    .disabled(input.name.isEmpty || saving)
                }
            }
        }
    }

    private func save() async {
        saving = true
        defer { saving = false }
        error = nil
        do {
            if let team {
                _ = try await APIClient.shared.updateTeam(gameId: gameId, teamId: team.id, input: input)
            } else {
                _ = try await APIClient.shared.createTeam(gameId: gameId, input: input)
            }
            dismiss()
        } catch { self.error = error.userMessage }
    }
}

// MARK: - Categories admin

struct CategoriesAdminView: View {
    let gameId: Int
    @State private var categories: [MissionCategory] = []
    @State private var loading = true
    @State private var error: String?
    @State private var editing: MissionCategory?
    @State private var creating = false
    @State private var editMode: EditMode = .inactive

    var body: some View {
        List {
            if loading {
                ProgressView()
            } else if categories.isEmpty {
                ContentUnavailableView("No categories yet", systemImage: "tag", description: Text("Categories group missions for players."))
            } else {
                ForEach(categories) { c in
                    Button { editing = c } label: {
                        HStack {
                            Circle().fill(Color(hex: c.color)).frame(width: 18, height: 18)
                            Text(c.name).foregroundStyle(.primary)
                            Spacer()
                            Text("#\(c.position)").font(.caption.monospaced()).foregroundStyle(.secondary)
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            Task { await delete(c) }
                        } label: { Label("Delete", systemImage: "trash") }
                    }
                }
                .onMove { from, to in
                    categories.move(fromOffsets: from, toOffset: to)
                    Task { await persistOrder() }
                }
            }
            if let error { Text(error).foregroundStyle(.red).font(.footnote) }
        }
        .environment(\.editMode, $editMode)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    if !categories.isEmpty {
                        Button(editMode == .active ? "Done" : "Reorder") {
                            editMode = (editMode == .active) ? .inactive : .active
                        }
                    }
                    Button { creating = true } label: { Image(systemName: "plus") }
                }
            }
        }
        .task { await load() }
        .refreshable { await load() }
        .sheet(isPresented: $creating, onDismiss: { Task { await load() } }) {
            CategoryEditorView(gameId: gameId, category: nil, defaultPosition: categories.count)
        }
        .sheet(item: $editing, onDismiss: { Task { await load() } }) { c in
            CategoryEditorView(gameId: gameId, category: c, defaultPosition: c.position)
        }
    }

    private func load() async {
        loading = true
        do {
            categories = try await APIClient.shared.categories(gameId: gameId).categories
            error = nil
        } catch { self.error = error.userMessage }
        loading = false
    }

    private func delete(_ c: MissionCategory) async {
        do { try await APIClient.shared.deleteCategory(gameId: gameId, categoryId: c.id); await load() }
        catch { self.error = error.userMessage }
    }

    private func persistOrder() async {
        do { try await APIClient.shared.reorderCategories(gameId: gameId, ids: categories.map(\.id)) }
        catch { self.error = error.userMessage }
    }
}

struct CategoryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let gameId: Int
    let category: MissionCategory?
    let defaultPosition: Int

    @State private var input: CategoryInput
    @State private var saving = false
    @State private var error: String?

    init(gameId: Int, category: MissionCategory?, defaultPosition: Int) {
        self.gameId = gameId
        self.category = category
        self.defaultPosition = defaultPosition
        _input = State(initialValue: category.map(CategoryInput.from) ?? CategoryInput.empty(position: defaultPosition))
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Category name", text: $input.name)
                ColorPickerRow(label: "Color", color: $input.color)
                Stepper("Position: \(input.position ?? 0)", value: Binding(
                    get: { input.position ?? 0 },
                    set: { input.position = $0 }
                ), in: 0...50)
                if let error { Text(error).foregroundStyle(.red).font(.footnote) }
            }
            .navigationTitle(category == nil ? "New category" : "Edit category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await save() }
                    } label: { if saving { ProgressView() } else { Text("Save").bold() } }
                    .disabled(input.name.isEmpty || saving)
                }
            }
        }
    }

    private func save() async {
        saving = true
        defer { saving = false }
        error = nil
        do {
            if let category {
                _ = try await APIClient.shared.updateCategory(gameId: gameId, categoryId: category.id, input: input)
            } else {
                _ = try await APIClient.shared.createCategory(gameId: gameId, input: input)
            }
            dismiss()
        } catch { self.error = error.userMessage }
    }
}

// MARK: - Missions admin

struct MissionsAdminView: View {
    let game: APIGame
    @State private var missions: [APIMission] = []
    @State private var categories: [MissionCategory] = []
    @State private var loading = true
    @State private var error: String?
    @State private var editing: APIMission?
    @State private var creating = false
    @State private var pickingTemplate = false
    @State private var editMode: EditMode = .inactive

    var body: some View {
        List {
            if loading {
                ProgressView()
            } else if missions.isEmpty {
                VStack(spacing: 12) {
                    ContentUnavailableView("No missions yet", systemImage: "list.bullet", description: Text("Missions are the prompts players photograph."))
                    Button { pickingTemplate = true } label: {
                        Label("Start from a template", systemImage: "wand.and.stars")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            } else {
                ForEach(missions) { m in
                    Button { editing = m } label: {
                        HStack {
                            Image(systemName: missionTypeIcon(m.missionType))
                                .foregroundStyle(Color(hex: m.categoryColor ?? "#94A3B8"))
                            VStack(alignment: .leading) {
                                Text(m.title).foregroundStyle(.primary).fontWeight(.medium)
                                HStack(spacing: 6) {
                                    Text("\(m.points) pts").font(.caption).foregroundStyle(.orange)
                                    if let cat = m.categoryName { Text(cat).font(.caption).foregroundStyle(.secondary) }
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            Task { await delete(m) }
                        } label: { Label("Delete", systemImage: "trash") }
                    }
                }
                .onMove { from, to in
                    missions.move(fromOffsets: from, toOffset: to)
                    Task { await persistOrder() }
                }
            }
            if let error { Text(error).foregroundStyle(.red).font(.footnote) }
        }
        .environment(\.editMode, $editMode)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    if !missions.isEmpty {
                        Button(editMode == .active ? "Done" : "Reorder") {
                            editMode = (editMode == .active) ? .inactive : .active
                        }
                    }
                    Menu {
                        Button { creating = true } label: { Label("New mission", systemImage: "plus") }
                        Button { pickingTemplate = true } label: { Label("Add from template", systemImage: "wand.and.stars") }
                    } label: { Image(systemName: "plus") }
                }
            }
        }
        .task { await load() }
        .refreshable { await load() }
        .sheet(isPresented: $creating, onDismiss: { Task { await load() } }) {
            MissionEditorView(gameId: game.id, mission: nil, categories: categories, defaultPosition: missions.count)
        }
        .sheet(isPresented: $pickingTemplate, onDismiss: { Task { await load() } }) {
            TemplatesPickerView(gameId: game.id)
        }
        .sheet(item: $editing, onDismiss: { Task { await load() } }) { m in
            MissionEditorView(gameId: game.id, mission: m, categories: categories, defaultPosition: m.position)
        }
    }

    private func load() async {
        loading = true
        do {
            let res = try await APIClient.shared.missions(gameId: game.id)
            missions = res.missions
            categories = res.categories
            error = nil
        } catch { self.error = error.userMessage }
        loading = false
    }

    private func delete(_ m: APIMission) async {
        do { try await APIClient.shared.deleteMission(gameId: game.id, missionId: m.id); await load() }
        catch { self.error = error.userMessage }
    }

    private func persistOrder() async {
        do { try await APIClient.shared.reorderMissions(gameId: game.id, ids: missions.map(\.id)) }
        catch { self.error = error.userMessage }
    }

    private func missionTypeIcon(_ t: String) -> String {
        switch t {
        case "photo": return "camera.fill"
        case "video": return "video.fill"
        case "gps":   return "location.fill"
        case "text":  return "text.bubble.fill"
        default:      return "questionmark.circle"
        }
    }
}

struct MissionEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let gameId: Int
    let mission: APIMission?
    let categories: [MissionCategory]
    let defaultPosition: Int

    @State private var input: MissionInput
    @State private var saving = false
    @State private var error: String?

    init(gameId: Int, mission: APIMission?, categories: [MissionCategory], defaultPosition: Int) {
        self.gameId = gameId
        self.mission = mission
        self.categories = categories
        self.defaultPosition = defaultPosition
        _input = State(initialValue: mission.map(MissionInput.from) ?? MissionInput.empty(position: defaultPosition))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Mission") {
                    TextField("Title", text: $input.title)
                    TextField("Description (optional)", text: Binding(get: { input.description ?? "" }, set: { input.description = $0.isEmpty ? nil : $0 }), axis: .vertical)
                        .lineLimit(2...5)
                }
                Section("Scoring") {
                    Stepper("Points: \(input.points)", value: $input.points, in: 0...10000, step: 25)
                    Stepper("Manual bonus: \(input.bonusPoints)", value: $input.bonusPoints, in: 0...10000, step: 25)
                    Stepper("First teams to award: \(input.firstBonusCount)", value: $input.firstBonusCount, in: 0...20)
                    Stepper("Bonus for first teams: \(input.firstBonusPoints)", value: $input.firstBonusPoints, in: 0...10000, step: 25)
                }
                Section("Availability window (optional)") {
                    OptionalDateRow(title: "Available from", date: $input.availableFrom)
                    OptionalDateRow(title: "Available until", date: $input.availableUntil)
                }
                Section(header: Text("Hot-spot (optional)"), footer: Text("Submissions must be made within the radius of this location.")) {
                    OptionalDoubleRow(title: "Latitude",  value: $input.hotspotLatitude)
                    OptionalDoubleRow(title: "Longitude", value: $input.hotspotLongitude)
                    OptionalIntRow(title: "Radius (m)", value: $input.hotspotRadiusM)
                }
                Section("Type & category") {
                    Picker("Type", selection: $input.missionType) {
                        Text("Photo").tag("photo")
                        Text("Video").tag("video")
                        Text("Text").tag("text")
                        Text("GPS").tag("gps")
                    }
                    Picker("Category", selection: $input.missionCategoryId) {
                        Text("— none —").tag(Int?.none)
                        ForEach(categories) { c in
                            Text(c.name).tag(Int?.some(c.id))
                        }
                    }
                }
                Section("Behavior") {
                    Toggle("Required for completion", isOn: $input.required)
                    Toggle("Repeatable", isOn: $input.repeatable)
                    Stepper("Max per team: \(input.maxSubmissionsPerTeam)", value: $input.maxSubmissionsPerTeam, in: 1...50)
                    Toggle("Requires GPS location", isOn: $input.requiresLocation)
                }
                Section("Order") {
                    Stepper("Position: \(input.position ?? 0)", value: Binding(
                        get: { input.position ?? 0 },
                        set: { input.position = $0 }
                    ), in: 0...200)
                }
                if let error { Text(error).foregroundStyle(.red).font(.footnote) }
            }
            .navigationTitle(mission == nil ? "New mission" : "Edit mission")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await save() }
                    } label: { if saving { ProgressView() } else { Text("Save").bold() } }
                    .disabled(input.title.isEmpty || saving)
                }
            }
        }
    }

    private func save() async {
        saving = true
        defer { saving = false }
        error = nil
        do {
            if let mission {
                _ = try await APIClient.shared.updateMission(gameId: gameId, missionId: mission.id, input: input)
            } else {
                _ = try await APIClient.shared.createMission(gameId: gameId, input: input)
            }
            dismiss()
        } catch { self.error = error.userMessage }
    }
}

// MARK: - Game settings admin

struct GameSettingsAdminView: View {
    @EnvironmentObject var appState: AppState
    let game: APIGame
    let onDeleted: () -> Void

    @State private var input: GameInput
    @State private var saving = false
    @State private var error: String?
    @State private var statusBusy = false
    @State private var deleting = false
    @State private var duplicating = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var coverUploading = false
    @State private var coverURL: String?

    init(game: APIGame, onDeleted: @escaping () -> Void) {
        self.game = game
        self.onDeleted = onDeleted
        _input = State(initialValue: GameInput.from(game))
        _coverURL = State(initialValue: game.coverUrl)
    }

    var body: some View {
        Form {
            Section("Invite players") {
                VStack(spacing: 12) {
                    QRCodeView(payload: SnapDeepLink.joinURL(code: game.joinCode).absoluteString)
                    Text(game.joinCode)
                        .font(.system(.title2, design: .monospaced).weight(.heavy))
                        .foregroundStyle(Color.accentColor)
                        .textSelection(.enabled)
                    ShareLink(item: "Join my Snap game \"\(game.title)\" — code \(game.joinCode)\n\(SnapDeepLink.joinURL(code: game.joinCode).absoluteString)") {
                        Label("Share invite", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            Section("Status") {
                LabeledContent("Current") {
                    StatusPill(status: game.status)
                }
                LabeledContent("Join code") {
                    Text(game.joinCode).font(.system(.body, design: .monospaced).weight(.bold)).foregroundStyle(Color.accentColor)
                }
                HStack {
                    if game.status != "active" {
                        Button {
                            Task { await changeStatus(.start) }
                        } label: {
                            HStack { if statusBusy { ProgressView() }; Text("Start game") }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    } else {
                        Button {
                            Task { await changeStatus(.end) }
                        } label: {
                            HStack { if statusBusy { ProgressView() }; Text("End game") }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                }
            }
            Section("Game") {
                TextField("Title", text: $input.title)
                TextField("Description", text: Binding(get: { input.description ?? "" }, set: { input.description = $0.isEmpty ? nil : $0 }), axis: .vertical)
                    .lineLimit(2...5)
            }
            Section("Cover image") {
                HStack(spacing: 12) {
                    if let url = coverURL, let imageURL = URL(string: url) {
                        AsyncImage(url: imageURL) { phase in
                            switch phase {
                            case .success(let img): img.resizable().scaledToFill()
                            default: Color.secondary.opacity(0.15).overlay(Image(systemName: "photo"))
                            }
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.secondary.opacity(0.15))
                            .frame(width: 80, height: 80)
                            .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
                    }
                    VStack(alignment: .leading) {
                        PhotosPicker(selection: $pickerItem, matching: .images) {
                            HStack {
                                if coverUploading { ProgressView() }
                                Label(coverURL == nil ? "Pick image" : "Change image", systemImage: "photo.badge.plus")
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(coverUploading)
                        Text("Shown on the game header.")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
            Section("Settings") {
                Toggle("Allow video submissions", isOn: $input.allowVideo)
                Toggle("Show leaderboard", isOn: $input.showLeaderboard)
                Toggle("Auto-approve submissions", isOn: $input.autoApprove)
            }
            Section {
                Button {
                    Task { await save() }
                } label: {
                    HStack { if saving { ProgressView() }; Text("Save changes").bold() }.frame(maxWidth: .infinity)
                }
                .disabled(input.title.isEmpty || saving)
                .buttonStyle(.borderedProminent)
            }
            Section("Actions") {
                Button {
                    Task { await duplicate() }
                } label: {
                    HStack {
                        if duplicating { ProgressView() }
                        Label("Duplicate to a new draft", systemImage: "square.on.square")
                    }
                }
                .disabled(duplicating)
            }
            Section("Danger zone") {
                Button(role: .destructive) {
                    Task { await deleteGame() }
                } label: {
                    HStack { if deleting { ProgressView() }; Text("Delete game") }
                }
            }
            if let error { Text(error).foregroundStyle(.red).font(.footnote) }
        }
        .onChange(of: pickerItem) { _, newItem in
            Task { await uploadCover(newItem) }
        }
    }

    private func uploadCover(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        coverUploading = true
        defer { coverUploading = false }
        error = nil
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else { return }
            let updated = try await APIClient.shared.uploadGameCover(id: game.id, image: image)
            coverURL = updated.coverUrl
            await appState.refreshGames()
        } catch { self.error = error.userMessage }
    }

    private func duplicate() async {
        duplicating = true
        defer { duplicating = false }
        error = nil
        do {
            _ = try await APIClient.shared.duplicateGame(id: game.id)
            await appState.refreshGames()
        } catch { self.error = error.userMessage }
    }

    enum StatusAction { case start, end }

    private func changeStatus(_ action: StatusAction) async {
        statusBusy = true
        defer { statusBusy = false }
        error = nil
        do {
            _ = try await {
                switch action {
                case .start: return try await APIClient.shared.startGame(id: game.id)
                case .end:   return try await APIClient.shared.endGame(id: game.id)
                }
            }()
            await appState.refreshGames()
        } catch { self.error = error.userMessage }
    }

    private func save() async {
        saving = true
        defer { saving = false }
        error = nil
        do {
            _ = try await APIClient.shared.updateGame(id: game.id, input: input)
            await appState.refreshGames()
        } catch { self.error = error.userMessage }
    }

    private func deleteGame() async {
        deleting = true
        defer { deleting = false }
        error = nil
        do {
            try await APIClient.shared.deleteGame(id: game.id)
            await appState.refreshGames()
            onDeleted()
        } catch { self.error = error.userMessage }
    }
}

// MARK: - Shared form helpers

struct OptionalDateRow: View {
    let title: String
    @Binding var date: Date?
    @State private var working: Date = Date()
    var body: some View {
        Toggle(title, isOn: Binding(
            get: { date != nil },
            set: { isOn in date = isOn ? working : nil }
        ))
        if date != nil {
            DatePicker(title, selection: Binding(
                get: { date ?? working },
                set: { date = $0; working = $0 }
            ))
            .labelsHidden()
        }
    }
}

struct OptionalDoubleRow: View {
    let title: String
    @Binding var value: Double?
    @State private var text: String = ""

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            TextField("—", text: $text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 140)
                .onChange(of: text) { _, new in
                    value = Double(new)
                }
        }
        .onAppear { text = value.map { String($0) } ?? "" }
    }
}

struct OptionalIntRow: View {
    let title: String
    @Binding var value: Int?
    @State private var text: String = ""

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            TextField("—", text: $text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 140)
                .onChange(of: text) { _, new in value = Int(new) }
        }
        .onAppear { text = value.map { String($0) } ?? "" }
    }
}

// MARK: - Shared

struct ColorPickerRow: View {
    let label: String
    @Binding var color: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            ColorPicker("", selection: Binding(
                get: { Color(hex: color) },
                set: { color = $0.toHex() }
            ))
            .labelsHidden()
        }
    }
}

extension Color {
    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components else { return "#4F46E5" }
        let r = Int((components[0] * 255).rounded())
        let g = Int(((components.count > 1 ? components[1] : 0) * 255).rounded())
        let b = Int(((components.count > 2 ? components[2] : 0) * 255).rounded())
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
