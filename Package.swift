// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "IShowSpeed",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "IShowSpeed", targets: ["IShowSpeed"])
    ],
    targets: [
        .executableTarget(
            name: "IShowSpeed"
        ),
        .testTarget(
            name: "IShowSpeedTests",
            dependencies: ["IShowSpeed"]
        )
    ]
)
