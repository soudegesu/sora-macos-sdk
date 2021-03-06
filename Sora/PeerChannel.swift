import Foundation
import WebRTC

private let peerChannelSignalingStateTable: PairTable<PeerChannelSignalingState, RTCSignalingState> =
    PairTable(name: "PeerChannelSignalingState",
              pairs: [(.stable, .stable),
                      (.haveLocalOffer, .haveLocalOffer),
                      (.haveLocalPrAnswer, .haveLocalPrAnswer),
                      (.haveRemoteOffer, .haveRemoteOffer),
                      (.haveRemotePrAnswer, .haveRemotePrAnswer),
                      (.closed, .closed)])

private let iceConnectionStateTable: PairTable<ICEConnectionState, RTCIceConnectionState> =
    PairTable(name: "ICEConnectionState",
              pairs: [(.new, .new),
                      (.checking, .checking),
                      (.connected, .connected),
                      (.completed, .completed),
                      (.failed, .failed),
                      (.disconnected, .disconnected),
                      (.closed, .closed),
                      (.count, .count)])

private let iceGatheringStateTable: PairTable<ICEGatheringState, RTCIceGatheringState> =
    PairTable(name: "ICEGatheringState",
              pairs: [(.new, .new),
                      (.gathering, .gathering),
                      (.complete, .complete)])

enum PeerChannelSignalingState {
    
    case stable
    case haveLocalOffer
    case haveLocalPrAnswer
    case haveRemoteOffer
    case haveRemotePrAnswer
    case closed
    
    init(nativeValue: RTCSignalingState) {
        self = peerChannelSignalingStateTable.left(other: nativeValue)!
    }
    
}

enum ICEConnectionState {
    
    case new
    case checking
    case connected
    case completed
    case failed
    case disconnected
    case closed
    case count
    
    init(nativeValue: RTCIceConnectionState) {
        self = iceConnectionStateTable.left(other: nativeValue)!
    }
    
}

enum ICEGatheringState {
    
    case new
    case gathering
    case complete
    
    init(nativeValue: RTCIceGatheringState) {
        self = iceGatheringStateTable.left(other: nativeValue)!
    }
    
}

class PeerChannelInternalState {
    
    var signalingState: PeerChannelSignalingState {
        didSet { validate() }
    }
    
    var iceConnectionState: ICEConnectionState {
        didSet { validate() }
    }
    
    var iceGatheringState: ICEGatheringState {
        didSet { validate() }
    }
    
    private var isConnected: Bool = false
    
    private var isCompleted: Bool {
        get {
            switch (signalingState, iceConnectionState, iceGatheringState) {
            case (.stable, .connected, .complete):
                return true
            default:
                return false
            }
        }
    }
    
    var onCompleteHandler: (() -> Void)?
    var onDisconnectHandler: (() -> Void)?
    
    init(signalingState: PeerChannelSignalingState,
         iceConnectionState: ICEConnectionState,
         iceGatheringState: ICEGatheringState) {
        self.signalingState = signalingState
        self.iceConnectionState = iceConnectionState
        self.iceGatheringState = iceGatheringState
    }
    
    private func validate() {
        if isCompleted {
            Logger.debug(type: .peerChannel,
                         message: "peer channel state: completed")
            Logger.debug(type: .peerChannel,
                         message: "    signaling state: \(signalingState)")
            Logger.debug(type: .peerChannel,
                         message: "    ICE connection state: \(iceConnectionState)")
            Logger.debug(type: .peerChannel,
                         message: "    ICE gathering state: \(iceGatheringState)")
            
            isConnected = true
            onCompleteHandler?()
            onCompleteHandler = nil
        } else if isConnected {
            if signalingState == .closed {
                Logger.debug(type: .peerChannel,
                             message: "peer channel state: disconnected")
                Logger.debug(type: .peerChannel,
                             message: "    signaling state: \(signalingState)")
                Logger.debug(type: .peerChannel,
                             message: "    ICE connection state: \(iceConnectionState)")
                Logger.debug(type: .peerChannel,
                             message: "    ICE gathering state: \(iceGatheringState)")
                isConnected = false
                onDisconnectHandler?()
            }
        } else {
            Logger.debug(type: .peerChannel,
                         message: "peer channel state: not completed")
            Logger.debug(type: .peerChannel,
                         message: "    signaling state: \(signalingState)")
            Logger.debug(type: .peerChannel,
                         message: "    ICE connection state: \(iceConnectionState)")
            Logger.debug(type: .peerChannel,
                         message: "    ICE gathering state: \(iceGatheringState)")
        }
    }
}

