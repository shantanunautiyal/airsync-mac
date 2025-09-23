import Foundation

enum DeviceTypeUtil {
    private static var deviceMappings: [String: [String: String]] = {
        guard let url = Bundle.main.url(forResource: "MacDeviceMappings", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: [String: String]] else {
            return [:]
        }
        return json
    }()

    static func modelIdentifier() -> String {
        var size: size_t = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: Int(size))
        sysctlbyname("hw.model", &model, &size, nil, 0)
        return String(cString: model)
    }

    static func deviceTypeDescription() -> String {
        let identifier = modelIdentifier()
        for (category, models) in deviceMappings {
            if models.keys.contains(identifier) {
                return category
            }
        }
        // Fallback to generic names
        if identifier.starts(with: "MacBookPro") {
            return "MacBook Pro"
        } else if identifier.starts(with: "MacBookAir") {
            return "MacBook Air"
        } else if identifier.starts(with: "Macmini") {
            return "Mac mini"
        } else if identifier.starts(with: "iMac") {
            return "iMac"
        } else if identifier.starts(with: "MacStudio") {
            return "Mac Studio"
        } else if identifier.starts(with: "MacPro") {
            return "Mac Pro"
        } else {
            return identifier // fallback to raw model id
        }
    }

    static func deviceFullDescription() -> String {
        let identifier = modelIdentifier()
        for (_, models) in deviceMappings {
            if let name = models[identifier] {
                return name
            }
        }
        // Fallback to major type
        return deviceTypeDescription()
    }

    static func deviceIconName() -> String {
        let identifier = modelIdentifier()
        // First, look for an explicit per-model icon key in any category
        for (_, models) in deviceMappings {
            if let icon = models["\(identifier)_icon"] { // e.g., "MacBookPro18,1_icon"
                return icon
            }
        }
        // Next, use category-based defaults
        let type = deviceTypeDescription()
        switch type {
        case "MacBook Pro", "MacBook Air":
            return "macbook"
        case "Mac mini":
            return "macmini"
        case "iMac":
            return "desktopcomputer"
        case "Mac Studio":
            return "macstudio"
        case "Mac Pro":
            return "macpro.gen3"
        default:
            return "desktopcomputer"
        }
    }
}
