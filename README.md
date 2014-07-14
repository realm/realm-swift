# Realm for iOS & OSX

![Logo](logo.png)

Realm is a mobile database that runs directly inside phones, tablets or wearables. This repository holds the source code for the iOS & OSX versions of Realm.

## Features

* **Mobile-first:** Realm is the first database built from the ground up to run directly inside phones, tablets and wearables
* **Fast:** Realm is faster than even raw SQLite on common operations
* **Simple:** add persistence to your apps in minutes
* **Modern:** Realm supports relationships, generics, vectorization and even Swift (experimental)

## Setting up Realm in your app

There are two ways to set up Realm in your app: manually or with CocoaPods.

Manually:

* [Download Realm.framework](http://static.realm.io/downloads/ios/latest) (or build it from source)
* Drag Realm.framework into your Xcode project
* Link `libc++.dylib` to your target

CocoaPods:

* Install [CocoaPods](http://cocoapods.org)
* Add `pod "Realm"` to your Podfile
* Run `pod install`

Once your app is set up with Realm, our [documentation](http://realm.io/docs/ios) will guide you to unleash its full potential.

## Documentation

Documentation for Realm can be found at [realm.io/docs/ios](http://realm.io/docs/ios). The API reference is located at [realm.io/docs/ios/latest/api](http://realm.io/docs/ios/latest/api).

## Requirements

* Building Realm requires Xcode 5
* Building Realm with Swift support requires Xcode6-Beta3
* Building Realm documentation requires [appledoc](https://github.com/tomaz/appledoc)

## Building Realm

Once you have all the necessary requirements, building Realm.framework just takes a single command: `sh build.sh ios`. You'll need an internet connection the first time you build Realm to download the core binary.

Run `sh build.sh help` to see all the actions you can perform.

## License

Realm Cocoa is published under the Apache 2.0 license.

![analytics](https://ga-beacon.appspot.com/UA-50247013-2/realm-cocoa/README?pixel)
