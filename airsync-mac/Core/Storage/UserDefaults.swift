//
//  UserDefaults.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2025-08-10.
//

import Foundation

extension UserDefaults {
    private enum Keys {
        static let lastLicenseCheckDate = "lastLicenseCheckDate"
        static let consecutiveLicenseFailCount = "consecutiveLicenseFailCount"
        static let scrcpyOnTop = "scrcpyOnTop"
        static let scrcpyShareRes = "scrcpyShareRes"
        static let scrcpyDesktopMode = "scrcpyDesktopMode"
        static let lastADBCommand = "lastADBCommand"
        static let stayAwake = "stayAwake"
        static let turnScreenOff = "turnScreenOff"
        static let noAudio = "noAudio"


        static let notificationStacks = "notificationStacks"
    }

    var consecutiveLicenseFailCount: Int {
        get { integer(forKey: Keys.consecutiveLicenseFailCount) }
        set { set(newValue, forKey: Keys.consecutiveLicenseFailCount) }
    }

    var lastLicenseCheckDate: Date? {
        get { object(forKey: "lastLicenseCheckDate") as? Date }
        set { set(newValue, forKey: "lastLicenseCheckDate") }
    }

    var scrcpyOnTop: Bool {
        get { bool(forKey: Keys.scrcpyOnTop)}
        set { set(newValue, forKey: Keys.scrcpyOnTop)}
    }

    var scrcpyShareRes: Bool {
        get { bool(forKey: Keys.scrcpyShareRes)}
        set { set(newValue, forKey: Keys.scrcpyShareRes)}
    }

    var scrcpyDesktopMode: String? {
        get { object(forKey: "scrcpyDesktopMode") as? String }
        set { set(newValue, forKey: Keys.scrcpyDesktopMode) }
    }

    var lastADBCommand: String? {
        get { object(forKey: "lastADBCommand") as? String }
        set { set(newValue, forKey: Keys.lastADBCommand) }
    }

    var stayAwake: Bool {
        get { bool(forKey: Keys.stayAwake)}
        set { set(newValue, forKey: Keys.stayAwake)}
    }

    var turnScreenOff: Bool {
        get { bool(forKey: Keys.turnScreenOff)}
        set { set(newValue, forKey: Keys.turnScreenOff)}
    }

    var noAudio: Bool {
        get { bool(forKey: Keys.noAudio)}
        set { set(newValue, forKey: Keys.noAudio)}
    }

    var notificationStacks: Bool {
        get { bool(forKey: Keys.notificationStacks)}
        set { set(newValue, forKey: Keys.notificationStacks)}
    }
}
