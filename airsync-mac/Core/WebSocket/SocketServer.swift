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
        newSocket.readData(to: GCDAsyncSocket.crlfData(), withTimeout: -1, tag: 0)
    }

    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        if let text = String(data: data, encoding: .utf8) {
            print("Received: \(text.trimmingCharacters(in: .whitespacesAndNewlines))")
        }
        sock.readData(to: GCDAsyncSocket.crlfData(), withTimeout: -1, tag: 0)
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
}
