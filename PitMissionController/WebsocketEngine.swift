import Foundation

public class WebSocketManager {
    private var webSocketTask: URLSessionWebSocketTask?
    private let url: URL
    private let session: URLSession

    public private(set) var isConnected = false
    private var reconnectDelay: TimeInterval = 2.0

    public init(urlString: String) {
        self.url = URL(string: urlString)!
        self.session = URLSession(configuration: .default)
    }

    public func connect() {
        print("[WebSocket] Connecting to \(url)")
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        isConnected = true
        DispatchQueue.main.async {
            sharedStates.stateL = .Screensaver
            sharedStates.stateR = .Screensaver
        }
        listen()
    }

    public func disconnect() {
        isConnected = false
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }

    public func send(message: String) {
        let msg = URLSessionWebSocketTask.Message.string(message)
        webSocketTask?.send(msg) { error in
            if let error = error {
                print("[WebSocket] Send error: \(error.localizedDescription)")
            }
        }
    }

    private func listen() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                print("[WebSocket] Disconnected: \(error.localizedDescription)")
                self.reconnect()
            case .success(let message):
                switch message {
                case .string(let text):
                    routeRequest(text)
                default:
                    break
                }
                self.listen()
            }
        }
    }

    private func reconnect() {
        guard isConnected else { return }

        print("[WebSocket] Reconnecting in \(reconnectDelay)s...")
        DispatchQueue.global().asyncAfter(deadline: .now() + reconnectDelay) { [weak self] in
            self?.connect()
        }
    }
    
    public func sendMessage(type: String, data: String) {
        let payload = mainPayload(type: type, data: data)
        do {
            let jsonData = try JSONEncoder().encode(payload)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                if isConnected {
                    send(message: jsonString)
                }
            }
        } catch {
            print("[WebSocket] Encode error: \(error)")
        }
    }
}

//public var socket = WebSocketManager(urlString: "ws://192.168.105.10:1701/missionController")
public var socket = WebSocketManager(urlString: "ws://10.7.14.113:1701/missionController")
