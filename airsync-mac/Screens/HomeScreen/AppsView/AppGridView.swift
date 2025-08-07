//
//  AppGridView.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2025-08-07.
//

import SwiftUI

struct AppGridView: View {
    @ObservedObject var appState = AppState.shared

    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 16), count: 5)

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(appState.appIcons.keys.sorted(), id: \.self) { package in
                    VStack(spacing: 8) {
                        if let path = appState.appIcons[package],
                           let image = Image(filePath: path) {
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

                        Text(package)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(8)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(10)
                    .onTapGesture {
                        if ((appState.device) != nil && appState.adbConnected) {
                            ADBConnector
                                .startScrcpy(
                                    ip: appState.device?.ipAddress ?? "192.168.100.1",
                                    port: appState.adbPort,
                                    deviceName: appState.device?.name ?? package,
                                    package: package
                                )
                        }
                    }
                }
            }
            .padding(0)
        }
        .padding(0)
    }
}
