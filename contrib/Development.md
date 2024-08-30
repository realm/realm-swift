# Developing Realm

## Building Realm

There are three ways to build Realm
1. \[Recommended] Using Xcode, open Package.swift. With this approach you can build either against a released Core version or a custom branch.
1. Using Xcode, open Realm.xcodeproj. This will download the version of Core specified in `dependencies.list/REALM_CORE_VERSION` and build the Swift SDK against it.
1. From the command line, run `./build.sh build`. Similarly to 2., this also downloads Core and builds against it.

### Building against a custom branch of Core

To build Realm against a custom Core branch, update `Package.swift` by updating the Realm Core dependency from `exact` to `branch`:

```diff
    dependencies: [
-        .package(url: "https://github.com/realm/realm-core.git", exact: coreVersion)
+        .package(url: "https://github.com/realm/realm-core.git", branch: "*your-custom-branch*")
    ],

