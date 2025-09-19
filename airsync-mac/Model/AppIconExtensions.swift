import SwiftUI
import AppKit
import UserNotifications
internal import Combine

// Custom implementation for app icon switching for macOS
struct AppIcon: Identifiable {
    let id = UUID()
    let name: String
    let image: Image
    let iconName: String?
    
    static let defaultIcon = AppIcon(
        name: "AirSync",
        image: Image("AppIconImage"),
        iconName: "AppIconImage"
    )
    
    static let p9Plus10 = AppIcon(
        name: "Google Pixel 9, 10",
        image: Image("AppIconImage-p9-10"),
        iconName: "AppIconImage-p9-10"
    )
    
    static let allIcons = [defaultIcon, p9Plus10]
}

// Simple app icon switching functionality for macOS
class AppIconManager: ObservableObject {
    @Published var currentIcon: AppIcon = .defaultIcon
    
    func setIcon(_ icon: AppIcon) {
        currentIcon = icon
        UserDefaults.standard.set(icon.iconName, forKey: "selectedAppIcon")
        print("App icon preference set to: \(icon.name)")
        
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
            print("Successfully changed app icon to: \(icon.name) using \(iconName)")
        } else {
            print("Could not load app icon: \(iconName)")
            // List available named images for debugging
            print("Trying to debug available images...")
            
            // Try some common fallback names
            let fallbackNames = ["AppIconImage", "AppIcon", "app", "icon"]
            for name in fallbackNames {
                if NSImage(named: name) != nil {
                    print("Found available image: \(name)")
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
            currentIcon = AppIcon.allIcons.first { $0.iconName == savedIconName } ?? .defaultIcon
            // Apply the saved icon
            updateAppIcon(for: currentIcon)
        }
    }
}
