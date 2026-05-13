import Foundation

struct APIUser: Codable, Identifiable, Equatable {
    let id: Int
    let emailAddress: String
    let name: String
    let admin: Bool
}

struct APIGame: Codable, Identifiable, Equatable, Hashable {
    let id: Int
    let title: String
    let description: String?
    let joinCode: String
    let status: String
    let startsAt: Date?
    let endsAt: Date?
    let allowVideo: Bool
    let showLeaderboard: Bool
    let autoApprove: Bool
    let owner: GameOwner?
    let coverUrl: String?
    let membership: Membership?
    let teamCount: Int?
    let missionCount: Int?
    let playerCount: Int?
    let role: String?
    let teamId: Int?

    struct GameOwner: Codable, Equatable, Hashable { let id: Int; let name: String }
    struct Membership: Codable, Equatable, Hashable { let role: String; let teamId: Int? }

    var isActive: Bool { status == "active" }
    var statusLabel: String { status.capitalized }
}

struct AuthResponse: Codable {
    let token: String
    let user: APIUser
}

struct MeResponse: Codable {
    let user: APIUser
    let games: [APIGame]
}

struct LeaderboardResponse: Codable {
    let gameId: Int
    let totalMissions: Int?
    let teams: [LeaderboardTeam]
    struct LeaderboardTeam: Codable, Identifiable, Equatable {
        let id: Int
        let name: String
        let color: String
        let points: Int
        let submissions: Int
        let missionsCompleted: Int?
        let completionPct: Int?
    }
}

struct TeamsResponse: Codable {
    let teams: [APITeam]
}

struct APITeam: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let color: String
    let memberCount: Int
    let points: Int
}

struct MissionsResponse: Codable {
    let categories: [MissionCategory]
    let missions: [APIMission]
}

struct MissionCategory: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let color: String
    let position: Int
}

struct APIMission: Codable, Identifiable, Equatable {
    let id: Int
    let gameId: Int
    let categoryId: Int?
    let categoryName: String?
    let categoryColor: String?
    let title: String
    let description: String?
    let points: Int
    let bonusPoints: Int
    let firstBonusCount: Int?
    let firstBonusPoints: Int?
    let missionType: String
    let position: Int
    let required: Bool
    let repeatable: Bool
    let maxSubmissionsPerTeam: Int
    let requiresLocation: Bool
    let availableFrom: Date?
    let availableUntil: Date?
    let hotspotLatitude: Double?
    let hotspotLongitude: Double?
    let hotspotRadiusM: Int?
    let availableNow: Bool?
    let completedByTeam: Bool
    let teamSubmissionCount: Int
}

struct APISubmission: Codable, Identifiable {
    let id: Int
    let missionId: Int
    let missionTitle: String
    let teamId: Int
    let teamName: String
    let teamColor: String
    let user: SubmissionUser
    let caption: String?
    let latitude: Double?
    let longitude: Double?
    let status: String
    let pointsAwarded: Int
    let createdAt: Date?
    let photoUrl: String?
    let videoUrl: String?
    var reactionCounts: [String: Int]?
    var reactionTotal: Int?
    var myReactions: [String]?
    var commentCount: Int?
    struct SubmissionUser: Codable, Hashable { let id: Int; let name: String }
}

struct APIComment: Codable, Identifiable {
    let id: Int
    let submissionId: Int
    let user: APISubmission.SubmissionUser
    let body: String
    let createdAt: Date?
}

struct CommentsResponse: Codable {
    let comments: [APIComment]
}

struct ReactionsPayload: Codable {
    let submissionId: Int
    let counts: [String: Int]
    let mine: [String]
}

struct PlayerProfile: Codable {
    let user: APISubmission.SubmissionUser
    let gameId: Int
    let team: PlayerTeam?
    let role: String
    let totalPoints: Int
    let submissionCount: Int
    let submissions: [APISubmission]
    struct PlayerTeam: Codable { let id: Int; let name: String; let color: String }
}

struct ActivityResponse: Codable {
    let events: [APISubmission]
}