/**
 ??????????????????????????????????????????????????????
 */
public final class PeerChannelHandlers {
    
    /// ???????????????????????? onDisconnect ?????????????????????????????????
    @available(*, deprecated, renamed: "onDisconnect",
    message: "???????????????????????? onDisconnect ?????????????????????????????????")
    public var onDisconnectHandler: ((Error?) -> Void)? {
        get { onDisconnect }
        set { onDisconnect = newValue }
    }
    
    /// ???????????????????????? onAddStream ?????????????????????????????????
    @available(*, deprecated, renamed: "onAddStream",
    message: "???????????????????????? onConnect ?????????????????????????????????")
    public var onAddStreamHandler: ((MediaStream) -> Void)? {
        get { onAddStream }
        set { onAddStream = newValue }
    }
    
    /// ???????????????????????? onRemoveStream ?????????????????????????????????
    @available(*, deprecated, renamed: "onRemoveStream",
    message: "???????????????????????? onRemoveStream ?????????????????????????????????")
    public var onRemoveStreamHandler: ((MediaStream) -> Void)? {
        get { onRemoveStream }
        set { onRemoveStream = newValue }
    }
    
    /// ???????????????????????? onUpdate ?????????????????????????????????
    @available(*, deprecated, renamed: "onUpdate",
    message: "???????????????????????? onUpdate ?????????????????????????????????")
    public var onUpdateHandler: ((String) -> Void)? {
        get { onUpdate }
        set { onUpdate = newValue }
    }
    
    /// ???????????????????????? onReceiveSignaling ?????????????????????????????????
    @available(*, deprecated, renamed: "onReceiveSignaling",
    message: "???????????????????????? onReceiveSignaling ?????????????????????????????????")
    public var onReceiveSignalingHandler: ((Signaling) -> Void)? {
        get { onReceiveSignaling }
        set { onReceiveSignaling = newValue }
    }
    
    /// ????????????????????????????????????????????????
    public var onDisconnect: ((Error?) -> Void)?
    
    /// ????????????????????????????????????????????????????????????
    public var onAddStream: ((MediaStream) -> Void)?
    
    /// ????????????????????????????????????????????????????????????
    public var onRemoveStream: ((MediaStream) -> Void)?
    
    /// ??????????????????????????????????????????????????????????????????????????????
    /// ??????????????????????????????????????????????????????????????????????????????
    public var onUpdate: ((String) -> Void)?
    
    /// ????????????????????????????????????????????????????????????
    public var onReceiveSignaling: ((Signaling) -> Void)?
    
    /// ?????????????????????
    public init() {}
    
}

// MARK: -

/**
 ??????????????????????????????????????????????????????????????????
 ???????????????????????????????????? (`internal`) ?????????????????????????????????????????????????????????????????????????????????
 ????????????????????????????????????????????????????????????????????????????????????????????????????????????
 
 ???????????????????????????????????????????????????????????????????????????????????????
 ???????????????????????????????????????????????????????????????????????? `MediaStream` ????????????
 ??????????????????????????????????????????????????????
 ??????????????????????????????????????????????????????????????? 1 ???????????????????????????????????????????????????????????????
 */
public protocol PeerChannel: class {
    
    // MARK: - ????????????????????????
    
    /// ????????????????????????
    var handlers: PeerChannelHandlers { get set }
    
    /**
     ??????????????????????????????????????????????????????
     ??????????????????????????????????????????????????????????????????????????????
     */
    var internalHandlers: PeerChannelHandlers { get set }
    
    // MARK: - ????????????
    
    /// ???????????????????????????
    var configuration: Configuration { get }
    
    /// ?????????????????? ID ?????????????????????????????????????????????
    var clientId: String? { get }
    
    /// ?????? ID ?????????????????????????????????????????????
    var connectionId: String? { get }
    
    /// ??????????????????????????????????????????????????????????????????????????? 1 ????????????
    var streams: [MediaStream] { get }
    
    /// ????????????
    var state: ConnectionState { get }
    
    /// ??????????????????????????????
    var signalingChannel: SignalingChannel { get }
    
    // MARK: - ???????????????????????????
    
    /**
     ?????????????????????
     
     - parameter configuration: ???????????????????????????
     - parameter signalingChannel: ??????????????????????????????????????????
     */
    init(configuration: Configuration, signalingChannel: SignalingChannel)
    
    // MARK: - ??????
    
    /**
     ?????????????????????????????????
     
     - parameter handler: ????????????????????????????????????????????????
     - parameter error: (?????????????????????) ?????????
     */
    func connect(handler: @escaping (_ error: Error?) -> Void)
    
