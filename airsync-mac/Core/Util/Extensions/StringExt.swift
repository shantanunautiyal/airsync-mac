//
//  StringExt.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2025-08-01.
//

import Foundation

extension String {
    func stripBase64Prefix() -> String {
        if let range = self.range(of: "base64,") {
            return String(self[range.upperBound...])
        }
        return self
    }

    func removingApostrophesAndPossessives() -> String {
        return self.replacingOccurrences(of: "'s", with: "")
            .replacingOccurrences(of: "'", with: "")
    }
}
