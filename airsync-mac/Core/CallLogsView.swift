//  CallLogsView.swift
//  AirSync
//
//  Created by AI Assistant on 2025-10-03.

import SwiftUI

struct CallLogsView: View {
    @ObservedObject var appState = AppState.shared

    var body: some View {
        Group {
            if appState.callLogs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No recent calls")
                        .foregroundColor(.secondary)
                    Button("Refresh") {
                        appState.requestCallLogs()
                    }
                }
                .padding()
            } else {
                List(appState.callLogs) { entry in
                    HStack(spacing: 12) {
                        Image(systemName: icon(for: entry.type))
                            .foregroundColor(color(for: entry.type))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.name ?? entry.number)
                                .font(.headline)
                            Text(entry.number)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(dateString(from: entry.timestamp))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if entry.durationSeconds > 0 {
                                Text(durationString(from: entry.durationSeconds))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.inset)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Calls")
        .onAppear {
            // Fetch call logs when view appears
            appState.requestCallLogs()
        }
    }

    private func icon(for type: String) -> String {
        switch type.lowercased() {
        case "incoming": return "phone.arrow.down.left"
        case "outgoing": return "phone.arrow.up.right"
        case "missed": return "phone.badge.plus" // closest symbol for missed
        case "rejected": return "phone.down"
        default: return "phone.fill"
        }
    }

    private func color(for type: String) -> Color {
        switch type.lowercased() {
        case "incoming": return .green
        case "outgoing": return .blue
        case "missed": return .red
        case "rejected": return .orange
        default: return .secondary
        }
    }

    private func dateString(from epochMillis: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(epochMillis) / 1000.0)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func durationString(from seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%dm %02ds", mins, secs)
    }
}

#Preview {
    CallLogsView()
}
