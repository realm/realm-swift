# Test and Debug - Swift SDK
## Testing
### Test Using a Default Realm
The easiest way to use and test Realm-backed applications
is to use the default realm. To avoid overriding application data or
leaking state between tests, set the default realm to a new file for
each test.

```swift
// A base class which each of your Realm-using tests should inherit from rather
// than directly from XCTestCase
class TestCaseBase: XCTestCase {
    override func setUp() {
        super.setUp()

        // Use an in-memory Realm identified by the name of the current test.
        // This ensures that each test can't accidentally access or modify the data
        // from other tests or the application itself, and because they're in-memory,
        // there's nothing that needs to be cleaned up.
        Realm.Configuration.defaultConfiguration.inMemoryIdentifier = self.name
    }
}

```

### Injecting Realm Instances
Another way to test Realm-related code is to have all the
methods you'd like to test accept a realm instance as an argument. This
enables you to pass in different realms when running the app and when
testing it.

For example, suppose your app has a method to `GET` a user profile
from a JSON API. You want to test that the local profile is properly
created.

### Simplify Testing with Class Projections
> Version added: 10.21.0

If you want to work with a subset of an object's properties for testing,
you can create a class projection.
A class projection is a model abstraction where you can pass through, rename,
or exclude realm object properties. While this feature simplifies view
model implementation, it also simplifies testing with Realm.

> Example:
> This example uses the object models
and the class projection from the
Define and Use Class Projections page.
>
> In this example, we create a realm object using the full object model.
Then, we view retrieve the object as a class projection, working with
only a subset of its properties.
>
> With this class projection, we don't need to access or account for
properties that we don't need to test.
>
> ```swift
> func testWithProjection() {
>     let realm = try! Realm()
>     // Create a Realm object, populate it with values
>     let jasonBourne = Person(value: ["firstName": "Jason",
>                                                        "lastName": "Bourne",
>                                                        "address": [
>                                                         "city": "Zurich",
>                                                         "country": "Switzerland"]])
>     try! realm.write {
>         realm.add(jasonBourne)
>     }
>
>     // Retrieve all class projections of the given type `PersonProjection`
>     // and filter for the first class projection where the `firstName` property
>     // value is "Jason"
>     let person = realm.objects(PersonProjection.self).first(where: { $0.firstName == "Jason" })!
>     // Verify that we have the correct PersonProjection
>     XCTAssert(person.firstName == "Jason")
>     // See that `homeCity` exists as a projection property
>     // Although it is not on the object model
>     XCTAssert(person.homeCity == "Zurich")
>
>     // Change a value on the class projection
>     try! realm.write {
>         person.firstName = "David"
>     }
>
>     // Verify that the projected property's value has changed
>     XCTAssert(person.firstName == "David")
> }
>
> ```
>

### Test Targets
Don't link the Realm framework directly to your test target.
This can cause your tests to fail with an exception message "Object type
'YourObject' is not managed by the Realm." Unlinking Realm
from your test target should resolve this issue.

Compile your model class files in your application or framework targets;
don't add them to your unit test targets. Otherwise, those classes are
duplicated when testing, which can lead to difficult-to-debug issues.

Expose all the code that you need for testing to your unit test
targets. Use the `public` access modifier or [@testable](https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/testing_with_xcode/chapters/04-writing_tests.html).

Since you're using Realm as a dynamic framework, you'll
need to make sure your unit test target can find Realm.
Add the parent path to `RealmSwift.framework` to your unit test's
"Framework Search Paths".

## Debugging
### Debug Using Realm Studio
Realm Studio enables you to open and edit local
realms. It supports Mac, Windows and Linux.

### LLDB
Debugging apps using Realm's Swift API must be done through
the LLDB console.

Although the LLDB script allows inspecting the contents of your realm
variables in Xcode's UI, this doesn't yet work for Swift. Those
variables will show incorrect data. Instead, use LLDB's `po`
command to inspect the contents of data stored in a realm.

## Troubleshooting
### Resolve Build Issues
Some developers experience build issues after installing the Realm Swift SDK via
CocoaPods or Carthage. Common causes of these issues include:

- Installation issues: Initial install failedUsing an unsupported version of the dependency manager
- Build tool issues: Build tools have stale cachesUpdating build tool versions
- Making changes to your project setup, such as: Adding a new targetSharing dependencies across targets

