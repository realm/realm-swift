# CRUD - Delete - Swift SDK
## Delete Realm Objects
Deleting Realm Objects must occur within write transactions. For
more information about write transactions, see: Transactions.

If you want to delete the Realm file itself, see: Delete a Realm.

> Important:
> You cannot access or modify an object after you have deleted it from
a realm. If you try to use a deleted object, Realm throws an
error.
>

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

```

### Delete an Object
#### Objective-C

To delete an object from a realm, pass the object to
`-[RLMRealm deleteObject:]`
inside of a write transaction.

```objectivec
[realm transactionWithBlock:^() {
    // Delete the instance from the realm.
    [realm deleteObject:dog];
}];

```

#### Swift

To delete an object from a realm, pass the object to
`Realm.delete(_:)`
inside of a write transaction.

```swift
// Previously, we've added a dog object to the realm.
let dog = Dog(value: ["name": "Max", "age": 5])

let realm = try! Realm()
try! realm.write {
    realm.add(dog)
}

// Delete the instance from the realm.
try! realm.write {
    realm.delete(dog)
}

```

### Delete Multiple Objects
#### Swift

> Version added: 10.19.0

To delete a collection of objects from a realm, pass the
collection to `Realm.delete(_:)`
inside of a write transaction.

```swift
let realm = try! Realm()
try! realm.write {
    // Find dogs younger than 2 years old.
    let puppies = realm.objects(Dog.self).where {
        $0.age < 2
    }

    // Delete the objects in the collection from the realm.
    realm.delete(puppies)
}

```

#### Swift Nspredicate

To delete a collection of objects from a realm, pass the
collection to `Realm.delete(_:)`
inside of a write transaction.

```swift
let realm = try! Realm()
try! realm.write {
    // Find dogs younger than 2 years old.
    let puppies = realm.objects(Dog.self).filter("age < 2")

    // Delete the objects in the collection from the realm.
    realm.delete(puppies)
}

```

#### Objective-C

To delete a collection of objects from a realm, pass the
collection to `-[Realm deleteObjects:]`
inside of a write transaction.

```objectivec
RLMRealm *realm = [RLMRealm defaultRealm];

[realm transactionWithBlock:^() {
    // Find dogs younger than 2 years old.
    RLMResults<Dog *> *puppies = [Dog objectsInRealm:realm where:@"age < 2"];

    // Delete all objects in the collection from the realm.
    [realm deleteObjects:puppies];
}];

```

### Delete an Object and Its Related Objects
Sometimes, you want to delete related objects when you delete the parent
object. We call this a **chaining delete**. Realm does not delete
the related objects for you. If you do not delete the objects yourself,
they remain orphaned in your realm. Whether or not this is a problem
depends on your application's needs.

The best way to delete dependent objects is to iterate through
the dependencies and delete them before deleting the parent object.

#### Objective-C

```objectivec
[realm transactionWithBlock:^() {
    // Delete Ali's dogs.
    [realm deleteObjects:[ali dogs]];
    // Delete Ali.
    [realm deleteObject:ali];
}];

```

#### Swift

```swift
let person = realm.object(ofType: Person.self, forPrimaryKey: 1)!
try! realm.write {
    // Delete the related collection
    realm.delete(person.dogs)
    realm.delete(person)
}

```

### Delete All Objects of a Specific Type
#### Objective-C

To delete all objects of a given object type from a realm, pass
the result of [+[YourRealmObjectClass
allObjectsInRealm:]]
to `-[Realm deleteObjects:]`
inside of a write transaction. Replace `YourRealmObjectClass`
with your Realm object class name.

```objectivec
RLMRealm *realm = [RLMRealm defaultRealm];

[realm transactionWithBlock:^() {
    // Delete all instances of Dog from the realm.
    RLMResults<Dog *> *allDogs = [Dog allObjectsInRealm:realm];
    [realm deleteObjects:allDogs];
}];

```

#### Swift

To delete all objects of a given object type from a realm, pass
the result of `Realm.objects(_)`
for the type you wish to delete to `Realm.delete(_:)`
inside of a write transaction.

```swift
let realm = try! Realm()

try! realm.write {
    // Delete all instances of Dog from the realm.
    let allDogs = realm.objects(Dog.self)
    realm.delete(allDogs)
}

