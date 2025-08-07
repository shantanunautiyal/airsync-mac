//
//  AppGridView.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2025-08-07.
//

import SwiftUI

struct AppGridView: View {
    @ObservedObject var appState = AppState.shared

    var body: some View {
        GeometryReader { geometry in
            let spacing: CGFloat = 16
            let itemWidth: CGFloat = 80
            let columnsCount = max(1, Int((geometry.size.width + spacing) / (itemWidth + spacing)))
            let columns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnsCount)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(appState.androidApps.values.sorted(by: { $0.name.lowercased() < $1.name.lowercased() }), id: \.packageName) { app in
                        ZStack(alignment: .topTrailing) {
                            VStack(spacing: 8) {
                                if let iconPath = app.iconUrl,
                                   let image = Image(filePath: iconPath) {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 48, height: 48)
                                        .cornerRadius(8)
                                } else {
                                    Image(systemName: "app.badge")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 48, height: 48)
                                        .foregroundColor(.gray)
                                }

                                Text(app.name)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity)
                            }
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .cornerRadius(15)
                            .onTapGesture {
                                if let device = appState.device, appState.adbConnected {
                                    ADBConnector.startScrcpy(
                                        ip: device.ipAddress,
                                        port: appState.adbPort,
                                        deviceName: device.name,
                                        package: app.packageName
                                    )
                                }
                            }

                            // Accent dot for listening apps
                            if !app.listening {
                                Image(systemName: "bell.slash")
                                    .resizable()
                                    .frame(width: 10, height: 10)
                                    .offset(x: -8, y: 8)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(0)
    }
}

