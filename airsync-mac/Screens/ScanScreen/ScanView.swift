//
//  ContentView.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-27.
//

import SwiftUI

struct ScanView: View {
    @ObservedObject var appState = AppState.shared

    @State private var deviceName: String = ""
    @State private var port: String = "6996"

    var body: some View {
        NavigationStack {
            HStack {
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
                        }

                        HStack{
                            Label("Sync device status", systemImage: "battery.75percent")
                            Spacer()
                            Toggle("", isOn: .constant(true))
                                .toggleStyle(.switch)
                        }

                        HStack{
                            Label("Sync clipoboard", systemImage: "clipboard")
                            Spacer()
                            Toggle("", isOn: .constant(true))
                                .toggleStyle(.switch)
                        }
                    }
                    .padding()

                    // Info Section
                    VStack {
                        ConnectionInfoText(label: "IP Address", icon: "wifi", text: getLocalIPAddress() ?? "N/A")

                        VStack {
                            HStack {
                                Label("Server Port", systemImage: "rectangle.connected.to.line.below")
                                Spacer()
                            }
                            TextField("Server Port", text: $port)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: port) { oldValue, newValue in
                                    // Only allow digits
                                    port = newValue.filter { "0123456789".contains($0) }
                                }
                        }

                        ConnectionInfoText(label: "Key", icon: "key", text: "OIh7GG4")
                        ConnectionInfoText(label: "Plus features", icon: "plus.app", text: "Active")
                    }
                    .padding()

                    .padding()

                    Button("Save Settings") {
                        let portNumber = UInt16(port) ?? Defaults.serverPort

                        appState.myDevice = Device(
                            name: deviceName,
                            ipAddress: getLocalIPAddress() ?? "N/A",
                            port: Int(portNumber)
                        )

                        // Save to UserDefaults
                        UserDefaults.standard.set(deviceName, forKey: "deviceName")
                        UserDefaults.standard.set(port, forKey: "devicePort")
                    }



                }
                .frame(minWidth: 300)
            }
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
    ScanView()
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
