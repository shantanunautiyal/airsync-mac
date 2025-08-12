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
                    .background(.background.opacity(0.3))
                    .cornerRadius(12.0)

                    SettingsFeaturesView()
                        .background(.background.opacity(0.3))
                        .cornerRadius(12.0)

                    // Info Section
                    VStack {
                        HStack {
                            Label("Network", systemImage: "rectangle.connected.to.line.below")
                            Spacer()

                            Picker("", selection: Binding(
                                get: { appState.selectedNetworkAdapterName },
                                set: { appState.selectedNetworkAdapterName = $0 }
                            )) {
                                Text("Auto").tag(nil as String?)
                                ForEach(availableAdapters, id: \.name) { adapter in
                                    Text("\(adapter.name) (\(adapter.address))").tag(Optional(adapter.name))
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        .onAppear {
                            availableAdapters = WebSocketServer.shared.getAvailableNetworkAdapters()
                        }
                        .onChange(of: appState.selectedNetworkAdapterName) { _, _ in
                            WebSocketServer.shared.stop()
                            if let port = UInt16(port) {
                                WebSocketServer.shared.start(port: port)
                            } else {
                                WebSocketServer.shared.start()
                            }
                        }




                        ConnectionInfoText(
                            label: "IP Address",
                            icon: "wifi",
                            text: WebSocketServer.shared.getLocalIPAddress(adapterName:
                                appState.selectedNetworkAdapterName
                            ) ?? "N/A"
                        )

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
                    .background(.background.opacity(0.3))
                    .cornerRadius(12.0)

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

                    VStack {
                        HStack{
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

                        HStack{
                            Text("Toolbar contrast")
                            Spacer()
                            Toggle("", isOn: $appState.toolbarContrast)
                                .toggleStyle(.switch)
                        }
                    }
                    .padding()
                    .background(.background.opacity(0.3))
                    .cornerRadius(12.0)

                    SettingsPlusView()
                        .padding()
                        .background(.background.opacity(0.3))
                        .cornerRadius(12.0)

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


