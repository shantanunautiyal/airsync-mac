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
                .frame(minWidth: 270)
        } detail: {
            AppContentView()
        }
        .navigationTitle(appState.device?.name ?? "AirSync")
        .background(.background.opacity(appState.windowOpacity))
    }
}



#Preview {
    HomeView()
}


#Preview {
    HomeView()
}
