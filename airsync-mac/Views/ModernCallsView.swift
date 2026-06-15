//
//  ModernCallsView.swift
//  airsync-mac
//
//  Liquid glass calls view
//

import SwiftUI
internal import Combine

struct CallsView: View {
    @ObservedObject private var manager = LiveNotificationManager.shared
    @State private var showDialer = false
    @State private var appearedItems: Set<String> = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Active call banner
                if let call = manager.activeCall, call.state != .ended && call.state != .rejected && call.state != .missed {
                    ActiveCallCard(call: call)
                        .transition(.scale.combined(with: .opacity))
                }
                
                // Call history
                if manager.callLogs.isEmpty {
                    EmptyStateCard(
                        icon: "phone.fill",
                        title: "No Call History",
                        message: "Call logs will appear here"
                    )
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(Array(manager.callLogs.enumerated()), id: \.element.id) { index, log in
                            CallLogCard(log: log)
                                .staggeredEntrance(index: index, isVisible: appearedItems.contains(log.id))
                                .onAppear {
                                    _ = withAnimation { appearedItems.insert(log.id) }
                                }
                        }
                    }
                }
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showDialer = true }) {
                    Image(systemName: "phone.badge.plus")
                }
                .help("Open Dialer")
            }
        }
        .sheet(isPresented: $showDialer) {
            DialerView()
        }
        .onAppear {
            // Use caching - this will return cached data immediately and request fresh data if needed
            _ = manager.getCallLogs()
        }
    }
}

struct ActiveCallCard: View {
    let call: LiveCallNotification
    @State private var currentTime = Date()
    @State private var isPulsing = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Pulsing green ring icon
            ZStack {
                // Outer pulse ring
                Circle()
                    .stroke(Color.green.opacity(0.3), lineWidth: 2)
                    .frame(width: 56, height: 56)
                    .scaleEffect(isPulsing ? 1.3 : 1.0)
                    .opacity(isPulsing ? 0 : 0.6)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: isPulsing)
                
                // Icon circle
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "phone.fill")
                    .font(.title2)
                    .foregroundColor(.green)
            }
            .onAppear { isPulsing = true }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(call.displayName)
                    .font(.headline)
                Text(call.stateDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Duration
            if call.state == .accepted || call.state == .offhook {
                Text(formatDuration(call.duration))
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .monospacedDigit()
                    .foregroundColor(.green)
                    .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                        currentTime = Date()
                    }
            }
        }
        .padding(16)
        .glassBoxIfAvailable(radius: 16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.25), lineWidth: 1)
        )
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct CallLogCard: View {
    let log: CallLogEntry
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 14) {
            // Glass icon circle
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                
                Image(systemName: log.typeIcon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(iconColor)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(log.displayName)
                    .font(.system(size: 14, weight: .semibold))
                Text(log.number)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Time & Duration
            VStack(alignment: .trailing, spacing: 3) {
                Text(log.date, style: .time)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                Text(log.durationFormatted)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassBoxIfAvailable(radius: 14)
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .shadow(color: .black.opacity(isHovered ? 0.08 : 0), radius: 8, y: 4)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.2)) { isHovered = hovering }
        }
    }
    
    private var iconColor: Color {
        switch log.type {
        case "incoming": return .blue
        case "outgoing": return .green
        case "missed": return .red
        default: return .gray
        }
    }
}

struct EmptyStateCard: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.08))
                    .frame(width: 80, height: 80)
                
                Image(systemName: icon)
                    .font(.system(size: 36))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .glassBoxIfAvailable(radius: 16)
    }
}