A fix that often clears these issues is to delete derived data
and clean the Xcode build folder.

#### Cocoapods

##### Reset the Cocoapods Integration State
Run these commands in the terminal, in the root of your project:

```bash
pod cache clean Realm
pod cache clean RealmSwift
pod deintegrate || rm -rf Pods
pod install --repo-update --verbose
# Assumes the default DerivedData location:
rm -rf ~/Library/Developer/Xcode/DerivedData
```

##### Clean the Xcode Build Folder
With your project open in Xcode, go to the Product drop-down menu,
and select Clean Build Folder.

#### Carthage

##### Reset Carthage-managed Dependency State
Run these commands in the terminal, in the root of your project:

```bash
rm -rf Carthage
# Assumes default DerivedData location:
rm -rf ~/Library/Developer/Xcode/DerivedData
carthage update
```

##### Clean the Xcode Build Folder
With your project open in Xcode, go to the Product drop-down menu,
and select Clean Build Folder.

### Issues Opening Realm Before Loading the UI
You may open a realm and immediately see crashes with error messages
related to properties being optional or required. Issues with your
object model can cause
these types of crashes. These errors occur after you open a realm,
but before you get to the UI.

Realm has a "schema discovery" phase when a realm opens on the device.
At this time, Realm examines the schema for any objects that it manages.
You can specify that a given realm should manage only a subset
of objects in your
application.

If you see errors related to properties during schema discovery, these are
likely due to schema issues and not issues with data from a specific object.
For example, you may see schema discovery errors if you define a to-one
relationship as required
instead of optional.

To debug these crashes, check the schema you've defined.

You can tell these are schema discovery issues because they occur before
the UI loads. This means that no UI element is attempting to incorrectly
use a property, and there aren't any objects in memory that could have
bad data. If you get errors related to properties *after* the UI loads,
this is probably not due to invalid schema. Instead, those errors are
likely a result of incorrect, wrongly-typed or missing data.

### No Properties are Defined for Model
The Realm Swift SDK uses the Swift language reflection feature to determine
the properties in your model at runtime. If you get a crash similar to
the following, confirm that your project has not disabled reflection metadata:

```shell
Terminating app due to uncaught exception 'RLMException', reason: 'No properties are defined for 'ObjectName'.
```

If you set `SWIFT_REFLECTION_METADATA_LEVEL = none`, Realm cannot
discover children of types, such as properties and enums. Reflection is
enabled by default if your project does not specifically set a level for
this setting.

### Bad Alloc/Not Enough Memory Available
In iOS or iPad devices with little available memory, or where you have a
memory-intensive application that uses multiple realms or many notifications,
you may encounter the following error:

```console
libc++abi: terminating due to an uncaught exception of type std::bad_alloc: std::bad_alloc
```

This error typically indicates that a resource cannot be allocated because
not enough memory is available.

If you are building for iOS 15+ or iPad 15+, you can add the
[Extended Virtual Addressing Entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_developer_kernel_extended-virtual-addressing)
to resolve this issue.

Add these keys to your Property List, and set the values to `true`:

```xml
<key>com.apple.developer.kernel.extended-virtual-addressing</key>
<true/>
<key>com.apple.developer.kernel.increased-memory-limit</key>
<true/>
```

### Swift Package Target Cannot be Built Dynamically
> Version changed: 10.49.3

Swift SDK v10.49.3 changed the details for installing the package with
Swift Package Manager (SPM). When you update from an older version of the
package to v10.49.3 or newer, you may get a build error similar to:

```console
Swift package target `Realm` is linked as a static library by `TargetName`
and `Realm`, but cannot be built dynamically because there is a package
product with the same name.
```

To resolve this error, unlink either the `Realm` or the `RealmSwift`
package from your build target. You can do this in Xcode by following these
steps:

1. In your project Targets, select your build target.
2. Go to the Build Phases tab.
3. Expand the Link Binary With Libraries element.
4. Select either `Realm` or `RealmSwift`, and click the Remove items
(-) button to remove the unneeded binary. If you use Swift or Swift
and Objective-C APIs, keep `RealmSwift`. If you use only Objective-C
APIs, keep `Realm`.

Now your target should build without this error.
