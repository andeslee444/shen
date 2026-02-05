//
//  SafariView.swift
//  Terrain
//
//  UIViewControllerRepresentable wrapper for SFSafariViewController
//  Used to open legal URLs (Terms, Privacy) in an in-app browser
//

import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        let safari = SFSafariViewController(url: url, configuration: config)
        // Use the app's warm brown accent color for the toolbar tint
        safari.preferredControlTintColor = UIColor(red: 139/255, green: 115/255, blue: 85/255, alpha: 1) // #8B7355
        return safari
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed — URL is immutable after creation
    }
}
