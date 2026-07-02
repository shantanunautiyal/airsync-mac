//
//  AirSyncIntents.swift
//  airsync-mac
//
//  Siri & Shortcuts integration via AppIntents framework.
//  Provides voice-activated queries for health data, connection status,
//  and notification management.
//

import AppIntents
import SwiftUI

// MARK: - App Shortcuts Provider

struct AirSyncShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetHealthSummaryIntent(),
            phrases: [
                "Show my health summary in \(.applicationName)",
                "How many steps today in \(.applicationName)",
                "Get my health stats from \(.applicationName)",
                "What's my step count in \(.applicationName)",
                "Show my fitness data in \(.applicationName)"
            ],
            shortTitle: "Health Summary",
            systemImageName: "heart.fill"
        )
        
        AppShortcut(
            intent: GetStepCountIntent(),
            phrases: [
                "How many steps have I taken in \(.applicationName)",
                "Step count in \(.applicationName)",
                "Steps today in \(.applicationName)"
            ],
            shortTitle: "Step Count",
            systemImageName: "figure.walk"
        )
        
        AppShortcut(
            intent: GetHeartRateIntent(),
            phrases: [
                "What's my heart rate in \(.applicationName)",
                "Heart rate from \(.applicationName)",
                "Check my heart rate in \(.applicationName)"
            ],
            shortTitle: "Heart Rate",
            systemImageName: "heart.fill"
        )
        
        AppShortcut(
            intent: CheckConnectionIntent(),
            phrases: [
                "Is my phone connected in \(.applicationName)",
                "Check connection status in \(.applicationName)",
                "Am I connected in \(.applicationName)",
                "Phone status in \(.applicationName)"
            ],
            shortTitle: "Connection Status",
            systemImageName: "antenna.radiowaves.left.and.right"
        )
        
        AppShortcut(
            intent: GetNotificationCountIntent(),
            phrases: [
                "How many notifications in \(.applicationName)",
                "Check notifications in \(.applicationName)",
                "Unread notifications in \(.applicationName)"
            ],
            shortTitle: "Notification Count",
            systemImageName: "bell.fill"
        )
        
        AppShortcut(
            intent: GetBatteryLevelIntent(),
            phrases: [
                "What's my phone battery in \(.applicationName)",
                "Phone battery level in \(.applicationName)",
                "Battery status in \(.applicationName)"
            ],
            shortTitle: "Phone Battery",
            systemImageName: "battery.75percent"
        )
        
        AppShortcut(
            intent: RefreshHealthDataIntent(),
            phrases: [
                "Refresh health data in \(.applicationName)",
                "Sync health from phone in \(.applicationName)",
                "Update health stats in \(.applicationName)"
            ],
            shortTitle: "Refresh Health",
            systemImageName: "arrow.clockwise"
        )
        
        AppShortcut(
            intent: GetSleepDataIntent(),
            phrases: [
                "How did I sleep in \(.applicationName)",
                "Sleep data from \(.applicationName)",
                "How long did I sleep in \(.applicationName)"
            ],
            shortTitle: "Sleep Data",
            systemImageName: "bed.double.fill"
        )
    }
}

// MARK: - Health Summary Intent

struct GetHealthSummaryIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Health Summary"
    static var description = IntentDescription(
        "Get a summary of your health metrics from your Android phone.",
        categoryName: "Health"
    )
    static var openAppWhenRun = false
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let manager = LiveNotificationManager.shared
        
        guard let summary = manager.healthSummary ?? manager.cachedHealthSummary(for: Date()) else {
            return .result(
                dialog: "I don't have any health data from your phone right now. Make sure your phone is connected and syncing health data.",
                view: EmptyView()
            )
        }
        
        let stepsText = summary.steps != nil ? "\(summary.steps!) steps" : "no step data"
        let caloriesText = summary.calories != nil ? "\(summary.calories!) calories" : "no calorie data"
        let heartText = summary.heartRateAvg != nil ? "\(summary.heartRateAvg!) bpm heart rate" : ""
        let sleepText: String = {
            guard let dur = summary.sleepDuration, dur > 0 else { return "" }
            return "\(dur / 60) hours \(dur % 60) minutes of sleep"
        }()
        
        var parts = [stepsText, caloriesText]
        if !heartText.isEmpty { parts.append(heartText) }
        if !sleepText.isEmpty { parts.append(sleepText) }
        
        let spoken = "Today you have " + parts.joined(separator: ", ") + "."
        
        return .result(
            dialog: IntentDialog(stringLiteral: spoken),
            view: HealthSummarySnippetView(summary: summary)
        )
    }
}

// MARK: - Step Count Intent

struct GetStepCountIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Step Count"
    static var description = IntentDescription(
        "Get your current step count from Health Connect.",
        categoryName: "Health"
    )
    static var openAppWhenRun = false
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = LiveNotificationManager.shared
        
        guard let summary = manager.healthSummary ?? manager.cachedHealthSummary(for: Date()) else {
            return .result(dialog: "No step data available. Make sure your phone is connected.")
        }
        
        guard let steps = summary.steps, steps > 0 else {
            return .result(dialog: "No steps recorded today yet.")
        }
        
        let progress = min(Double(steps) / 10000.0, 1.0) * 100
        return .result(dialog: IntentDialog(stringLiteral: "You've taken \(steps) steps today — that's \(Int(progress))% of your 10,000 step goal."))
    }
}

// MARK: - Heart Rate Intent

