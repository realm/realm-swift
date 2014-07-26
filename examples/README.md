# Realm Examples

Included in this folder are sample iOS/OSX apps using Realm.

## iOS (Objective-C)

In the `ios/objc/RealmExamples.xcodeproj` project, you will find the following examples:

### Simple

This app covers several introductory concepts about Realm. Without any UI distractions, just a little console output.

### TableView

This app demonstrates how Realm can be the data source for UITableViews.

You can add rows by tapping the add button and remove rows by swiping right-to-left.

The application also demonstrates how to import data in a background thread.

### Migration

This example shows how to use the migration features of Realm.

### REST

Using data from FourSquare, the example shows how you can populate a Realm with external json data.

### Encryption

This simple app shows how to use an encrypted realm.

## iOS (Swift)

In the `ios/swift/RealmExamples.xcodeproj` project, you will find the following examples:

### Simple

This app covers several introductory concepts about Realm. Without any UI distractions, just a little console output.

### TableView

This app demonstrates how Realm can be the data source for UITableViews.

You can add rows by tapping the add button and remove rows by swiping right-to-left.

The application also demonstrates how to import data in a background thread.

### Migration

This example shows how to use the migration features of Realm.

### Encryption

This simple app shows how to use an encrypted realm.

## iOS (RubyMotion)

***RubyMotion support is experimental. We make no claims towards stability and/or performance when using Realm in RubyMotion.***

In the `ios/rubymotion` directory, you will find a Simple example demonstrating how to use Realm in a [RubyMotion](http://www.rubymotion.com) iOS app. Make sure to have run `sh build.sh ios` from the root of this repo before building and running this example. You can build and run this example by running `rake` from the `rubymotion/Simple` directory.

To use Realm in your own RubyMotion iOS or OSX app, you must define your models in Objective-C and place them in the `models/` directory. Then in your `Rakefile`, define the following `vendor_project`s:

```ruby
app.vendor_project 'path/to/Realm/Realm.framework', :static, :products => ['Realm'], :force_load => false
app.vendor_project 'models', :static, :cflags => '-F /path/to/Realm/'
```

## OSX (Objective-C)

In the `osx/objc/RealmExamples.xcodeproj` project, you will find the following examples:

### JSON

This is a small OS X command-line program which shows how you can import data from JSON into a Realm. It requires Xcode 5 to build.

Open the project in Xcode, and press "Run" to build and run the program. It will write output to the console.
