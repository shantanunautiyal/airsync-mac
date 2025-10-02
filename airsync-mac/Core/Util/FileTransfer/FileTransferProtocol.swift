import Foundation
import CryptoKit

enum FileTransferProtocol {
    static func buildInit(id: String, name: String, size: Int, mime: String, checksum: String?) -> String {
        let checksumLine = (checksum?.isEmpty == false) ? ",\n        \"checksum\": \"\(checksum!)\"" : ""
        return """
        {
            "type": "fileTransferInit",
            "data": {
                "id": "\(id)",
                "name": "\(name)",
                "size": \(size),
                "mime": "\(mime)"\(checksumLine)
            }
        }
        """
    }

    static func buildChunk(id: String, index: Int, base64Chunk: String) -> String {
        return """
        {
            "type": "fileChunk",
            "data": {
                "id": "\(id)",
                "index": \(index),
                "chunk": "\(base64Chunk)"
            }
        }
        """
    }

    static func buildComplete(id: String, name: String, size: Int, checksum: String?) -> String {
        let checksumLine = (checksum?.isEmpty == false) ? ",\n                \"checksum\": \"\(checksum!)\"" : ""
        return """
        {
            "type": "fileTransferComplete",
            "data": {
                "id": "\(id)",
                "name": "\(name)",
                "size": \(size)\(checksumLine)
            }
        }
        """
    }

    static func buildChunkAck(id: String, index: Int) -> String {
        return """
        {
            "type": "fileChunkAck",
            "data": { "id": "\(id)", "index": \(index) }
        }
        """
    }

    static func buildTransferVerified(id: String, verified: Bool) -> String {
        return """
        {
            "type": "transferVerified",
            "data": { "id": "\(id)", "verified": \(verified) }
        }
        """
    }

    static func md5Hex(_ data: Data) -> String {
        let digest = Insecure.MD5.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    static func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
