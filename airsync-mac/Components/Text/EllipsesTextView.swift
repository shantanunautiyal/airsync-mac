//
//  MarqueeTextView.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2025-08-05.
//

import SwiftUI

struct EllipsesTextView: View {
    let text: String
    let font: Font

    var body: some View {
        Text(text)
            .font(font)
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
