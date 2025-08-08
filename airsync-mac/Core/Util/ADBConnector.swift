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

        AppState.shared.lastADBCommand = "adb mdns services"

        // Step 1: Discover devices
        runADBCommand(adbPath: adbPath, arguments: ["mdns", "services"]) { output in
            let trimmedMDNSOutput = output.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmedMDNSOutput.isEmpty {
                DispatchQueue.main.async {
                    AppState.shared.adbConnectionResult = """
`adb mdns services` returned no results.

Make sure:
- Your Android device is on the same Wi-Fi network
- Wireless debugging is enabled in Developer Options
- You can see your device in `adb devices`

Raw output:
\(trimmedMDNSOutput)
"""
                    AppState.shared.adbConnected = false
                }
                return
            }

            let lines = trimmedMDNSOutput.components(separatedBy: .newlines)
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

            let selectedPort = tlsPort ?? normalPort
            guard let port = selectedPort else {
                DispatchQueue.main.async {
                    AppState.shared.adbConnectionResult = """
No ADB service found for IP \(ip).

Suggestions:
- Ensure your Android device is in Wireless debugging mode
- Try toggling Wireless Debugging off and on again
- Reconnect to the same Wi-Fi as your Mac

Raw `adb mdns services` output:
\(trimmedMDNSOutput)
"""
                    AppState.shared.adbConnected = false
                }
                return
            }

            let fullAddress = "\(ip):\(port)"

            // Step 2: Kill adb server
            runADBCommand(adbPath: adbPath, arguments: ["kill-server"]) { _ in
                // Step 3: Connect
                runADBCommand(adbPath: adbPath, arguments: ["connect", fullAddress]) { output in
                    let trimmedOutput = output.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

                    DispatchQueue.main.async {
                        AppState.shared.lastADBCommand = "adb connect \(fullAddress)"
                        AppState.shared.adbConnectionResult = trimmedOutput

                        if trimmedOutput.contains("connected to") {
                            AppState.shared.adbConnected = true
                            AppState.shared.adbPort = port
                        }
                        else if trimmedOutput.contains("protocol fault") || trimmedOutput.contains("connection reset by peer") {
                            AppState.shared.adbConnected = false
                            AppState.shared.adbConnectionResult = """
ADB connection failed due to another ADB instance already using the device.

This is not an AirSync error — it’s a limitation of the ADB protocol (only one connection allowed at a time).

Possible fixes:
- Check for other ADB connections (including Android Studio, scrcpy, or other tools)
- In Terminal: run `adb kill-server`
- If that doesn’t work, quit ADB manually via Activity Monitor
- Toggle Wireless Debugging off and on in Developer Options

Raw output:
\(trimmedOutput)
"""
                        }
                        else {
                            AppState.shared.adbConnected = false
                            AppState.shared.adbConnectionResult = (AppState.shared.adbConnectionResult ?? "") + """

Possible fixes:
- Ensure device is authorized for adb
- Disconnect and reconnect Wireless Debugging
- Run `adb disconnect` then retry
- It might be connected to another device.
  Try killing any external adb instances in mac terminal with 'adb kill-server' command.

Raw output:
\(trimmedOutput)
"""
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
        AppState.shared.lastADBCommand = "adb kill-server"
        AppState.shared.adbConnected = false
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
                "--new-display=900x900/140",
                "--start-app=\(package ?? "")",
                "--no-vd-system-decorations"
            ])
        }


        let task = Process()
        task.executableURL = URL(fileURLWithPath: scrcpyPath)
        task.arguments = args

        AppState.shared.lastADBCommand = "scrcpy \(args.joined(separator: " "))"

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
