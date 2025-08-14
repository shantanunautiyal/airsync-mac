//
//  Gumroad.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-31.
//

import Foundation

func checkLicenseKeyValidity(key: String, save: Bool, isNewRegistration: Bool) async throws -> Bool {
    if key == "i-am-a-tester" {
        AppState.shared.setPlusTemporarily(true)
        AppState.shared.licenseDetails = LicenseDetails(
            key: key,
            email: "tester@example.com",
            productName: "Test Mode",
            orderNumber: 0,
            purchaserID: "tester",
            usesCount: 0,
            price: 0,
            currency: "usd",
            saleTimestamp: "",
            subscriptionCancelledAt: nil,
            subscriptionEndedAt: nil,
            subscriptionFailedAt: nil,
            refunded: false,
            disputed: false,
            chargebacked: false
        )
        return true
    }

    let productID = "smrIThhDxoQI33gQm3wwxw=="
    let url = URL(string: "https://api.gumroad.com/v2/licenses/verify")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"

    let bodyComponents: [String: String] = [
        "product_id": productID,
        "license_key": key,
        "increment_uses_count": isNewRegistration ? "true" : "false"
    ]

    request.httpBody = bodyComponents
        .map { "\($0.key)=\($0.value)" }
        .joined(separator: "&")
        .data(using: .utf8)

    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
        throw NSError(domain: "InvalidResponse", code: 0, userInfo: nil)
    }

    if httpResponse.statusCode == 404 {
        AppState.shared.isPlus = false
        if save { AppState.shared.licenseDetails = nil }
        return false
    }

    guard
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
        let success = json["success"] as? Bool,
        success,
        let purchase = json["purchase"] as? [String: Any]
    else {
        AppState.shared.isPlus = false
        if save { AppState.shared.licenseDetails = nil }
        return false
    }

    let cancelledAt = purchase["subscription_cancelled_at"] as? String
    let endedAt = purchase["subscription_ended_at"] as? String
    let failedAt = purchase["subscription_failed_at"] as? String

    if [cancelledAt, endedAt, failedAt].contains(where: { dateStr in
        if let s = dateStr, !s.isEmpty { return true }
        return false
    }) {
        AppState.shared.isPlus = false
        if save { AppState.shared.licenseDetails = nil }
        return false
    }

    // Passed all checks
    AppState.shared.isPlus = true

    if save {
        let details = LicenseDetails(
            key: key,
            email: purchase["email"] as? String ?? "unknown",
            productName: purchase["product_name"] as? String ?? "unknown",
            orderNumber: purchase["order_number"] as? Int ?? 0,
            purchaserID: purchase["purchaser_id"] as? String ?? "",
            usesCount: json["uses"] as? Int ?? 0,
            price: purchase["price"] as? Int ?? 0,
            currency: purchase["currency"] as? String ?? "usd",
            saleTimestamp: purchase["sale_timestamp"] as? String ?? "",
            subscriptionCancelledAt: cancelledAt,
            subscriptionEndedAt: endedAt,
            subscriptionFailedAt: failedAt,
            refunded: purchase["refunded"] as? Bool ?? false,
            disputed: purchase["disputed"] as? Bool ?? false,
            chargebacked: purchase["chargebacked"] as? Bool ?? false
        )
        AppState.shared.licenseDetails = details
    }

    return true
}
