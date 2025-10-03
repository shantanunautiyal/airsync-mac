import SwiftUI

struct MessageBubble: View {
    let message: SmsMessage
    @ObservedObject var appState = AppState.shared
    
    var body: some View {
        // Determine message direction more robustly
        let isFromMe: Bool = {
            let from = message.from.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if from == "me" { return true }
            if let myDevice = AppState.shared.myDevice {
                let myName = myDevice.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                let myIp = myDevice.ipAddress.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if from == myName || from == myIp { return true }
            }
            return false
        }()

        // Format timestamp (handles seconds or milliseconds)
        let formattedTime: String = {
            let ts = message.timestamp
            let interval: TimeInterval = ts > 9_999_999_999 ? TimeInterval(ts) / 1000.0 : TimeInterval(ts)
            let d = Date(timeIntervalSince1970: interval)
            let df = DateFormatter()
            df.timeStyle = .short
            df.dateStyle = .none
            return df.string(from: d)
        }()

        HStack(alignment: .bottom) {
            if isFromMe { Spacer(minLength: 8) }

            VStack(alignment: isFromMe ? .trailing : .leading, spacing: 4) {
                // Bubble
                Text(message.body)
                    .padding(12)
                    .background(isFromMe ? Color.accentColor : Color.secondary.opacity(0.15))
                    .foregroundStyle(isFromMe ? .white : .primary)
                    .cornerRadius(16)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 600, alignment: isFromMe ? .trailing : .leading)
                    .multilineTextAlignment(isFromMe ? .trailing : .leading)
                    .textSelection(.enabled)

                // Timestamp
                Text(formattedTime)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(isFromMe ? .trailing : .leading, 6)
            }

            if !isFromMe { Spacer(minLength: 8) }
        }
    }
}