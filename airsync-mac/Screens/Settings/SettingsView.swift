import SwiftUI
import Foundation

struct SettingsView: View {
    @ObservedObject var appState = AppState.shared
    @State private var showMirror: Bool = false

    @State private var deviceName: String = ""
    @State private var port: String = "6996"
    @State private var availableAdapters: [(name: String, address: String)] = []
    @State private var currentIPAddress: String = "N/A"
    
    @AppStorage("automaticallyChecksForUpdates") private var automaticallyChecksForUpdates: Bool = true
    @AppStorage("automaticallyDownloadsUpdates") private var automaticallyDownloadsUpdates: Bool = false
    @State private var showRemoteSheet = false


    var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 1. Device
                    VStack {
                        DeviceNameView(deviceName: $deviceName)
                    }
                    .padding()
                    .background(.background.opacity(0.3))
                    .cornerRadius(12.0)

                    // 2. Server
                    headerSection(title: "Server", icon: "server.rack")
                    VStack(spacing: 12) {
                        HStack {
                            Label("Network Adapter", systemImage: "rectangle.connected.to.line.below")
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
                        }
                        .onChange(of: appState.selectedNetworkAdapterName) { _, _ in
                            currentIPAddress = WebSocketServer.shared.getLocalIPAddress(adapterName: appState.selectedNetworkAdapterName) ?? "N/A"
                            WebSocketServer.shared.stop()
                            if let port = UInt16(port) {
                                WebSocketServer.shared.start(port: port)
                            } else {
                                WebSocketServer.shared.start()
                            }
                            appState.shouldRefreshQR = true
                        }

                        Divider()

                        // MARK: - Mirror Settings (Hidden)
                        // Commented out - Mirror settings moved to separate view
                        /*
                        // Mirror method picker directly under Network
                        HStack {
                            Label("Mirror method", systemImage: "display")
                            Spacer()
                            Picker("", selection: Binding(
                                get: { UserDefaults.standard.string(forKey: "connection.mode") ?? "remote" },
                                set: { UserDefaults.standard.set($0, forKey: "connection.mode") }
                            )) {
                                Text("Remote Connect").tag("remote")
                                Text("ADB Connect").tag("adb")
                            }
                            .pickerStyle(.segmented)
                            .frame(maxWidth: 260)
                        }

                        // Inline remote settings when Remote is chosen
                        if (UserDefaults.standard.string(forKey: "connection.mode") ?? "remote") == "remote" {
                            // Reuse MirrorSettingsView content without its own mode picker
                            MirrorSettingsView(showModePicker: false)
                                .padding(.top, 8)
                        }
                        */

                        ConnectionInfoText(
                            label: "IP Address",
                            icon: "wifi",
                            text: currentIPAddress,
                            activeIp: appState.activeMacIp
                        )

                        HStack {
                            Label("Server Port", systemImage: "rectangle.connected.to.line.below")
                                .padding(.trailing, 20)
                            Spacer()
                            TextField("Server Port", text: $port)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: port) { oldValue, newValue in
                                    port = newValue.filter { "0123456789".contains($0) }
                                }
                                .frame(maxWidth: 100)
                        }

