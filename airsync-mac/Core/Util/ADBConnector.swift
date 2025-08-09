//
//  ADBConnector.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2025-08-01.
//

import Foundation

struct ADBConnector {

    // Potential fallback paths
    private static let possibleADBPaths = [
        "/opt/homebrew/bin/adb",  // Apple Silicon Homebrew
        "/usr/local/bin/adb"      // Intel Homebrew
    ]
    private static let possibleScrcpyPaths = [
        "/opt/scrcpy/scrcpy",
        "/opt/homebrew/bin/scrcpy",
        "/usr/local/bin/scrcpy"
    ]

    // Try to locate a binary
    private static func findExecutable(named name: String, fallbackPaths: [String]) -> String? {
        // Step 1: Try direct execution from PATH
        if isExecutableAvailable(name) {
            logBinaryDetection("\(name) found in system PATH — using direct command.")
            return name
        }

        // Step 2: Try fallback paths
        for path in fallbackPaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                logBinaryDetection("\(name) found at \(path) — using fallback path.")
                return path
            }
        }

        logBinaryDetection("\(name) not found in PATH or fallback locations.")
        return nil
    }

    // Check if binary is available in PATH
    private static func isExecutableAvailable(_ name: String) -> Bool {
        let process = Process()
        process.launchPath = "/usr/bin/which"
        process.arguments = [name]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return false
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !output.isEmpty
    }

    private static func logBinaryDetection(_ message: String) {
        DispatchQueue.main.async {
            AppState.shared.adbConnectionResult = (AppState.shared.adbConnectionResult ?? "") + "\n[Binary Detection] \(message)"
        }
        print("[Binary Detection] \(message)")
    }

    static func connectToADB(ip: String) {
        // Find adb
        guard let adbPath = findExecutable(named: "adb", fallbackPaths: possibleADBPaths) else {
            AppState.shared.adbConnectionResult = "ADB not found. Please install via Homebrew: brew install android-platform-tools"
            AppState.shared.adbConnected = false
            return
        }

        UserDefaults.standard.lastADBCommand = "adb mdns services"

        logBinaryDetection("Running: \(adbPath) mdns services")

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
            logBinaryDetection("Killing adb server: \(adbPath) kill-server")
            runADBCommand(adbPath: adbPath, arguments: ["kill-server"]) { _ in
                // Step 3: Connect
                logBinaryDetection("Connecting to device: \(adbPath) connect \(fullAddress)")
                runADBCommand(adbPath: adbPath, arguments: ["connect", fullAddress]) { output in
                    let trimmedOutput = output.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

                    DispatchQueue.main.async {
                        UserDefaults.standard.lastADBCommand = "adb connect \(fullAddress)"
                        AppState.shared.adbConnectionResult = trimmedOutput

                        if trimmedOutput.contains("connected to") {
                            AppState.shared.adbConnected = true
                            AppState.shared.adbPort = port
                            logBinaryDetection("(/^▽^)/ ADB connection successful to \(fullAddress)")
                        }
                        else if trimmedOutput.contains("protocol fault") || trimmedOutput.contains("connection reset by peer") {
                            AppState.shared.adbConnected = false
                            logBinaryDetection("(T＿T) ADB connection failed due to existing connection.")
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
                            logBinaryDetection("(∩︵∩) ADB connection failed.")
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
        guard let adbPath = findExecutable(named: "adb", fallbackPaths: possibleADBPaths) else {
            AppState.shared.adbConnectionResult = "ADB not found — cannot disconnect."
            AppState.shared.adbConnected = false
            return
        }

        logBinaryDetection("Killing adb server: \(adbPath) kill-server")
        runADBCommand(adbPath: adbPath, arguments: ["kill-server"])
        UserDefaults.standard.lastADBCommand = "adb kill-server"
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
            completion?("Failed to run \(adbPath): \(error.localizedDescription)")
        }
    }

    static func startScrcpy(
        ip: String,
        port: UInt16,
        deviceName: String,
        desktop: Bool? = false,
        package: String? = nil
    ) {
        guard let scrcpyPath = findExecutable(named: "scrcpy", fallbackPaths: possibleScrcpyPaths) else {
            AppState.shared.adbConnectionResult = "scrcpy not found. Please install via Homebrew: brew install scrcpy"
            return
        }

        let fullAddress = "\(ip):\(port)"
        let deviceNameFormatted = deviceName.removingApostrophesAndPossessives()
        let bitrate = AppState.shared.scrcpyBitrate
        let resolution = AppState.shared.scrcpyResolution
        let desktopMode = UserDefaults.standard.scrcpyDesktopMode
        let alwaysOnTop = UserDefaults.standard.scrcpyOnTop
        let appRes = UserDefaults.standard.scrcpyShareRes ? UserDefaults.standard.scrcpyDesktopMode : "900x2100"

        var args = [
            "--window-title=\(deviceNameFormatted)",
            "--tcpip=\(fullAddress)",
            "--video-bit-rate=\(bitrate)M",
            "--video-codec=h265",
            "--max-size=\(resolution)"
        ]

        if alwaysOnTop {
            args.append("--always-on-top")
        }

        if desktop ?? true {
            args.append("--new-display=\(desktopMode ?? "1600x1000")")
        }

        if let pkg = package {
            args.append(contentsOf: [
                "--new-display=\(appRes ?? "900x2100")",
                "--start-app=\(pkg)",
                "--no-vd-system-decorations"
            ])
        }

        logBinaryDetection("Launching scrcpy: \(scrcpyPath) \(args.joined(separator: " "))")

        let task = Process()
        task.executableURL = URL(fileURLWithPath: scrcpyPath)
        task.arguments = args

        //  Inject adb into scrcpy's environment
        if let adbPath = findExecutable(named: "adb", fallbackPaths: possibleADBPaths) {
            var env = ProcessInfo.processInfo.environment
            let adbDir = URL(fileURLWithPath: adbPath).deletingLastPathComponent().path
            env["PATH"] = "\(adbDir):" + (env["PATH"] ?? "")
            env["ADB"] = adbPath
            task.environment = env
        }

        UserDefaults.standard.lastADBCommand = "scrcpy \(args.joined(separator: " "))"


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
                AppState.shared.adbConnectionResult = "(ﾉ´ヮ´)ﾉ Started scrcpy on \(fullAddress)"
            }
        } catch {
            DispatchQueue.main.async {
                AppState.shared.adbConnectionResult = "┐('～`；)┌ Failed to start scrcpy: \(error.localizedDescription)"
            }
        }
    }
}
