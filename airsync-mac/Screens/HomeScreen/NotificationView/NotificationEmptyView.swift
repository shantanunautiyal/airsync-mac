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
            Spacer()
            Text("└(=^‥^=)┐")
                .font(.title)
                .padding()
            Label("You're all caught up!", systemImage: "tray")
            Spacer()
        }
    }
}

#Preview {
    NotificationEmptyView()
}
