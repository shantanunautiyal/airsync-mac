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

extension String {
    func stripBase64Prefix() -> String {
        if let range = self.range(of: "base64,") {
            return String(self[range.upperBound...])
        }
        return self
    }
}


// General-purpose subdirectory helper
func appCacheDirectory(sub folder: String) -> URL {
    let manager = FileManager.default
    let baseURL = manager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("airsync-mac")
        .appendingPathComponent(folder)

    if !manager.fileExists(atPath: baseURL.path) {
        try? manager.createDirectory(at: baseURL, withIntermediateDirectories: true)
    }

    return baseURL
}

// Icons
func appIconsDirectory() -> URL {
    return appCacheDirectory(sub: "AppIcons")
}

func loadCachedIcons() {
    let dir = appIconsDirectory()
    let contents = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []

    for file in contents where file.pathExtension == "png" {
        let package = file.deletingPathExtension().lastPathComponent
        AppState.shared.appIcons[package] = file.path
    }
}

// Wallpapers
func wallpaperDirectory() -> URL {
    return appCacheDirectory(sub: "Wallpapers")
}

func loadCachedWallpapers() {
    let dir = wallpaperDirectory()
    let contents = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []

    for file in contents where file.pathExtension == "png" {
        let key = file.deletingPathExtension().lastPathComponent
        AppState.shared.deviceWallpapers[key] = file.path
    }
}

