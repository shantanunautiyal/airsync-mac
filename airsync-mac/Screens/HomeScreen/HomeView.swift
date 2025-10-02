//
//  HomeView.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-27.
//

import SwiftUI
import AppKit
internal import Combine

struct HomeView: View {
    @ObservedObject var appState = AppState.shared
    @State private var targetOpacity: Double = 0
    @AppStorage("hasPairedDeviceOnce") private var hasPairedDeviceOnce: Bool = false
    @State var showOnboarding = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var cancellable: AnyCancellable?
    
    private var needsOnboarding: Bool {
        // Show onboarding if either:
        // 1. User has never paired a device (first time user)
        // 2. User's lastOnboarding doesn't match current ForceUpdateKey
        return !hasPairedDeviceOnce || UserDefaults.standard.needsOnboarding
    }

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
        .navigationTitle("")
        .background(.background.opacity(appState.windowOpacity))
        .toolbarBackground(
            appState.toolbarContrast ? Material.ultraThinMaterial.opacity(1)
            : Material.ultraThinMaterial.opacity(0),
            for: .windowToolbar
        )
        // Show onboarding sheet when needed
        .onAppear {
            print("HomeView onAppear")
            if needsOnboarding {
                showOnboarding = true
                appState.isOnboardingActive = true
            }
            setupDeviceChangeSubscription()
            DispatchQueue.main.async {
                updateSidebarVisibility()
            }
            // Watchdog: if the onboarding sheet fails to present (e.g., resource missing),
            // restore window visibility so the app isn't invisible.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                if showOnboarding && AppState.shared.isOnboardingActive {
                    // If the sheet didn't present, don't keep the main window hidden/dimmed forever
                    print("[onboarding] Watchdog restoring window visibility — sheet may have failed to present")
                    AppState.shared.isOnboardingActive = false
                }
            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView()
                .frame(minWidth: 640, minHeight: 420)
        }
        .onChange(of: showOnboarding) { oldValue, newValue in
            print("HomeView onChange(of: showOnboarding)")
            if !newValue {
                appState.isOnboardingActive = false
            }
        }

    }

    private func setupDeviceChangeSubscription() {
        cancellable = appState.$device
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { _ in
                print("HomeView device changed")
                updateSidebarVisibility()
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
