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
                    VStack(spacing: 8) {
                        icon.image
                            .resizable()
                            .frame(width: 60, height: 60)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(
                                        appIconManager.currentIcon.id == icon.id ? Color.accentColor : Color.clear,
                                        lineWidth: 3
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
