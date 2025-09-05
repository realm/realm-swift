# CRUD - Update - Swift SDK
## Update Realm Objects
Updates to Realm Objects must occur within write transactions. For
more information about write transactions, see: Transactions.

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
class Dog: Object {
    @Persisted var name = ""
    @Persisted var age = 0
    @Persisted var color = ""
    @Persisted var currentCity = ""
    @Persisted var citiesVisited: MutableSet<String>
    @Persisted var companion: AnyRealmValue

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
}

class Address: EmbeddedObject {
    @Persisted var street: String?
    @Persisted var city: String?
    @Persisted var country: String?
    @Persisted var postalCode: String?
}

```

### Update an Object
You can modify properties of a Realm object inside of a write
transaction in the same way that you would update any other Swift or
Objective-C object.

#### Objective-C

```objectivec
RLMRealm *realm = [RLMRealm defaultRealm];
// Open a thread-safe transaction.
[realm transactionWithBlock:^{
    // Get a dog to update.
    Dog *dog = [[Dog allObjectsInRealm: realm] firstObject];

    // Update some properties on the instance.
    // These changes are saved to the realm.
    dog.name = @"Wolfie";
    dog.age += 1;
}];

```

#### Swift

```swift
let realm = try! Realm()

// Get a dog to update
let dog = realm.objects(Dog.self).first!

// Open a thread-safe transaction
try! realm.write {
    // Update some properties on the instance.
    // These changes are saved to the realm
    dog.name = "Wolfie"
    dog.age += 1
}

```

> Tip:
> To update a property of an embedded object or a related object, modify the property with
dot-notation or bracket-notation as if it were in a regular, nested
object.
>

### Update Properties with Key-value Coding
`Object`, `Result`, and `List` all conform to
[key-value coding](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/KeyValueCoding/).
This can be useful when you need to determine which property to update
at runtime.

Applying KVC to a collection is a great way to update objects in bulk.
Avoid the overhead of iterating over a collection while creating
accessors for every item.

```swift
let realm = try! Realm()

let allDogs = realm.objects(Dog.self)

try! realm.write {
    allDogs.first?.setValue("Sparky", forKey: "name")
    // Move the dogs to Toronto for vacation
    allDogs.setValue("Toronto", forKey: "currentCity")
}

```

You can also add values for embedded objects or relationships this
way. In this example, we add a collection to an object's list property:

#### Objective-C

```objectivec
RLMRealm *realm = [RLMRealm defaultRealm];

[realm transactionWithBlock:^() {
    // Create a person to take care of some dogs.
    Person *ali = [[Person alloc] initWithValue:@{@"_id": @1, @"name": @"Ali"}];
    [realm addObject:ali];

    // Find dogs younger than 2.
    RLMResults<Dog *> *puppies = [Dog objectsInRealm:realm where:@"age < 2"];

    // Batch update: give all puppies to Ali.
    [ali setValue:puppies forKey:@"dogs"];
}];

```

#### Swift

```swift
let realm = try! Realm()
try! realm.write {
    // Create a person to take care of some dogs.
    let person = Person(value: ["id": 1, "name": "Ali"])
    realm.add(person)

    let dog = Dog(value: ["name": "Rex", "age": 1])
    realm.add(dog)

    // Find dogs younger than 2.
    let puppies = realm.objects(Dog.self).filter("age < 2")

    // Give all puppies to Ali.
    person.setValue(puppies, forKey: "dogs")

}

```

### Upsert an Object
An **upsert** either inserts or updates an object depending on whether
the object already exists. Upserts require the data model to have a
primary key.

#### Objective-C

To upsert an object, call `-[RLMRealm addOrUpdateObject:]`.

```objectivec
RLMRealm *realm = [RLMRealm defaultRealm];
[realm transactionWithBlock:^{
    Person *jones = [[Person alloc] initWithValue:@{@"_id": @1234, @"name": @"Jones"}];
    // Add a new person to the realm. Since nobody with ID 1234
    // has been added yet, this adds the instance to the realm.
    [realm addOrUpdateObject:jones];
    
    Person *bowie = [[Person alloc] initWithValue:@{@"_id": @1234, @"name": @"Bowie"}];
    // Judging by the ID, it's the same person, just with a different name.
    // This overwrites the original entry (i.e. Jones -> Bowie).
    [realm addOrUpdateObject:bowie];
}];

