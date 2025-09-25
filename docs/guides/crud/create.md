# CRUD - Create - Swift SDK
## Create a New Object
### About The Examples On This Page
The examples on this page use the following models:

#### Objective-C

```objectivec
// DogToy.h
@interface DogToy : RLMObject
@property NSString *name;
@end

// Dog.h
@interface Dog : RLMObject
@property NSString *name;
@property int age;
@property NSString *color;

// To-one relationship
@property DogToy *favoriteToy;

@end

// Enable Dog for use in RLMArray
RLM_COLLECTION_TYPE(Dog)

// Person.h
// A person has a primary key ID, a collection of dogs, and can be a member of multiple clubs.
@interface Person : RLMObject
@property int _id;
@property NSString *name;

// To-many relationship - a person can have many dogs
@property RLMArray<Dog *><Dog> *dogs;

// Inverse relationship - a person can be a member of many clubs
@property (readonly) RLMLinkingObjects *clubs;
@end

RLM_COLLECTION_TYPE(Person)

// DogClub.h
@interface DogClub : RLMObject
@property NSString *name;
@property RLMArray<Person *><Person> *members;
@end

// Dog.m
@implementation Dog
@end

// DogToy.m
@implementation DogToy
@end

// Person.m
@implementation Person
// Define the primary key for the class
+ (NSString *)primaryKey {
    return @"_id";
}

// Define the inverse relationship to dog clubs
+ (NSDictionary *)linkingObjectsProperties {
    return @{
        @"clubs": [RLMPropertyDescriptor descriptorWithClass:DogClub.class propertyName:@"members"],
    };
}
@end

// DogClub.m
@implementation DogClub
@end

```

#### Swift

```swift
class DogToy: Object {
    @Persisted var name = ""
}

class Dog: Object {
    @Persisted var name = ""
    @Persisted var age = 0
    @Persisted var color = ""
    @Persisted var currentCity = ""
    @Persisted var citiesVisited: MutableSet<String>
    @Persisted var companion: AnyRealmValue

    // To-one relationship
    @Persisted var favoriteToy: DogToy?

    // Map of city name -> favorite park in that city
    @Persisted var favoriteParksByCity: Map<String, String>
}

class Person: Object {
    @Persisted(primaryKey: true) var id = 0
    @Persisted var name = ""

    // To-many relationship - a person can have many dogs
    @Persisted var dogs: List<Dog>

    // Embed a single object.
    // Embedded object properties must be marked optional.
    @Persisted var address: Address?

    convenience init(name: String, address: Address) {
        self.init()
        self.name = name
        self.address = address
    }
}

class Address: EmbeddedObject {
    @Persisted var street: String?
    @Persisted var city: String?
    @Persisted var country: String?
    @Persisted var postalCode: String?
}

```

### Create an Object
#### Objective-C

To add an object to a realm, instantiate it as you would any other
object and then pass it to `-[RLMRealm addObject:]` inside
of a write transaction.

```objectivec
// Get the default realm.
// You only need to do this once per thread.
RLMRealm *realm = [RLMRealm defaultRealm];

// Instantiate the class.
Dog *dog = [[Dog alloc] init];
dog.name = @"Max";
dog.age = 5;

// Open a thread-safe transaction.
[realm transactionWithBlock:^() {
    // Add the instance to the realm.
    [realm addObject:dog];
}];

```

#### Swift

To add an object to a realm, instantiate it as you would any other
object and then pass it to `Realm.add(_:update:)`
inside of a write transaction.

```swift
// Instantiate the class and set its values.
let dog = Dog()
dog.name = "Rex"
dog.age = 10

// Get the default realm. You only need to do this once per thread.
let realm = try! Realm()
// Open a thread-safe transaction.
try! realm.write {
    // Add the instance to the realm.
    realm.add(dog)
}

```

### Initialize Objects with a Value
You can initialize an object by passing an initializer value to
`Object.init(value:)`.
The initializer value can be a [key-value coding](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/KeyValueCoding/)
compliant object, a dictionary, or an array containing one element for
each managed property.

> Note:
> When using an array as an initializer value, you must include all
properties in the same order as they are defined in the model.
>

#### Objective-C

```objectivec
// (1) Create a Dog object from a dictionary
Dog *myDog = [[Dog alloc] initWithValue:@{@"name" : @"Pluto", @"age" : @3}];

// (2) Create a Dog object from an array
Dog *myOtherDog = [[Dog alloc] initWithValue:@[@"Pluto", @3]];

RLMRealm *realm = [RLMRealm defaultRealm];

// Add to the realm with transaction
[realm transactionWithBlock:^() {
    [realm addObject:myDog];
    [realm addObject:myOtherDog];
}];

```

#### Swift

```swift
// (1) Create a Dog object from a dictionary
let myDog = Dog(value: ["name": "Pluto", "age": 3])

// (2) Create a Dog object from an array
let myOtherDog = Dog(value: ["Fido", 5])

let realm = try! Realm()
// Add to the realm inside a transaction
try! realm.write {
    realm.add([myDog, myOtherDog])
}

```

You can even initialize related or
embedded objects by nesting initializer
values:

