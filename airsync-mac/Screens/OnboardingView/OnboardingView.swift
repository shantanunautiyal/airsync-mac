//
//  OnboardingView.swift
//  AirSync
//
//  Created by AI Assistant on 2025-08-13.
//

import SwiftUI
import AppKit

struct OnboardingView: View {
    @ObservedObject var appState = AppState.shared
    @State private var showQR = false

    var body: some View {
        ZStack {
            Color.clear
                .background(.background.opacity(appState.windowOpacity))
                .ignoresSafeArea()

            Group {
                if showQR {
                    ScannerView()
                        .transition(.opacity)
                        .padding()
                } else {
                    VStack(spacing: 20) {

                        if let appIcon = NSApplication.shared.applicationIconImage {
                            Image(nsImage: appIcon)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                        }

                        Text("AirSync")
                            .font(.system(size: 48, weight: .bold))
                            .tracking(0.5)

                        Text("Sync notifications, clipboard, and more between your Mac and Android. Get started by pairing your phone.")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 520)

                        GlassButtonView(
                            label: "Let's Start!",
                            systemImage: "arrow.right.circle",
                            size: .extraLarge,
                            primary: true,
                            action: {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    showQR = true
                                }
                            }
                        )
                        .transition(.identity)
                    }
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


