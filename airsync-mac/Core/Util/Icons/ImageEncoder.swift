//
//  ImageEncoder.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-30.
//

import Foundation
import SwiftUI

extension Image {
    init?(base64String: String) {
        var cleaned = base64String
        if let range = cleaned.range(of: "base64,") {
            cleaned = String(cleaned[range.upperBound...])
        }

        guard let data = Data(base64Encoded: cleaned),
              let nsImage = NSImage(data: data) else {
            return nil
        }

        self = Image(nsImage: nsImage)
    }
}