#### Objective-C

```objectivec
// Instead of using pre-existing dogs...
Person *aPerson = [[Person alloc]
    initWithValue:@[@123, @"Jane", @[aDog, anotherDog]]];

// ...we can create them inline
Person *anotherPerson = [[Person alloc]
    initWithValue:@[@123, @"Jane", @[@[@"Buster", @5], @[@"Buddy", @6]]]];

```

#### Swift

```swift
// Instead of using pre-existing dogs...
let aPerson = Person(value: [123, "Jane", [aDog, anotherDog]])

// ...we can create them inline
let anotherPerson = Person(value: [123, "Jane", [["Buster", 5], ["Buddy", 6]]])

```

#### Some Property Types are Only Mutable in a Write Transaction
Some property types are only mutable in a write transaction. For example,
you can instantiate an object with a MutableSet
property, but you can only set that property's value in a write transaction.
You cannot initialize the object with a value for that property unless
you do so inside a write transaction.

### Create an Object with JSON
Realm does not directly support JSON, but you can use
[JSONSerialization.jsonObject(with:options:)](https://developer.apple.com/documentation/foundation/jsonserialization/1415493-jsonobject) to
convert JSON into a value that you can pass to
`Realm.create(_:value:update:)`.

#### Objective-C

```objectivec
// Specify a dog toy in JSON
NSData *data = [@"{\"name\": \"Tennis ball\"}" dataUsingEncoding: NSUTF8StringEncoding];
RLMRealm *realm = [RLMRealm defaultRealm];

// Insert from NSData containing JSON
[realm transactionWithBlock:^{
    id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
    [DogToy createInRealm:realm withValue:json];
}];

```

#### Swift

```swift
// Specify a dog toy in JSON
let data = "{\"name\": \"Tennis ball\"}".data(using: .utf8)!
let realm = try! Realm()
// Insert from data containing JSON
try! realm.write {
    let json = try! JSONSerialization.jsonObject(with: data, options: [])
    realm.create(DogToy.self, value: json)
}

```

Nested objects or arrays in the JSON map to to-one or to-many relationships.

The JSON property names and types must match the destination
object schema exactly. For example:

- `float` properties must be initialized with float-backed `NSNumbers`.
- `Date` and `Data` properties cannot be inferred from strings. Convert them to the appropriate type before passing to `Realm.create(_:value:update:)`.
- Required properties cannot be `null` or missing in the JSON.

Realm ignores any properties in the JSON not defined in the
object schema.

> Tip:
> If your JSON schema doesn't exactly align with your Realm objects,
consider using a third-party framework to transform your JSON. There
are many model mapping frameworks that work with Realm.
See a [partial list in the realm-swift repository](https://github.com/realm/realm-swift/issues/694#issuecomment-144785299).
>

### Create an Embedded Object
To create an embedded object, assign an instance of the embedded object
to a parent object's property:

#### Objective-C

```objectivec
RLMRealm *realm = [RLMRealm defaultRealm];
[realm transactionWithBlock:^{
    Address *address = [[Address alloc] init];
    address.street = @"123 Fake St.";
    address.city = @"Springfield";
    address.country = @"USA";
    address.postalCode = @"90710";

    Contact *contact = [Contact contactWithName:@"Nick Riviera"];

    // Assign the embedded object property
    contact.address = address;

    [realm addObject:contact];

    NSLog(@"Added contact: %@", contact);
}];

```

#### Swift

```swift
// Open the default realm
let realm = try! Realm()

try! realm.write {
    let address = Address()
    address.street = "123 Fake St"
    address.city = "Springfield"
    address.country = "USA"
    address.postalCode = "90710"
    let contact = Person(name: "Nick Riviera", address: address)
    realm.add(contact)
}

```

### Create an Object with a Map Property
When you create an object that has a `map property`, you can set the values for keys in a few ways:

- Set keys and values on the object and then add the object to the realm
- Set the object's keys and values directly inside a write transaction
- Use key-value coding to set or update keys and values inside a write transaction

```swift
let realm = try! Realm()
// Record a dog's name and current city
let dog = Dog()
dog.name = "Wolfie"
dog.currentCity = "New York"
// Set map values
dog.favoriteParksByCity["New York"] = "Domino Park"
// Store the data in a realm
try! realm.write {
    realm.add(dog)
    // You can also set map values inside a write transaction
    dog.favoriteParksByCity["Chicago"] = "Wrigley Field"
    dog.favoriteParksByCity.setValue("Bush Park", forKey: "Ottawa")
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

### Create an Object with a MutableSet Property
You can create objects that contain `MutableSet` properties as you would any Realm object, but you
can only mutate a MutableSet within a write transaction. This means you can
only set the value(s) of a mutable set property within a write transaction.

```swift
let realm = try! Realm()

// Record a dog's name and current city
let dog = Dog()
dog.name = "Maui"
dog.currentCity = "New York"

// Store the data in a realm. Add the dog's current city
// to the citiesVisited MutableSet
try! realm.write {
    realm.add(dog)
    // You can only mutate the MutableSet in a write transaction.
    // This means you can't set values at initialization, but must do it during a write.
    dog.citiesVisited.insert(dog.currentCity)
}

// You can also add multiple items to the set.
try! realm.write {
    dog.citiesVisited.insert(objectsIn: ["Boston", "Chicago"])
}

print("\(dog.name) has visited: \(dog.citiesVisited)")

```

### Create an Object with an AnyRealmValue Property
When you create an object with an AnyRealmValue property, you must specify the type of the value you store in
the property. The Realm Swift SDK provides an `AnyRealmValue enum` that iterates through all of the types the
AnyRealmValue can store.

Later, when you read an AnyRealmValue,
you must check the type before you do anything with the value.

```swift
// Create a Dog object and then set its properties
let myDog = Dog()
myDog.name = "Rex"
// This dog has no companion.
// You can set the field's type to "none", which represents `nil`
myDog.companion = .none

// Create another Dog whose companion is a cat.
// We don't have a Cat object, so we'll use a string to describe the companion.
let theirDog = Dog()
theirDog.name = "Wolfie"
theirDog.companion = .string("Fluffy the Cat")

// Another dog might have a dog as a companion.
// We do have an object that can represent that, so we can specify the
// type is a Dog object, and even set the object's value.
let anotherDog = Dog()
anotherDog.name = "Fido"
// Note: this sets Spot as a companion of Fido, but does not set
// Fido as a companion of Spot. Spot has no companion in this instance.
anotherDog.companion = .object(Dog(value: ["name": "Spot"]))

// Add the dogs to the realm
let realm = try! Realm()
try! realm.write {
    realm.add([myDog, theirDog, anotherDog])
}
// After adding these dogs to the realm, we now have 4 dog objects.
let dogs = realm.objects(Dog.self)
XCTAssertEqual(dogs.count, 4)

```

## Create an Object Asynchronously
You can use Swift concurrency features to write asynchronously to an
actor-isolated realm.

This function from the example `RealmActor` defined on the
Use Realm with Actors page shows how you might
write to an actor-isolated realm:

```swift
func createTodo(name: String, owner: String, status: String) async throws {
    try await realm.asyncWrite {
        realm.create(Todo.self, value: [
            "_id": ObjectId.generate(),
            "name": name,
            "owner": owner,
            "status": status
        ])
    }
}

```

And you might perform this write using Swift's async syntax:

```swift
func createObject() async throws {
    // Because this function is not isolated to this actor,
    // you must await operations completed on the actor
    try await actor.createTodo(name: "Take the ring to Mount Doom", owner: "Frodo", status: "In Progress")
    let taskCount = await actor.count
    print("The actor currently has \(taskCount) tasks")
}

let actor = try await RealmActor()

try await createObject()

```

This operation does not block or perform I/O on the calling thread. For
more information about writing to realm using Swift concurrency features,
refer to Use Realm with Actors - Swift SDK.

## Copy an Object to Another Realm
#### Objective-C

To copy an object from one realm to another, pass the original
object to `+[RLMObject createInRealm:withValue:]`:

```objectivec
RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
configuration.inMemoryIdentifier = @"first realm";
RLMRealm *realm = [RLMRealm realmWithConfiguration:configuration error:nil];

[realm transactionWithBlock:^{
    Dog *dog = [[Dog alloc] init];
    dog.name = @"Wolfie";
    dog.age = 1;
    [realm addObject:dog];
}];

// Later, fetch the instance we want to copy
Dog *wolfie = [[Dog objectsInRealm:realm where:@"name == 'Wolfie'"] firstObject];

// Open the other realm
RLMRealmConfiguration *otherConfiguration = [RLMRealmConfiguration defaultConfiguration];
otherConfiguration.inMemoryIdentifier = @"second realm";
RLMRealm *otherRealm = [RLMRealm realmWithConfiguration:otherConfiguration error:nil];
[otherRealm transactionWithBlock:^{
    // Copy to the other realm
    Dog *wolfieCopy = [[wolfie class] createInRealm:otherRealm withValue:wolfie];
    wolfieCopy.age = 2;

    // Verify that the copy is separate from the original
    XCTAssertNotEqual(wolfie.age, wolfieCopy.age);
}];

```

#### Swift

To copy an object from one realm to another, pass the original
object to `Realm.create(_:value:update:):`:

```swift
let realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "first realm"))

try! realm.write {
    let dog = Dog()
    dog.name = "Wolfie"
    dog.age = 1
    realm.add(dog)
}

// Later, fetch the instance we want to copy
let wolfie = realm.objects(Dog.self).first(where: { $0.name == "Wolfie" })!

// Open the other realm
let otherRealm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "second realm"))
try! otherRealm.write {
    // Copy to the other realm
    let wolfieCopy = otherRealm.create(type(of: wolfie), value: wolfie)
    wolfieCopy.age = 2

    // Verify that the copy is separate from the original
    XCTAssertNotEqual(wolfie.age, wolfieCopy.age)
}

```

> Important:
> The `create` methods do not support handling cyclical object
graphs. Do not pass in an object containing relationships involving
objects that refer back to their parents, either directly or
indirectly.
>
