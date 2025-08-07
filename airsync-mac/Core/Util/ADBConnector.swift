//
//  ADBConnector.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2025-08-01.
//

import Foundation

struct ADBConnector {
    static func connectToADB(ip: String) {
        guard let adbPath = Bundle.main.path(forResource: "adb", ofType: nil) else {
            AppState.shared.adbConnectionResult = "ADB binary not found in bundle."
            AppState.shared.adbConnected = false
            return
        }

        // Step 1: Run `adb mdns services` to discover devices
        runADBCommand(adbPath: adbPath, arguments: ["mdns", "services"]) { output in
            let lines = output.components(separatedBy: .newlines)

            var tlsPort: UInt16?
            var normalPort: UInt16?

            for line in lines {
                guard let range = line.range(of: "\(ip):") else { continue }

                let remaining = line[range.upperBound...]
                if let portStr = remaining.split(separator: " ").first,
                   let port = UInt16(portStr) {
                    if line.contains("_adb-tls-connect._tcp"), tlsPort == nil {
                        tlsPort = port
                    } else if line.contains("_adb._tcp"), normalPort == nil {
                        normalPort = port
                    }
                }
            }

            // Prefer TLS port
            let selectedPort = tlsPort ?? normalPort

            guard let port = selectedPort else {
                DispatchQueue.main.async {
                    AppState.shared.adbConnectionResult = "No ADB service found for IP \(ip)."
                    AppState.shared.adbConnected = false
                }
                return
            }

            let fullAddress = "\(ip):\(port)"

            // Step 2: Kill any existing adb server
            runADBCommand(adbPath: adbPath, arguments: ["kill-server"]) { _ in
                // Step 3: Connect to device
                runADBCommand(adbPath: adbPath, arguments: ["connect", fullAddress]) { output in
                    DispatchQueue.main.async {
                        let trimmedOutput = output.trimmingCharacters(in: .whitespacesAndNewlines)
                        AppState.shared.adbConnectionResult = trimmedOutput

                        if trimmedOutput.lowercased().contains("connected to") {
                            AppState.shared.adbConnected = true
                            AppState.shared.adbPort = port
                        } else {
                            AppState.shared.adbConnected = false
                        }
                    }
                }
            }
        }
    }


    static func disconnectADB() {
        guard let adbPath = Bundle.main.path(forResource: "adb", ofType: nil) else {
            AppState.shared.adbConnectionResult = "ADB binary not found in bundle."
            AppState.shared.adbConnected = false
            return
        }

        // Step 1: Kill any existing adb server
        runADBCommand(adbPath: adbPath, arguments: ["kill-server"])
    }


    private static func runADBCommand(adbPath: String, arguments: [String], completion: ((String) -> Void)? = nil) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: adbPath)
        task.arguments = arguments

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        task.terminationHandler = { _ in
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? "No output"
            completion?(output)
        }

        do {
            try task.run()
        } catch {
            completion?("Failed to run adb: \(error.localizedDescription)")
        }
    }

    static func startScrcpy(
        ip: String,
        port: UInt16,
        deviceName: String,
        desktop: Bool? = false,
        package: String? = nil
    ) {
        guard let scrcpyPath = Bundle.main.path(forResource: "scrcpy", ofType: nil) else {
            AppState.shared.adbConnectionResult = "scrcpy binary not found in bundle."
            return
        }

        let fullAddress = "\(ip):\(port)"
        let deviceNameFormatted = deviceName.removingApostrophesAndPossessives()
        let bitrate = AppState.shared.scrcpyBitrate
        let resolution = AppState.shared.scrcpyResolution
        let desktopMode = AppState.shared.scrcpyDesktopMode
        let alwaysOnTop = AppState.shared.scrcpyOnTop

        // Arguments to scrcpy for wireless connection
        // scrcpy --tcpip=<ip>:<port>
        var args = [
            "--window-title=\(deviceNameFormatted)",
            "--tcpip=\(fullAddress)",
            "--video-bit-rate=\(bitrate)M",
            "--video-codec=h265",
            "--max-size=\(resolution)"
        ]

        if  (alwaysOnTop) {
            args.append("--always-on-top")
        }

        if desktop ?? true {
            args.append("--new-display=\(desktopMode)")
        }

        if package != nil {
            args.append(contentsOf: [
                "--new-display=500x800",
                "--start-app=\(package ?? "")",
                "--no-vd-system-decorations"
            ])
        }


        let task = Process()
        task.executableURL = URL(fileURLWithPath: scrcpyPath)
        task.arguments = args

        AppState.shared.lastADBCommand = "scrcpy \(args.joined(separator: " "))"

        // Optionally, capture output if you want to show logs
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        task.terminationHandler = { _ in
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? "No output"
            DispatchQueue.main.async {
                AppState.shared.adbConnectionResult = "scrcpy exited:\n" + output
            }
        }

        do {
            try task.run()
            DispatchQueue.main.async {
                AppState.shared.adbConnectionResult = "Started scrcpy on \(fullAddress)"
            }
        } catch {
            DispatchQueue.main.async {
                AppState.shared.adbConnectionResult = "Failed to start scrcpy: \(error.localizedDescription)"
            }
        }
    }
}
