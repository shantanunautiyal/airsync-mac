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
        case .notifications: return "bell.badge"
        case .apps: return "app.badge"
        case .settings: return "gear"
        }
    }

    static var availableTabs: [TabIdentifier] {
        var tabs: [TabIdentifier] = [.settings]
        if AppState.shared.device != nil {
            tabs.insert(.notifications, at: 0)
            tabs.insert(.apps, at: 1)
        }
        return tabs
    }
}

struct AppContentView: View {
    @ObservedObject var appState = AppState.shared
    @State private var showAboutSheet = false
    @AppStorage("notificationStacks") private var notificationStacks = true

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                switch AppState.shared.selectedTab {
                case .notifications:
                    NotificationView()
                        .transition(.blurReplace)
                        .toolbar {
                            if (appState.notifications.count > 0){
                                ToolbarItem(placement: .primaryAction) {
                                    Button {
                                        notificationStacks.toggle()
                                    } label: {
                                        Label("Toggle Notification Stacks", systemImage: notificationStacks ? "mail" : "mail.stack")
                                    }
                                }
                                ToolbarItem(placement: .primaryAction) {
                                    Button {
                                        appState.clearNotifications()
                                    } label: {
                                        Label("Clear", systemImage: "wind")
                                    }
                                .badge(appState.notifications.count)
                                }
                            }
                        }

                case .apps:
                    AppsView()
                    .font(.largeTitle)
                    .transition(.blurReplace)

                case .settings:
                    SettingsView()
                        .transition(.blurReplace)
                        .toolbar {
                            ToolbarItem(placement: .primaryAction) {
                                Button("Feedback", systemImage: "exclamationmark.bubble"){
                                    if let url = URL(string: "https://github.com/sameerasw/airsync-mac/issues/new/choose") {
                                        NSWorkspace.shared.open(url)
                                    }
                                }
                            }

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
            .animation(.easeInOut(duration: 0.35), value: AppState.shared.selectedTab)
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
//                        Label(tab.rawValue, systemImage: tab.icon)
//                            .labelStyle(.iconOnly)
//                            .tag(tab)
                        Button(tab.rawValue, systemImage: tab.icon){}
                            .labelStyle(.iconOnly)
                            .tag(tab)
                    }
                }
                .pickerStyle(.palette)
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
