// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DdayApp",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "DdayApp",
            path: "Sources/DdayApp"
        )
    ]
)
