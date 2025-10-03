//
//  WebSocketServer.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-28.
//

import Foundation
import UniformTypeIdentifiers
#if canImport(MobileCoreServices)
import MobileCoreServices
#endif
import UserNotifications
import Swifter
internal import Combine
import CryptoKit

enum WebSocketStatus {
    case stopped
    case starting
    case started(port: UInt16, ip: String?)
    case failed(error: String)
}

class WebSocketServer: ObservableObject {
    static let shared = WebSocketServer()

    private var server = HttpServer()
    private var activeSessions: [WebSocketSession] = []
    @Published var symmetricKey: SymmetricKey?

    @Published var localPort: UInt16?
    @Published var localIPAddress: String?

    @Published var connectedDevice: Device?
    @Published var notifications: [Notification] = []
    @Published var deviceStatus: DeviceStatus?

    private var lastKnownIP: String?
    private var networkMonitorTimer: Timer?
    private let networkCheckInterval: TimeInterval = 10.0 // seconds

    // Incoming file transfers (Android -> Mac) — keep only IO here; state lives in AppState
    private struct IncomingFileIO {
        var tempUrl: URL
        var fileHandle: FileHandle?
    }
    private var incomingFiles: [String: IncomingFileIO] = [:]
    private var incomingFilesChecksum: [String: String] = [:]
    // Outgoing transfer ack tracking
    private var outgoingAcks: [String: Set<Int>] = [:]
    
    // Serial queue to protect access to outgoingAcks from multiple threads
    private let outgoingAckQueue = DispatchQueue(label: "com.airsync.websocket.outgoing-ack-queue")

    private let maxChunkRetries = 3
    private let ackWaitMs: UInt32 = 2000 // 2s

    private var lastKnownAdapters: [(name: String, address: String)] = []
    // Track last adapter selection we logged to avoid repetitive logs
    private var lastLoggedSelectedAdapter: (name: String, address: String)? = nil

