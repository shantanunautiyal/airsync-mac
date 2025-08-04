//
//  SettingsFeaturesView.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2025-08-04.
//

import SwiftUI

struct SettingsFeaturesView: View {
    @ObservedObject var appState = AppState.shared

    @State private var adbPortString: String = ""
    @State private var showingPlusPopover = false
    @State private var tempBitrate: Double = 4.00
    @State private var isDragging = false

    var body: some View {
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

                VStack{
                    HStack{
                        Label("Mirroring Settings", systemImage: "gear")
                        Spacer()
                    }
                    HStack{
                        Text("Video bitrate")
                        Spacer()
                        Slider(
                            value: $tempBitrate,
                            in: 1...8,
                            step: 1,
                            onEditingChanged: { editing in
                                if !editing {
                                    AppState.shared.scrcpyBitrate = Int(tempBitrate)
                                }
                                isDragging = editing
                            }
                        )
                        .focusable(false)
                        .frame(maxWidth: 200)

                        Text("\(AppState.shared.scrcpyBitrate) Mbps")
                            .monospacedDigit()
                            .foregroundColor(isDragging ? .accentColor : .secondary)
                            .frame(width: 60, alignment: .leading)
                    }
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
        .onAppear{

            adbPortString = String(appState.adbPort)
        }
    }
}
