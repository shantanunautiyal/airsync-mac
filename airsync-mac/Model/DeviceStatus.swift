//
//  DeviceStatus.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-28.
//

import Foundation

struct DeviceStatus: Hashable, Identifiable, Codable{
    var id = UUID()

    let battery: Battery
    let isPaired: Bool
    let music: Music
}

struct Music: Hashable, Codable{
    let isPlaying: Bool
    let title: String
    let artist: String
    let volume: Int
    let isMuted: Bool
}

struct Battery: Hashable, Codable{
    let level: Int
    let isCharging: Bool
}

