import SwiftUI
import Foundation

struct SettingsView: View {
    @ObservedObject var appState = AppState.shared
    @State private var showMirror: Bool = false
    @State private var deviceName: String = ""
    @State private var port: String = "6996"

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
        .onReceive(Foundation.NotificationCenter.default.publisher(for: Foundation.Notification.Name.mirrorShouldOpen)) { _ in
            showMirror = true
        }
        .sheet(isPresented: $showMirror) {
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
}

extension Foundation.Notification.Name {
    static let mirrorShouldOpen = Foundation.Notification.Name("MirrorShouldOpen")
}

extension WebSocketServer {
    public func handleMirrorFrame(base64: String, format: String?) {
        DispatchQueue.main.async {
            Foundation.NotificationCenter.default.post(name: Foundation.Notification.Name.mirrorShouldOpen, object: nil)
        }

        let fmt = format?.lowercased()

        guard let data = Data(base64Encoded: base64) else {
            print("[websocket] mirrorFrame base64 decode failed, format=\(fmt ?? "unknown")")
            return
        }

        if fmt == "h264" || fmt == "video/avc" || fmt == "avc" {
            H264Decoder.shared.feedAnnexB(data)
            return
        }

        print("[websocket] mirrorFrame received frame. format=\(fmt ?? "unknown"), bytes=\(data.count)")
    }
}
