//
//  SocketServer.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-28.
//

import Foundation
import CocoaAsyncSocket

class SocketServer: NSObject, GCDAsyncSocketDelegate {
    var serverSocket: GCDAsyncSocket!
    var connectedSockets: [GCDAsyncSocket] = []

    override init() {
        super.init()
        serverSocket = GCDAsyncSocket(delegate: self, delegateQueue: .main)
    }

    func start(port: UInt16 = 8080) {
        do {
            try serverSocket.accept(onPort: port)
            print("Server started on port \(port)")
        } catch {
            print("Error starting server: \(error)")
        }
    }

    func stop() {
        serverSocket.disconnect()
        for socket in connectedSockets {
            socket.disconnect()
        }
        connectedSockets.removeAll()
    }

    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        print("Accepted new socket from \(newSocket.connectedHost ?? "unknown")")
        connectedSockets.append(newSocket)
        newSocket.readData(to: GCDAsyncSocket.crlfData(), withTimeout: -1, tag: 0)
    }

    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        if let str = String(data: data, encoding: .utf8) {
            print("Received: \(str.trimmingCharacters(in: .newlines))")
            let reply = "Echo: \(str)"
            sock.write(reply.data(using: .utf8), withTimeout: -1, tag: 0)
        }
        sock.readData(to: GCDAsyncSocket.crlfData(), withTimeout: -1, tag: 0)
    }
}
