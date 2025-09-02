//
//  OnboardingView.swift
//  AirSync
//
//  Created by AI Assistant on 2025-08-13.
//

import SwiftUI
import AppKit
import QRCode
internal import SwiftImageReadWrite

struct OnboardingView: View {
    @ObservedObject var appState = AppState.shared
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasPairedDeviceOnce") private var hasPairedDeviceOnce: Bool = false

    @State private var showQR = false

    var body: some View {
        ZStack {
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                .edgesIgnoringSafeArea(.all)

            Group {
                if showQR {
                    InstallAndroidView()
                } else {
                    WelcomeView(showQR: $showQR)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
    }
}

#Preview {
    OnboardingView()
}
