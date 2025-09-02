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
                if let base64 = AppState.shared.currentDeviceWallpaperBase64,
                   let data = Data(base64Encoded: base64.stripBase64Prefix()),
                   let nsImage = NSImage(data: data) {

                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFill()
                        .blur(radius: 10)
                        .opacity(targetOpacity)
                        .mask(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .black, location: 0.0),
                                    .init(color: .black, location: 0.2),
                                    .init(color: .clear, location: 0.8),
                                    .init(color: .clear, location: 1.0)
                                ]),
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 4), value: targetOpacity)
                        .onAppear {
                            targetOpacity = 0.5
                        }
                        .onChange(of: base64) {
                            fadeOpacity()
                        }
                }

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
    }

    private func updateSidebarVisibility() {
        withAnimation(.easeInOut(duration: 0.3)) {
            columnVisibility = appState.device != nil ? .all : .detailOnly
        }
    }

    func fadeOpacity() {
        withAnimation(.easeOut(duration: 1)) {
            targetOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation(.easeIn(duration: 1)) {
                targetOpacity = 0.5
            }
        }
    }
}

#Preview {
    HomeView()
}
