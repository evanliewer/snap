import Foundation
import UIKit

enum APIError: Error {
    case http(Int, String)
    case decoding
    case network(String)
    case unauthorized

    var message: String {
        switch self {
        case .http(_, let m): return m
        case .decoding: return "Couldn't parse the server response."
        case .network(let m): return m
        case .unauthorized: return "Session expired. Please log in again."
        }
    }
}

final class APIClient {
    static let shared = APIClient()

    static let defaultProductionURL = URL(string: "https://snap-backend-4cav.onrender.com")!

    /// Override at runtime via the API settings sheet on the auth screen.
    var baseURL: URL {
        if let custom = UserDefaults.standard.string(forKey: "snap.api.baseURL"),
           let url = URL(string: custom) {
            return url
        }
        #if targetEnvironment(simulator)
        return URL(string: "http://localhost:3000")!
        #else
        return Self.defaultProductionURL
        #endif
    }

    private let tokenKey = "snap.api.token"
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        self.decoder = d
    }

    var token: String? { UserDefaults.standard.string(forKey: tokenKey) }
    func setToken(_ t: String) { UserDefaults.standard.set(t, forKey: tokenKey) }
    func clearToken() { UserDefaults.standard.removeObject(forKey: tokenKey) }

    func setBaseURL(_ urlString: String) {
        UserDefaults.standard.set(urlString, forKey: "snap.api.baseURL")
    }

    // MARK: Auth

    func signup(name: String, email: String, password: String) async throws -> AuthResponse {
        try await post("/api/v1/signup", body: ["name": name, "email_address": email, "password": password], authed: false)
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        try await post("/api/v1/login", body: ["email_address": email, "password": password], authed: false)
    }

    func logout() async throws {
        _ = try? await request("/api/v1/logout", method: "DELETE", body: nil as String?)
    }

    // MARK: Me

    func me() async throws -> MeResponse {
        try await get("/api/v1/me")
    }

    // MARK: Games

    func joinGame(code: String) async throws -> APIGame {
        try await post("/api/v1/games/join", body: ["join_code": code])
    }

    func game(_ id: Int) async throws -> APIGame {
        try await get("/api/v1/games/\(id)")
    }

    func createGame(input: GameInput) async throws -> APIGame {
        try await post("/api/v1/games", body: ["game": input])
    }

    func updateGame(id: Int, input: GameInput) async throws -> APIGame {
        try await patch("/api/v1/games/\(id)", body: ["game": input])
    }

    func deleteGame(id: Int) async throws {
        _ = try await request("/api/v1/games/\(id)", method: "DELETE", body: nil as String?)
    }

    func startGame(id: Int) async throws -> APIGame {
        try await post("/api/v1/games/\(id)/start", body: [String: String]())
    }

    func endGame(id: Int) async throws -> APIGame {
        try await post("/api/v1/games/\(id)/end", body: [String: String]())
    }

    func duplicateGame(id: Int) async throws -> APIGame {
        try await post("/api/v1/games/\(id)/duplicate", body: [String: String]())
    }

    func uploadGameCover(id: Int, image: UIImage) async throws -> APIGame {
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = try buildRequest(path: "/api/v1/games/\(id)/cover", method: "PATCH", authed: true)
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        var body = Data()
        if let jpeg = image.jpegData(compressionQuality: 0.85) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"cover_image\"; filename=\"cover.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(jpeg)
            body.append("\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        let (data, response) = try await session.upload(for: request, from: body)
        return try decode(data: data, response: response)
    }

    func reorderMissions(gameId: Int, ids: [Int]) async throws {
        _ = try await request("/api/v1/games/\(gameId)/missions/reorder", method: "POST", body: ["ids": ids])
    }

    func reorderCategories(gameId: Int, ids: [Int]) async throws {
        _ = try await request("/api/v1/games/\(gameId)/categories/reorder", method: "POST", body: ["ids": ids])
    }

    func leaderboard(gameId: Int) async throws -> LeaderboardResponse {
        try await get("/api/v1/games/\(gameId)/leaderboard")
    }

    func activity(gameId: Int) async throws -> ActivityResponse {
        try await get("/api/v1/games/\(gameId)/activity")
    }

    // MARK: Teams

    func teams(gameId: Int) async throws -> TeamsResponse {
        try await get("/api/v1/games/\(gameId)/teams")
    }

    func joinTeam(gameId: Int, teamId: Int) async throws -> APITeam {
        try await post("/api/v1/games/\(gameId)/teams/\(teamId)/join", body: [String: String]())
    }

    func createTeam(gameId: Int, input: TeamInput) async throws -> APITeam {
        try await post("/api/v1/games/\(gameId)/teams", body: ["team": input])
    }

    func updateTeam(gameId: Int, teamId: Int, input: TeamInput) async throws -> APITeam {
        try await patch("/api/v1/games/\(gameId)/teams/\(teamId)", body: ["team": input])
    }

    func deleteTeam(gameId: Int, teamId: Int) async throws {
        _ = try await request("/api/v1/games/\(gameId)/teams/\(teamId)", method: "DELETE", body: nil as String?)
    }

    // MARK: Categories

    func categories(gameId: Int) async throws -> CategoriesResponse {
        try await get("/api/v1/games/\(gameId)/categories")
    }

    func createCategory(gameId: Int, input: CategoryInput) async throws -> MissionCategory {
        try await post("/api/v1/games/\(gameId)/categories", body: ["mission_category": input])
    }

    func updateCategory(gameId: Int, categoryId: Int, input: CategoryInput) async throws -> MissionCategory {
        try await patch("/api/v1/games/\(gameId)/categories/\(categoryId)", body: ["mission_category": input])
    }

    func deleteCategory(gameId: Int, categoryId: Int) async throws {
        _ = try await request("/api/v1/games/\(gameId)/categories/\(categoryId)", method: "DELETE", body: nil as String?)
    }

    // MARK: Missions

    func missions(gameId: Int) async throws -> MissionsResponse {
        try await get("/api/v1/games/\(gameId)/missions")
    }

    func createMission(gameId: Int, input: MissionInput) async throws -> APIMission {
        try await post("/api/v1/games/\(gameId)/missions", body: ["mission": input])
    }

    func updateMission(gameId: Int, missionId: Int, input: MissionInput) async throws -> APIMission {
        try await patch("/api/v1/games/\(gameId)/missions/\(missionId)", body: ["mission": input])
    }

    func deleteMission(gameId: Int, missionId: Int) async throws {
        _ = try await request("/api/v1/games/\(gameId)/missions/\(missionId)", method: "DELETE", body: nil as String?)
    }

    // MARK: Submissions

    func submissions(gameId: Int, status: String? = nil) async throws -> SubmissionsResponse {
        var path = "/api/v1/games/\(gameId)/submissions"
        if let status, !status.isEmpty {
            path += "?status=\(status)"
        }
        return try await get(path)
    }

    func reviewSubmission(id: Int, status: String, pointsAwarded: Int? = nil, reviewNotes: String? = nil) async throws -> APISubmission {
        struct Body: Encodable {
            struct Sub: Encodable {
                let status: String
                let pointsAwarded: Int?
                let reviewNotes: String?
            }
            let submission: Sub
        }
        let body = Body(submission: .init(status: status, pointsAwarded: pointsAwarded, reviewNotes: reviewNotes))
        return try await patch("/api/v1/submissions/\(id)", body: body)
    }

    func deleteSubmission(id: Int) async throws {
        _ = try await request("/api/v1/submissions/\(id)", method: "DELETE", body: nil as String?)
    }

    func submitPhoto(missionId: Int, image: UIImage, caption: String?, latitude: Double?, longitude: Double?) async throws -> APISubmission {
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = try buildRequest(path: "/api/v1/missions/\(missionId)/submissions", method: "POST", authed: true)
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        func appendField(name: String, value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        if let caption, !caption.isEmpty { appendField(name: "caption", value: caption) }
        if let latitude { appendField(name: "latitude", value: String(latitude)) }
        if let longitude { appendField(name: "longitude", value: String(longitude)) }

        if let jpeg = image.jpegData(compressionQuality: 0.85) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"photo\"; filename=\"submission.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(jpeg)
            body.append("\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        let (data, response) = try await session.upload(for: request, from: body)
        return try decode(data: data, response: response)
    }

    // MARK: Generic plumbing

    private func get<T: Decodable>(_ path: String) async throws -> T {
        let (data, response) = try await request(path, method: "GET", body: nil as String?)
        return try decode(data: data, response: response)
    }

    private func post<T: Decodable, B: Encodable>(_ path: String, body: B, authed: Bool = true) async throws -> T {
        let (data, response) = try await request(path, method: "POST", body: body, authed: authed)
        return try decode(data: data, response: response)
    }

    private func patch<T: Decodable, B: Encodable>(_ path: String, body: B, authed: Bool = true) async throws -> T {
        let (data, response) = try await request(path, method: "PATCH", body: body, authed: authed)
        return try decode(data: data, response: response)
    }

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private func request<B: Encodable>(_ path: String, method: String, body: B?, authed: Bool = true) async throws -> (Data, URLResponse) {
        var request = try buildRequest(path: path, method: method, authed: authed)
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(body)
        }
        do {
            return try await session.data(for: request)
        } catch {
            throw APIError.network(error.localizedDescription)
        }
    }

    private func buildRequest(path: String, method: String, authed: Bool) throws -> URLRequest {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw APIError.network("Invalid URL")
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if authed, let token { req.setValue("Token \(token)", forHTTPHeaderField: "Authorization") }
        return req
    }

    private func decode<T: Decodable>(data: Data, response: URLResponse) throws -> T {
        guard let http = response as? HTTPURLResponse else { throw APIError.network("No response") }
        if http.statusCode == 401 { throw APIError.unauthorized }
        if !(200...299).contains(http.statusCode) {
            let msg = (try? decoder.decode(ErrorPayload.self, from: data))?.error ?? "Request failed (\(http.statusCode))"
            throw APIError.http(http.statusCode, msg)
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            print("[APIClient] decoding failed: \(error)")
            throw APIError.decoding
        }
    }

    struct ErrorPayload: Decodable { let error: String? }
}
