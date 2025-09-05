# Supported Types - Swift SDK
## Collection Types
Realm has several types to represent groups of objects,
which we call **collections**. A collection is an object that contains
zero or more instances of one Realm type. Realm collections are **homogenous**:
all objects in a collection are of the same type.

You can filter and sort any collection using Realm's
query engine. Collections are
live, so they always reflect the current state
of the realm instance on the current thread. You can also
listen for changes in the collection by subscribing to collection
notifications.

All collection types conform to the `RealmCollection` protocol. This protocol inherits from
`CollectionType`, so you can use
a Realm collection as you would any other standard library
collections.

Using the RealmCollection protocol, you can write generic code that can
operate on any Realm collection:

```swift
func operateOn<C: RealmCollection>(collection: C) {
    // Collection could be either Results or List
    print("operating on collection containing \(collection.count) objects")
}

```

### Results and Sectioned Results
The Swift SDK `Results` collection is
a class representing objects retrieved from queries. A
`[Results` collection represents the
lazily-evaluated results of a query operation. Results are immutable:
you cannot add or remove elements to or from the results collection.
Results have an associated query that determines their contents.

The Swift SDK also provides `SectionedResults`,
a type-safe collection which holds `ResultsSection` as its elements.
Each `ResultSection` is a results
collection that contains only objects that belong to a given section key.

For example, an app that includes a contact list might use SectionedResults
to display a list of contacts divided into sections, where each section
contains all the contacts whose first name starts with the given letter.
The `ResultsSection` whose key is "L" would contain "Larry", "Liam",
and "Lisa".

> Seealso:
> Reads
>

### Collections as Properties
The Swift SDK also offers several collection types you can use as properties
in your data model:

1. `List`, a class representing
to-many relationships in models.
2. `LinkingObjects`, a class
representing inverse relationships in models.
3. MutableSet, a class representing
a to-many relationship.
4. Map, a class representing an associative array of key-value
pairs with unique keys.
5. `AnyRealmCollection`, a [type-erased](https://en.wikipedia.org/wiki/Type_erasure) class that can forward calls to a concrete Realm collection like Results, List or LinkingObjects.

### Collections are Live
Like live objects, Realm collections
are usually **live**:

- Live results collections always reflect the current results of the associated query.
- Live lists always reflect the current state of the relationship on the realm instance.

There are two cases when a collection is **not** live:

- The collection is unmanaged. For example, a List property of
a Realm object that has not been added to a realm yet
or that has been copied from a realm is not live.
- The collection is frozen.

Combined with collection notifications, live collections enable
clean, reactive code. For example, suppose your view displays the
results of a query. You can keep a reference to the results collection
in your view class, then read the results collection as needed without
having to refresh it or validate that it is up-to-date.

> Important:
> Since results update themselves automatically, do not
store the positional index of an object in the collection
or the count of objects in a collection. The stored index
or count value could be outdated by the time you use
it.
>

## Supported Property Types
You can use the following types to define your object model
properties.

### Property Cheat Sheet
#### Swift

> Version changed: 10.10.0
> `@Persisted` property declaration syntax
>

|Type|Required|Optional|
| --- | --- | --- |
|Bool|`@Persisted var boolName: Bool`|`@Persisted var optBoolName: Bool?`|
|Int, Int8, Int16, Int32, Int64|`@Persisted var intName: Int`|`@Persisted var optIntName: Int?`|
|Float|`@Persisted var floatName: Float`|`@Persisted var optFloatName: Float?`|
|Double|`@Persisted var doubleName: Double`|`@Persisted var optDoubleName: Double?`|
|String|`@Persisted var stringName: String`|`@Persisted var optStringName: String?`|
|Data|`@Persisted var dataName: Data`|`@Persisted var optDataName: Data?`|
|Date|`@Persisted var dateName: Date`|`@Persisted var optDateName: Date?`|
|Decimal128|`@Persisted var decimalName: Decimal128`|`@Persisted var optDecimalName: Decimal128?`|
|`UUID`|`@Persisted var uuidName: UUID`|`@Persisted var optUuidName: UUID?`|
|`ObjectId`|`@Persisted var objectIdName: ObjectId`|`@Persisted var optObjectIdName: ObjectId?`|
|`List`|`@Persisted var listName: List<MyCustomObjectType>`|N/A|
|MutableSet|`@Persisted var mutableSetName: MutableSet<String>`|N/A|
|Map|`@Persisted var mapName: Map<String, String>`|N/A|
|AnyRealmValue|`@Persisted var anyRealmValueName: AnyRealmValue`|N/A|
|User-defined `Object`|N/A|`@Persisted var optObjectPropertyName: MyCustomObjectType?`|
|User-defined `EmbeddedObject`|N/A|`@Persisted var optEmbeddedObjectPropertyName: MyEmbeddedObjectType?`|
|User-defined `Enums`|`@Persisted var enumName: MyPersistableEnum`|`@Persisted var optEnumName: MyPersistableEnum?`|

`CGFloat` properties are discouraged, as the type is not
platform independent.

To use Key-Value Coding with a user-defined object in the `@Persisted`
syntax, add the `@objc` attribute: `@Persisted @objc var myObject: MyClass?`

##### Setting Default Values
With the `@Persisted` property declaration syntax, you may see a
performance impact when setting default values for:

- `List`
- `MutableSet`
- `Dictionary`
- `Decimal128`
- `UUID`
- `ObjectId`

`@Persisted var listProperty: List<Int>` and `@Persisted var
listProperty = List<Int>()` are both valid, and are functionally
equivalent. However, the second declaration will result in poorer
performance.

This is because the List is created when the parent object is
created, rather than lazily as needed. For most types, this is
a difference so small you can't measure it. For the types listed
here, you may see a performance impact when using the second
declaration style.

#### Objective-C

|Type|Required|Optional|
| --- | --- | --- |
|Boolean|`@property BOOL boolName;`|`@property NSNumber<RLMBool> *optBoolName;`|
|Integer|`@property int intName;`|`@property NSNumber<RLMInt> *optIntName;`|
|Float|`@property float floatName;`|`@property NSNumber<RLMFloat> *optFloatName;`|
|Double|`@property double doubleName;`|`@property NSNumber<RLMDouble> *optDoubleName;`|
|String|`@property NSString *stringName;`|`@property NSString *optStringName;`|
|Data|`@property NSData *dataName;`|`@property NSData *optDataName;`|
|Date|`@property NSDate *dateName;`|`@property NSDate *optDateName;`|
|Decimal128|`@property RLMDecimal128 *decimalName;`|`@property RLMDecimal128 *optDecimalName;`|
|NSUUID|`@property NSUUID *uuidName;`|`@property NSUUID *optUuidName;`|
|`RLMObjectId`|`@property RLMObjectId *objectIdName;`|`@property RLMObjectId *optObjectIdName;`|
|`RLMArray`|`@property RLMArray<MyObject *><MyObject> *arrayName;`|N/A|
|`RLMSet`|`@property RLMSet<RLMString> *setName;`|N/A|
|`RLMDictionary`|`@property RLMDictionary<NSString *, NSString *><RLMString, RLMString> *dictionaryName;`|N/A|
|User-defined `RLMObject`|N/A|`@property MyObject *optObjectPropertyName;`|
|User-defined `RLMEmbeddedObject`|N/A|`@property MyEmbeddedObject *optEmbeddedObjectPropertyName;`|

Additionally:

- Integral types `int`, `NSInteger`, `long`, `long long`

`CGFloat` properties are discouraged, as the type is not
platform independent.

#### Swift Pre 10.10.0

> Version changed: 10.8.0
> `RealmProperty` replaces `RealmOptional`
>

|Type|Required|Optional|
| --- | --- | --- |
|Bool|`@objc dynamic var value = false`|`let value = RealmProperty<Bool?>()`|
|Int, Int8, Int16, Int32, Int64|`@objc dynamic var value = 0`|`let value = RealmProperty<Int?>()`|
|Float|`@objc dynamic var value: Float = 0.0`|`let value = RealmProperty<Float?>()`|
|Double|`@objc dynamic var value: Double = 0.0`|`let value = RealmProperty<Double?>()`|
|String|`@objc dynamic var value = ""`|`@objc dynamic var value: String? = nil`|
|Data|`@objc dynamic var value = Data()`|`@objc dynamic var value: Data? = nil`|
|Date|`@objc dynamic var value = Date()`|`@objc dynamic var value: Date? = nil`|
|Decimal128|`@objc dynamic var decimal: Decimal128 = 0`|`@objc dynamic var decimal: Decimal128?`|
|`UUID`|`@objc dynamic var uuid = UUID()`|`@objc dynamic var uuidOpt: UUID?`|
|`ObjectId`|`@objc dynamic var objectId = ObjectId.generate()`|`@objc dynamic var objectId: ObjectId?`|
|`List`|`let value = List<Type>()`||
|MutableSet|`let value = MutableSet<Type>()`||
|Map|`let value = Map<String, String>()`||
|AnyRealmValue|`let value = RealmProperty<AnyRealmValue>()`|N/A|
|User-defined `Object`|N/A|`@objc dynamic var value: MyClass?`|

Additionally:

- `EmbeddedObject`-derived types
- `Enum`

You can use `RealmProperty <T?>` to
represent integers, doubles, and other types as optional.

`CGFloat` properties are discouraged, as the type is not
platform independent.

### Unique Identifiers
> Version added: 10.8.0
> `UUID` type
>

`ObjectId` is a 12-byte unique value. `UUID` is a
16-byte globally-unique value. You can index
both types, and use either as a primary key.

> Note:
> When declaring default values for `@Persisted` UUID or ObjectId property
attributes, both of these syntax types are valid:
>
> - `@Persisted var value: UUID`
> - `@Persisted var value = UUID()`
>
> However, the second will result in poorer performance. This is because the
latter creates a new identifier that is never used any time an object is
read from the realm, while the former only creates them when needed.
>
> `@Persisted var id: ObjectId` has equivalent behavior to `@objc dynamic
var _id = ObjectId.generate()`. They both make random ObjectIds.
>
> `@Persisted var _id = ObjectId()` has equivalent behavior to `@objc
dynamic var _id = ObjectId()`. They both make zero-initialized ObjectIds.
>

### Size Limitations
Data and string properties cannot hold more than 16MB. To store
larger amounts of data, either:

- Break the data into 16MB chunks, or
- Store data directly on the file system and store paths to the files in the realm.

Realm throws a runtime exception if your app attempts to
store more than 16MB in a single property.

To avoid size limitations and a performance impact, it is best not to
store large blobs, such as image and video files, directly in a
realm. Instead, save the file to a file store and keep only the
location of the file and any relevant metadata in the realm.

### AnyRealmCollection
To store a collection as a property or variable without needing to know
the concrete collection type, Swift's type system requires a type-erased
wrapper like `AnyRealmCollection`:

```swift
class ViewController {
//    let collection: RealmCollection
//                    ^
//                    error: protocol 'RealmCollection' can only be used
//                    as a generic constraint because it has Self or
//                    associated type requirements
//
//    init<C: RealmCollection>(collection: C) where C.ElementType == MyModel {
//        self.collection = collection
//    }

    let collection: AnyRealmCollection<MyModel>

    init<C: RealmCollection & _ObjcBridgeable>(collection: C) where C.ElementType == MyModel {
        self.collection = AnyRealmCollection(collection)
    }
}

```

### Mutable Set
> Version added: 10.8.0

A `MutableSet`
collection represents a to-many relationship
containing distinct values. A `MutableSet` supports the following types
(and their optional versions):

- Bool
- Data
- Date
- Decimal128
- Double
- Float
- Int
- Int8
- Int16
- Int32
- Int64
- Object
- ObjectId
- String
- UUID

Like Swift's [Set](https://developer.apple.com/documentation/swift/set), `MutableSet` is a
generic type that is parameterized on the type it stores. Unlike
[native Swift collections](https://developer.apple.com/documentation/swift/swift_standard_library/collections),
Realm mutable sets are reference types, as opposed to value
types (structs).

You can only call the `MutableSets` mutation methods during a write
transaction. As a result, `MutableSets` are immutable if you open the
managing realm as a read-only realm.

You can filter and sort a `MutableSet` with the same predicates as Results. Like other
Realm collections, you can register a change listener on a `MutableSet`.

For example, a `Dog` class model might contain a `MutableSet` for
`citiesVisited`:

```swift
class Dog: Object {
    @Persisted var name = ""
    @Persisted var currentCity = ""
    @Persisted var citiesVisited: MutableSet<String>
}
```

> Note:
> When declaring default values for `@Persisted` MutableSet property attributes,
both of these syntax types is valid:
>
> - `@Persisted var value: MutableSet<String>`
> - `@Persisted var value = MutableSet<String>()`
>
> However, the second will result in significantly worse performance. This is
because the MutableSet is created when the parent object is created, rather than
lazily as needed.
>

### Map/Dictionary
> Version added: 10.8.0

The `Map` is an associative array that
contains key-value pairs with unique keys.

Like Swift's [Dictionary](https://developer.apple.com/documentation/swift/dictionary),
`Map` is a generic type that is parameterized on its key and value
types. Unlike [native Swift collections](https://developer.apple.com/documentation/swift/swift_standard_library/collections),
Realm Maps are reference types (classes), as opposed to
value types (structs).

You can declare a Map as a property of an object:

```swift
class Dog: Object {
    @Persisted var name = ""
    @Persisted var currentCity = ""

    // Map of city name -> favorite park in that city
    @Persisted var favoriteParksByCity: Map<String, String>
}
```

Realm disallows the use of `.` or `$` characters in map keys.
You can use percent encoding and decoding to store a map key that contains
one of these disallowed characters.

```
// Percent encode . or $ characters to use them in map keys
let mapKey = "New York.Brooklyn"
let encodedMapKey = "New York%2EBrooklyn"

```

> Note:
> When declaring default values for `@Persisted` Map property attributes, both
of these syntax types is valid:
>
> - `@Persisted var value: Map<String, String>`
> - `@Persisted var value = Map<String, String>()`
>
> However, the second will result in significantly worse performance. This is
because the Map is created when the parent object is created, rather than
lazily as needed.
>

### AnyRealmValue
> Version changed: 10.51.0
> `AnyRealmValue` properties can hold lists or maps of mixed data.
>

> Version added: 10.8.0

`AnyRealmValue` is a Realm property type that can hold different
data types. Supported `AnyRealmValue` data types include:

- Int
- Float
- Double
- Decimal128
- ObjectID
- UUID
- Bool
- Date
- Data
- String
- List
- Map
- Object

`AnyRealmValue` *cannot* hold a `MutableSet` or embedded object.

This mixed data type
is indexable, but you can't use it as a
primary key. Because `null` is a
permitted value, you can't declare an `AnyRealmValue` as optional.

```swift
class Dog: Object {
    @Persisted var name = ""
    @Persisted var currentCity = ""

    @Persisted var companion: AnyRealmValue
}
```

#### Collections as Mixed
In version 10.51.0 and later, a `AnyRealmValue` data type can
contain collections (a list or map, but *not* a set) of `AnyRealmValue`
elements. You can use mixed collections to
model unstructured or variable data. For more information, refer to
Define Unstructured Data.

- You can nest mixed collections up to 100 levels.
- You can query mixed collection properties and
register a listener for changes,
as you would a normal collection.
- You can find and update individual mixed collection elements
- You *cannot* store sets or embedded objects in mixed collections.

To use mixed collections in your app, define the `AnyRealmValue` type
property in your data model.
Then, you can create the list or map collections like any other mixed data value.

### Geospatial Data
> Version added: 10.47.0

Geospatial data, or "geodata", specifies points and geometric objects on
the Earth's surface.

If you want to persist geospatial data, it must conform to the
[GeoJSON spec](https://datatracker.ietf.org/doc/html/rfc7946).

To persist geospatial data with the Swift SDK, create a GeoJSON-compatible
embedded class that you can use in your data model.

Your custom embedded object must contain the two fields required by the
GeoJSON spec:

- A field of type `String` property that maps to a `type` property with
the value of `"Point"`: `@Persisted var type: String = "Point"`
- A field of type `List<Double>` that maps to a `coordinates`
property containing a latitude/longitude pair:
`@Persisted private var coordinates: List<Double>`

```swift
class CustomGeoPoint: EmbeddedObject {
    @Persisted private var type: String = "Point"
    @Persisted private var coordinates: List<Double>

    public var latitude: Double { return coordinates[1] }
    public var longitude: Double { return coordinates[0] }

    convenience init(_ latitude: Double, _ longitude: Double) {
        self.init()
        // Longitude comes first in the coordinates array of a GeoJson document
        coordinates.append(objectsIn: [longitude, latitude])
    }
}

```

## Map Unsupported Types to Supported Types
> Version added: 10.20.0

You can use Type Projection to persist unsupported types as supported types
in Realm. This enables you to work with Swift types that Realm
does not support, but store them as types that Realm does support. You could
store a URL as a `String`, for example, but read it from
Realm and use it in your application as though it were a URL.

### Declare Type Projections
To use type projection with Realm:

1. Use one of Realm's custom type protocols to map an unsupported data type
to a type that Realm supports
2. Use the projected types as @Persisted properties in the Realm object
model

#### Conform to the Type Projection Protocol
You can map an unsupported data type to a type that Realm supports using one of the Realm type projection protocols.

The Swift SDK provides two type projection protocols:

- CustomPersistable
- FailableCustomPersistable

Use `CustomPersistable`
when there is no chance the conversion can fail.

Use `FailableCustomPersistable`
when it is possible for the conversion to fail.

```swift
// Extend a type as a CustomPersistable if if is impossible for
// conversion between the mapped type and the persisted type to fail.
extension CLLocationCoordinate2D: CustomPersistable {
    // Define the storage object that is persisted to the database.
    // The `PersistedType` must be a type that Realm supports.
    // In this example, the PersistedType is an embedded object.
    public typealias PersistedType = Location
    // Construct an instance of the mapped type from the persisted type.
    // When reading from the database, this converts the persisted type to the mapped type.
    public init(persistedValue: PersistedType) {
        self.init(latitude: persistedValue.latitude, longitude: persistedValue.longitude)
    }
    // Construct an instance of the persisted type from the mapped type.
    // When writing to the database, this converts the mapped type to a persistable type.
    public var persistableValue: PersistedType {
        Location(value: [self.latitude, self.longitude])
    }
}

// Extend a type as a FailableCustomPersistable if it is possible for
// conversion between the mapped type and the persisted type to fail.
// This returns nil on read if the underlying column contains nil or
// something that can't be converted to the specified type.
extension URL: FailableCustomPersistable {
    // Define the storage object that is persisted to the database.
    // The `PersistedType` must be a type that Realm supports.
    public typealias PersistedType = String
    // Construct an instance of the mapped type from the persisted type.
    // When reading from the database, this converts the persisted type to the mapped type.
    // This must be a failable initializer when the conversion may fail.
    public init?(persistedValue: String) { self.init(string: persistedValue) }
    // Construct an instance of the persisted type from the mapped type.
    // When writing to the database, this converts the mapped type to a persistable type.
    public var persistableValue: String { self.absoluteString }
}

```

> Seealso:
> These are protocols modeled after Swift's built-in [RawRepresentable](https://developer.apple.com/documentation/swift/rawrepresentable).
>

##### Supported PersistedTypes
The `PersistedType` can use any of the primitive types that the
Swift SDK supports. It can also be
an Embedded Object.

`PersistedType` cannot be an optional or a collection. However you can use the mapped type as an
optional or collection property in your object model.

```swift
extension URL: FailableCustomPersistable {
   // The `PersistedType` cannot be an optional, so this is not a valid
   // conformance to the FailableCustomPersistable protocol.
   public typealias PersistedType = String?
   ...
}

class Club: Object {
   @Persisted var id: ObjectId
   @Persisted var name: String
   // Although the `PersistedType` cannot be optional, you can use the
   // custom-mapped type as an optional in your object model.
   @Persisted var url: URL?
}
```

#### Use Type Projection in the Model
A type that conforms to one of the type projection protocols can be used with
the `@Persisted` property declaration syntax introduced in Swift SDK
version 10.10.0. It does not work with the `@objc dynamic` syntax.

You can use projected types for:

- Top-level types
- Optional versions of the type
- The types for a collection

When using a `FailableCustomPersistable` as a property, define it as an
optional property. When it is optional, the `FailableCustomPersistable`
protocol maps invalid values to `nil`. When it is a required property, it is
force-unwrapped. If you have a value that can't be converted to the projected
type, reading that property throws an unwrapped fail exception.

```swift
class Club: Object {
    @Persisted var id: ObjectId
    @Persisted var name: String
    // Since we declared the URL as a FailableCustomPersistable,
    // it must be optional.
    @Persisted var url: URL?
    // Here, the `location` property maps to an embedded object.
    // We can declare the property as required.
    // If the underlying field contains nil, this becomes
    // a default-constructed instance of CLLocationCoordinate
    // with field values of `0`.
    @Persisted var location: CLLocationCoordinate2D
}

public class Location: EmbeddedObject {
    @Persisted var latitude: Double
    @Persisted var longitude: Double
}

```

When your model contains projected types, you can create the object with values using the persisted type, or
by assigning to the field properties of an initialized object using the
projected types.

```swift
// Initialize objects and assign values
let club = Club(value: ["name": "American Kennel Club", "url": "https://akc.org"])
let club2 = Club()
club2.name = "Continental Kennel Club"
// When assigning the value to a type-projected property, type safety
// checks for the mapped type - not the persisted type.
club2.url = URL(string: "https://ckcusa.com/")!
club2.location = CLLocationCoordinate2D(latitude: 40.7509, longitude: 73.9777)

```

##### Type Projection in the Schema
When you declare your type as conforming to a type projection protocol, you
specify the type that should be persisted in realm. For example, if
you map a custom type `URL` to a persisted type of `String`, a `URL`
property appears as a `String` in the schema, and dynamic access to the
property acts on strings.

The schema does not directly represent mapped types. Changing a property
from its persisted type to its mapped type, or vice versa, does not require
a migration.
