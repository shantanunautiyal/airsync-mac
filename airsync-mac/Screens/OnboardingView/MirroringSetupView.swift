//
//  MirroringSetupView.swift
//  AirSync
//
//  Created by AI Assistant on 2025-09-04.
//

import SwiftUI
import AppKit

struct MirroringSetupView: View {
    let onNext: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Optional Setup")
                .font(.title)
                .multilineTextAlignment(.center)
                .padding()

            Text("Mirroring features are currently under development.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: 500)

            HStack(spacing: 16) {
                GlassButtonView(
                    label: "Continue",
                    systemImage: "arrow.right.circle",
                    size: .large,
                    primary: true,
                    action: onNext
                )
                .transition(.identity)
            }
        }
    }
}

#Preview {
    MirroringSetupView(onNext: {}, onSkip: {})
}