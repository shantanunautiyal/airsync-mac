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

    @Published var device: Device? = nil
    @Published var notifications: [Notification] = []
    @Published var status: DeviceStatus? = nil

    func removeNotification(_ notif: Notification) {
        DispatchQueue.main.async {
            withAnimation {
                self.notifications.removeAll { $0.id == notif.id }
            }
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

}

