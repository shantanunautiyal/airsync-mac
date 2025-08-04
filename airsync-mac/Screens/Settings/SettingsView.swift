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
    @State private var adbPortString: String = ""
    @State private var showingPlusPopover = false


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


                    VStack{
                        HStack {
                            Label("Connect ADB", systemImage: "bolt.horizontal.circle")
                            Spacer()

                            ZStack {
                                Toggle(
                                    "",
                                    isOn: $appState.adbEnabled
                                )
                                    .labelsHidden()
                                    .toggleStyle(.switch)
                                    .disabled(!AppState.shared.isPlus && AppState.shared.licenseCheck)

                                // Transparent tap area on top to show popover even if disabled
                                if !AppState.shared.isPlus && AppState.shared.licenseCheck {
                                    Rectangle()
                                        .fill(Color.clear)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            showingPlusPopover = true
                                        }
                                }
                            }
                            .frame(width: 55)
                        }
                        .popover(isPresented: $showingPlusPopover, arrowEdge: .bottom) {
                            PlusFeaturePopover(message: "Wireless ADB features are available in AirSync+")
                                .onTapGesture {
                                    showingPlusPopover = false
                                }
                        }

                        // Show port field if ADB toggle is on
                        if appState.isPlus, appState.adbEnabled{
                            HStack {
                                Label("ADB Port", systemImage: "arrow.left.arrow.right")
                                Spacer()
                                TextField("ADB Port", text: $adbPortString)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 100)
                                    .onChange(of: adbPortString) { _, newValue in
                                        adbPortString = newValue.filter { "0123456789".contains($0) }
                                    }

                                    GlassButtonView(
                                        label: "Set",
                                        systemImage: "checkmark.circle",
                                        action: {
                                            if let port = UInt16(adbPortString), port > 0 && port < 65535 {
                                                appState.adbPort = port
                                                UserDefaults.standard.set(port, forKey: "adbPort")
                                            }
                                        }
                                    )
                                    .disabled(adbPortString.isEmpty)

                                if appState.adbConnected {
                                        GlassButtonView(
                                            label: "Disconnect ADB",
                                            systemImage: "stop.circle",
                                            action: {
                                                ADBConnector.disconnectADB()
                                                appState.adbConnected = false
                                            }
                                        )

                                } else {
                                        GlassButtonView(
                                            label: "Connect ADB",
                                            systemImage: "play.circle",
                                            action: {
                                                let ip = appState.device?.ipAddress ?? ""
                                                let port = appState.adbPort
                                                ADBConnector.connectToADB(ip: ip, port: port)
                                            }
                                        )
                                        .disabled(
                                            adbPortString.isEmpty || appState.device == nil
                                        )

                                }



                            }



                            HStack{
                                Label("App Mirroring", systemImage: "apps.iphone.badge.plus")
                                Spacer()
                                Toggle("", isOn: $appState.mirroringPlus)
                                    .toggleStyle(.switch)
                            }

                            if let result = appState.adbConnectionResult {
                                VStack(alignment: .leading, spacing: 4) {
                                    ExpandableLicenseSection(title: "ADB Console", content: result)
                                }
                                .padding()
                                .transition(.opacity)
                            }

                        }


                        HStack{
                            Label("Sync device status", systemImage: "battery.75percent")
                            Spacer()
                            Toggle("", isOn: .constant(false))
                                .toggleStyle(.switch)
                                .disabled(true)
                        }

                        HStack{
                            Label("Sync clipboard", systemImage: "clipboard")
                            Spacer()
                            Toggle("", isOn: $appState.isClipboardSyncEnabled)
                                .toggleStyle(.switch)
                        }

                    }
                    .padding()

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

                    adbPortString = String(appState.adbPort)
                }

            }


}

#Preview {
    SettingsView()
}


