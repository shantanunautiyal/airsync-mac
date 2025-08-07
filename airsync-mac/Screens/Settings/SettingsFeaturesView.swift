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
    @State private var tempResolution: Double = 1200.00
    @State private var isDragging = false

    @State var isExpanded = false

    var body: some View {
        VStack{
            HStack {
                Label("Auto connect ADB", systemImage: "bolt.horizontal.circle")
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
                                ADBConnector.connectToADB(ip: ip)
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
                    DisclosureGroup(isExpanded: $isExpanded) {
                        VStack(spacing: 10){

                            HStack {
                                Text("Video bitrate")
                                Spacer()

                                Slider(
                                    value: $tempBitrate,
                                    in: 1...12,
                                    step: 1,
                                    onEditingChanged: { editing in
                                        if !editing {
                                            AppState.shared.scrcpyBitrate = Int(tempBitrate)
                                        }
                                        isDragging = editing
                                    }
                                )
                                .focusable(false)
                                .frame(maxWidth: 150)

                                Text("\(AppState.shared.scrcpyBitrate) Mbps")
                                    .monospacedDigit()
                                    .foregroundColor(isDragging ? .accentColor : .secondary)
                                    .frame(width: 60, alignment: .leading)
                            }

                            HStack {
                                Text("Max size")
                                Spacer()

                                Slider(
                                    value: $tempResolution,
                                    in: 800...2600,
                                    step: 200,
                                    onEditingChanged: { editing in
                                        if !editing {
                                            AppState.shared.scrcpyResolution = Int(
                                                tempResolution
                                            )
                                        }
                                        isDragging = editing
                                    }
                                )
                                .focusable(false)
                                .frame(maxWidth: 150)

                                Text("\(AppState.shared.scrcpyResolution)")
                                    .monospacedDigit()
                                    .foregroundColor(isDragging ? .accentColor : .secondary)
                                    .frame(width: 60, alignment: .leading)
                            }

                            HStack {
                                Text("Stay on top")
                                Spacer()

                                Toggle("", isOn: $appState.scrcpyOnTop)
                                    .toggleStyle(.switch)
                            }


                            HStack {
                                Text("Desktop mode")
                                Spacer()

                                Picker("", selection: Binding(
                                    get: { appState.scrcpyDesktopMode },
                                    set: { appState.scrcpyDesktopMode = $0 }
                                )) {
                                    Text("2560x1440").tag("2560x1440")
                                    Text("2560x1600").tag("2560x1600")
                                    Text("2000x1800").tag("2000x1800")
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                        }
                    } label: {
                        Label("Mirroring Settings", systemImage: "gear")
                            .font(.subheadline)
                            .bold()
                    }
                    .onAppear {
                        tempBitrate = Double(AppState.shared.scrcpyBitrate)
                        tempResolution = Double(AppState.shared.scrcpyResolution)
                    }
                    .focusEffectDisabled()
                    .padding(.bottom, 7)


                    if let result = appState.adbConnectionResult {
                        VStack(alignment: .leading, spacing: 6) {
                            ExpandableLicenseSection(title: "ADB Console", content: "[" + (appState.lastADBCommand ?? "[]") + "] " + result)
                        }
                        .transition(.opacity)
                    }

                }
                .padding()
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

            HStack{
                Label("Sync notification dismissals", systemImage: "bell.badge")
                Spacer()
                Toggle("", isOn: $appState.dismissNotif)
                    .toggleStyle(.switch)
            }

        }
        .padding()
        .onAppear{

            adbPortString = String(appState.adbPort)
        }
    }
}
