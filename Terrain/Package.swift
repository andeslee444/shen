// swift-tools-version: 5.9
// This Package.swift is for SPM compatibility during development
// The main Xcode project should be used for iOS builds

import PackageDescription

let package = Package(
    name: "Terrain",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Terrain",
            targets: ["Terrain"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Terrain",
            dependencies: [],
            path: ".",
            exclude: [
                "Resources",
                "Tests",
                "App/TerrainApp.swift"  // Exclude @main entry point for library builds
            ],
            sources: [
                "App",
                "Core",
                "Features",
                "DesignSystem"
            ]
        ),
        .testTarget(
            name: "TerrainTests",
            dependencies: ["Terrain"],
            path: "Tests"
        ),
    ]
)
