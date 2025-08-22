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

                    if !notification.actions.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(notification.actions) { action in
                                if action.type == .reply {
                                    ReplyActionButton(notification: notification, action: action)
                                } else {
                                    GlassButtonView(
                                        label: action.name,
                                        action: {
                                            WebSocketServer.shared.sendNotificationAction(id: notification.nid, name: action.name)
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
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

private struct ReplyActionButton: View {
    @State private var showingField = false
    @State private var replyText = ""
    let notification: Notification
    let action: NotificationAction

    var body: some View {
        HStack(spacing: 4) {
            if showingField {
                TextField(action.name, text: $replyText, onCommit: send)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 160)


                GlassButtonView(
                    label: "Send",
                    systemImage: "paperplane",
                    primary: true,
                    action: {
                        send()
                    }
                )
                .disabled(replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            } else {

                GlassButtonView(
                    label: action.name,
                    systemImage: "paperplane",
                    primary: true,
                    action: {
                        withAnimation { showingField = true }
                    }
                )
            }
        }
    }

    private func send() {
        let text = replyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        WebSocketServer.shared.sendNotificationAction(id: notification.nid, name: action.name, text: text)
        replyText = ""
        showingField = false
    }
}

#Preview {
    NotificationCardView(
        notification: MockData.sampleNotificaiton,
        deleteNotification: {},
        hideNotification: {}
    )
}
