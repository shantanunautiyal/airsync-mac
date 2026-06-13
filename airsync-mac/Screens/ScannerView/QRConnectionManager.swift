//
//  QRConnectionManager.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2026-05-19.
//

import SwiftUI
internal import Combine
import QRCode
import LocalAuthentication

class QRConnectionManager: ObservableObject {
    static let shared = QRConnectionManager()
    
    @Published var qrImage: CGImage?
    @Published var isUnlocked = false
    @Published var hasValidIP = true
    @Published var copyStatus: String?
    @Published var showConfirmReset = false
    
    @Published var isAuthenticating = false
    
    private var unlockTimer: Timer?
    
    func generateQRAsync() {
        let ip = WebSocketServer.shared
            .getLocalIPAddress(
                adapterName: AppState.shared.selectedNetworkAdapterName
            )

        // Check if we have a valid IP address
        guard let validIP = ip else {
            DispatchQueue.main.async {
                self.hasValidIP = false
                self.qrImage = nil
            }
            return
        }

        // If we have a valid IP, proceed with QR generation
        DispatchQueue.main.async {
            self.hasValidIP = true
            self.qrImage = nil // Reset to show progress view
        }

        let text = generateQRText(
            ip: validIP,
            port: UInt16(AppState.shared.myDevice?.port ?? Int(Defaults.serverPort)),
            name: AppState.shared.myDevice?.name,
            key: WebSocketServer.shared.getSymmetricKeyBase64() ?? ""
        ) ?? "That doesn't look right, QR Generation failed"

        Task {
            if let cgImage = await QRCodeGenerator.generateQRCode(for: text) {
                DispatchQueue.main.async {
                    self.qrImage = cgImage
                }
            }
        }
    }
    
    func authenticateUser() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            DispatchQueue.main.async {
                self.isAuthenticating = true
            }
            let reason = "Authenticate to reveal connection credentials"
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { [weak self] success, authenticationError in
                guard let self = self else { return }
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.isAuthenticating = false
                    if success {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            self.isUnlocked = true
                        }
                        
                        self.unlockTimer?.invalidate()
                        self.unlockTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: false) { [weak self] _ in
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                self?.isUnlocked = false
                            }
                        }
                    }
                }
            }
        } else {
            // Fallback if no auth policy is available
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                self.isUnlocked = true
            }
            self.unlockTimer?.invalidate()
            self.unlockTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: false) { [weak self] _ in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    self?.isUnlocked = false
                }
            }
        }
    }
    
    func cleanUpTimer() {
        unlockTimer?.invalidate()
        unlockTimer = nil
    }
    
    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        withAnimation {
            copyStatus = "Copied! Keep it safe"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                self.copyStatus = nil
            }
        }
    }
}
