//
//  WebSocketServer.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-28.
//

import Foundation
import Swifter
internal import Combine

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

    @Published var localPort: UInt16?
    @Published var localIPAddress: String?

    @Published var connectedDevice: Device?
    @Published var notifications: [Notification] = []
    @Published var deviceStatus: DeviceStatus?

    init() {
        setupWebSocket()
    }

    func start(port: UInt16 = Defaults.serverPort) {
        DispatchQueue.main.async {
            AppState.shared.webSocketStatus = .starting
        }
        do {
            try server.start(port)
            let ip = getLocalIPAddress(adapterName: AppState.shared.selectedNetworkAdapterName)

            DispatchQueue.main.async {
                self.localPort = port
                self.localIPAddress = ip
                AppState.shared.webSocketStatus = .started(port: port, ip: ip)
            }
            print("WebSocket server started at ws://\(ip ?? "unknown"):\(port)/socket")
        } catch {
            DispatchQueue.main.async {
                AppState.shared.webSocketStatus = .failed(error: "\(error)")
            }
            print("Failed to start WebSocket server: \(error)")
        }
    }


    func stop() {
        server.stop()
        activeSessions.removeAll()
        DispatchQueue.main.async {
            AppState.shared.webSocketStatus = .stopped
        }
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
                guard let self = self else { return }
                print("WebSocket disconnected")

                self.activeSessions.removeAll(where: { $0 === session })

                // Only call disconnectDevice if no other sessions remain
                if self.activeSessions.isEmpty {
                    DispatchQueue.main.async {
                        AppState.shared.disconnectDevice()
                    }
                }
            }
        )
    }


    // MARK: - Local IP

    func getLocalIPAddress(adapterName: String?) -> String? {
        let address: String? = "N/A"
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return nil
        }

        defer { freeifaddrs(ifaddr) }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            let name = String(cString: interface.ifa_name)

            if addrFamily == UInt8(AF_INET) {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                let result = getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                         &hostname, socklen_t(hostname.count),
                                         nil, socklen_t(0), NI_NUMERICHOST)

                if result == 0 {
                    let ip = String(cString: hostname)
                    print("Checking adapter: \(name), IP: \(ip), target: \(adapterName ?? "nil")")

                    if ip == "127.0.0.1" {
                        continue // Skip loopback
                    }

                    if adapterName == nil || name == adapterName {
                        print("Selected adapter match or fallback: \(name) -> \(ip)")
                        return ip
                    }
                }
            }
        }

        return address
    }


    func getAvailableNetworkAdapters() -> [(name: String, address: String)] {
        var adapters: [(String, String)] = []
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil

        if getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr {
            var ptr = firstAddr
            while ptr.pointee.ifa_next != nil {
                defer { ptr = ptr.pointee.ifa_next! }

                let interface = ptr.pointee
                let addrFamily = interface.ifa_addr.pointee.sa_family

                if addrFamily == UInt8(AF_INET),
                   let name = String(validatingUTF8: interface.ifa_name) {
                    var addr = interface.ifa_addr.pointee
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(&addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    let address = String(cString: hostname)
                    if address != "127.0.0.1" {
                        adapters.append((name, address))
                    }

                }
            }
            freeifaddrs(ifaddr)
        }

        return adapters
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

                if let base64 = dict["wallpaper"] as? String {
                    AppState.shared.currentDeviceWallpaperBase64 = base64
                }
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
            if let dict = message.data.value as? [String: [String: Any]] {
                DispatchQueue.global(qos: .background).async {
                    for (package, details) in dict {
                        guard let name = details["name"] as? String,
                              let iconBase64 = details["icon"] as? String,
                              let systemApp = details["systemApp"] as? Bool,
                              let listening = details["listening"] as? Bool else {
                            continue
                        }

                        var cleaned = iconBase64
                        if let range = cleaned.range(of: "base64,") {
                            cleaned = String(cleaned[range.upperBound...])
                        }

                        var iconPath: String? = nil
                        if let data = Data(base64Encoded: cleaned) {
                            let fileURL = appIconsDirectory().appendingPathComponent("\(package).png")
                            do {
                                try data.write(to: fileURL)
                                iconPath = fileURL.path
                            } catch {
                                print("Failed to write icon for \(package): \(error)")
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
                            AppState.shared.appIcons[package] = iconPath ?? ""
                        }
                    }
                }
            }


        case .clipboardUpdate:
            if let dict = message.data.value as? [String: Any],
               let text = dict["text"] as? String {
                AppState.shared.updateClipboardFromAndroid(text)
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
        sendToFirstAvailable(message: message)
    }


}
