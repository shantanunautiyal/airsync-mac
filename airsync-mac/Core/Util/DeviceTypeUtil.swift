import Foundation

enum DeviceTypeUtil {
    static func modelIdentifier() -> String {
        var size: size_t = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: Int(size))
        sysctlbyname("hw.model", &model, &size, nil, 0)
        return String(cString: model)
    }

    static func deviceTypeDescription() -> String {
        let identifier = modelIdentifier()
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
}
