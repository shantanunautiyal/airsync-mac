//
//  Notification.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-28.
//

import Foundation

struct Notification: Codable, Identifiable, Equatable {
    let id = UUID()
    let title: String
    let body: String
    let app: String
    let nid: String
    let package: String

    private enum CodingKeys: String, CodingKey {
        case title, body, app, nid, package
        // id is omitted — won't be decoded or encoded
    }
}
