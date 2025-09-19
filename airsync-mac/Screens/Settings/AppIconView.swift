//
//  AppIconView.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2025-09-19.
//

import SwiftUI

struct AppIconView: View {
    @StateObject var appIconManager = AppIconManager()
    @ObservedObject var appState = AppState.shared
    @State private var showingPlusPopover = false

    var body: some View {
        // App Icon Selection Section
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("App Icon", systemImage: "app.badge")
                Spacer()
            }

            HStack(alignment: .top,spacing: 16) {
                ForEach(AppIcon.allIcons) { icon in
                    AppIconImageView(
                        appIconManager: appIconManager, 
                        icon: icon,
                        isDisabled: !appState.isPlus && appState.licenseCheck,
                        showLock: !appState.isPlus && appState.licenseCheck && !icon.isDefault,
                        onRestrictedTap: {
                            showingPlusPopover = true
                        }
                    )
                }
            }
        }
        .padding()
        .background(.background.opacity(0.3))
        .cornerRadius(12.0)
        .onAppear {
            appIconManager.loadCurrentIcon()
        }
        .popover(isPresented: $showingPlusPopover, arrowEdge: .bottom) {
            PlusFeaturePopover(message: "Custom app icons are available with AirSync+")
        }

    }
}

#Preview {
    AppIconView()
}

struct AppIconImageView: View {
    @ObservedObject var appIconManager: AppIconManager
    let icon: AppIcon
    let isDisabled: Bool
    let showLock: Bool
    let onRestrictedTap: () -> Void
    
    init(appIconManager: AppIconManager, icon: AppIcon, isDisabled: Bool = false, showLock: Bool = false, onRestrictedTap: @escaping () -> Void = {}) {
        self.appIconManager = appIconManager
        self.icon = icon
        self.isDisabled = isDisabled
        self.showLock = showLock
        self.onRestrictedTap = onRestrictedTap
    }

    private var isSelected: Bool {
        // Compare by iconName (stable across instances). Fallback to name if needed.
        let currentKey = appIconManager.currentIcon.iconName ?? appIconManager.currentIcon.name
        let thisKey = icon.iconName ?? icon.name
        return currentKey == thisKey
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                icon.image
                    .resizable()
                    .frame(width: 60, height: 60)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(
                                isSelected ? Color.secondary : Color.clear,
                                lineWidth: 5
                            )
                    )
                    .opacity(isDisabled ? 0.5 : 1.0)
                
                // Lock overlay for non-default icons when user doesn't have Plus
                if showLock {
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.7))
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: "lock.fill")
                            .foregroundColor(.white)
                            .font(.caption)
                    }
                    .offset(x: 18, y: -18)
                }
            }
            .onTapGesture {
                if isDisabled {
                    onRestrictedTap()
                } else {
                    appIconManager.setIcon(icon)
                }
            }

            Text(icon.name)
                .font(.caption)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 50)
                .foregroundColor(isDisabled ? .secondary : .primary)
        }
    }
}
