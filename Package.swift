// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Boo",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Boo",
            path: "Sources/Boo"
        )
    ]
)
