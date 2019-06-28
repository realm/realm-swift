// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "SwiftPMExample",
    dependencies: [
        .package(path: "../../.."),
    ],
    targets: [
        .target(
            name: "SwiftPMExample",
            dependencies: ["RealmSwift"]),
        .testTarget(
            name: "SwiftPMExampleTests",
            dependencies: ["SwiftPMExample"]),
    ]
)
