//
//  ScreenView.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2025-09-20.
//

import SwiftUI

struct ScreenView: View {
    @ObservedObject var appState = AppState.shared
    var body: some View {
        VStack{

            Spacer()

            TimeView()
                .transition(.opacity.combined(with: .scale))

            Spacer()

            if appState.device != nil {

                HStack(spacing: 10){
                    GlassButtonView(
                        label: "Send",
                        systemImage: "square.and.arrow.up",
                        // FIXED: The 'adbConnected' property was removed.
                        // You need to decide the new logic for this.
                        // Using 'false' as a default to always show the label.
                        iconOnly: false,
                        action: {
                            let panel = NSOpenPanel()
                            panel.canChooseFiles = true
                            panel.canChooseDirectories = false
                            panel.allowsMultipleSelection = false
                            panel.begin { response in
                                if response == .OK, let url = panel.url {
                                    AppState.shared.sendFile(url: url)
                                }
                            }
                        }
                    )
                    .transition(.identity)
                    .keyboardShortcut(
                        "f",
                        modifiers: .command
                    )
                }
            }
            if (appState.status != nil){
                DeviceStatusView()
                    .transition(.scale.combined(with: .opacity))
                    .animation(.interpolatingSpring(stiffness: 200, damping: 30), value: appState.isMusicCardHidden)
            }

        }
        .padding(8)
        // REMOVED: This animation was tied to the deleted 'adbConnected' property.
        // .animation(
        //     .easeInOut(duration: 0.35),
        //     value: AppState.shared.adbConnected
        // )
        .animation(
            .easeInOut(duration: 0.28),
            value: appState.isMusicCardHidden
        )
    }
}

#Preview {
    ScreenView()
}
