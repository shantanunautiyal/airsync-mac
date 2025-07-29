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
            HStack(alignment: .top){
                Image(systemName: "app.badge")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 25, height: 25)
                    .padding(5)

                VStack{
                    HStack{
                        Text(notification.app + " - " + notification.title)
                            .font(.headline)

                        Spacer()
                    }

                    HStack {
                        Text(String(notification.body))
                        .font(.body)

                        Spacer()
                    }
                }
            }
            .padding()
        }
        .background(.clear)
        .glassEffect(in: .rect(cornerRadius: 20))
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
