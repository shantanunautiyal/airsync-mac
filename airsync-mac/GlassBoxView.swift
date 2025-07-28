//
//  GlassBoxView.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-28.
//

import SwiftUI

struct GlassBoxView: View {
    var color: Color = .clear
    var width: CGFloat = .infinity
    var height: CGFloat = .infinity
    var maxWidth: CGFloat?
    var maxHeight: CGFloat?
    var radius: CGFloat = 16.0

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: width, height: height)
            .frame(maxWidth: maxWidth, maxHeight: maxHeight)
            .glassEffect(in: .rect(cornerRadius: radius))
            .cornerRadius(radius)
    }
}


#Preview {
    GlassBoxView(width: 100, height: 100)
}
