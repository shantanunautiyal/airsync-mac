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
                if #available(macOS 26.0, *) {
                    DeviceStatusView()
                        .padding()
                        .background(.clear)
                        .glassEffect(in: .rect(cornerRadius: 20))
                } else {
                    DeviceStatusView()
                        .padding()
                }
            }

            PhoneView()

        }
        .frame(minWidth: 270, minHeight: 400)
        .safeAreaInset(edge: .bottom) {
            VStack{
                HStack{

                    if appState.adbConnected{
                        if #available(macOS 26.0, *) {
                            GlassButtonView(
                                label: "Mirror",
                                systemImage: "apps.iphone",
                                action: {ADBConnector.startScrcpy(ip: appState.device?.ipAddress ?? "", port: appState.adbPort)}
                            )
                            .buttonStyle(.glass)
                        } else {
                            GlassButtonView(
                                label: "Mirror",
                                systemImage: "apps.iphone",
                                action: {ADBConnector.startScrcpy(ip: appState.device?.ipAddress ?? "", port: appState.adbPort)}
                            )
                        }
                    }

                    if #available(macOS 26.0, *) {
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
                        .buttonStyle(.glass)
                    } else {
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
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }
}

#Preview {
    SidebarView()
}
