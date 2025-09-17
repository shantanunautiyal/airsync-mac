//
//  NowPlayingViewModel.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2025-09-17.
//
import Foundation
internal import Combine
import IOKit.ps

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
        
        print("Starting media playback monitoring - device connected")
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
        
        NowPlayingCLI.shared.fetchNowPlaying { [weak self] info in
            guard let info = info else {
                print("No now playing info")
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
    }

    private func sendDeviceStatusIfNeeded(with info: NowPlayingInfo) {
        // Only send if there's a connected device and the info has changed
        guard AppState.shared.device != nil else { return }

        // Check if the media info has actually changed to avoid spam
        if let lastInfo = lastSentInfo,
           lastInfo.title == info.title &&
           lastInfo.artist == info.artist &&
           lastInfo.isPlaying == info.isPlaying &&
           lastInfo.elapsedTime == info.elapsedTime {
            return
        }

        // Get battery info (hardcoded for now)
        let batteryInfo = getBatteryInfo()

        // Convert artwork to base64 if available
        let albumArtBase64 = info.artworkData?.base64EncodedString()

        // Send device status to Android
        WebSocketServer.shared.sendDeviceStatus(
            batteryLevel: batteryInfo.level,
            isCharging: batteryInfo.isCharging,
            isPaired: true, // Always true when device is connected
            musicInfo: info,
            albumArtBase64: albumArtBase64
        )

        // Update last sent info
        lastSentInfo = info
        print("Sent device status to Android: \(info.title ?? "Unknown") by \(info.artist ?? "Unknown")")
    }

    private func getBatteryInfo() -> (level: Int, isCharging: Bool) {
        // Get battery info using IOKit
        let powerSourcesInfo = IOPSCopyPowerSourcesInfo()?.takeRetainedValue()
        let powerSources = IOPSCopyPowerSourcesList(powerSourcesInfo)?.takeRetainedValue() as? [CFTypeRef]

        for powerSource in powerSources ?? [] {
            if let psInfo = IOPSGetPowerSourceDescription(powerSourcesInfo, powerSource)?.takeUnretainedValue() as? [String: Any] {
                if let currentCapacity = psInfo[kIOPSCurrentCapacityKey] as? Int,
                   let maxCapacity = psInfo[kIOPSMaxCapacityKey] as? Int,
                   let powerSourceState = psInfo[kIOPSPowerSourceStateKey] as? String {

                    let batteryLevel = (currentCapacity * 100) / maxCapacity
                    let isCharging = (powerSourceState == kIOPSACPowerValue)

                    return (level: batteryLevel, isCharging: isCharging)
                }
            }
        }

        // Fallback to hardcoded values if battery info can't be retrieved
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
