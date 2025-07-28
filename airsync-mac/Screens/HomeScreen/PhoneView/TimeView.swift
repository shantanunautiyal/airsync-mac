//
//  TimeView.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-28.
//

import SwiftUI
internal import Combine

struct TimeView: View {
    @State private var currentDate = Date()

    // Timer that updates every second
    private let timer = Timer
        .publish(every: 1, on: .main, in: .common)
        .autoconnect()

    var body: some View {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentDate)
        let minute = calendar.component(.minute, from: currentDate)

        VStack(spacing: -20) {
            Text(String(format: "%02d", hour))
            Text(String(format: "%02d", minute))
        }
        .font(.system(size: 75))
        .onReceive(timer) { newValue in
            currentDate = newValue
        }
    }
}

#Preview {
    TimeView()
}