    /**
     ???????????????????????????
     
     - parameter error: ??????????????????????????????????????????
     */
    func disconnect(error: Error?)
    
}

// MARK: -

class BasicPeerChannel: PeerChannel {
    
    var handlers: PeerChannelHandlers = PeerChannelHandlers()
    var internalHandlers: PeerChannelHandlers = PeerChannelHandlers()
    let configuration: Configuration
    let signalingChannel: SignalingChannel
    
    private(set) var streams: [MediaStream] = []
    private(set) var iceCandidates: [ICECandidate] = []
    
    var clientId: String? {
        get { return context.clientId }
    }
    
    var connectionId: String? {
        context.connectionId
    }
    
    var state: ConnectionState {
        get {
            switch context.state {
            case .disconnecting:
                return .disconnecting
            case .disconnected:
                return .disconnected
            case .connected:
                return .connected
            default:
                return .connecting
            }
        }
    }
    
    private var context: BasicPeerChannelContext!
    
    required init(configuration: Configuration, signalingChannel: SignalingChannel) {
        self.configuration = configuration
        self.signalingChannel = signalingChannel
        context = BasicPeerChannelContext(channel: self)
    }
    
    func add(stream: MediaStream) {
        streams.append(stream)
        Logger.debug(type: .peerChannel, message: "call onAddStream")
        internalHandlers.onAddStream?(stream)
        handlers.onAddStream?(stream)
    }
    
    func remove(streamId: String) {
        let stream = streams.first { stream in stream.streamId == streamId }
        if let stream = stream {
            remove(stream: stream)
        }
    }
    
    func remove(stream: MediaStream) {
        streams = streams.filter { each in each.streamId != stream.streamId }
        Logger.debug(type: .peerChannel, message: "call onRemoveStream")
        internalHandlers.onRemoveStream?(stream)
        handlers.onRemoveStream?(stream)
    }
    
    func add(iceCandidate: ICECandidate) {
        iceCandidates.append(iceCandidate)
    }
    
    func remove(iceCandidate: ICECandidate) {
        iceCandidates = iceCandidates.filter { each in each == iceCandidate }
    }
    
    func connect(handler: @escaping (Error?) -> Void) {
        context.connect(handler: handler)
    }
    
    func disconnect(error: Error?) {
        context.disconnect(error: error)
    }
    
    fileprivate func terminateAllStreams() {
        for stream in streams {
            stream.terminate()
        }
        streams.removeAll()
        // Do not call `handlers.onRemoveStreamHandler` here
        // This method is meant to be called only when disconnection cleanup
    }
    
}

// MARK: -

class BasicPeerChannelContext: NSObject, RTCPeerConnectionDelegate {
    
    enum State {
        case connecting
        case waitingOffer
        case waitingComplete
        case waitingUpdateComplete
        case connected
        case disconnecting
        case disconnected
    }
    
    final class Lock {
        
        weak var context: BasicPeerChannelContext?
        var count: Int = 0
        var shouldDisconnect: (Bool, Error?) = (false, nil)
        
        func waitDisconnect(error: Error?) {
            if count == 0 {
                context?.basicDisconnect(error: error)
            } else {
                shouldDisconnect = (true, error)
            }
        }
        
        func lock() {
            count += 1
        }
        
        func unlock() {
            if count <= 0 {
                fatalError("count is already 0")
            }
            count -= 1
            if count == 0 {
                disconnect()
            }
        }
        
        func disconnect() {
            switch shouldDisconnect {
            case (true, let error):
                shouldDisconnect = (false, nil)
                if let context = context {
                    if context.state != .disconnecting && context.state != .disconnected {
                        context.basicDisconnect(error: error)
                    }
                }
            default:
                break
            }
        }
    }
    
    weak var channel: BasicPeerChannel!
    var state: State = .disconnected
    
    // connect() ????????????????????????????????????????????? nil ???????????????????????????
    // connect() ???????????? nil ????????????????????????????????????
    var nativeChannel: RTCPeerConnection!
    var internalState: PeerChannelInternalState!
    
    var signalingChannel: SignalingChannel {
        get { return channel.signalingChannel }
    }
    
    var webRTCConfiguration: WebRTCConfiguration!
    var clientId: String?
    var connectionId: String?

    var configuration: Configuration {
        get { return channel.configuration }
    }
    
    var onConnectHandler: ((Error?) -> Void)?
    
    var isAudioInputInitialized: Bool = false
    
    private var lock: Lock
    
    private var offerEncodings: [SignalingOffer.Encoding]?

