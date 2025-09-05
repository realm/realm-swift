# Define a Realm Object Model - Swift SDK
## Define a New Object Type
#### Objective-C

You can define a Realm object by deriving from the
`RLMObject` or
`RLMEmbeddedObject` class. The name of the
class becomes the table name in the realm, and properties of the
class persist in the database. This makes it as easy to work with
persisted objects as it is to work with regular Objective-C
objects.

```objectivec
// A dog has an _id primary key, a string name, an optional
// string breed, and a date of birth.
@interface Dog : RLMObject
@property RLMObjectId *_id;
@property NSString *name;
@property NSString *breed;
@property NSDate *dateOfBirth;
@end

@implementation Dog
+ (NSString *)primaryKey {
    return @"_id";
}

+ (NSArray<NSString *> *)requiredProperties {
    return @[
        @"_id", @"name", @"dateOfBirth"
    ];
}
@end

```

#### Swift

You can define a Realm object by deriving from the
`Object` or
`EmbeddedObject`
class. The name of the class becomes the table name in the realm,
and properties of the class persist in the database. This makes it
as easy to work with persisted objects as it is to work with
regular Swift objects.

```swift
// A dog has an _id primary key, a string name, an optional
// string breed, and a date of birth.
class Dog: Object {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var name = ""
    @Persisted var breed: String?
    @Persisted var dateOfBirth = Date()
}

```

> Note:
> Class names are limited to a maximum of 57 UTF-8 characters.
>

## Declare Properties
When you declare the property attributes of a class, you can specify whether
or not those properties should be managed by the realm. **Managed properties**
are stored or updated in the database. **Ignored properties** are not
stored to the database. You can mix managed and ignored properties
within a class.

The syntax to mark properties as managed or ignored varies depending on which
version of the SDK you use.

### Persisted Property Attributes
> Version added: 10.10.0The  declaration style replaces the ,
, and  declaration notations from older
versions of the SDK. For an older version of the SDK, see:
.

Declare model properties that you want to store to the database as
`@Persisted`. This enables them to access the underlying database data.

When you declare any properties as `@Persisted` within a class, the other
properties within that class are automatically ignored.

If you mix `@Persisted` and `@objc dynamic` property declarations within
a class definition, any property attributes marked as `@objc dynamic` will
be ignored.

> Seealso:
> Our Supported Property Types
page contains a property declaration cheatsheet.
>

### Objective-C Dynamic Property Attributes
> Version changed: 10.10.0This property declaration information is for versions of the SDK before
10.10.0.

Declare dynamic Realm model properties in the Objective-C runtime. This
enables them to access the underlying database data.

You can either:

- Use `@objc dynamic var` to declare individual properties
- Use `@objcMembers` to declare a class. Then, declare individual
properties with `dynamic var`.

Use `let` to declare `LinkingObjects`, `List`, `RealmOptional` and
`RealmProperty`. The Objective-C runtime cannot represent these
generic properties.

> Version changed: 10.8.0
> `RealmProperty` replaces `RealmOptional`
>

> Seealso:
> Our Supported Property Types
page contains a property declaration cheatsheet.
>

> Tip:
> For reference on which types Realm supports for use as
properties, see Supported Property Types.
>

#### Swift

When declaring non-generic properties, use the `@Persisted` annotation.
The `@Persisted` attribute turns Realm model properties into accessors
for the underlying database data.

#### Objective-C

Declare properties on your object type as you would on a normal
Objective-C interface.

In order to use your interface in a Realm array, pass your
interface name to the `RLM_COLLECTION_TYPE()` macro. You can put this
at the bottom of your interface's header file. The
`RLM_COLLECTION_TYPE()` macro creates a protocol that allows you to
tag `RLMArray` with your type:

```objectivec
// Task.h
@interface Task : RLMObject
@property NSString *description;
@end

// Define an RLMArray<Task> type
RLM_COLLECTION_TYPE(Task)

// User.h
// #include "Task.h"
@interface User : RLMObject
@property NSString *name;
// Use RLMArray<Task> to have a list of tasks
// Note the required double tag (<Task *><Task>)
@property RLMArray<Task *><Task> *tasks;
@end

```

#### Swift Pre 10.10.0

