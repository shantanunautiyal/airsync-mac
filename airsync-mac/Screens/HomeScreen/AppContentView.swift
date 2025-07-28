//
//  AppContentView.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-28.
//

import SwiftUI

struct AppContentView: View {
    var body: some View {
            TabView {
                List{
                    NotificationView()
                    NotificationView()
                    NotificationView()
                    NotificationView()
                    NotificationView()
                    NotificationView()
                    NotificationView()
                    NotificationView()
                    NotificationView()
                    NotificationView()
                    NotificationView()
                    NotificationView()
                    NotificationView()
                    NotificationView()
                    NotificationView()
                    NotificationView()
                    NotificationView()
                    NotificationView()
                    NotificationView()
                    NotificationView()
                    NotificationView()
                    NotificationView()
                    NotificationView()
                    NotificationView()
                    NotificationView()
                    NotificationView()
                    NotificationView()
                    NotificationView()
                }
                .scrollContentBackground(.hidden)
                .background(.clear)
                .toolbar {
                    Button {

                    } label: {
                        Label("Notifications", systemImage: "wind")
                    }
                }
                .background(.clear)
                    .tabItem {
                        Label("Notifications", systemImage: "bell.badge.fill")
                            .font(.title2)
                    }

                Text("(っ◕‿◕)っ")
                    .tabItem {
                        Label("Apps", systemImage: "bell.badge.fill")
                            .font(.title2)
                    }
                    .toolbar {
                        Button {

                        } label: {
                            Label("Refresh", systemImage: "repeat")
                        }
                    }

                ScanView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                            .font(.title2)
                    }
                    .toolbar {
                        Button {

                        } label: {
                            Label("About", systemImage: "info.circle")
                        }
                    }
            }
            .frame(minWidth: 420)
            .background(.clear)
    }
}

#Preview {
    AppContentView()
}
