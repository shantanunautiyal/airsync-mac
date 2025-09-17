//
//  TimeView.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-28.
//

import SwiftUI
internal import Combine
import CoreText

// MARK: - CoreText -> Path helper (macOS-safe)
private struct TextHelper {
    private init() { }

    static func path(for string: NSAttributedString) -> Path {
        let line = CTLineCreateWithAttributedString(string)
        let runs = CTLineGetGlyphRuns(line) as NSArray

        let outputPath = CGMutablePath()

        for i in 0..<CFArrayGetCount(runs) {
            let run = unsafeBitCast(CFArrayGetValueAtIndex(runs, i), to: CTRun.self)
            let attributes = CTRunGetAttributes(run) as NSDictionary

            let key = kCTFontAttributeName as NSAttributedString.Key
            guard let anyCTFont = attributes[key] else {
                print("[LiquidGlassText] Missing font attribute in run attributes: \(attributes)")
                continue
            }
            let ctFont = anyCTFont as! CTFont

            let glyphCount = CTRunGetGlyphCount(run)
            var glyphs = [CGGlyph](repeating: 0, count: glyphCount)
            var positions = [CGPoint](repeating: .zero, count: glyphCount)

            CTRunGetGlyphs(run, CFRangeMake(0, 0), &glyphs)
            CTRunGetPositions(run, CFRangeMake(0, 0), &positions)

            for j in 0..<glyphCount {
                if let glyphPath = CTFontCreatePathForGlyph(ctFont, glyphs[j], nil) {
                    let position = positions[j]
                    let transform = CGAffineTransform(translationX: position.x, y: position.y)
                    outputPath.addPath(glyphPath, transform: transform)
                }
            }
        }

        let swiftUIPath = Path(outputPath)
        let bounds = swiftUIPath.boundingRect
        // Flip vertically within the bounds
        let flipped = swiftUIPath
            .applying(CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -bounds.height))
        return flipped
    }
}

// MARK: - Rounded font helper
private func roundedFont(ofSize size: CGFloat, weight: NSFont.Weight) -> NSFont {
    // Try common SF Rounded faces; fall back to system if not available
    let candidates = [
        "SF Pro Rounded Black",
        "SF Pro Display Rounded Black",
        "SF Pro Text Rounded Black"
    ]
    for name in candidates {
        if let f = NSFont(name: name, size: size) {
            // Return the rounded face directly; weight adjustments are limited for named fonts
            return f
        }
    }
    // Fallback to system font with requested weight
    return NSFont.systemFont(ofSize: size, weight: weight)
}

// MARK: - LiquidGlassText (flat, rounded)
private struct LiquidGlassText: View {
    private let string: NSAttributedString

    init(_ string: NSAttributedString) {
        self.string = string
    }

    init(_ text: String, font: NSFont) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font
        ]
        self.string = NSAttributedString(string: text, attributes: attrs)
    }

    var body: some View {
        let path = TextHelper.path(for: string)
        let bounds = path.boundingRect

        // Flat look: apply clear glass to the raw glyph path (no stroke/emboss)
        Color.clear
            .frame(width: bounds.width, height: bounds.height, alignment: .center)
            .overlay(
                Group {
                    if !UIStyle.pretendOlderOS, #available(macOS 26.0, *) {
                        Color.clear
                            .glassEffect(in: path)
                    } else {
                        Color.clear
                    }
                }
            )
            .accessibilityHidden(true)
    }
}

struct TimeView: View {
    @State private var currentDate = Date()

    // Timer that updates every second
    private let timer = Timer
        .publish(every: 1, on: .main, in: .common)
        .autoconnect()

    var body: some View {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: currentDate)

        let is24Hour = isSystemUsing24Hour()
        let hourValue = components.hour ?? 0
        let displayHour = is24Hour ? hourValue : (hourValue % 12 == 0 ? 12 : hourValue % 12)
        let hour = String(format: "%02d", displayHour)
        let minute = String(format: "%02d", components.minute ?? 0)

        // Desired size and weight
        let fontSize: CGFloat = 75
        // Keep the on-screen Text fallback as medium rounded
        let fallbackWeight: Font.Weight = .light
        // Use a rounded NSFont for the liquid glass path
        let roundedNSFont = roundedFont(ofSize: fontSize, weight: .black)

        HStack{
            if !UIStyle.pretendOlderOS, #available(macOS 26.0, *) {
                VStack(spacing: 5) {
                    // Liquid glass (flat, rounded)
                    LiquidGlassText(hour, font: roundedNSFont)
                    LiquidGlassText(minute, font: roundedNSFont)
                }
            } else {
                VStack(spacing: -20) {
                    // Fallback to existing view (rounded design already specified)
                    Text(hour)
                    Text(minute)
                }
            }
        }
        .font(.system(size: fontSize, weight: fallbackWeight, design: .rounded))
        .onReceive(timer) { newValue in
            currentDate = newValue
        }
        .foregroundColor(.white)
//        .shadow(radius: 10)
    }

    // Detect if system uses 24-hour time
    private func isSystemUsing24Hour() -> Bool {
        let formatString = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: Locale.current) ?? ""
        return !formatString.contains("a")
    }
}

#Preview {
    TimeView()
}
