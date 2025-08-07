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
        self.connect()
    }

    public func connect() {
        print("Connecting to \(url)")
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        isConnected = true
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
                print("Send error: \(error)")
            }
        }
    }

    private func listen() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                print("Receive error: \(error.localizedDescription)")
                self.reconnect()
            case .success(let message):
                switch message {
                case .string(let text):
                    print("Received string: \(text)")
                default:
                    print("Received non-string message")
                }

                // Continue listening
                self.listen()
            }
        }
    }

    private func reconnect() {
        guard isConnected else { return }

        print("Attempting reconnect in \(reconnectDelay) seconds...")
        DispatchQueue.global().asyncAfter(deadline: .now() + reconnectDelay) { [weak self] in
            self?.connect()
        }
    }
    
    private func incomingMessageHandler(message: String) {
        if let jsonData = message.data(using: .utf8) {
            routeRequest(jsonData)
        }
    }
    
    public func sendMessage(type: String, data: Data) {
        let payload = mainPayload(type: type, data: data)
        do {
            let jsonData = try JSONEncoder().encode(payload)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                if isConnected {
                    send(message: jsonString)
                }
            } else {
                print("Failed to convert JSON data to string.")
            }
        } catch {
            print("Failed to encode payload: \(error)")
        }
    }
}

public var socket = WebSocketManager(urlString: "ws://192.168.105.10:1701/missionController")
