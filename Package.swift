// swift-tools-version:5.5

import PackageDescription
import Foundation

let coreVersionStr = "13.10.1"
let cocoaVersionStr = "10.39.1"

let coreVersionPieces = coreVersionStr.split(separator: ".")
let coreVersionExtra = coreVersionPieces[2].split(separator: "-")
let cxxSettings: [CXXSetting] = [
    .headerSearchPath("."),
    .headerSearchPath("include"),
    .define("REALM_SPM", to: "1"),
    .define("REALM_ENABLE_SYNC", to: "1"),
    .define("REALM_COCOA_VERSION", to: "@\"\(cocoaVersionStr)\""),
    .define("REALM_VERSION", to: "\"\(coreVersionStr)\""),

    .define("REALM_DEBUG", .when(configuration: .debug)),
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
let testCxxSettings: [CXXSetting] = cxxSettings + [
    // Command-line `swift build` resolves header search paths
    // relative to the package root, while Xcode resolves them
    // relative to the target root, so we need both.
    .headerSearchPath("Realm"),
    .headerSearchPath(".."),
]

// SPM requires all targets to explicitly include or exclude every file, which
// gets very awkward when we have four targets building from a single directory
let objectServerTestSources = [
    "Object-Server-Tests-Bridging-Header.h",
    "ObjectServerTests-Info.plist",
    "RLMAsymmetricSyncServerTests.mm",
    "RLMBSONTests.mm",
    "RLMCollectionSyncTests.mm",
    "RLMFlexibleSyncServerTests.mm",
    "RLMObjectServerPartitionTests.mm",
    "RLMObjectServerTests.mm",
    "RLMServerTestObjects.m",
    "RLMSyncTestCase.h",
    "RLMSyncTestCase.mm",
    "RLMUser+ObjectServerTests.h",
    "RLMUser+ObjectServerTests.mm",
    "RLMWatchTestUtility.h",
    "RLMWatchTestUtility.m",
    "EventTests.swift",
    "RealmServer.swift",
    "SwiftAsymmetricSyncServerTests.swift",
    "SwiftCollectionSyncTests.swift",
    "SwiftFlexibleSyncServerTests.swift",
    "SwiftMongoClientTests.swift",
    "SwiftObjectServerPartitionTests.swift",
    "SwiftObjectServerTests.swift",
    "SwiftServerObjects.swift",
    "SwiftSyncTestCase.swift",
    "SwiftUIServerTests.swift",
    "TimeoutProxyServer.swift",
    "WatchTestUtility.swift",
    "certificates",
    "config_overrides.json",
    "include",
    "setup_baas.rb",
]

func objectServerTestSupportTarget(name: String, dependencies: [Target.Dependency], sources: [String]) -> Target {
    .target(
        name: name,
        dependencies: dependencies,
        path: "Realm/ObjectServerTests",
        exclude: objectServerTestSources.filter { !sources.contains($0) },
        sources: sources,
        cxxSettings: testCxxSettings
    )
}

func objectServerTestTarget(name: String, sources: [String]) -> Target {
    .testTarget(
        name: name,
        dependencies: ["RealmSwift", "RealmTestSupport", "RealmSyncTestSupport", "RealmSwiftSyncTestSupport"],
        path: "Realm/ObjectServerTests",
        exclude: objectServerTestSources.filter { !sources.contains($0) },
        sources: sources,
        cxxSettings: testCxxSettings
    )
}

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
        .package(name: "RealmDatabase", url: "https://github.com/realm/realm-core.git", .exact(Version(coreVersionStr)!))
    ],
    targets: [
      .target(
            name: "Realm",
            dependencies: [.product(name: "RealmCore", package: "RealmDatabase")],
            path: ".",
            exclude: [
                "CHANGELOG.md",
                "CONTRIBUTING.md",
                "Carthage",
                "Configuration",
                "Jenkinsfile.releasability",
                "LICENSE",
                "Package.swift",
                "README.md",
                "Realm.podspec",
                "Realm.xcodeproj",
                "Realm/ObjectServerTests",
                "Realm/RLMPlatform.h.in",
                "Realm/Realm-Info.plist",
                "Realm/Swift/RLMSupport.swift",
                "Realm/TestUtils",
                "Realm/Tests",
                "RealmSwift",
                "RealmSwift.podspec",
                "SUPPORT.md",
                "build.sh",
                "ci_scripts/ci_post_clone.sh",
                "contrib",
                "dependencies.list",
                "docs",
                "examples",
                "include",
                "logo.png",
                "plugin",
                "scripts",
            ],
            sources: [
                "Realm/RLMAccessor.mm",
                "Realm/RLMAnalytics.mm",
                "Realm/RLMArray.mm",
                "Realm/RLMAsymmetricObject.mm",
                "Realm/RLMAsyncTask.mm",
                "Realm/RLMClassInfo.mm",
                "Realm/RLMCollection.mm",
                "Realm/RLMConstants.m",
                "Realm/RLMDecimal128.mm",
                "Realm/RLMDictionary.mm",
                "Realm/RLMEmbeddedObject.mm",
                "Realm/RLMError.mm",
                "Realm/RLMEvent.mm",
                "Realm/RLMLogger.mm",
                "Realm/RLMManagedArray.mm",
                "Realm/RLMManagedDictionary.mm",
                "Realm/RLMManagedSet.mm",
                "Realm/RLMMigration.mm",
                "Realm/RLMObject.mm",
                "Realm/RLMObjectBase.mm",
                "Realm/RLMObjectId.mm",
                "Realm/RLMObjectSchema.mm",
                "Realm/RLMObjectStore.mm",
                "Realm/RLMObservation.mm",
                "Realm/RLMPredicateUtil.mm",
                "Realm/RLMProperty.mm",
                "Realm/RLMQueryUtil.mm",
                "Realm/RLMRealm.mm",
                "Realm/RLMRealmConfiguration.mm",
                "Realm/RLMRealmUtil.mm",
                "Realm/RLMResults.mm",
                "Realm/RLMScheduler.mm",
                "Realm/RLMSchema.mm",
                "Realm/RLMSectionedResults.mm",
                "Realm/RLMSet.mm",
                "Realm/RLMSwiftCollectionBase.mm",
                "Realm/RLMSwiftSupport.m",
                "Realm/RLMSwiftValueStorage.mm",
                "Realm/RLMThreadSafeReference.mm",
                "Realm/RLMUUID.mm",
                "Realm/RLMUpdateChecker.mm",
                "Realm/RLMUtil.mm",
                "Realm/RLMValue.mm",

                // Sync source files
                "Realm/NSError+RLMSync.m",
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
                "Realm/RLMSyncConfiguration.mm",
                "Realm/RLMSyncManager.mm",
                "Realm/RLMSyncSession.mm",
                "Realm/RLMSyncSubscription.mm",
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
                "Nonsync.swift",
                "RealmSwift-Info.plist",
                "Tests",
            ]
        ),
        .target(
            name: "RealmTestSupport",
            dependencies: ["Realm"],
            path: "Realm/TestUtils",
            cxxSettings: testCxxSettings
        ),
        .target(
            name: "RealmSwiftTestSupport",
            dependencies: ["RealmSwift", "RealmTestSupport"],
            path: "RealmSwift/Tests",
            sources: ["TestUtils.swift"]
        ),
        .testTarget(
            name: "RealmTests",
            dependencies: ["Realm", "RealmTestSupport"],
            path: "Realm/Tests",
            exclude: [
                "PrimitiveArrayPropertyTests.tpl.m",
                "PrimitiveDictionaryPropertyTests.tpl.m",
                "PrimitiveRLMValuePropertyTests.tpl.m",
                "PrimitiveSetPropertyTests.tpl.m",
                "RealmTests-Info.plist",
                "Swift",
                "SwiftUITestHost",
                "SwiftUITestHostUITests",
                "TestHost",
                "array_tests.py",
                "dictionary_tests.py",
                "fileformat-pre-null.realm",
                "mixed_tests.py",
                "set_tests.py",
                "SwiftUISyncTestHost",
                "SwiftUISyncTestHostUITests"
            ],
            cxxSettings: testCxxSettings
        ),
        .testTarget(
            name: "RealmObjcSwiftTests",
            dependencies: ["Realm", "RealmTestSupport"],
            path: "Realm/Tests/Swift",
            exclude: ["RealmObjcSwiftTests-Info.plist"]
        ),
        .testTarget(
            name: "RealmSwiftTests",
            dependencies: ["RealmSwift", "RealmTestSupport", "RealmSwiftTestSupport"],
            path: "RealmSwift/Tests",
            exclude: [
                "RealmSwiftTests-Info.plist",
                "QueryTests.swift.gyb",
                "TestUtils.swift"
            ]
        ),

        // Object server tests have support code written in both obj-c and
        // Swift which is used by both the obj-c and swift test code. SPM
        // doesn't support mixed targets, so this ends up requiring four
        // different targets.
        objectServerTestSupportTarget(
            name: "RealmSyncTestSupport",
            dependencies: ["Realm", "RealmSwift", "RealmTestSupport"],
            sources: ["RLMSyncTestCase.mm",
                      "RLMUser+ObjectServerTests.mm",
                      "RLMServerTestObjects.m"]
        ),
        objectServerTestSupportTarget(
            name: "RealmSwiftSyncTestSupport",
            dependencies: ["RealmSwift", "RealmTestSupport", "RealmSyncTestSupport", "RealmSwiftTestSupport"],
            sources: [
                 "SwiftSyncTestCase.swift",
                 "TimeoutProxyServer.swift",
                 "WatchTestUtility.swift",
                 "RealmServer.swift",
                 "SwiftServerObjects.swift"
            ]
        ),
        objectServerTestTarget(
            name: "SwiftObjectServerTests",
            sources: [
                "EventTests.swift",
                "SwiftAsymmetricSyncServerTests.swift",
                "SwiftCollectionSyncTests.swift",
                "SwiftFlexibleSyncServerTests.swift",
                "SwiftMongoClientTests.swift",
                "SwiftObjectServerPartitionTests.swift",
                "SwiftObjectServerTests.swift",
                "SwiftUIServerTests.swift"
            ]
        ),
        objectServerTestTarget(
            name: "ObjcObjectServerTests",
            sources: [
                "RLMAsymmetricSyncServerTests.mm",
                "RLMBSONTests.mm",
                "RLMCollectionSyncTests.mm",
                "RLMFlexibleSyncServerTests.mm",
                "RLMObjectServerPartitionTests.mm",
                "RLMObjectServerTests.mm",
                "RLMWatchTestUtility.m"
            ]
        )
    ],
    cxxLanguageStandard: .cxx20
)
