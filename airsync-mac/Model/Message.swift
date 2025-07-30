//
//  Message.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-29.
//
import Foundation

enum MessageType: String, Codable {
    case device
    case notification
    case status
    case dismissalResponse
    case mediaControlResponse
    case appIcons
    case clipboardUpdate
    case wallpaperImage
}

struct Message: Codable {
    let type: MessageType
    let data: CodableValue
}
