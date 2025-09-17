//
//  NowPlayingAccessibility.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2025-09-17.
//

import Foundation

class NowPlayingCLI {
    static let shared = NowPlayingCLI()
    private let path = "/opt/homebrew/bin/media-control"

    private init() {}

    func fetchNowPlaying(completion: @escaping (NowPlayingInfo?) -> Void) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/media-control")
        process.arguments = ["get"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        let handle = pipe.fileHandleForReading

        var buffer = Data()

        handle.readabilityHandler = { fileHandle in
            let data = fileHandle.availableData
            guard !data.isEmpty else { return }
            buffer.append(data)
        }

        process.terminationHandler = { _ in
            handle.readabilityHandler = nil
            guard !buffer.isEmpty else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            // Try decoding the full JSON at once
            if let jsonString = String(data: buffer, encoding: .utf8) {
                print("Full media-control JSON:", jsonString) // debug
                do {
                    if let dict = try JSONSerialization.jsonObject(with: Data(jsonString.utf8)) as? [String: Any] {
                        var info = NowPlayingInfo()
                        info.updateFromPayload(dict)
                        DispatchQueue.main.async {
                            completion(info)
                        }
                    }
                } catch {
                    print("JSON parse error:", error)
                }
            } else {
                DispatchQueue.main.async { completion(nil) }
            }
        }

        do {
            try process.run()
        } catch {
            print("Failed to run media-control get:", error)
            completion(nil)
        }
    }




    func play() { runCommand("play") }
    func pause() { runCommand("pause") }
    func toggle() { runCommand("toggle-play-pause") }
    func next() { runCommand("next") }
    func previous() { runCommand("previous") }

    private func runCommand(_ cmd: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = [cmd]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        try? process.run()
    }
}
