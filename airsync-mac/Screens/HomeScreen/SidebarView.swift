//
//  SidebarView.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-28.
//

import SwiftUI


struct SidebarView: View {

    @ObservedObject var appState = AppState.shared
    @ObservedObject var mirroring = MirroringManager.shared
    @State private var isExpandedAllSeas: Bool = false
    @State private var showDisconnectAlert = false

    var body: some View {
        VStack{

            HStack(alignment: .center) {
                let name = appState.device?.name ?? "AirSync"
                let truncated = name.count > 20
                ? String(name.prefix(20)) + "..."
                : name

                Text(truncated)
                    .font(.title3)
            }
            .padding(8)



            if let deviceVersion = appState.device?.version,
               isVersion(deviceVersion, lessThan: appState.minAndroidVersion) {
                Label(L("sidebar.androidAppOutdated"), systemImage: "iphone.badge.exclamationmark")
                    .padding(4)
            }


            PhoneView()
                .transition(.scale)
                .opacity(appState.device != nil ? 1 : 0.5)


            .animation(.easeInOut(duration: 0.5), value: appState.status != nil)
            .frame(minWidth: 280, minHeight: 400)
            .safeAreaInset(edge: .bottom) {
                HStack{
                    if appState.device != nil {
                        if !mirroring.isMirroring {
                            GlassButtonView(
                                label: "Start Mirroring",
                                systemImage: "rectangle.stack.badge.play",
                                action: {
                                    let resHint = appState.mirrorDesktopMode ? nil : (appState.mirrorResolution.isEmpty ? nil : appState.mirrorResolution)
                                    AppState.shared.requestStartMirroring(
                                        mode: appState.mirrorDesktopMode ? "desktop" : "device",
                                        resolution: resHint,
                                        bitrateMbps: appState.mirrorBitrateMbps
                                    )
                                }
                            )
                            .transition(.identity)
                        } else {
                            GlassButtonView(
                                label: "Stop Mirroring",
                                systemImage: "rectangle.stack.badge.minus",
                                action: {
                                    // Closing the window also stops mirroring, but provide explicit stop as well
                                    MirroringManager.shared.stopMirroring()
                                    AppState.shared.sendStopMirrorRequest()
                                }
                            )
                            .transition(.identity)
                        }

                        GlassButtonView(
                            label: "Disconnect",
                            systemImage: "xmark",
                            action: {
                                showDisconnectAlert = true
                            }
                        )
                        .transition(.identity)
                    } else {
                        Label(L("sidebar.connectDevice"), systemImage: "arrow.2.circlepath.circle")
                    }
                }
                .padding(16)
            }
        }
        .alert(isPresented: $showDisconnectAlert) {
            Alert(
                title: Text("Disconnect Device"),
                message: Text("Do you want to disconnect \"\(appState.device?.name ?? "device")\"?"),
                primaryButton: .destructive(Text("Disconnect")) {
                    appState.disconnectDevice()
                },
                secondaryButton: .cancel()
            )
        }
    }
}

#Preview {
    SidebarView()
}
