
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
