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
                        ConnectionInfoText(label: "Port", icon: "rectangle.connected.to.line.below", text: port)
                        ConnectionInfoText(label: "Key", icon: "key", text: "OIh7GG4")
                        ConnectionInfoText(label: "Plus features", icon: "plus.app", text: "Active")
                    }
                    .padding()

                    // Save button
                    Button("Save Settings") {
                        let portNumber = UInt16(port) ?? Defaults.serverPort
                        appState.myDevice = Device(
                            name: deviceName,
                            ipAddress: getLocalIPAddress() ?? "N/A",
                            port: Int(portNumber)
                        )
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
                    deviceName = Host.current().localizedName ?? "My Mac"
                    port = String(Defaults.serverPort)
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
