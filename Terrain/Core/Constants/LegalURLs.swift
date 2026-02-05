//
//  LegalURLs.swift
//  Terrain
//
//  Centralized URLs for legal documents and support contact.
//  These point to the terrainhealth.app website.
//

import Foundation

enum LegalURLs {
    static let termsOfService: URL = {
        guard let url = URL(string: "https://terrainhealth.app/terms") else {
            fatalError("Invalid LegalURLs.termsOfService — check URL string")
        }
        return url
    }()

    static let privacyPolicy: URL = {
        guard let url = URL(string: "https://terrainhealth.app/privacy") else {
            fatalError("Invalid LegalURLs.privacyPolicy — check URL string")
        }
        return url
    }()

    static let support: URL = {
        guard let url = URL(string: "mailto:support@terrainhealth.app") else {
            fatalError("Invalid LegalURLs.support — check URL string")
        }
        return url
    }()
}
