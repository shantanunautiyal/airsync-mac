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
    @State private var checking = true

    var body: some View {
        VStack(spacing: 20) {
            Text("Optional Android mirroring setup")
                .font(.title)
                .multilineTextAlignment(.center)
                .padding()

            Text("AirSync can mirror your Android screen to your Mac using ADB and scrcpy. This allows you to control your Android device from your Mac. But mirroring is an optional AirSync+ feature which you may or may not need. ADB and scrcpy are required for mirroring.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 500)

            if checking {
                ProgressView("Checking for ADB and scrcpy...")
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

                    if !adbAvailable || !scrcpyAvailable {
                        Text("Install with Homebrew running the following commands terminal:")
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
                        Text("Great! Both ADB and scrcpy are available.")
                            .font(.callout)
                            .foregroundColor(.green)
                    }
                }
            }

            HStack(spacing: 16) {
                GlassButtonView(
                    label: "Skip",
                    size: .large,
                    action: onSkip
                )
                .transition(.identity)

                GlassButtonView(
                    label: "Continue",
                    systemImage: "arrow.right.circle",
                    size: .large,
                    primary: true,
                    action: onNext
                )
                .transition(.identity)
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

            DispatchQueue.main.async {
                self.adbAvailable = adbFound
                self.scrcpyAvailable = scrcpyFound
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
