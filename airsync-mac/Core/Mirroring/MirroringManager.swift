//
//  MirroringManager.swift
//  airsync-mac
//
//  Created by Shantanu Nautiyal on 2025-10-04.
//

import Foundation
import AppKit
import VideoToolbox
internal import Combine

class MirroringManager: NSObject, NSWindowDelegate, ObservableObject {
    static let shared = MirroringManager()
    @Published var isMirroring: Bool = false

    private var mirroringWindow: NSWindow?
    private var mirroringView: MirroringView?
    
    private var decompressionSession: VTDecompressionSession?
    private var videoFormatDescription: CMVideoFormatDescription?
    
    private var spsData: Data?
    private var ppsData: Data?
    private var frameCount: CMTimeValue = 0

    private var pendingWindowStart: (mode: String, resolution: String, bitrate: Int, package: String?)?
    private var firstFrameReceived: Bool = false

    private override init() {
        super.init()
    }

    func startMirroring(mode: String, resolution: String, bitrate: Int, package: String?) {
        print("[MirroringManager] Starting mirroring request with mode=\(mode), resolution=\(resolution), bitrate=\(bitrate)")
        // Defer window creation until first frame arrives to avoid blank popup
        DispatchQueue.main.async {
            self.pendingWindowStart = (mode, resolution, bitrate, package)
            self.firstFrameReceived = false
        }
    }

    func stopMirroring() {
        print("[MirroringManager] Stopping mirroring")
        
        DispatchQueue.main.async {
            self.mirroringWindow?.close()
            self.mirroringWindow?.level = .normal
            self.isMirroring = false
        }
        
        self.pendingWindowStart = nil
        self.firstFrameReceived = false
        
        if let session = decompressionSession {
            VTDecompressionSessionInvalidate(session)
            self.decompressionSession = nil
        }
        self.videoFormatDescription = nil
        self.spsData = nil
        self.ppsData = nil
    }
    
    @objc func windowWillClose(_ notification: Foundation.Notification) {
        guard let window = notification.object as? NSWindow, window === self.mirroringWindow else {
            return
        }
        
        print("[MirroringManager] Mirroring window closed by user.")
        DispatchQueue.main.async {
            self.mirroringWindow = nil
            self.mirroringView = nil
            self.isMirroring = false
            AppState.shared.sendStopMirrorRequest()
        }
    }

