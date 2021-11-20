// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "estates-checker",
    products: [
        .executable(
            name: "EstatesChecker",
            targets: ["App"]),
        .library(
            name: "ComposableArchitecture",
            targets: ["ComposableArchitecture"]),
        .library(
            name: "CLI",
            targets: ["CLI"]),
        .library(
            name: "EstatesProvider",
            targets: ["EstatesProvider"]),
        .library(
            name: "Notifications",
            targets: ["Notifications"]),
        .library(
            name: "Storage",
            targets: ["Storage"]),
        .library(
            name: "Networking",
            targets: ["Networking"]),
        .library(
            name: "Persistence",
            targets: ["Persistence"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.0.5"),
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                "ComposableArchitecture",
                "CLI",
                "EstatesProvider",
                "Notifications",
                "Persistence"
            ],
            path: "Sources/App"
        ),
        .target(
            name: "ComposableArchitecture",
            dependencies: [],
            path: "Sources/ComposableArchitecture"
        ),
        .target(
            name: "CLI",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "ComposableArchitecture",
                "Notifications",
                "Storage",
                "EstatesProvider",
            ],
            path: "Sources/CLI"
        ),
        .target(
            name: "EstatesProvider",
            dependencies: [
                "Networking",
            ],
            path: "Sources/EstatesProvider"
        ),
        .target(
            name: "Notifications",
            dependencies: [
                "ComposableArchitecture",
                "Networking",
            ],
            path: "Sources/Services/Notifications"
        ),
        .target(
            name: "Storage",
            dependencies: ["ComposableArchitecture"],
            path: "Sources/Services/Storage"
        ),
        .target(
            name: "Networking",
            dependencies: ["ComposableArchitecture"],
            path: "Sources/Networking"
        ),
        .target(
            name: "Persistence",
            dependencies: ["ComposableArchitecture", "Storage", "EstatesProvider", "Notifications"],
            path: "Sources/Persistence"
        ),
    ]
)
