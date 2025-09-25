# Use Realm with SwiftUI Previews
## Overview
SwiftUI Previews are a useful tool during development. You can work with Realm
data in SwiftUI Previews in a few ways:

- Initialize individual objects to use in detail views
- Conditionally use an array of objects in place of `@ObservedResults`
- Create a realm that contains data for the previews

SwiftUI Preview debugging can be opaque, so we also have a few tips to debug
issue with persisting Realms within SwiftUI Previews.

### Initialize an Object for a Detail View
In the simplest case, you can use SwiftUI Previews with one or more objects
that use Realm properties you can set directly at initialization.
You might want to do this when previewing a Detail view. Consider DoggoDB's
`DogDetailView`:

```swift
struct DogDetailView: View {
    @ObservedRealmObject var dog: Dog

    var body: some View {
        VStack {
            Text(dog.name)
                .font(.title2)
            Text("\(dog.name) is a \(dog.breed)")
            AsyncImage(url: dog.profileImageUrl) { image in
                            image.resizable()
                        } placeholder: {
                            ProgressView()
                        }
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150, height: 150)
            Text("Favorite toy: \(dog.favoriteToy)")
        }
    }
}

```

Create an extension for your model object. Where you put this extension depends
on convention in your codebase. You may put it directly in the model file,
have a dedicated directory for sample data, or use some other convention in
your codebase.

In this extension, initialize one or more Realm objects with `static let`:

```swift
extension Dog {
    static let dog1 = Dog(value: ["name": "Lita", "breed": "Lab mix", "weight": 27, "favoriteToy": "Squeaky duck", "profileImageUrl": "https://www.corporaterunaways.com/images/2021/04/lita-768x768.jpeg"])
    static let dog2 = Dog(value: ["name": "Maui", "breed": "English Springer Spaniel", "weight": 42, "favoriteToy": "Wubba", "profileImageUrl": "https://www.corporaterunaways.com/images/2021/04/maui_with_leaf-768x576.jpeg"])
    static let dog3 = Dog(value: ["name": "Ben", "breed": "Border Collie mix", "weight": 48, "favoriteToy": "Frisbee", "profileImageUrl": "https://www.corporaterunaways.com/images/2012/03/ben-630x420.jpg"])

}

```

In this example, we initialize objects with a value. You can only initialize objects with
a value when your model contains properties that you can directly initialize.
If your model object contains properties that are only mutable within a
write transaction, such as a List property,
you must instead create a realm to use with your SwiftUI Previews.

After you have initialized an object as an extension of your model class,
you can use it in your SwiftUI Preview. You can pass the object directly
to the View in the Preview:

```swift
struct DogDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DogDetailView(dog: Dog.dog1)
        }
    }
}

```

### Conditionally Use ObservedResults in a List View
When you use `@ObservedResults`
in a List view, this implicitly opens a realm and queries it. For this to
work in a Preview, you need a realm populated with data. As an alternative, you can conditionally
use a static array in Previews and only use the `@ObservedResults` variable
when running the app.

You could do this in multiple ways, but for the sake of making our
code easier to read and understand, we'll create an `EnvironmentValue`
that can detect whether the app is running in a Preview:

```swift
import Foundation
import SwiftUI

public extension EnvironmentValues {
   var isPreview: Bool {
      #if DEBUG
      return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
      #else
      return false
      #endif
   }
}
```

Then, we can use this as an environment value in our view, and conditionally
change which variable we use based on whether or not we are in a Preview.

This example builds on the Dog extension we defined above. We'll create an `dogArray` as
a `static let` in our Dog extension, and include the item objects we
already created:

```swift
static let dogArray = [dog1, dog2, dog3]
```

Then, when we iterate through our List, use the static `dogArray` if
running in a Preview, or use the `@ObservedResults` query if not in a Preview.

```swift
struct DogsView: View {
   @Environment(\.isPreview) var isPreview
   @ObservedResults(Dog.self) var dogs
   var previewDogs = Dog.dogArray

   var body: some View {
      NavigationView {
         VStack {
            List {
               if isPreview {
                  ForEach(previewDogs) { dog in
                     DogRow(dog: dog)
                  }
               } else {
                  ForEach(dogs) { dog in
                     DogRow(dog: dog)
                  }.onDelete(perform: $dogs.remove)
               }
            }
            ... More View code
```

This has the benefit of being lightweight and not persisting any data, but
the downside of making the View code more verbose. If you prefer cleaner
View code, you can create a realm with data that you use in the Previews.

### Create a Realm with Data for Previews
In some cases, your only option to see realm data in a SwiftUI Preview
is to create a realm that contains the data. You might do this when populating
a property that can only be populated during a write transaction, rather
than initialized directly with a value, such as a List or MutableSet.
You might also want to do this if your view relies on more complex object
hierarchies being passed in from other views.

