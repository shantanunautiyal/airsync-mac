//
//  OnboardingView.swift
//  AirSync
//
//  Created by AI Assistant on 2025-08-13.
//

import SwiftUI
import AppKit
import QRCode
internal import SwiftImageReadWrite

struct OnboardingView: View {
    @ObservedObject var appState = AppState.shared
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasPairedDeviceOnce") private var hasPairedDeviceOnce: Bool = false

    @State private var showQR = false
    @State private var qrImage: CGImage?

    var body: some View {
        ZStack {
            Color.clear
                .background(.background.opacity(appState.windowOpacity))
                .ignoresSafeArea()

            Group {
                if showQR {
                    VStack {
                        Text("Get started by installing the app on your Android device.")
                            .font(.title)
                            .multilineTextAlignment(.center)
                            .padding()

                        if let qrImage = qrImage {
                            Image(decorative: qrImage, scale: 1.0)
                                .resizable()
                                .interpolation(.none)
                                .frame(width: 190, height: 190)
                                .accessibilityLabel("QR Code to download AirSync Android app")
                                .shadow(radius: 10)
                                .padding()
                        } else {
                            ProgressView("Generating QR…")
                                .frame(width: 100, height: 100)
                        }

                        Text("Scan the QR code to download the app from GitHub.")
                            .multilineTextAlignment(.center)
                            .padding()

                        GlassButtonView(
                            label: "I'm ready",
                            systemImage: "apps.iphone.badge.checkmark",
                            size: .extraLarge,
                            primary: true,
                            action: {
                                hasPairedDeviceOnce = true
                                dismiss()
                            }
                        )
                        .transition(.identity)
                    }
                    .onAppear {
                        if qrImage == nil {
                            generateQRAsync()
                        }
                    }
                } else {
                    VStack(spacing: 20) {
                        if let appIcon = NSApplication.shared.applicationIconImage {
                            Image(nsImage: appIcon)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .shadow(radius: 4)
                        }

                        Text("AirSync")
                            .font(.system(size: 48, weight: .bold))
                            .tracking(0.5)

                        Text("Sync notifications, clipboard, and more between your Mac and Android. First, install AirSync on your Android device.")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 520)

                        HStack{
                            GlassButtonView(
                                label: "How to use?",
                                systemImage: "questionmark.circle",
                                size: .extraLarge,
                                action: {
                                    if let url = URL(string: "https://airsync.notion.site") {
                                        NSWorkspace.shared.open(url)
                                    }
                                }
                            )
                            .transition(.identity)

                            GlassButtonView(
                                label: "Let's Start!",
                                systemImage: "arrow.right.circle",
                                size: .extraLarge,
                                primary: true,
                                action: {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        showQR = true
                                    }
                                }
                            )
                            .transition(.identity)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
    }

    /// Generates a QR code for the Android app download link
    func generateQRAsync() {
        let text = "https://github.com/sameerasw/airsync-android/releases/latest"

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let builder = try QRCode.build
                    .text(text)
                    .quietZonePixelCount(2)
                    .eye.shape(QRCode.EyeShape.RoundedPointingIn())
                    .onPixels.shape(QRCode.PixelShape.Blob())
                    .foregroundColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1.0))
                    .backgroundColor(CGColor(srgbRed: 0.0, green: 0.0, blue: 0.0, alpha: 1.0))
                    .background.cornerRadius(4)

                let imageData = try builder.generate.image(dimension: 200, representation: .png())

                guard let provider = CGDataProvider(data: imageData as CFData),
                      let cgImage = CGImage(
                        pngDataProviderSource: provider,
                        decode: nil,
                        shouldInterpolate: false,
                        intent: .defaultIntent
                      ) else {
                    print("Failed to convert PNG data to CGImage")
                    return
                }

                DispatchQueue.main.async {
                    self.qrImage = cgImage
                }
            } catch {
                print("QR generation failed: \(error)")
            }
        }
    }
}

#Preview {
    OnboardingView()
}
