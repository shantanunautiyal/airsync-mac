//
//  AnimatedAppIconCarousel.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2025-09-19.
//

import SwiftUI

struct AnimatedAppIconCarousel: View {
    @State private var currentIconIndex = 0
    @State private var timer: Timer?
    @State private var isAnimating = false
    
    let iconSize: CGFloat
    let cornerRadius: CGFloat
    
    init(iconSize: CGFloat = 140, cornerRadius: CGFloat = 24) {
        self.iconSize = iconSize
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        ZStack {
            ForEach(0..<AppIcon.allIcons.count, id: \.self) { index in
                let icon = AppIcon.allIcons[index]
                icon.image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: iconSize, height: iconSize)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
                    .opacity(index == currentIconIndex ? 1.0 : 0.0)
                    .blur(radius: index == currentIconIndex ? 0 : 15)
                    .scaleEffect(index == currentIconIndex ? 1.0 : 0.85)
                    .animation(.easeInOut(duration: 0.8), value: currentIconIndex)
            }
        }
        .onAppear {
            startCarousel()
        }
        .onDisappear {
            stopCarousel()
        }
    }
    
    private func startCarousel() {
        // Start after a brief delay to let the view settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.8)) {
                    currentIconIndex = (currentIconIndex + 1) % AppIcon.allIcons.count
                }
            }
        }
    }
    
    private func stopCarousel() {
        timer?.invalidate()
        timer = nil
    }
    
    func pauseCarousel() {
        stopCarousel()
    }
    
    func resumeCarousel() {
        if timer == nil {
            startCarousel()
        }
    }
}

#Preview {
    AnimatedAppIconCarousel()
        .frame(width: 200, height: 200)
        .background(Color.gray.opacity(0.1))
}
