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

    private func getDeviceName() -> String {
        let deviceName = appState.device?.name ?? "Ready"
        return deviceName
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AirSync - \(getDeviceName())")
                .font(.headline)
                .padding(.bottom, 4)

            Divider()

            if (appState.device != nil) {
                DeviceStatusView()
            }

            HStack {
                GlassButtonView(
                    label: "Open App",
                    systemImage: "arrow.up.forward.app"
                ) {
                    openWindow(id: "main")
                }
            }

            if (appState.adbConnected && appState.isPlus) {
                HStack {

                    GlassButtonView(
                        label: "Android Mirror",
                        systemImage: "iphone.gen3.badge.play"
                    ) {
                        ADBConnector
                            .startScrcpy(
                                ip: appState.device?.ipAddress ?? "",
                                port: appState.adbPort,
                                deviceName: appState.device?.name ?? "My Phone"
                            )
                    }
                }
            }

            Divider()

            GlassButtonView(label: "Quit", systemImage: "power") {
                NSApplication.shared.terminate(nil)
            }

        }
        .padding()
        .frame(width: 250)
    }
}

#Preview {
    MenubarView()
}