When declaring non-generic properties, use the `@objc dynamic
var` annotation. The `@objc dynamic var` attribute turns Realm
model properties into accessors for the underlying database data.
If the class is declared as `@objcMembers` (Swift 4 or later),
you can declare properties as `dynamic var` without `@objc`.

To declare properties of generic types `LinkingObjects`,
`List`, and `RealmProperty`, use `let`. Generic properties
cannot be represented in the Objective‑C runtime, which
Realm uses for dynamic dispatch of dynamic
properties.

> Note:
> Property names are limited to a maximum of 63 UTF-8 characters.
>

### Specify an Optional/Required Property
#### Swift

You can declare properties as optional or required (non-optional) using
standard Swift syntax.

```swift
class Person: Object {
    // Required string property
    @Persisted var name = ""

    // Optional string property
    @Persisted var address: String?

    // Required numeric property
    @Persisted var ageYears = 0

    // Optional numeric property
    @Persisted var heightCm: Float?
}

```

#### Objective-C

To declare a given property as required, implement the
`requiredProperties`
method and return an array of required property names.

```objectivec
@interface Person : RLMObject
// Required property - included in `requiredProperties`
// return value array
@property NSString *name;

// Optional string property - not included in `requiredProperties`
@property NSString *address;

// Required numeric property
@property int ageYears;

// Optional numeric properties use NSNumber tagged
// with RLMInt, RLMFloat, etc.
@property NSNumber<RLMFloat> *heightCm;
@end

@implementation Person
// Specify required pointer-type properties here.
// Implicitly required properties (such as properties
// of primitive types) do not need to be named here.
+ (NSArray<NSString *> *)requiredProperties {
    return @[@"name"];
}
@end

```

#### Swift Pre 10.10.0

> Version changed: 10.8.0
> `RealmProperty` replaces `RealmOptional`
>

You can declare `String`, `Date`, `Data`, and
`ObjectId` properties as
optional or required (non-optional) using standard Swift syntax.
Declare optional numeric types using the `RealmProperty`
type.

```swift
class Person: Object {
    // Required string property
    @objc dynamic var name = ""

    // Optional string property
    @objc dynamic var address: String?

    // Required numeric property
    @objc dynamic var ageYears = 0

    // Optional numeric property
    let heightCm = RealmProperty<Float?>()
}

```

RealmProperty supports `Int`, `Float`, `Double`, `Bool`,
and all of the sized versions of `Int` (`Int8`, `Int16`,
`Int32`, `Int64`).

### Specify a Primary Key
You can designate a property as the **primary key** of your class.

Primary keys allow you to efficiently find, update, and upsert objects.

Primary keys are subject to the following limitations:

- You can define only one primary key per object model.
- Primary key values must be unique across all instances of an object
in a realm. Realm throws an error if you try to
insert a duplicate primary key value.
- Primary key values are immutable. To change the primary key value of
an object, you must delete the original object and insert a new object
with a different primary key value.
- Embedded objects cannot define a
primary key.

#### Swift

Declare the property with `primaryKey: true`
on the `@Persisted` notation to set the model's primary key.

```swift
class Project: Object {
    @Persisted(primaryKey: true) var id = 0
    @Persisted var name = ""
}

```

#### Objective-C

Override `+[RLMObject primaryKey]` to
set the model's primary key.

```objectivec
@interface Project : RLMObject
@property NSInteger id; // Intended primary key
@property NSString *name;
@end

@implementation Project
// Return the name of the primary key property
+ (NSString *)primaryKey {
    return @"id";
}
@end

```

#### Swift Pre 10.10.0

Override `Object.primaryKey()`
to set the model's primary key.

```swift
class Project: Object {
    @objc dynamic var id = 0
    @objc dynamic var name = ""

    // Return the name of the primary key property
    override static func primaryKey() -> String? {
        return "id"
    }
}

```

### Index a Property
You can create an index on a given property of your model. Indexes speed up
queries using equality and IN operators. They make insert and update operation
speed slightly slower. Indexes use memory and take up more space in the realm
file. Each index entry is a minimum of 12 bytes. It's best to only add indexes
when optimizing the read performance for specific situations.

Realm supports indexing for string, integer, boolean, `Date`, `UUID`,
`ObjectId`, and `AnyRealmValue` properties.

> Version added: 10.8.0
> `UUID` and `AnyRealmValue` types
>

#### Swift

