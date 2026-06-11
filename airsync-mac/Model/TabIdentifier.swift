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
        }
        return tabs
    }
}
