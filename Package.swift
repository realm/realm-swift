// swift-tools-version:4.2
import PackageDescription

let package = Package(
    name: "Realm",
    products: [
        .library(name: "Realm", targets: ["Realm"])
        .library(name: "RealmSwift", targets: ["RealmSwift"])
    ],
    targets: [
        .target(
            name: "Realm",
            path: "Realm"
        ),
        .target(
            name: "RealmSwift",
            dependencies: ["Realm"],
            path: "RealmSwift"
        ),
    ]
)
