//
//  ContentView.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-27.
//

import SwiftUI

struct ScanView: View {
    @ObservedObject var appState = AppState.shared
    @EnvironmentObject var socketServer: SocketServer

    @State private var deviceName: String = ""
    @State private var port: String = ""

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
                        ConnectionInfoText(label: "IP Address", icon: "wifi", text: socketServer.localIPAddress ?? "Unavailable")
                        ConnectionInfoText(label: "Port", icon: "rectangle.connected.to.line.below", text: port)
                        ConnectionInfoText(label: "Key", icon: "key", text: "OIh7GG4")
                        ConnectionInfoText(label: "Plus features", icon: "plus.app", text: "Active")
                    }
                    .padding()

                    // Save button
                    Button("Save Settings") {
                        if let portNumber = UInt16(port) {
                            appState.myDevice = Device(
                                name: deviceName,
                                ipAddress: socketServer.localIPAddress ?? "0.0.0.0",
                                port: Int(portNumber)
                            )
                        }
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
                    // Default to current system name and default port
                    deviceName = Host.current().localizedName ?? "My Mac"
                    port = String(socketServer.localPort ?? 5555)
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
