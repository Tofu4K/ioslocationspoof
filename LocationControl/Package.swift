// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LocationControl",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "LocationControlCore",
            targets: ["LocationControlCore"]
        ),
        .executable(
            name: "LocationControlApp",
            targets: ["LocationControlApp"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "LocationControlCore",
            dependencies: [],
            path: "Sources/LocationControlCore"
        ),
        .executableTarget(
            name: "LocationControlApp",
            dependencies: ["LocationControlCore"],
            path: "Sources/LocationControlApp"
        ),
        .testTarget(
            name: "LocationControlTests",
            dependencies: ["LocationControlCore"],
            path: "Tests"
        )
    ]
)
