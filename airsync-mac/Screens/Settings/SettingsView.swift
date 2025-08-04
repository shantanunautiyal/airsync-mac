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


    @State private var availableAdapters: [(name: String, address: String)] = []




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

                    SettingsFeaturesView()

                    // Info Section
                    VStack {
                        HStack {
                            Label("Network", systemImage: "rectangle.connected.to.line.below")
                            Spacer()

                            Picker("", selection: Binding(
                                get: { appState.selectedNetworkAdapter },
                                set: { appState.selectedNetworkAdapter = $0 }
                            )) {
                                Text("Auto").tag(nil as Int?)

                                ForEach(Array(availableAdapters.enumerated()), id: \.offset) { index, adapter in
                                    Text("\(adapter.name) (\(adapter.address))").tag(Optional(index))
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }

                        .onAppear {
                            availableAdapters = WebSocketServer.shared.getAvailableNetworkAdapters()
                        }


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
                        SaveAndRestartButton(
                            title: "Save and Restart the Server",
                            systemImage: "square.and.arrow.down.badge.checkmark",
                            deviceName: deviceName,
                            port: port,
                            version: appState.device?.version ?? "",
                            onSave: nil,
                            onRestart: nil
                        )

                    }
                    .padding()

                    HStack {
                        Text("Liquid Opacity")
                        Spacer()
                        Slider(
                            value: $appState.windowOpacity,
                            in: 0...1.0
                        )
                            .frame(width: 200)
                        HStack{
                            Spacer()
                            Text(appState.windowOpacity == 0.0 ? "Liquid AF" : String(format: "%.0f%%", appState.windowOpacity * 100))
                                .font(.caption)
                        }
                            .frame(width: 75)
                    }
                    .padding()

                    Divider()

                    SettingsPlusView()

                        }
                .padding()
                    }

                }
                .frame(minWidth: 300)
                .onAppear {
                    if let device = appState.myDevice {
                        deviceName = device.name
                        port = String(device.port)
                    } else {
                        deviceName = UserDefaults.standard.string(forKey: "deviceName")
                        ?? (Host.current().localizedName ?? "My Mac")
                        port = UserDefaults.standard.string(forKey: "devicePort")
                        ?? String(Defaults.serverPort)
                    }
                }
            }
}

#Preview {
    SettingsView()
}


