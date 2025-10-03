import Foundation
import AppKit
import VideoToolbox
internal import Combine

class MirroringManager: NSObject {
    static let shared = MirroringManager()

    private var mirroringWindow: NSWindow?
    private var mirroringView: MirroringView?
    
    private var decompressionSession: VTDecompressionSession?
    private var videoFormatDescription: CMVideoFormatDescription?
    
    private var spsData: Data?
    private var ppsData: Data?

    private override init() {
        super.init()
    }

    func startMirroring(mode: String, resolution: String, bitrate: Int, package: String?) {
        print("[MirroringManager] Starting mirroring with mode=\(mode), resolution=\(resolution), bitrate=\(bitrate)")

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
    }

    func stopMirroring() {
        print("[MirroringManager] Stopping mirroring")
        
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
        self.spsData = nil
        self.ppsData = nil
    }

    func handleVideoFrame(data: Data) {
        let frameBytes = [UInt8](data)
        let startCode: [UInt8] = [0, 0, 0, 1]
        
        var searchIndex = 0
        while searchIndex < frameBytes.count {
            guard let nextStartCodeIndex = frameBytes[searchIndex...].firstRange(of: startCode)?.lowerBound else {
                // No more start codes
                break
            }
            
            let nalUnitStartIndex = nextStartCodeIndex + startCode.count
            var nalUnitEndIndex = frameBytes.count
            
            if let subsequentStartCodeIndex = frameBytes[nalUnitStartIndex...].firstRange(of: startCode)?.lowerBound {
                nalUnitEndIndex = subsequentStartCodeIndex
            }
            
            let nalUnitBytes = Data(frameBytes[nalUnitStartIndex..<nalUnitEndIndex])
            let nalType = nalUnitBytes[0] & 0x1F
            
            switch nalType {
            case 7: // SPS
                spsData = nalUnitBytes
                if let pps = ppsData {
                    createDecompressionSession(sps: nalUnitBytes, pps: pps)
                }
            case 8: // PPS
                ppsData = nalUnitBytes
                if let sps = spsData {
                    createDecompressionSession(sps: sps, pps: nalUnitBytes)
                }
            case 5: // IDR frame
                decodeFrame(nalUnit: nalUnitBytes, isSync: true)
            case 1: // Non-IDR frame
                decodeFrame(nalUnit: nalUnitBytes, isSync: false)
            default:
                break
            }
            
            searchIndex = nalUnitEndIndex
        }
    }

    private func createDecompressionSession(sps: Data, pps: Data) {
        guard videoFormatDescription == nil else { return }
        
        sps.withUnsafeBytes { spsBytes in
            pps.withUnsafeBytes { ppsBytes in
                guard let spsPtr = spsBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                      let ppsPtr = ppsBytes.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                    return
                }

                let parameterSetPointers: [UnsafePointer<UInt8>] = [spsPtr, ppsPtr]
                let parameterSetSizes: [Int] = [sps.count, pps.count]

                let status: OSStatus = parameterSetPointers.withUnsafeBufferPointer { ptrs in
                    parameterSetSizes.withUnsafeBufferPointer { sizes in
                        CMVideoFormatDescriptionCreateFromH264ParameterSets(
                            allocator: kCFAllocatorDefault,
                            parameterSetCount: 2,
                            parameterSetPointers: ptrs.baseAddress!,
                            parameterSetSizes: sizes.baseAddress!,
                            nalUnitHeaderLength: 4,
                            formatDescriptionOut: &videoFormatDescription
                        )
                    }
                }

                if status == noErr, let format = videoFormatDescription {
                    var session: VTDecompressionSession?
                    let decoderParameters = [:] as CFDictionary
                    var outputCallback = VTDecompressionOutputCallbackRecord(decompressionOutputCallback: { (decompressionOutputRefCon, sourceFrameRefCon, status, infoFlags, imageBuffer, presentationTimeStamp, duration) in
                        guard let manager = decompressionOutputRefCon.map({ Unmanaged<MirroringManager>.fromOpaque($0).takeUnretainedValue() }) else { return }
                        if status == noErr, let imageBuffer = imageBuffer {
                            var timingInfo = CMSampleTimingInfo(duration: duration, presentationTimeStamp: presentationTimeStamp, decodeTimeStamp: .invalid)
                            var sampleBuffer: CMSampleBuffer?
                            guard let format = manager.videoFormatDescription else { return }
                            CMSampleBufferCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: imageBuffer, dataReady: true, makeDataReadyCallback: nil, refcon: nil, formatDescription: format, sampleTiming: &timingInfo, sampleBufferOut: &sampleBuffer)

                            if let sampleBuffer = sampleBuffer {
                                DispatchQueue.main.async {
                                    manager.mirroringView?.enqueue(sampleBuffer)
                                }
                            }
                        }
                    }, decompressionOutputRefCon: Unmanaged.passUnretained(self).toOpaque())

                    VTDecompressionSessionCreate(allocator: kCFAllocatorDefault, formatDescription: format, decoderSpecification: decoderParameters, imageBufferAttributes: nil, outputCallback: &outputCallback, decompressionSessionOut: &session)
                    self.decompressionSession = session
                }
            }
        }
    }
    
    private func decodeFrame(nalUnit: Data, isSync: Bool) {
        guard let session = decompressionSession, let format = videoFormatDescription else { return }
        
        var blockBuffer: CMBlockBuffer?
        let status = nalUnit.withUnsafeBytes { (body: UnsafeRawBufferPointer) -> OSStatus in
            CMBlockBufferCreateWithMemoryBlock(
                allocator: kCFAllocatorDefault,
                memoryBlock: UnsafeMutableRawPointer(mutating: body.baseAddress!),
                blockLength: nalUnit.count,
                blockAllocator: kCFAllocatorNull,
                customBlockSource: nil,
                offsetToData: 0,
                dataLength: nalUnit.count,
                flags: 0,
                blockBufferOut: &blockBuffer
            )
        }
        
        if status == kCMBlockBufferNoErr, let buffer = blockBuffer {
            var sampleBuffer: CMSampleBuffer?
            let sampleSize = nalUnit.count
            
            CMSampleBufferCreate(
                allocator: kCFAllocatorDefault,
                dataBuffer: buffer,
                dataReady: true,
                makeDataReadyCallback: nil,
                refcon: nil,
                formatDescription: format,
                sampleCount: 1,
                sampleTimingEntryCount: 0,
                sampleTimingArray: nil,
                sampleSizeEntryCount: 1,
                sampleSizeArray: [sampleSize],
                sampleBufferOut: &sampleBuffer
            )
            
            if let sampleBuffer = sampleBuffer {
                let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: true)!
                let dict = unsafeBitCast(CFArrayGetValueAtIndex(attachments, 0), to: CFMutableDictionary.self)
                CFDictionarySetValue(dict, Unmanaged.passUnretained(kCMSampleAttachmentKey_DisplayImmediately).toOpaque(), Unmanaged.passUnretained(kCFBooleanTrue).toOpaque())
                
                var infoFlags: VTDecodeInfoFlags = []
                let decodeStatus = VTDecompressionSessionDecodeFrame(session, sampleBuffer: sampleBuffer, flags: [], frameRefcon: nil, infoFlagsOut: &infoFlags)
                
                if decodeStatus != noErr {
                    print("[MirroringManager] Decode failed: \(decodeStatus)")
                }
            }
        }
    }
}