struct SubmissionsResponse: Codable {
    let submissions: [APISubmission]
}

struct CategoriesResponse: Codable {
    let categories: [MissionCategory]
}

// MARK: - Inputs for create/update endpoints

struct GameInput: Encodable {
    var title: String
    var description: String?
    var startsAt: Date?
    var endsAt: Date?
    var allowVideo: Bool
    var showLeaderboard: Bool
    var autoApprove: Bool

    static func empty() -> GameInput {
        GameInput(title: "", description: nil, startsAt: nil, endsAt: nil,
                  allowVideo: false, showLeaderboard: true, autoApprove: true)
    }

    static func from(_ game: APIGame) -> GameInput {
        GameInput(
            title: game.title,
            description: game.description,
            startsAt: game.startsAt,
            endsAt: game.endsAt,
            allowVideo: game.allowVideo,
            showLeaderboard: game.showLeaderboard,
            autoApprove: game.autoApprove
        )
    }
}

struct TeamInput: Encodable {
    var name: String
    var color: String

    static func empty() -> TeamInput { TeamInput(name: "", color: "#4F46E5") }
    static func from(_ team: APITeam) -> TeamInput { TeamInput(name: team.name, color: team.color) }
}

struct CategoryInput: Encodable {
    var name: String
    var color: String
    var position: Int?

    static func empty(position: Int = 0) -> CategoryInput {
        CategoryInput(name: "", color: "#10B981", position: position)
    }
    static func from(_ c: MissionCategory) -> CategoryInput {
        CategoryInput(name: c.name, color: c.color, position: c.position)
    }
}

struct MissionInput: Encodable {
    var title: String
    var description: String?
    var points: Int
    var bonusPoints: Int
    var firstBonusCount: Int
    var firstBonusPoints: Int
    var missionType: String
    var position: Int?
    var required: Bool
    var repeatable: Bool
    var maxSubmissionsPerTeam: Int
    var requiresLocation: Bool
    var missionCategoryId: Int?
    var availableFrom: Date?
    var availableUntil: Date?
    var hotspotLatitude: Double?
    var hotspotLongitude: Double?
    var hotspotRadiusM: Int?

    static func empty(position: Int = 0) -> MissionInput {
        MissionInput(title: "", description: nil, points: 100, bonusPoints: 0,
                     firstBonusCount: 0, firstBonusPoints: 0,
                     missionType: "photo", position: position, required: false,
                     repeatable: false, maxSubmissionsPerTeam: 1, requiresLocation: false,
                     missionCategoryId: nil,
                     availableFrom: nil, availableUntil: nil,
                     hotspotLatitude: nil, hotspotLongitude: nil, hotspotRadiusM: nil)
    }
    static func from(_ m: APIMission) -> MissionInput {
        MissionInput(
            title: m.title, description: m.description, points: m.points,
            bonusPoints: m.bonusPoints,
            firstBonusCount: m.firstBonusCount ?? 0,
            firstBonusPoints: m.firstBonusPoints ?? 0,
            missionType: m.missionType, position: m.position,
            required: m.required, repeatable: m.repeatable,
            maxSubmissionsPerTeam: m.maxSubmissionsPerTeam,
            requiresLocation: m.requiresLocation, missionCategoryId: m.categoryId,
            availableFrom: m.availableFrom, availableUntil: m.availableUntil,
            hotspotLatitude: m.hotspotLatitude, hotspotLongitude: m.hotspotLongitude,
            hotspotRadiusM: m.hotspotRadiusM
        )
    }
}

struct GameTemplateSummary: Codable, Identifiable {
    var id: String { slug }
    let slug: String
    let title: String
    let description: String
    let categoryCount: Int
    let missionCount: Int
    let categories: [TemplateCategory]
    let missions: [TemplateMission]
    struct TemplateCategory: Codable, Hashable { let name: String; let color: String? }
    struct TemplateMission: Codable, Hashable { let title: String; let points: Int; let category: String? }
}

struct GameTemplatesResponse: Codable {
    let templates: [GameTemplateSummary]
}
