import SwiftUI

import SwiftUI

typealias NetworkAdapter = (name: String, address: String)

struct SettingsView: View {
    @ObservedObject var appState = AppState.shared
    @State private var availableAdapters: [NetworkAdapter] = []
    @State private var currentIPAddress: String = "N/A"
    @State private var port: String = ""
    
    private var deviceName: String {
        appState.device?.name ?? "Unknown Device"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Info Section
                VStack {
                    HStack {
                        Label(L("settings.general.network"), systemImage: "rectangle.connected.to.line.below")
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
                        currentIPAddress = WebSocketServer.shared.getLocalIPAddress(adapterName: appState.selectedNetworkAdapterName) ?? "N/A"
                        port = String(appState.port)
                    }
                    .onChange(of: appState.selectedNetworkAdapterName) { _, _ in
                        // Update IP address immediately
                        currentIPAddress = WebSocketServer.shared.getLocalIPAddress(adapterName: appState.selectedNetworkAdapterName) ?? "N/A"
                        
                        WebSocketServer.shared.stop()
                        if let port = UInt16(port) {
                            WebSocketServer.shared.start(port: port)
                        } else {
                            WebSocketServer.shared.start()
                        }
                        // Refresh QR code since IP address may have changed
                        appState.shouldRefreshQR = true
                    }

                    ConnectionInfoText(
                        label: "IP Address",
                        icon: "wifi",
                        text: currentIPAddress
                    )

                    HStack {
                        Label(L("settings.general.serverPort"), systemImage: "rectangle.connected.to.line.below")
                            .padding(.trailing, 20)
                        Spacer()
                        TextField("Server Port", text: $port)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: port) { oldValue, newValue in
                                port = newValue.filter { "0123456789".contains($0) }
                            }
                            .frame(maxWidth: 100)
                    }
                }
                .padding()
                .background(.background.opacity(0.3))
                .cornerRadius(12.0)

                HStack{
                    Spacer()

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

                Spacer(minLength: 32)

                // Mirroring Settings
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Mirroring", systemImage: "rectangle.on.rectangle")
                        Spacer()
                        Toggle("Desktop mode", isOn: $appState.mirrorDesktopMode)
                            .toggleStyle(.switch)
                            .help("When on, follow the stream aspect ratio (desktop). When off, force 9:16 portrait window.")
                    }

                    HStack {
                        Label("Force 9:16 portrait", systemImage: "rectangle.portrait")
                        Spacer()
                        Toggle("", isOn: $appState.mirrorForcePortrait916)
                            .toggleStyle(.switch)
                            .disabled(appState.mirrorDesktopMode)
                            .help("When Desktop mode is off, keep the mirroring window locked to 9:16.")
                    }

                    HStack {
                        Label("Resolution", systemImage: "rectangle.compress.vertical")
                        Spacer()
                        Picker("", selection: $appState.mirrorResolution) {
                            Text("720x1280").tag("720x1280")
                            Text("1080x1920").tag("1080x1920")
                            Text("1440x2560").tag("1440x2560")
                            Text("2160x3840").tag("2160x3840")
                            Text("Auto").tag("")
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(maxWidth: 160)
                        .disabled(appState.mirrorDesktopMode)
                        .help("Preferred portrait resolution hint sent to Android. Use Auto to let device decide.")
                    }

                    HStack {
                        Label("Bitrate (Mbps)", systemImage: "speedometer")
                        Spacer()
                        Stepper(value: $appState.mirrorBitrateMbps, in: 2...30) {
                            Text("\(appState.mirrorBitrateMbps)")
                        }
                        .frame(maxWidth: 160)
                        .help("Target streaming bitrate. Actual value may be adjusted by the device.")
                    }
                    
                    HStack {
                        Label("Fill window (no black bars)", systemImage: "rectangle.expand.vertical")
                        Spacer()
                        Toggle("", isOn: $appState.mirrorScaleFill)
                            .toggleStyle(.switch)
                            .help("When on, the mirroring view fills the window and may crop the stream slightly to remove black bars.")
                    }

                    HStack {
                        Button {
                            let resHint = appState.mirrorDesktopMode ? nil : (appState.mirrorResolution.isEmpty ? nil : appState.mirrorResolution)
                            AppState.shared.requestStartMirroring(
                                mode: appState.mirrorDesktopMode ? "desktop" : "device",
                                resolution: resHint,
                                bitrateMbps: appState.mirrorBitrateMbps
                            )
                        } label: {
                            Label("Start Mirroring", systemImage: "play.rectangle")
                        }

                        Button(role: .cancel) {
                            AppState.shared.sendStopMirrorRequest()
                        } label: {
                            Label("Stop", systemImage: "stop")
                        }

                        Spacer()

                        Button {
                            AppState.shared.requestRemoteConnect(hint: "webrtc")
                        } label: {
                            Label("Remote Connect", systemImage: "antenna.radiowaves.left.and.right")
                        }
                        .help("Start remote connect handshake (Android will prompt).")
                    }
                }
                .padding()
                .background(.background.opacity(0.3))
                .cornerRadius(12.0)

                Spacer(minLength: 32)

                SettingsFeaturesView()
                    .background(.background.opacity(0.3))
                    .cornerRadius(12.0)

                Spacer(minLength: 32)

                // App icons
                AppIconView()

                // UI Tweaks Section
                VStack {

                    HStack{
                        Label(L("settings.general.liquidOpacity"), systemImage: "app.background.dotted")
                        Spacer()
                        Slider(
                            value: $appState.windowOpacity,
                            in: 0...1.0
                        )
                        .frame(width: 200)
                    }

                    HStack{
                        Label(L("settings.general.toolbarContrast"), systemImage: "uiwindow.split.2x1")
                        Spacer()
                        Toggle("", isOn: $appState.toolbarContrast)
                            .toggleStyle(.switch)
                    }

                    HStack{
                        Label(L("settings.general.hideDockIcon"), systemImage: "dock.rectangle")
                        Spacer()
                        Toggle("", isOn: $appState.hideDockIcon)
                            .toggleStyle(.switch)
                    }

                    HStack{
                        Label(L("settings.general.alwaysOpenWindow"), systemImage: "macwindow")
                        Spacer()
                        Toggle("", isOn: $appState.alwaysOpenWindow)
                            .toggleStyle(.switch)
                    }

                    HStack{
                        Label(L("settings.general.menubarText"), systemImage: "menubar.arrow.up.rectangle")
                        Spacer()
                        Toggle("", isOn: $appState.showMenubarText)
                            .toggleStyle(.switch)
                    }

                    if appState.showMenubarText {
                        HStack {
                            Label(L("settings.general.menubarTextLength"), systemImage: "textformat.123")
                            Spacer()
                            Slider(
                                value: Binding(
                                    get: { Double(appState.menubarTextMaxLength) },
                                    set: { appState.menubarTextMaxLength = Int($0) }
                                ),
                                in: 10...80,
                                step: 5
                            )
                            .frame(maxWidth: 200)
                            .controlSize(.small)
                        }
                    }
                }
                .padding()
                .background(.background.opacity(0.3))
                .cornerRadius(12.0)
            }
            .padding()
        }
    }
}