    func handleVideoFrame(data: Data) {
        if !firstFrameReceived {
            firstFrameReceived = true
            DispatchQueue.main.async {
                if self.mirroringWindow == nil {
                    let windowRect = NSRect(x: 0, y: 0, width: 360, height: 640) // default portrait-ish
                    self.mirroringView = MirroringView(frame: windowRect)
                    self.mirroringWindow = NSWindow(
                        contentRect: windowRect,
                        styleMask: [.titled, .closable, .resizable, .miniaturizable],
                        backing: .buffered,
                        defer: false
                    )
                    self.mirroringWindow?.delegate = self
                    self.mirroringWindow?.contentView = self.mirroringView
                    self.mirroringView?.setFillMode(AppState.shared.mirrorScaleFill)
                    self.mirroringWindow?.title = "Screen Mirroring"
                    self.mirroringWindow?.center()
                    self.mirroringWindow?.isReleasedWhenClosed = false
                    // Keep the window visible and above normal level while mirroring
                    self.mirroringWindow?.level = .floating
                    self.mirroringWindow?.isMovableByWindowBackground = true

                    // Apply portrait 9:16 if desktop mode is disabled
                    if !AppState.shared.mirrorDesktopMode && AppState.shared.mirrorForcePortrait916 {
                        let portraitSize = NSSize(width: 360, height: 640)
                        self.mirroringWindow?.setContentSize(portraitSize)
                        self.mirroringWindow?.contentAspectRatio = NSSize(width: 9, height: 16)
                    }

                    self.mirroringWindow?.makeKeyAndOrderFront(nil)
                    NSApp.activate(ignoringOtherApps: true)
                    self.isMirroring = true
                }
            }
        }
        
        let startCode: [UInt8] = [0, 0, 0, 1]
        var searchIndex = data.startIndex
        
        while let range = data.range(of: Data(startCode), in: searchIndex..<data.endIndex) {
            let nalUnitStartIndex = range.upperBound
            
            var nextNalUnitRange: Range<Data.Index>?
            if nalUnitStartIndex < data.endIndex {
                nextNalUnitRange = data.range(of: Data(startCode), in: nalUnitStartIndex..<data.endIndex)
            }
            
            let nalUnitEndIndex = nextNalUnitRange?.lowerBound ?? data.endIndex
            let nalUnitBytes = data[nalUnitStartIndex..<nalUnitEndIndex]
            
            if nalUnitBytes.isEmpty {
                searchIndex = nalUnitEndIndex
                continue
            }
            
            let nalType = nalUnitBytes[nalUnitBytes.startIndex] & 0x1F
            
            switch nalType {
            case 7: // SPS
                spsData = Data(nalUnitBytes)
                if let pps = ppsData {
                    createDecompressionSession(sps: Data(nalUnitBytes), pps: pps)
                }
            case 8: // PPS
                ppsData = Data(nalUnitBytes)
                if let sps = spsData {
                    createDecompressionSession(sps: sps, pps: Data(nalUnitBytes))
                }
            case 5, 1: // IDR frame (keyframe) or Non-IDR frame
                decodeFrame(nalUnit: Data(nalUnitBytes))
            default:
                break
            }
            
            searchIndex = nalUnitEndIndex
        }
    }

