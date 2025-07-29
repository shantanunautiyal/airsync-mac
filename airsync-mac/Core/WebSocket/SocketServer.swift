//
//  SocketServer.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-28.
//

import Foundation
import CocoaAsyncSocket
import Network
internal import Combine

class SocketServer: NSObject, GCDAsyncSocketDelegate, ObservableObject {
    private var serverSocket: GCDAsyncSocket!
    @Published var localPort: UInt16?
    @Published var localIPAddress: String?

    @Published var connectedDevice: Device?
    @Published var notifications: [Notification] = []
    @Published var deviceStatus: DeviceStatus?


    override init() {
        super.init()
        serverSocket = GCDAsyncSocket(delegate: self, delegateQueue: .main)
    }

    func start(port: UInt16 = 6996) {
        do {
            try serverSocket.accept(onPort: port)
            localPort = serverSocket.localPort
            localIPAddress = getWiFiAddress()
            print("Socket server started on \(localIPAddress ?? "unknown"):\(localPort ?? 6996)")
        } catch {
            print("Error starting server: \(error)")
        }
    }

    func stop() {
        serverSocket.disconnect()
    }

    // MARK: - GCDAsyncSocketDelegate

    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        print("Accepted connection from \(newSocket.connectedHost ?? "unknown")")
        newSocket.readData(to: GCDAsyncSocket.lfData(), withTimeout: -1, tag: 0)
    }

    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        if let jsonString = String(data: data, encoding: .utf8) {
            print("RAW RECEIVED:\n\(jsonString)")

            do {
                let decoder = JSONDecoder()
                let message = try decoder.decode(Message.self, from: data)

                DispatchQueue.main.async {
                    self.handleMessage(message)
                }
            } catch {
                print("Failed to decode: \(error)")
            }
        }

        sock.readData(to: GCDAsyncSocket.lfData(), withTimeout: -1, tag: 0)
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
                   name == "en0" // Wi-Fi
                {
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
               let title = dict["title"] as? String,
               let body = dict["body"] as? String,
               let app = dict["app"] as? String {
                AppState.shared.notifications.insert(Notification(title: title, body: body, app: app), at: 0)
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
        }
    }
}

struct BaseMessage: Codable {
    let type: String
}

struct TypedMessage<T: Codable>: Codable {
    let type: String
    let data: T
}


