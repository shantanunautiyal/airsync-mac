//
//  NotificationView.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2025-08-07.
//

import SwiftUI

struct NotificationView: View {
    @ObservedObject var appState = AppState.shared

    var body: some View {
        if appState.notifications.count > 0 {
            List(appState.notifications.prefix(20), id: \.id) { notif in
                notificationRow(for: notif)
            }
            .scrollContentBackground(.hidden)
            .background(.clear)
            .transition(.blurReplace)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        appState.clearNotifications()
                    } label: {
                        Label("Clear", systemImage: "wind")
                    }
                }
            }
        } else {
            NotificationEmptyView()
        }
    }

    @ViewBuilder
    private func notificationRow(for notif: Notification) -> some View {
        NotificationCardView(
            notification: notif,
            deleteNotification: {
                appState.removeNotification(notif)
            },
            hideNotification: {
                appState.hideNotification(notif)
            }
        )
        .background(.clear)
        .applyGlassViewIfAvailable()
        .onTapGesture {
            if appState.device != nil && appState.adbConnected &&
                notif.package != "" &&
                notif.package != "com.sameerasw.airsync" &&
                appState.mirroringPlus {
                ADBConnector.startScrcpy(
                    ip: appState.device?.ipAddress ?? "",
                    port: appState.adbPort,
                    deviceName: appState.device?.name ?? "My Phone",
                    package: notif.package
                )
            }
        }
    }

}

#Preview {
    NotificationView()
}

extension View {
    @ViewBuilder
    func applyGlassViewIfAvailable() -> some View {
        if #available(macOS 26.0, *) {
            self.glassEffect(in: .rect(cornerRadius: 20))
        }
    }
}