    init(channel: BasicPeerChannel) {
        self.channel = channel
        lock = Lock()
        super.init()
        lock.context = self
        
        signalingChannel.internalHandlers.onDisconnect = { error in
            self.disconnect(error: error)
        }
        
        signalingChannel.internalHandlers.onReceive = handle
    }
    
    func connect(handler: @escaping (Error?) -> Void) {
        if channel.state.isConnecting {
            handler(SoraError.connectionBusy(reason:
                "PeerChannel is already connected"))
            return
        }
        
        Logger.debug(type: .peerChannel, message: "try connecting")
        Logger.debug(type: .peerChannel, message: "try connecting to signaling channel")
        
        self.webRTCConfiguration = channel.configuration.webRTCConfiguration
        nativeChannel = NativePeerChannelFactory.default
            .createNativePeerChannel(configuration: webRTCConfiguration,
                                     constraints: webRTCConfiguration.constraints,
                                     delegate: self)
        guard nativeChannel != nil else {
            let message = "createNativePeerChannel failed"
            Logger.debug(type: .peerChannel, message: message)
            handler(SoraError.peerChannelError(reason: message))
            return
        }
        
        // ?????????????????? finishConnecting() ??????????????????
        lock.lock()
        onConnectHandler = handler

        // ??????????????????????????????????????????????????? RTCPeerConnection ??????????????? WrapperVideoEncoderFactory ??????????????????????????????
        // ????????? (??????????????????) ???????????????????????????????????????????????????????????????????????????????????????????????????????????????
        WrapperVideoEncoderFactory.shared.simulcastEnabled = configuration.simulcastEnabled || (!Sora.isSpotlightLegacyEnabled && configuration.spotlightEnabled == .enabled)

        internalState = PeerChannelInternalState(
            signalingState: PeerChannelSignalingState(
                nativeValue: nativeChannel.signalingState),
            iceConnectionState: ICEConnectionState(
                nativeValue: nativeChannel.iceConnectionState),
            iceGatheringState: ICEGatheringState(
                nativeValue: nativeChannel.iceGatheringState))
        internalState.onCompleteHandler = finishConnecting
        
        internalState.onDisconnectHandler = {
            self.disconnect(error: nil)
        }
        
        signalingChannel.connect(handler: sendConnectMessage)
        state = .connecting
    }
    
    func sendConnectMessage(error: Error?) {
        if let error = error {
            Logger.error(type: .peerChannel,
                         message: "failed connecting to signaling channel (\(error.localizedDescription))")
            onConnectHandler?(error)
            onConnectHandler = nil
            return
        }
        
        if configuration.isSender {
            Logger.debug(type: .peerChannel, message: "try creating offer SDP")
            NativePeerChannelFactory.default
                .createClientOfferSDP(configuration: webRTCConfiguration,
                                      constraints: webRTCConfiguration.constraints)
                { sdp, sdpError in
                    if let error = sdpError {
                        Logger.debug(type: .peerChannel,
                                     message: "failed to create offer SDP (\(error.localizedDescription))")
                    } else {
                        Logger.debug(type: .peerChannel,
                                     message: "did create offer SDP")
                    }
                    self.sendConnectMessage(with: sdp, error: error)
            }
        } else {
            self.sendConnectMessage(with: nil, error: nil)
        }
    }
    
