// swift-tools-version:5.10

import PackageDescription
import Foundation

let coreVersion = Version("20.1.0")
let cocoaVersion = Version("20.0.3")

#if compiler(>=6)
let swiftVersion = [SwiftVersion.version("6")]
#else
let swiftVersion = [SwiftVersion.v5]
#endif

let cxxSettings: [CXXSetting] = [
    .headerSearchPath("."),
    .headerSearchPath("include"),
    .define("REALM_SPM", to: "1"),
    .define("REALM_COCOA_VERSION", to: "@\"\(cocoaVersion)\""),
    .define("REALM_VERSION", to: "\"\(coreVersion)\""),

    .define("REALM_DEBUG", .when(configuration: .debug)),
    .define("REALM_NO_CONFIG"),
    .define("REALM_INSTALL_LIBEXECDIR", to: ""),
    .define("REALM_ENABLE_ASSERTIONS", to: "1"),
    .define("REALM_ENABLE_ENCRYPTION", to: "1"),

    .define("REALM_VERSION_MAJOR", to: String(coreVersion.major)),
    .define("REALM_VERSION_MINOR", to: String(coreVersion.minor)),
    .define("REALM_VERSION_PATCH", to: String(coreVersion.patch)),
    .define("REALM_VERSION_EXTRA", to: "\"\(coreVersion.prereleaseIdentifiers.first ?? "")\""),
    .define("REALM_VERSION_STRING", to: "\"\(coreVersion)\""),
    .define("REALM_ENABLE_GEOSPATIAL", to: "1"),
]
let testCxxSettings: [CXXSetting] = cxxSettings + [
    // Command-line `swift build` resolves header search paths
    // relative to the package root, while Xcode resolves them
    // relative to the target root, so we need both.
    .headerSearchPath("Realm"),
    .headerSearchPath(".."),
]

let package = Package(
    name: "Realm",
    platforms: [
        .macOS(.v10_13),
        .iOS(.v12),
        .tvOS(.v12),
        .watchOS(.v4)
    ],
    products: [
        .library(
            name: "Realm",
            type: .dynamic,
            targets: ["Realm"]),
        .library(
            name: "RealmSwift",
            type: .dynamic,
            targets: ["RealmSwift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/realm/realm-core.git", exact: coreVersion)
    ],
    targets: [
      .target(
            name: "Realm",
            dependencies: [.product(name: "RealmCore", package: "realm-core")],
            path: ".",
            exclude: [
                "CHANGELOG.md",
                "CONTRIBUTING.md",
                "Carthage",
                "Configuration",
                "LICENSE",
                "Package.swift",
                "README.md",
                "Realm.podspec",
                "Realm.xcodeproj",
                "Realm/Realm-Info.plist",
                "Realm/Swift/RLMSupport.swift",
                "Realm/TestUtils",
                "Realm/Tests",
                "RealmSwift",
                "RealmSwift.podspec",
                "SUPPORT.md",
                "build.sh",
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
                "Realm/RLMArray.mm",
                "Realm/RLMAsyncTask.mm",
                "Realm/RLMClassInfo.mm",
                "Realm/RLMCollection.mm",
                "Realm/RLMConstants.m",
                "Realm/RLMDecimal128.mm",
                "Realm/RLMDictionary.mm",
                "Realm/RLMEmbeddedObject.mm",
                "Realm/RLMError.mm",
                "Realm/RLMGeospatial.mm",
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
                "Realm/RLMUtil.mm",
                "Realm/RLMValue.mm",
            ],
            resources: [
                .copy("Realm/PrivacyInfo.xcprivacy")
            ],
            publicHeadersPath: "include",
            cxxSettings: cxxSettings,
            linkerSettings: [
                .linkedFramework("UIKit", .when(platforms: [.iOS, .macCatalyst, .tvOS, .watchOS]))
            ]
        ),
        .target(
            name: "RealmSwift",
            dependencies: ["Realm"],
            path: "RealmSwift",
            exclude: [
                "RealmSwift-Info.plist",
                "Tests",
            ],
            resources: [
                .copy("PrivacyInfo.xcprivacy")
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
    ],
    swiftLanguageVersions: swiftVersion,
    cxxLanguageStandard: .cxx20
)
