//
//  AppState.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-29.
//
import SwiftUI
import Foundation
internal import Combine
import UserNotifications

class AppState: ObservableObject {
    static let shared = AppState()

    private var clipboardCancellable: AnyCancellable?
    private var lastClipboardValue: String? = nil
    private var shouldSkipSave = false
    private let licenseDetailsKey = "licenseDetails"


    init() {
        self.isPlus = UserDefaults.standard.bool(forKey: "isPlus")


        // Load from UserDefaults
        let name = UserDefaults.standard.string(forKey: "deviceName") ?? (Host.current().localizedName ?? "My Mac")
        let portString = UserDefaults.standard.string(forKey: "devicePort") ?? String(Defaults.serverPort)
        let port = Int(portString) ?? Int(Defaults.serverPort)
        let adbPortValue = UserDefaults.standard.integer(forKey: "adbPort")
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.0.0"

        self.adbPort = adbPortValue == 0 ? 5555 : UInt16(adbPortValue)
        self.mirroringPlus = UserDefaults.standard.bool(forKey: "mirroringPlus")
        self.adbEnabled = UserDefaults.standard.bool(forKey: "adbEnabled")

        self.isClipboardSyncEnabled = UserDefaults.standard.bool(forKey: "isClipboardSyncEnabled")
        self.windowOpacity = UserDefaults.standard
            .double(forKey: "windowOpacity")
        if isClipboardSyncEnabled {
            startClipboardMonitoring()
        }

        self.scrcpyBitrate = UserDefaults.standard.integer(forKey: "scrcpyBitrate")
        if self.scrcpyBitrate == 0 { self.scrcpyBitrate = 4 }

        self.scrcpyResolution = UserDefaults.standard.integer(forKey: "scrcpyResolution")
        if self.scrcpyResolution == 0 { self.scrcpyResolution = 1200 }

        self.scrcpyOnTop = UserDefaults.standard.bool(forKey: "scrcpyOnTop")
        self.scrcpyDesktopMode = UserDefaults.standard.string(forKey: "scrcpyDesktopMode") ?? "2560x1440"
        self.lastADBCommand = UserDefaults.standard.string(forKey: "lastADBCommand")



        self.myDevice = Device(
            name: name,
            ipAddress: getLocalIPAddress() ?? "N/A",
            port: port,
            version:appVersion
        )
        self.licenseDetails = loadLicenseDetailsFromUserDefaults()

        loadAppsFromDisk()

        postNativeNotification(id: "test_notification", appName: "AirSync Beta", title: "Hi there! (っ◕‿◕)っ", body: "Welcome to and thanks for testing out the app. Please don't forget to report issues to sameerasw.com@gmail.com or any other community you prefer. <3", appIcon: nil)
    }

    @Published var minAndroidVersion = Bundle.main.infoDictionary?["AndroidVersion"] as? String ?? "2.0.0"

    @Published var device: Device? = nil
    @Published var notifications: [Notification] = []
    @Published var status: DeviceStatus? = nil
    @Published var myDevice: Device? = nil
    @Published var port: UInt16 = Defaults.serverPort

    @Published var appIcons: [String: String] = [:] // packageName: base64Icon
    @Published var androidApps: [String: AndroidApp] = [:]