To index a property, declare the property with
`indexed:true`
on the `@Persisted` notation.

```swift
class Book: Object {
    @Persisted var priceCents = 0
    @Persisted(indexed: true) var title = ""
}

```

#### Objective-C

To index a property, override `RLMObject
indexedProperties`
and return a list of indexed property names.

```objectivec
@interface Book : RLMObject
@property int priceCents;
@property NSString *title;
@end

@implementation Book
// Return a list of indexed property names
+ (NSArray *)indexedProperties {
    return @[@"title"];
}
@end

```

#### Swift Pre 10.10.0

To index a property, override
`Object.indexedProperties()`
and return a list of indexed property names.

```swift
class Book: Object {
    @objc dynamic var priceCents = 0
    @objc dynamic var title = ""

    // Return a list of indexed property names
    override static func indexedProperties() -> [String] {
        return ["title"]
    }
}

```

### Ignore a Property
Ignored properties behave exactly like normal properties. They can't be
used in queries and won't trigger Realm notifications. You can still
observe them using [KVO](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/KeyValueObserving/KeyValueObserving.html).

> Tip:
> Realm automatically ignores read-only properties.
>

#### Swift

> Deprecated:

If you don't want to save a field in your model to its realm,
leave the `@Persisted` notation off the property attribute.

Additionally, if you mix `@Persisted` and `@objc dynamic`
property declarations within a class, the `@objc dynamic`
properties will be ignored.

```swift
class Person: Object {
    // If some properties are marked as @Persisted,
    // any properties that do not have the @Persisted
    // annotation are automatically ignored.
    var tmpId = 0

    // The @Persisted properties are managed
    @Persisted var firstName = ""
    @Persisted var lastName = ""

    // Read-only properties are automatically ignored
    var name: String {
        return "\(firstName) \(lastName)"
    }

    // If you mix the pre-10.10 property declaration
    // syntax `@objc dynamic` with the 10.10+ @Persisted
    // annotation within a class, `@objc dynamic`
    // properties are ignored.
    @objc dynamic var email = ""
}

```

#### Objective-C

If you don't want to save a field in your model to its realm,
override `+[RLMObject ignoredProperties]`
and return a list of ignored property names.

```objectivec
@interface Person : RLMObject
@property NSInteger tmpId;
@property (readonly) NSString *name; // read-only properties are automatically ignored
@property NSString *firstName;
@property NSString *lastName;
@end

@implementation Person
+ (NSArray *)ignoredProperties {
    return @[@"tmpId"];
}
- (NSString *)name {
    return [NSString stringWithFormat:@"%@ %@", self.firstName, self.lastName];
}
@end

```

#### Swift Pre 10.10.0

If you don't want to save a field in your model to its realm,
override `Object.ignoredProperties()`
and return a list of ignored property names.

```swift
class Person: Object {
    @objc dynamic var tmpId = 0
    @objc dynamic var firstName = ""
    @objc dynamic var lastName = ""

    // Read-only properties are automatically ignored
    var name: String {
        return "\(firstName) \(lastName)"
    }

    // Return a list of ignored property names
    override static func ignoredProperties() -> [String] {
        return ["tmpId"]
    }
}

```

### Declare Enum Properties
#### Swift

> Version changed: 10.10.0
> Protocol is now `PersistableEnum` rather than `RealmEnum`.
>

You can use enums with `@Persisted` by marking them as complying with the
`PersistableEnum`
protocol. A `PersistableEnum` can be any `RawRepresentable` enum
whose raw type is a type that Realm supports.

```swift
// Define the enum
enum TaskStatusEnum: String, PersistableEnum {
    case notStarted
    case inProgress
    case complete
}

// To use the enum:
class Task: Object {
    @Persisted var name: String = ""
    @Persisted var owner: String?

    // Required enum property
    @Persisted var status = TaskStatusEnum.notStarted

    // Optional enum property
    @Persisted var optionalTaskStatusEnumProperty: TaskStatusEnum?
}

```

#### Swift Pre 10.10.0

Realm supports only `Int`-backed `@objc` enums.

