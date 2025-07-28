//
//  Notification.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-28.
//

import Foundation

struct Notification: Hashable, Identifiable{
    let id = UUID()

    let title: String
    let body: String
    let app: String

}
