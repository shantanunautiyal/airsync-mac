//
//  GetLocalIPAddress.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-30.
//

import Foundation

func getLocalIPAddress() -> String? {
    var address: String?
    var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil

    if getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr {
        var ptr = firstAddr
        while ptr.pointee.ifa_next != nil {
            defer { ptr = ptr.pointee.ifa_next! }

            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family

            if addrFamily == UInt8(AF_INET),
               let name = String(validatingUTF8: interface.ifa_name),
               name == "en0" // Wi-Fi on macOS
            {
                var addr = interface.ifa_addr.pointee
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(&addr,
                            socklen_t(interface.ifa_addr.pointee.sa_len),
                            &hostname,
                            socklen_t(hostname.count),
                            nil,
                            0,
                            NI_NUMERICHOST)
                address = String(cString: hostname)
                break
            }
        }
    }

    freeifaddrs(ifaddr)
    return address
}
