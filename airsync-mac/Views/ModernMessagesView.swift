//
//  ModernMessagesView.swift
//  airsync-mac
//
//  Liquid glass messages view
//

import SwiftUI

struct MessagesView: View {
    @ObservedObject private var manager = LiveNotificationManager.shared
    @State private var searchText = ""
    @State private var showNewMessage = false
    
    var filteredThreads: [SmsThread] {
        if searchText.isEmpty {
            return manager.smsThreads
        } else {
            return manager.smsThreads.filter { thread in
                thread.displayName.localizedCaseInsensitiveContains(searchText) ||
                thread.address.contains(searchText) ||
                thread.snippet.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Glass Search Bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))
                
                TextField("Search messages...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .glassBoxIfAvailable(radius: 12)
            .padding(.horizontal)
            .padding(.vertical, 10)
            
            // Messages List
            ScrollView {
                if filteredThreads.isEmpty {
                    if manager.smsThreads.isEmpty {
                        EmptyStateCard(
                            icon: "message.fill",
                            title: "No Messages",
                            message: "SMS conversations will appear here"
                        )
                        .padding()
                    } else {
                        // No search results
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("No messages found")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Try searching with a different term")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(40)
                        .glassBoxIfAvailable(radius: 16)
                        .padding()
                    }
                } else {
                    LazyVStack(spacing: 6) {
                        ForEach(filteredThreads) { thread in
                            NavigationLink(destination: SmsDetailView(thread: thread)) {
                                MessageThreadRow(thread: thread, searchText: searchText)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showNewMessage = true }) {
                    Image(systemName: "square.and.pencil")
                }
                .help("New Message")
            }
        }
        .sheet(isPresented: $showNewMessage) {
            NewMessageView()
        }
        .onAppear {
            // Use caching - this will return cached data immediately and request fresh data if needed
            _ = manager.getSmsThreads()
        }
    }
}

struct MessageThreadRow: View {
    let thread: SmsThread
    let searchText: String
    @State private var isHovered = false
    
    init(thread: SmsThread, searchText: String = "") {
        self.thread = thread
        self.searchText = searchText
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Glass-backed avatar
            ZStack {
                Circle()
                    .fill(avatarColor.opacity(0.15))
                    .frame(width: 46, height: 46)
                
                Circle()
                    .stroke(avatarColor.opacity(0.2), lineWidth: 1.5)
                    .frame(width: 46, height: 46)
                
                Text(thread.displayName.prefix(1).uppercased())
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(avatarColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    HighlightedText(
                        text: thread.displayName,
                        searchText: searchText,
                        font: .system(size: 14, weight: thread.hasUnread ? .semibold : .medium),
                        weight: thread.hasUnread ? .semibold : .regular
                    )
                    
                    Spacer()
                    
                    Text(thread.date, style: .time)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    HighlightedText(
                        text: thread.snippet,
                        searchText: searchText,
                        font: .subheadline,
                        color: thread.hasUnread ? .primary : .secondary
                    )
                    .lineLimit(2)
                    
                    Spacer()
                    
                    // Read-only indicator or Unread badge
                    if isReadOnlyThread(thread) {
                        Image(systemName: "eye.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if thread.unreadCount > 0 {
                        Text("\(thread.unreadCount)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .frame(minWidth: 22, minHeight: 22)
                            .background(Color.blue, in: Circle())
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            Group {
                if isHovered || thread.hasUnread {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            isHovered
                            ? Color.primary.opacity(0.04)
                            : Color.blue.opacity(0.04)
                        )
                }
            }
        )
        .glassBoxIfAvailable(radius: 14)
        .contentShape(Rectangle())
        .scaleEffect(isHovered ? 1.005 : 1.0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
    
    private var avatarColor: Color {
        let colors: [Color] = [.blue, .purple, .orange, .teal, .pink, .indigo, .mint]
        let hash = abs(thread.displayName.hashValue)
        return colors[hash % colors.count]
    }
    
    // Helper function to determine if thread is read-only
    private func isReadOnlyThread(_ thread: SmsThread) -> Bool {
        SmsReadOnlyDetector.isReadOnly(address: thread.address, displayName: thread.displayName, snippet: thread.snippet)
    }
}

// Helper view for highlighting search text
struct HighlightedText: View {
    let text: String
    let searchText: String
    let font: Font
    let weight: Font.Weight?
    let color: Color?
    
    init(text: String, searchText: String, font: Font, weight: Font.Weight? = nil, color: Color? = nil) {
        self.text = text
        self.searchText = searchText
        self.font = font
        self.weight = weight
        self.color = color
    }
    
    var body: some View {
        if searchText.isEmpty {
            Text(text)
                .font(font)
                .fontWeight(weight)
                .foregroundColor(color)
        } else {
            let parts = text.components(separatedBy: searchText)
            if parts.count > 1 {
                // Text contains search term
                HStack(spacing: 0) {
                    ForEach(0..<parts.count, id: \.self) { index in
                        Text(parts[index])
                            .font(font)
                            .fontWeight(weight)
                            .foregroundColor(color)
                        
                        if index < parts.count - 1 {
                            Text(searchText)
                                .font(font)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                                .background(Color.yellow.opacity(0.3))
                        }
                    }
                }
            } else {
                // Text doesn't contain search term
                Text(text)
                    .font(font)
                    .fontWeight(weight)
                    .foregroundColor(color)
            }
        }
    }
}
