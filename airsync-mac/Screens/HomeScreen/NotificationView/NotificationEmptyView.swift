//
//  NotificationEmptyView.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2025-08-07.
//

import SwiftUI

struct NotificationEmptyView: View {
    var body: some View {
        VStack {
            Text(loc: "notifications.empty.emoji")
                .font(.title)
                .padding()
            Label(L("notifications.empty.title"), systemImage: "tray")
            .padding()
        }
    }
}

#Preview {
    NotificationEmptyView()
}