```

#### Swift

To upsert an object, call `Realm.add(_:update:)`
with the second parameter, update policy, set to `.modified`.

```swift
let realm = try! Realm()
try! realm.write {
    let person1 = Person(value: ["id": 1234, "name": "Jones"])
    // Add a new person to the realm. Since nobody with ID 1234
    // has been added yet, this adds the instance to the realm.
    realm.add(person1, update: .modified)

    let person2 = Person(value: ["id": 1234, "name": "Bowie"])
    // Judging by the ID, it's the same person, just with a
    // different name. When `update` is:
    // - .modified: update the fields that have changed.
    // - .all: replace all of the fields regardless of
    //   whether they've changed.
    // - .error: throw an exception if a key with the same
    //   primary key already exists.
    realm.add(person2, update: .modified)
}

```

You can also partially update an object by passing the primary key and a
subset of the values to update:

#### Objective-C

```objectivec
RLMRealm *realm = [RLMRealm defaultRealm];
[realm transactionWithBlock:^{
    // Only update the provided values.
    // Note that the "name" property will remain the same
    // for the person with primary key "_id" 123.
    [Person createOrUpdateModifiedInRealm:realm
        withValue:@{@"_id": @123, @"dogs": @[@[@"Buster", @5]]}];
}];

```

#### Swift

```swift
let realm = try! Realm()
try! realm.write {
    // Use .modified to only update the provided values.
    // Note that the "name" property will remain the same
    // for the person with primary key "id" 123.
    realm.create(Person.self,
                 value: ["id": 123, "dogs": [["Buster", 5]]],
                 update: .modified)
}

```

### Update a Map/Dictionary
You can update a realm `map` as you would a
standard [Dictionary](https://developer.apple.com/documentation/swift/dictionary):

```swift
let realm = try! Realm()

// Find the dog we want to update
let wolfie = realm.objects(Dog.self).where {
    $0.name == "Wolfie"
}.first!

print("Wolfie's favorite park in New York is: \(wolfie.favoriteParksByCity["New York"])")
XCTAssertTrue(wolfie.favoriteParksByCity["New York"] == "Domino Park")

// Update values for keys, or add values if the keys do not currently exist
try! realm.write {
    wolfie.favoriteParksByCity["New York"] = "Washington Square Park"
    wolfie.favoriteParksByCity.updateValue("A Street Park", forKey: "Boston")
    wolfie.favoriteParksByCity.setValue("Little Long Pond", forKey: "Seal Harbor")
}

XCTAssertTrue(wolfie.favoriteParksByCity["New York"] == "Washington Square Park")

```

### Update a MutableSet Property
You can `insert` elements into a `MutableSet` during write transactions to add them to the
property. If you are working with multiple sets, you can also insert or
remove set elements contained in one set from the other set. Alternately,
you can mutate a set to contain only the common elements from both.

```swift
let realm = try! Realm()

// Record a dog's name, current city, and store it to the cities visited.
let dog = Dog()
dog.name = "Maui"
dog.currentCity = "New York"
try! realm.write {
    realm.add(dog)
    dog.citiesVisited.insert(dog.currentCity)
}

// Update the dog's current city, and add it to the set of cities visited.
try! realm.write {
    dog.currentCity = "Toronto"
    dog.citiesVisited.insert(dog.currentCity)
}
XCTAssertEqual(dog.citiesVisited.count, 2)

// If you're operating with two sets, you can insert the elements from one set into another set.
// The dog2 set contains one element that isn't present in the dog set.
try! realm.write {
    dog.citiesVisited.formUnion(dog2.citiesVisited)
}
XCTAssertEqual(dog.citiesVisited.count, 3)

// Or you can remove elements that are present in the second set. This removes the one element
// that we added above from the dog2 set.
try! realm.write {
    dog.citiesVisited.subtract(dog2.citiesVisited)
}
XCTAssertEqual(dog.citiesVisited.count, 2)

// If the sets contain common elements, you can mutate the set to only contain those common elements.
// In this case, the two sets contain no common elements, so this set should now contain 0 items.
try! realm.write {
    dog.citiesVisited.formIntersection(dog2.citiesVisited)
}
XCTAssertEqual(dog.citiesVisited.count, 0)

```

### Update an AnyRealmValue Property
You can update an AnyRealmValue property through assignment, but you must
specify the type of the value when you assign it. The Realm Swift SDK
provides an `AnyRealmValue enum` that
iterates through all of the types the AnyRealmValue can store.

```swift
let realm = try! Realm()

// Get a dog to update
let rex = realm.objects(Dog.self).where {
    $0.name == "Rex"
}.first!

