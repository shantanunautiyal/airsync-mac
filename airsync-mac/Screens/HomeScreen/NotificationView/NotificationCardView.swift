//
//  NotificationView.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-28.
//

import SwiftUI

struct NotificationCardView: View {

    let notification: Notification
    let deleteNotification: () -> Void
    let hideNotification: () -> Void

    var body: some View {
        ZStack {
            HStack(alignment: .top) {
                appIconView()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 25, height: 25)
                    .padding(5)

                VStack(alignment: .leading) {
                    Text(notification.app + " - " + notification.title)
                        .font(.headline)

                    Text(notification.body)
                        .font(.body)
                }

                Spacer()
            }
            .padding()
        }
        .swipeActions(edge: .leading) {
            Button(role: .cancel) {
                hideNotification()
            } label: {
                Label("Hide", systemImage: "xmark")
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                deleteNotification()
            } label: {
                Label("Dismiss", systemImage: "trash")
            }
        }
        .listRowSeparator(.hidden)
    }

    @ViewBuilder
    private func appIconView() -> some View {
        if let path = AppState.shared.androidApps[notification.package]?.iconUrl,
           let image = Image(filePath: path) {
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 25, height: 25)
                .padding(5)
        } else {
            Image(systemName: "app.badge")
                .resizable()
        }
    }




}

#Preview {
    NotificationCardView(
        notification: MockData.sampleNotificaiton,
        deleteNotification: {},
        hideNotification: {}
    )
}
