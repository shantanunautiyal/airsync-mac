//
//  SystemSounds.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-09-30.
//

import Foundation
import AudioToolbox
import AppKit

struct SystemSounds {
    /// Available macOS system sounds for notifications
    static let availableSounds: [String] = [
        "Basso",
        "Blow",
        "Bottle", 
        "Frog",
        "Funk",
        "Glass",
        "Hero",
        "Morse",
        "Ping",
        "Pop",
        "Purr",
        "Sosumi",
        "Submarine",
        "Tink"
    ]
    
    /// Play a system sound for testing
    static func playSound(_ soundName: String) {
        guard soundName != "default" else {
            // Play the default system notification sound
            NSSound.beep()
            return
        }
        
        // Try to play the named system sound
        if let sound = NSSound(named: soundName) {
            sound.play()
        } else {
            // Try from system sounds directory
            let soundPath = "/System/Library/Sounds/\(soundName).aiff"
            if let sound = NSSound(contentsOfFile: soundPath, byReference: true) {
                sound.play()
            } else {
                // Fallback to system beep
                NSSound.beep()
            }
        }
    }
}