//
//  SidebarView.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-28.
//

import SwiftUI


struct SidebarView: View {

    @ObservedObject var appState = AppState.shared
    @State private var isExpandedAllSeas: Bool = false

    var body: some View {
        VStack{
            if (appState.status != nil){
                    DeviceStatusView()
                        .transition(.opacity.combined(with: .scale))
                }

            if let deviceVersion = appState.device?.version,
               isVersion(deviceVersion, lessThan: appState.minAndroidVersion) {
                Label("Your Android app is outdated", systemImage: "iphone.badge.exclamationmark")
                    .padding(4)
            }


            PhoneView()
                .transition(.scale)

        }
        .animation(.easeInOut(duration: 0.5), value: appState.status != nil)
        .frame(minWidth: 270, minHeight: 420)
        .safeAreaInset(edge: .bottom) {
            VStack{
                HStack{

                    if appState.adbConnected{
                            GlassButtonView(
                                label: "Mirror",
                                systemImage: "apps.iphone",
                                action: {
                                    ADBConnector
                                        .startScrcpy(
                                            ip: appState.device?.ipAddress ?? "",
                                            port: appState.adbPort,
                                            deviceName: appState.device?.name ?? "My Phone"
                                        )
                                }
                            )
                            .transition(.identity)
                            .contextMenu {
                                Button("Desktop Mode") {
                                    ADBConnector.startScrcpy(
                                        ip: appState.device?.ipAddress ?? "",
                                        port: appState.adbPort,
                                        deviceName: appState.device?.name ?? "My Phone",
                                        desktop: true
                                    )
                                }
                            }
                    }

                        GlassButtonView(
                            label: "Disconnect",
                            systemImage: "xmark",
                            iconOnly: appState.adbConnected,
                            action: {
                                appState.disconnectDevice()
                                ADBConnector.disconnectADB()
                                appState.adbConnected = false
                            }
                        )
                        .transition(.identity)
                }
                .animation(
                    .easeInOut(duration: 0.35),
                    value: AppState.shared.adbConnected
                )
                .padding(.bottom, 20)
                .offset(y: 12)
            }
        }
    }
}

#Preview {
    SidebarView()
}
