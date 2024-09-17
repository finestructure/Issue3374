// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Issue3374",
    products: [],
    dependencies: [
        .package(url: "https://github.com/SwiftPackageIndex/ShellOut.git", from: "3.1.3"),
    ],
    targets: [
        .testTarget(
            name: "Issue3374Tests",
            dependencies: ["ShellOut"]
        ),
    ]
)
