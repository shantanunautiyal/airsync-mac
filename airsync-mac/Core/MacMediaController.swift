////
//  MacMediaController.swift
//  airsync-mac
//
//  Created by Shantanu Nautiyal on 2025-10-04.
//

import Foundation
import AppKit

class MacMediaController {

    // These constants represent the specific keys for media control
    private let keyPlayPause: Int32 = 16
    private let keyNext: Int32 = 19
    private let keyPrevious: Int32 = 20

    /// Performs a media action by simulating a key press.
    func perform(_ action: MediaAction) {
        let keyCode: Int32

        switch action {
        case .playPause:
            keyCode = keyPlayPause
            print("[media-control] Executing Play/Pause action")
        case .next:
            keyCode = keyNext
            print("[media-control] Executing Next action")
        case .previous:
            keyCode = keyPrevious
            print("[media-control] Executing Previous action")
        }

        // Simulate the key press
        pressMediaKey(keyCode)
    }

    /// Simulates a single press of a special media key.
    private func pressMediaKey(_ key: Int32) {
        _ = CGEventSource(stateID: .hidSystemState)

        // Simulate Key Down event
        let keyDownEvent = NSEvent.otherEvent(
            with: .systemDefined,
            location: NSPoint(),
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8, // Subtype for media key events
            data1: (Int(key) << 16) | (0x0A << 8), // Key down state
            data2: -1
        )
        keyDownEvent?.cgEvent?.post(tap: .cghidEventTap)

        // Simulate Key Up event
        let keyUpEvent = NSEvent.otherEvent(
            with: .systemDefined,
            location: NSPoint(),
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8, // Subtype for media key events
            data1: (Int(key) << 16) | (0x0B << 8), // Key up state
            data2: -1
        )
        keyUpEvent?.cgEvent?.post(tap: .cghidEventTap)
    }
}
