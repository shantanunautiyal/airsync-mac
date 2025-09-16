//
//  HomeView.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-27.
//

import SwiftUI
import AppKit

struct HomeView: View {
    @ObservedObject var appState = AppState.shared
    @State private var targetOpacity: Double = 0
    @AppStorage("hasPairedDeviceOnce") private var hasPairedDeviceOnce: Bool = false
    @State var showOnboarding = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            ZStack {
                SidebarView()
                    .transition(.opacity.combined(with: .scale))
            }
            .frame(minWidth: 270)
        } detail: {
            AppContentView()
        }
        .navigationTitle(appState.device?.name ?? "AirSync")
        .background(.background.opacity(appState.windowOpacity))
        .toolbarBackground(
            appState.toolbarContrast ? Material.ultraThinMaterial.opacity(1)
            : Material.ultraThinMaterial.opacity(0),
            for: .windowToolbar
        )
        // Show onboarding sheet when needed
        .onAppear {
            if hasPairedDeviceOnce == false {
                showOnboarding = true
                appState.isOnboardingActive = true
            }
            updateSidebarVisibility()
        }
        .onChange(of: appState.device) { _, _ in
            updateSidebarVisibility()
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView()
                .frame(minWidth: 640, minHeight: 420)
        }
        .onChange(of: showOnboarding) { oldValue, newValue in
            if !newValue {
                appState.isOnboardingActive = false
            }
        }
        .onChange(of: appState.isOnboardingActive) { oldValue, newValue in
            // Force view update to refresh window properties
        }
    }

    private func updateSidebarVisibility() {
        withAnimation(.easeInOut(duration: 0.3)) {
            columnVisibility = appState.device != nil ? .all : .detailOnly
        }
    }
}

#Preview {
    HomeView()
}
