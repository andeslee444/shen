//
//  MediaAsset.swift
//  Terrain
//
//  Media asset reference for images, videos, and animations
//

import Foundation

/// Type of media asset
enum MediaType: String, Codable {
    case image
    case video
    case lottie
    case svg
}

/// A reference to a media asset (image, video, animation)
struct MediaAsset: Codable, Hashable, Identifiable {
    var id: String { uri }

    let type: MediaType
    let uri: String
    var alt: LocalizedString?
    var credit: LocalizedString?

    init(type: MediaType, uri: String, alt: LocalizedString? = nil, credit: LocalizedString? = nil) {
        self.type = type
        self.uri = uri
        self.alt = alt
        self.credit = credit
    }

    /// Returns the URL for loading the asset
    var url: URL? {
        if uri.hasPrefix("http://") || uri.hasPrefix("https://") {
            return URL(string: uri)
        } else {
            return Bundle.main.url(forResource: uri, withExtension: nil)
        }
    }

    /// Whether this is a bundled asset vs remote
    var isBundled: Bool {
        !uri.hasPrefix("http://") && !uri.hasPrefix("https://")
    }
}

/// Placeholder assets for development
extension MediaAsset {
    static func placeholder(type: MediaType = .image) -> MediaAsset {
        MediaAsset(
            type: type,
            uri: "placeholder",
            alt: LocalizedString(english: "Placeholder image")
        )
    }

    static func ingredient(_ name: String) -> MediaAsset {
        MediaAsset(
            type: .image,
            uri: "ingredients/\(name.lowercased().replacingOccurrences(of: " ", with: "_"))",
            alt: LocalizedString(english: name)
        )
    }

    static func movement(_ name: String) -> MediaAsset {
        MediaAsset(
            type: .svg,
            uri: "movements/\(name.lowercased().replacingOccurrences(of: " ", with: "_"))",
            alt: LocalizedString(english: name)
        )
    }
}
