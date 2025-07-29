//
//  Device.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-28.
//

import Foundation

struct Device: Hashable, Identifiable, Codable{
    var id = UUID()

    let name: String
    let ipAddress: String
    let port: Int

}

struct MockData{
    static let sampleDevice = Device(name: "Test Device", ipAddress: "192.168.1.100", port: 8080)

    static let sampleDevices = [
        Device(name: "Test Device 1", ipAddress: "192.168.1.101", port: 8080),
        Device(name: "Test Device 2", ipAddress: "192.168.1.102", port: 8080),
        Device(name: "Test Device 3", ipAddress: "192.168.1.103", port: 8080)
    ]
}
