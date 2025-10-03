import Foundation

struct SmsMessage: Codable, Identifiable {
    let id: String
    let from: String
    let to: String
    let body: String
    let timestamp: Int64
}
