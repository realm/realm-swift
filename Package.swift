// swift-tools-version:5.0

import PackageDescription
import Foundation

let coreVersionStr = "6.0.6"
let cocoaVersionStr = "5.1.0"

let coreVersionPieces = coreVersionStr.split(separator: ".")
let coreVersionExtra = coreVersionPieces[2].split(separator: "-")
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
        .package(url: "https://github.com/realm/realm-core", .exact(Version(coreVersionStr)!)),
    ],
    targets: [
      .target(
            name: "Realm",
            dependencies: ["RealmCore"],
            path: ".",
            sources: [
                "Realm/ObjectStore/src/binding_callback_thread_observer.cpp",
                "Realm/ObjectStore/src/collection_notifications.cpp",
                "Realm/ObjectStore/src/impl/apple/external_commit_helper.cpp",
                "Realm/ObjectStore/src/impl/apple/keychain_helper.cpp",
                "Realm/ObjectStore/src/impl/collection_change_builder.cpp",
                "Realm/ObjectStore/src/impl/collection_notifier.cpp",
                "Realm/ObjectStore/src/impl/list_notifier.cpp",
                "Realm/ObjectStore/src/impl/object_notifier.cpp",
                "Realm/ObjectStore/src/impl/primitive_list_notifier.cpp",
                "Realm/ObjectStore/src/impl/realm_coordinator.cpp",
                "Realm/ObjectStore/src/impl/results_notifier.cpp",
                "Realm/ObjectStore/src/impl/transact_log_handler.cpp",
                "Realm/ObjectStore/src/impl/weak_realm_notifier.cpp",
                "Realm/ObjectStore/src/index_set.cpp",
                "Realm/ObjectStore/src/list.cpp",
                "Realm/ObjectStore/src/object.cpp",
                "Realm/ObjectStore/src/object_changeset.cpp",
                "Realm/ObjectStore/src/object_schema.cpp",
                "Realm/ObjectStore/src/object_store.cpp",
                "Realm/ObjectStore/src/results.cpp",
                "Realm/ObjectStore/src/schema.cpp",
                "Realm/ObjectStore/src/shared_realm.cpp",
                "Realm/ObjectStore/src/thread_safe_reference.cpp",
                "Realm/ObjectStore/src/util/scheduler.cpp",
                "Realm/ObjectStore/src/util/uuid.cpp",
                "Realm/RLMAccessor.mm",
                "Realm/RLMAnalytics.mm",
                "Realm/RLMArray.mm",
                "Realm/RLMClassInfo.mm",
                "Realm/RLMCollection.mm",
                "Realm/RLMConstants.m",
                "Realm/RLMListBase.mm",
                "Realm/RLMManagedArray.mm",
                "Realm/RLMMigration.mm",
                "Realm/RLMObject.mm",
                "Realm/RLMObjectBase.mm",
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
                "Realm/RLMUtil.mm"
            ],
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
    cxxLanguageStandard: .cxx1z
)
