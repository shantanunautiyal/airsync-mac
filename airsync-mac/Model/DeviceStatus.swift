//
//  DeviceStatus.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-28.
//

import Foundation

struct DeviceStatus: Hashable{

    let battery: Battery
    let isPaired: Bool
    let music: Music

}

struct Music: Hashable{

    let isPlaying: Bool
    let title: String
    let artist: String
    let volume: Int
    let isMuted: Bool
}

struct Battery: Hashable{
    let level: Int
    let isCharging: Bool
}

