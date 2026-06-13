//
//  RemotePermissionView.swift
//  airsync-mac
//
//  Created by AirSync on 2026-01-10.
//

import SwiftUI
internal import Combine

struct RemotePermissionView: View {
    @Environment(\.dismiss) var dismiss
    @State private var isTrusted: Bool = false
    @State private var timer: AnyCancellable?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "keyboard.badge.eye")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
                .padding(.bottom, 10)
            
            Text("Remote Control Permission")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("To allow AirSync to simulate keystrokes (arrows, media keys) and control volume, you must enable it under **Privacy & Security > Accessibility** in System Settings.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)

            GlassButtonView(
                label:  !isTrusted ? "Open System Settings" : "You're all set!",
                systemImage: "accessibility",
                primary: true,
            ){
                if isTrusted {
                    dismiss()
                } else {
                    MacRemoteManager.shared.requestAccessibilityPermission()
                }
            }
            
            if !isTrusted {
                VStack(spacing: 8) {
                    Text("⚠️ Note: Enable under **Accessibility**, not 'Remote Control' or 'Input Monitoring'.")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                    
                    Text("If it is already enabled in Accessibility but not recognized, select AirSync and click the '—' (minus) button to remove it, then toggle it again when prompted.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .multilineTextAlignment(.center)
                .padding(.top, 10)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(30)
        .frame(width: 450)
        .onAppear {
            checkPermission()
            timer = Timer.publish(every: 2, on: .main, in: .default)
                .autoconnect()
                .sink { _ in checkPermission() }
        }
        .onDisappear {
            timer?.cancel()
            timer = nil
        }
    }
    
    private func checkPermission() {
        isTrusted = MacRemoteManager.shared.isAccessibilityTrusted()
    }
}

#Preview {
    RemotePermissionView()
}
