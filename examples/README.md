# Realm Examples

Included in this folder are sample iOS/OSX apps using Realm.

## iOS (Objective-C)

The following examples are located in the `ios/objc/RealmExamples.xcodeproj` project:

### Simple

This app covers several introductory concepts about Realm. Without any UI distractions, just a little console output.

### TableView

This app demonstrates how Realm can be the data source for UITableViews.

You can add rows by tapping the add button and remove rows by swiping right-to-left.

The application also demonstrates how to import data in a background thread.

### GroupedTableView

A sample app to demonstrate how to use Realm to populate a table view with sections.

### Migration

This example showcases Realm's migration features.

### REST

Using data from FourSquare, this example demonstrates how to populate a Realm with external json data.

### Encryption

This simple app shows how to use an encrypted realm.

### Backlink

This simple app demonstrates how to define models with inverse relationships using `-linkingObjectsOfClass:forProperty:`.

### Draw

This is a simple drawing app designed to show off the collaborative features of the [Realm Mobile Platform](https://realm.io/news/introducing-realm-mobile-platform/).

Any number of users may draw on a single shared canvas in any given moment, with contributions from other devices appearing on the canvas in real-time.

#### Installation Instructions

1. [Download the macOS version](https://realm.io/docs/realm-mobile-platform/get-started/) of the Realm Mobile Platform.
2. Run a local instance of the Realm Mobile Platform.
3. Open the Realm Object Server Dashboard in your browser by visiting 'http://localhost:9080'.
4. Create a user account with the email 'demo@realm.io' and the password 'password'.
5. Build the Draw app and deploy it to iOS devices on the same network as your Mac.

## iOS (Swift)

In the `ios/swift/RealmExamples.xcodeproj` project, you will find the following examples:

### GettingStarted.playground

This is a Swift Playground that goes over a few Realm basics.

### Simple

This app covers several introductory concepts about Realm. Without any UI distractions, just a little console output.

### TableView

This app demonstrates how Realm can be the data source for UITableViews.

You can add rows by tapping the add button and remove rows by swiping right-to-left.

The application also demonstrates how to import data in a background thread.

### GroupedTableView

A sample app to demonstrate how to use Realm to populate a table view with sections.

### Migration

This example showcases Realm's migration features.

### Encryption

This simple app shows how to use an encrypted realm.

### Backlink

This simple app demonstrates how to define models with inverse relationships using `linkingObjectsOfClass(_:forProperty:)`.

### AppClip / AppClipParent

These two targets demonstrate how to use Realm to persist data between an App Clip and its parent.

**Note:** This is only supported for non-synchronized realms.

#### Example Usage

For the purpose of this example, the app clip invocation and parent application download is simulated by running each target.

For more information on complete App Clip flow see: [Responding to invocations](https://developer.apple.com/documentation/app_clips/responding_to_invocations) and [Launch Experience](https://developer.apple.com/documentation/app_clips/testing_your_app_clip_s_launch_experience).

![alt text](https://github.com/realm/realm-cocoa/blob/em/appclip_ex/examples/ios/swift/AppClip/appclip_ex.gif?raw=true)

**Note:** When testing App Group Entitlements on MacOS (including the iOS simulator), `containerURL(forSecurityApplicationGroupIdentifier:)` will always return the shared directory URL, even when the group identifier is invalid.  Be sure to test on physical devices with non-simulated iOS for expected security behavior. See [Return Value](https://developer.apple.com/documentation/foundation/filemanager/1412643-containerurl).



## OSX (Objective-C)

In the `osx/objc/RealmExamples.xcodeproj` project, you will find the following examples:

### JSONImport

This is a small OS X command-line program which demonstrates how to import data from JSON into a Realm.

Open the project in Xcode, and press "Run" to build and run the program. It will write output to the console.

## Installation Examples

The `installation/` directory contains example Xcode projects demonstrating how
to install Realm Objective-C and Realm Swift from all available methods defined
in <https://realm.io/docs/objc/latest/#installation> and
<https://realm.io/docs/swift/latest/#installation>.

## tvOS (Objective-C)

### DownloadCache

A tvOS app that demonstrates how to use Realm to store data and display data from a REST API.

### PreloadedData

A tvOS app that demonstrates how to use a Realm file included in your app bundle.

## tvOS (Swift)

### DownloadCache

A tvOS app that demonstrates how to use Realm to store data and display data from a REST API.

### PreloadedData

A tvOS app that demonstrates how to use a Realm file included in your app bundle.
