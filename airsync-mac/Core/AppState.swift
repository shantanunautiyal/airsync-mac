//
//  AppState.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-29.
//
import SwiftUI
import Foundation
internal import Combine

class AppState: ObservableObject {
    static let shared = AppState()
    
    init() {
        // Load from UserDefaults
        let name = UserDefaults.standard.string(forKey: "deviceName") ?? (Host.current().localizedName ?? "My Mac")
        let portString = UserDefaults.standard.string(forKey: "devicePort") ?? String(Defaults.serverPort)
        let port = Int(portString) ?? Int(Defaults.serverPort)

        self.myDevice = Device(
            name: name,
            ipAddress: getLocalIPAddress() ?? "N/A",
            port: port
        )
    }


    @Published var device: Device? = nil
    @Published var notifications: [Notification] = []
    @Published var status: DeviceStatus? = nil
    @Published var myDevice: Device? = nil
    @Published var port: UInt16 = Defaults.serverPort
    @Published var appIcons: [String: String] = [:] // packageName: base64Icon


    func removeNotification(_ notif: Notification) {
        DispatchQueue.main.async {
            withAnimation {
                self.notifications.removeAll { $0.id == notif.id }
            }
            WebSocketServer.shared.dismissNotification(id: notif.nid)
        }
    }


    func clearNotifications() {
        DispatchQueue.main.async {
            if !self.notifications.isEmpty {
                withAnimation {
                    self.notifications.removeAll()
                }
            }
        }
    }

    func disconnectDevice() {
        DispatchQueue.main.async{
            self.device = nil
            self.notifications.removeAll()
            self.status = nil
        }
    }

}

