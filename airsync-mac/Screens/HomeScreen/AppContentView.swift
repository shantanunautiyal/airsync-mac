//
//  AppContentView.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-28.
//

import SwiftUI

enum TabIdentifier: String, CaseIterable, Identifiable {
    case notifications = "Notifications"
    //    case apps = "Apps"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .notifications: return "bell.badge.fill"
            //        case .apps: return "app.badge"
        case .settings: return "gear"
        }
    }

    static var availableTabs: [TabIdentifier] {
        var tabs: [TabIdentifier] = [.settings]
        if AppState.shared.device != nil {
            tabs.insert(.notifications, at: 0)
        }
        return tabs
    }
}

struct AppContentView: View {
    @ObservedObject var appState = AppState.shared
    @State private var showAboutSheet = false

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                switch AppState.shared.selectedTab {
                case .notifications:
                    if appState.notifications.count > 0 {
                        List(appState.notifications.prefix(20), id: \.id) { notif in
                            if #available(macOS 26.0, *) {
                                NotificationView(
                                    notification: notif,
                                    deleteNotification: {
                                        appState.removeNotification(notif)
                                    },
                                    hideNotification: {
                                        appState.hideNotification(notif)
                                    }
                                )
                                .background(.clear)
                                .glassEffect(in: .rect(cornerRadius: 20))
                            } else {
                                NotificationView(
                                    notification: notif,
                                    deleteNotification: {
                                        appState.removeNotification(notif)
                                    },
                                    hideNotification: {
                                        appState.hideNotification(notif)
                                    }
                                )
                            }
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
                        VStack {
                            Spacer()
                            Text("└(=^‥^=)┐")
                                .font(.title)
                                .padding()
                            Label("You're all caught up!", systemImage: "tray")
                            Spacer()
                        }
                    }

//                case .apps:
//                    VStack(alignment: .leading) {
//                        if let device = appState.device {
//                            Text("📱 \(device.name) @ \(device.ipAddress):\(device.port)")
//                                .font(.headline)
//                        }
//
//                        if let status = appState.status {
//                            Text("🔋 Battery: \(status.battery.level)% \(status.battery.isCharging ? "⚡️ Charging" : "")")
//                            Text("🎵 Now Playing: \(status.music.title) by \(status.music.artist)")
//                        }
//                    }
//                    .padding()
//                    .font(.largeTitle)
//                    .transition(.blurReplace)
//                    .toolbar {
//                        ToolbarItem(placement: .primaryAction) {
//                            Button {
//                                // Refresh
//                            } label: {
//                                Label("Refresh", systemImage: "repeat")
//                            }
//                        }
//                    }

                case .settings:
                    SettingsView()
                        .transition(.blurReplace)
                        .toolbar {
                            ToolbarItem(placement: .primaryAction) {
                                Button {
                                    showAboutSheet = true
                                } label: {
                                    Label("About", systemImage: "info")
                                }
                            }
                        }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: AppState.shared.selectedTab)
            .frame(minWidth: 550)
        }
        .onChange(of: appState.device) {
            if appState.device == nil {
                AppState.shared.selectedTab = .settings
            } else {
                AppState.shared.selectedTab = .notifications
            }
        }
        .toolbar {
            ToolbarItem(placement: .secondaryAction) {
                Picker("Tab", selection: $appState.selectedTab) {
                    ForEach(TabIdentifier.availableTabs) { tab in
                        Label(tab.rawValue, systemImage: tab.icon)
                            .labelStyle(.iconOnly)
                            .tag(tab)
                    }
                }
                .pickerStyle(.palette)
            }

            ToolbarItem(placement: .secondaryAction) {
                Button("Feedback", systemImage: "exclamationmark.bubble"){
                    if let url = URL(string: "https://github.com/sameerasw/airsync-mac/issues/new/choose") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
        .sheet(isPresented: $showAboutSheet) {
            AboutView(
                onClose: { showAboutSheet = false }
            )
        }
    }
}

#Preview {
    AppContentView()
}