                        HStack {
                            Label("Fallback to mdns services", systemImage: "antenna.radiowaves.left.and.right")
                            Spacer()
                            Toggle("", isOn: $appState.fallbackToMdns)
                                .toggleStyle(.switch)
                        }
                    }
                    .padding()
                    .background(.background.opacity(0.3))
                    .cornerRadius(12.0)

                    HStack {
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

                    // 2. Features
                    headerSection(title: "Features", icon: "square.grid.2x2")
                    SettingsFeaturesView()
                        .background(.background.opacity(0.3))
                        .cornerRadius(12.0)

                    Spacer(minLength: 32)
                    
                    // Bluetooth Pairing
                    BluetoothPairingView()

                    Spacer(minLength: 32)

                    VStack {
                        HStack {
                            Label("Remote Control Permission", systemImage: "accessibility")
                            Spacer()
                            GlassButtonView(label: "Configure", systemImage: "gearshape"){
                                showRemoteSheet = true
                            }
                        }
                    }
                    .padding()
                    .background(.background.opacity(0.3))
                    .cornerRadius(12.0)
                    .sheet(isPresented: $showRemoteSheet) {
                        RemotePermissionView()
                    }

                    VStack{
                        HStack{
                            Label("Show File Share Dialog", systemImage: "doc.on.doc")
                            Spacer()
                            Toggle("", isOn: $appState.showFileShareDialog)
                                .toggleStyle(.switch)
                        }
                    }
                    .padding()
                    .background(.background.opacity(0.3))
                    .cornerRadius(12.0)

                    // 3. Appearance
                    headerSection(title: "Appearance", icon: "paintbrush")
                    VStack(spacing: 12) {
                        HStack{
                            Label("Liquid Opacity", systemImage: "app.background.dotted")
                            Spacer()
                            Slider(
                                value: $appState.windowOpacity,
                                in: 0...1.0
                            )
                            .frame(width: 150)
                        }

                        HStack{
                            Label("Hide Dock Icon", systemImage: "dock.rectangle")
                            Spacer()
                            Toggle("", isOn: $appState.hideDockIcon)
                                .toggleStyle(.switch)
                        }

                        HStack{
                            Label("Dock Size", systemImage: "rectangle.dock")
                            Spacer()
                            Slider(
                                value: $appState.dockSize,
                                in: 32...64,
                                step: 4
                            )
                            .frame(width: 200)
                            
                            Text("\(Int(appState.dockSize))px")
                                .font(.caption)
                                .frame(width: 40, alignment: .trailing)
                        }

                        HStack{
                            Label("Always Open Window", systemImage: "macwindow")
                            Spacer()
                            Toggle("", isOn: $appState.alwaysOpenWindow)
                                .toggleStyle(.switch)
                        }
                    }
                    .padding()
                    .background(.background.opacity(0.3))
                    .cornerRadius(12.0)

                    // 4. Menu Bar
                    headerSection(title: "Menu Bar", icon: "menubar.arrow.up.rectangle")
                    VStack(spacing: 12) {
                        HStack{
                            Label("Show Menu Bar Text", systemImage: "text.alignleft")
                            Spacer()
                            Toggle("", isOn: $appState.showMenubarText)
                                .toggleStyle(.switch)
                        }

                        if appState.showMenubarText {
                            VStack(spacing: 12) {
                                
                                HStack {
                                    Label("Max Length", systemImage: "arrow.left.and.right")
                                    Spacer()
                                    Slider(
                                        value: Binding(
                                            get: { Double(appState.menubarTextMaxLength) },
                                            set: { appState.menubarTextMaxLength = Int($0) }
                                        ),
                                        in: 10...80,
                                        step: 5
                                    )
                                    .frame(width: 150)
                                    .controlSize(.small)
                                }

                                HStack{
                                    Label("Show Device Name", systemImage: "iphone.gen3")
                                    Spacer()
                                    Toggle("", isOn: $appState.showMenubarDeviceName)
                                        .toggleStyle(.switch)
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding()
                    .background(.background.opacity(0.3))
                    .cornerRadius(12.0)

                    // 5. Application
                    headerSection(title: "Application", icon: "app.badge")
                    VStack(spacing: 12) {
                        SettingsToggleView(name: "Check for updates automatically", icon: "sparkles", isOn: $automaticallyChecksForUpdates)
                        SettingsToggleView(name: "Download updates automatically", icon: "arrow.down.circle", isOn: $automaticallyDownloadsUpdates)
                    }
                    .padding()
                    .background(.background.opacity(0.3))
                    .cornerRadius(12.0)

                    // 6. AirSync+
                    headerSection(title: "AirSync+", icon: "plus.diamond.fill")
                    SettingsPlusView()
                        .padding()
                        .background(.background.opacity(0.3))
                        .cornerRadius(12.0)
                }
                .padding()
                .animation(.spring(), value: appState.showMenubarText)

                Spacer(minLength: 100 + (appState.dockSize - 48))

    var body: some View {
        Group {
            switch appState.selectedSettingsTab {
            case .myMac:
                MyMacSettingsView()
            case .sync:
                SyncSettingsView()
            case .notifications:
                NotificationsSettingsView()
            case .mirroring:
                MirroringSettingsView()
            case .quickShare:
                QuickShareSettingsView()
            case .menubar:
                MenubarSettingsView()
            case .appleIntelligence:
                AppleIntelligenceSettingsView()
            case .appearance:
                AppearanceSettingsView()
            case .airsyncPlus:
                AirSyncPlusSettingsView()
            }
        }
        .frame(minWidth: 300)
<<<<<<< HEAD
        .onReceive(Foundation.NotificationCenter.default.publisher(for: Foundation.Notification.Name.mirrorShouldOpen)) { _ in
            showMirror = true
        }
        .sheet(isPresented: $showMirror) {
            // Replace MirrorView() with your actual mirror rendering view if different
            MirrorView()
        }
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


    @ViewBuilder
    private func headerSection(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(Color.accentColor)
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 8)
=======
>>>>>>> ec134ad7bafb586dc3aa206bda9fcadc8c4ccd1e
    }
}

extension Foundation.Notification.Name {
    static let mirrorShouldOpen = Foundation.Notification.Name("MirrorShouldOpen")
}

extension WebSocketServer {
    /// Handles a mirror frame. If the format is 'h264', logs and skips. Otherwise logs the data for now.
    public func handleMirrorFrame(base64: String, format: String?) {
        // As soon as a frame is received, notify UI to present the mirror view
        DispatchQueue.main.async {
            Foundation.NotificationCenter.default.post(name: Foundation.Notification.Name.mirrorShouldOpen, object: nil)
        }

        let fmt = format?.lowercased()

        guard let data = Data(base64Encoded: base64) else {
            print("[websocket] mirrorFrame base64 decode failed, format=\(fmt ?? "unknown")")
            return
        }

        if fmt == "h264" || fmt == "video/avc" || fmt == "avc" {
            // Assume Annex B NAL stream. Feed to decoder.
            H264Decoder.shared.feedAnnexB(data)
            return
        }

        // For demonstration: just log that a frame was received with the given format
        print("[websocket] mirrorFrame received frame. format=\(fmt ?? "unknown"), bytes=\(data.count)")
        // In a full implementation, decode (e.g. jpeg/png) and display in the Mirror UI
    }
}
