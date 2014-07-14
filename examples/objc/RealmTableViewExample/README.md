# Realm Table View Example

This very simple project demonstrates how to create a `UITableViewController` backed by Realm.

![Screenshot](screenshot.png)

You can add rows by tapping the add button and remove rows by swiping right-to-left.

The application also demonstrates how to import large amounts of data in a background thread.

You'll have to build the `Realm.framework` to be able to run this project. Run this command from the root of this repository:

```objc
$ sh build.sh ios
```

If you wish to run in debug mode, you must build the framework for that configuration:

```obj_c
$ sh build.sh ios-debug
```

See [realm.io](http://realm.io/docs/ios) for documentation and more information about Realm.
