//
//  Gumroad.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-31.
//

import GumroadLicenseValidator

func checkLicenseKeyValidity(key: String) async throws -> Bool {
    // Allow test bypass
    if key == "i-am-a-tester" {
        AppState.shared.setPlusTemporarily(true)
        return true
    }


    let client = GumroadClient(productPermalink: "your product permalink")
    let isValid = await client?.isLicenseKeyValid(key) ?? false
    AppState.shared.isPlus = isValid
    return isValid
}
