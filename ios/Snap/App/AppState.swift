import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    enum Phase: Equatable { case loading, signedOut, signedIn }

    @Published var phase: Phase = .loading
    @Published var currentUser: APIUser?
    @Published var joinedGames: [APIGame] = []
    @Published var errorMessage: String?

    let api: APIClient

    init(api: APIClient = .shared) {
        self.api = api
    }

    func bootstrap() async {
        if api.token != nil {
            do {
                let me = try await api.me()
                currentUser = me.user
                joinedGames = me.games
                phase = .signedIn
            } catch {
                api.clearToken()
                phase = .signedOut
            }
        } else {
            phase = .signedOut
        }
    }

    func login(email: String, password: String) async {
        do {
            let res = try await api.login(email: email, password: password)
            api.setToken(res.token)
            currentUser = res.user
            await refreshGames()
            phase = .signedIn
        } catch {
            errorMessage = error.userMessage
        }
    }

    func signup(name: String, email: String, password: String) async {
        do {
            let res = try await api.signup(name: name, email: email, password: password)
            api.setToken(res.token)
            currentUser = res.user
            joinedGames = []
            phase = .signedIn
        } catch {
            errorMessage = error.userMessage
        }
    }

    func logout() async {
        try? await api.logout()
        api.clearToken()
        currentUser = nil
        joinedGames = []
        phase = .signedOut
    }

    func refreshGames() async {
        do {
            let me = try await api.me()
            currentUser = me.user
            joinedGames = me.games
        } catch {
            errorMessage = error.userMessage
        }
    }

    func joinGame(code: String) async -> APIGame? {
        do {
            let game = try await api.joinGame(code: code)
            await refreshGames()
            return game
        } catch {
            errorMessage = error.userMessage
            return nil
        }
    }
}

extension Error {
    var userMessage: String {
        if let apiErr = self as? APIError { return apiErr.message }
        return localizedDescription
    }
}
