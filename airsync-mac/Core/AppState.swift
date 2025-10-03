//
//  AppState.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-29.
//
import SwiftUI
import Foundation
import Cocoa
internal import Combine
import UserNotifications

class AppState: ObservableObject {
    static let shared = AppState()

    private var clipboardCancellable: AnyCancellable?
    private var lastClipboardValue: String? = nil
    private var shouldSkipSave = false
    private let licenseDetailsKey = "licenseDetails"

    @Published var isOS26: Bool = true

    init() {
        // Force-enable Plus for personal builds and persist
        self.isPlus = true
        UserDefaults.standard.set(true, forKey: "isPlus")

        // Load from UserDefaults
        let name = UserDefaults.standard.string(forKey: "deviceName") ?? (Host.current().localizedName ?? "My Mac")
        let portString = UserDefaults.standard.string(forKey: "devicePort") ?? String(Defaults.serverPort)
        let port = Int(portString) ?? Int(Defaults.serverPort)
        let adbPortValue = UserDefaults.standard.integer(forKey: "adbPort")
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.0.0"

        self.adbPort = adbPortValue == 0 ? 5555 : UInt16(adbPortValue)
        self.mirroringPlus = UserDefaults.standard.bool(forKey: "mirroringPlus")
        self.adbEnabled = UserDefaults.standard.bool(forKey: "adbEnabled")
        self.showMenubarText = UserDefaults.standard.bool(forKey: "showMenubarText")

        // Default to true if not previously set
        let showNameObj = UserDefaults.standard.object(forKey: "showMenubarDeviceName")
        self.showMenubarDeviceName = showNameObj == nil
            ? true
            : UserDefaults.standard.bool(forKey: "showMenubarDeviceName")

        let savedMaxLength = UserDefaults.standard.integer(forKey: "menubarTextMaxLength")
        self.menubarTextMaxLength = savedMaxLength > 0 ? savedMaxLength : 30

        self.isClipboardSyncEnabled = UserDefaults.standard.bool(forKey: "isClipboardSyncEnabled")
        self.windowOpacity = UserDefaults.standard
            .double(forKey: "windowOpacity")
        self.toolbarContrast = UserDefaults.standard
            .bool(forKey: "toolbarContrast")
        self.hideDockIcon = UserDefaults.standard
            .bool(forKey: "hideDockIcon")
        self.alwaysOpenWindow = UserDefaults.standard
            .bool(forKey: "alwaysOpenWindow")
        self.notificationSound = UserDefaults.standard
            .string(forKey: "notificationSound") ?? "default"
        self.dismissNotif = UserDefaults.standard
            .bool(forKey: "dismissNotif")
        
        // Default to true for backward compatibility - existing behavior should continue
        let savedNowPlayingStatus = UserDefaults.standard.object(forKey: "sendNowPlayingStatus")
        self.sendNowPlayingStatus = savedNowPlayingStatus == nil ? true : UserDefaults.standard.bool(forKey: "sendNowPlayingStatus")
        
        self.isBluetoothEnabled = UserDefaults.standard.bool(forKey: "isBluetoothEnabled")
        // Activate Bluetooth manager if it was enabled on last run
        if self.isBluetoothEnabled {
            BluetoothManager.shared.enable(true)
        }

        if isClipboardSyncEnabled {
            startClipboardMonitoring()
        }

        if licenseCheck {
            Task {
                await Gumroad().checkLicenseIfNeeded()
            }
        }

        self.scrcpyBitrate = UserDefaults.standard.integer(forKey: "scrcpyBitrate")
        if self.scrcpyBitrate == 0 { self.scrcpyBitrate = 4 }

        self.scrcpyResolution = UserDefaults.standard.integer(forKey: "scrcpyResolution")
        if self.scrcpyResolution == 0 { self.scrcpyResolution = 1200 }

    // Initialize persisted UI toggles
    self.isMusicCardHidden = UserDefaults.standard.bool(forKey: "isMusicCardHidden")

        // Load and validate saved network adapter
        let savedAdapterName = UserDefaults.standard.string(forKey: "selectedNetworkAdapterName")
        self.selectedNetworkAdapterName = validateAndGetNetworkAdapter(savedName: savedAdapterName)

        self.myDevice = Device(
            name: name,
            ipAddress: WebSocketServer.shared
                .getLocalIPAddress(
                    adapterName: selectedNetworkAdapterName
                ) ?? "N/A",
            port: port,
            version:appVersion
        )
        self.licenseDetails = loadLicenseDetailsFromUserDefaults()

        loadAppsFromDisk()
        // QuickConnectManager handles its own initialization

//        postNativeNotification(id: "test_notification", appName: "AirSync Beta", title: "Hi there! (っ◕‿◕)っ", body: "Welcome to and thanks for testing out the app. Please don't forget to report issues to sameerasw.com@gmail.com or any other community you prefer. <3", appIcon: nil)
        
        // Attempt auto-reconnect to last device shortly after launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if let _ = QuickConnectManager.shared.getLastConnectedDevice() {
                print("[state] Auto-reconnect: attempting wake-up of last connected device")
                QuickConnectManager.shared.wakeUpLastConnectedDevice()
            } else {
                print("[state] Auto-reconnect: no previous device found for current network")
            }
        }

        self.registerMirrorApprovalHandler()
    }

    @Published var minAndroidVersion = Bundle.main.infoDictionary?["AndroidVersion"] as? String ?? "2.0.0"

    @Published var device: Device? = nil {
        didSet {
            // Store the last connected device when a new device connects
            if let newDevice = device {
                QuickConnectManager.shared.saveLastConnectedDevice(newDevice)
            }
        }
    }
    @Published var notifications: [Notification] = []
    @Published var status: DeviceStatus? = nil
    @Published var myDevice: Device? = nil
    // Tracks if a low battery notification has been sent for the current device session
    @Published var lowBatteryNotifSent: Bool = false

    @Published var port: UInt16 = Defaults.serverPort
    @Published var androidApps: [String: AndroidApp] = [:]

    // SMS conversations received from the connected device
    @Published var smsConversations: [SmsConversation] = []
    // Phone call logs received from the connected device
    @Published var callLogs: [CallLogEntry] = []

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

    @Published var adbConnected: Bool = false
    @Published var adbConnecting: Bool = false
    @Published var currentDeviceWallpaperBase64: String? = nil
    @Published var selectedNetworkAdapterName: String? { // e.g., "en0"
        didSet {
            UserDefaults.standard.set(selectedNetworkAdapterName, forKey: "selectedNetworkAdapterName")
        }
    }
    @Published var showMenubarText: Bool {
        didSet {
            UserDefaults.standard.set(showMenubarText, forKey: "showMenubarText")
        }
    }

    @Published var showMenubarDeviceName: Bool {
        didSet {
            UserDefaults.standard.set(showMenubarDeviceName, forKey: "showMenubarDeviceName")
        }
    }

    @Published var menubarTextMaxLength: Int {
        didSet {
            UserDefaults.standard.set(menubarTextMaxLength, forKey: "menubarTextMaxLength")
        }
    }

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

    @Published var toolbarContrast: Bool {
        didSet {
            UserDefaults.standard.set(toolbarContrast, forKey: "toolbarContrast")
        }
    }

    @Published var hideDockIcon: Bool {
        didSet {
            UserDefaults.standard.set(hideDockIcon, forKey: "hideDockIcon")
            updateDockIconVisibility()
        }
    }

    @Published var alwaysOpenWindow: Bool {
        didSet {
            UserDefaults.standard.set(alwaysOpenWindow, forKey: "alwaysOpenWindow")
        }
    }

    @Published var notificationSound: String {
        didSet {
            UserDefaults.standard.set(notificationSound, forKey: "notificationSound")
        }
    }

    @Published var dismissNotif: Bool {
        didSet {
            UserDefaults.standard.set(dismissNotif, forKey: "dismissNotif")
        }
    }

    @Published var sendNowPlayingStatus: Bool {
        didSet {
            UserDefaults.standard.set(sendNowPlayingStatus, forKey: "sendNowPlayingStatus")
        }
    }

    @Published var isBluetoothEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isBluetoothEnabled, forKey: "isBluetoothEnabled")
            // Enable or disable the Bluetooth manager based on the toggle
            BluetoothManager.shared.enable(isBluetoothEnabled)
        }
    }

    // Whether the media player card is hidden on the PhoneView
    @Published var isMusicCardHidden: Bool = false {
        didSet {
            UserDefaults.standard.set(isMusicCardHidden, forKey: "isMusicCardHidden")
        }
    }

    @Published var isOnboardingActive: Bool = false {
        didSet {
            NotificationCenter.default.post(
                name: NSNotification.Name("OnboardingStateChanged"),
                object: nil,
                userInfo: ["isActive": isOnboardingActive]
            )
        }
    }

    @Published var selectedTab: Tab = .qr

    // Renamed from AppTab to avoid conflicts and centralize logic
    enum Tab: String, CaseIterable, Identifiable {
        case notifications = "notifications.tab"
        case apps = "apps.tab"
        case transfers = "transfers.tab"
        case sms = "sms.tab"
        case calls = "calls.tab"
        case health = "health.tab"
        case settings = "settings.tab"
        case qr = "qr.tab"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .notifications: return "bell.badge.fill"
            case .apps: return "square.grid.2x2.fill"
            case .transfers: return "arrow.up.doc.fill"
            case .sms: return "message.fill"
            case .calls: return "phone.fill"
            case .health: return "heart.fill"
            case .settings: return "gearshape.fill"
            case .qr: return "qrcode.viewfinder"
            }
        }

        var shortcut: KeyEquivalent {
            switch self {
            case .notifications: return "1"
            case .apps: return "2"
            case .transfers: return "3"
            case .sms: return "4"
            case .calls: return "6"
            case .health: return "5"
            case .settings: return ","
            case .qr: return "."
            }
        }
    }


    // File transfer tracking state
    @Published var transfers: [String: FileTransferSession] = [:]

    // Toggle licensing
    let licenseCheck: Bool = false

    @Published var isPlus: Bool {
        didSet {
            if !shouldSkipSave {
                UserDefaults.standard.set(isPlus, forKey: "isPlus")
            }
            // Notify about license status change for icon revert logic
            NotificationCenter.default.post(name: NSNotification.Name("LicenseStatusChanged"), object: nil)
        }
    }

    // Moved from TabIdentifier and adapted
    static var availableTabs: [Tab] {
        // Default for disconnected state
        if AppState.shared.device == nil {
            // Show QR, Health and Settings even when not connected so Health UI is reachable
            return [.qr, .health, .settings]
        }

        // When a device is connected, show full set with Health included
        return [
            .notifications,
            .apps,
            .transfers,
            .sms,
            .calls,
            .health,
            .settings
        ]
    }


    /// Central message sending hub. Decides whether to send via WebSocket or Bluetooth.
    func sendMessage(_ message: String) {
        // If the connected device is via Bluetooth, use the BluetoothManager.
        if device?.ipAddress == "BLE" {
            BluetoothManager.shared.send(message)
            let truncated = message.count > 100 ? String(message.prefix(100)) + "..." : message
            print("[app-state] Sent message via BLE: \(truncated)")
        } else {
            // Otherwise, use the WebSocketServer.
            WebSocketServer.shared.sendToFirstAvailable(message: message)
        }
    }

    // Remove notification by id and system notif center
    func removeNotificationById(_ nid: String) {
        DispatchQueue.main.async {
            withAnimation {
                self.notifications.removeAll { $0.nid == nid }
            }
            if self.dismissNotif {
                WebSocketServer.shared.dismissNotification(id: nid)
            }
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [nid])
        }
    }

    // Remove notification by model instance and system notif center
    func removeNotification(_ notif: Notification) {
        DispatchQueue.main.async {
            withAnimation {
                self.notifications.removeAll { $0.id == notif.id }
            }
            if self.dismissNotif {
                WebSocketServer.shared.dismissNotification(id: notif.nid)
            }
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [notif.nid])
            print("[app-state] Removed notification nid=\(notif.nid)")
        }
    }

    func hideNotification(_ notif: Notification) {
        DispatchQueue.main.async {
            withAnimation {
                self.notifications.removeAll { $0.id == notif.id }
            }
            // Also remove from system center for consistency
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [notif.nid])
            print("[app-state] Hid notification nid=\(notif.nid)")
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
            print("[app-state] Cleared all notifications (in-memory and system center)")
        }
    }

    func postNativeNotification(
        id: String,
        appName: String,
        title: String,
        body: String,
        appIcon: NSImage? = nil,
        package: String? = nil,
        actions: [NotificationAction] = [],
        extraActions: [UNNotificationAction] = [],
        extraUserInfo: [String: Any] = [:]) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "\(appName) - \(title)"
        content.body = body
        
        // Use custom sound if selected, otherwise use default
        if notificationSound == "default" {
            content.sound = .default
        } else {
            // For system sounds, we need to use the .aiff extension
            content.sound = UNNotificationSound(named: UNNotificationSoundName("\(notificationSound).aiff"))
        }

        content.userInfo["nid"] = id
        if let pkg = package { content.userInfo["package"] = pkg }
        // Merge any extra payload the caller wants to pass
        for (k, v) in extraUserInfo { content.userInfo[k] = v }

        // Build action list (Android actions + optional View action if mirroring conditions)
        let actionDefinitions: [NotificationAction] = actions
        var includeView = false
        if let pkg = package, pkg != "com.sameerasw.airsync", adbConnected, mirroringPlus {
            includeView = true
        }

        // Construct UNNotificationActions
        var unActions: [UNNotificationAction] = []
        for a in actionDefinitions.prefix(8) { // safety cap
            switch a.type {
            case .button:
                unActions.append(UNNotificationAction(identifier: "ACT_\(a.name)", title: a.name, options: []))
            case .reply:
                if #available(macOS 13.0, *) {
                    unActions.append(UNTextInputNotificationAction(identifier: "ACT_\(a.name)", title: a.name, options: [], textInputButtonTitle: "Send", textInputPlaceholder: a.name))
                } else {
                    unActions.append(UNNotificationAction(identifier: "ACT_\(a.name)", title: a.name, options: []))
                }
            }
        }
        if includeView {
            unActions.append(UNNotificationAction(identifier: "VIEW_ACTION", title: "View", options: []))
        }
        // Append caller-provided extra actions (e.g., OPEN_LINK)
        unActions.append(contentsOf: extraActions)

        // Choose category: DEFAULT_CATEGORY when no custom actions besides optional view; otherwise derive
        if unActions.isEmpty {
            content.categoryIdentifier = "DEFAULT_CATEGORY"
            content.userInfo["actions"] = []
            finalizeAndSchedule(center: center, content: content, id: id, appIcon: appIcon)
        } else {
            let actionNamesKey = unActions.map { $0.identifier }.joined(separator: "_")
            let catId = "DYN_\(actionNamesKey)"
            content.categoryIdentifier = catId
            content.userInfo["actions"] = actions.map { ["name": $0.name, "type": $0.type.rawValue] }

            center.getNotificationCategories { existing in
                if existing.first(where: { $0.identifier == catId }) == nil {
                    let newCat = UNNotificationCategory(identifier: catId, actions: unActions, intentIdentifiers: [], options: [])
                    center.setNotificationCategories(existing.union([newCat]))
                }
                self.finalizeAndSchedule(center: center, content: content, id: id, appIcon: appIcon)
            }
        }
    }

    private func finalizeAndSchedule(center: UNUserNotificationCenter, content: UNMutableNotificationContent, id: String, appIcon: NSImage?) {
        // Attach icon
        if let icon = appIcon, let iconFileURL = saveIconToTemporaryFile(icon: icon) {
            if let attachment = try? UNNotificationAttachment(identifier: "appIcon", url: iconFileURL, options: nil) {
                content.attachments = [attachment]
            }
        }
        let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)
        center.add(request) { error in
            if let error = error { print("[state] (notification) Failed to post native notification: \(error)") }
        }
    }

    private func saveIconToTemporaryFile(icon: NSImage) -> URL? {
        // Save NSImage as a temporary PNG file to attach in notification
        guard let tiffData = icon.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else { return nil }

        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
        let tempFile = tempDir.appendingPathComponent("notification_icon_\(UUID().uuidString).png")

        do {
            try pngData.write(to: tempFile)
            return tempFile
        } catch {
            print("[state] Error saving icon to temp file: \(error)")
            return nil
        }
    }

    /// Adds a notification to in-memory list and posts a native macOS notification.
    func addNotification(_ notif: Notification) {
        DispatchQueue.main.async {
            withAnimation {
                self.notifications.insert(notif, at: 0)
            }
            // Trigger native macOS notification
            var appIcon: NSImage? = nil
            if let iconPath = self.androidApps[notif.package]?.iconUrl {
                appIcon = NSImage(contentsOfFile: iconPath)
            }
            self.postNativeNotification(
                id: notif.nid,
                appName: notif.app,
                title: notif.title,
                body: notif.body,
                appIcon: appIcon,
                package: notif.package,
                actions: notif.actions
            )
            print("[app-state] Added notification nid=\(notif.nid) app=\(notif.app) title=\(notif.title)")
        }
    }

    /// Disconnects the current device and resets related state.
    func disconnectDevice() {
        DispatchQueue.main.async {
            // Ask remote to disconnect (best-effort)
            WebSocketServer.shared.sendDisconnectRequest()

            // Reset local state
            self.device = nil
            self.notifications.removeAll()
            self.status = nil
            self.currentDeviceWallpaperBase64 = nil
            self.transfers = [:]
            self.lowBatteryNotifSent = false

            if self.adbConnected {
                ADBConnector.disconnectADB()
            }
            print("[app-state] Device disconnected; state reset")
        }
    }
    
    /// Sends a mirror start response back to Android (connection-agnostic).
    /// Use this instead of calling private WebSocketServer APIs from other files.
    func sendStartMirrorResponse(success: Bool) {
        let payload: [String: Any] = [
            "type": "startMirrorResponse",
            "data": ["success": success]
        ]
        if let json = try? JSONSerialization.data(withJSONObject: payload, options: []),
           let str = String(data: json, encoding: .utf8) {
            sendMessage(str)
            print("[app-state] Sent startMirrorResponse: success=\(success)")
        }
    }

    // MARK: - ADB-free Mirroring Control (Connection Agnostic)
    /// Requests Android to start mirroring using its own capture/stream stack (e.g., MediaProjection/WebRTC) without ADB.
    /// - Parameters:
    ///   - mode: Optional mode hint (e.g., "device", "desktop"). Android side may ignore.
    ///   - resolution: Optional target resolution string (e.g., "1600x1000").
    ///   - bitrateMbps: Optional target bitrate in Mbps.
    ///   - appPackage: Optional package to mirror specifically.
    func requestStartMirroring(mode: String? = nil, resolution: String? = nil, bitrateMbps: Int? = nil, appPackage: String? = nil) {
        var data: [String: Any] = [:]
        if let mode { data["mode"] = mode }
        // Include both new and legacy keys to maximize compatibility with Android/server implementations
        if let resolution {
            data["resolution"] = resolution
            data["res"] = resolution
        }
        if let bitrateMbps {
            data["bitrateMbps"] = bitrateMbps
            data["bitrate"] = bitrateMbps
        }
        if let appPackage { data["package"] = appPackage }

        let payload: [String: Any] = [
            "type": "startMirrorRequest",
            "data": data
        ]
        if let json = try? JSONSerialization.data(withJSONObject: payload, options: []),
           let str = String(data: json, encoding: .utf8) {
            sendMessage(str)
            print("[app-state] Sent startMirrorRequest: mode=\(mode ?? "-") res=\(resolution ?? "-") bitrate=\(bitrateMbps.map(String.init) ?? "-") package=\(appPackage ?? "-")")
        }
    }

    /// Requests Android to stop any ongoing mirroring session started via WebSocket.
    func requestStopMirroring() {
        let payload: [String: Any] = [
            "type": "stopMirrorRequest",
            "data": [:]
        ]
        if let json = try? JSONSerialization.data(withJSONObject: payload, options: []),
           let str = String(data: json, encoding: .utf8) {
            sendMessage(str)
            print("[app-state] Sent stopMirrorRequest")
        }
    }

    /// Sends a file to the connected device, regardless of connection type.
    func sendFile(url: URL) {
        DispatchQueue.global(qos: .userInitiated).async {
            // The sending logic is in WebSocketServer, but it uses AppState.sendMessage, so it's connection-agnostic.
            WebSocketServer.shared.sendFile(url: url)
        }
    }

    func syncWithSystemNotifications() {
        UNUserNotificationCenter.current().getDeliveredNotifications { systemNotifs in
            let systemNIDs = Set(systemNotifs.map { $0.request.identifier })

            DispatchQueue.main.async {
                let currentNIDs = Set(self.notifications.map { $0.nid })
                let removedNIDs = currentNIDs.subtracting(systemNIDs)

                for nid in removedNIDs {
                    print("[state] (notification) System notification \(nid) was dismissed manually.")
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
                    print("[state] (clipboard) updated :" + copiedString)
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
        sendMessage(message)
    }

    func updateClipboardFromAndroid(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        self.lastClipboardValue = text

        // Only show "Continue browsing" if the whole text is a valid http/https URL
        // AND the user has AirSync+ (isPlus). Otherwise show a regular clipboard update.
        if let url = exactURL(from: text), self.isPlus {
            let open = UNNotificationAction(identifier: "OPEN_LINK", title: "Open", options: [])
            self.postNativeNotification(
                id: "clipboard",
                appName: "Clipboard",
                title: "Continue browsing",
                body: text,
                extraActions: [open],
                extraUserInfo: ["url": url.absoluteString]
            )
        } else {
            // Non-plus users or non-URL clipboard content: simple clipboard update notification
            self.postNativeNotification(id: "clipboard", appName: "Clipboard", title: "Updated", body: text)
        }
    }

    private func stopClipboardMonitoring() {
        clipboardCancellable?.cancel()
        clipboardCancellable = nil
    }

    // MARK: - Continue browsing helper (exact URL detection)
    private func exactURL(from text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              (scheme == "http" || scheme == "https"),
              url.host != nil else { return nil }
        // Ensure no extra text beyond a URL
        if trimmed != text { /* allow surrounding whitespace */ }
        return url
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
            print("[state] (license) Failed to encode license details: \(error)")
        }
    }

    private func loadLicenseDetailsFromUserDefaults() -> LicenseDetails? {
        guard let data = UserDefaults.standard.data(forKey: licenseDetailsKey) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(LicenseDetails.self, from: data)
        } catch {
            print("[state] (license) Failed to decode license details: \(error)")
            return nil
        }
    }

    func saveAppsToDisk() {
        let url = appIconsDirectory().appendingPathComponent("apps.json")
        do {
            let data = try JSONEncoder().encode(Array(AppState.shared.androidApps.values))
            try data.write(to: url)
        } catch {
            print("[state] (apps) Error saving apps: \(error)")
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
                        AppState.shared
                            .androidApps[app.packageName]?.iconUrl = iconPath
                    }
                }
            }
        } catch {
            print("[state] (apps) Error loading apps: \(error)")
        }
    }

    func updateDockIconVisibility() {
        DispatchQueue.main.async {
            if self.hideDockIcon {
                NSApp.setActivationPolicy(.accessory)
            } else {
                NSApp.setActivationPolicy(.regular)
            }
        }
    }
    
    /// Revalidates the current network adapter selection and falls back to auto if no longer valid
    func revalidateNetworkAdapter() {
        let currentSelection = selectedNetworkAdapterName
        let validated = validateAndGetNetworkAdapter(savedName: currentSelection)
        
        if currentSelection != validated {
            print("[state] Network adapter changed from '\(currentSelection ?? "auto")' to '\(validated ?? "auto")'")
            selectedNetworkAdapterName = validated
            shouldRefreshQR = true
        }
    }
    
    /// Validates a saved network adapter name and returns it if available with valid IP, otherwise returns nil (auto)
    private func validateAndGetNetworkAdapter(savedName: String?) -> String? {
        guard let savedName = savedName else {
            print("[state] No saved network adapter, using auto selection")
            return nil // Auto mode
        }
        
        // Get available adapters from WebSocketServer
        let availableAdapters = WebSocketServer.shared.getAvailableNetworkAdapters()
        
        // Check if the saved adapter is still available
        guard availableAdapters
            .first(where: { $0.name == savedName }) != nil else {
            print("[state] Saved network adapter '\(savedName)' not found, falling back to auto")
            return nil // Fall back to auto
        }
        
        // Verify the adapter has a valid IP address
        let ipAddress = WebSocketServer.shared.getLocalIPAddress(adapterName: savedName)
        guard let validIP = ipAddress, !validIP.isEmpty, validIP != "127.0.0.1" else {
            print("[state] Saved network adapter '\(savedName)' has no valid IP (\(ipAddress ?? "nil")), falling back to auto")
            return nil // Fall back to auto
        }
        
        print("[state] Using saved network adapter: \(savedName) -> \(validIP)")
        return savedName
    }
    
    // MARK: - Health Data Request (Android -> Mac)
    /// Requests latest health snapshot from the connected Android device.
    func requestHealthData() {
        let message = """
        {
            "type": "requestHealthData",
            "data": {}
        }
        """
        sendMessage(message)
        print("[app-state] Sent requestHealthData")
    }

    // MARK: - Calls & Messages Requests (Android -> Mac)
    /// Requests recent call logs from the connected Android device.
    /// - Parameter limit: Maximum number of entries to request (device side may clamp).
    func requestCallLogs(limit: Int = 50) {
        let payload: [String: Any] = [
            "type": "requestCallLogs",
            "data": ["limit": limit]
        ]
        if let json = try? JSONSerialization.data(withJSONObject: payload, options: []),
           let str = String(data: json, encoding: .utf8) {
            sendMessage(str)
            print("[app-state] Sent requestCallLogs(limit: \(limit))")
        }
    }

    /// Requests recent SMS conversations from the connected Android device.
    func requestSmsConversations() {
        let payload: [String: Any] = [
            "type": "requestSmsConversations",
            "data": [:]
        ]
        if let json = try? JSONSerialization.data(withJSONObject: payload, options: []),
           let str = String(data: json, encoding: .utf8) {
            sendMessage(str)
            print("[app-state] Sent requestSmsConversations")
        }
    }

    /// Replaces current call logs with the provided array (to be called by network layer upon response).
    func setCallLogs(_ logs: [CallLogEntry]) {
        DispatchQueue.main.async {
            self.callLogs = logs
        }
    }
}

