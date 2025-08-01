//
//  NotificationDelegate.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-30.
//

import SwiftUI
import UserNotifications

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didRemoveDeliveredNotifications identifiers: [String]) {
        for nid in identifiers {
            print("User dismissed system notification with nid: \(nid)")
            DispatchQueue.main.async {
                AppState.shared.removeNotificationById(nid)
            }
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.actionIdentifier == "VIEW_ACTION" {
            let userInfo = response.notification.request.content.userInfo
            if let package = userInfo["package"] as? String,
               let ip = AppState.shared.device?.ipAddress,
               let name = AppState.shared.device?.name {

                ADBConnector.startScrcpy(
                    ip: ip,
                    port: AppState.shared.adbPort,
                    deviceName: name,
                    package: package
                )
            } else {
                print("Missing device details or package for scrcpy.")
            }
        }

        completionHandler()
    }

}
