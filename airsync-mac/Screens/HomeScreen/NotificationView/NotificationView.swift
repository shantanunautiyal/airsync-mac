//
//  NotificationView.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-28.
//

import SwiftUI

struct NotificationView: View {

    let notification: Notification
    let deleteNotification: () -> Void

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
            Button(role: .destructive) {
                deleteNotification()
            } label: {
                Label("Dismiss", systemImage: "trash")
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
        if let base64 = AppState.shared.appIcons[notification.package] {
            if let image = Image(base64String: base64) {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 25, height: 25)
                    .padding(5)
            } else {
                Image(systemName: "app.badge")
                    .resizable()
            }
        } else {
            Image(systemName: "app.badge")
                .resizable()
        }
    }



}

#Preview {
    NotificationView(
        notification: MockData.sampleNotificaiton,
        deleteNotification: {}
    )
}
