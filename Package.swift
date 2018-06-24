// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var realmTargetExclude = [
    "ObjectServerTests",
    "ObjectStore/tests",
    "Swift",
    "Tests",
    "ObjectStore/src/placeholder.cpp",
    "ObjectStore/src/impl/windows",
    "ObjectStore/src/impl/generic",
    "ObjectStore/src/util/generic",
]
#if os(Linux)
realmTargetExclude.append("ObjectStore/src/impl/apple")
realmTargetExclude.append("ObjectStore/src/sync/impl/apple")
#else
realmTargetExclude.append("ObjectStore/src/impl/epoll")
#endif

let package = Package(
    name: "RealmSwift",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "Realm",
            targets: ["Realm"]),
        .library(
            name: "RealmSwift",
            targets: ["RealmSwift", "Realm"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Realm",
            dependencies: [],
            exclude: realmTargetExclude
        ),
        .target(
            name: "RealmSwift",
            dependencies: ["Realm"],
            exclude: [
                "Tests",
            ]
        ),
    ],
    cxxLanguageStandard: .cxx14
)
