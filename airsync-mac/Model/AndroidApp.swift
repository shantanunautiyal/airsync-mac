//
//  AndroidApp.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-28.
//

import Foundation

struct AndroidApp: Hashable, Identifiable{
    let id = UUID()

    let packageName: String
    let name: String
    let iconUrl: String?
    var listening: Bool

}
