//
//  MediaControlModels.swift
//  AirSync
//
//  Created by Shantanu Nautiyal on 04/10/25.
//

import Foundation

struct MediaControlData: Codable {
    let action: MediaAction
}

enum MediaAction: String, Codable {
    case playPause
    case next
    case previous
}
