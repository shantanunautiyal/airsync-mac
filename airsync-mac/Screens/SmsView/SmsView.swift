import SwiftUI

struct SmsView: View {
    @ObservedObject var appState = AppState.shared
    @State private var selectedConversationId: String? = nil
    @State private var messageText: String = ""
    
    var body: some View {
        HSplitView {
            // Conversations List
            List(appState.smsConversations) { conversation in
                ConversationRow(conversation: conversation)
                    .onTapGesture {
                        selectedConversationId = conversation.id
                    }
                    .background(selectedConversationId == conversation.id ? Color.accentColor.opacity(0.1) : Color.clear)
            }
            .frame(minWidth: 250, maxWidth: 350)
            
            // Message Thread View
            if let conversation = appState.smsConversations.first(where: { $0.id == selectedConversationId }) {
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(conversation.messages) { message in
                                    MessageBubble(message: message)
                                }
                            }
                            .padding()
                        }
                        .frame(height: geometry.size.height - 50) // Adjust 50 based on input field height

                        // Message Input
                        HStack {
                            TextField("Type a message...", text: $messageText)
                                .textFieldStyle(.roundedBorder)
                            
                            Button(action: sendMessage) {
                                Image(systemName: "paperplane.fill")
                            }
                            .disabled(messageText.isEmpty)
                        }
                        .padding()
                        .frame(height: 50)
                    }
                }
            } else {
                VStack {
                    Spacer()
                    Text("Select a conversation")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            // Request SMS permissions and load conversations
            requestSmsPermissions()
        }
    }
    
    private func sendMessage() {
        guard let conversation = appState.smsConversations.first(where: { $0.id == selectedConversationId }),
              !messageText.isEmpty else { return }

        // Create message payload
        let payload: [String: Any] = [
            "type": "sendSms",
            "data": [
                "recipient": conversation.address,
                "message": messageText
            ]
        ]

        // Send via WebSocket
        if let jsonData = try? JSONSerialization.data(withJSONObject: payload),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            appState.sendMessage(jsonString)

            // Clear input field
            messageText = ""
        }
    }
    
    private func requestSmsPermissions() {
        let payload: [String: Any] = [
            "type": "requestSmsPermissions",
            "data": [:]
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: payload),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            appState.sendMessage(jsonString)
        }
    }
}

// MARK: - Component Imports

#Preview {
    SmsView()
}