    init() {
        loadOrGenerateSymmetricKey()
        setupWebSocket()
        // Request notification permission so we can show incoming file alerts
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let err = error {
                print("[websocket] Notification auth error: \(err)")
            } else {
                print("[websocket] Notification permission granted: \(granted)")
            }
        }
    }

    func start(port: UInt16 = Defaults.serverPort) {
        DispatchQueue.main.async {
            AppState.shared.webSocketStatus = .starting
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            do {
                try self.server.start(port)
                let ip = self.getLocalIPAddress(adapterName: AppState.shared.selectedNetworkAdapterName)

                DispatchQueue.main.async {
                    self.localPort = port
                    self.localIPAddress = ip
                    AppState.shared.webSocketStatus = .started(port: port, ip: ip)

                    self.lastKnownIP = ip
                }
                print("[websocket] WebSocket server started at ws://\(ip ?? "unknown"):\(port)/socket)")

                self.startNetworkMonitoring()
            } catch {
                DispatchQueue.main.async {
                    AppState.shared.webSocketStatus = .failed(error: "\(error)")
                }
                print("[websocket] Failed to start WebSocket server: \(error)")
            }
        }
    }





    func stop() {
        server.stop()
        activeSessions.removeAll()
        DispatchQueue.main.async {
            AppState.shared.webSocketStatus = .stopped
        }
        stopNetworkMonitoring()
    }



    func sendDisconnectRequest() {
        let message = """
    {
        "type": "disconnectRequest",
        "data": {}
    }
    """
        AppState.shared.sendMessage(message)
    }


    private func setupWebSocket() {
        server["/socket"] = websocket(
            text: { [weak self] session, text in
                guard let self = self else { return }

                // Step 1: Decrypt the message
                let decryptedText: String
                if let key = self.symmetricKey {
                    decryptedText = decryptMessage(text, using: key) ?? ""
                } else {
                    decryptedText = text
                }

                let truncated = decryptedText.count > 300
                ? decryptedText.prefix(300) + "..."
                : decryptedText
                print("[websocket] [received] \n\(truncated)")


                // Step 2: Decode JSON and handle
                if let data = decryptedText.data(using: .utf8) {
                    do {
                        let message = try JSONDecoder().decode(Message.self, from: data)
                        DispatchQueue.main.async {
                            self.handleMessage(message)
                        }
                    } catch {
                        print("[websocket] WebSocket JSON decode failed: \(error)")
                    }
                }
            },

            connected: { [weak self] session in
                print("[websocket] Device connected")
                self?.activeSessions.append(session)
            },
            disconnected: { [weak self] session in
                guard let self = self else { return }
                print("[websocket] Device disconnected")

                self.activeSessions.removeAll(where: { $0 === session })

                // Only call disconnectDevice if no other sessions remain
                if self.activeSessions.isEmpty {
                    DispatchQueue.main.async {
                        AppState.shared.disconnectDevice()
                    }
                }
            }
        )

        server["/video"] = websocket(
            binary: { [weak self] session, data in
                self?.handleVideoData(data)
            }
        )
    }

    private func handleVideoData(_ data: [UInt8]) {
        MirroringManager.shared.handleVideoFrame(data: Data(data))
    }

    /// Handles a raw, unencrypted message string, typically from a non-WebSocket source like Bluetooth.
    func handleRawBluetoothMessage(_ text: String) {
        let truncated = text.count > 300
        ? text.prefix(300) + "..."
        : text
        print("[bluetooth-bridge] [received] \n\(truncated)")

        if let data = text.data(using: .utf8) {
            do {
                let message = try JSONDecoder().decode(Message.self, from: data)
                DispatchQueue.main.async {
                    self.handleMessage(message)
                }
            } catch {
                print("[bluetooth-bridge] JSON decode failed: \(error)")
            }
        }
    }

    // MARK: - Local IP handling

    func getLocalIPAddress(adapterName: String?) -> String? {
        let adapters = getAvailableNetworkAdapters()

        if let adapterName = adapterName {
            if let exact = adapters.first(where: { $0.name == adapterName }) {
                // Log only when selection changes
                if lastLoggedSelectedAdapter?.name != exact.name || lastLoggedSelectedAdapter?.address != exact.address {
                    print("[websocket] Selected adapter match: \(exact.name) -> \(exact.address)")
                    lastLoggedSelectedAdapter = (exact.name, exact.address)
                }
                return exact.address
            }
            // [quiet] adapter not found can be noisy; keep for debugging
            // print("[websocket] Adapter \(adapterName) not found, falling back")
        }

        // Auto mode
        if adapterName == nil {
            // Priority 1: Wi-Fi/Ethernet (en0, en1, en2…)
            if let primary = adapters.first(where: { $0.name.hasPrefix("en") }) {
                // Log only when selection changes
                if lastLoggedSelectedAdapter?.name != primary.name || lastLoggedSelectedAdapter?.address != primary.address {
                    print("[websocket] Auto-selected network adapter: \(primary.name) -> \(primary.address)")
                    lastLoggedSelectedAdapter = (primary.name, primary.address)
                }
                return primary.address
            }
            // Priority 2: Standard private ranges (192.168, 10.x, 172.16–31)
            if let privateIP = adapters.first(where: { ipIsPrivatePreferred($0.address) }) {
                if lastLoggedSelectedAdapter?.name != privateIP.name || lastLoggedSelectedAdapter?.address != privateIP.address {
                    print("[websocket] Auto-selected private adapter: \(privateIP.name) -> \(privateIP.address)")
                    lastLoggedSelectedAdapter = (privateIP.name, privateIP.address)
                }
                return privateIP.address
            }
            // Priority 3: Any other adapter
            if let any = adapters.first {
                if lastLoggedSelectedAdapter?.name != any.name || lastLoggedSelectedAdapter?.address != any.address {
                    print("[websocket] Auto-selected fallback adapter: \(any.name) -> \(any.address)")
                    lastLoggedSelectedAdapter = (any.name, any.address)
                }
                return any.address
            }
        }

        return nil
    }

    func getAvailableNetworkAdapters() -> [(name: String, address: String)] {
        var adapters: [(String, String)] = []
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil

        if getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr {
            for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
                let interface = ptr.pointee
                let addrFamily = interface.ifa_addr.pointee.sa_family

                if addrFamily == UInt8(AF_INET),
                   let name = String(validatingUTF8: interface.ifa_name) {
                    var addr = interface.ifa_addr.pointee
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    let result = getnameinfo(&addr,
                                             socklen_t(interface.ifa_addr.pointee.sa_len),
                                             &hostname,
                                             socklen_t(hostname.count),
                                             nil,
                                             socklen_t(0),
                                             NI_NUMERICHOST)
                    if result == 0 {
                        let address = String(cString: hostname)
                        if address != "127.0.0.1" {
                            adapters.append((name, address))
                        }
                    }
                }
            }
            freeifaddrs(ifaddr)
        }

        return adapters
    }

    private func ipIsPrivatePreferred(_ ip: String) -> Bool {
        if ip.hasPrefix("192.168.") { return true }
        if ip.hasPrefix("10.") { return true }
        if ip.hasPrefix("172.") {
            let parts = ip.split(separator: ".")
            if parts.count > 1, let second = Int(parts[1]), (16...31).contains(second) {
                return true
            }
        }
        return false
    }



    // MARK: - Message Handling

    func handleMessage(_ message: Message) {
        switch message.type {
        case .device:
            if let dict = message.data.value as? [String: Any],
               let name = dict["name"] as? String,
               let ip = dict["ipAddress"] as? String,
               let port = dict["port"] as? Int {

                let version = dict["version"] as? String ?? "2.0.0"

                AppState.shared.device = Device(
                    name: name,
                    ipAddress: ip,
                    port: port,
                    version: version
                )

                // Accept multiple keys for wallpaper; sanitize and store
                if let rawAny = (dict["wallpaper"] as? String) ?? (dict["deviceWallpaper"] as? String) {
                    var cleaned = rawAny.trimmingCharacters(in: .whitespacesAndNewlines)
                    if let range = cleaned.range(of: "base64,") { cleaned = String(cleaned[range.upperBound...]) }
                    cleaned = cleaned.replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\r", with: "")
                    print("[websocket] Received wallpaper base64 (len=\(cleaned.count))")
                    DispatchQueue.main.async {
                        AppState.shared.currentDeviceWallpaperBase64 = cleaned
                    }
                } else {
                    print("[websocket] No wallpaper provided in device hello; Android may send it later via status or a separate message")
                }

                if (!AppState.shared.adbConnected && AppState.shared.adbEnabled && AppState.shared.isPlus) {
                    ADBConnector.connectToADB(ip: ip)
                }

				// mark first-time pairing
				if UserDefaults.standard.hasPairedDeviceOnce == false {
					UserDefaults.standard.hasPairedDeviceOnce = true
				}
				
				// Send Mac info response to Android
				sendMacInfoResponse()

                // Ask Android for wallpaper explicitly (helps devices that don't include it in hello)
                let request = """
                {
                    "type": "requestWallpaper",
                    "data": {}
                }
                """
                AppState.shared.sendMessage(request)
                print("[websocket] Sent requestWallpaper to device (encrypted/plain)")
                
                // Proactively request health snapshot shortly after connect
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    AppState.shared.requestHealthData()
                }
            }


        case .notification:
            if let dict = message.data.value as? [String: Any],
               let nid = dict["id"] as? String,
               let title = dict["title"] as? String,
               let body = dict["body"] as? String,
               let app = dict["app"] as? String,
               let package = dict["package"] as? String {
                var actions: [NotificationAction] = []
                if let arr = dict["actions"] as? [[String: Any]] {
                    for a in arr {
                        if let name = a["name"] as? String, let typeStr = a["type"] as? String,
                           let t = NotificationAction.ActionType(rawValue: typeStr) {
                            actions.append(NotificationAction(name: name, type: t))
                        }
                    }
                }
                let notif = Notification(title: title, body: body, app: app, nid: nid, package: package, actions: actions)
                DispatchQueue.main.async {
                    AppState.shared.addNotification(notif)
                }
            }
        case .notificationActionResponse:
            if let dict = message.data.value as? [String: Any],
               let id = dict["id"] as? String,
               let action = dict["action"] as? String,
               let success = dict["success"] as? Bool {
                let msg = dict["message"] as? String ?? ""
                print("[websocket] Notification action response id=\(id) action=\(action) success=\(success) message=\(msg)")
            }
        case .notificationAction:
            print("[websocket] Warning: received 'notificationAction' from remote (ignored).")
        case .notificationUpdate:
            if let dict = message.data.value as? [String: Any],
               let nid = dict["id"] as? String {
                if let action = dict["action"] as? String, action.lowercased() == "dismiss" || dict["dismissed"] as? Bool == true {
                    DispatchQueue.main.async {
                        // Remove from in-memory list if present; ignore if not found.
                        let existed = AppState.shared.notifications.contains { $0.nid == nid }
                        if existed {
                            AppState.shared.removeNotificationById(nid)
                        }
                        // Ensure system notification also removed.
                        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [nid])
                    }
                }
            }

        case .status:
            if let dict = message.data.value as? [String: Any],
               let battery = dict["battery"] as? [String: Any],
               let level = battery["level"] as? Int,
               let isCharging = battery["isCharging"] as? Bool,
               let paired = dict["isPaired"] as? Bool,
               let music = dict["music"] as? [String: Any],
               let playing = music["isPlaying"] as? Bool,
               let title = music["title"] as? String,
               let artist = music["artist"] as? String,
               let volume = music["volume"] as? Int,
               let isMuted = music["isMuted"] as? Bool
            {
                let albumArt = (music["albumArt"] as? String) ?? ""
                let likeStatus = (music["likeStatus"] as? String) ?? "none"

                let newStatus = DeviceStatus(
                    battery: .init(level: level, isCharging: isCharging),
                    isPaired: paired,
                    music: .init(
                        isPlaying: playing,
                        title: title,
                        artist: artist,
                        volume: volume,
                        isMuted: isMuted,
                        albumArt: albumArt,
                        likeStatus: likeStatus
                    )
                )
                DispatchQueue.main.async {
                    AppState.shared.status = newStatus
                    // Check for low battery alert
                    if let level = battery["level"] as? Int, let isCharging = battery["isCharging"] as? Bool {
                        self.checkLowBattery(level: level, isCharging: isCharging)
                    }
                }
            }

        case .health:
            if let dict = message.data.value as? [String: Any] {
                let hr = dict["heartRate"] as? Int ?? dict["hr"] as? Int ?? 0
                let steps = dict["steps"] as? Int ?? 0
                let calories = dict["calories"] as? Int ?? 0
                let distance = dict["distance"] as? Double ?? (dict["distanceKm"] as? Double ?? 0.0)
                let sleep = dict["sleepHours"] as? Double ?? (dict["sleep"] as? Double ?? 0.0)

                // Log a concise summary
                print("[health] Received: HR=\(hr) BPM, steps=\(steps), calories=\(calories), distance=\(distance) km, sleep=\(sleep) h")

                DispatchQueue.main.async {
                    HealthDataManager.shared.healthData.heartRate = hr
                    HealthDataManager.shared.healthData.steps = steps
                    HealthDataManager.shared.healthData.calories = calories
                    HealthDataManager.shared.healthData.distance = distance
                    HealthDataManager.shared.healthData.sleepHours = sleep
                }
            }

        case .dismissalResponse:
            if let dict = message.data.value as? [String: Any],
               let id = dict["id"] as? String,
               let success = dict["success"] as? Bool {
                print("[websocket] Dismissal \(success ? "succeeded" : "failed") for notification id: \(id)")
            }

        case .mediaControlResponse:
            if let dict = message.data.value as? [String: Any],
               let action = dict["action"] as? String,
               let success = dict["success"] as? Bool {
                print("[websocket] Media control \(action) \(success ? "succeeded" : "failed")")
            }

        case .volumeControlResponse:
            if let dict = message.data.value as? [String: Any],
                let action = dict["action"] as? String,
                let success = dict["success"] as? Bool {
                let msg = dict["message"] as? String ?? ""
                print("[websocket] Volume control response: \(action) \(success ? "succeeded" : "failed"), message: \(msg)")
            }

        case .appIcons:
            if let dict = message.data.value as? [String: [String: Any]] {
                DispatchQueue.global(qos: .background).async {
                    let incomingPackages = Set(dict.keys)
                    let existingPackages = Set(AppState.shared.androidApps.keys)

                    // Decode & write/update icons
                    for (package, details) in dict {
                        guard let name = details["name"] as? String,
                              let iconBase64 = details["icon"] as? String,
                              let systemApp = details["systemApp"] as? Bool,
                              let listening = details["listening"] as? Bool else { continue }

                        var cleaned = iconBase64
                        if let range = cleaned.range(of: "base64,") { cleaned = String(cleaned[range.upperBound...]) }

                        var iconPath: String? = nil
                        if let data = Data(base64Encoded: cleaned) {
                            let fileURL = appIconsDirectory().appendingPathComponent("\(package).png")
                            do {
                                try data.write(to: fileURL, options: .atomic)
                                iconPath = fileURL.path
                            } catch {
                                print("[websocket] Failed to write icon for \(package): \(error)")
                            }
                        }

                        let app = AndroidApp(
                            packageName: package,
                            name: name,
                            iconUrl: iconPath,
                            listening: listening,
                            systemApp: systemApp
                        )

                        DispatchQueue.main.async {
                            AppState.shared.androidApps[package] = app
                            if let iconPath { AppState.shared.androidApps[package]?.iconUrl = iconPath }
                        }
                    }

                    // Remove apps (and their icon files) that are no longer present on the device
                    let toRemove = existingPackages.subtracting(incomingPackages)
                    if !toRemove.isEmpty {
                        DispatchQueue.main.async {
                            for pkg in toRemove {
                                if let iconPath = AppState.shared.androidApps[pkg]?.iconUrl {
                                    try? FileManager.default.removeItem(atPath: iconPath)
                                }
                                AppState.shared.androidApps.removeValue(forKey: pkg)
                            }
                        }
                    }

                    // Persist updated snapshot
                    DispatchQueue.main.async {
                        AppState.shared.saveAppsToDisk()
                    }
                }
            }


        case .clipboardUpdate:
            if let dict = message.data.value as? [String: Any],
               let text = dict["text"] as? String {
                AppState.shared.updateClipboardFromAndroid(text)
            }

        // File transfer messages (Android -> Mac)
        case .fileTransferInit:
            if let dict = message.data.value as? [String: Any],
               let id = dict["id"] as? String,
               let name = dict["name"] as? String,
               let size = dict["size"] as? Int,
               let mime = dict["mime"] as? String {
                let checksum = dict["checksum"] as? String

                let tempDir = FileManager.default.temporaryDirectory
                let safeName = name.replacingOccurrences(of: "/", with: "_")
                let tempFile = tempDir.appendingPathComponent("incoming_\(id)_\(safeName)")
                FileManager.default.createFile(atPath: tempFile.path, contents: nil, attributes: nil)
                let handle = try? FileHandle(forWritingTo: tempFile)

                let io = IncomingFileIO(tempUrl: tempFile, fileHandle: handle)
                incomingFiles[id] = io
                if let checksum = checksum {
                    incomingFilesChecksum[id] = checksum
                }
                // Start tracking incoming transfer in AppState
                AppState.shared.startIncomingTransfer(id: id, name: name, size: size, mime: mime)
            }

        case .fileChunk:
            if let dict = message.data.value as? [String: Any],
               let id = dict["id"] as? String,
               let chunkBase64 = dict["chunk"] as? String,
               let io = incomingFiles[id],
               let data = Data(base64Encoded: chunkBase64) {

                io.fileHandle?.seekToEndOfFile()
                io.fileHandle?.write(data)
                // Update incoming progress in AppState (increment)
                let prev = AppState.shared.transfers[id]?.bytesTransferred ?? 0
                let newBytes = prev + data.count
                AppState.shared.updateIncomingProgress(id: id, receivedBytes: newBytes)
            }

        case .fileChunkAck:
            if let dict = message.data.value as? [String: Any],
               let id = dict["id"] as? String,
               let index = dict["index"] as? Int {
                outgoingAckQueue.async {
                    var set = self.outgoingAcks[id] ?? []
                    set.insert(index)
                    self.outgoingAcks[id] = set
                    print("[websocket] (file-transfer) Received ack for id=\(id) index=\(index) totalAcked=\(set.count)")
                }
            }

        case .fileTransferComplete:
                if let dict = message.data.value as? [String: Any],
                    let id = dict["id"] as? String,
                    let state = incomingFiles[id] {
                    state.fileHandle?.closeFile()

                    // Resolve a name for notifications and final filename. Prefer AppState metadata; fall back to temp filename.
                    let resolvedName = AppState.shared.transfers[id]?.name ?? state.tempUrl.lastPathComponent

                    // Verify checksum if present (support MD5 32-hex and SHA-256 64-hex)
                    if let expected = incomingFilesChecksum[id] {
                        if let fileData = try? Data(contentsOf: state.tempUrl) {
                            let computed: String
                            switch expected.count {
                            case 32: // MD5
                                computed = FileTransferProtocol.md5Hex(fileData)
                            case 64: // SHA-256
                                computed = FileTransferProtocol.sha256Hex(fileData)
                            default:
                                // Fallback to MD5 for legacy clients
                                computed = FileTransferProtocol.md5Hex(fileData)
                            }

                            if computed != expected {
                                print("[websocket] (file-transfer) Checksum mismatch for incoming file id=\(id), expected=\(expected), computed=\(computed)")
                                // Post notification about checksum mismatch via AppState util
                                AppState.shared.postNativeNotification(
                                    id: "incoming_file_\(id)_mismatch",
                                    appName: "AirSync",
                                    title: "Received: \(resolvedName)",
                                    body: "Saved to Downloads (checksum mismatch)"
                                )
                            }
                        }
                        incomingFilesChecksum.removeValue(forKey: id)
                    }

                    // Move to Downloads
                    if let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
                        do {
                            let finalDest = downloads.appendingPathComponent(resolvedName)
                            if FileManager.default.fileExists(atPath: finalDest.path) {
                                try FileManager.default.removeItem(at: finalDest)
                            }
                            try FileManager.default.moveItem(at: state.tempUrl, to: finalDest)

                            // Optionally: show a user notification (simple print for now)
                            print("[websocket] (file-transfer) Saved incoming file to \(finalDest.path)")

                            // Mark as completed in AppState and post notification via AppState util
                            AppState.shared.completeIncoming(id: id, verified: nil)
                            AppState.shared.postNativeNotification(
                                id: "incoming_file_\(id)",
                                appName: "AirSync",
                                title: "Received: \(resolvedName)",
                                body: "Saved to Downloads"
                            )
                        } catch {
                            print("[websocket] (file-transfer) Failed to move incoming file: \(error)")
                        }
                    }

                    incomingFiles.removeValue(forKey: id)
            }
        case .transferVerified:
            if let dict = message.data.value as? [String: Any],
               let id = dict["id"] as? String,
               let verified = dict["verified"] as? Bool {
                print("[websocket] (file-transfer) Received transferVerified for id=\(id) verified=\(verified)")
                // Update AppState and show a confirmation notification via AppState util
                AppState.shared.completeOutgoingVerified(id: id, verified: verified)
                AppState.shared.postNativeNotification(
                    id: "transfer_verified_\(id)",
                    appName: "AirSync",
                    title: "Transfer verified",
                    body: verified ? "Receiver verified the file checksum" : "Receiver reported checksum mismatch"
                )
            }

        case .macMediaControl:
            if let dict = message.data.value as? [String: Any],
               let action = dict["action"] as? String {
                print("[websocket] Received Mac media control: \(action)")
                handleMacMediaControl(action: action)
            }

        case .macMediaControlResponse:
            // This case handles responses from Android to Mac media control responses
            // Currently not needed as Mac sends responses to Android, not vice versa
            print("[websocket] Received macMediaControlResponse (not typically expected)")

        case .macInfo:
            // This case handles macInfo messages from Android to Mac
            // Currently not expected as Mac sends macInfo to Android, not vice versa
            print("[websocket] Received macInfo message from Android (not typically expected)")
            
        case .wakeUpRequest:
            // This case handles wake-up requests from Android to Mac
            // Currently not expected as Mac sends wake-up requests to Android, not vice versa
            print("[websocket] Received wakeUpRequest from Android (not typically expected)")
        case .startMirrorRequest:
            if let dict = message.data.value as? [String: Any],
               let mode = dict["mode"] as? String,
               let res = dict["res"] as? String,
               let bitrate = dict["bitrate"] as? Int {
                let package = dict["package"] as? String
                
                MirroringManager.shared.startMirroring(mode: mode, resolution: res, bitrate: bitrate, package: package)
                sendStartMirrorResponse(success: true)
            } else {
                print("[websocket] Received invalid start mirror request")
                sendStartMirrorResponse(success: false)
            }
        case .smsConversations:
            if let arr = message.data.value as? [[String: Any]] {
                var convs: [SmsConversation] = []
                for item in arr {
                    if let json = try? JSONSerialization.data(withJSONObject: item, options: []),
                       let conv = try? JSONDecoder().decode(SmsConversation.self, from: json) {
                        convs.append(conv)
                    }
                }
                DispatchQueue.main.async {
                    AppState.shared.smsConversations = convs
                }
            }
        case .smsMessages:
            // smsMessages contains messages for a particular conversation
            if let dict = message.data.value as? [String: Any],
               let convId = dict["conversationId"] as? String,
               let msgsArr = dict["messages"] as? [[String: Any]] {
                var messages: [SmsMessage] = []
                for m in msgsArr {
                    if let d = try? JSONSerialization.data(withJSONObject: m, options: []),
                       let msg = try? JSONDecoder().decode(SmsMessage.self, from: d) {
                        messages.append(msg)
                    }
                }
                DispatchQueue.main.async {
                    if let idx = AppState.shared.smsConversations.firstIndex(where: { $0.id == convId }) {
                        AppState.shared.smsConversations[idx].messages = messages
                    } else if let first = messages.first {
                        // Create a new conversation if not found
                        let conv = SmsConversation(id: convId, address: first.from, messages: messages)
                        AppState.shared.smsConversations.append(conv)
                    }
                }
            }
        case .smsMessageSent:
            // A single message sent acknowledgement; append to conversation if present
            if let dict = message.data.value as? [String: Any],
               let convId = dict["conversationId"] as? String,
               let msgDict = dict["message"] as? [String: Any] {
                if let d = try? JSONSerialization.data(withJSONObject: msgDict, options: []),
                   let msg = try? JSONDecoder().decode(SmsMessage.self, from: d) {
                    DispatchQueue.main.async {
                        if let idx = AppState.shared.smsConversations.firstIndex(where: { $0.id == convId }) {
                            AppState.shared.smsConversations[idx].messages.append(msg)
                        } else {
                            let conv = SmsConversation(id: convId, address: msg.to.isEmpty ? msg.from : msg.to, messages: [msg])
                            AppState.shared.smsConversations.append(conv)
                        }
                    }
                }
            }
        case .stopMirrorRequest:
            print("[websocket] Received stop mirror request")
            MirroringManager.shared.stopMirroring()
            sendStopMirrorResponse(success: true)
        default:
            // Handle ad-hoc/unknown types we haven't modeled yet
            if message.type.rawValue == "wallpaperResponse" {
                if let dict = message.data.value as? [String: Any] {
                    // Prefer explicit base64 payload under common keys
                    if var base64 = (dict["wallpaper"] as? String) ?? (dict["base64"] as? String) ?? (dict["data"] as? String) {
                        // Clean data URL prefix and whitespace/newlines
                        base64 = base64.trimmingCharacters(in: .whitespacesAndNewlines)
                        if let range = base64.range(of: "base64,") { base64 = String(base64[range.upperBound...]) }
                        base64 = base64.replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\r", with: "")

                        print("[websocket] Received wallpaperResponse base64 (len=\(base64.count))")

                        // Update in-memory base64 on main thread
                        DispatchQueue.main.async {
                            AppState.shared.currentDeviceWallpaperBase64 = base64
                        }

                        // Persist to cache if decodable
                        if let data = Data(base64Encoded: base64) {
                            let dir = AppState.shared.wallpaperCacheDirectory()
                            let deviceName = AppState.shared.device?.name ?? AppState.shared.myDevice?.name ?? "Device"
                            let deviceIP = AppState.shared.device?.ipAddress ?? AppState.shared.myDevice?.ipAddress ?? "ip"
                            let safeName = deviceName.replacingOccurrences(of: "/", with: "_")
                            let key = "\(safeName)-\(deviceIP)"
                            let fileURL = dir.appendingPathComponent("\(key).png")
                            do {
                                try data.write(to: fileURL, options: .atomic)
                                DispatchQueue.main.async {
                                    AppState.shared.deviceWallpapers[key] = fileURL.path
                                }
                                print("[websocket] Saved wallpaper to cache: \(fileURL.path)")
                            } catch {
                                print("[websocket] Failed to write wallpaper: \(error)")
                            }
                        } else {
                            print("[websocket] Wallpaper base64 could not be decoded")
                        }
                    } else if let success = dict["success"] as? Bool {
                        // Backward-compat: simple success/message response without payload
                        let msg = dict["message"] as? String ?? ""
                        print("[websocket] Wallpaper response: success=\(success) message=\(msg)")
                        if !success {
                            AppState.shared.postNativeNotification(
                                id: "wallpaper_permission",
                                appName: "AirSync",
                                title: "Wallpaper not available",
                                body: msg
                            )
                        }
                    } else {
                        print("[websocket] Wallpaper response received but payload malformed")
                    }
                } else {
                    print("[websocket] Wallpaper response received but data is not a dictionary")
                }
            } else {
                print("[websocket] Received unhandled message type: \(message.type.rawValue)")
            }
        }


    }

    // MARK: - Mac Media Control Handler
    private func handleMacMediaControl(action: String) {
        // Get reference to the NowPlayingViewModel from the app
        // We'll access it through the main app or AppState if needed

        switch action {
        case "play":
            NowPlayingCLI.shared.play()
            print("[websocket] Mac media control: play")

        case "pause":
            NowPlayingCLI.shared.pause()
            print("[websocket] Mac media control: pause")

        case "previous":
            NowPlayingCLI.shared.previous()
            print("[websocket] Mac media control: previous")

        case "next":
            NowPlayingCLI.shared.next()
            print("[websocket] Mac media control: next")

        case "stop":
            NowPlayingCLI.shared.stop()
            print("[websocket] Mac media control: stop")
            
        default:
            print("[websocket] Unknown Mac media control action: \(action)")
        }

        // Send response back to Android
        sendMacMediaControlResponse(action: action, success: true)
    }

    private func sendMacMediaControlResponse(action: String, success: Bool) {
        let message = """
        {
            "type": "macMediaControlResponse",
            "data": {
                "action": "\(action)",
                "success": \(success)
            }
        }
        """
        sendToFirstAvailable(message: message)
    }

    private func sendStartMirrorResponse(success: Bool) {
        let message = """
        {
            "type": "startMirrorResponse",
            "data": {
                "success": \(success)
            }
        }
        """
        sendToFirstAvailable(message: message)
    }

    private func sendStopMirrorResponse(success: Bool) {
        let message = """
        {
            "type": "stopMirrorResponse",
            "data": {
                "success": \(success)
            }
        }
        """
        sendToFirstAvailable(message: message)
    }

    private func sendMacInfoResponse() {
        // Gather Mac info with robust fallbacks
        let macName = AppState.shared.myDevice?.name ?? (Host.current().localizedName ?? "My Mac")
        let categoryTypeRaw = DeviceTypeUtil.deviceTypeDescription()
        let exactDeviceNameRaw = DeviceTypeUtil.deviceFullDescription()
        let categoryType = categoryTypeRaw.isEmpty ? "Mac" : categoryTypeRaw
        let exactDeviceName = exactDeviceNameRaw.isEmpty ? categoryType : exactDeviceNameRaw
        let isPlusSubscription = AppState.shared.isPlus

        // Saved app packages
        let savedAppPackages = Array(AppState.shared.androidApps.keys)

        // Base macInfo model (for forward compatibility / decoding symmetry)
        let macInfo = MacInfo(
            name: macName,
            categoryType: categoryType,
            exactDeviceName: exactDeviceName,
            isPlusSubscription: isPlusSubscription,
            savedAppPackages: savedAppPackages
        )

        do {
            let jsonData = try JSONEncoder().encode(macInfo)
            if var jsonDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                // Enrich with legacy / explicit keys Android may expect
                jsonDict["model"] = exactDeviceName   // Full marketing name
                jsonDict["type"] = categoryType       // Broad category
                jsonDict["isPlus"] = isPlusSubscription // Alias for existing isPlusSubscription

                let messageDict: [String: Any] = [
                    "type": "macInfo",
                    "data": jsonDict
                ]

                let messageJsonData = try JSONSerialization.data(withJSONObject: messageDict, options: [])
                if let messageJsonString = String(data: messageJsonData, encoding: .utf8) {
                    AppState.shared.sendMessage(messageJsonString)
                    print("[websocket] Sent Mac info response: model=\(exactDeviceName), type=\(categoryType)")
                }
            }
        } catch {
            print("[websocket] Error creating Mac info response: \(error)")
        }
    }

    // MARK: - Sending Helpers

    private func broadcast(message: String) {
        activeSessions.forEach { $0.writeText(message) }
    }

    func sendToFirstAvailable(message: String) {
        if let key = symmetricKey, let encrypted = encryptMessage(message, using: key) {
            activeSessions.first?.writeText(encrypted)
        } else {
            activeSessions.first?.writeText(message)
        }
    }


    // MARK: - Notification Control

    func dismissNotification(id: String) {
        let message = """
        {
            "type": "dismissNotification",
            "data": {
                "id": "\(id)"
            }
        }
        """
        AppState.shared.sendMessage(message)
    }

    func sendNotificationAction(id: String, name: String, text: String? = nil) {
        var data: [String: Any] = ["id": id, "name": name]
        if let t = text, !t.isEmpty { data["text"] = t }
        if let jsonData = try? JSONSerialization.data(withJSONObject: ["type": "notificationAction", "data": data], options: []),
           let json = String(data: jsonData, encoding: .utf8) { AppState.shared.sendMessage(json)
        }
    }

    // MARK: - Media Controls

    func togglePlayPause() {
        sendMediaAction("playPause")
    }

    func skipNext() {
        sendMediaAction("next")
    }

    func skipPrevious() {
        sendMediaAction("previous")
    }

    func stopMedia() {
        sendMediaAction("stop")
    }

    // Like controls
    func toggleLike() {
        sendMediaAction("toggleLike")
    }

    func like() {
        sendMediaAction("like")
    }

    func unlike() {
        sendMediaAction("unlike")
    }

    private func sendMediaAction(_ action: String) {
        let message = """
        {
            "type": "mediaControl",
            "data": {
                "action": "\(action)"
            }
        }
        """
        AppState.shared.sendMessage(message)
    }

    // MARK: - Volume Controls

    func volumeUp() {
        sendVolumeAction("volumeUp")
    }

    func volumeDown() {
        sendVolumeAction("volumeDown")
    }

    func toggleMute() {
        sendVolumeAction("mute")
    }

    func setVolume(_ volume: Int) {
        let message = """
        {
            "type": "volumeControl",
            "data": {
                "action": "setVolume",
                "volume": \(volume)
            }
        }
        """
        AppState.shared.sendMessage(message)
    }

    private func sendVolumeAction(_ action: String) {
        let message = """
        {
            "type": "volumeControl",
            "data": {
                "action": "\(action)"
            }
        }
        """
        AppState.shared.sendMessage(message)
    }

    func sendClipboardUpdate(_ message: String) {
        AppState.shared.sendMessage(message)
    }

    // MARK: - Device Status (Mac -> Android)
    func sendDeviceStatus(batteryLevel: Int, isCharging: Bool, isPaired: Bool, musicInfo: NowPlayingInfo?, albumArtBase64: String? = nil) {
        var statusDict: [String: Any] = [
            "battery": [
                "level": batteryLevel, // -1 for non-MacBooks, 0-100 for MacBooks
                "isCharging": isCharging
            ],
            "isPaired": isPaired
        ]

        // Only include music section if we have valid playback info
        if let musicInfo {
            let musicDict: [String: Any] = [
                "isPlaying": musicInfo.isPlaying ?? false,
                "title": musicInfo.title ?? "",
                "artist": musicInfo.artist ?? "",
                "volume": 50, // Hardcoded for now - will be replaced later
                "isMuted": false, // Hardcoded for now - will be replaced later
                "albumArt": albumArtBase64 ?? "",
                "likeStatus": "none" // Hardcoded for now - will be replaced later
            ]
            statusDict["music"] = musicDict
        }

        let messageDict: [String: Any] = [
            "type": "status",
            "data": statusDict
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: messageDict, options: [])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                AppState.shared.sendMessage(jsonString)
            }
        } catch {
            print("[websocket] Error creating device status message: \(error)")
        }
    }

    // MARK: - Low Battery Alerts
    private func checkLowBattery(level: Int, isCharging: Bool) {
        let lowBatteryThreshold = 20
        let appState = AppState.shared

        // If battery is low and not charging, and we haven't sent a notification yet
        if level <= lowBatteryThreshold && !isCharging && !appState.lowBatteryNotifSent {
            appState.postNativeNotification(
                id: "low_battery_\(appState.device?.name ?? "device")",
                appName: "AirSync",
                title: "\(appState.device?.name ?? "Device") Low Battery",
                body: "Battery is at \(level)%. You might want to charge it soon."
            )
            appState.lowBatteryNotifSent = true
            print("[websocket] Sent low battery alert for device.")
        }
        
        // Reset the flag if the battery is charged above the threshold or is charging
        if (level > lowBatteryThreshold || isCharging) && appState.lowBatteryNotifSent {
            appState.lowBatteryNotifSent = false
            print("[websocket] Low battery alert flag reset.")
        }
    }

    // MARK: - File transfer (Mac -> Android)
    func sendFile(url: URL, chunkSize: Int = 64 * 1024) {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        guard let data = try? Data(contentsOf: url) else { return }
        // compute checksum
        let checksumAll = FileTransferProtocol.md5Hex(data)

        let transferId = UUID().uuidString
        let fileName = url.lastPathComponent
        let totalSize = data.count
        let mime = mimeType(for: url) ?? "application/octet-stream"

        // Temporary: bypass checksum for image types to avoid false negatives on Android
        let checksum: String? = (mime.hasPrefix("image/png") || mime.hasPrefix("image/jpeg")) ? nil : checksumAll

        // Track in AppState
        AppState.shared.startOutgoingTransfer(id: transferId, name: fileName, size: totalSize, mime: mime, chunkSize: chunkSize)

        // Send init message
        let initMessage = FileTransferProtocol.buildInit(id: transferId, name: fileName, size: totalSize, mime: mime, checksum: checksum)
        AppState.shared.sendMessage(initMessage)

        // Send chunks using a simple sliding window to allow multiple in-flight chunks
        let windowSize = 1
        let totalChunks = (totalSize + chunkSize - 1) / chunkSize
        outgoingAckQueue.sync {
            outgoingAcks[transferId] = []
        }

        // Keep a buffer of sent chunks for potential retransmit: index -> (payloadBase64, attempts, lastSent)
        var sentBuffer: [Int: (payload: String, attempts: Int, lastSent: Date)] = [:]

        var nextIndexToSend = 0
        let startTime = Date()

        func sendChunkAt(_ idx: Int) {
            let start = idx * chunkSize
            let end = min(start + chunkSize, totalSize)
            let chunk = data.subdata(in: start..<end)
            let base64 = chunk.base64EncodedString()
            let chunkMessage = FileTransferProtocol.buildChunk(id: transferId, index: idx, base64Chunk: base64)
            AppState.shared.sendMessage(chunkMessage)
            sentBuffer[idx] = (payload: base64, attempts: 1, lastSent: Date())
        }

        // Prime the window
        while nextIndexToSend < totalChunks && nextIndexToSend < windowSize {
            sendChunkAt(nextIndexToSend)
            nextIndexToSend += 1
        }

        // Loop until all chunks are acked
        while true {
            let acked = outgoingAckQueue.sync {
                outgoingAcks[transferId] ?? []
            }

            // compute baseIndex = lowest unacked index (first missing starting from 0)
            var baseIndex = 0
            while acked.contains(baseIndex) {
                // free memory for acknowledged chunks
                sentBuffer.removeValue(forKey: baseIndex)
                baseIndex += 1
            }

            // Update progress in AppState
            let bytesAcked = min(acked.count * chunkSize, totalSize)
            AppState.shared.updateOutgoingProgress(id: transferId, bytesTransferred: bytesAcked)

            // completion when baseIndex reached totalChunks
            if baseIndex >= totalChunks {
                break
            }

            // send new chunks while window has space
            while nextIndexToSend < totalChunks && (nextIndexToSend - baseIndex) < windowSize {
                sendChunkAt(nextIndexToSend)
                nextIndexToSend += 1
            }

            // Retransmit chunks that haven't been acked and exceeded timeout
            let now = Date()
            for (idx, entry) in sentBuffer {
                if acked.contains(idx) { continue }
                let elapsedMs = now.timeIntervalSince(entry.lastSent) * 1000.0
                if elapsedMs > Double(ackWaitMs) {
                    if entry.attempts >= maxChunkRetries {
                        print("[websocket] (file-transfer) Failed to get ack for chunk \(idx) after \(maxChunkRetries) attempts")
                        _ = outgoingAckQueue.sync {
                            outgoingAcks.removeValue(forKey: transferId)
                        }
                        return
                    }
                    // retransmit
                    let start = idx * chunkSize
                    let end = min(start + chunkSize, totalSize)
                    let chunk = data.subdata(in: start..<end)
                    let base64 = chunk.base64EncodedString()
                    let chunkMessage = FileTransferProtocol.buildChunk(id: transferId, index: idx, base64Chunk: base64)
                    AppState.shared.sendMessage(chunkMessage)
                    sentBuffer[idx] = (payload: base64, attempts: entry.attempts + 1, lastSent: Date())
                }
            }

            // brief sleep to avoid busy-looping
            usleep(50_000) // 50ms
        }

        // Ensure progress shows 100%
        AppState.shared.updateOutgoingProgress(id: transferId, bytesTransferred: totalSize)
        let elapsed = Date().timeIntervalSince(startTime)
        print("[websocket] (file-transfer) Completed sending \(totalSize) bytes in \(elapsed) s")

        // Send complete
        let completeMessage = FileTransferProtocol.buildComplete(id: transferId, name: fileName, size: totalSize, checksum: checksum)
        AppState.shared.sendMessage(completeMessage)
    }

    func toggleNotification(for package: String, to state: Bool) {
        guard var app = AppState.shared.androidApps[package] else { return }

        app.listening = state
        AppState.shared.androidApps[package] = app
        AppState.shared.saveAppsToDisk()

        // WebSocket call
        let message = """
        {
            "type": "toggleAppNotif",
            "data": {
                "package": "\(package)",
                "state": "\(state)"
            }
        }
        """
        AppState.shared.sendMessage(message)
    }

    func loadOrGenerateSymmetricKey() {
        let defaults = UserDefaults.standard

        if let savedKey = defaults.string(forKey: "encryptionKey"),
           let keyData = Data(base64Encoded: savedKey) {
            symmetricKey = SymmetricKey(data: keyData)
            print("[websocket] (auth) Loaded existing symmetric key")
        } else {
            let base64Key = generateSymmetricKey()
            defaults.set(base64Key, forKey: "encryptionKey")

            if let keyData = Data(base64Encoded: base64Key) {
                symmetricKey = SymmetricKey(data: keyData)
                print("[websocket] (auth) Generated and stored new symmetric key")
            } else {
                print("[websocket] (auth) Failed to generate symmetric key")
            }
        }
    }

    func resetSymmetricKey() {
        UserDefaults.standard.removeObject(forKey: "encryptionKey")
        loadOrGenerateSymmetricKey()
    }

    func getSymmetricKeyBase64() -> String? {
        guard let key = symmetricKey else { return nil }
        return key.withUnsafeBytes { Data($0).base64EncodedString() }
    }


    func setEncryptionKey(base64Key: String) {
        if let data = Data(base64Encoded: base64Key) {
            symmetricKey = SymmetricKey(data: data)
            print("[websocket] (auth) Encryption key set")
        }
    }

    // Helper: determine mime type for a file URL
    func mimeType(for url: URL) -> String? {
        let ext = url.pathExtension
        if ext.isEmpty { return nil }

        if #available(macOS 11.0, *) {
            if let ut = UTType(filenameExtension: ext) {
                return ut.preferredMIMEType
            }
        } else {
#if canImport(MobileCoreServices)
            // Fallback to MobileCoreServices APIs
            if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, ext as CFString, nil)?.takeRetainedValue() {
                if let mime = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() as String? {
                    return mime
                }
            }
