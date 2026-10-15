//
//  RecentAppsGridView.swift
//  AirSync
//
//  Created by Sameera Wijerathna on 2026-03-11.
//

import SwiftUI

struct RecentAppsGridView: View {
    @ObservedObject var appState = AppState.shared
    
    var body: some View {
        HStack(spacing: 2) {

            Spacer()
            
            ForEach(0..<min(5, appState.recentApps.count), id: \.self) { index in
                RecentAppIconView(app: appState.recentApps[index])
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

private struct RecentAppIconView: View {
    let app: AndroidApp
    @ObservedObject var appState = AppState.shared
    @State private var isHovered = false
    
    var body: some View {
        Button {
            appState.trackAppUse(app) // Move to front
            if appState.useNativeMirroringByDefault || !appState.adbConnected {
                print("[apps] Launching recent app via Native Mirroring: \(app.packageName)")
                WebSocketServer.shared.sendMirrorRequest(action: "start", mode: "app", package: app.packageName)
                appState.isNativeMirroring = true
            } else if let device = appState.device, appState.adbConnected {
                print("[apps] Launching recent app via scrcpy: \(app.packageName)")
                ADBConnector.startScrcpy(
                    ip: device.ipAddress,
                    port: appState.adbPort,
                    deviceName: device.name,
                    package: app.packageName
                )
            }
        } label: {
            ZStack {
                if let iconPath = app.iconUrl, let image = Image(filePath: iconPath) {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 36, height: 36)
                        .cornerRadius(10)
                } else {
                    Image(systemName: "app.badge")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .frame(width: 36, height: 36)
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}


#Preview {
    RecentAppsGridView()
        .background(Color.blue.opacity(0.3))
}