However, using a realm directly does inject state into your SwiftUI Previews,
which can come with drawbacks. Whether you're using Realm or Core Data,
stateful SwiftUI Previews can cause issues like:

- Seeing unexpected or duplicated data due to re-running the realm file
creation steps repeatedly
- Needing to perform a migration within the SwiftUI Preview when you make model changes
- Potential issues related to changing state within views
- Unexplained crashes or performance issues related to issues that are not
surfaced in a visible way in SwiftUI Previews

You can avoid or fix some of these issues with these tips:

- Use an in-memory realm, when possible (demonstrated in the example above)
- Manually delete all preview data from the command line to reset state
- Check out diagnostic logs to try to troubleshoot SwiftUI Preview issues

You can create a static variable for your realm in your model extension.
This is where you do the work to populate your realm. In our case, we
create a `Person` and append some `Dog` objects to the `dogs`
List property. This example builds on the example above where we initialized
a few Dog objects in an Dog extension.

We'll create a `Person` extension, and create a single `Person` object
in that extension. Then, we'll create a `previewRealm` by adding the
`Person` we just created, and appending the example `Dog` objects from
the `Dog` extension.

To avoid adding these objects more than once, we add a check to see if the
Person already exists by querying for Person objects and checking that
the count is 1. If the realm contains a Person, we can use it in our
SwiftUI Preview. If not, we add the data.

```swift
static var previewRealm: Realm {
    var realm: Realm
    let identifier = "previewRealm"
    let config = Realm.Configuration(inMemoryIdentifier: identifier)
    do {
        realm = try Realm(configuration: config)
        // Check to see whether the in-memory realm already contains a Person.
        // If it does, we'll just return the existing realm.
        // If it doesn't, we'll add a Person append the Dogs.
        let realmObjects = realm.objects(Person.self)
        if realmObjects.count == 1 {
            return realm
        } else {
            try realm.write {
                realm.add(person)
                person.dogs.append(objectsIn: [Dog.dog1, Dog.dog2, Dog.dog3])
            }
            return realm
        }
    } catch let error {
        fatalError("Can't bootstrap item data: \(error.localizedDescription)")
    }
}

```

To use it in the SwiftUI Preview, our ProfileView code expects a Profile.
This is a projection of the Person object. In our
Preview, we can get the realm, query it for the Profile, and pass it to the
view:

```swift
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        let realm = Person.previewRealm
        let profile = realm.objects(Profile.self)
        ProfileView(profile: profile.first!)
    }
}

```

If you don't have a View that is expecting a realm object to be passed in,
but instead uses `@ObservedResults` to query a realm or otherwise work
with an existing realm, you can inject the realm into the view as an
environment value:

```swift
struct SomeListView_Previews: PreviewProvider {
   static var previews: some View {
      SomeListView()
         .environment(\.realm, Person.previewRealm)
   }
}
```

#### Use an In-Memory Realm
When possible, use an in-memory realm
to get around some of the state-related issues that can come from using
a database within a SwiftUI Preview.

Use the `inMemoryIdentifier`
configuration property when you initialize the realm.

```swift
static var previewRealm: Realm {
   var realm: Realm
   let identifier = "previewRealm"
   let config = Realm.Configuration(inMemoryIdentifier: identifier)
   do {
      realm = try Realm(configuration: config)
      // ... Add data to realm
```

> Note:
> Do not use the the `deleteRealmIfMigrationNeeded`
configuration property when you initialize a realm for SwiftUI Previews.
Due to the way Apple has implemented SwiftUI Previews, using this property
to bypass migration issues causes SwiftUI Previews to crash.
>

#### Delete SwiftUI Previews
If you run into other SwiftUI Preview issues related to state,
such as a failure to load a realm in a Preview due to migration being
required, there are a few things you can do to remove cached Preview data.

The Apple-recommended fix is to close Xcode and use the command line to
delete all your existing SwiftUI Preview data.

1. Close Xcode.
2. From your command line, run: `xcrun simctl --set previews delete all`

It's possible that data may persist after running this command. This is
likely due to Xcode retaining a reference due to something in the Preview
and being unable to delete it. You can also try these steps to resolve issues:

- Build for a different simulator
- Restart the computer and re-run `xcrun simctl --set previews delete all`
- Delete stored Preview data directly. This data is stored in
`~/Library/Developer/Xcode/UserData/Previews`.

#### Get Detailed Information about SwiftUI Preview Crashes
If you have an unexplained SwiftUI Preview crash when using realm, first try
running the application on the simulator. The error messaging and logs available
for the simulator make it easier to find and diagnose issues. If you can
debug the issue in the simulator, this is the easiest route.

If you cannot replicate a SwiftUI Preview crash in the simulator, you can
view crash logs for the SwiftUI Preview app. These logs are available in
`~/Library/Logs/DiagnosticReports/`. These logs sometimes appear after
a delay, so wait a few minutes after a crash if you don't see the relevant
log immediately.
