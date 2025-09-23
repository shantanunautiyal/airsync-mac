//
//  FadingImageView.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2025-09-20.
//

import SwiftUI

struct FadingImageView: NSViewRepresentable {
    let image: NSImage?
    let duration: TimeInterval

    func makeNSView(context: Context) -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layerContentsRedrawPolicy = .onSetNeedsDisplay
        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let layer = nsView.layer else { return }
        layer.masksToBounds = true

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        // Remove old image sublayers beyond top 2 to avoid buildup
        if let sublayers = layer.sublayers, sublayers.count > 2 {
            sublayers.dropLast(2).forEach { $0.removeFromSuperlayer() }
        }

        let newContents = image
        if let newContents, let cg = newContents.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            let newLayer = CALayer()
            newLayer.contents = cg
            newLayer.frame = layer.bounds
            newLayer.contentsGravity = .resizeAspectFill
            newLayer.opacity = 0
            layer.addSublayer(newLayer)

            let fade = CABasicAnimation(keyPath: "opacity")
            fade.fromValue = 0
            fade.toValue = 1
            fade.duration = duration
            fade.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            newLayer.add(fade, forKey: "fade")
            newLayer.opacity = 1

            // Fade out previous top layer (excluding this one)
            if let sublayers = layer.sublayers, sublayers.count > 1 {
                let previous = sublayers[sublayers.count - 2]
                let fadeOut = CABasicAnimation(keyPath: "opacity")
                fadeOut.fromValue = previous.opacity
                fadeOut.toValue = 0
                fadeOut.duration = duration
                fadeOut.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                previous.add(fadeOut, forKey: "fadeOut")
                previous.opacity = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) {
                    previous.removeFromSuperlayer()
                }
            }
        }
        CATransaction.commit()
        // Keep layer resized on parent layout changes
        DispatchQueue.main.async {
            layer.sublayers?.forEach { $0.frame = layer.bounds }
        }
    }
}
