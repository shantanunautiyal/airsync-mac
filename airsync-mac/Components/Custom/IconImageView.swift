//
//  IconImageView.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2025-09-19.
//

import SwiftUI

struct IconImageView: View {
    let iconPath: String

    var body: some View {
        if let nsImage = NSImage(contentsOfFile: iconPath) {
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFit()
                .frame(width: 128, height: 128)
        } else {
            Text("⚠️ Could not load .icon file")
        }
    }
}
