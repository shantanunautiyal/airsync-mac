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
    // 3D tilt state
    @State private var tiltX: Double = 0
    @State private var tiltY: Double = 0
    @State private var isInteracting: Bool = false

    var body: some View {
        GeometryReader { geo in
            let cardWidth: CGFloat = 180
            let cardHeight: CGFloat = 400
            let corner: CGFloat = 24
            ZStack {
                // Wallpaper background layer(s) WITH 3D tilt
                ZStack {
                    Group {
                        if let image = currentImage {
                            Image(nsImage: image)
                                .resizable()
                                .scaledToFill()
                                .transition(.blurReplace)
                        }
                        if let image = nextImage {
                            Image(nsImage: image)
                                .resizable()
                                .scaledToFill()
                                .opacity(nextImageOpacity)
                                .transition(.blurReplace)
                        }
                    }
                    .overlay(
                        // Subtle gradient for readability
                        LinearGradient(
                            colors: [Color.black.opacity(0.35), Color.black.opacity(0.05)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                }
                .scaleEffect(isInteracting ? 1.085 : 1.035)
                .rotation3DEffect(.degrees(tiltX), axis: (x: 1, y: 0, z: 0))
                .rotation3DEffect(.degrees(tiltY), axis: (x: 0, y: 1, z: 0))
                .animation(.easeOut(duration: 0.22), value: tiltX)
                .animation(.easeOut(duration: 0.22), value: tiltY)
                .animation(.easeOut(duration: 0.25), value: isInteracting)

                // Foreground content
                ScreenView()
                    .padding(.horizontal, 4)
                    .transition(.blurReplace)
            }
            .frame(width: cardWidth, height: cardHeight)
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.25), radius: 22, x: 0, y: 8)
            .contentShape(RoundedRectangle(cornerRadius: corner))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let size = CGSize(width: cardWidth, height: cardHeight)
                        let origin = CGPoint(
                            x: value.location.x - (geo.size.width - cardWidth) / 2,
                            y: value.location.y - (geo.size.height - cardHeight) / 2
                        )
                        let dx = origin.x - size.width / 2
                        let dy = origin.y - size.height / 2
                        let maxAngle: CGFloat = 5 // tight limit to prevent edge exposure
                        if !isInteracting { isInteracting = true }
                        withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.75, blendDuration: 0.2)) {
                            let rawY = Double((dx / size.width) * maxAngle)
                            let rawX = Double((-dy / size.height) * maxAngle)
                            let limit = Double(maxAngle)
                            tiltY = max(min(rawY, limit), -limit)
                            tiltX = max(min(rawX, limit), -limit)
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            tiltX = 0
                            tiltY = 0
                            isInteracting = false
                        }
                    }
            )
            .onAppear { updateImage(animated: false) }
            .onChange(of: appState.status?.music.isPlaying) { updateImage(animated: true) }
            .onChange(of: appState.status?.music.albumArt) { updateImage(animated: true) }
            .onChange(of: AppState.shared.currentDeviceWallpaperBase64) { updateImage(animated: true) }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 180, height: 400)
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