try! realm.write {
    // As with creating an object with an AnyRealmValue, you must specify the
    // type of the value when you update the property.
    rex.companion = .object(Dog(value: ["name": "Regina"]))
}

```

### Update an Embedded Object Property
To update a property in an embedded object, modify the property in a
write transaction. If the embedded object is null, updating an embedded
object property has no effect.

#### Objective-C

```objectivec
RLMRealm *realm = [RLMRealm defaultRealm];
[realm transactionWithBlock: ^{
    Contact *contact = [Contact objectInRealm:realm
                                forPrimaryKey:[[RLMObjectId alloc] initWithString:@"5f481c21f634a1f4eeaa7268" error:nil]];
    contact.address.street = @"Hollywood Upstairs Medical College";
    contact.address.city = @"Los Angeles";
    contact.address.postalCode = @"90210";
    NSLog(@"Updated contact: %@", contact);
}];

```

#### Swift

```swift
// Open the default realm
let realm = try! Realm()

let idOfPersonToUpdate = 123

// Find the person to update by ID
guard let person = realm.object(ofType: Person.self, forPrimaryKey: idOfPersonToUpdate) else {
    print("Person \(idOfPersonToUpdate) not found")
    return
}

try! realm.write {
    // Update the embedded object directly through the person
    // If the embedded object is null, updating these properties has no effect
    person.address?.street = "789 Any Street"
    person.address?.city = "Anytown"
    person.address?.postalCode = "12345"
    print("Updated person: \(person)")
}

```

### Overwrite an Embedded Object
To overwrite an embedded object, reassign the embedded object property
of a party to a new instance in a write transaction.

#### Objective-C

```objectivec
RLMRealm *realm = [RLMRealm defaultRealm];
[realm transactionWithBlock: ^{
    Contact *contact = [Contact objectInRealm:realm
                                forPrimaryKey:[[RLMObjectId alloc] initWithString:@"5f481c21f634a1f4eeaa7268" error:nil]];
    Address *newAddress = [[Address alloc] init];
    newAddress.street = @"Hollywood Upstairs Medical College";
    newAddress.city = @"Los Angeles";
    newAddress.country = @"USA";
    newAddress.postalCode = @"90210";
    contact.address = newAddress;
    NSLog(@"Updated contact: %@", contact);
}];

```

#### Swift

```swift
// Open the default realm
let realm = try! Realm()

let idOfPersonToUpdate = 123

// Find the person to update by ID
guard let person = realm.object(ofType: Person.self, forPrimaryKey: idOfPersonToUpdate) else {
    print("Person \(idOfPersonToUpdate) not found")
    return
}

try! realm.write {
    let newAddress = Address()
    newAddress.street = "789 Any Street"
    newAddress.city = "Anytown"
    newAddress.country = "USA"
    newAddress.postalCode = "12345"

    // Overwrite the embedded object
    person.address = newAddress
    print("Updated person: \(person)")
}

```

## Update an Object Asynchronously
You can use Swift concurrency features to asynchronously update objects
using an actor-isolated realm.

This function from the example `RealmActor` defined on the
Use Realm with Actors page shows how you might
update an object in an actor-isolated realm:

```swift
func updateTodo(_id: ObjectId, name: String, owner: String, status: String) async throws {
    try await realm.asyncWrite {
        realm.create(Todo.self, value: [
            "_id": _id,
            "name": name,
            "owner": owner,
            "status": status
        ], update: .modified)
    }
}

```

And you might perform this update using Swift's async syntax:

```swift
let actor = try await RealmActor()

// Read objects in functions isolated to the actor and pass primitive values to the caller
func getObjectId(in actor: isolated RealmActor, forTodoNamed name: String) async -> ObjectId {
    let todo = actor.realm.objects(Todo.self).where {
        $0.name == name
    }.first!
    return todo._id
}
let objectId = await getObjectId(in: actor, forTodoNamed: "Keep it safe")

try await actor.updateTodo(_id: objectId, name: "Keep it safe", owner: "Frodo", status: "Completed")

```

This operation does not block or perform I/O on the calling thread. For
more information about writing to realm using Swift concurrency features,
refer to Use Realm with Actors - Swift SDK.

## Update Properties through Class Projections
### Change Class Projection Properties
You can make changes to a class projection's properties in a write transaction.

```swift
// Retrieve all class projections of the given type `PersonProjection`
// and filter for the first class projection where the `firstName` property
// value is "Jason"
let person = realm.objects(PersonProjection.self).first(where: { $0.firstName == "Jason" })!
// Update class projection property in a write transaction
try! realm.write {
    person.firstName = "David"
}

```
