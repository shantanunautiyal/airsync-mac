//
//  NotificationEmptyView.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2025-08-07.
//

import SwiftUI
import Lottie

struct NotificationEmptyView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack {
            Spacer()
            LottieView(animation: .named("empty-notification-v1-clear"))
                .playing(loopMode: .playOnce)
                .frame(width: 100, height: 100)
                .modifier(InvertIfLightMode(colorScheme: colorScheme))

            Text(L("notifications.empty.emoji"))
                .font(.title)
                .padding()


            Text(L("notifications.empty.title"))
                .padding()
            
            Spacer()
        }
    }
}


#Preview {
    NotificationEmptyView()
}
