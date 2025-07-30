//
//  ImageEncoder.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-30.
//

import Foundation
import SwiftUI

extension Image {
    init?(filePath: String) {
        guard let image = NSImage(contentsOfFile: filePath) else { return nil }
        self = Image(nsImage: image)
    }
}


func appIconsDirectory() -> URL {
    let manager = FileManager.default
    let url = manager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("airsync-mac/AppIcons")

    if !manager.fileExists(atPath: url.path) {
        try? manager.createDirectory(at: url, withIntermediateDirectories: true)
    }

    return url
}

func loadCachedIcons() {
    let dir = appIconsDirectory()
    let contents = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []

    for file in contents where file.pathExtension == "png" {
        let package = file.deletingPathExtension().lastPathComponent
        AppState.shared.appIcons[package] = file.path
    }
}
