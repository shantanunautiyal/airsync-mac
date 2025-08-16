//
//  PhoneView.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-27.
//

import SwiftUI

struct PhoneView: View {
    @ObservedObject var appState = AppState.shared

    @State private var currentImage: NSImage?
    @State private var nextImage: NSImage?
    @State private var nextImageOpacity: Double = 0.0

    var body: some View {
        ZStack {

            ZStack {
                if let image = currentImage {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                        .opacity(0.75)
                        .transition(.blurReplace)
                }

                if let image = nextImage {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                        .opacity(nextImageOpacity * 0.75)
                        .transition(.blurReplace)
                }
            }
            .aspectRatio(contentMode: .fill)
            .frame(width: 180, height: 400)
            .cornerRadius(20)

            ScreenView()
                .transition(.blurReplace)
        }
        .frame(width: 190, height: 410)
        .applyGlassViewIfAvailable(cornerRadius: 25)
        .transition(.opacity.combined(with: .scale))
        .onAppear {
            updateImage(animated: false)
        }
        .onChange(of: appState.status?.music.isPlaying) {
            updateImage(animated: true)
        }
        .onChange(of: appState.status?.music.albumArt) {
            updateImage(animated: true)
        }
        .onChange(of: AppState.shared.currentDeviceWallpaperBase64) {
            updateImage(animated: true)
        }
    }

    private func updateImage(animated: Bool) {
        let base64 = (appState.status?.music.isPlaying ?? false)
        ? appState.status?.music.albumArt
        : AppState.shared.currentDeviceWallpaperBase64

        guard let base64 = base64,
              let data = Data(base64Encoded: base64.stripBase64Prefix()),
              let nsImage = NSImage(data: data) else { return }

        if !animated || currentImage == nil {
            currentImage = nsImage
            nextImage = nil
            nextImageOpacity = 0.0
            return
        }

        // Crossfade
        nextImage = nsImage
        nextImageOpacity = 0.0

        withAnimation(.easeInOut(duration: 0.75)) {
            nextImageOpacity = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            currentImage = nsImage
            nextImage = nil
            nextImageOpacity = 0.0
        }
    }
}

#Preview {
    PhoneView()
}


struct StatusBarView: View {
    var body: some View {
            HStack{
                Spacer()
                Circle()
                    .fill(.background.opacity(0.6))
                    .frame(width: 15, height: 15)
                    .padding(5)
                Spacer()
            }
    }
}

struct ScreenView: View {
    @ObservedObject var appState = AppState.shared
    var body: some View {
        VStack{
            StatusBarView()

            Spacer()

            TimeView()
                .transition(.opacity.combined(with: .scale))

            Spacer()

            if let music = appState.status?.music,
               let title = appState.status?.music.title.trimmingCharacters(in: .whitespacesAndNewlines),
               !title.isEmpty {

                MediaPlayerView(music: music)
                    .transition(.opacity.combined(with: .scale))
            } else {
                Spacer()
            }

            HStack(spacing: 10){
                GlassButtonView(
                    label: "Send",
                    systemImage: "square.and.arrow.up",
                    iconOnly: appState.adbConnected,
                    action: {
                        let panel = NSOpenPanel()
                        panel.canChooseFiles = true
                        panel.canChooseDirectories = false
                        panel.allowsMultipleSelection = false
                        panel.begin { response in
                            if response == .OK, let url = panel.url {
                                DispatchQueue.global(qos: .userInitiated).async {
                                    WebSocketServer.shared.sendFile(url: url)
                                }
                            }
                        }
                    }
                )
                .transition(.identity)


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
            }

        }
        .frame(maxWidth: 175, maxHeight: 390)
        .animation(
            .easeInOut(duration: 0.35),
            value: AppState.shared.adbConnected
        )
    }
}

