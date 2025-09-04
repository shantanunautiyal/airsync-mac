//
//  WelcomeView.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2025-09-02.
//

import SwiftUI

struct WelcomeView: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            if let appIcon = NSApplication.shared.applicationIconImage {
                Image(nsImage: appIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(radius: 4)
            }

            Text("AirSync")
                .font(.system(size: 48, weight: .bold))
                .tracking(0.5)

            Text("Sync notifications, clipboard, and more between your Mac and Android. First, install AirSync on your Android device.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 520)

            HStack{
                GlassButtonView(
                    label: "How to use?",
                    systemImage: "questionmark.circle",
                    size: .extraLarge,
                    action: {
                        if let url = URL(string: "https://airsync.notion.site") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                )
                .transition(.identity)

                GlassButtonView(
                    label: "Let's Start!",
                    systemImage: "arrow.right.circle",
                    size: .extraLarge,
                    primary: true,
                    action: onNext
                )
                .transition(.identity)
            }
        }
    }
}

#Preview {
    WelcomeView(onNext: {})
}
