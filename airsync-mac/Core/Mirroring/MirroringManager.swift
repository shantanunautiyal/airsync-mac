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

class MirroringManager: NSObject, NSWindowDelegate {
    static let shared = MirroringManager()

    private var mirroringWindow: NSWindow?
    private var mirroringView: MirroringView?
    
    private var decompressionSession: VTDecompressionSession?
    private var videoFormatDescription: CMVideoFormatDescription?
    
    private var spsData: Data?
    private var ppsData: Data?
    private var frameCount: CMTimeValue = 0

    private override init() {
        super.init()
    }

    func startMirroring(mode: String, resolution: String, bitrate: Int, package: String?) {
        print("[MirroringManager] Starting mirroring with mode=\(mode), resolution=\(resolution), bitrate=\(bitrate)")

        DispatchQueue.main.async {
            if let window = self.mirroringWindow {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                return
            }
            
            let windowRect = NSRect(x: 0, y: 0, width: 800, height: 450)
            self.mirroringView = MirroringView(frame: windowRect)
            
            self.mirroringWindow = NSWindow(
                contentRect: windowRect,
                styleMask: [.titled, .closable, .resizable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            self.mirroringWindow?.delegate = self
            self.mirroringWindow?.contentView = self.mirroringView
            self.mirroringWindow?.title = "Screen Mirroring"
            self.mirroringWindow?.center()
            self.mirroringWindow?.isReleasedWhenClosed = false
            self.mirroringWindow?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func stopMirroring() {
        print("[MirroringManager] Stopping mirroring")
        
        DispatchQueue.main.async {
            self.mirroringWindow?.close()
        }
        
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
        }
        AppState.shared.sendStopMirrorRequest()
    }

    func handleVideoFrame(data: Data) {
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
                if let window = self.mirroringWindow {
                    let contentRect = window.contentRect(forFrameRect: window.frame)
                    let newHeight = contentRect.width / aspectRatio
                    let newFrameSize = NSSize(width: contentRect.width, height: newHeight)
                    print("[MirroringManager] Resizing window to: \(newFrameSize)")
                    window.setContentSize(newFrameSize)
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