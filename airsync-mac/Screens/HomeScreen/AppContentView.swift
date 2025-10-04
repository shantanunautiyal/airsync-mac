//
//  AppContentView.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-28.
//

import SwiftUI
import AVFoundation
import AppKit
internal import Combine

struct AppContentView: View {
    @ObservedObject var appState = AppState.shared
    @State private var showAboutSheet = false
    @State private var showHelpSheet = false
    @AppStorage("notificationStacks") private var notificationStacks = true
    @State private var showDisconnectAlert = false
    @State private var screenCaptureAllowed: Bool = true
    @State private var awaitingServerStart: Bool = false

    private func checkScreenRecordingPermission() {
        // Preflight check for Screen Recording permission
        screenCaptureAllowed = CGPreflightScreenCaptureAccess()
    }

    private func requestScreenRecordingPermission() {
        // If not allowed, request access. This may prompt the user and require app restart
        if !CGPreflightScreenCaptureAccess() {
            let granted = CGRequestScreenCaptureAccess()
            screenCaptureAllowed = granted
            if !granted {
                // Guide user to System Settings if they denied
                openScreenRecordingSystemSettings()
            }
        } else {
            screenCaptureAllowed = true
        }
    }

    private func openScreenRecordingSystemSettings() {
        // Open the Screen Recording privacy pane in System Settings
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Group {
                switch appState.selectedTab {
                case .notifications:
                    NotificationView()
                        .transition(.opacity)
                        .toolbar {
                            if (appState.notifications.count > 0){
                                ToolbarItem(placement: .primaryAction) {
                                Button {
                                        notificationStacks.toggle()
                                    } label: {
                                        Label(L("notifications.actions.toggleStacks"), systemImage: notificationStacks ? "mail" : "mail.stack")
                                    }
                                    .help(notificationStacks ? "Switch to stacked view" : "Switch to expanded view")
                                }
                                ToolbarItem(placement: .primaryAction) {
                                    Button {
                                        appState.clearNotifications()
                                    } label: {
                                        Label(L("common.clear"), systemImage: "wind")
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
                    .transition(.opacity)

                case .transfers:
                    TransfersView()
                        .transition(.opacity)
                        .toolbar {
                            ToolbarItem(placement: .primaryAction) {
                                Button {
                                    AppState.shared.removeCompletedTransfers()
                                } label: {
                                    Label(L("transfers.actions.clearCompleted"), systemImage: "trash")
                                }
                                .help("Remove all completed transfers from the list")
                                .keyboardShortcut(
                                    .delete,
                                    modifiers: .command
                                )
                            }
                        }

                case .sms:
                    SmsView()
                        .transition(.opacity)
                        
                case .health:
                    HealthView()
                        .transition(.opacity)

                case .settings:
                    SettingsView()
                        .transition(.opacity)
                        .toolbar {
                            ToolbarItemGroup{
                                Button("Help", systemImage: "questionmark.circle"){
                                    showHelpSheet = true
                                }
                                .help("Feedback and How to?")

                                Button {
                                    showAboutSheet = true
                                } label: {
                                    Label(L("common.about"), systemImage: "info")
                                }
                                .help("View app information and version details")
                            }

                            if appState.device != nil {
                                ToolbarItemGroup{
                                    Button {
                                        showDisconnectAlert = true
                                    } label: {
                                        Label(L("device.actions.disconnect"), systemImage: "iphone.slash")
                                    }
                                    .help("Disconnect Device")
                                }
                            }
                        }

                case .qr:
                    ScannerView()
                        .transition(.opacity)
                        .toolbar {
                            ToolbarItemGroup{
                                Button("Help", systemImage: "questionmark.circle"){
                                    showHelpSheet = true
                                }
                                .help("Feedback and How to?")


                                Button("Refresh", systemImage: "repeat"){
                                    WebSocketServer.shared.stop()
                                    WebSocketServer.shared.start()
                                    // Wait until the server reports .started before refreshing QR
                                    awaitingServerStart = true
                                }
                                .help("Refresh server")
                            }
                        }
                default:
                    EmptyView()
                        .transition(.opacity)
                }
            }
            }
            .id(appState.selectedTab)
            .overlay(alignment: .top) {
                if !screenCaptureAllowed {
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: "rectangle.badge.record")
                            .foregroundStyle(.red)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Screen Recording Required")
                                .font(.headline)
                            Text("Enable Screen Recording in System Settings to allow mirroring.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Enable") {
                            requestScreenRecordingPermission()
                        }
                        .buttonStyle(.borderedProminent)
                        Button("Open Settings") {
                            openScreenRecordingSystemSettings()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(12)
                    .background(.thinMaterial, in: .rect(cornerRadius: 14))
                    .padding([.horizontal, .top], 12)
                }
            }
            .frame(minWidth: 550, minHeight: 400)
        }
        .onAppear {
            print("AppContentView onAppear")
            checkScreenRecordingPermission()
            DispatchQueue.main.async {
                // Ensure the correct tab is selected when the view appears
                // This fixes the bug where the scanner tab shows even when connected
                if appState.device == nil {
                    AppState.shared.selectedTab = .qr
                } else {
                    AppState.shared.selectedTab = .notifications
                }
            }
        }
        .onChange(of: appState.device) { _, newValue in
            var t = Transaction()
            t.disablesAnimations = true
            withTransaction(t) {
                if newValue == nil {
                    appState.selectedTab = .qr
                } else if appState.selectedTab == .qr {
                    appState.selectedTab = .notifications
                }
            }
        }
        .onReceive(appState.$webSocketStatus) { status in
            guard awaitingServerStart else { return }
            switch status {
            case .started:
                AppState.shared.shouldRefreshQR = true
                awaitingServerStart = false
            case .failed(let error):
                print("[ui] WebSocket failed to start: \(error)")
                awaitingServerStart = false
            default:
                break
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                HStack(spacing: 2) {
                    ForEach(AppState.availableTabs) { tab in
                        NavigationTabView(tab: tab, isSelected: appState.selectedTab == tab, action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                appState.selectedTab = tab
                            }
                        })
                    }
                }
                .padding(.horizontal, 8)
            }


        }
        .sheet(isPresented: $showAboutSheet) {
            AboutView(
                onClose: { showAboutSheet = false }
            )
        }
        .sheet(isPresented: $showHelpSheet) {
            HelpWebSheet(
                isPresented: $showHelpSheet
            )
        }
        .alert(isPresented: $showDisconnectAlert) {
            Alert(
                title: Text("Disconnect Device"),
                message: Text("Do you want to disconnect \(appState.device?.name ?? "device")?"),
                primaryButton: .destructive(Text("Disconnect")) {
                    appState.disconnectDevice()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
}

#Preview {
    AppContentView()
}
