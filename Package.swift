// swift-tools-version:5.0

import PackageDescription
import Foundation

let coreVersionStr = "5.23.5"
let cocoaVersionStr = "3.20.0"

let coreVersionPieces = coreVersionStr.split(separator: ".")
let cxxSettings: [CXXSetting] = [
    .headerSearchPath("."),
    .headerSearchPath("include"),
    .headerSearchPath("Realm/ObjectStore/src"),
    .define("REALM_SPM", to: "1"),
    .define("REALM_COCOA_VERSION", to: "@\"\(cocoaVersionStr)\""),
    .define("REALM_VERSION", to: "\"\(coreVersionStr)\""),

    .define("REALM_NO_CONFIG"),
    .define("REALM_INSTALL_LIBEXECDIR", to: ""),
    .define("REALM_ENABLE_ASSERTIONS", to: "1"),
    .define("REALM_ENABLE_ENCRYPTION", to: "1"),

    .define("REALM_VERSION_MAJOR", to: String(coreVersionPieces[0])),
    .define("REALM_VERSION_MINOR", to: String(coreVersionPieces[1])),
    .define("REALM_VERSION_PATCH", to: String(coreVersionPieces[2])),
    .define("REALM_VERSION_EXTRA", to: "\"\""),
    .define("REALM_VERSION_STRING", to: "\"\(coreVersionStr)\""),
]

let package = Package(
    name: "Realm",
    products: [
        .library(
            name: "Realm",
            targets: ["Realm"]),
        .library(
            name: "RealmSwift",
            targets: ["Realm", "RealmSwift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/realm/realm-core", .exact(Version(coreVersionStr)!)),
    ],
    targets: [
      .target(
            name: "Realm",
            dependencies: ["RealmCore"],
            path: ".",
            exclude: [
                "Realm/NSError+RLMSync.m",
                "Realm/RLMJSONModels.m",
                "Realm/RLMNetworkClient.mm",
                "Realm/RLMRealm+Sync.mm",
                "Realm/RLMRealmConfiguration+Sync.mm",
                "Realm/RLMSyncConfiguration.mm",
                "Realm/RLMSyncCredentials.m",
                "Realm/RLMSyncManager.mm",
                "Realm/RLMSyncPermission.mm",
                "Realm/RLMSyncPermissionResults.mm",
                "Realm/RLMSyncSession.mm",
                "Realm/RLMSyncSessionRefreshHandle.mm",
                "Realm/RLMSyncSubscription.mm",
                "Realm/RLMSyncUser.mm",
                "Realm/RLMSyncUtil.mm",

                "Realm/ObjectServerTests",
                "Realm/Swift",
                "Realm/Tests",
                "Realm/TestUtils",
                "Realm/ObjectStore/external",
                "Realm/ObjectStore/tests",
                "Realm/ObjectStore/src/server",
                "Realm/ObjectStore/src/sync",
                "Realm/ObjectStore/src/impl/generic",
                "Realm/ObjectStore/src/impl/epoll",
                "Realm/ObjectStore/src/impl/android",
                "Realm/ObjectStore/src/impl/windows",
            ],
            sources: ["Realm"],
            publicHeadersPath: "include",
            cxxSettings: cxxSettings
        ),
        .target(
            name: "RealmSwift",
            dependencies: ["Realm"],
            path: "RealmSwift",
            exclude: [
                "Sync.swift",
                "ObjectiveCSupport+Sync.swift",
                "Tests",
            ]
        ),
        .target(
            name: "RealmTestSupport",
            dependencies: ["Realm"],
            path: "Realm/TestUtils",
            cxxSettings: cxxSettings + [
                // Command-line `swift build` resolves header search paths
                // relative to the package root, while Xcode resolves them
                // relative to the target root, so we need both.
                .headerSearchPath("Realm"),
                .headerSearchPath(".."),
            ]
        ),
        .testTarget(
            name: "RealmTests",
            dependencies: ["Realm", "RealmTestSupport"],
            path: "Realm/Tests",
            exclude: [
                "Swift",
                "TestHost",
                "PrimitiveArrayPropertyTests.tpl.m",
            ],
            cxxSettings: cxxSettings + [
                .headerSearchPath("Realm"),
                .headerSearchPath(".."),
                .headerSearchPath("../ObjectStore/src"),
            ]
        ),
        .testTarget(
            name: "RealmObjcSwiftTests",
            dependencies: ["Realm", "RealmTestSupport"],
            path: "Realm/Tests/Swift"
        ),
        .testTarget(
            name: "RealmSwiftTests",
            dependencies: ["RealmSwift", "RealmTestSupport"],
            path: "RealmSwift/Tests",
            exclude: ["TestUtils.mm"]
        )
    ],
    cxxLanguageStandard: .cxx14
)