    func sendConnectMessage(with sdp: String?, error: Error?) {
        if error != nil {
            Logger.error(type: .peerChannel,
                         message: "failed connecting to signaling channel (\(error!.localizedDescription))")
            disconnect(error: SoraError.peerChannelError(
                reason: "failed connecting to signaling channel"))
            return
        }
        
        Logger.debug(type: .peerChannel,
                     message: "did connect to signaling channel")
        
        state = .waitingOffer
        var role: SignalingRole!
        var multistream = configuration.multistreamEnabled || configuration.spotlightEnabled == .enabled
        switch configuration.role {
        case .publisher, .sendonly:
            role = .sendonly
        case .subscriber, .recvonly:
            role = .recvonly
        case .group, .sendrecv:
            role = .sendrecv
            multistream = true
        case .groupSub:
            role = .recvonly
            multistream = true
        }
        
        let soraClient = "Sora macOS SDK \(SDKInfo.shared.version) (\(SDKInfo.shared.shortRevision))"
        
        var webRTCVersion: String?
        if let info = WebRTCInfo.load() {
            webRTCVersion = "Shiguredo-build \(info.version) (\(info.version).\(info.commitPosition).\(info.maintenanceVersion) \(info.shortRevision))"
        }
        
        let simulcast = configuration.simulcastEnabled || (!Sora.isSpotlightLegacyEnabled && configuration.spotlightEnabled == .enabled)
        let connect = SignalingConnect(
            role: role,
            channelId: configuration.channelId,
            clientId: configuration.clientId,
            metadata: configuration.signalingConnectMetadata,
            notifyMetadata: configuration.signalingConnectNotifyMetadata,
            sdp: sdp,
            multistreamEnabled: multistream,
            videoEnabled: configuration.videoEnabled,
            videoCodec: configuration.videoCodec,
            videoBitRate: configuration.videoBitRate,
            // WARN: video only ?????? answer ??????????????????????????????
            // ?????????????????????????????????????????????????????????
            // audioEnabled: config.audioEnabled,
            audioEnabled: true,
            audioCodec: configuration.audioCodec,
            audioBitRate: configuration.audioBitRate,
            spotlightEnabled: configuration.spotlightEnabled,
            spotlightNumber: configuration.spotlightNumber,
            spotlightFocusRid: configuration.spotlightFocusRid,
            spotlightUnfocusRid: configuration.spotlightUnfocusRid,
            simulcastEnabled: simulcast,
            simulcastRid: configuration.simulcastRid,
            soraClient: soraClient,
            webRTCVersion: webRTCVersion,
            environment: DeviceInfo.current.description)
        Logger.debug(type: .peerChannel, message: "send connect")
        signalingChannel.send(message: Signaling.connect(connect))
    }
    
    func initializeSenderStream() {
        Logger.debug(type: .peerChannel,
                     message: "initialize sender stream")
        
        let nativeStream = NativePeerChannelFactory.default
            .createNativeSenderStream(streamId: configuration.publisherStreamId,
                                         videoTrackId:
                configuration.videoEnabled ? configuration.publisherVideoTrackId: nil,
                                         audioTrackId:
                configuration.audioEnabled ? configuration.publisherAudioTrackId : nil,
                                         constraints: webRTCConfiguration.constraints)
        let stream = BasicMediaStream(peerChannel: channel,
                                      nativeStream: nativeStream)
        if configuration.videoEnabled {
            switch configuration.videoCapturerDevice {
            case .camera(let settings):
                Logger.debug(type: .peerChannel,
                             message: "initialize video capture device")
                // ???????????????????????????????????????????????????????????????????????????????????????CameraVideoCapturer?????????????????????????????????????????????
                if CameraVideoCapturer.shared.isRunning {
                    CameraVideoCapturer.shared.stop()
                }
                CameraVideoCapturer.shared.settings = settings
                CameraVideoCapturer.shared.start()
                stream.videoCapturer = CameraVideoCapturer.shared
            case .custom:
                // ????????????????????????????????????????????????????????????????????????????????????
                // ?????????????????????????????????VideoCapturer??????????????????????????????????????????
                break
            }
        }
        
        if let track = stream.nativeVideoTrack {
            nativeChannel.add(track,
                              streamIds: [stream.nativeStream.streamId])
        }
        if let track = stream.nativeAudioTrack {
            nativeChannel.add(track,
                              streamIds: [stream.nativeStream.streamId])
        }
        channel.add(stream: stream)
        Logger.debug(type: .peerChannel,
                     message: "create publisher stream (id: \(configuration.publisherStreamId))")
    }
    
    /** `initializeSenderStream()` ????????????????????????????????????????????????????????????????????????????????????????????? */
    func terminateSenderStream() {
        if configuration.videoEnabled {
            switch configuration.videoCapturerDevice {
            case .camera(settings: let settings):
                // ??????????????????????????????????????????
                // ????????????????????????????????????????????????????????????????????????????????????????????????????????????
                if settings.canStop {
                    CameraVideoCapturer.shared.stop()
                }
            case .custom:
                // ????????????????????????????????????????????????????????????????????????????????????
                // ?????????????????????????????????VideoCapturer??????????????????????????????????????????
                break
            }
        }
    }
    
