//
//  QRCodeGenerator.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-09-02.
//

import Foundation
import QRCode
internal import SwiftImageReadWrite
import CoreGraphics

class QRCodeGenerator {
    static func generateQRCode(for text: String, dimension: Int = 400) async -> CGImage? {
        do {
            let builder = try QRCode.build
                .text(text)
                .quietZonePixelCount(2)
                .eye.shape(QRCode.EyeShape.RoundedPointingIn())
                .onPixels.shape(QRCode.PixelShape.Blob())
                .foregroundColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1.0))
                .backgroundColor(CGColor(srgbRed: 0.0, green: 0.0, blue: 0.0, alpha: 1.0))
                .background.cornerRadius(6)

            let imageData = try builder.generate.image(dimension: dimension, representation: .png())

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
            print("QR generation failed: \(error)")
            return nil
        }
    }
}