#else
            // No fallback available on this SDK
#endif
        }
        return nil
    }
    func startNetworkMonitoring() {
        networkMonitorTimer = Timer.scheduledTimer(withTimeInterval: networkCheckInterval, repeats: true) { [weak self] _ in
            self?.checkNetworkChange()
        }
        networkMonitorTimer?.tolerance = 1.0
        networkMonitorTimer?.fire()
    }

    func stopNetworkMonitoring() {
        networkMonitorTimer?.invalidate()
        networkMonitorTimer = nil
        lastKnownAdapters = []
    }

    private func checkNetworkChange() {
        let adapters = getAvailableNetworkAdapters()
        let chosenIP = getLocalIPAddress(adapterName: AppState.shared.selectedNetworkAdapterName)

        // Compare by addresses to detect any change
        let adapterAddresses = adapters.map { $0.address }
        let lastAddresses = lastKnownAdapters.map { $0.address }

        if adapterAddresses != lastAddresses {
            lastKnownAdapters = adapters

            // Revalidate the current network adapter selection
            AppState.shared.revalidateNetworkAdapter()

            for adapter in adapters {
                let activeMark = (adapter.address == chosenIP) ? " [ACTIVE]" : ""
                print("[websocket] (network) \(adapter.name) -> \(adapter.address)\(activeMark)")
            }

            // Restart if the IP changed
            if let lastIP = lastKnownIP, lastIP != chosenIP {
                print("[websocket] (network) IP changed from \(lastIP) to \(chosenIP ?? "N/A"), restarting WebSocket in 5 seconds")
                lastKnownIP = chosenIP
                AppState.shared.shouldRefreshQR = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    self.stop()
                    self.start(port: Defaults.serverPort)
                }
            } else if lastKnownIP == nil {
                // First run
                lastKnownIP = chosenIP
            }
        } else {
            // [quiet] No change is the common case; keep log line for debugging
            // print("[websocket] (network) No change detected")
        }
    }
    
    // MARK: - Quick Connect Delegate
    
    /// Delegates wake-up functionality to QuickConnectManager
    func wakeUpLastConnectedDevice() {
        QuickConnectManager.shared.wakeUpLastConnectedDevice()
    }
}

