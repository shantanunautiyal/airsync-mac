//
//  NotificationView.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-28.
//

import SwiftUI

struct NotificationView: View {
    var body: some View {
        ZStack{
            GlassBoxView(
                color: Color.gray.opacity(0.1),
                width: .infinity,
                maxHeight: 75,
                radius: 20
            )

//            Rectangle()
//                .fill(Color.gray.opacity(0.1))
//                .cornerRadius(20)
//                .frame(maxHeight: 75)

            HStack{
                Image(systemName: "app.badge")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 25, height: 25)
                    .padding(3)

                VStack{
                    HStack{
                        Text("WhatsApp")
                            .font(.default)

                        Spacer()
                    }

                    HStack{
                        Text("You've got a new message")

                        Spacer()
                    }
                }
            }
            .padding()
        }
        .swipeActions(edge: .leading) {
            Button {
                //                store.toggleUnread(message)
            } label: {
                Label("Unread", systemImage: "envelope.badge")
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                //                store.delete(message)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            Button {
                //                store.flag(message)
            } label: {
                Label("Flag", systemImage: "flag")
            }
        }
        .listRowSeparator(.hidden)
    }
}

#Preview {
    NotificationView()
}
