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

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                switch selectedTab {
                case .notifications:
                    List(0..<30, id: \.self) { _ in
                        NotificationView()
                    }
                    .scrollContentBackground(.hidden)
                    .background(.clear)
                    .transition(.blurReplace)
                    .toolbar{
                        ToolbarItem(placement: .primaryAction) {
                            Button {

                            } label: {
                                Label("Clear", systemImage: "wind")
                            }
                        }
                    }

                case .apps:
                    VStack{
                        Text("(っ◕‿◕)っ")
                        Text("Connected to: \(server.connectedDevice?.name ?? "None")")
                        List(server.notifications) { notification in
                            Text("\(notification.app): \(notification.title) - \(notification.body)")
                        }
                        Text("Battery: \(server.deviceStatus?.battery.level ?? 0)%")

                    }
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
