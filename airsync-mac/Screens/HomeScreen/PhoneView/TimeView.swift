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
        let components = calendar.dateComponents([.hour, .minute], from: currentDate)

        let is24Hour = isSystemUsing24Hour()
        let hourValue = components.hour ?? 0
        let displayHour = is24Hour ? hourValue : (hourValue % 12 == 0 ? 12 : hourValue % 12)
        let hour = String(format: "%02d", displayHour)
        let minute = String(format: "%02d", components.minute ?? 0)

        VStack(spacing: -20) {
            Text(hour)
            Text(minute)
        }
        .font(.system(size: 75, weight: .medium, design: .rounded))
        .onReceive(timer) { newValue in
            currentDate = newValue
        }
    }

    // Detect if system uses 24-hour time
    private func isSystemUsing24Hour() -> Bool {
        let formatString = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: Locale.current) ?? ""
        return !formatString.contains("a")
    }
}

#Preview {
    TimeView()
}
