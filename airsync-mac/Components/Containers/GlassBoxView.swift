//
//  GlassBoxView.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-28.
//

import SwiftUI

struct GlassBoxView: View {
    var color: Color = .clear
    var width: CGFloat? = nil
    var height: CGFloat? = nil
    var maxWidth: CGFloat? = nil
    var maxHeight: CGFloat? = nil
    var radius: CGFloat = 16.0

    var body: some View {
        if #available(macOS 26.0, *) {
            Rectangle()
                .fill(color)
                .frame(width: width, height: height)
                .frame(maxWidth: maxWidth, maxHeight: maxHeight)
                .glassEffect(in: .rect(cornerRadius: radius))
                .cornerRadius(radius)
        } else {
            Rectangle()
                .fill(color)
                .frame(width: width, height: height)
                .frame(maxWidth: maxWidth, maxHeight: maxHeight)
                .cornerRadius(radius)
        }
    }
}


#Preview {
    GlassBoxView(width: 100, height: 100)
}
