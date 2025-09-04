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

enum OnboardingStep {
    case welcome
    case installAndroid
    case mirroringSetup
    case done
}

struct OnboardingView: View {
    @ObservedObject var appState = AppState.shared
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasPairedDeviceOnce") private var hasPairedDeviceOnce: Bool = false

    @State private var currentStep: OnboardingStep = .welcome

    var body: some View {
        ZStack {
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                .edgesIgnoringSafeArea(.all)

            Group {
                switch currentStep {
                case .welcome:
                    WelcomeView(onNext: { withAnimation(.easeInOut(duration: 0.25)) { currentStep = .installAndroid } })
                case .installAndroid:
                    InstallAndroidView(onNext: { withAnimation(.easeInOut(duration: 0.25)) { currentStep = .mirroringSetup } })
                case .mirroringSetup:
                    MirroringSetupView(
                        onNext: { withAnimation(.easeInOut(duration: 0.25)) { currentStep = .done } },
                        onSkip: { withAnimation(.easeInOut(duration: 0.25)) { currentStep = .done } }
                    )
                case .done:
                    Color.clear.onAppear {
                        hasPairedDeviceOnce = true
                        dismiss()
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
