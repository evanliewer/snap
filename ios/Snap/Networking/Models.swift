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
    let teams: [LeaderboardTeam]
    struct LeaderboardTeam: Codable, Identifiable {
        let id: Int
        let name: String
        let color: String
        let points: Int
        let submissions: Int
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
    let missionType: String
    let position: Int
    let required: Bool
    let repeatable: Bool
    let maxSubmissionsPerTeam: Int
    let requiresLocation: Bool
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
    struct SubmissionUser: Codable { let id: Int; let name: String }
}

struct ActivityResponse: Codable {
    let events: [APISubmission]
}
