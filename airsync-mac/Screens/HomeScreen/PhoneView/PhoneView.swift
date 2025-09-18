//
//  PhoneView.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-27.
//

import SwiftUI

struct PhoneView: View {
    @ObservedObject var appState = AppState.shared
    @State private var displayedImage: NSImage?
    // 3D tilt state
    @State private var tiltX: Double = 0
    @State private var tiltY: Double = 0
    @State private var isInteracting: Bool = false

    var body: some View {
        GeometryReader { geo in
            let cardWidth: CGFloat = 220
            let cardHeight: CGFloat = 460
            let corner: CGFloat = 24
            ZStack {
                // Wallpaper background layer(s) WITH 3D tilt
                FadingImageView(image: displayedImage, duration: 0.75)
                    .overlay(
                        LinearGradient(
                            colors: [Color.black.opacity(0.35), Color.black.opacity(0.05)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
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
            .onAppear { updateImage() }
            .onChange(of: appState.status?.music.isPlaying) { updateImage() }
            .onChange(of: appState.status?.music.albumArt) { updateImage() }
            .onChange(of: AppState.shared.currentDeviceWallpaperBase64) { updateImage() }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func updateImage() {
        let base64 = (appState.status?.music.isPlaying ?? false)
            ? appState.status?.music.albumArt
            : AppState.shared.currentDeviceWallpaperBase64

        guard let base64 = base64,
              let data = Data(base64Encoded: base64.stripBase64Prefix()),
              let nsImage = NSImage(data: data) else { return }
        // Setting displayedImage triggers fade in representable
        displayedImage = nsImage
    }
}

#Preview {
    PhoneView()
}

struct ScreenView: View {
    @ObservedObject var appState = AppState.shared
    var body: some View {
        VStack{
            if (appState.status != nil){
                DeviceStatusView()
                    .transition(.opacity.combined(with: .scale))
            }

            Spacer()

            TimeView()
                .transition(.opacity.combined(with: .scale))

            Spacer()

            if let music = appState.status?.music,
               let title = appState.status?.music.title.trimmingCharacters(in: .whitespacesAndNewlines),
               !title.isEmpty,
               !appState.isMusicCardHidden {

                MediaPlayerView(music: music)
                    .transition(.opacity.combined(with: .scale))
            } else {
                Spacer()
            }

            if appState.device != nil {

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
                    .keyboardShortcut(
                        "f",
                        modifiers: .command
                    )


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
                        .keyboardShortcut(
                            "p",
                            modifiers: .command
                        )
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
                        .keyboardShortcut(
                            "p",
                            modifiers: [.command, .shift]
                        )
                    }
                }
            }

        }
        .padding(8)
        .animation(
            .easeInOut(duration: 0.35),
            value: AppState.shared.adbConnected
        )
        .animation(
            .easeInOut(duration: 0.28),
            value: appState.isMusicCardHidden
        )
    }
}

// MARK: - Fading Image Backed by NSView for smoother layer transitions
private struct FadingImageView: NSViewRepresentable {
    let image: NSImage?
    let duration: TimeInterval

    func makeNSView(context: Context) -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layerContentsRedrawPolicy = .onSetNeedsDisplay
        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let layer = nsView.layer else { return }
        layer.masksToBounds = true

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        // Remove old image sublayers beyond top 2 to avoid buildup
        if let sublayers = layer.sublayers, sublayers.count > 2 {
            sublayers.dropLast(2).forEach { $0.removeFromSuperlayer() }
        }

        let newContents = image
        if let newContents, let cg = newContents.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            let newLayer = CALayer()
            newLayer.contents = cg
            newLayer.frame = layer.bounds
            newLayer.contentsGravity = .resizeAspectFill
            newLayer.opacity = 0
            layer.addSublayer(newLayer)

            let fade = CABasicAnimation(keyPath: "opacity")
            fade.fromValue = 0
            fade.toValue = 1
            fade.duration = duration
            fade.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            newLayer.add(fade, forKey: "fade")
            newLayer.opacity = 1

            // Fade out previous top layer (excluding this one)
            if let sublayers = layer.sublayers, sublayers.count > 1 {
                let previous = sublayers[sublayers.count - 2]
                let fadeOut = CABasicAnimation(keyPath: "opacity")
                fadeOut.fromValue = previous.opacity
                fadeOut.toValue = 0
                fadeOut.duration = duration
                fadeOut.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                previous.add(fadeOut, forKey: "fadeOut")
                previous.opacity = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) {
                    previous.removeFromSuperlayer()
                }
            }
        }
        CATransaction.commit()
        // Keep layer resized on parent layout changes
        DispatchQueue.main.async {
            layer.sublayers?.forEach { $0.frame = layer.bounds }
        }
    }
}
