//
//  GlassButtonView.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-28.
//

import SwiftUI

struct GlassButtonView: View {
    var label: String
    var systemImage: String? = nil
    var image: String? = nil
    var iconOnly: Bool = false
    var size: ControlSize = .large
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            if let systemImage {
                Label(label, systemImage: systemImage)
                    .transition(.identity)
                    .animation(.easeInOut(duration: 0.2), value: systemImage)
            } else if let image {
                Label(label, image: image)
            } else {
                Text(label)
            }
        }
        .buttonStyle(.glass)
        .controlSize(size)
    }
}


#Preview {
    GlassButtonView(label: "Button", systemImage: "xmark")
}
