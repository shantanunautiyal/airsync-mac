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
                        Button("Save Settings") {
                            let portNumber = UInt16(port) ?? Defaults.serverPort
                            let ipAddress = getLocalIPAddress() ?? "N/A"

                            appState.myDevice = Device(
                                name: deviceName,
                                ipAddress: ipAddress,
                                port: Int(portNumber)
                            )

                            UserDefaults.standard.set(deviceName, forKey: "deviceName")
                            UserDefaults.standard.set(port, forKey: "devicePort")

                            WebSocketServer.shared.stop()
                            WebSocketServer.shared.start(port: portNumber)

                            appState.shouldRefreshQR = true
                        }


                    }
                    .padding()

                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("AirSync+ License", systemImage: "key")
                            Spacer()
                        }

                        TextField("Enter license key", text: $licenseKey)
                            .textFieldStyle(.roundedBorder)
                            .disabled(isCheckingLicense)

                        HStack {
                            Button("Check License") {
                                Task {
                                    isCheckingLicense = true
                                    licenseValid = nil
                                    let result = try? await checkLicenseKeyValidity(key: licenseKey)
                                    licenseValid = result ?? false
                                    isCheckingLicense = false
                                }
                            }
                            .disabled(licenseKey.isEmpty || isCheckingLicense)

                            if isCheckingLicense {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else if let valid = licenseValid {
                                Image(systemName: valid ? "checkmark.circle.fill" : "xmark.octagon.fill")
                                    .foregroundColor(valid ? .green : .red)
                                    .transition(.scale)
                            }
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

    
}

#Preview {
    SettingsView()
}


struct ConnectionInfoText: View {
    var label: String
    var icon: String
    var text: String

    var body: some View {
        HStack{
            Label(label, systemImage: icon)
            Spacer()
            Text(text)
        }
        .padding(1)
    }
}
