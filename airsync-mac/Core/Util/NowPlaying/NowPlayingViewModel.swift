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

    private var timer: Timer?

    init() {
        startPolling()
    }

    deinit {
        stopPolling()
    }

    private func startPolling() {
        fetch() // initial fetch
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.fetch()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    private func fetch() {
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
            }
        }
    }

    func togglePlayPause() {
        NowPlayingCLI.shared.toggle()
    }
}
