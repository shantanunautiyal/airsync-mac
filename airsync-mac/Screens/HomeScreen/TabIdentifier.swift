import SwiftUI

/// Represents the main tabs in the app's primary UI
enum TabIdentifier: String, CaseIterable, Identifiable, Hashable {
    case notifications
    case apps
    case transfers
    case settings
    case qr

    var id: String { rawValue }

    /// System image name for toolbar/tab presentation
    var icon: String {
        switch self {
        case .notifications: return "bell"
        case .apps: return "apps.iphone"
        case .transfers: return "tray.and.arrow.up"
        case .settings: return "gearshape"
        case .qr: return "qrcode.viewfinder"
        }
    }

    /// Keyboard shortcut for quick switching (Command + key)
    var shortcut: KeyEquivalent {
        switch self {
        case .notifications: return "1"
        case .apps: return "2"
        case .transfers: return "3"
        case .settings: return "4"
        case .qr: return "5"
        }
    }

    /// Localized title key
    var titleKey: String {
        switch self {
        case .notifications: return "tabs.notifications"
        case .apps: return "tabs.apps"
        case .transfers: return "tabs.transfers"
        case .settings: return "tabs.settings"
        case .qr: return "tabs.qr"
        }
    }

    /// The tabs that should be visible in the picker/toolbar
    static var availableTabs: [TabIdentifier] {
        return [.notifications, .apps, .transfers, .settings, .qr]
    }
}
