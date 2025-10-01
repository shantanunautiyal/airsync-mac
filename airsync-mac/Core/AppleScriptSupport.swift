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

@objc(AirSyncLaunchMirroringCommand)
class AirSyncLaunchMirroringCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        // Check if device is connected
        guard let device = AppState.shared.device else {
            let errorInfo: [String: Any] = [
                "success": false,
                "error": "no_device_connected",
                "message": "No Android device connected. Please connect a device first."
            ]
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: errorInfo, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
            return "No device connected"
        }
        
        // Check if ADB is available
        guard ADBConnector.findExecutable(named: "adb", fallbackPaths: ADBConnector.possibleADBPaths) != nil else {
            let errorInfo: [String: Any] = [
                "success": false,
                "error": "adb_not_found",
                "message": "ADB not found. Please install via Homebrew: brew install android-platform-tools"
            ]
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: errorInfo, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
            return "ADB not found"
        }
        
        // Check if scrcpy is available
        guard ADBConnector.findExecutable(named: "scrcpy", fallbackPaths: ADBConnector.possibleScrcpyPaths) != nil else {
            let errorInfo: [String: Any] = [
                "success": false,
                "error": "scrcpy_not_found",
                "message": "scrcpy not found. Please install via Homebrew: brew install scrcpy"
            ]
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: errorInfo, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
            return "scrcpy not found"
        }
        
        // Check if ADB is connected
        guard AppState.shared.adbConnected else {
            let errorInfo: [String: Any] = [
                "success": false,
                "error": "adb_not_connected",
                "message": "ADB not connected. Please enable wireless debugging on your Android device and connect via ADB first."
            ]
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: errorInfo, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
            return "ADB not connected"
        }
        
        // Start mirroring
        DispatchQueue.main.async {
            ADBConnector.startScrcpy(
                ip: device.ipAddress,
                port: AppState.shared.adbPort,
                deviceName: device.name
            )
        }
        
        let successInfo: [String: Any] = [
            "success": true,
            "message": "Launching mirroring for \(device.name)",
            "device": device.name,
            "ip": device.ipAddress
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: successInfo, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        
        return "Starting mirroring for \(device.name)"
    }
}

@objc(AirSyncGetAppsCommand)
class AirSyncGetAppsCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        guard AppState.shared.device != nil else {
            return "No device connected"
        }
        
        let apps = Array(AppState.shared.androidApps.values).sorted { $0.name.lowercased() < $1.name.lowercased() }
        
        var appsArray: [[String: Any]] = []
        
        for app in apps {
            var appIconBase64: String? = nil
            
            // Convert app icon to base64 if available
            if let iconPath = app.iconUrl,
               let imageData = NSImage(contentsOfFile: iconPath)?.tiffRepresentation,
               let bitmapRep = NSBitmapImageRep(data: imageData),
               let pngData = bitmapRep.representation(using: NSBitmapImageRep.FileType.png, properties: [:]) {
                appIconBase64 = pngData.base64EncodedString()
            }
            
            let appInfo: [String: Any] = [
                "package_name": app.packageName,
                "name": app.name,
                "system_app": app.systemApp,
                "listening": app.listening,
                "icon": appIconBase64 ?? ""
            ]
            
            appsArray.append(appInfo)
        }
        
        let result: [String: Any] = [
            "apps": appsArray,
            "count": appsArray.count
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: result, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        
        return "Failed to serialize apps information"
    }
}

@objc(AirSyncMirrorAppCommand)
class AirSyncMirrorAppCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        // Check if device is connected
        guard let device = AppState.shared.device else {
            let errorInfo: [String: Any] = [
                "success": false,
                "error": "no_device_connected",
                "message": "No Android device connected. Please connect a device first."
            ]
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: errorInfo, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
            return "No device connected"
        }
        
        // Check if ADB is connected
        guard AppState.shared.adbConnected else {
            let errorInfo: [String: Any] = [
                "success": false,
                "error": "adb_not_connected",
                "message": "ADB not connected. Please enable wireless debugging and connect via ADB first."
            ]
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: errorInfo, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
            return "ADB not connected"
        }
        
        // Get package name from command arguments
        guard let packageName = self.directParameter as? String, !packageName.isEmpty else {
            let errorInfo: [String: Any] = [
                "success": false,
                "error": "missing_package_name",
                "message": "Package name is required. Usage: mirror app \"com.example.app\""
            ]
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: errorInfo, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
            return "Package name required"
        }
        
        // Check if app exists
        guard let app = AppState.shared.androidApps[packageName] else {
            let errorInfo: [String: Any] = [
                "success": false,
                "error": "app_not_found",
                "message": "App with package name '\(packageName)' not found on device."
            ]
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: errorInfo, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
            return "App not found: \(packageName)"
        }
        
        // Start app-specific mirroring
        DispatchQueue.main.async {
            ADBConnector.startScrcpy(
                ip: device.ipAddress,
                port: AppState.shared.adbPort,
                deviceName: device.name,
                package: packageName
            )
        }
        
        let successInfo: [String: Any] = [
            "success": true,
            "message": "Launching app-specific mirroring for \(app.name)",
            "app_name": app.name,
            "package_name": packageName,
            "device": device.name
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: successInfo, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        
        return "Starting app mirroring for \(app.name)"
    }
}

@objc(AirSyncDesktopModeCommand)
class AirSyncDesktopModeCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        // Check if device is connected
        guard let device = AppState.shared.device else {
            let errorInfo: [String: Any] = [
                "success": false,
                "error": "no_device_connected",
                "message": "No Android device connected. Please connect a device first."
            ]
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: errorInfo, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
            return "No device connected"
        }
        
        // Check if ADB is connected
        guard AppState.shared.adbConnected else {
            let errorInfo: [String: Any] = [
                "success": false,
                "error": "adb_not_connected",
                "message": "ADB not connected. Please enable wireless debugging and connect via ADB first."
            ]
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: errorInfo, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
            return "ADB not connected"
        }
        
        // Start desktop mode mirroring
        DispatchQueue.main.async {
            ADBConnector.startScrcpy(
                ip: device.ipAddress,
                port: AppState.shared.adbPort,
                deviceName: device.name,
                desktop: true
            )
        }
        
        let successInfo: [String: Any] = [
            "success": true,
            "message": "Launching desktop mode mirroring for \(device.name)",
            "device": device.name,
            "mode": "desktop",
            "note": "Desktop mode requires Android 15+ and vendor support"
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: successInfo, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        
        return "Starting desktop mode mirroring for \(device.name)"
    }
}