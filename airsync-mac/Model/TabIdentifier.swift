//
//  TabIdentifier.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2025-09-20.
//

import SwiftUI

enum TabIdentifier: String, CaseIterable, Identifiable {
    case notifications = "notifications.tab"
    case apps = "apps.tab"
    case transfers = "transfers.tab"
    case calls = "calls.tab"
    case messages = "messages.tab"
    case health = "health.tab"
    case settings = "settings.tab"
    case qr = "qr.tab"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .notifications: return "bell"
        case .apps: return "app"
        case .transfers: return "arrow.up.arrow.down"
        case .calls: return "phone"
        case .messages: return "message"
        case .health: return "heart"
        case .settings: return "gear"
        case .qr: return "qrcode"
        }
    }

    var shortcut: KeyEquivalent {
        switch self {
        case .notifications: return "1"
        case .apps: return "2"
        case .transfers: return "3"
        case .calls: return "4"
        case .messages: return "5"
        case .health: return "6"
        case .settings: return "8"
        case .qr: return "9"
        }
    }
}
