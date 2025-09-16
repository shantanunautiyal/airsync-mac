//
//  Gumroad.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-31.
//

import Foundation

// New: error type to distinguish network/server failures from invalid license results
enum LicenseCheckError: Error {
    case network(Error)           // Transport / connectivity issues (timeouts, offline, DNS, etc.)
    case server(String)           // Non-OK HTTP or malformed responses
}

func checkLicenseKeyValidity(key: String, save: Bool, isNewRegistration: Bool) async throws -> Bool {
    // Tester shortcut (kept)
    if key == "i-am-a-tester" {
        if save {
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
        }
        return true
    }

    // Select product id based on chosen plan
    let selectedPlan = UserDefaults.standard.licensePlanType
    let membershipProductID = "smrIThhDxoQI33gQm3wwxw=="
    let oneTimeProductID = "3HkBPf4ovp7KiVISJS6N5A=="
    let productID = (selectedPlan == .oneTime) ? oneTimeProductID : membershipProductID
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

    let data: Data
    let response: URLResponse
    do {
        (data, response) = try await URLSession.shared.data(for: request)
    } catch {
        // Transport / connectivity error
        throw LicenseCheckError.network(error)
    }

    guard let httpResponse = response as? HTTPURLResponse else {
        throw LicenseCheckError.server("Invalid HTTP response")
    }

    // Treat 404 as an invalid license (not a network error)
    if httpResponse.statusCode == 404 {
        if save {
            AppState.shared.isPlus = false
            AppState.shared.licenseDetails = nil
        }
        return false
    }

    // Accept only 2xx here; other codes are server-ish problems
    guard (200...299).contains(httpResponse.statusCode) else {
        throw LicenseCheckError.server("HTTP \(httpResponse.statusCode)")
    }

    // Parse JSON
    guard
        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let success = json["success"] as? Bool,
        let purchase = json["purchase"] as? [String: Any]
    else {
        throw LicenseCheckError.server("Malformed JSON")
    }

    // If Gumroad says not success => invalid license
    guard success else {
        if save {
            AppState.shared.isPlus = false
            AppState.shared.licenseDetails = nil
        }
        return false
    }

    // Subscription-only fields — for one-time purchase these may be nil/empty.
    let cancelledAt = purchase["subscription_cancelled_at"] as? String
    let endedAt = purchase["subscription_ended_at"] as? String
    let failedAt = purchase["subscription_failed_at"] as? String

    // Membership plan must be active; otherwise invalid
    if selectedPlan == .membership {
        if [cancelledAt, endedAt, failedAt].contains(where: { dateStr in
            if let s = dateStr, !s.isEmpty { return true }
            return false
        }) {
            if save {
                AppState.shared.isPlus = false
                AppState.shared.licenseDetails = nil
            }
            return false
        }
    }

    // Device limit logic — if exceeded we treat as invalid
    let currentUsesCount = json["uses"] as? Int ?? 0
    let previousUsesCount = AppState.shared.licenseDetails?.usesCount ?? currentUsesCount
    if (currentUsesCount - previousUsesCount) > 3 {
        if save {
            AppState.shared.isPlus = false
            AppState.shared.licenseDetails = nil
        }
        return false
    }

    // Valid license
    if save {
        AppState.shared.isPlus = true
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