    private func createDecompressionSession(sps: Data, pps: Data) {
        guard decompressionSession == nil else { return }

        var parameterSetPointers: [UnsafePointer<UInt8>] = []
        var parameterSetSizes: [Int] = []
        let parameterSet = [sps, pps]

        parameterSet.forEach { data in
            let pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
            data.copyBytes(to: pointer, count: data.count)
            parameterSetPointers.append(UnsafePointer(pointer))
            parameterSetSizes.append(data.count)
        }
        
        defer {
            parameterSetPointers.forEach { $0.deallocate() }
        }

        var status = noErr
        parameterSetPointers.withUnsafeBufferPointer { pointers in
            parameterSetSizes.withUnsafeBufferPointer { sizes in
                status = CMVideoFormatDescriptionCreateFromH264ParameterSets(
                    allocator: kCFAllocatorDefault,
                    parameterSetCount: parameterSet.count,
                    parameterSetPointers: pointers.baseAddress!,
                    parameterSetSizes: sizes.baseAddress!,
                    nalUnitHeaderLength: 4,
                    formatDescriptionOut: &videoFormatDescription
                )
            }
        }

        guard status == noErr, let format = videoFormatDescription else {
            print("[MirroringManager] ERROR: Failed to create video format description. Status: \(status)")
            return
        }

        let dimensions = CMVideoFormatDescriptionGetDimensions(format)
        print("[MirroringManager] Video dimensions: \(dimensions.width)x\(dimensions.height)")
        if dimensions.width > 0 && dimensions.height > 0 {
            let aspectRatio = CGFloat(dimensions.width) / CGFloat(dimensions.height)
            print("[MirroringManager] Video aspect ratio: \(aspectRatio)")
            DispatchQueue.main.async {
                guard let window = self.mirroringWindow else { return }
                if !AppState.shared.mirrorDesktopMode && AppState.shared.mirrorForcePortrait916 {
                    // Force portrait 9:16 window
                    var newWidth: CGFloat = max(360, window.frame.width)
                    var newHeight: CGFloat = newWidth * (16.0/9.0)
                    if newHeight < 640 { newHeight = 640; newWidth = newHeight * (9.0/16.0) }
                    let newFrameSize = NSSize(width: newWidth, height: newHeight)
                    print("[MirroringManager] Forcing portrait 9:16 size: \(newFrameSize)")
                    window.setContentSize(newFrameSize)
                    window.contentAspectRatio = NSSize(width: 9, height: 16)
                } else if AppState.shared.mirrorScaleFill {
                    // Fill the window to remove black bars; MirroringView will crop as needed
                    let contentRect = window.contentRect(forFrameRect: window.frame)
                    var newWidth = contentRect.width
                    var newHeight = contentRect.height
                    if newWidth / newHeight < CGFloat(aspectRatio) {
                        // Window is taller than stream; expand width to match aspect
                        newWidth = newHeight * CGFloat(aspectRatio)
                    } else {
                        // Window is wider; expand height
                        newHeight = newWidth / CGFloat(aspectRatio)
                    }
                    window.setContentSize(NSSize(width: newWidth, height: newHeight))
                    window.contentAspectRatio = NSSize(width: CGFloat(aspectRatio), height: 1.0)
                    self.mirroringView?.setFillMode(true)
                } else {
                    // Follow stream aspect
                    let contentRect = window.contentRect(forFrameRect: window.frame)
                    var newWidth = contentRect.width
                    var newHeight = newWidth / aspectRatio
                    if newWidth < 320 { newWidth = 320; newHeight = newWidth / aspectRatio }
                    if newHeight < 240 { newHeight = 240; newWidth = newHeight * aspectRatio }
                    let newFrameSize = NSSize(width: newWidth, height: newHeight)
                    print("[MirroringManager] Resizing window to: \(newFrameSize)")
                    window.setContentSize(newFrameSize)
                    window.contentAspectRatio = NSSize(width: aspectRatio, height: 1.0)
                    self.mirroringView?.setFillMode(false)
                }
            }
        }

        var session: VTDecompressionSession?
        let decoderParameters = [:] as CFDictionary
        let imageBufferAttributes = [
            kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA
        ] as CFDictionary
        var outputCallback = VTDecompressionOutputCallbackRecord(
            decompressionOutputCallback: { (decompressionOutputRefCon, sourceFrameRefCon, status, infoFlags, imageBuffer, presentationTimeStamp, duration) in
                guard let manager = decompressionOutputRefCon.map({ Unmanaged<MirroringManager>.fromOpaque($0).takeUnretainedValue() }) else { return }
                if status == noErr, let imageBuffer = imageBuffer {
                    var sampleBuffer: CMSampleBuffer?
                    var formatDescription: CMVideoFormatDescription?
                    CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: imageBuffer, formatDescriptionOut: &formatDescription)

                    var timingInfo = CMSampleTimingInfo(duration: duration, presentationTimeStamp: presentationTimeStamp, decodeTimeStamp: .invalid)

                    CMSampleBufferCreateForImageBuffer(
                        allocator: kCFAllocatorDefault,
                        imageBuffer: imageBuffer,
                        dataReady: true,
                        makeDataReadyCallback: nil,
                        refcon: nil,
                        formatDescription: formatDescription!,
                        sampleTiming: &timingInfo,
                        sampleBufferOut: &sampleBuffer
                    )

                    if let sampleBuffer = sampleBuffer {
                        DispatchQueue.main.async {
                            manager.mirroringView?.enqueue(sampleBuffer)
                        }
                    }
                } else {
                    print("[MirroringManager] ERROR: Decompression callback error: \(status)")
                    if let manager = decompressionOutputRefCon.map({ Unmanaged<MirroringManager>.fromOpaque($0).takeUnretainedValue() }) {
                        if let session = manager.decompressionSession {
                            VTDecompressionSessionInvalidate(session)
                            manager.decompressionSession = nil
                        }
                    }
                }
            },
            decompressionOutputRefCon: Unmanaged.passUnretained(self).toOpaque()
        )

