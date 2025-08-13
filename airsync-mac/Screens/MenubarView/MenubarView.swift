//
//  MenubarView.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2025-08-08.
//

import SwiftUI

struct MenubarView: View {
    @Environment(\.openWindow) var openWindow
    @StateObject private var appState = AppState.shared

    enum Tab: String, CaseIterable, Identifiable {
        case home, notifications, apps

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .notifications: return "bell.fill"
            case .apps: return "app.fill"
            }
        }

        static var availableTabs: [Tab] {
            var tabs: [Tab] = [.home]
            if AppState.shared.device != nil {
                tabs.append(.notifications)
                tabs.append(.apps)
            }
            return tabs
        }
    }

    @State private var selectedTab: Tab = .home

    private func getDeviceName() -> String {
        appState.device?.name ?? "Ready"
    }

    var body: some View {
        VStack() {
            // Header
            // Icon-only Picker for tabs
            Picker("", selection: $selectedTab) {
                ForEach(Tab.availableTabs) { tab in
                    Label(tab.rawValue.capitalized, systemImage: tab.icon)
                        .labelStyle(.iconOnly)
                        .tag(tab)
                        .help(tab.rawValue.capitalized)
                }
            }
            .pickerStyle(.palette)

            Text("AirSync - \(getDeviceName())")
                .font(.headline)


            // Tab content
            ZStack {
                switch selectedTab {
                case .home:
                    VStack(alignment: .center, spacing: 12) {
                        if appState.device != nil {
                            DeviceStatusView()
                            PhoneView()
                        }

                        if appState.adbConnected && appState.isPlus {
                            HStack {
                                GlassButtonView(
                                    label: "Android Mirror",
                                    systemImage: "iphone.gen3.badge.play"
                                ) {
                                    ADBConnector.startScrcpy(
                                        ip: appState.device?.ipAddress ?? "",
                                        port: appState.adbPort,
                                        deviceName: appState.device?.name ?? "My Phone"
                                    )
                                }
                            }
                        }
                    }

                case .notifications:
                    NotificationView()

                case .apps:
                    AppsView()
                }
            }
            .frame( minWidth: 300,minHeight: appState.device != nil ? 480 : 0)


            // Footer
            HStack {
                GlassButtonView(
                    label: "Open App",
                    systemImage: "arrow.up.forward.app"
                ) {
                    openWindow(id: "main")
                }

                GlassButtonView(label: "Quit", systemImage: "power") {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .padding()
    }
}

#Preview {
    MenubarView()
}
