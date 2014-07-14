![Realm](logo.png)

Realm is a mobile database that runs directly inside phones, tablets or wearables. This repository holds the source code for the iOS & OSX versions of Realm, for both Swift & Objective-C

## Features

* **Mobile-first:** Realm is the first database built from the ground up to run directly inside phones, tablets and wearables
* **Simple:** data is directly [exposed as objects](http://realm.io/docs/ios/latest/#models) and [queryable by code](http://realm.io/docs/ios/latest/#queries), removing the need for ORM's riddled with performance & maintenance issues. Plus, we've worked hard to [keep our API down to just 3 common classes](http://realm.io/docs/ios/latest/api/) (Object, Arrays and Realms) and 1 utility class (Migrations): most of our users pick it up intuitively, getting simple apps up & running in minutes.
* **Modern:** Realm supports relationships, generics, vectorization and even Swift (experimental)
* **Fast:** Realm is faster than even raw SQLite on common operations, while maintaining an extremely rich feature set.

## Setting up Realm in your app

There are two ways to set up Realm in your app: manually or with CocoaPods.

Manually:

* [Download Realm.framework](http://static.realm.io/downloads/ios/latest) (or [build it from source](#building-realm))
* Drag Realm.framework into your Xcode project
* Link `libc++.dylib` to your target

CocoaPods:

* Install [CocoaPods](http://cocoapods.org)
* Add `pod "Realm"` to your Podfile
* Run `pod install`

Once your app is set up with Realm, our [documentation](#documentation) will guide you to unleash its full potential.

## Documentation

Documentation for Realm can be found at [realm.io/docs/ios](http://realm.io/docs/ios). The API reference is located at [realm.io/docs/ios/latest/api](http://realm.io/docs/ios/latest/api).

## Building Realm

Prerequisites:
* Building Realm requires Xcode 5 or above
* Building Realm with Swift support requires Xcode6-Beta3 specifically
* Building Realm documentation requires [appledoc](https://github.com/tomaz/appledoc)

Once you have all the necessary prerequisites, building Realm.framework just takes a single command: `sh build.sh ios`. You'll need an internet connection the first time you build Realm to download the core binary.

Run `sh build.sh help` to see all the actions you can perform (build ios/osx, generate docs, test, etc.).

## License

Realm Cocoa is published under the Apache 2.0 license.

![analytics](https://ga-beacon.appspot.com/UA-50247013-2/realm-cocoa/README?pixel)
