# Realm Visual Editor

This project builds a Mac OS app that allows you to open, browse & edit .realm files.


## Installing

If you are just looking to install this app on your machine, the easiest way is to download the [latest release of Realm](http://realm.io/docs/ios/latest). The zip releases contain an easy-to-build version of this tool under the `tools/` folder.


## Modifying

If you want to modify this tool, read on for instructions on how to build it locally from the files in this folder.

1. Build the Realm framework
  - Navigate to the root directory for your realm-objc repo
  - Open the Realm.xcodeproj project in Xcode.
  - Build the “OSX Framework” target.
  - Under “Products” in Xcode’s File navigator, right click on the “Realm.framework” product and select “Show in Finder”.
  - Copy the Realm.framework back to the build sub-directory in the Realm project directory.
2. Build the Visual Editor application
  - Open the tools/RealmVisualEditor.xcodeproj project in Xcode
  - Build and run!
