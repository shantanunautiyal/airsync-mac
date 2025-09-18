//
//  NowPlayingViewModel.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2025-09-17.
//
import Foundation
internal import Combine

class NowPlayingViewModel: ObservableObject {
    @Published var title: String = "Unknown Title"
    @Published var artist: String = "Unknown Artist"
    @Published var album: String = "Unknown Album"
    @Published var elapsed: Double = 0
    @Published var duration: Double = 0
    @Published var isPlaying: Bool = false
    @Published var artworkBase64: String = ""

    private var timer: Timer?
    private var lastSentInfo: NowPlayingInfo?
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Monitor device connection status and start/stop polling accordingly
        AppState.shared.$device
            .sink { [weak self] device in
                if device != nil {
                    self?.startPolling()
                } else {
                    self?.stopPolling()
                }
            }
            .store(in: &cancellables)
    }

    deinit {
        stopPolling()
        cancellables.removeAll()
    }

    private func startPolling() {
        // Don't start if already running
        guard timer == nil else { return }

        print("Starting device status monitoring - device connected")
        fetch() // initial fetch
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.fetch()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func stopPolling() {
        guard timer != nil else { return }

        print("Stopping media playback monitoring - device disconnected")
        timer?.invalidate()
        timer = nil

        // Reset published properties when stopping
        title = "Unknown Title"
        artist = "Unknown Artist"
        album = "Unknown Album"
        elapsed = 0
        duration = 0
        isPlaying = false
        artworkBase64 = ""
        lastSentInfo = nil
    }

    private func fetch() {
        // Only fetch if there's a connected device
        guard AppState.shared.device != nil else { return }

        // Check if now playing status is enabled
        if AppState.shared.sendNowPlayingStatus {
            // Fetch now playing info and send device status with music info
            NowPlayingCLI.shared.fetchNowPlaying { [weak self] info in
                guard let info = info else {
                    print("No now playing info")
                    // Still send device status without music info
                    self?.sendDeviceStatusWithoutMusic()
                    return
                }
                // MUST update @Published properties on main thread
                DispatchQueue.main.async {
                    print("Now Playing fetched:", info) // debug
                    self?.title = info.title ?? "Unknown Title"
                    self?.artist = info.artist ?? "Unknown Artist"
                    self?.album = info.album ?? "Unknown Album"
                    self?.elapsed = info.elapsedTime ?? 0
                    self?.duration = info.duration ?? 0
                    self?.isPlaying = info.isPlaying ?? false

                    // Convert artwork to base64 if available
                    if let artworkData = info.artworkData {
                        self?.artworkBase64 = artworkData.base64EncodedString()
                    } else {
                        self?.artworkBase64 = ""
                    }

                    // Send to Android if connected and info has changed
                    self?.sendDeviceStatusIfNeeded(with: info)
                }
            }
        } else {
            // Now playing disabled - just send device status without music info
            sendDeviceStatusWithoutMusic()
        }
    }
    
    private func sendDeviceStatusWithoutMusic() {
        // Only send if there's a connected device
        guard AppState.shared.device != nil else { return }

        // Get battery info
        let batteryInfo = getBatteryInfo()

        // Send device status without music info
        WebSocketServer.shared.sendDeviceStatus(
            batteryLevel: batteryInfo.level,
            isCharging: batteryInfo.isCharging,
            isPaired: true, // Always true when device is connected
            musicInfo: nil, // No music info when disabled
            albumArtBase64: nil
        )

        // Handle N/A battery status for desktop Macs
        if batteryInfo.level == -1 {
            print("Sent device status update (desktop Mac - no battery, no music)")
        } else {
            print("Sent device status update (battery: \(batteryInfo.level)%, charging: \(batteryInfo.isCharging), no music)")
        }
    }

    private func sendDeviceStatusIfNeeded(with info: NowPlayingInfo) {
        // Only send if there's a connected device
        guard AppState.shared.device != nil else { return }

        // Check if now playing is enabled - if not, send status without music info
        let shouldIncludeMusicInfo = AppState.shared.sendNowPlayingStatus
        
        // Check if the media info has actually changed for logging purposes
        let mediaInfoChanged: Bool
        if let lastInfo = lastSentInfo {
            let titleChanged = lastInfo.title != info.title
            let artistChanged = lastInfo.artist != info.artist
            let playingChanged = lastInfo.isPlaying != info.isPlaying
            let elapsedChanged = lastInfo.elapsedTime != info.elapsedTime
            mediaInfoChanged = titleChanged || artistChanged || playingChanged || elapsedChanged
        } else {
            mediaInfoChanged = true
        }

        // Get battery info
        let batteryInfo = getBatteryInfo()

        // Convert artwork to base64 if available and music info is enabled
        let albumArtBase64 = shouldIncludeMusicInfo ? info.artworkData?.base64EncodedString() : nil

        // Always send device status to Android (includes battery info which can change independently)
        // But conditionally include music info based on user setting
        WebSocketServer.shared.sendDeviceStatus(
            batteryLevel: batteryInfo.level,
            isCharging: batteryInfo.isCharging,
            isPaired: true, // Always true when device is connected
            musicInfo: shouldIncludeMusicInfo ? info : nil,
            albumArtBase64: albumArtBase64
        )

        // Update last sent info only if we're tracking music
        if shouldIncludeMusicInfo {
            lastSentInfo = info
        }
        
        if shouldIncludeMusicInfo && mediaInfoChanged {
            print("Sent device status to Android: \(info.title ?? "Unknown") by \(info.artist ?? "Unknown")")
        } else {
            // Handle N/A battery status for desktop Macs
            if batteryInfo.level == -1 {
                print("Sent device status update (desktop Mac - no battery)")
            } else {
                print("Sent device status update (battery: \(batteryInfo.level)%, charging: \(batteryInfo.isCharging))")
            }
        }
    }

    private func getBatteryInfo() -> (level: Int, isCharging: Bool) {
        // Check if this is a MacBook (Air or Pro) - only these have batteries
        let deviceType = DeviceTypeUtil.deviceTypeDescription()
        let isMacBook = deviceType.contains("MacBook")
        
        guard isMacBook else {
            // For desktop Macs (iMac, Mac mini, Mac Pro, Mac Studio), return N/A status
            print("Desktop Mac detected (\(deviceType)) - no battery present")
            return (level: -1, isCharging: false) // -1 indicates N/A
        }
        
        // Get battery info using pmset command for MacBooks
        if let batteryStatus = BatteryInfo.fetchStatus() {
            return (level: batteryStatus.percentage, isCharging: batteryStatus.isCharging)
        }
        
        // Fallback to hardcoded values if battery info can't be retrieved on MacBook
        print("Failed to fetch battery status on MacBook, using fallback values")
        return (level: 75, isCharging: false)
    }

    // MARK: - Media Control Functions
    func togglePlayPause() {
        NowPlayingCLI.shared.toggle()
    }

    func play() {
        NowPlayingCLI.shared.play()
    }

    func pause() {
        NowPlayingCLI.shared.pause()
    }

    func next() {
        print("Next track requested")
        // Add implementation for next track if available in NowPlayingCLI
    }

    func previous() {
        print("Previous track requested")
        // Add implementation for previous track if available in NowPlayingCLI
    }

    func stop() {
        print("Stop playback requested")
        // Add implementation for stop if available in NowPlayingCLI
    }
}