```swift
// Define the enum
@objc enum TaskStatusEnum: Int, RealmEnum {
    case notStarted = 1
    case inProgress = 2
    case complete = 3
}

// To use the enum:
class Task: Object {
    @objc dynamic var name: String = ""
    @objc dynamic var owner: String?

    // Required enum property
    @objc dynamic var status = TaskStatusEnum.notStarted
    // Optional enum property
    let optionalTaskStatusEnumProperty = RealmProperty<TaskStatusEnum?>()
}

```

> Seealso:
> `RealmEnum`
>

### Remap a Property Name
> Version added: 10.33.0

You can map the public name of a property in your object model to a different
private name to store in the realm.

Declare the name you want to use in your project as the `@Persisted`
property on the object model. Then, pass a dictionary containing the
public and private values for the property names via the
`propertiesMapping()` function.

In this example, `firstName` is the public property name we use in the code
throughout the project to perform CRUD operations. Using the `propertiesMapping()`
function, we map that to store values using the private property name
`first_name` in the realm.

```swift
class Person: Object {
    @Persisted var firstName = ""
    @Persisted var lastName = ""

    override class public func propertiesMapping() -> [String: String] {
        ["firstName": "first_name",
         "lastName": "last_name"]
    }
}

```

## Define a Class Projection
### About These Examples
The examples in this section use a simple data set. The two Realm object
types are `Person` and an embedded object `Address`. A `Person` has
a first and last name, an optional `Address`, and a list of friends
consisting of other `Person` objects. An `Address` has a city and country.

See the schema for these two classes, `Person` and `Address`, below:

```swift
class Person: Object {
    @Persisted var firstName = ""
    @Persisted var lastName = ""
    @Persisted var address: Address?
    @Persisted var friends = List<Person>()
}

class Address: EmbeddedObject {
    @Persisted var city: String = ""
    @Persisted var country = ""
}

```

### How to Define a Class Projection
> Version added: 10.21.0

Define a class projection by creating a class of type `Projection`. Specify the `Object`
or `EmbeddedObject` base whose
properties you want to use in the class projection. Use the `@Projected`
property wrapper to declare a property that you want to project from a
`@Persisted` property on the base object.

> Note:
> When you use a List or a MutableSet in a class projection, the type in the
class projection should be `ProjectedCollection`.
>

```swift
class PersonProjection: Projection<Person> {
    @Projected(\Person.firstName) var firstName // Passthrough from original object
    @Projected(\Person.address?.city) var homeCity // Rename and access embedded object property through keypath
    @Projected(\Person.friends.projectTo.firstName) var firstFriendsName: ProjectedCollection<String> // Collection mapping
}

```

When you define a class projection, you can transform the original `@Persisted`
property in several ways:

- Passthrough: the property is the same name and type as the original object
- Rename: the property has the same type as the original object, but a
different name
- Keypath resolution: use keypath resolution to access properties of the
original object, including embedded object properties
- Collection mapping: Project lists or
mutable sets of `Object` s or
`EmbeddedObject` s as a collection of primitive values
- Exclusion: when you use a class projection, the underlying object's
properties that are not `@Projected` through the class projection are
excluded. This enables you to watch for changes to a class projection
and not see changes for properties that are not part of the class
projection.

## Define Unstructured Data
> Version added: 10.51.0

Starting in SDK version 10.51.0, you can store collections of mixed data
within a `AnyRealmValue` property. You can use this feature to model complex data
structures, such as JSON, without having to define a
strict data model.

**Unstructured data** is data that doesn't easily conform to an expected
schema, making it difficult or impractical to model to individual
data classes. For example, your app might have highly variable data or dynamic
data whose structure is unknown at runtime.

Storing collections in a mixed property offers flexibility without sacrificing
functionality. And
you can work with them the same way you would a non-mixed
collection:

- You can nest mixed collections up to 100 levels.
- You can query on and react to changes on mixed collections.
- You can find and update individual mixed collection elements.

However, storing data in mixed collections is less performant than using a structured
schema or serializing JSON blobs into a single string property.

To model unstructured data in your app, define the appropriate properties in
your schema as AnyRealmValue types. You can then
set these `AnyRealmValue` properties as a list or a
dictionary collection of `AnyRealmValue` elements.
Note that `AnyRealmValue` *cannot* represent a `MutableSet` or an embedded
object.

> Tip:
> - Use a map of mixed data types when the type is unknown but each value will have a unique identifier.
> - Use a list of mixed data types when the type is unknown but the order of
objects is meaningful.
>
