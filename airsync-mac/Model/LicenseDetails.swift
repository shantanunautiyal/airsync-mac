//
//  LicenseDetails.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-31.
//

struct LicenseDetails: Equatable, Codable {
    let key: String
    let email: String
    let productName: String
    let orderNumber: Int
    let purchaserID: String

    // Additional fields from Gumroad
    let usesCount: Int
    let price: Int
    let currency: String
    let saleTimestamp: String
    let subscriptionCancelledAt: String?
    let subscriptionEndedAt: String?
    let subscriptionFailedAt: String?
    let refunded: Bool
    let disputed: Bool
    let chargebacked: Bool
}
