# Realm Examples

Included in this folder are sample iOS/OSX apps using Realm.

## iOS (Objective-C)

The following examples are located in the `ios/objc/RealmExamples.xcodeproj` project:

### Chat

Chat app to demonstrate how to use a synced realm. To run, follow these steps:

* Checkout realm-core’s [sync-demo-2 branch](https://github.com/tightdb/tightdb/tree/sync-demo-2)
* Build realm-core by running `sh build.sh config && sh build.sh build-cocoa`
* Copy the `core` directory from your realm-cocoa to your realm-cocoa-private directory
* In realm-core start the realm server by running `./src/realm/realm-server-noinst <HOSTNAME>`
* Edit `examples/ios/objc/Chat/AppDelegate.m` to use the hostname of the computer running the realm server
* Run the "Chat" scheme

### Draw

Drawing app to demonstrate how to use a synced realm. To run, follow these steps:

* Checkout realm-core’s [sync-demo-2 branch](https://github.com/tightdb/tightdb/tree/sync-demo-2)
* Build realm-core by running `sh build.sh config && sh build.sh build-cocoa`
* Copy the `core` directory from your realm-cocoa to your realm-cocoa-private directory
* In realm-core start the realm server by running `./src/realm/realm-server-noinst <HOSTNAME>`
* Edit `examples/ios/objc/Draw/AppDelegate.m` and `examples/osx/objc/Draw/AppDelegate.m` to use the hostname of the computer running the realm server
* Run the "Draw" scheme in both examples projects

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

## iOS (Swift)

In the `ios/swift/RealmExamples.xcodeproj` project, you will find the following examples (Xcode6-Beta6 required):

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

## iOS (RubyMotion)

***RubyMotion support is experimental. We make no claims towards stability and/or performance when using Realm in RubyMotion.***

In the `ios/rubymotion` directory, you will find a Simple example demonstrating how to use Realm in a [RubyMotion](http://www.rubymotion.com) iOS app. Make sure to have run `sh build.sh ios-static` from the root of this repo before building and running this example. You can build and run this example by running `rake` from the `rubymotion/Simple` directory.

To use Realm in your own RubyMotion iOS or OSX app, you must define your models in Objective-C and place them in the `models/` directory. Then in your `Rakefile`, define the following `vendor_project`s:

```ruby
app.vendor_project 'path/to/Realm/Realm.framework', :static, :products => ['Realm'], :force_load => false
app.vendor_project 'models', :static, :cflags => '-F /path/to/Realm/'
```

## OSX (Objective-C)

In the `osx/objc/RealmExamples.xcodeproj` project, you will find the following examples:

### JSONImport

This is a small OS X command-line program which demonstrates how to import data from JSON into a Realm.

Open the project in Xcode, and press "Run" to build and run the program. It will write output to the console.
