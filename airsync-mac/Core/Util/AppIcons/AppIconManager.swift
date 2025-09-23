//
//  AppIconManager.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2025-09-20.
//

import Foundation
internal import Combine
import AppKit

class AppIconManager: ObservableObject {
    @Published var currentIcon: AppIcon = .defaultIcon

    init() {
        // Listen for license status changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(licenseStatusChanged),
            name: NSNotification.Name("LicenseStatusChanged"),
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func licenseStatusChanged() {
        DispatchQueue.main.async {
            self.revertToDefaultIfNeeded()
        }
    }

    func setIcon(_ icon: AppIcon) {
        currentIcon = icon
        UserDefaults.standard.set(icon.iconName, forKey: "selectedAppIcon")
        print("[app-icon-manager] App icon preference set to: \(icon.name)")

        // Actually change the app icon at runtime
        DispatchQueue.main.async {
            self.updateAppIcon(for: icon)
        }
    }

    private func updateAppIcon(for icon: AppIcon) {
        let iconName = icon.iconName ?? "AppIconImage"

        // For macOS apps, try different approaches to load the image
        var nsImage: NSImage?

        // Method 1: Try NSImage(named:) from asset catalog
        nsImage = NSImage(named: iconName)

        // Method 2: If that fails, try loading from bundle resources
        if nsImage == nil {
            if let imagePath = Bundle.main.path(forResource: iconName, ofType: "png") {
                nsImage = NSImage(contentsOfFile: imagePath)
            }
        }

        // Method 3: Try with different file extensions
        if nsImage == nil {
            for ext in ["png", "jpg", "jpeg", "icns"] {
                if let imagePath = Bundle.main.path(forResource: iconName, ofType: ext) {
                    nsImage = NSImage(contentsOfFile: imagePath)
                    if nsImage != nil { break }
                }
            }
        }

        // Method 4: Create from SwiftUI Image (convert to NSImage)
        if nsImage == nil {
            // Try to get a large version from the asset catalog
            if iconName == "AppIconImage" {
                nsImage = NSImage(named: "AppIconImage")
            } else if iconName == "AppIconImage-p9-10" {
                nsImage = NSImage(named: "AppIconImage-p9-10")
            }
        }

        // Set the app icon if we successfully loaded an image
        if let nsImage = nsImage {
            DispatchQueue.main.async {
                NSApplication.shared.applicationIconImage = nsImage
            }
            print("[app-icon-manager] Successfully changed app icon to: \(icon.name) using \(iconName)")
        } else {
            print("[app-icon-manager] Could not load app icon: \(iconName)")
            // List available named images for debugging
            print("[app-icon-manager] Trying to debug available images...")

            // Try some common fallback names
            let fallbackNames = ["AppIconImage", "AppIcon", "app", "icon"]
            for name in fallbackNames {
                if NSImage(named: name) != nil {
                    print("[app-icon-manager] Found available image: \(name)")
                    DispatchQueue.main.async {
                        NSApplication.shared.applicationIconImage = NSImage(named: name)
                    }
                    return
                }
            }
        }
    }

    func loadCurrentIcon() {
        if let savedIconName = UserDefaults.standard.string(forKey: "selectedAppIcon") {
            let savedIcon = AppIcon.allIcons.first { $0.iconName == savedIconName } ?? .defaultIcon

            // If the saved icon is not default and user doesn't have Plus, revert to default
            let isPlus = UserDefaults.standard.bool(forKey: "isPlus")
            if !savedIcon.isDefault && !isPlus {
                print("[app-icon-manager] Reverting to default icon - Plus required for custom icons")
                currentIcon = .defaultIcon
                UserDefaults.standard.set(AppIcon.defaultIcon.iconName, forKey: "selectedAppIcon")
                updateAppIcon(for: .defaultIcon)
                return
            }

            currentIcon = savedIcon
            // Apply the saved icon
            updateAppIcon(for: currentIcon)
        }
    }

    func revertToDefaultIfNeeded() {
        // Check if current icon is not default and user doesn't have Plus
        let isPlus = UserDefaults.standard.bool(forKey: "isPlus")
        if !currentIcon.isDefault && !isPlus {
            print("[app-icon-manager] Reverting to default icon - license check failed")
            currentIcon = .defaultIcon
            UserDefaults.standard.set(AppIcon.defaultIcon.iconName, forKey: "selectedAppIcon")
            updateAppIcon(for: .defaultIcon)
        }
    }
}
