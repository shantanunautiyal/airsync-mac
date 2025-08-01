//
//  HomeView.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-27.
//

import SwiftUI



struct HomeView: View {
    @ObservedObject var appState = AppState.shared
    @State private var isDisconnected: Bool = false

    var body: some View {
        NavigationSplitView {
            VStack {
                ZStack {
                    if appState.device != nil {
                        SidebarView()
                            .transition(.opacity.combined(with: .scale))
                    } else {
                        ScannerView()
                            .transition(.opacity.combined(with: .scale))
                    }
                }
                .animation(.easeInOut(duration: 0.35), value: appState.device)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(minWidth: 270)
            .navigationTitle("Devices")
        } detail: {
            AppContentView()
        }
        .navigationTitle(appState.device?.name ?? "AirSync")
        .sheet(isPresented: $isDisconnected) {
            SettingsView()
        }
    }
}



#Preview {
    HomeView()
}


#Preview {
    HomeView()
}