```

### Delete All Objects in a Realm
#### Objective-C

To delete all objects from the realm, call [-[RLMRealm
deleteAllObjects]]
inside of a write transaction. This clears the realm of all object
instances but does not affect the realm's schema.

```objectivec
RLMRealm *realm = [RLMRealm defaultRealm];

[realm transactionWithBlock:^() {
    // Delete all objects from the realm.
    [realm deleteAllObjects];
}];

```

#### Swift

To delete all objects from the realm, call
`Realm.deleteAll()` inside of a
write transaction. This clears the realm of all object instances
but does not affect the realm's schema.

```swift
let realm = try! Realm()

try! realm.write {
    // Delete all objects from the realm.
    realm.deleteAll()
}

```

### Delete Map Keys/Values
You can delete `map` entries in a few ways:

- Use `removeObject(for:)` to remove the key and the value
- If the dictionary's value is optional, you can set the value of the key to
`nil` to keep the key.

```swift
let realm = try! Realm()

// Find the dog we want to update
let wolfie = realm.objects(Dog.self).where {
    $0.name == "Wolfie"
}.first!

// Delete an entry
try! realm.write {
    // Use removeObject(for:)
    wolfie.favoriteParksByCity.removeObject(for: "New York")
    // Or assign `nil` to delete non-optional values.
    // If the value type were optional (e.g. Map<String, String?>)
    // this would assign `nil` to that entry rather than deleting it.
    wolfie.favoriteParksByCity["New York"] = nil
}
XCTAssertNil(wolfie.favoriteParksByCity["New York"])

```

### Delete MutableSet Elements
You can delete specific elements from a `MutableSet`, or clear all of the elements from the set.
If you are working with multiple sets, you can also remove elements in one
set from the other set; see: Update a MutableSet Property.

```swift
let realm = try! Realm()

// Record a dog's name and list of cities he has visited.
let dog = Dog()
dog.name = "Maui"
let dogCitiesVisited = ["New York", "Boston", "Toronto"]
try! realm.write {
    realm.add(dog)
    dog.citiesVisited.insert(objectsIn: dogCitiesVisited)
}
XCTAssertEqual(dog.citiesVisited.count, 3)

// Later... we decide the dog didn't really visit Toronto
// since the plane just stopped there for a layover.
// Remove the element from the set.
try! realm.write {
    dog.citiesVisited.remove("Toronto")
}
XCTAssertEqual(dog.citiesVisited.count, 2)

// Or, in the case where the person entered the data for
// the wrong dog, remove all elements from the set.
try! realm.write {
    dog.citiesVisited.removeAll()
}
XCTAssertEqual(dog.citiesVisited.count, 0)

```

### Delete the Value of an AnyRealmValue
To delete the value of an AnyRealmValue, set it to `.none`.

```swift
let realm = try! Realm()

// Wolfie's companion is "Fluffy the Cat", represented by a string.
// Fluffy has gone to visit friends for the summer, so Wolfie has no companion.
let wolfie = realm.objects(Dog.self).where {
    $0.name == "Wolfie"
}.first!

try! realm.write {
    // You cannot set an AnyRealmValue to nil; you must set it to `.none`, instead.
    wolfie.companion = .none
}

```

## Delete an Object Asynchronously
You can use Swift concurrency features to asynchronously delete objects
using an actor-isolated realm.

This function from the example `RealmActor` defined on the
Use Realm with Actors page shows how you might
delete an object in an actor-isolated realm:

```swift
func deleteTodo(id: ObjectId) async throws {
    try await realm.asyncWrite {
        let todoToDelete = realm.object(ofType: Todo.self, forPrimaryKey: id)
        realm.delete(todoToDelete!)
    }
}

```

And you might perform this deletion using Swift's async syntax:

```swift
let actor = try await RealmActor()
let todoId = await actor.getObjectId(forTodoNamed: "Keep Mr. Frodo safe from that Gollum")

try await actor.deleteTodo(id: todoId)
let updatedTodoCount = await actor.count
if updatedTodoCount == todoCount - 1 {
    print("Successfully deleted the todo")
}

```

This operation does not block or perform I/O on the calling thread. For
more information about writing to realm using Swift concurrency features,
refer to Use Realm with Actors.