    func createAnswer(isSender: Bool,
                      offer: String,
                      constraints: RTCMediaConstraints,
                      handler: @escaping (String?, Error?) -> Void) {
        Logger.debug(type: .peerChannel, message: "try create answer")
        Logger.debug(type: .peerChannel, message: offer)
        
        Logger.debug(type: .peerChannel, message: "try setting remote description")
        let offer = RTCSessionDescription(type: .offer, sdp: offer)
        nativeChannel.setRemoteDescription(offer) { error in
            guard error == nil else {
                Logger.debug(type: .peerChannel,
                             message: "failed setting remote description: (\(error!.localizedDescription)")
                handler(nil, error)
                return
            }
            Logger.debug(type: .peerChannel, message: "did set remote description")
            Logger.debug(type: .peerChannel, message: "\(offer.sdpDescription)")
            
            if isSender {
                self.initializeSenderStream()
                self.updateSenderOfferEncodings()
            }
            
            Logger.debug(type: .peerChannel, message: "try creating native answer")
            self.nativeChannel.answer(for: constraints) { answer, error in
                guard error == nil else {
                    Logger.debug(type: .peerChannel,
                                 message: "failed creating native answer (\(error!.localizedDescription)")
                    handler(nil, error)
                    return
                }
                Logger.debug(type: .peerChannel, message: "did create answer")
                
                Logger.debug(type: .peerChannel, message: "try setting local description")
                self.nativeChannel.setLocalDescription(answer!) { error in
                    guard error == nil else {
                        Logger.debug(type: .peerChannel,
                                     message: "failed setting local description")
                        handler(nil, error)
                        return
                    }
                    Logger.debug(type: .peerChannel,
                                 message: "did set local description")
                    Logger.debug(type: .peerChannel,
                                 message: "\(answer!.sdpDescription)")
                    Logger.debug(type: .peerChannel,
                                 message: "did create answer")
                    handler(answer!.sdp, nil)
                }
            }
        }
    }
        
    private func updateSenderOfferEncodings() {
        guard let oldEncodings = offerEncodings else {
            return
        }
        Logger.debug(type: .peerChannel, message: "update sender offer encodings")
        for sender in nativeChannel.senders {
            sender.updateOfferEncodings(oldEncodings)
        }
    }
    
    func createAndSendAnswer(offer: SignalingOffer) {
        Logger.debug(type: .peerChannel, message: "try sending answer")
        state = .waitingComplete
        offerEncodings = offer.encodings
        
        if let config = offer.configuration {
            Logger.debug(type: .peerChannel, message: "update configuration")
            Logger.debug(type: .peerChannel, message: "ICE server infos => \(config.iceServerInfos)")
            Logger.debug(type: .peerChannel, message: "ICE transport policy => \(config.iceTransportPolicy)")
            webRTCConfiguration.iceServerInfos = config.iceServerInfos
            webRTCConfiguration.iceTransportPolicy = config.iceTransportPolicy
            nativeChannel.setConfiguration(webRTCConfiguration.nativeValue)
        }
        
        lock.lock()
        createAnswer(isSender: configuration.isSender,
                     offer: offer.sdp,
                     constraints: webRTCConfiguration.nativeConstraints)
        { sdp, error in
            guard error == nil else {
                Logger.error(type: .peerChannel,
                             message: "failed to create answer (\(error!.localizedDescription))")
                self.lock.unlock()
                self.disconnect(error: SoraError
                    .peerChannelError(reason: "failed to create answer"))
                return
            }
            
            let answer = SignalingAnswer(sdp: sdp!)
            self.signalingChannel.send(message: Signaling.answer(answer))
            self.lock.unlock()
            Logger.debug(type: .peerChannel, message: "did send answer")
        }
    }
    
    
    func createAndSendUpdateAnswer(forOffer offer: String) {
        Logger.debug(type: .peerChannel, message: "create and send update-answer")
        lock.lock()
        state = .waitingUpdateComplete
        createAnswer(isSender: false,
                     offer: offer,
                     constraints: webRTCConfiguration.nativeConstraints)
        { answer, error in
            guard error == nil else {
                Logger.error(type: .peerChannel,
                             message: "failed to create update-answer (\(error!.localizedDescription)")
                self.lock.unlock()
                self.disconnect(error: SoraError
                    .peerChannelError(reason: "failed to create update-answer"))
                return
            }
            
            let message = Signaling.update(SignalingUpdate(sdp: answer!))
            self.signalingChannel.send(message: message)
            
            if (self.configuration.isSender) {
                self.updateSenderOfferEncodings()
            }
            
            // Answer ???????????? RTCPeerConnection ????????????????????????????????????
            // Answer ???????????????????????????????????????
            self.state = .connected
            
            Logger.debug(type: .peerChannel, message: "call onUpdate")
            self.channel.internalHandlers.onUpdate?(answer!)
            self.channel.handlers.onUpdate?(answer!)
            
            self.lock.unlock()
        }
    }
    
