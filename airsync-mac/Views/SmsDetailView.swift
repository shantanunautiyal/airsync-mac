//
//  SmsDetailView.swift
//  airsync-mac
//
//  Liquid glass SMS conversation detail view
//

import SwiftUI

struct SmsDetailView: View {
    let thread: SmsThread
    @ObservedObject private var manager = LiveNotificationManager.shared
    @State private var messages: [SmsMessage] = []
    @State private var newMessage = ""
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss
    
    // Computed property to determine if messages can be sent
    private var canSendMessages: Bool {
        !isReadOnlyConversation
    }
    
    // Determine if this conversation supports sending messages
    private var isReadOnlyConversation: Bool {
        SmsReadOnlyDetector.isReadOnly(address: thread.address, displayName: thread.displayName, snippet: thread.snippet)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Messages List
            messagesView
            
            // Input Area (if sending is supported) or Read-only indicator
            if canSendMessages {
                inputView
            } else {
                readOnlyIndicator
            }
        }
        .onAppear {
            loadMessages()
        }
        .navigationTitle("")
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack(spacing: 12) {
            // Back Button
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 32, height: 32)
                    .background(Color.primary.opacity(0.06), in: Circle())
            }
            .buttonStyle(.plain)
            .help("Back to messages")
            
            // Glass-backed Contact Avatar
            ZStack {
                Circle()
                    .fill(avatarColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Circle()
                    .stroke(avatarColor.opacity(0.2), lineWidth: 1.5)
                    .frame(width: 40, height: 40)
                
                Text(thread.displayName.prefix(1).uppercased())
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(avatarColor)
            }
            
            // Contact Info
            VStack(alignment: .leading, spacing: 2) {
                Text(thread.displayName)
                    .font(.system(size: 15, weight: .semibold))
                
                Text(thread.address)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Message Count
            Text("\(messages.count) messages")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .glassBoxIfAvailable(radius: 10)
            
            // Refresh Button
            Button(action: loadMessages) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 15))
                    .rotationEffect(.degrees(isLoading ? 360 : 0))
                    .animation(isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isLoading)
            }
            .buttonStyle(.plain)
            .help("Refresh messages")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassBoxIfAvailable(radius: 0)
    }
    
    // MARK: - Messages View
    
    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if isLoading && messages.isEmpty {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading messages...")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else if messages.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "message.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No messages in this conversation")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    LazyVStack(spacing: 6) {
                        ForEach(messages) { message in
                            MessageBubble(message: message, thread: thread)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
            }
            .onChange(of: messages.count) { _, _ in
                // Auto-scroll to bottom when new messages arrive
                if let lastMessage = messages.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // MARK: - Input View
    
    private var inputView: some View {
        HStack(spacing: 12) {
            // Glass text input
            TextField("Type a message...", text: $newMessage, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .glassBoxIfAvailable(radius: 20)
                .onSubmit {
                    sendMessage()
                }
            
            // Glass send button
            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(
                        newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? Color.gray.opacity(0.5)
                        : Color.blue
                    )
                    .clipShape(Circle())
                    .shadow(color: Color.blue.opacity(newMessage.isEmpty ? 0 : 0.3), radius: 8, y: 2)
            }
            .buttonStyle(.plain)
            .disabled(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassBoxIfAvailable(radius: 0)
    }
    
    // MARK: - Read-Only Indicator
    
    private var readOnlyIndicator: some View {
        HStack(spacing: 12) {
            Image(systemName: "eye.fill")
                .font(.title3)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Read-Only Conversation")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("This conversation doesn't support replies")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassBoxIfAvailable(radius: 0)
    }
    
    // MARK: - Avatar Color
    
    private var avatarColor: Color {
        let colors: [Color] = [.blue, .purple, .orange, .teal, .pink, .indigo, .mint]
        let hash = abs(thread.displayName.hashValue)
        return colors[hash % colors.count]
    }
    
    // MARK: - Helper Methods
    
    private func loadMessages() {
        isLoading = true
        print("[sms-detail] Loading messages for thread: \(thread.threadId)")
        
        // Load existing messages from manager
        messages = manager.smsMessagesByThread[thread.threadId] ?? []
        
        // Request fresh messages for this thread
        WebSocketServer.shared.requestSmsMessages(threadId: thread.threadId, limit: 100)
        
        // Stop loading after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            isLoading = false
            // Update with any new messages received
            messages = manager.smsMessagesByThread[thread.threadId] ?? messages
        }
    }
    
    private func sendMessage() {
        let messageText = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageText.isEmpty else { return }
        
        print("[sms-detail] Sending message to \(thread.address): \(messageText)")
        
        // Send via WebSocket
        WebSocketServer.shared.sendSms(to: thread.address, message: messageText)
        
        // Clear input
        newMessage = ""
        
        // Optimistically add to local messages (will be replaced by real message from server)
        let optimisticMessage = SmsMessage(
            id: UUID().uuidString,
            threadId: thread.threadId,
            address: thread.address,
            body: messageText,
            date: Date(),
            type: 2, // sent
            read: true,
            contactName: thread.contactName
        )
        
        messages.append(optimisticMessage)
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: SmsMessage
    let thread: SmsThread
    
    var body: some View {
        HStack {
            if message.isSent {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: message.isSent ? .trailing : .leading, spacing: 4) {
                // Glass message bubble
                Text(message.body)
                    .font(.body)
                    .foregroundColor(message.isSent ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Group {
                            if message.isSent {
                                // Sent: blue-tinted glass
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue, Color.blue.opacity(0.85)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            } else {
                                // Received: glass effect
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color.primary.opacity(0.06))
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                
                // Timestamp
                Text(message.date, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
            
            if message.isReceived {
                Spacer(minLength: 60)
            }
        }
    }
}
