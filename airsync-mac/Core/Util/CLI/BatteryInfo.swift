//
//  BatteryInfo.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2025-09-18.
//

import Foundation

struct BatteryStatus {
    let percentage: Int
    let isCharging: Bool
}

class BatteryInfo {
    static func fetchStatus() -> BatteryStatus? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["-g", "batt"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            print("[battery-info] Failed to run pmset: \(error)")
            return nil
        }

        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()

        guard let output = String(data: data, encoding: .utf8) else { return nil }

        // Example output:
        // Now drawing from 'Battery Power'
        // -InternalBattery-0  87%; discharging; (no estimate)

        let lines = output.components(separatedBy: .newlines)
        guard let batteryLine = lines.first(where: { $0.contains("%") }) else { return nil }

        // Extract percentage
        let percentageRegex = try! NSRegularExpression(pattern: "(\\d+)%")
        let percentMatch = percentageRegex.firstMatch(in: batteryLine, range: NSRange(batteryLine.startIndex..., in: batteryLine))
        let percentage: Int
        if let match = percentMatch, let range = Range(match.range(at: 1), in: batteryLine) {
            percentage = Int(batteryLine[range]) ?? 0
        } else {
            percentage = 0
        }

        // Check charging/discharging - when unplugged it shows "discharging"
        let isCharging = !batteryLine.contains("discharging") && (batteryLine.contains("charging") || batteryLine.contains("AC Power"))

        return BatteryStatus(percentage: percentage, isCharging: isCharging)
    }
}
