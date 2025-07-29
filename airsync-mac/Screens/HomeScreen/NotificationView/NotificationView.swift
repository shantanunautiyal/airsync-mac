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
        ZStack{
            GlassBoxView(
                color: Color(.windowBackgroundColor).opacity(0.5),
                maxHeight: 75,
                radius: 20
            )


            HStack{
                Image(systemName: "app.badge")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 25, height: 25)
                    .padding(3)

                VStack{
                    HStack{
                        Text(notification.app)
                            .font(.default)

                        Spacer()
                    }

                    HStack{
                        Text(notification.title)

                        Spacer()
                    }
                }
            }
            .padding()
        }
        .swipeActions(edge: .leading) {
            Button(role: .destructive) {
                //                store.delete(message)
                deleteNotification()
            } label: {
                Label("Dismiss", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                //                store.delete(message)
                deleteNotification()
            } label: {
                Label("Dismiss", systemImage: "trash")
            }
        }
        .listRowSeparator(.hidden)
    }
}

#Preview {
    NotificationView(
        notification: MockData.sampleNotificaiton,
        deleteNotification: {}
    )
}
