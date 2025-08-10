//
//  NotificationView.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2025-08-07.
//

import SwiftUI

struct NotificationView: View {
    @ObservedObject var appState = AppState.shared
    @AppStorage("notificationStacks") private var notificationStacks = true
    @State private var expandedPackages: Set<String> = []

    var body: some View {
        Group {
            if appState.notifications.isEmpty {
                NotificationEmptyView()
                    .transition(.scale)
            } else {
                if notificationStacks {
                    stackedList
                        .id("stacked")
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .top).combined(
                                    with: .scale
                                ),
                                removal:
                                        .move(edge: .bottom)
                                        .combined(with: .scale)
)
)
                } else {
                    flatList
                        .id("flat")
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .bottom).combined(
                                    with: .scale
                                ),
                                removal:
                                        .move(edge: .top)
                                        .combined(with: .scale)
)
)
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: notificationStacks)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: expandedPackages)
    }

    // MARK: - Flat List
    private var flatList: some View {
        List(appState.notifications.prefix(20), id: \.id) { notif in
            notificationRow(for: notif)
                .transition(.opacity.combined(with: .scale))
        }
        .scrollContentBackground(.hidden)
        .background(.clear)
        .listStyle(.sidebar)
    }

    // MARK: - Stacked List
    private var stackedList: some View {
        List {
            ForEach(groupedNotifications.keys.sorted(), id: \.self) { package in
                let packageNotifs = groupedNotifications[package] ?? []
                let isExpanded = expandedPackages.contains(package)

                Section {
                    let visibleNotifs = isExpanded ? packageNotifs : Array(packageNotifs.prefix(1))

                    ForEach(visibleNotifs, id: \.id) { notif in
                        notificationRow(for: notif)
                            .transition(.opacity.combined(with: .scale))
                    }

                    if packageNotifs.count > 1 {
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                if isExpanded {
                                    expandedPackages.remove(package)
                                } else {
                                    expandedPackages.insert(package)
                                }
                            }
                        } label: {
                            Label(
                                isExpanded ? "Show Less" : "Show \(packageNotifs.count - 1) More",
                                systemImage: isExpanded ? "chevron.up" : "chevron.down"
                            )
                            .font(.caption)
                        }
                        .buttonStyle(.borderless)
                        .padding(.top, 4)
                        .transition(.opacity)
                    }
                } header: {
                    Text(appState.androidApps[package]?.name ?? "AirSync")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(.clear)
        .listStyle(.sidebar)
    }

    // MARK: - Helpers
    private var groupedNotifications: [String: [Notification]] {
        Dictionary(grouping: appState.notifications.prefix(20)) { notif in
            notif.package
        }
    }

    @ViewBuilder
    private func notificationRow(for notif: Notification) -> some View {
        NotificationCardView(
            notification: notif,
            deleteNotification: { appState.removeNotification(notif) },
            hideNotification: { appState.hideNotification(notif) }
        )
        .background(.clear)
        .applyGlassViewIfAvailable()
        .onTapGesture {
            if appState.device != nil && appState.adbConnected &&
                notif.package != "" &&
                notif.package != "com.sameerasw.airsync" &&
                appState.mirroringPlus {
                ADBConnector.startScrcpy(
                    ip: appState.device?.ipAddress ?? "",
                    port: appState.adbPort,
                    deviceName: appState.device?.name ?? "My Phone",
                    package: notif.package
                )
            }
        }
    }
}


#Preview {
    NotificationView()
}
