// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation

public final class WebSocketService {

    private var connections: [URL: WebSocketConnection] = [:]
    private let queue = DispatchQueue(label: "WebSocketService")
    private let consoleLogger: ((String) -> Void)?
    private let networkDebugLogger: NetworkDebugLogger

    public init(
        consoleLogger: ((String) -> Void)? = nil,
        networkDebugLogger: NetworkDebugLogger
    ) {
        self.consoleLogger = consoleLogger
        self.networkDebugLogger = networkDebugLogger
    }

    public func connect(
        url: URL,
        handler: @escaping (WebSocketConnection.Event) -> Void
    ) {
        consoleLogger?("WebSocketService: connect \(url)")
        let interceptHandler: (WebSocketConnection.Event) -> Void = { [handler, weak self] event in
            guard let self else { return }
            guard event != .recoverFromURLSessionCompletionError else {
                self.queue.sync {
                    if let existingConnection = self.connections[url], !existingConnection.isConnected {
                        existingConnection.open()
                    }
                }
                return
            }
            handler(event)
        }
        queue.sync { [weak self] in
            guard let self else { return }
            var connection: WebSocketConnection
            if let existingConnection = self.connections[url] {
                connection = existingConnection
            } else {
                connection = WebSocketConnection(
                    url: url,
                    handler: interceptHandler,
                    consoleLogger: self.consoleLogger,
                    networkDebugLogger: self.networkDebugLogger
                )
                self.connections[url] = connection
            }
            if !connection.isConnected {
                connection.open()
            }
        }
    }

    public func disconnect(url: URL) {
        consoleLogger?("WebSocketService: disconnect \(url)")
        queue.sync { [weak self] in
            self?.connections[url]?.close(closeCode: .normalClosure)
        }
    }

    public func send(url: URL, message: WebSocketConnection.Message) {
        consoleLogger?("WebSocketService: send \(url) message: \(message)")
        queue.sync { [weak self] in
            self?.connections[url]?.send(message)
        }
    }
}
