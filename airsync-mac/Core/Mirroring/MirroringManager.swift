import Foundation
import AppKit
import VideoToolbox

class MirroringManager: NSObject {
    static let shared = MirroringManager()

    private var mirroringWindow: NSWindow?
    private var mirroringView: MirroringView?
    
    private var decompressionSession: VTDecompressionSession?
    private var videoFormatDescription: CMVideoFormatDescription?

    private override init() {
        super.init()
        // The WebSocket server for video stream will be set up here
    }

    func startMirroring(mode: String, resolution: String, bitrate: Int, package: String?) {
        print("[MirroringManager] Starting mirroring with mode=\(mode), resolution=\(resolution), bitrate=\(bitrate)")

        // TODO: Set up WebSocket endpoint for video stream

        // Create and show the mirroring window
        DispatchQueue.main.async {
            let windowRect = NSRect(x: 0, y: 0, width: 800, height: 600) // Initial size
            self.mirroringView = MirroringView(frame: windowRect)
            
            self.mirroringWindow = NSWindow(
                contentRect: windowRect,
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            self.mirroringWindow?.contentView = self.mirroringView
            self.mirroringWindow?.title = "Screen Mirroring"
            self.mirroringWindow?.center()
            self.mirroringWindow?.makeKeyAndOrderFront(nil)
        }
        
        // TODO: Initialize VTDecompressionSession when video format is known
    }

    func stopMirroring() {
        print("[MirroringManager] Stopping mirroring")
        
        // TODO: Close WebSocket connection
        
        DispatchQueue.main.async {
            self.mirroringWindow?.close()
            self.mirroringWindow = nil
            self.mirroringView = nil
        }
        
        if let session = decompressionSession {
            VTDecompressionSessionInvalidate(session)
            self.decompressionSession = nil
        }
        self.videoFormatDescription = nil
    }

    // This will be called when a video frame is received
    func handleVideoFrame(data: Data) {
        // TODO: Decode the frame and display it
    }
}
