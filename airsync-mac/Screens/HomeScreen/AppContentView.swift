//
//  AppContentView.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-28.
//

import SwiftUI

enum TabIdentifier: String, CaseIterable, Identifiable {
    case notifications = "notifications.tab"
    case apps = "apps.tab"
    case transfers = "transfers.tab"
    case settings = "settings.tab"
    case qr = "qr.tab"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .notifications: return "bell.badge"
        case .apps: return "app"
        case .transfers: return "tray.and.arrow.up"
        case .settings: return "gear"
            case .qr: return "qrcode"
        }
    }

    var shortcut: KeyEquivalent {
        switch self {
            case .notifications: return "1"
            case .apps: return "2"
            case .transfers: return "3"
            case .settings: return ","
            case .qr: return "."
        }
    }

    static var availableTabs: [TabIdentifier] {
        var tabs: [TabIdentifier] = [.qr, .settings]
        if AppState.shared.device != nil {
            tabs.remove(at: 0)
            tabs.insert(.notifications, at: 0)
            tabs.insert(.apps, at: 1)
            tabs.insert(.transfers, at: 2)
        }
        return tabs
    }
}

struct AppContentView: View {
    @ObservedObject var appState = AppState.shared
    @State private var showAboutSheet = false
    @State private var showHelpSheet = false
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
                                    .help(notificationStacks ? "Switch to stacked view" : "Switch to expanded view")
                                }
                                ToolbarItem(placement: .primaryAction) {
                                    Button {
                                        appState.clearNotifications()
                                    } label: {
                                        Label("Clear", systemImage: "wind")
                                    }
                                    .help("Clear all notifications")
                                    .keyboardShortcut(
                                        .delete,
                                        modifiers: .command
                                    )
                                .badge(appState.notifications.count)
                                }
                            }
                        }

                case .apps:
                    AppsView()
                    .font(.largeTitle)
                    .transition(.blurReplace)

                case .transfers:
                    TransfersView()
                        .transition(.blurReplace)
                        .toolbar {
                            ToolbarItem(placement: .primaryAction) {
                                Button {
                                    AppState.shared.removeCompletedTransfers()
                                } label: {
                                    Label("Clear completed", systemImage: "trash")
                                }
                                .help("Remove all completed transfers from the list")
                                .keyboardShortcut(
                                    .delete,
                                    modifiers: .command
                                )
                            }
                        }

                case .settings:
                    SettingsView()
                        .transition(.blurReplace)
                        .toolbar {
                            ToolbarItemGroup{
                                Button("Help", systemImage: "questionmark.circle"){
                                    showHelpSheet = true
                                }
                                .help("Feedback and How to?")

                                Button {
                                    showAboutSheet = true
                                } label: {
                                    Label("About", systemImage: "info")
                                }
                                .help("View app information and version details")
                            }

                            if appState.device != nil {
                                ToolbarItemGroup{
                                    Button {
                                        appState.disconnectDevice()
                                        ADBConnector.disconnectADB()
                                        appState.adbConnected = false
                                    } label: {
                                        Label("Disconnect", systemImage: "iphone.slash")
                                    }
                                    .help("Disconnect Device")
                                }
                            }
                        }

                case .qr:
                    ScannerView()
                        .transition(.blurReplace)
                        .toolbar {
                            ToolbarItemGroup{
                                Button("Help", systemImage: "questionmark.circle"){
                                    showHelpSheet = true
                                }
                                .help("Feedback and How to?")
                            }
                        }
                }
            }
            .animation(.easeInOut(duration: 0.35), value: AppState.shared.selectedTab)
            .frame(minWidth: 550)
        }
        .onChange(of: appState.device) {
            if appState.device == nil {
                AppState.shared.selectedTab = .qr
            } else {
                AppState.shared.selectedTab = .notifications
            }
        }
        .toolbar {
            ToolbarItem(placement: .secondaryAction) {
                Picker("Tab", selection: $appState.selectedTab) {
                    ForEach(TabIdentifier.availableTabs) { tab in
                        Button(L(tab.rawValue), systemImage: tab.icon) {}
                                .labelStyle(.iconOnly)
                                .tag(tab)
                            .help(L(tab.rawValue))
                                .keyboardShortcut(
                                    tab.shortcut,
                                    modifiers: .command
                                )
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
        .sheet(isPresented: $showHelpSheet) {
            HelpWebSheet(isPresented: $showHelpSheet)
        }
    }
}



#Preview {
    AppContentView()
}

