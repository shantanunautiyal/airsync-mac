//
//  AppContentView.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-28.
//

import SwiftUI

enum TabIdentifier: String, CaseIterable, Identifiable {
    case notifications = "Notifications"
    case apps = "Apps"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .notifications: return "bell.badge.fill"
        case .apps: return "app.badge"
        case .settings: return "gear"
        }
    }
}

struct AppContentView: View {
    @State private var selectedTab: TabIdentifier = .notifications
    @StateObject var server = SocketServer()
    @ObservedObject var appState = AppState.shared

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                switch selectedTab {
                case .notifications:
                    List(appState.notifications.prefix(20), id: \.id) { notif in
                        NotificationView(
                            notification: notif,
                            deleteNotification: {
                                appState.removeNotification(notif)
                            }
                        )
                    }
                    .scrollContentBackground(.hidden)
                    .background(.clear)
                    .transition(.blurReplace)
                    .toolbar{
                        ToolbarItem(placement: .primaryAction) {
                            Button {
                                appState.clearNotifications()
                            } label: {
                                Label("Clear", systemImage: "wind")
                            }
                        }
                    }

                case .apps:
                    VStack(alignment: .leading) {
                        if let device = appState.device {
                            Text("📱 \(device.name) @ \(device.ipAddress):\(device.port)")
                                .font(.headline)
                        }

                        if let status = appState.status {
                            Text("🔋 Battery: \(status.battery.level)% \(status.battery.isCharging ? "⚡️ Charging" : "")")
                            Text("🎵 Now Playing: \(status.music.title) by \(status.music.artist)")
                        }
                    }
                    .padding()
                        .font(.largeTitle)
                        .transition(.blurReplace)
                        .toolbar{
                            ToolbarItem(placement: .primaryAction) {
                                Button {

                                } label: {
                                    Label("Refresh", systemImage: "repeat")
                                }
                            }
                        }

                case .settings:
                    ScanView()
                        .transition(.blurReplace)
                        .toolbar{
                            ToolbarItem(placement: .primaryAction) {
                                Button {

                                } label: {
                                    Label("About", systemImage: "info")
                                }
                            }
                        }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: selectedTab)
            .frame(minWidth: 550)
        }
        .toolbar {
            ToolbarItem(placement: .secondaryAction)  {
                Picker("Tab", selection: $selectedTab) {
                    ForEach(TabIdentifier.allCases) { tab in
                        Label(tab.rawValue, systemImage: tab.icon)
                            .labelStyle(.titleAndIcon)
                            .tag(tab)
                    }
                }
                .pickerStyle(.palette)

                Spacer()
            }
        }
    }
}


#Preview {
    AppContentView()
}
