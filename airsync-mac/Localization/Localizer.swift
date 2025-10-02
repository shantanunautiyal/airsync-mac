import Foundation
import SwiftUI
internal import Combine

/// Simple JSON-based localization loader.
/// Loads `en.json` as base and overlays with current locale file if available.
final class Localizer: ObservableObject {
    static let shared = Localizer()

    @Published private(set) var strings: [String: String] = [:]
    private var currentLocale: String = Locale.current.language.languageCode?.identifier ?? "en"

    private init() {
        load()
    }

    func load(locale: String? = nil) {
        let localeCode = locale ?? currentLocale
        var result: [String: String] = [:]

        if let base = loadJSON(named: "en") { result.merge(base) { $1 } }
        if localeCode != "en", let overlay = loadJSON(named: localeCode) { result.merge(overlay) { $1 } }
        self.strings = result
    }

    private func loadJSON(named name: String) -> [String: String]? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else { return nil }
        do {
            let data = try Data(contentsOf: url)
            let dict = try JSONDecoder().decode([String: String].self, from: data)
            return dict
        } catch {
            print("[localizer] Localization load error for \(name): \(error)")
            return nil
        }
    }

    func text(_ key: String) -> String {
        if let value = strings[key] {
            return value
        } else {
            #if DEBUG
            print("[localizer] Missing key: \(key)")
            #endif
            // Provide a readable fallback from the last path component of the key
            let fallback = key.split(separator: ".").last.map { String($0).replacingOccurrences(of: "_", with: " ") } ?? key
            return fallback.capitalized
        }
    }
}

/// Convenience SwiftUI helper
extension Text {
    init(loc key: String) { self.init(Localizer.shared.text(key)) }
}

/// Helper function
func L(_ key: String) -> String { Localizer.shared.text(key) }
