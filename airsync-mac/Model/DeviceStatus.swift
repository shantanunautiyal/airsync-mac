//
//  DeviceStatus.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-28.
//

import Foundation

struct DeviceStatus: Codable {
    struct Battery: Codable {
        let level: Int
        let isCharging: Bool
    }

    struct Music: Codable {
        let isPlaying: Bool
        let title: String
        let artist: String
        let volume: Int
        let isMuted: Bool
        let albumArt: String
        let likeStatus: String
    }

    let battery: Battery
    let isPaired: Bool
    let music: Music
}