struct GetHeartRateIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Heart Rate"
    static var description = IntentDescription(
        "Get your latest heart rate reading.",
        categoryName: "Health"
    )
    static var openAppWhenRun = false
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = LiveNotificationManager.shared
        
        guard let summary = manager.healthSummary ?? manager.cachedHealthSummary(for: Date()) else {
            return .result(dialog: "No heart rate data available. Make sure your phone is connected.")
        }
        
        guard let hr = summary.heartRateAvg, hr > 0 else {
            return .result(dialog: "No heart rate data recorded today.")
        }
        
        var response = "Your average heart rate today is \(hr) beats per minute."
        
        if let min = summary.heartRateMin, let max = summary.heartRateMax, min > 0, max > 0 {
            response += " It ranged from \(min) to \(max) bpm."
        }
        
        if let resting = summary.restingHeartRate, resting > 0 {
            response += " Your resting heart rate is \(resting) bpm."
        }
        
        return .result(dialog: IntentDialog(stringLiteral: response))
    }
}

// MARK: - Sleep Data Intent

struct GetSleepDataIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Sleep Data"
    static var description = IntentDescription(
        "Get your sleep duration from last night.",
        categoryName: "Health"
    )
    static var openAppWhenRun = false
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = LiveNotificationManager.shared
        
        guard let summary = manager.healthSummary ?? manager.cachedHealthSummary(for: Date()) else {
            return .result(dialog: "No sleep data available. Make sure your phone is connected.")
        }
        
        guard let dur = summary.sleepDuration, dur > 0 else {
            return .result(dialog: "No sleep data recorded. Your phone may not have tracked sleep last night.")
        }
        
        let hours = dur / 60
        let minutes = dur % 60
        let goal = 8 * 60 // 8 hours
        let percentage = min(Double(dur) / Double(goal), 1.0) * 100
        
        return .result(dialog: IntentDialog(stringLiteral: "You slept \(hours) hours and \(minutes) minutes last night — \(Int(percentage))% of your 8-hour goal."))
    }
}

// MARK: - Connection Status Intent

struct CheckConnectionIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Phone Connection"
    static var description = IntentDescription(
        "Check if your Android phone is connected to AirSync.",
        categoryName: "Connection"
    )
    static var openAppWhenRun = false
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let appState = AppState.shared
        
        let isConnected = appState.device != nil
        let deviceName = appState.device?.name ?? "your phone"
        
        if isConnected {
            var response = "\(deviceName) is connected"
            
            if let battery = appState.status?.battery {
                response += " with \(battery.level)% battery"
            }
            
            response += "."
            
            return .result(dialog: IntentDialog(stringLiteral: response))
        } else {
            return .result(dialog: "Your phone is not connected. Make sure both devices are on the same network and AirSync is running on your phone.")
        }
    }
}

// MARK: - Notification Count Intent

struct GetNotificationCountIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Notification Count"
    static var description = IntentDescription(
        "Check how many notifications are synced from your phone.",
        categoryName: "Notifications"
    )
    static var openAppWhenRun = false
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let appState = AppState.shared
        let count = appState.notifications.count
        
        if count == 0 {
            return .result(dialog: "You have no notifications from your phone right now.")
        }
        
        let apps = Set(appState.notifications.map { $0.package })
        return .result(dialog: IntentDialog(stringLiteral: "You have \(count) notification\(count == 1 ? "" : "s") from \(apps.count) app\(apps.count == 1 ? "" : "s") on your phone."))
    }
}

// MARK: - Battery Level Intent

struct GetBatteryLevelIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Phone Battery"
    static var description = IntentDescription(
        "Check your Android phone's battery level.",
        categoryName: "Connection"
    )
    static var openAppWhenRun = false
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let appState = AppState.shared
        
        guard appState.device != nil else {
            return .result(dialog: "Your phone is not connected. Connect it first to check battery.")
        }
        
        guard let battery = appState.status?.battery else {
            return .result(dialog: "Battery information is not available right now.")
        }
        
        let deviceName = appState.device?.name ?? "Your phone"
        let level: String
        switch battery.level {
        case 0..<20: level = "low"
        case 20..<50: level = "moderate"
        case 50..<80: level = "good"
        default: level = "great"
        }
        
        let isCharging = battery.isCharging
        var response = "\(deviceName) is at \(battery.level)% battery (\(level))"
        if isCharging {
            response += " and is currently charging"
        }
        response += "."
        
        return .result(dialog: IntentDialog(stringLiteral: response))
    }
}

// MARK: - Refresh Health Data Intent

struct RefreshHealthDataIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh Health Data"
    static var description = IntentDescription(
        "Request fresh health data from your Android phone.",
        categoryName: "Health"
    )
    static var openAppWhenRun = false
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = LiveNotificationManager.shared
        
        _ = manager.getHealthSummary(for: Date(), forceRefresh: true)
        
        return .result(dialog: "Requesting fresh health data from your phone. It should be available in a few seconds.")
    }
}

// MARK: - Snippet View for Health Summary

struct HealthSummarySnippetView: View {
    let summary: HealthSummary
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                MetricBubble(
                    icon: "figure.walk",
                    value: summary.steps != nil ? "\(summary.steps!)" : "--",
                    label: "Steps",
                    color: Color(hex: "4FC3F7")
                )
                MetricBubble(
                    icon: "flame.fill",
                    value: summary.calories != nil ? "\(summary.calories!)" : "--",
                    label: "Calories",
                    color: Color(hex: "FF7043")
                )
                MetricBubble(
                    icon: "heart.fill",
                    value: summary.heartRateAvg != nil ? "\(summary.heartRateAvg!)" : "--",
                    label: "BPM",
                    color: Color(hex: "E53935")
                )
            }
            
            if let dur = summary.sleepDuration, dur > 0 {
                HStack {
                    Image(systemName: "bed.double.fill")
                        .foregroundColor(Color(hex: "7E57C2"))
                    Text("Sleep: \(dur / 60)h \(dur % 60)m")
                        .font(.subheadline)
                }
            }
        }
        .padding()
    }
}

struct MetricBubble: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}
