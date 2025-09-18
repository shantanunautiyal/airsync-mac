//
//  MirroringSetupView.swift
//  AirSync
//
//  Created by AI Assistant on 2025-09-04.
//

import SwiftUI

struct MirroringSetupView: View {
    let onNext: () -> Void
    let onSkip: () -> Void

    @State private var adbAvailable = false
    @State private var scrcpyAvailable = false
    @State private var mediaControlAvailable = false
    @State private var checking = true

    var body: some View {
        VStack(spacing: 20) {
            Text("Optional Setup - Android Mirror and Media Playback")
                .font(.title)
                .multilineTextAlignment(.center)
                .padding()

            Text("AirSync can mirror your Android screen to your Mac using ADB and scrcpy. This allows you to control your Android device from your Mac. But mirroring is an optional AirSync+ feature which you may or may not need. ADB and scrcpy are required for mirroring. For rich media features (showing the current song and controlling playback), we recommend installing the optional media-control CLI as well.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: 500)


            Text("media-control is optional, but enables Now Playing sync to Android and media keys from Mac. Recommended.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: 500)

            if checking {
                ProgressView("Checking for ADB, scrcpy, and media-control...")
                    .frame(width: 200, height: 50)
            } else {
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: adbAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(adbAvailable ? .green : .red)
                        Text("ADB \(adbAvailable ? "found" : "not found")")
                    }

                    HStack {
                        Image(systemName: scrcpyAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(scrcpyAvailable ? .green : .red)
                        Text("scrcpy \(scrcpyAvailable ? "found" : "not found")")
                    }

                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: mediaControlAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(mediaControlAvailable ? .green : .red)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("media-control \(mediaControlAvailable ? "found" : "not found")")
                        }
                    }

                    if !adbAvailable || !scrcpyAvailable || !mediaControlAvailable {
                        Text("Install with Homebrew by running the following commands in Terminal:")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .frame(maxWidth: 500)

                        VStack(alignment: .leading, spacing: 8) {
                            if !adbAvailable {
                                commandRow("brew install android-platform-tools")
                            }
                            if !scrcpyAvailable {
                                commandRow("brew install scrcpy")
                            }
                            if !mediaControlAvailable {
                                commandRow("brew install media-control")
                            }
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)

                        Text("After installing, click 'Check Again' to verify.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        GlassButtonView(
                            label: "Check Again",
                            systemImage: "arrow.clockwise",
                            size: .large,
                            action: {
                                checking = true
                                checkDependencies()
                            }
                        )
                        .transition(.identity)
                    } else {
                        Text("Great! ADB, scrcpy, and media-control are available.")
                            .font(.callout)
                            .foregroundColor(.green)
                    }
                }
            }

            HStack(spacing: 16) {
                if adbAvailable && scrcpyAvailable {
                    GlassButtonView(
                        label: "Continue",
                        systemImage: "arrow.right.circle",
                        size: .large,
                        primary: true,
                        action: onNext
                    )
                    .transition(.identity)
                } else {
                    GlassButtonView(
                        label: "Skip",
                        size: .large,
                        action: onSkip
                    )
                    .transition(.identity)
                }
            }
        }
        .onAppear {
            checkDependencies()
        }
    }

    private func checkDependencies() {
        DispatchQueue.global(qos: .background).async {
            let adbFound = ADBConnector.findExecutable(named: "adb", fallbackPaths: ADBConnector.possibleADBPaths) != nil
            let scrcpyFound = ADBConnector.findExecutable(named: "scrcpy", fallbackPaths: ADBConnector.possibleScrcpyPaths) != nil
            let mediaFound = ADBConnector.findExecutable(named: "media-control", fallbackPaths: ["/opt/homebrew/bin/media-control", "/usr/local/bin/media-control"]) != nil

            // let scrcpyFound = false

            DispatchQueue.main.async {
                self.adbAvailable = adbFound
                self.scrcpyAvailable = scrcpyFound
                self.mediaControlAvailable = mediaFound
                self.checking = false
            }
        }
    }

    @ViewBuilder
    private func commandRow(_ command: String) -> some View {
        HStack {
            Text(command)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.primary)
            Spacer()
            Button(action: {
                copyToClipboard(command)
            }) {
                Image(systemName: "doc.on.doc")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

#Preview {
    MirroringSetupView(onNext: {}, onSkip: {})
}
