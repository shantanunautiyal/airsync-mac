//
//  AppState.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-29.
//
import SwiftUI
import Foundation
internal import Combine
import UserNotifications

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
        
        postNativeNotification(appName: "Test App", title: "Hello", body: "This is a test notification", appIcon: nil)
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

    func hideNotification(_ notif: Notification) {
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

    func disconnectDevice() {
        DispatchQueue.main.async {
            // Send request to remote device to disconnect
            WebSocketServer.shared.sendDisconnectRequest()

            // Then locally reset state
            self.device = nil
            self.notifications.removeAll()
            self.status = nil
        }
    }

    func addNotification(_ notif: Notification) {
        DispatchQueue.main.async {
            withAnimation {
                self.notifications.insert(notif, at: 0)
            }
            // Trigger native macOS notification
            var appIcon: NSImage? = nil
            if let iconPath = self.appIcons[notif.package] {
                appIcon = NSImage(contentsOfFile: iconPath)
            }
            self.postNativeNotification(
                appName: notif.app,
                title: notif.title,
                body: notif.body,
                appIcon: appIcon
            )
        }
    }



    func postNativeNotification(appName: String, title: String, body: String, appIcon: NSImage? = nil) {
        let content = UNMutableNotificationContent()

        // Show "AppName - Title" as the notification title
        content.title = "\(appName) - \(title)"
        content.body = body
        content.sound = .default

        // Attach the app icon as the notification icon if available
        if let icon = appIcon {
            if let iconFileURL = saveIconToTemporaryFile(icon: icon) {
                do {
                    let attachment = try UNNotificationAttachment(identifier: "appIcon", url: iconFileURL, options: nil)
                    content.attachments = [attachment]
                } catch {
                    print("Failed to attach app icon to notification: \(error)")
                }
            }
        }

        // Create a unique identifier for the notification
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // deliver immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to post native notification: \(error)")
            }
        }
    }

    private func saveIconToTemporaryFile(icon: NSImage) -> URL? {
        // Save NSImage as a temporary PNG file to attach in notification
        guard let tiffData = icon.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }

        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
        let tempFile = tempDir.appendingPathComponent("notification_icon_\(UUID().uuidString).png")

        do {
            try pngData.write(to: tempFile)
            return tempFile
        } catch {
            print("Error saving icon to temp file: \(error)")
            return nil
        }
    }
    


}

