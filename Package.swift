// swift-tools-version:5.0

import PackageDescription
import Foundation

let coreVersionStr = "10.0.0"
let cocoaVersionStr = "10.1.1"

let coreVersionPieces = coreVersionStr.split(separator: ".")
let coreVersionExtra = coreVersionPieces[2].split(separator: "-")
let cxxSettings: [CXXSetting] = [
    .headerSearchPath("."),
    .headerSearchPath("include"),
    .define("REALM_SPM", to: "1"),
    .define("REALM_ENABLE_SYNC", to: "1"),
    .define("REALM_COCOA_VERSION", to: "@\"\(cocoaVersionStr)\""),
    .define("REALM_VERSION", to: "\"\(coreVersionStr)\""),

    .define("REALM_NO_CONFIG"),
    .define("REALM_INSTALL_LIBEXECDIR", to: ""),
    .define("REALM_ENABLE_ASSERTIONS", to: "1"),
    .define("REALM_ENABLE_ENCRYPTION", to: "1"),

    .define("REALM_VERSION_MAJOR", to: String(coreVersionPieces[0])),
    .define("REALM_VERSION_MINOR", to: String(coreVersionPieces[1])),
    .define("REALM_VERSION_PATCH", to: String(coreVersionExtra[0])),
    .define("REALM_VERSION_EXTRA", to: "\"\(coreVersionExtra.count > 1 ? String(coreVersionExtra[1]) : "")\""),
    .define("REALM_VERSION_STRING", to: "\"\(coreVersionStr)\""),
]

let package = Package(
    name: "Realm",
    platforms: [
        .macOS(.v10_10),
        .iOS(.v11),
        .tvOS(.v9),
        .watchOS(.v2)
    ],
    products: [
        .library(
            name: "Realm",
            targets: ["Realm"]),
        .library(
            name: "RealmSwift",
            targets: ["Realm", "RealmSwift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/realm/realm-core", .branch("monorepo"))
    ],
    targets: [
      .target(
            name: "Realm",
            dependencies: ["RealmObjectStore"],
            path: ".",
            sources: [
                "Realm/RLMAccessor.mm",
                "Realm/RLMAnalytics.mm",
                "Realm/RLMArray.mm",
                "Realm/RLMClassInfo.mm",
                "Realm/RLMCollection.mm",
                "Realm/RLMConstants.m",
                "Realm/RLMDecimal128.mm",
                "Realm/RLMEmbeddedObject.mm",
                "Realm/RLMListBase.mm",
                "Realm/RLMManagedArray.mm",
                "Realm/RLMMigration.mm",
                "Realm/RLMObject.mm",
                "Realm/RLMObjectBase.mm",
                "Realm/RLMObjectId.mm",
                "Realm/RLMObjectSchema.mm",
                "Realm/RLMObjectStore.mm",
                "Realm/RLMObservation.mm",
                "Realm/RLMOptionalBase.mm",
                "Realm/RLMPredicateUtil.mm",
                "Realm/RLMProperty.mm",
                "Realm/RLMQueryUtil.mm",
                "Realm/RLMRealm.mm",
                "Realm/RLMRealmConfiguration.mm",
                "Realm/RLMRealmUtil.mm",
                "Realm/RLMResults.mm",
                "Realm/RLMSchema.mm",
                "Realm/RLMSwiftSupport.m",
                "Realm/RLMThreadSafeReference.mm",
                "Realm/RLMUpdateChecker.mm",
                "Realm/RLMUtil.mm",

                // Sync source files
                "Realm/RLMApp.mm",
                "Realm/RLMAPIKeyAuth.mm",
                "Realm/RLMBSON.mm",
                "Realm/RLMCredentials.mm",
                "Realm/RLMEmailPasswordAuth.mm",
                "Realm/RLMFindOneAndModifyOptions.mm",
                "Realm/RLMFindOptions.mm",
                "Realm/RLMMongoClient.mm",
                "Realm/RLMMongoCollection.mm",
                "Realm/RLMNetworkTransport.mm",
                "Realm/RLMProviderClient.mm",
                "Realm/RLMPushClient.mm",
                "Realm/RLMRealm+Sync.mm",
                "Realm/RLMRealmConfiguration+Sync.mm",
                "Realm/RLMSyncConfiguration.mm",
                "Realm/RLMSyncManager.mm",
                "Realm/RLMSyncSession.mm",
                "Realm/RLMSyncUtil.mm",
                "Realm/RLMUpdateResult.mm",
                "Realm/RLMUser.mm",
                "Realm/RLMUserAPIKey.mm"
            ],
            publicHeadersPath: "include",
            cxxSettings: cxxSettings
        ),
        .target(
            name: "RealmSwift",
            dependencies: ["Realm"],
            path: "RealmSwift",
            exclude: [
                "Tests",
                "Nonsync.swift",
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
                .headerSearchPath("..")
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
    cxxLanguageStandard: .cxx1z
)