    func handle(signaling: Signaling) {
        Logger.debug(type: .mediaStream, message: "handle signaling => \(signaling.typeName())")
        switch signaling {
        case .offer(let offer):
            clientId = offer.clientId
            connectionId = offer.connectionId
            createAndSendAnswer(offer: offer)
            
        case .update(let update):
            if configuration.isMultistream {
                createAndSendUpdateAnswer(forOffer: update.sdp)
            }
            
        case .ping(let ping):
            let pong = SignalingPong()
            if ping.statisticsEnabled == true {
//                nativeChannel.statistics { report in
//                    var json: [String: Any] = ["type": "pong"]
//                    let stats = Statistics(contentsOf: report)
//                    json["stats"] = stats.jsonObject
//                    do {
//                        let data = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])
//                        if let message = String(data: data, encoding: .utf8) {
//                            self.signalingChannel.send(text: message)
//                        } else {
//                            self.signalingChannel.send(message: .pong(pong))
//                        }
//                    } catch {
//                        self.signalingChannel.send(message: .pong(pong))
//                    }
//                }
                // TODO: ??????pong???????????????
                signalingChannel.send(message: .pong(pong))
            } else {
                signalingChannel.send(message: .pong(pong))
            }
            
        default:
            break
        }
        
        Logger.debug(type: .peerChannel, message: "call onReceiveSignaling")
        channel.internalHandlers.onReceiveSignaling?(signaling)
        channel.handlers.onReceiveSignaling?(signaling)
    }
    
    func finishConnecting() {
        Logger.debug(type: .peerChannel, message: "did connect")
        Logger.debug(type: .peerChannel,
                     message: "media streams = \(channel.streams.count)")
        Logger.debug(type: .peerChannel,
                     message: "native senders = \(nativeChannel.senders.count)")
        Logger.debug(type: .peerChannel,
                     message: "native receivers = \(nativeChannel.receivers.count)")
        state = .connected
        
        if onConnectHandler != nil {
            Logger.debug(type: .peerChannel, message: "call connect(handler:)")
            onConnectHandler!(nil)
            onConnectHandler = nil
        }
        lock.unlock()
    }
    
    func disconnect(error: Error?) {
        switch state {
        case .disconnecting, .disconnected:
            break
        default:
            Logger.debug(type: .peerChannel, message: "wait to disconnect")
            lock.waitDisconnect(error: error)
        }
    }
    
    func basicDisconnect(error: Error?) {
        Logger.debug(type: .peerChannel, message: "try disconnecting")
        if let error = error {
            Logger.error(type: .peerChannel,
                         message: "error: \(error.localizedDescription)")
        }
        
        state = .disconnecting
        
        if configuration.isSender {
            terminateSenderStream()
        }
        channel.terminateAllStreams()
        nativeChannel.close()
        
        signalingChannel.send(message: Signaling.disconnect)
        signalingChannel.disconnect(error: error)
        
        state = .disconnected
        
        Logger.debug(type: .peerChannel, message: "call onDisconnect")
        channel.internalHandlers.onDisconnect?(error)
        channel.handlers.onDisconnect?(error)
        
        if onConnectHandler != nil {
            Logger.debug(type: .peerChannel, message: "call connect(handler:)")
            onConnectHandler!(error)
            onConnectHandler = nil
        }
        
        Logger.debug(type: .peerChannel, message: "did disconnect")
    }
    
    // MARK: - RTCPeerConnectionDelegate
    
    func peerConnection(_ nativePeerConnection: RTCPeerConnection,
                        didChange stateChanged: RTCSignalingState) {
        let newState = PeerChannelSignalingState(nativeValue: stateChanged)
        Logger.debug(type: .peerChannel,
                     message: "changed signaling state to \(newState)")
        internalState.signalingState = newState
    }
    
    func peerConnection(_ nativePeerConnection: RTCPeerConnection,
                        didAdd stream: RTCMediaStream) {
        Logger.debug(type: .peerChannel,
                     message: "try add a stream (id: \(stream.streamId))")
        for cur in channel.streams {
            if cur.streamId == stream.streamId {
                Logger.debug(type: .peerChannel,
                             message: "stream already exists")
                return
            }
        }
        
        if channel.configuration.isMultistream &&
            stream.streamId == clientId {
            Logger.debug(type: .peerChannel,
                         message: "stream already exists in multistream")
            return
        }
        
        Logger.debug(type: .peerChannel, message: "add a stream")
        stream.audioTracks.first?.source.volume = MediaStreamAudioVolume.max
        
        // WARN: connect ????????????????????? audio=false ???????????? answer ?????????????????????????????????
        // ?????????????????????????????????????????????????????????
        if !configuration.audioEnabled {
            Logger.debug(type: .peerChannel, message: "disable audio tracks")
            let tracks = stream.audioTracks
            for track in tracks {
                track.source.volume = 0
                stream.removeAudioTrack(track)
            }
        }
        
        let stream = BasicMediaStream(peerChannel: self.channel,
                                      nativeStream: stream)
        channel.add(stream: stream)
    }
    
