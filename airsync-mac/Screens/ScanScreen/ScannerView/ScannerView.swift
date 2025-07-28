//
//  ScannerView.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-28.
//

import SwiftUI
import QRCode
internal import SwiftImageReadWrite

struct ScannerView: View {
    var body: some View {
        VStack {
            Spacer()

            if let cgImage = qrGenerate() {
                Image(decorative: cgImage, scale: 1.0)
                    .resizable()
                    .interpolation(.none)
                    .frame(width: 190, height: 190)
                    .accessibilityLabel("QR Code")
                    .shadow(radius: 10)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.clear)
                            .blur(radius: 1)
                    )
                Text("Scan to connect")
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 200, height: 200)
                    .overlay(
                        Text("QR Code\nUnavailable")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                    )
            }

            Spacer()
        }
    }
}

#Preview {
    ScannerView()
}

func qrGenerate() -> CGImage? {
    do {
        let builder = try QRCode.build
            .text("https://www.youtube.com/watch?v=dQw4w9WgXcQ")
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
            return nil
        }

        return cgImage
    } catch {
        print("❌ QR generation failed: \(error)")
        return nil
    }
}
