//
//  AppleScriptSupport.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2025-10-01.
//

import Foundation
import Cocoa
import SwiftUI

// MARK: - AppleScript Commands

@objc(AirSyncDisconnectCommand)
class AirSyncDisconnectCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        let appState = AppState.shared

        if let device = appState.device {
            let deviceName = device.name
            DispatchQueue.main.async {
                appState.disconnectDevice()
            }
            return "Disconnected from \(deviceName)"
        } else {
            return "Not connected"
        }
    }
}

@objc(AirSyncStatusCommand)
class AirSyncStatusCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        let appState = AppState.shared

        if let device = appState.device {
            let statusInfo = [
                "device_name": device.name,
                "device_ip": device.ipAddress,
                "device_port": String(device.port),
                "device_version": device.version,
                "adb_connected": String(appState.adbConnected),
                "notifications_count": String(appState.notifications.count)
            ]

            if let jsonData = try? JSONSerialization.data(withJSONObject: statusInfo, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }

            return "Device: \(device.name) (\(device.ipAddress):\(device.port))"
        } else {
            return "No device connected"
        }
    }
}

@objc(AirSyncReconnectCommand)
class AirSyncReconnectCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        if let lastDevice = QuickConnectManager.shared.getLastConnectedDevice() {
            DispatchQueue.main.async {
                QuickConnectManager.shared.wakeUpLastConnectedDevice()
            }
            return "Attempting to reconnect to \(lastDevice.name) (\(lastDevice.ipAddress))"
        } else {
            return "No previous device found for current network"
        }
    }
}

@objc(AirSyncGetNotificationsCommand)
class AirSyncGetNotificationsCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        let appState = AppState.shared

        if appState.device != nil {
            let notifications = Array(appState.notifications.prefix(20))

            if notifications.isEmpty {
                return "No notifications"
            }

            let notificationData = notifications.map { notif in
                var data: [String: Any] = [
                    "title": notif.title,
                    "body": notif.body,
                    "app": notif.app,
                    "id": notif.id.uuidString,
                    "package": notif.package
                ]
                
                // Add app icon as base64 if available
                if let iconPath = appState.androidApps[notif.package]?.iconUrl,
                   let iconData = NSData(contentsOfFile: iconPath) {
                    data["app_icon_base64"] = iconData.base64EncodedString()
                }
                
                return data
            }

            if let jsonData = try? JSONSerialization.data(withJSONObject: notificationData, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }

            return "Found \(notifications.count) notifications"
        } else {
            return "No device connected"
        }
    }
}

@objc(AirSyncGetMediaCommand)
class AirSyncGetMediaCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        let appState = AppState.shared

        if let device = appState.device {
            if let music = appState.status?.music {
                var mediaInfo: [String: Any] = [
                    "title": music.title,
                    "artist": music.artist,
                    "is_playing": String(music.isPlaying),
                    "volume": String(music.volume),
                    "is_muted": String(music.isMuted),
                    "like_status": music.likeStatus
                ]

                // Add album art as base64 if available (albumArt is already base64)
                if !music.albumArt.isEmpty {
                    mediaInfo["album_art_base64"] = music.albumArt
                }

                if let jsonData = try? JSONSerialization.data(withJSONObject: mediaInfo, options: .prettyPrinted),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    return jsonString
                }

                return "\(music.title) by \(music.artist) - \(music.isPlaying ? "Playing" : "Paused")"
            } else {
                return "No media playing on \(device.name)"
            }
        } else {
            return "No device connected"
        }
    }
}
