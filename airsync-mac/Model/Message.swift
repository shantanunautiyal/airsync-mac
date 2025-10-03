//
//  Message.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-29.
//
import Foundation

enum MessageType: String, Codable {
    case device
    case macInfo
    case notification
    case notificationAction
    case notificationActionResponse
    case notificationUpdate
    case status
    case dismissalResponse
    case mediaControlResponse
    case macMediaControl
    case macMediaControlResponse
    case appIcons
    case clipboardUpdate
    case volumeControlResponse
    case wallpaperResponse
    case requestHealthData
    case health
    // file transfer
    case fileTransferInit
    case fileChunk
    case fileTransferComplete
    case fileChunkAck
    case transferVerified
    // wake up / quick connect
    case wakeUpRequest
    case startMirrorRequest
    case startMirrorResponse
    case stopMirrorRequest
    // SMS
    case requestSmsConversations
    case smsConversations
    case requestSmsMessages
    case smsMessages
    case sendSmsMessage
    case smsMessageSent
}

struct Message: Codable {
    let type: MessageType
    let data: CodableValue
}
