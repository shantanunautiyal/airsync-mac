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
    @Environment(\.openWindow) private var openWindow
    @State private var hostingWindow: NSWindow?

    var body: some View {
        ZStack {
            WindowAccessor { window in
                hostingWindow = window
            }
            Color.clear
                .background(.background.opacity(appState.windowOpacity))
                .ignoresSafeArea()

            Group {
                if showQR {
                    // Reuse existing ScannerView which generates and shows the QR for pairing
                    ScannerView()
                        .transition(.opacity)
                        .padding()
                } else {
                    VStack(spacing: 20) {
                        Text("AirSync")
                            .font(.system(size: 48, weight: .bold))
                            .tracking(0.5)

                        Text("Sync notifications, clipboard, and more between your Mac and Android. Get started by pairing your phone.")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 520)

                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showQR = true
                            }
                        }) {
                            Text("Lets start!")
                                .font(.headline)
                                .padding(.horizontal, 28)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.accentColor)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
        .frame(minWidth: 640, minHeight: 420)
        .onChange(of: appState.device) { newDevice in
            if newDevice != nil {
                openWindow(id: "main")
                hostingWindow?.close()
            }
        }
    }
}

#Preview {
    OnboardingView()
}


