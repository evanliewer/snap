import Foundation

/// Minimal ActionCable client over URLSessionWebSocketTask.
/// Connects to /cable?token=<api_token>, subscribes to a channel + params,
/// invokes `onMessage` for each broadcast message decoded into the given Decodable type.
@MainActor
final class CableClient<Payload: Decodable & Sendable>: NSObject, URLSessionWebSocketDelegate {
    private let baseURL: URL
    private let token: String
    private let channel: String
    private let params: [String: Any]
    private let onMessage: (Payload) -> Void

    private var task: URLSessionWebSocketTask?
    private var session: URLSession?
    private var identifier: String = ""
    private var reconnectAttempt = 0
    private var stopped = false

    init(baseURL: URL,
         token: String,
         channel: String,
         params: [String: Any],
         onMessage: @escaping (Payload) -> Void) {
        self.baseURL = baseURL
        self.token = token
        self.channel = channel
        self.params = params
        self.onMessage = onMessage
        super.init()
    }

    func connect() {
        stopped = false
        var ident: [String: Any] = ["channel": channel]
        for (k, v) in params { ident[k] = v }
        let identData = try! JSONSerialization.data(withJSONObject: ident, options: [.sortedKeys])
        identifier = String(data: identData, encoding: .utf8) ?? ""

        guard var components = URLComponents(url: baseURL.appendingPathComponent("cable"), resolvingAgainstBaseURL: false) else { return }
        // ws:// or wss:// based on scheme
        switch components.scheme {
        case "https": components.scheme = "wss"
        case "http":  components.scheme = "ws"
        default: break
        }
        components.queryItems = [URLQueryItem(name: "token", value: token)]
        guard let url = components.url else { return }

        let config = URLSessionConfiguration.default
        let s = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        let t = s.webSocketTask(with: url, protocols: ["actioncable-v1-json"])
        session = s
        task = t
        t.resume()
        listen()
    }

    func disconnect() {
        stopped = true
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
        session?.invalidateAndCancel()
        session = nil
    }

    private func sendSubscribe() {
        let msg: [String: Any] = ["command": "subscribe", "identifier": identifier]
        send(json: msg)
    }

    private func send(json: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: json, options: []),
              let text = String(data: data, encoding: .utf8) else { return }
        task?.send(.string(text)) { error in
            if let error { print("[CableClient] send error: \(error)") }
        }
    }

    private func listen() {
        task?.receive { [weak self] result in
            guard let self else { return }
            Task { @MainActor in
                switch result {
                case .success(.string(let text)):
                    self.handle(text: text)
                    self.listen()
                case .success(.data(let data)):
                    if let text = String(data: data, encoding: .utf8) { self.handle(text: text) }
                    self.listen()
                case .success:
                    self.listen()
                case .failure(let error):
                    print("[CableClient] receive failure: \(error)")
                    self.scheduleReconnect()
                }
            }
        }
    }

    private func handle(text: String) {
        guard let data = text.data(using: .utf8),
              let any = try? JSONSerialization.jsonObject(with: data),
              let obj = any as? [String: Any] else { return }
        if let type = obj["type"] as? String {
            switch type {
            case "welcome":
                sendSubscribe()
            case "ping":
                return
            case "confirm_subscription":
                reconnectAttempt = 0
                return
            case "reject_subscription":
                print("[CableClient] subscription rejected")
                return
            default:
                break
            }
        }
        if let message = obj["message"] {
            guard let payloadData = try? JSONSerialization.data(withJSONObject: message) else { return }
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                decoder.dateDecodingStrategy = .iso8601
                let payload = try decoder.decode(Payload.self, from: payloadData)
                onMessage(payload)
            } catch {
                print("[CableClient] decode failed: \(error)")
            }
        }
    }

    private func scheduleReconnect() {
        guard !stopped else { return }
        reconnectAttempt += 1
        let delay = min(30.0, pow(2.0, Double(reconnectAttempt)))
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !stopped else { return }
            self.task?.cancel(with: .normalClosure, reason: nil)
            self.connect()
        }
    }

    // MARK: URLSessionWebSocketDelegate

    nonisolated func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        // Welcome message will trigger subscribe
    }

    nonisolated func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        Task { @MainActor in self.scheduleReconnect() }
    }
}

/// Wire-level message from ActivityChannel broadcasts.
struct ActivityChannelMessage: Decodable, Sendable {
    let type: String
    let submission: APISubmission
}
