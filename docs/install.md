# Install the SDK for iOS, macOS, tvOS, and watchOS
## Overview
Realm SDK for Swift enables you to build iOS, macOS, tvOS,
and watchOS applications using either the Swift or Objective-C programming
languages. This page details how to install the SDK in your project and get
started.

## Prerequisites
Before getting started, ensure your development environment
meets the following prerequisites:

- Your project uses an Xcode version and minimum OS version listed in the
OS Support section of this page.
- Reflection is enabled in your project. The Swift SDK uses reflection to
determine your model's properties. Your project must not set
`SWIFT_REFLECTION_METADATA_LEVEL = none`, or the SDK cannot see properties
in your model. Reflection is enabled by default if your project does
not specifically set a level for this setting.

## Installation
You can use `SwiftPM`, `CocoaPods`, or `Carthage` to add the
Swift SDK to your project.

> Tip:
> The SDK uses Realm Core database for device data persistence. When you
install the Swift SDK, the package names reflect Realm naming.
>

#### Swiftpm

##### Add Package Dependency
In Xcode, select `File` > `Add Packages...`.

##### Specify the Repository
Copy and paste the following into the search/input box.

```sh
https://github.com/realm/realm-swift.git
```

##### Specify Options
In the options for the `realm-swift` package, we recommend setting
the `Dependency Rule` to `Up to Next Major Version`,
and enter the [current Realm Swift SDK version](https://github.com/realm/realm-swift/releases) . Then, click `Add Package`.

##### Select the Package Products
> Version changed: 10.49.3
> Instead of adding both, only add one package.
>

Select either `RealmSwift` or `Realm`, then click `Add Package`.

- If you use Swift or Swift and Objective-C APIs, add `RealmSwift`.
- If you use *only* Objective-C APIs, add `Realm`.

##### (Optional) Build RealmSwift as a Dynamic Framework
To use the Privacy Manifest supplied by the SDK, build `RealmSwift`
as a dynamic framework. If you build `RealmSwift` as a static
framework, you must supply your own Privacy Manifest.

To build `RealmSwift` as a dynamic framework:

1. In your project Targets, select your build target.
2. Go to the General tab.
3. Expand the Frameworks and Libraries element.
4. For the `RealmSwift` framework, change the
Embed option from "Do Not Embed" to "Embed & Sign."

Now, Xcode builds `RealmSwift` dynamically, and can provide the
SDK-supplied Privacy Manifest.

#### Cocoapods

If you are installing with [CocoaPods](https://guides.cocoapods.org/using/getting-started.html), you need CocoaPods 1.10.1 or later.

##### Update the CocoaPods repositories
On the command line, run `pod repo update` to ensure
CocoaPods can access the latest available Realm versions.

##### Initialize CocoaPods for Your Project
If you do not already have a Podfile for your project,
run `pod init` in the root directory of your project to
create a Podfile for your project. A Podfile allows you
to specify project dependencies to CocoaPods.

##### Add the SDK as a Dependency in Your Podfile
#### Objective-C

Add the line `pod 'Realm', '~>10'` to your main and test
targets.

Add the line `use_frameworks!` as well if it is not
already there.

When done, your Podfile should look something like this:

```text
# Uncomment the next line to define a global platform for your project
# platform :ios, '11.0'

target 'MyDeviceSDKProject' do
# Comment the next line if you don't want to use dynamic frameworks
use_frameworks!

# Pods for MyDeviceSDKProject
pod 'Realm', '~>10'

target 'MyRealmProjectTests' do
   inherit! :search_paths
   # Pods for testing
   pod 'Realm', '~>10'
end

end
```

#### Swift

Add the line `use_frameworks!` if it is not
already there.

Add the line `pod 'RealmSwift', '~>10'` to your main and test
targets.

When done, your Podfile should look something like this:

```text
platform :ios, '12.0'

target 'MyDeviceSDKProject' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for MyDeviceSDKProject
  pod 'RealmSwift', '~>10'

end
```

##### Install the Dependencies
From the command line, run `pod install` to fetch the
dependencies.

###### Use the CocoaPods-Generated  File

##### Use the CocoaPods-Generated .xcworkspace File
CocoaPods generates an `.xcworkspace` file for you. This
file has all of the dependencies configured. From now on,
open this file -- not the `.xcodeproj` file -- to work
on your project.

#### Carthage

If you are installing with [Carthage](https://github.com/Carthage/Carthage#installing-carthage), you need Carthage 0.33 or later.

##### Add the SDK as a Dependency in Your Cartfile
Add the SDK as a dependency by appending the line `github
"realm/realm-swift"` to your Cartfile.

You can create a Cartfile or append to an existing one by
running the following command in your project directory:

```bash
echo 'github "realm/realm-swift"' >> Cartfile
```

##### Install the Dependencies
From the command line, run `carthage update --use-xcframeworks`
to fetch the dependencies.

##### Add the Frameworks to Your Project
Carthage places the built dependencies in the `Carthage/Build`
directory.

Open your project's `xcodeproj` file in Xcode. Go to
the Project Navigator panel and click your application
name to open the project settings editor. Select the
General tab.

In Finder, open the `Carthage/Build/` directory. Drag the
`RealmSwift.xcframework` and `Realm.xcframework` files
found in that directory to the Frameworks,
Libraries, and Embedded Content section of your
project's General settings.

#### Dynamic Framework

##### Download and Extract the Framework
Download the [latest release of the Swift SDK](https://github.com/realm/realm-swift/releases) and extract the zip.

##### Copy Framework(s) Into Your Project
Drag `Realm.xcframework` and `RealmSwift.xcframework` (if using)
to the File Navigator of your Xcode project. Select the
Copy items if needed checkbox and press Finish.

> Tip:
> If using the Objective-C API within a Swift project, we
recommend you include both Realm Swift and Realm Objective-C in your
project. Within your Swift files, you can access the Swift API and
all required wrappers. Using the RealmSwift API in mixed
Swift/Objective-C projects is possible because the vast majority of
RealmSwift types are directly aliased from their Objective-C
counterparts.
>

## Import the SDK
> Tip:
> The SDK uses Realm Core database for device data persistence. When you
import the Swift SDK, the package names reflect Realm naming.
>

Add the following line at the top of your source files to use the SDK:

#### Objective-C

```objectivec
#include <Realm/Realm.h>

```

#### Swift

```swift
import RealmSwift

```

## App Download File Size
The SDK should only add around 5 to 8 MB to your app's download
size. The releases we distribute are significantly larger because they
include support for the iOS, watchOS and tvOS simulators, some debug symbols,
and bitcode, all of which are stripped by the App Store automatically when
apps are downloaded.

## Troubleshooting
If you have build issues after using one of these methods to install
the SDK, see our troubleshooting guidelines
for information about resolving those issues.

## OS Support
> Important:
> There are special considerations when using the SDK with
tvOS. See Build for tvOS for more information.
>

### Xcode 15
> Version changed: 10.50.0
> Minimum required Xcode version is 15.1
>

|Supported OS|Realm|
| --- | --- |
|iOS 12.0+|X|
|macOS 10.14+|X|
|tvOS 12.0+|X|
|watchOS 4.0+|X|
|visionOS 1.0+|X|

### Xcode 14
> Version changed: 10.50.0
> Removed support for Xcode 14.
>

Swift SDK version 10.50.0 drops support for Xcode 14. For v10.49.3 and earlier,
these Xcode 14 requirements apply:

- [Xcode](https://developer.apple.com/xcode/) version 14.1 or higher.
- When using Xcode 14, a target of iOS 11.0 or higher, macOS 10.13 or higher, tvOS 11.0 or higher, or watchOS 4.0 or higher.

## Swift Concurrency Support
The Swift SDK supports Swift's concurrency-related language features.
For best practices on using the Swift SDK's concurrency features, refer
to the documentation below.

### Async/Await Support
Starting with Realm Swift SDK Versions 10.15.0 and 10.16.0, many of the
Realm APIs support the Swift async/await syntax. Projects must
meet these requirements:

|Swift SDK Version|Swift Version Requirement|Supported OS|
| --- | --- | --- |
|10.25.0|Swift 5.6|iOS 13.x|
|10.15.0 or 10.16.0|Swift 5.5|iOS 15.x|

If your app accesses Realm in an `async/await` context, mark the code
with `@MainActor` to avoid threading-related crashes.

For more information about async/await support in the Swift SDK, refer
to Swift Concurrency: Async/Await APIs.

### Actor Support
The Swift SDK supports actor-isolated realm instances. For more information,
refer to Use Realm with Actors - Swift SDK.

## Apple Privacy Manifest
> Version changed: 10.49.3
> Build RealmSwift as a dynamic framework to include the Privacy Manifest.
>

Apple requires apps that use `RealmSwift` to provide a privacy manifest
containing details about the SDK's data collection and use practices. The
bundled manifest file must be included when submitting new apps or app updates
to the App Store. For more details about Apple's requirements, refer to
[Upcoming third-party SDK requirements](https://developer.apple.com/support/third-party-SDK-requirements/)
on the Apple Developer website.

Starting in Swift SDK version 10.46.0, the SDK ships with privacy manifests
for `Realm` and `RealmSwift`. Each package contains its own privacy manifest
with Apple's required API disclosures and the reasons for using those APIs.

You can view the privacy manifests in each package, or in the `realm-swift`
GitHub repository:

- `Realm`: [https://github.com/realm/realm-swift/blob/master/Realm/PrivacyInfo.xcprivacy](https://github.com/realm/realm-swift/blob/master/Realm/PrivacyInfo.xcprivacy)
- `RealmSwift`: [https://github.com/realm/realm-swift/blob/master/RealmSwift/PrivacyInfo.xcprivacy](https://github.com/realm/realm-swift/blob/master/RealmSwift/PrivacyInfo.xcprivacy)

To include these manifests in a build target that uses `RealmSwift`, you must
build `RealmSwift` as a dynamic framework. For details, refer to the Swift
Package Manager Installation instructions step
**(Optional) Build RealmSwift as a Dynamic Framework**.

The Swift SDK does not include analytics code in builds for the App Store.

You may need to add additional disclosures to your app's privacy manifest
detailing your data collection and use practices when using these APIs.

For more information, refer to Apple's
[Privacy manifest files documentation](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files).
