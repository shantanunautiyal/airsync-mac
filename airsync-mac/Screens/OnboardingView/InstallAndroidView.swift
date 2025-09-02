//
//  InstallAndroidView.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2025-09-02.
//

import SwiftUI
import QRCode
internal import SwiftImageReadWrite

struct InstallAndroidView: View {

    @State private var qrImage: CGImage?
    @AppStorage("hasPairedDeviceOnce") private var hasPairedDeviceOnce: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            Text("Get started by installing the app on your Android device.")
                .font(.title)
                .multilineTextAlignment(.center)
                .padding()
            Text("The app is currently pending approval on Google Play in Early Access.")
                .font(.callout)
                .multilineTextAlignment(.center)

            GlassButtonView(
                label: "First, Join the Google group",
                size: .extraLarge,
                action: {
                    if let url = URL(string: "https://groups.google.com/forum/#!forum/airsync-testing/join") {
                        NSWorkspace.shared.open(url)
                    }
                }
            )
            .transition(.identity)

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

            Text("Scan the QR code to download the app from Google Play Early Access or use the below link.")
                .multilineTextAlignment(.center)
                .padding()


            GlassButtonView(
                label: "Enroll and install from web",
                size: .extraLarge,
                action: {
                    if let url = URL(string: "https://play.google.com/apps/testing/com.sameerasw.airsync") {
                        NSWorkspace.shared.open(url)
                    }
                }
            )
            .transition(.identity)

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
    }

    /// Generates a QR code for the Android app download link
    func generateQRAsync() {
        let text = "https://play.google.com/store/apps/details?id=com.sameerasw.airsync"

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
    InstallAndroidView()
}

