//
//  GlassButtonView.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-28.
//

import SwiftUI

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
            labelContent
        }
        .controlSize(size)
        .modifier(LabelStyleModifier(iconOnly: iconOnly))
        .applyGlassIfAvailable()
    }

    @ViewBuilder
    private var labelContent: some View {
        if let systemImage {
            Label(label, systemImage: systemImage)
        } else if let image {
            Label(label, image: image)
        } else {
            Text(label)
        }
    }
}

// Conditional label style
struct LabelStyleModifier: ViewModifier {
    var iconOnly: Bool

    func body(content: Content) -> some View {
        if iconOnly {
            content.labelStyle(IconOnlyLabelStyle())
        } else {
            content.labelStyle(TitleAndIconLabelStyle())
        }
    }
}




#Preview {
    GlassButtonView(label: "Button", systemImage: "xmark")
}
