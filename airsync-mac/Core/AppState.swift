//
//  AppState.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-29.
//

import Foundation
internal import Combine

class AppState: ObservableObject {
    static let shared = AppState()

    @Published var device: Device? = nil
    @Published var notifications: [Notification] = []
    @Published var status: DeviceStatus? = nil
}