        let createStatus = VTDecompressionSessionCreate(
            allocator: kCFAllocatorDefault,
            formatDescription: format,
            decoderSpecification: decoderParameters,
            imageBufferAttributes: imageBufferAttributes,
            outputCallback: &outputCallback,
            decompressionSessionOut: &session
        )
        
        if createStatus == noErr {
            self.decompressionSession = session
            print("[MirroringManager] SUCCESS: Decompression session created.")
        } else {
            print("[MirroringManager] ERROR: Failed to create decompression session. Status: \(createStatus)")
        }
    }
    
    private func decodeFrame(nalUnit: Data) {
        guard let session = decompressionSession, let format = videoFormatDescription else { return }
        
        var blockBuffer: CMBlockBuffer?
        var length = CFSwapInt32HostToBig(UInt32(nalUnit.count))
        
        let nalUnitWithLength = NSMutableData()
        nalUnitWithLength.append(&length, length: 4)
        nalUnitWithLength.append(nalUnit)
        
        let status = CMBlockBufferCreateWithMemoryBlock(
            allocator: kCFAllocatorDefault,
            memoryBlock: nalUnitWithLength.mutableBytes,
            blockLength: nalUnitWithLength.length,
            blockAllocator: kCFAllocatorNull,
            customBlockSource: nil,
            offsetToData: 0,
            dataLength: nalUnitWithLength.length,
            flags: 0,
            blockBufferOut: &blockBuffer
        )
        
        guard status == kCMBlockBufferNoErr, let buffer = blockBuffer else {
            print("[MirroringManager] ERROR: Failed to create block buffer. Status: \(status)")
            return
        }
        
        var sampleBuffer: CMSampleBuffer?
        let sampleSizeArray = [nalUnitWithLength.length]
        
        var timingInfo = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: 30),
            presentationTimeStamp: CMTime(value: self.frameCount, timescale: 30),
            decodeTimeStamp: .invalid
        )
        self.frameCount += 1

        let createStatus = CMSampleBufferCreate(
            allocator: kCFAllocatorDefault,
            dataBuffer: buffer,
            dataReady: true,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: format,
            sampleCount: 1,
            sampleTimingEntryCount: 1,
            sampleTimingArray: &timingInfo,
            sampleSizeEntryCount: 1,
            sampleSizeArray: sampleSizeArray,
            sampleBufferOut: &sampleBuffer
        )
        
        guard createStatus == noErr, let finalSampleBuffer = sampleBuffer else {
            print("[MirroringManager] ERROR: Failed to create sample buffer. Status: \(createStatus)")
            return
        }
        
        if let attachments = CMSampleBufferGetSampleAttachmentsArray(finalSampleBuffer, createIfNecessary: true) {
            if CFArrayGetCount(attachments) > 0 {
                if let dict = CFArrayGetValueAtIndex(attachments, 0) {
                    let mutableDict = Unmanaged<CFMutableDictionary>.fromOpaque(dict).takeUnretainedValue()
                    CFDictionarySetValue(
                        mutableDict,
                        Unmanaged.passUnretained(kCMSampleAttachmentKey_DisplayImmediately).toOpaque(),
                        Unmanaged.passUnretained(kCFBooleanTrue).toOpaque()
                    )
                }
            }
        }
        
        var infoFlags: VTDecodeInfoFlags = []
        let decodeStatus = VTDecompressionSessionDecodeFrame(session, sampleBuffer: finalSampleBuffer, flags: ._EnableAsynchronousDecompression, frameRefcon: nil, infoFlagsOut: &infoFlags)
        
        if decodeStatus != noErr {
            print("[MirroringManager] ERROR: DecodeFrame failed with status: \(decodeStatus)")
        }
    }
}

extension MirroringView {
    @objc func setFillMode(_ fill: Bool) { /* no-op if not implemented */ }
}
