import Foundation
import SwiftUI

// Custom implementation for app icon switching for macOS
struct AppIcon: Identifiable {
    let id = UUID()
    let name: String
    let image: Image
    let iconName: String?
    let isDefault: Bool
    
    static let defaultIcon = AppIcon(
        name: "AirSync",
        image: Image("AppIconImage"),
        iconName: "AppIconImage",
        isDefault: true
    )
    
    static let p9Plus10 = AppIcon(
        name: "Pixel 9, 10",
        image: Image("AppIconImage-p9-10"),
        iconName: "AppIconImage-p9-10",
        isDefault: false
    )

    static let p7Plus8 = AppIcon(
        name: "Pixel 7, 8",
        image: Image("AppIconImage-p7-8"),
        iconName: "AppIconImage-p7-8",
        isDefault: false
    )

    static let p6 = AppIcon(
        name: "Pixel 6",
        image: Image("AppIconImage-p6"),
        iconName: "AppIconImage-p6",
        isDefault: false
    )

    static let s2x = AppIcon(
        name: "Galaxy S22^",
        image: Image("AppIconImage-s2x"),
        iconName: "AppIconImage-s2x",
        isDefault: false
    )

    static let s21 = AppIcon(
        name: "Galaxy S21",
        image: Image("AppIconImage-s21"),
        iconName: "AppIconImage-s21",
        isDefault: false
    )

    static let zfold = AppIcon(
        name: "Galaxy zFold",
        image: Image("AppIconImage-zfold"),
        iconName: "AppIconImage-zfold",
        isDefault: false
    )

    static let zflip = AppIcon(
        name: "Galaxy zFlip",
        image: Image("AppIconImage-zflip"),
        iconName: "AppIconImage-zflip",
        isDefault: false
    )

    static let pfold = AppIcon(
        name: "Pixel Fold",
        image: Image("AppIconImage-pfold"),
        iconName: "AppIconImage-pfold",
        isDefault: false
    )

    static let allIcons = [defaultIcon, p9Plus10, p7Plus8, p6, s2x, s21, zfold, zflip, pfold]
}
