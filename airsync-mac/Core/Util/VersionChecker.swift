//
//  VersionChecker.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2025-08-03.
//

import Foundation

func isVersion(_ version: String, lessThan minVersion: String) -> Bool {
    let numbers1 = version.split(separator: "-")[0]
        .split(separator: ".")
        .compactMap { Int($0) }

    let numbers2 = minVersion.split(separator: "-")[0]
        .split(separator: ".")
        .compactMap { Int($0) }

    for (v1, v2) in zip(numbers1, numbers2) {
        if v1 < v2 { return true }
        if v1 > v2 { return false }
    }

    return numbers1.count < numbers2.count
}