    @Published var deviceWallpapers: [String: String] = [:] // key = deviceName-ip, value = file path
    @Published var isClipboardSyncEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isClipboardSyncEnabled, forKey: "isClipboardSyncEnabled")
            if isClipboardSyncEnabled {
                startClipboardMonitoring()
            } else {
                stopClipboardMonitoring()
            }
        }
    }
    @Published var shouldRefreshQR: Bool = false
    @Published var webSocketStatus: WebSocketStatus = .stopped
    @Published var selectedTab: TabIdentifier = .settings

    @Published var adbConnected: Bool = false
    @Published var currentDeviceWallpaperBase64: String? = nil
    @Published var selectedNetworkAdapterName: String? // e.g., "en0"

    @Published var scrcpyBitrate: Int = 4 {
        didSet {
            UserDefaults.standard.set(scrcpyBitrate, forKey: "scrcpyBitrate")
        }
    }

    @Published var scrcpyResolution: Int = 1200 {
        didSet {
            UserDefaults.standard.set(scrcpyResolution, forKey: "scrcpyResolution")
        }
    }

    @Published var scrcpyOnTop: Bool = false {
        didSet {
            UserDefaults.standard.set(scrcpyOnTop, forKey: "scrcpyOnTop")
        }
    }

    @Published var scrcpyDesktopMode: String = "2560x1440" {
        didSet {
            UserDefaults.standard.set(scrcpyDesktopMode, forKey: "scrcpyDesktopMode")
        }
    }

    @Published var lastADBCommand: String? {
        didSet {
            UserDefaults.standard.set(lastADBCommand, forKey: "lastADBCommand")
        }
    }





    @Published var licenseDetails: LicenseDetails? {
        didSet {
            saveLicenseDetailsToUserDefaults()
        }
    }

    @Published var adbPort: UInt16 {
        didSet {
            UserDefaults.standard.set(adbPort, forKey: "adbPort")
        }
    }
    @Published var adbConnectionResult: String? = nil

    @Published var mirroringPlus: Bool {
        didSet {
            UserDefaults.standard.set(mirroringPlus, forKey: "mirroringPlus")
        }
    }

    @Published var adbEnabled: Bool {
        didSet {
            UserDefaults.standard.set(adbEnabled, forKey: "adbEnabled")
        }
    }

    @Published var windowOpacity: Double {
        didSet {
            UserDefaults.standard.set(windowOpacity, forKey: "windowOpacity")
        }
    }

    // Toggle licensing
    let licenseCheck: Bool = true

    @Published var isPlus: Bool {
        didSet {
            if !shouldSkipSave {
                UserDefaults.standard.set(isPlus, forKey: "isPlus")
            }
        }
    }

    func setPlusTemporarily(_ value: Bool) {
        shouldSkipSave = true
        isPlus = value
        shouldSkipSave = false
    }


    // Remove notification by model instance and system notif center
    func removeNotification(_ notif: Notification) {
        DispatchQueue.main.async {
            withAnimation {
                self.notifications.removeAll { $0.id == notif.id }
            }
            WebSocketServer.shared.dismissNotification(id: notif.nid)
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [notif.nid])
        }
    }

    func removeNotificationById(_ nid: String) {
        DispatchQueue.main.async {
            withAnimation {
                self.notifications.removeAll { $0.nid == nid }
            }
            WebSocketServer.shared.dismissNotification(id: nid)
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [nid])
        }
    }


    func hideNotification(_ notif: Notification) {
        DispatchQueue.main.async {
            withAnimation {
                self.notifications.removeAll { $0.id == notif.id }
            }
            self.removeNotification(notif)
        }
    }

    func clearNotifications() {
        DispatchQueue.main.async {
            if !self.notifications.isEmpty {
                withAnimation {
                    self.notifications.removeAll()
                }
            }
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        }
    }

    func disconnectDevice() {
        DispatchQueue.main.async {
            // Send request to remote device to disconnect
            WebSocketServer.shared.sendDisconnectRequest()

            // Then locally reset state
            self.device = nil
            self.notifications.removeAll()
            self.status = nil
        }
    }

    func addNotification(_ notif: Notification) {
        DispatchQueue.main.async {
            withAnimation {
                self.notifications.insert(notif, at: 0)
            }
            // Trigger native macOS notification
            var appIcon: NSImage? = nil
            if let iconPath = self.appIcons[notif.package] {
                appIcon = NSImage(contentsOfFile: iconPath)
            }
            self.postNativeNotification(
                id: notif.nid,
                appName: notif.app,
                title: notif.title,
                body: notif.body,
                appIcon: appIcon,
                package: notif.package
            )
        }
    }

    func postNativeNotification(
        id: String,
        appName: String,
        title: String,
        body: String,
        appIcon: NSImage? = nil,
        package: String? = nil
    ) {
        let content = UNMutableNotificationContent()
        content.title = "\(appName) - \(title)"
        content.body = body
        content.sound = .default

        if let pkg = package, pkg != "com.sameerasw.airsync", adbConnected, mirroringPlus {
            content.categoryIdentifier = "DEFAULT_CATEGORY"
            content.userInfo["package"] = pkg
        }

        // Attach app icon if available
        if let icon = appIcon {
            if let iconFileURL = saveIconToTemporaryFile(icon: icon) {
                do {
                    let attachment = try UNNotificationAttachment(identifier: "appIcon", url: iconFileURL, options: nil)
                    content.attachments = [attachment]
                } catch {
                    print("Failed to attach app icon to notification: \(error)")
                }
            }
        }

        let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to post native notification: \(error)")
            }
        }
    }


    private func saveIconToTemporaryFile(icon: NSImage) -> URL? {
        // Save NSImage as a temporary PNG file to attach in notification
        guard let tiffData = icon.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }

        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
        let tempFile = tempDir.appendingPathComponent("notification_icon_\(UUID().uuidString).png")

        do {
            try pngData.write(to: tempFile)
            return tempFile
        } catch {
            print("Error saving icon to temp file: \(error)")
            return nil
        }
    }

    func syncWithSystemNotifications() {
        UNUserNotificationCenter.current().getDeliveredNotifications { systemNotifs in
            let systemNIDs = Set(systemNotifs.map { $0.request.identifier })

            DispatchQueue.main.async {
                let currentNIDs = Set(self.notifications.map { $0.nid })
                let removedNIDs = currentNIDs.subtracting(systemNIDs)

                for nid in removedNIDs {
                    print("System notification \(nid) was dismissed manually.")
                    self.removeNotificationById(nid)
                }
            }
        }
    }

    private func startClipboardMonitoring() {
        guard isClipboardSyncEnabled else { return }
        clipboardCancellable = Timer
            .publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                let pasteboard = NSPasteboard.general
                if let copiedString = pasteboard.string(forType: .string),
                   copiedString != self.lastClipboardValue {
                    self.lastClipboardValue = copiedString
                    self.sendClipboardToAndroid(text: copiedString)
                    print("Clipboard updated :" + copiedString)
                }
            }
    }

    func sendClipboardToAndroid(text: String) {
        let message = """
    {
        "type": "clipboardUpdate",
        "data": {
            "text": "\(text.replacingOccurrences(of: "\"", with: "\\\""))"
        }
    }
    """
        WebSocketServer.shared.sendClipboardUpdate(message)
    }

    func updateClipboardFromAndroid(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        self.lastClipboardValue = text
        self.postNativeNotification(id: "clipboard", appName: "Clipboard", title: "Updated", body: text)
    }

    private func stopClipboardMonitoring() {
        clipboardCancellable?.cancel()
        clipboardCancellable = nil
    }


    func wallpaperCacheDirectory() -> URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("wallpapers", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    var currentWallpaperPath: String? {
        guard let device = myDevice else { return nil }
        let key = "\(device.name)-\(device.ipAddress)"
        return deviceWallpapers[key]
    }

    private func saveLicenseDetailsToUserDefaults() {
        guard let details = licenseDetails else {
            UserDefaults.standard.removeObject(forKey: licenseDetailsKey)
            return
        }

        do {
            let data = try JSONEncoder().encode(details)
            UserDefaults.standard.set(data, forKey: licenseDetailsKey)
        } catch {
            print("Failed to encode license details: \(error)")
        }
    }

    private func loadLicenseDetailsFromUserDefaults() -> LicenseDetails? {
        guard let data = UserDefaults.standard.data(forKey: licenseDetailsKey) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(LicenseDetails.self, from: data)
        } catch {
            print("Failed to decode license details: \(error)")
            return nil
        }
    }

    func saveAppsToDisk() {
        let url = appIconsDirectory().appendingPathComponent("apps.json")
        do {
            let data = try JSONEncoder().encode(Array(AppState.shared.androidApps.values))
            try data.write(to: url)
        } catch {
            print("Error saving apps: \(error)")
        }
    }

    func loadAppsFromDisk() {
        let url = appIconsDirectory().appendingPathComponent("apps.json")
        do {
            let data = try Data(contentsOf: url)
            let apps = try JSONDecoder().decode([AndroidApp].self, from: data)
            DispatchQueue.main.async {
                for app in apps {
                    AppState.shared.androidApps[app.packageName] = app
                    if let iconPath = app.iconUrl {
                        AppState.shared.appIcons[app.packageName] = iconPath
                    }
                }
            }
        } catch {
            print("Error loading apps: \(error)")
        }
    }




}
