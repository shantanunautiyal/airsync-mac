//
//  AppIconView.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2025-09-19.
//

import SwiftUI

struct AppIconView: View {
    @StateObject var appIconManager = AppIconManager()

    var body: some View {
        // App Icon Selection Section
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("App Icon", systemImage: "app.badge")
                Spacer()
            }

            HStack(alignment: .top,spacing: 16) {
                ForEach(AppIcon.allIcons) { icon in
                    AppIconImageView(appIconManager: appIconManager, icon: icon)
                }
            }
        }
        .padding()
        .background(.background.opacity(0.3))
        .cornerRadius(10.0)
        .onAppear {
            appIconManager.loadCurrentIcon()
        }

    }
}

#Preview {
    AppIconView()
}

struct AppIconImageView: View {
    @ObservedObject var appIconManager: AppIconManager
    let icon: AppIcon

    private var isSelected: Bool {
        // Compare by iconName (stable across instances). Fallback to name if needed.
        let currentKey = appIconManager.currentIcon.iconName ?? appIconManager.currentIcon.name
        let thisKey = icon.iconName ?? icon.name
        return currentKey == thisKey
    }

    var body: some View {
        VStack(spacing: 8) {
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
                .onTapGesture {
                    appIconManager.setIcon(icon)
                }

            Text(icon.name)
                .font(.caption)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 50)
        }
    }
}
