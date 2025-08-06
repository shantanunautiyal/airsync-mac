//
//  UpdateChecker.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2025-08-07.
//

import Foundation
import AppKit

class UpdateChecker {
    static let shared = UpdateChecker()
    private let updatesURL = URL(string: "https://sameerasw.github.io/airsync-mac/updates.json")!
    private let assetName = "airsync.dmg"

    private init() {}

    func checkForUpdateAndDownloadIfNeeded(presentingWindow: NSWindow?, completion: @escaping (Bool) -> Void) {
        guard let currentVersionShort = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
              let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String else {
            print("Unable to get current app version info")
            completion(false)
            return
        }

        let currentVersion = "\(currentVersionShort).\(buildVersion)"
        print("Current app version: \(currentVersion)")

        let task = URLSession.shared.dataTask(with: updatesURL) { data, response, error in
            guard error == nil, let data = data else {
                print("Error fetching update info: \(error?.localizedDescription ?? "Unknown error")")
                completion(false)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let latestVersionTag = json["latestVersion"] as? String,
                   let downloadURLString = json["downloadURL"] as? String,
                   let downloadURL = URL(string: downloadURLString) {

                    print("Latest version from JSON: \(latestVersionTag)")

                    if self.isVersion(latestVersionTag, greaterThan: currentVersion) {
                        print("New version available: \(latestVersionTag)")

                        // Ask user if they want to download
                        DispatchQueue.main.async {
                            let alert = NSAlert()
                            alert.messageText = "Update Available"
                            alert.informativeText = "Version \(latestVersionTag) is available. Would you like to download it now?"
                            alert.addButton(withTitle: "Download")
                            alert.addButton(withTitle: "Cancel")
                            if let window = presentingWindow {
                                alert.beginSheetModal(for: window) { response in
                                    if response == .alertFirstButtonReturn {
                                        self.downloadUpdate(from: downloadURL, completion: completion)
                                    } else {
                                        completion(false)
                                    }
                                }
                            } else {
                                let response = alert.runModal()
                                if response == .alertFirstButtonReturn {
                                    self.downloadUpdate(from: downloadURL, completion: completion)
                                } else {
                                    completion(false)
                                }
                            }
                        }
                    } else {
                        print("App is up to date")
                        completion(false)
                    }

                } else {
                    print("Malformed JSON")
                    completion(false)
                }
            } catch {
                print("JSON parsing error: \(error.localizedDescription)")
                completion(false)
            }
        }
        task.resume()
    }

    private func downloadUpdate(from url: URL, completion: @escaping (Bool) -> Void) {
        let downloadsDir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
        let destinationURL = downloadsDir.appendingPathComponent(assetName)

        // Remove existing file if any
        try? FileManager.default.removeItem(at: destinationURL)

        let downloadTask = URLSession.shared.downloadTask(with: url) { tempURL, response, error in
            guard let tempURL = tempURL, error == nil else {
                print("Download failed: \(error?.localizedDescription ?? "Unknown error")")
                completion(false)
                return
            }

            do {
                // Move downloaded file to Downloads folder
                try FileManager.default.moveItem(at: tempURL, to: destinationURL)
                print("Downloaded update to \(destinationURL.path)")

                DispatchQueue.main.async {
                    NSWorkspace.shared.activateFileViewerSelecting([destinationURL])

                    // Prompt user to open DMG and update app
                    let alert = NSAlert()
                    alert.messageText = "Update Downloaded"
                    alert.informativeText = """
                    The update has been downloaded to your Downloads folder.
                    
                    Please open `AirSync.dmg` and move the AirSync app to your Applications folder to complete the update.
                    
                    The app will quit now.
                    """
                    alert.addButton(withTitle: "OK")
                    alert.addButton(withTitle: "Cancel")
                    let response = alert.runModal()
                    if response == .alertFirstButtonReturn {
                        NSApplication.shared.terminate(nil)
                    } else {
                        completion(false)
                    }
                }
            } catch {
                print("Failed to move downloaded file: \(error.localizedDescription)")
                completion(false)
            }
        }
        downloadTask.resume()
    }

    private func isVersion(_ v1: String, greaterThan v2: String) -> Bool {
        let version1 = Version(v1)
        let version2 = Version(v2)
        return version1 > version2
    }
}



struct Version: Comparable {
    let major: Int
    let minor: Int
    let patch: Int
    let build: Int?
    let prerelease: String?

    init(_ string: String) {
        var s = string
        if s.hasPrefix("v") { s.removeFirst() }

        let parts = s.split(separator: "-", maxSplits: 1).map(String.init)
        let numbers = parts[0].split(separator: ".").map { Int($0) ?? 0 }

        major = numbers.count > 0 ? numbers[0] : 0
        minor = numbers.count > 1 ? numbers[1] : 0
        patch = numbers.count > 2 ? numbers[2] : 0
        build = numbers.count > 3 ? numbers[3] : nil

        prerelease = parts.count > 1 ? parts[1] : nil
    }

    static func < (lhs: Version, rhs: Version) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        if lhs.patch != rhs.patch { return lhs.patch < rhs.patch }

        // Compare build if both have it
        if let lb = lhs.build, let rb = rhs.build {
            if lb != rb { return lb < rb }
        } else if lhs.build != nil {
            // lhs has build, rhs doesn't => lhs is greater
            return false
        } else if rhs.build != nil {
            // rhs has build, lhs doesn't => lhs is smaller
            return true
        }

        // Stable version is greater than prerelease
        if lhs.prerelease == nil && rhs.prerelease != nil {
            return false
        }
        if lhs.prerelease != nil && rhs.prerelease == nil {
            return true
        }

        // Both have prerelease, lex compare
        return (lhs.prerelease ?? "") < (rhs.prerelease ?? "")
    }
}
