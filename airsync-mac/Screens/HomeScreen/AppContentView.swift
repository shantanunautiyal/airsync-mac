//
//  AppContentView.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-28.
//

import SwiftUI

struct AppContentView: View {
    var body: some View {
        VStack{
            HStack{
                Label("Notifications", systemImage: "bell.badge.fill")
                    .font(.title2)

                Spacer()

                Button{
                    //                    isShowingSafariView = true
                } label: {
                    Label("Dismiss All", systemImage: "xmark")
                }
                .buttonStyle(.glass)
                .labelStyle(.iconOnly)
                .controlSize(.large)
                .help("Dismiss All")
            }
            .padding()

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


        }
    }
}

#Preview {
    AppContentView()
}
