import AppKit
import AVFoundation

class MirroringView: NSView {
    private let displayLayer = AVSampleBufferDisplayLayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }

    private func setupLayer() {
        wantsLayer = true
        if layer == nil { layer = CALayer() }
        layer?.backgroundColor = NSColor.clear.cgColor
        displayLayer.backgroundColor = NSColor.clear.cgColor
        displayLayer.isOpaque = false
        layer?.addSublayer(displayLayer)
        updateVideoGravity()
        
        do {
            let timebase = try CMTimebase(sourceClock: CMClockGetHostTimeClock())
            CMTimebaseSetRate(timebase, rate: 1.0)
            displayLayer.controlTimebase = timebase
        } catch {
            print("[MirroringView] ERROR: Failed to create timebase: \(error)")
        }
    }

    private func updateVideoGravity() {
        // Enforce aspect-fit to avoid any cropping regardless of mode or flags
        displayLayer.videoGravity = .resizeAspect
    }
    
    func applyCurrentVideoGravity() {
        updateVideoGravity()
    }

    func enqueue(_ sampleBuffer: CMSampleBuffer) {
        displayLayer.enqueue(sampleBuffer)
    }
    
    func flush() {
        displayLayer.flush()
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        displayLayer.frame = CGRect(origin: .zero, size: newSize)
    }

    // MARK: - Input Events

    override var acceptsFirstResponder: Bool {
        return true
    }

    override func mouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        let normalizedX = location.x / bounds.width
        let normalizedY = 1.0 - (location.y / bounds.height)
        sendControlEvent(type: "touch", action: "down", x: normalizedX, y: normalizedY)
    }

    override func mouseDragged(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        let normalizedX = location.x / bounds.width
        let normalizedY = 1.0 - (location.y / bounds.height)
        sendControlEvent(type: "touch", action: "move", x: normalizedX, y: normalizedY)
    }

    override func mouseUp(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        let normalizedX = location.x / bounds.width
        let normalizedY = 1.0 - (location.y / bounds.height)
        sendControlEvent(type: "touch", action: "up", x: normalizedX, y: normalizedY)
    }

    override func keyDown(with event: NSEvent) {
        sendControlEvent(type: "key", action: "down", keyCode: event.keyCode)
    }

    override func keyUp(with event: NSEvent) {
        sendControlEvent(type: "key", action: "up", keyCode: event.keyCode)
    }

    private func sendControlEvent(type: String, action: String, x: CGFloat? = nil, y: CGFloat? = nil, keyCode: UInt16? = nil) {
        var data: [String: Any] = [
            "type": type,
            "action": action
        ]
        if let x = x, let y = y {
            data["x"] = x
            data["y"] = y
        }
        if let keyCode = keyCode {
            data["keyCode"] = keyCode
        }
        
        let payload: [String: Any] = [
            "type": "inputEvent",
            "data": data
        ]
        
        if let json = try? JSONSerialization.data(withJSONObject: payload, options: []),
           let str = String(data: json, encoding: .utf8) {
            AppState.shared.sendMessage(str)
        }
    }
}