    func peerConnection(_ nativePeerConnection: RTCPeerConnection,
                        didRemove stream: RTCMediaStream) {
        Logger.debug(type: .peerChannel,
                     message: "removed a media stream (id: \(stream.streamId))")
        channel.remove(streamId: stream.streamId)
    }
    
    func peerConnectionShouldNegotiate(_ nativePeerConnection: RTCPeerConnection) {
        Logger.debug(type: .peerChannel, message: "required negatiation")
    }
    
    func peerConnection(_ nativePeerConnection: RTCPeerConnection,
                        didChange newState: RTCIceConnectionState) {
        let newState = ICEConnectionState(nativeValue: newState)
        Logger.debug(type: .peerChannel,
                     message: "changed ICE connection state to \(newState)")
        internalState.iceConnectionState = newState
    }
    
    func peerConnection(_ nativePeerConnection: RTCPeerConnection,
                        didChange newState: RTCIceGatheringState) {
        let newState = ICEGatheringState(nativeValue: newState)
        Logger.debug(type: .peerChannel,
                     message: "changed ICE gathering state to \(newState)")
        internalState.iceGatheringState = newState
    }
    
    func peerConnection(_ nativePeerConnection: RTCPeerConnection,
                        didGenerate candidate: RTCIceCandidate) {
        Logger.debug(type: .peerChannel,
                     message: "generated ICE candidate \(candidate)")
        let candidate = ICECandidate(nativeICECandidate: candidate)
        channel.add(iceCandidate: candidate)
        let message = Signaling.candidate(SignalingCandidate(candidate: candidate))
        signalingChannel.send(message: message)
    }
    
    func peerConnection(_ nativePeerConnection: RTCPeerConnection,
                        didRemove candidates: [RTCIceCandidate]) {
        Logger.debug(type: .peerChannel,
                     message: "removed ICE candidate \(candidates)")
        let candidates = channel.iceCandidates.filter {
            old in
            for candidate in candidates {
                let remove = ICECandidate(nativeICECandidate: candidate)
                if old == remove {
                    return true
                }
            }
            return false
        }
        for candidate in candidates {
            channel.remove(iceCandidate: candidate)
        }
    }
    
    // NOTE: Sora ????????????????????????????????????
    func peerConnection(_ nativePeerConnection: RTCPeerConnection,
                        didOpen dataChannel: RTCDataChannel) {
        Logger.debug(type: .peerChannel, message: "opened data channel (ignored)")
        // ???????????????
    }
    
}

extension RTCRtpSender {
    
    func updateOfferEncodings(_ encodings: [SignalingOffer.Encoding]) {
        Logger.debug(type: .peerChannel, message: "update offer encodings for sender => \(senderId)")
        
        // paramaters ??????????????????????????????????????????????????????????????????????????? parameters ?????????????????????
        let newParameters = parameters // ??????????????????
        for oldEncoding in newParameters.encodings {
            Logger.debug(type: .peerChannel, message: "update encoding => \(ObjectIdentifier(oldEncoding))")
            for encoding in encodings {
                guard oldEncoding.rid == encoding.rid else {
                    continue
                }
                
                if let rid = encoding.rid {
                    Logger.debug(type: .peerChannel, message: "rid => \(rid)")
                    oldEncoding.rid = rid
                }
                
                Logger.debug(type: .peerChannel, message: "active => \(encoding.active)")
                oldEncoding.isActive = encoding.active
                Logger.debug(type: .peerChannel, message: "old active => \(oldEncoding.isActive)")

                if let value = encoding.maxFramerate {
                    Logger.debug(type: .peerChannel, message: "maxFramerate:  \(value)")
                    oldEncoding.maxFramerate = NSNumber(floatLiteral: value)
                }
                
                if let value = encoding.maxBitrate {
                    Logger.debug(type: .peerChannel, message: "maxBitrate: \(value))")
                    oldEncoding.maxBitrateBps = NSNumber(integerLiteral: value)
                }
                
                if let value = encoding.scaleResolutionDownBy {
                    Logger.debug(type: .peerChannel, message: "scaleResolutionDownBy: \(value))")
                    oldEncoding.scaleResolutionDownBy = NSNumber(value: value)
                }
                
                break
            }
        }
        
        self.parameters = newParameters
    }
}
