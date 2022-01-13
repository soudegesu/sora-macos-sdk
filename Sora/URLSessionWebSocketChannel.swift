import Foundation

@available(iOS 13, *)
class URLSessionWebSocketChannel: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionWebSocketDelegate {
    let url: URL
    var handlers = WebSocketChannelHandlers()
    var internalHandlers = WebSocketChannelInternalHandlers()
    var isClosing = false

    var host: String {
        url.host!
    }

    var urlSession: URLSession?
    var webSocketTask: URLSessionWebSocketTask?

    init(url: URL) {
        self.url = url
    }

    func connect() {
        Logger.debug(type: .webSocketChannel, message: "[\(host)] try connecting")
        urlSession = URLSession(configuration: .default,
                                delegate: self,
                                delegateQueue: nil)
        webSocketTask = urlSession?.webSocketTask(with: url)
        webSocketTask?.resume()
        receive()
    }

    func disconnect(error: Error?) {
        guard !isClosing else {
            return
        }

        isClosing = true
        Logger.debug(type: .webSocketChannel, message: "[\(host)] try disconnecting")
        if error != nil {
            Logger.debug(type: .webSocketChannel,
                         message: "error: \(error!.localizedDescription)")
        }

        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        urlSession?.invalidateAndCancel()

        Logger.debug(type: .webSocketChannel, message: "[\(host)] call onDisconnect")
        internalHandlers.onDisconnect?(self, error)
        handlers.onDisconnect?(error)

        Logger.debug(type: .webSocketChannel, message: "[\(host)] did disconnect")
    }

    func send(message: WebSocketMessage) {
        var naviveMessage: URLSessionWebSocketTask.Message!
        switch message {
        case let .text(text):
            Logger.debug(type: .webSocketChannel, message: text)
            naviveMessage = .string(text)
        case let .binary(data):
            Logger.debug(type: .webSocketChannel, message: "[\(host)] \(data)")
            naviveMessage = .data(data)
        }
        webSocketTask!.send(naviveMessage) { [weak self] error in
            guard let weakSelf = self else {
                return
            }
            if let error = error {
                Logger.debug(type: .webSocketChannel, message: "[\(weakSelf.host)]failed to send message")
                weakSelf.disconnect(error: error)
            }
        }
    }

    func receive() {
        webSocketTask?.receive { [weak self] result in
            guard let weakSelf = self else {
                return
            }

            switch result {
            case let .success(message):
                Logger.debug(type: .webSocketChannel, message: "[\(weakSelf.host)] receive message => \(message)")

                var newMessage: WebSocketMessage?
                switch message {
                case let .string(string):
                    newMessage = .text(string)
                case let .data(data):
                    newMessage = .binary(data)
                @unknown default:
                    break
                }

                if let message = newMessage {
                    Logger.debug(type: .webSocketChannel, message: "[\(weakSelf.host)] call onReceive")
                    weakSelf.internalHandlers.onReceive?(message)
                    weakSelf.handlers.onReceive?(message)
                } else {
                    Logger.debug(type: .webSocketChannel,
                                 message: "[\(weakSelf.host)] received message is not string or binary (discarded)")
                    // discard
                }

                weakSelf.receive()

            case let .failure(error):
                Logger.debug(type: .webSocketChannel,
                             message: "[\(weakSelf.host)] failed => \(error.localizedDescription)")
                weakSelf.disconnect(error: SoraError.webSocketError(error))
            }
        }
    }

    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didOpenWithProtocol protocol: String?)
    {
        Logger.debug(type: .webSocketChannel, message: "[\(host)] connected")
        if let onConnect = internalHandlers.onConnect {
            onConnect(self)
        }
    }

    func reason2string(reason: Data?) -> String? {
        guard let reason = reason else {
            return nil
        }

        return String(data: reason, encoding: .utf8)
    }

    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
                    reason: Data?)
    {
        var message = "[\(host)] closed with code => \(closeCode.rawValue)"

        let reasonString = reason2string(reason: reason)
        if reasonString != nil {
            message = message + " and reason => \(String(describing: reasonString))"
        }

        Logger.debug(type: .webSocketChannel, message: message)

        if closeCode != .normalClosure {
            let statusCode = WebSocketStatusCode(rawValue: closeCode.rawValue)
            let error = SoraError.webSocketClosed(statusCode: statusCode,
                                                  reason: reasonString)
            disconnect(error: error)
        }
    }
}
