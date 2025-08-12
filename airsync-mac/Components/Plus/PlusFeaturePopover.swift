//
//  PlusFeaturePopover.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-31.
//

import SwiftUI

struct PlusFeaturePopover: View {
    var message: String = "Available with AirSync+"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(message)
                .font(.headline)
                .padding(.bottom, 4)

            HStack{
                Spacer()
                GlassButtonView(label: "See more", action: {
                    AppState.shared.selectedTab = .settings
                })
                Spacer()
            }
        }
        .padding()
        .frame(width: 250)
    }
}
