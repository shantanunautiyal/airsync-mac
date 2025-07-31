//
//  ContentView.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-27.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState = AppState.shared

    @State private var deviceName: String = ""
    @State private var port: String = "6996"
    @State private var licenseKey: String = ""
    @State private var isCheckingLicense = false
    @State private var licenseValid: Bool? = nil

    @State private var isExpanded: Bool = false


    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    // Name Field
                    VStack {
                        HStack {
                            Label("Device Name", systemImage: "pencil")
                            Spacer()
                        }
                        TextField("Device Name", text: $deviceName)
                    }
                    .padding()


                    VStack{
                        HStack{
                            Label("Connect ADB", systemImage: "iphone")
                            Spacer()
                            Toggle("", isOn: .constant(false))
                                .toggleStyle(.switch)
                                .disabled(true)
                        }

                        HStack{
                            Label("Sync device status", systemImage: "battery.75percent")
                            Spacer()
                            Toggle("", isOn: .constant(false))
                                .toggleStyle(.switch)
                                .disabled(true)
                        }

                        HStack{
                            Label("Sync clipoboard", systemImage: "clipboard")
                            Spacer()
                            Toggle("", isOn: $appState.isClipboardSyncEnabled)
                                .toggleStyle(.switch)
                        }
                    }
                    .padding()

                    // Info Section
                    VStack {
                        ConnectionInfoText(label: "IP Address", icon: "wifi", text: getLocalIPAddress() ?? "N/A")

                        HStack {
                            Label("Server Port", systemImage: "rectangle.connected.to.line.below")
                                .padding(.trailing, 20)
                            Spacer()
                            TextField("Server Port", text: $port)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: port) { oldValue, newValue in
                                    // Only allow digits
                                    port = newValue.filter { "0123456789".contains($0) }
                                }
                        }

                        ConnectionInfoText(
                            label: "Plus features",
                            icon: "plus.app",
                            text: appState.isPlus ? "Active" : "Not active"
                        )

                    }
                    .padding()
                    HStack{
                        Spacer()

                        if #available(macOS 26.0, *) {
                            Button(
                                "Save and Restart the Server",
                                systemImage: "square.and.arrow.down.badge.checkmark"
                            ) {
                                let portNumber = UInt16(
                                    port
                                ) ?? Defaults.serverPort
                                let ipAddress = getLocalIPAddress() ?? "N/A"
    
                                appState.myDevice = Device(
                                    name: deviceName,
                                    ipAddress: ipAddress,
                                    port: Int(portNumber)
                                )
    
                                UserDefaults.standard
                                    .set(deviceName, forKey: "deviceName")
                                UserDefaults.standard
                                    .set(port, forKey: "devicePort")
    
                                WebSocketServer.shared.stop()
                                WebSocketServer.shared.start(port: portNumber)
    
                                appState.shouldRefreshQR = true
                            }
                            .controlSize(.large)
                            .buttonStyle(.glass)
                        } else {
                            Button(
                                "Save and Restart the Server",
                                systemImage: "square.and.arrow.down.badge.checkmark"
                            ) {
                                let portNumber = UInt16(
                                    port
                                ) ?? Defaults.serverPort
                                let ipAddress = getLocalIPAddress() ?? "N/A"

                                appState.myDevice = Device(
                                    name: deviceName,
                                    ipAddress: ipAddress,
                                    port: Int(portNumber)
                                )

                                UserDefaults.standard
                                    .set(deviceName, forKey: "deviceName")
                                UserDefaults.standard
                                    .set(port, forKey: "devicePort")

                                WebSocketServer.shared.stop()
                                WebSocketServer.shared.start(port: portNumber)

                                appState.shouldRefreshQR = true
                            }
                            .controlSize(.large)
                        }

                    }
                    .padding()

                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("AirSync+", systemImage: "key")
                            Spacer()
                        }
                        .padding()

                        TextField("Enter license key", text: $licenseKey)
                            .textFieldStyle(.roundedBorder)
                            .disabled(isCheckingLicense)

                        HStack{
                            if #available(macOS 26.0, *) {
                                Button("Check License") {
                                    Task {
                                        isCheckingLicense = true
                                        licenseValid = nil
                                        let result = try? await checkLicenseKeyValidity(
                                            key: licenseKey
                                        )
                                        licenseValid = result ?? false
                                        isCheckingLicense = false
                                    }
                                }
                                .disabled(
                                    licenseKey.isEmpty || isCheckingLicense
                                )
                                .buttonStyle(.glass)
                                .controlSize(.large)
                            } else {
                                Button("Check License") {
                                    Task {
                                        isCheckingLicense = true
                                        licenseValid = nil
                                        let result = try? await checkLicenseKeyValidity(
                                            key: licenseKey
                                        )
                                        licenseValid = result ?? false
                                        isCheckingLicense = false
                                    }
                                }
                                .disabled(
                                    licenseKey.isEmpty || isCheckingLicense
                                )
                            }


                            if isCheckingLicense {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else if let valid = licenseValid {
                                Image(systemName: valid ? "checkmark.circle.fill" : "xmark.octagon.fill")
                                    .foregroundColor(valid ? .green : .red)
                                    .transition(.scale)
                            }

                            if #available(macOS 26.0, *) {
                                GlassButtonView(
                                    label: "Get AirSync+",
                                    systemImage: "link",
                                    action: {
                                        if let url = URL(string: "https://store.sameerasw.com") {
                                            NSWorkspace.shared.open(url)
                                        }
                                    }
                                )
                                .buttonStyle(.glass)
                            } else {
                                GlassButtonView(
                                    label: "Get AirSync+",
                                    systemImage: "link",
                                    action: {
                                        if let url = URL(string: "https://store.sameerasw.com") {
                                            NSWorkspace.shared.open(url)
                                        }
                                    }
                                )
                            }

                            Spacer()
                        }


                        DisclosureGroup(isExpanded: $isExpanded) {
                            Text(
                            """
It’s not a subscription, Just a small one-time purchase to support the developer (that's me!). Think of it as a little donation to keep this project alive and evolving.
That said, I know not everyone who wants the full experience can afford it. If that’s you, please don’t hesitate to reach out. 😊

The source code is available on GitHub, and you're more than welcome to build with all Plus features free—for personal use which also opens for contributions which is a win win!.
As a thank-you for supporting the app, AirSync+ unlocks some nice extras: media controls, synced widgets, low battery alerts, wireless ADB, and more to come as I keep adding new features.

Enjoy the app!
(っ◕‿◕)っ
"""
                            )
                                .font(.footnote)
                                .multilineTextAlignment(.leading)
                                .padding()
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(8)
                        } label: {
                            Text("Why plus?")
                                .font(.subheadline)
                                .bold()
                        }
                        .padding(.horizontal)
                        .focusEffectDisabled()

                        }
                    }
                    .padding()


                }
                .frame(minWidth: 300)
                .padding()
                .onAppear {
                    if let device = appState.myDevice {
                        deviceName = device.name
                        port = String(device.port)
                    } else {
                        // Load from saved values first
                        deviceName = UserDefaults.standard.string(forKey: "deviceName")
                        ?? (Host.current().localizedName ?? "My Mac")
                        port = UserDefaults.standard.string(forKey: "devicePort")
                        ?? String(Defaults.serverPort)
                    }
                }
            }


        }
}

#Preview {
    SettingsView()
}


