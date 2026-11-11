// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "Tuckbar",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Tuckbar",
            path: "Sources/Tuckbar",
            linkerSettings: [.linkedFramework("Carbon")]
        )
    ]
)
