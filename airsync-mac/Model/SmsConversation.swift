import Foundation

struct SmsConversation: Codable, Identifiable {
    let id: String
    let address: String
    let contact: String?
    var messages: [SmsMessage]

    private enum CodingKeys: String, CodingKey {
        case id
        case address
        case contact
        case messages
        // legacy keys
        case from
        case body
        case timestamp
    }

    init(id: String, address: String, contact: String? = nil, messages: [SmsMessage] = []) {
        self.id = id
        self.address = address
        self.contact = contact
        self.messages = messages
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Try modern shape first
        if let id = try? container.decode(String.self, forKey: .id),
           let address = try? container.decode(String.self, forKey: .address),
           let msgs = try? container.decode([SmsMessage].self, forKey: .messages) {
            self.id = id
            self.address = address
            self.contact = try? container.decodeIfPresent(String.self, forKey: .contact)
            self.messages = msgs
            return
        }

        // Fallback to legacy single-message shape
        let from = (try? container.decode(String.self, forKey: .from)) ?? "unknown"
        let body = (try? container.decode(String.self, forKey: .body)) ?? ""
        let timestamp = (try? container.decode(Int64.self, forKey: .timestamp)) ?? Int64(Date().timeIntervalSince1970)
        // Use 'from' as address and id
        self.id = UUID().uuidString
        self.address = from
        self.contact = nil
        let message = SmsMessage(id: UUID().uuidString, from: from, to: "", body: body, timestamp: timestamp)
        self.messages = [message]
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(address, forKey: .address)
        try container.encodeIfPresent(contact, forKey: .contact)
        try container.encode(messages, forKey: .messages)
    }
}
