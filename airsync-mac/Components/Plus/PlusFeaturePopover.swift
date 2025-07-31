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
                if #available(macOS 26.0, *) {
                    Button("See more") {
                        AppState.shared.selectedTab = .settings
                    }
                    .buttonStyle(.glass)
                } else {
                    Button("See more") {
                        AppState.shared.selectedTab = .settings
                    }
                    .buttonStyle(.borderedProminent)
                }
                Spacer()
            }
        }
        .padding()
        .frame(width: 250)
    }
}
