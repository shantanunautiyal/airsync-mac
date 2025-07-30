//
//  WebSocketServer.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-28.
//

import Foundation
import Swifter
internal import Combine

class WebSocketServer: ObservableObject {
    static let shared = WebSocketServer()

    private var server = HttpServer()
    private var activeSessions: [WebSocketSession] = []

    @Published var localPort: UInt16?
    @Published var localIPAddress: String?

    @Published var connectedDevice: Device?
    @Published var notifications: [Notification] = []
    @Published var deviceStatus: DeviceStatus?

    init() {
        setupWebSocket()
    }

    func start(port: UInt16 = Defaults.serverPort) {
        do {
            try server.start(port)
            localPort = port
            localIPAddress = getWiFiAddress()
            print("WebSocket server started at ws://\(localIPAddress ?? "unknown"):\(port)/socket")
        } catch {
            print("Failed to start WebSocket server: \(error)")
        }
    }

    func stop() {
        server.stop()
        activeSessions.removeAll()
    }

    func sendDisconnectRequest() {
        let message = """
    {
        "type": "disconnectRequest",
        "data": {}
    }
    """
        sendToFirstAvailable(message: message)
    }


    private func setupWebSocket() {
        server["/socket"] = websocket(
            text: { [weak self] session, text in
                guard let self = self else { return }
                print("WebSocket Received:\n\(text)")

                if let data = text.data(using: .utf8) {
                    do {
                        let message = try JSONDecoder().decode(Message.self, from: data)
                        DispatchQueue.main.async {
                            self.handleMessage(message)
                        }
                    } catch {
                        print("WebSocket JSON decode failed: \(error)")
                    }
                }
            },
            connected: { [weak self] session in
                print("WebSocket connected")
                self?.activeSessions.append(session)
            },
            disconnected: { [weak self] session in
                print("WebSocket disconnected")
                self?.activeSessions.removeAll(where: { $0 === session })
            }
        )
    }

    // MARK: - Local IP

    private func getWiFiAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil

        if getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr {
            var ptr = firstAddr
            while ptr.pointee.ifa_next != nil {
                defer { ptr = ptr.pointee.ifa_next! }

                let interface = ptr.pointee
                let addrFamily = interface.ifa_addr.pointee.sa_family

                if addrFamily == UInt8(AF_INET),
                   let name = String(validatingUTF8: interface.ifa_name),
                   name == "en0" {
                    var addr = interface.ifa_addr.pointee
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(&addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                    break
                }
            }
        }

        freeifaddrs(ifaddr)
        return address
    }

    // MARK: - Message Handling

    func handleMessage(_ message: Message) {
        switch message.type {
        case .device:
            if let dict = message.data.value as? [String: Any],
               let name = dict["name"] as? String,
               let ip = dict["ipAddress"] as? String,
               let port = dict["port"] as? Int {
                AppState.shared.device = Device(name: name, ipAddress: ip, port: port)
            }

        case .notification:
            if let dict = message.data.value as? [String: Any],
               let nid = dict["id"] as? String,
               let title = dict["title"] as? String,
               let body = dict["body"] as? String,
               let app = dict["app"] as? String,
               let package = dict["package"] as? String{
                let notif = Notification(title: title, body: body, app: app, nid: nid, package: package)
                DispatchQueue.main.async {
//                    AppState.shared.notifications.insert(notif, at: 0)
                    AppState.shared.addNotification(notif)
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
               let isMuted = music["isMuted"] as? Bool {
                AppState.shared.status = DeviceStatus(
                    battery: .init(level: level, isCharging: isCharging),
                    isPaired: paired,
                    music: .init(isPlaying: playing, title: title, artist: artist, volume: volume, isMuted: isMuted)
                )
            }

        case .dismissalResponse:
            if let dict = message.data.value as? [String: Any],
               let id = dict["id"] as? String,
               let success = dict["success"] as? Bool {
                print("Dismissal \(success ? "succeeded" : "failed") for notification id: \(id)")
            }

        case .mediaControlResponse:
            if let dict = message.data.value as? [String: Any],
               let action = dict["action"] as? String,
               let success = dict["success"] as? Bool {
                print("Media control \(action) \(success ? "succeeded" : "failed")")
            }

        case .appIcons:
            if let dict = message.data.value as? [String: String] {
                DispatchQueue.global(qos: .background).async {
                    for (package, base64Icon) in dict {
                        // Strip data URI if present
                        var cleaned = base64Icon
                        if let range = cleaned.range(of: "base64,") {
                            cleaned = String(cleaned[range.upperBound...])
                        }

                        if let data = Data(base64Encoded: cleaned) {
                            let fileURL = appIconsDirectory().appendingPathComponent("\(package).png")
                            try? data.write(to: fileURL)

                            DispatchQueue.main.async {
                                AppState.shared.appIcons[package] = fileURL.path
                            }
                        }
                    }
                }
            }

        case .clipboardUpdate:
            if let dict = message.data.value as? [String: Any],
               let text = dict["text"] as? String {
                AppState.shared.updateClipboardFromAndroid(text)
            }

        case .wallpaperImage:
            if let dict = message.data.value as? [String: Any],
               let base64 = dict["image"] as? String,
               let deviceName = dict["deviceName"] as? String,
               let ipAddress = dict["ipAddress"] as? String {

                DispatchQueue.global(qos: .background).async {
                    let key = "\(deviceName)-\(ipAddress)".replacingOccurrences(of: " ", with: "_")
                    if let imageData = Data(base64Encoded: base64.stripBase64Prefix()) {
                        let fileURL = wallpaperDirectory().appendingPathComponent("\(key).png")
                        do {
                            try imageData.write(to: fileURL)
                            DispatchQueue.main.async {
                                AppState.shared.deviceWallpapers[key] = fileURL.path
                                print("✅ Saved wallpaper for \(deviceName) at: \(fileURL.path)")
                            }
                        } catch {
                            print("❌ Failed to save wallpaper: \(error)")
                        }
                    }
                }
            }




        }

        
    }

    // MARK: - Sending Helpers

    private func broadcast(message: String) {
        activeSessions.forEach { $0.writeText(message) }
    }

    private func sendToFirstAvailable(message: String) {
        activeSessions.first?.writeText(message)
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
        sendToFirstAvailable(message: message)
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

    private func sendMediaAction(_ action: String) {
        let message = """
        {
            "type": "mediaControl",
            "data": {
                "action": "\(action)"
            }
        }
        """
        sendToFirstAvailable(message: message)
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
        sendToFirstAvailable(message: message)
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
        sendToFirstAvailable(message: message)
    }

    func sendClipboardUpdate(_ message: String) {
        sendToFirstAvailable(message: message)
    }

}
