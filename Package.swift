// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CatVodPlayer",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "CatVodPlayer",
            targets: ["CatVodPlayer"]),
    ],
    dependencies: [
        // VLCKit
        .package(url: "https://code.videolan.org/videolan/VLCKit.git", from: "3.6.0"),
    ],
    targets: [
        .target(
            name: "CatVodPlayer",
            dependencies: [
                .product(name: "VLCKit", package: "VLCKit")
            ],
            path: "Sources"),
    ]
)