extension AppState {
    /// Call this during app initialization to route mirror approval actions.
    func registerMirrorApprovalHandler() {
        UNUserNotificationCenter.current().delegate = NotificationActionRouter.shared
    }
}

final class NotificationActionRouter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationActionRouter()

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let info = response.notification.request.content.userInfo
        guard let type = info["type"] as? String, type == "startMirrorRequest" else { return }

        let mode = (info["mode"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        let res = (info["resolution"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        let bitrate = info["bitrate"] as? Int
        let pkg = (info["package"] as? String).flatMap { $0.isEmpty ? nil : $0 }

        switch response.actionIdentifier {
        case "MIRROR_ACCEPT":
            // Start mirroring on Mac and send positive response back to Android
            MirroringManager.shared.startMirroring(mode: mode ?? "desktop", resolution: res ?? "1600x1000", bitrate: bitrate ?? 6, package: pkg)
            AppState.shared.sendStartMirrorResponse(success: true)
        case "MIRROR_REJECT":
            AppState.shared.sendStartMirrorResponse(success: false)
        case "MIRROR_CANCEL":
            // Neutral response — treat as reject
            AppState.shared.sendStartMirrorResponse(success: false)
        default:
            break
        }
    }
}

struct CallLogEntry: Codable, Identifiable {
    let id: String            // Unique identifier per call (e.g., Android _id or generated UUID)
    let name: String?         // Cached contact name if available
    let number: String        // E.164 or raw dialed number
    let type: String          // "incoming", "outgoing", "missed", "rejected", etc.
    let timestamp: Int64      // Epoch milliseconds
    let durationSeconds: Int  // Call duration in seconds
}

