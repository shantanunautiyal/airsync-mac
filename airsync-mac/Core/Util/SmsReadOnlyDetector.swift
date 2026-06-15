//
//  SmsReadOnlyDetector.swift
//  airsync-mac
//
//  Shared utility to detect if an SMS thread is read-only (company/service number)
//

import Foundation

/// Detects whether an SMS thread is from a service/company number that doesn't accept replies.
enum SmsReadOnlyDetector {
    
    /// Returns true if the thread should be treated as read-only (no reply field).
    static func isReadOnly(address: String, displayName: String, snippet: String) -> Bool {
        let cleaned = address.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 1. Alphanumeric sender IDs (e.g., "AD-PAYTM", "AMAZON", "BZ-SWIGGY")
        //    Real phone numbers only contain digits, +, -, spaces, parentheses.
        //    If the address contains any letters, it's a service/company sender.
        let digitsAndSymbols = CharacterSet(charactersIn: "0123456789+-() ")
        if cleaned.unicodeScalars.contains(where: { !digitsAndSymbols.contains($0) }) {
            return true
        }
        
        // 2. Short codes (typically 3-6 digit numbers)
        let digitsOnly = cleaned.filter { $0.isNumber }
        if digitsOnly.count <= 6 && digitsOnly.count >= 3 && cleaned.allSatisfy({ $0.isNumber || $0 == " " }) {
            return true
        }
        
        // 3. Common service number prefixes
        let servicePrefixes = ["12345", "54321", "88888", "99999", "00000"]
        if servicePrefixes.contains(where: { cleaned.hasPrefix($0) }) {
            return true
        }
        
        // 4. Notification keywords in contact name
        let notificationKeywords = [
            "noreply", "no-reply", "donotreply", "do-not-reply",
            "notification", "alert", "system", "automated",
            "info", "update", "verify", "otp", "bank", "offers"
        ]
        let nameLower = displayName.lowercased()
        if notificationKeywords.contains(where: { nameLower.contains($0) }) {
            return true
        }
        
        // 5. Automated patterns in message snippet
        let snippetLower = snippet.lowercased()
        let automatedPatterns = [
            "do not reply", "don't reply", "no reply",
            "automated message", "this is an automated",
            "unsubscribe", "opt out", "opt-out",
            "verification code", "otp is", "otp:",
            "one time password"
        ]
        if automatedPatterns.contains(where: { snippetLower.contains($0) }) {
            return true
        }
        
        return false
    }
}
