//
//  LocalizedString.swift
//  Terrain
//
//  Localized string support for multi-language content
//

import Foundation
import SwiftData

/// A dictionary-like structure for storing localized strings
/// Keys are BCP-47 locale codes (e.g., "en-US", "zh-CN")
struct LocalizedString: Codable, Hashable {
    private var values: [String: String]

    init(_ values: [String: String] = [:]) {
        self.values = values
    }

    init(english: String) {
        self.values = ["en-US": english]
    }

    subscript(locale: String) -> String? {
        get { values[locale] }
        set { values[locale] = newValue }
    }

    /// Returns the localized string for the current locale, falling back to en-US
    var localized: String {
        let currentLocale = Locale.current.identifier.replacingOccurrences(of: "_", with: "-")

        // Try exact match first
        if let value = values[currentLocale] {
            return value
        }

        // Try language only (e.g., "en" from "en-US")
        let language = String(currentLocale.prefix(2))
        for (key, value) in values {
            if key.hasPrefix(language) {
                return value
            }
        }

        // Fall back to en-US
        return values["en-US"] ?? values.values.first ?? ""
    }

    var isEmpty: Bool {
        values.isEmpty || values.values.allSatisfy { $0.isEmpty }
    }
}

extension LocalizedString: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        self.values = ["en-US": value]
    }
}

extension LocalizedString: CustomStringConvertible {
    var description: String {
        localized
    }
}
