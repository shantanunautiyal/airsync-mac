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
            print("[notification-delegate] User dismissed system notification with nid: \(nid)")
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
        if response.actionIdentifier == "OPEN_LINK" {
            let userInfo = response.notification.request.content.userInfo
            if let urlString = userInfo["url"] as? String, let url = URL(string: urlString) {
                NSWorkspace.shared.open(url)
            }
        } else if response.actionIdentifier == "VIEW_ACTION" {
            let userInfo = response.notification.request.content.userInfo
            if let package = userInfo["package"] as? String {
                AppState.shared.requestStartMirroring(appPackage: package)
            } else {
                print("[notification-delegate] Missing package for mirroring.")
            }
        } else if response.actionIdentifier.hasPrefix("ACT_") {
            let actionName = String(response.actionIdentifier.dropFirst(4))
            let userInfo = response.notification.request.content.userInfo
            let nid = userInfo["nid"] as? String ?? response.notification.request.identifier

            var replyText: String? = nil
            if let textResp = response as? UNTextInputNotificationResponse {
                replyText = textResp.userText
            }
            WebSocketServer.shared.sendNotificationAction(id: nid, name: actionName, text: replyText)
        }

        completionHandler()
    }

}
