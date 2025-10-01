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
        DispatchQueue.main.async {
            AppState.shared.disconnectDevice()
        }
        return NSNumber(value: true)
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
