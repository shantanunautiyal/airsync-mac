import SwiftUI

struct ConversationRow: View {
    let conversation: SmsConversation
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(conversation.contact ?? conversation.address)
                .fontWeight(.medium)
            if let lastMessage = conversation.messages.last {
                Text(lastMessage.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .font(.callout)
            }
        }
        .padding(.vertical, 4)
    }
}