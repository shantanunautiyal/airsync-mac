//
//  ScannerView.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-28.
//

import SwiftUI
import QRCode
internal import SwiftImageReadWrite
import CryptoKit

struct ScannerView: View {
    @ObservedObject var appState = AppState.shared
    @StateObject private var quickConnectManager = QuickConnectManager.shared
    @State private var qrImage: CGImage?
    @State private var copyStatus: String?
    @State private var hasValidIP: Bool = true
    @State private var showConfirmReset = false
    @State private var revealKey: Bool = false
    @State private var pairAsSecond: Bool = false

    private func statusInfo(for status: WebSocketStatus) -> (text: String, icon: String, color: Color) {
        switch status {
        case .stopped:
            return ("Stopped", "xmark.circle", .gray)
        case .starting:
            return ("Starting...", "clock", .orange)
        case .started:
            return ("Ready", "checkmark.circle", .green)
        case .failed(let error):
            return ("Failed: \(error)", "exclamationmark.triangle", .red)
        }
    }

    var body: some View {

        let info = statusInfo(for: appState.webSocketStatus)

        VStack {
            Spacer()

            if !hasValidIP {
                VStack {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 30))
                        .foregroundColor(.gray)
                        .padding()

                    Text("No local IP found")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .frame(width: 250, height: 250)
                .padding()
            } else if let qrImage = qrImage {
                HStack{
                    Text("Scan to connect")
                        .font(.title)
                        .padding()

                    if !UIStyle.pretendOlderOS, #available(macOS 26.0, *) {
                        Label {
                            Text(info.text)
                                .foregroundColor(info.color)
                        } icon: {
                            Image(systemName: info.icon)
                                .foregroundColor(info.color)
                        }
                        .padding(10)
                        .background(.clear)
                        .glassEffect(in: .rect(cornerRadius: 20))
                    } else {
                        Label {
                            Text(info.text)
                                .foregroundColor(info.color)
                        } icon: {
                            Image(systemName: info.icon)
                                .foregroundColor(info.color)
                        }
                        .padding(10)
                        .background(.thinMaterial, in: .rect(cornerRadius: 20))
                    }
                }
                HStack(spacing: 12) {
                    Button {
                        // Restart server and regenerate QR
                        let port = UInt16(appState.myDevice?.port ?? Int(Defaults.serverPort))
                        WebSocketServer.shared.stop()
                        WebSocketServer.shared.start(port: port)
                        generateQRAsync()
                    } label: {
                        Label("Rescan", systemImage: "qrcode.viewfinder")
                    }
                    .buttonStyle(.bordered)

                    Button(role: .destructive) {
                        // Rotate key, restart server, and regenerate QR
                        WebSocketServer.shared.resetSymmetricKey()
                        let port = UInt16(appState.myDevice?.port ?? Int(Defaults.serverPort))
                        WebSocketServer.shared.stop()
                        WebSocketServer.shared.start(port: port)
                        generateQRAsync()
                    } label: {
                        Label("Reset key & QR", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.bottom, 6)

                Toggle("Pair as second device", isOn: $pairAsSecond)
                    .toggleStyle(.switch)
                    .onChange(of: pairAsSecond) { _, _ in
                        generateQRAsync()
                    }
                    .padding(.bottom, 4)

                Image(decorative: qrImage, scale: 1.0)
                    .resizable()
                    .interpolation(.none)
                    .frame(width: 250, height: 250)
                    .accessibilityLabel("QR Code")
                    .shadow(radius: 20)
                    .padding()
                    .background(.black.opacity(0.6), in: .rect(cornerRadius: 30))
            } else {
                ProgressView("Generating QR…")
                    .frame(width: 100, height: 100)
            }

            // --- Copy Key Button ---
            if hasValidIP,
               let key = WebSocketServer.shared.getSymmetricKeyBase64(),
               !key.isEmpty {
                HStack {
                    GlassButtonView(
                        label: "Copy Key",
                        systemImage: "key",
                        action: {
                            copyToClipboard(key)
                        }
                    )

                    GlassButtonView(
                        label: "Re-generate key",
                        systemImage: "repeat.badge.xmark",
                        iconOnly: true,
                        action: {
                            showConfirmReset = true
                        }
                    )
                }
                .padding(.top, 8)

                // Confirmation popup
                .confirmationDialog(
                    "Are you sure you want to reset the key? You will have to re-auth all the devices.",
                    isPresented: $showConfirmReset
                ) {
                    Button("Reset key", role: .destructive) {
                        WebSocketServer.shared.resetSymmetricKey()
                        generateQRAsync()
                    }
                    Button("Cancel", role: .cancel) { }
                }

                if let status = copyStatus {
                    Text(status)
                        .font(.caption)
                        .foregroundColor(.green)
                        .transition(.opacity)
                }
            }

            // --- Manual Setup (Advanced) ---
            if hasValidIP {
                VStack(alignment: .leading, spacing: 8) {
                    DisclosureGroup {
                        let ip = WebSocketServer.shared.getLocalIPAddress(
                            adapterName: appState.selectedNetworkAdapterName
                        ) ?? "N/A"
                        let port: UInt16 = UInt16(appState.myDevice?.port ?? Int(Defaults.serverPort))
                        let name = appState.myDevice?.name ?? "My Mac"
                        let key = WebSocketServer.shared.getSymmetricKeyBase64() ?? ""
                        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
                        let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
                        let plus = AppState.shared.isPlus
                        let slotParam = pairAsSecond ? "&slot=2" : ""
                        let connectionString = "airsync://\(ip):\(port)?name=\(encodedName)&plus=\(plus)&key=\(encodedKey)\(slotParam)"

                        VStack(alignment: .leading, spacing: 10) {
                            // IP & Port
                            HStack {
                                Text("IP:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(ip)
                                    .font(.caption)
                                Spacer()
                                Button("Copy") { copyToClipboard(ip) }
                                    .buttonStyle(.bordered)
                                    .font(.caption)
                            }
                            HStack {
                                Text("Port:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(String(port))
                                    .font(.caption)
                                Spacer()
                                Button("Copy") { copyToClipboard(String(port)) }
                                    .buttonStyle(.bordered)
                                    .font(.caption)
                            }

                            // Name
                            HStack {
                                Text("Device name:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(name)
                                    .font(.caption)
                                Spacer()
                                Button("Copy") { copyToClipboard(name) }
                                    .buttonStyle(.bordered)
                                    .font(.caption)
                            }

                            // Encryption key (masked with Reveal)
                            HStack {
                                Text("Encryption key:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if revealKey {
                                    Text(key.isEmpty ? "—" : key)
                                        .font(.caption)
                                        .textSelection(.enabled)
                                } else {
                                    Text(key.isEmpty ? "—" : String(repeating: "•", count: max(4, min(24, key.count))))
                                        .font(.caption)
                                }
                                Spacer()
                                Button(revealKey ? "Hide" : "Reveal") { revealKey.toggle() }
                                    .buttonStyle(.bordered)
                                    .font(.caption)
                                Button("Copy") { copyToClipboard(key) }
                                    .buttonStyle(.bordered)
                                    .font(.caption)
                                    .disabled(key.isEmpty)
                            }

                            // Full connection string
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Connection string:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(connectionString)
                                    .font(.caption2)
                                    .textSelection(.enabled)
                                    .lineLimit(3)
                                    .multilineTextAlignment(.leading)
                                HStack {
                                    Spacer()
                                    Button("Copy Connection") { copyToClipboard(connectionString) }
                                        .buttonStyle(.bordered)
                                        .font(.caption)
                                }
                            }

                            Text("If scanning the QR fails on your second device, open AirSync on Android and choose manual add/pair, then paste the connection string or enter IP, Port and Encryption key above.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(10)
                        .background(.thinMaterial, in: .rect(cornerRadius: 12))
                    } label: {
                        Label("Manual setup (advanced)", systemImage: "wrench.and.screwdriver")
                            .font(.subheadline)
                            .bold()
                    }
                }
                .frame(maxWidth: 720)
                .padding(.top, 8)
            }

            // --- Quick Connect Button ---
            if let lastDevice = quickConnectManager.getLastConnectedDevice() {
                VStack(spacing: 8) {
                    Text("Last connected device:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(lastDevice.name)
                                .font(.system(size: 14, weight: .medium))
                            Text("\(lastDevice.ipAddress)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.trailing, 16)

                        GlassButtonView(
                            label: "Reconnect",
                            systemImage: "bolt.circle",
                            action: {
                                quickConnectManager.wakeUpLastConnectedDevice()
                            }
                        )

                        GlassButtonView(
                            label: "Clear",
                            systemImage: "xmark.circle",
                            iconOnly: true,
                            action: {
                                quickConnectManager.clearLastConnectedDevice()
                            }
                        )
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.thinMaterial, in: .rect(cornerRadius: 16))
                }
                .padding(.top, 12)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .onAppear {
            generateQRAsync()
        }
        .onTapGesture {
            generateQRAsync()
        }
        .onChange(of: appState.shouldRefreshQR) { _, newValue in
            if newValue {
                generateQRAsync()
                appState.shouldRefreshQR = false
            }
        }
        .onChange(of: appState.selectedNetworkAdapterName) { _, _ in
            // Network adapter changed, regenerate QR with new IP
            generateQRAsync()
            // Refresh device info for new network
            quickConnectManager.refreshDeviceForCurrentNetwork()
        }
        .onChange(of: appState.myDevice?.port) { _, _ in
            // Port changed, regenerate QR
            generateQRAsync()
        }
        .onChange(of: appState.myDevice?.name) { _, _ in
            // Device name changed, regenerate QR
            generateQRAsync()
        }

    }

     func generateQRAsync() {
        // Ensure server is running before generating QR
        switch appState.webSocketStatus {
        case .started:
            break
        default:
            let port = UInt16(appState.myDevice?.port ?? Int(Defaults.serverPort))
            WebSocketServer.shared.stop()
            WebSocketServer.shared.start(port: port)
        }

        let ip = WebSocketServer.shared
            .getLocalIPAddress(
                adapterName: appState.selectedNetworkAdapterName
            )

        // Check if we have a valid IP address
        guard let validIP = ip else {
            DispatchQueue.main.async {
                self.hasValidIP = false
                self.qrImage = nil
            }
            return
        }

        // If we have a valid IP, proceed with QR generation
        DispatchQueue.main.async {
            self.hasValidIP = true
            self.qrImage = nil // Reset to show progress view
        }

        let text = generateQRText(
            ip: validIP,
            port: UInt16(appState.myDevice?.port ?? Int(Defaults.serverPort)),
            name: appState.myDevice?.name,
            key: WebSocketServer.shared.getSymmetricKeyBase64() ?? "",
            slot: pairAsSecond ? 2 : nil
        ) ?? "That doesn't look right, QR Generation failed"

        Task {
            if let cgImage = await QRCodeGenerator.generateQRCode(for: text) {
                DispatchQueue.main.async {
                    self.qrImage = cgImage
                }
            }
        }
    }


    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        withAnimation {
            copyStatus = "Copied! Keep it safe"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                copyStatus = nil
            }
        }
    }
}

func generateQRText(ip: String?, port: UInt16?, name: String?, key: String, slot: Int? = nil) -> String? {
    guard let ip = ip, let port = port else { return nil }

    let encodedName = (name ?? "My Mac").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "My Mac"
    let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
    let plus = AppState.shared.isPlus
    let slotQuery = slot != nil ? "&slot=\(slot!)" : ""

    // Use '&' between query parameters; keep custom scheme
    return "airsync://\(ip):\(port)?name=\(encodedName)&plus=\(plus)&key=\(encodedKey)\(slotQuery)"
}



#Preview {
    ScannerView()
}

