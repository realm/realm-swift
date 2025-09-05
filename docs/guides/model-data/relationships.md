# Model Relationships - Swift SDK
## Declare Relationship Properties

### Define a To-One Relationship Property
A **to-one** relationship maps one property to a single instance of
another object type. For example, you can model a person having at most
one companion dog as a to-one relationship.

Setting a relationship field to null removes the connection between objects.
Realm does not delete the referenced object, though, unless it is
an embedded object.

> Important:
> When you declare a to-one relationship in your object model, it must
be an optional property. If you try to make a to-one relationship
required, Realm throws an exception at runtime.
>

#### Objective-C

```objectivec
// Dog.h
@interface Dog : RLMObject
@property NSString *name;
// No backlink to person -- one-directional relationship
@end

// Define an RLMArray<Dog> type
RLM_COLLECTION_TYPE(Dog)

// Person.h
@interface Person : RLMObject
@property NSString *name;
// A person can have one dog
@property Dog *dog;
@end

// Dog.m
@implementation Dog
@end

// Person.m
@implementation Person
@end

```

#### Swift

```swift
class Person: Object {
    @Persisted var name: String = ""
    @Persisted var birthdate: Date = Date(timeIntervalSince1970: 1)

    // A person can have one dog
    @Persisted var dog: Dog?
}

class Dog: Object {
    @Persisted var name: String = ""
    @Persisted var age: Int = 0
    @Persisted var breed: String?
    // No backlink to person -- one-directional relationship
}

```

> Seealso:
> For more information about to-one relationships, see:
To-One Relationship.
>

### Define a To-Many Relationship Property
A **to-many** relationship maps one property to zero or more instances
of another object type. For example, you can model a person having any
number of companion dogs as a to-many relationship.

#### Objective-C

Use `RLMArray` tagged with your
target type to define your to-many relationship property.

> Tip:
> Remember to use the `RLM_COLLECTION_TYPE()` macro with your type
to declare the RLMArray protocol for your type.
>

```objectivec
// Dog.h
@interface Dog : RLMObject
@property NSString *name;
// No backlink to person -- one-directional relationship
@end

// Define an RLMArray<Dog> type
RLM_COLLECTION_TYPE(Dog)

// Person.h
@interface Person : RLMObject
@property NSString *name;
// A person can have many dogs
@property RLMArray<Dog *><Dog> *dogs;
@end

// Dog.m
@implementation Dog
@end

// Person.m
@implementation Person
@end

```

#### Swift

Use `List` tagged with your target
type to define your to-many relationship property.

```swift
class Person: Object {
    @Persisted var name: String = ""
    @Persisted var birthdate: Date = Date(timeIntervalSince1970: 1)

    // A person can have many dogs
    @Persisted var dogs: List<Dog>
}

class Dog: Object {
    @Persisted var name: String = ""
    @Persisted var age: Int = 0
    @Persisted var breed: String?
    // No backlink to person -- one-directional relationship
}

```

> Seealso:
> For more information about to-many relationships, see:
To-Many Relationship.
>

### Define an Inverse Relationship Property
An **inverse relationship** property is an automatic backlink
relationship. Realm automatically updates implicit
relationships whenever an object is added or removed in a corresponding
to-many list or to-one relationship property. You cannot manually set
the value of an inverse relationship property.

#### Swift

To define an inverse relationship, use `LinkingObjects` in your object model. The
`LinkingObjects` definition specifies the object type and
property name of the relationship that it inverts.

```swift
class User: Object {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var _partition: String = ""
    @Persisted var name: String = ""

    // A user can have many tasks.
    @Persisted var tasks: List<Task>
}

class Task: Object {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var _partition: String = ""
    @Persisted var text: String = ""

    // Backlink to the user. This is automatically updated whenever
    // this task is added to or removed from a user's task list.
    @Persisted(originProperty: "tasks") var assignee: LinkingObjects<User>
}

```

#### Objective-C

To define an inverse relationship, use
`RLMLinkingObjects` in your object model.
Override `+[RLMObject linkingObjectProperties]`
method in your class to specify the object type and property name
of the relationship that it inverts.

```objectivec
// Task.h
@interface Task : RLMObject
@property NSString *description;
@property (readonly) RLMLinkingObjects *assignees;
@end

// Define an RLMArray<Task> type
RLM_COLLECTION_TYPE(Task)

// User.h
@interface User : RLMObject
@property NSString *name;
@property RLMArray<Task *><Task> *tasks;
@end

// Task.m
@implementation Task
+ (NSDictionary *)linkingObjectsProperties {
    return @{
        @"assignees": [RLMPropertyDescriptor descriptorWithClass:User.class propertyName:@"tasks"],
    };
}
@end

// User.m
@implementation User
@end

```

#### Swift Pre 10.10.0

To define an inverse relationship, use `LinkingObjects`
in your object model. The `LinkingObjects` definition specifies
the object type and property name of the relationship that it inverts.

```swift
class User: Object {
    @objc dynamic var _id: ObjectId = ObjectId.generate()
    @objc dynamic var _partition: String = ""
    @objc dynamic var name: String = ""

    // A user can have many tasks.
    let tasks = List<Task>()

    override static func primaryKey() -> String? {
        return "_id"
    }
}

class Task: Object {
    @objc dynamic var _id: ObjectId = ObjectId.generate()
    @objc dynamic var _partition: String = ""
    @objc dynamic var text: String = ""

    // Backlink to the user. This is automatically updated whenever
    // this task is added to or removed from a user's task list.
    let assignee = LinkingObjects(fromType: User.self, property: "tasks")

    override static func primaryKey() -> String? {
        return "_id"
    }
}

```

> Seealso:
> For more information about inverse relationships, see:
Inverse Relationship.
>

### Define an Embedded Object Property
An **embedded object** exists as nested data inside of a single,
specific parent object. It inherits the lifecycle of its parent object
and cannot exist as an independent Realm object. Realm automatically
deletes embedded objects if their parent object is deleted or when
overwritten by a new embedded object instance.

> Note:
> When you delete a Realm object, any embedded objects referenced by
that object are deleted with it. If you want the referenced objects
to persist after the deletion of the parent object, your type should
not be an embedded object at all. Use a regular Realm object with a to-one relationship instead.
>

#### Objective-C

You can define an embedded object by deriving from the
`RLMEmbeddedObject` class. You can use your
embedded object in another model as you would any other type.

```objectivec
// Define an embedded object
@interface Address : RLMEmbeddedObject
@property NSString *street;
@property NSString *city;
@property NSString *country;
@property NSString *postalCode;
@end

// Enable Address for use in RLMArray
RLM_COLLECTION_TYPE(Address)

@implementation Address
@end

// Define an object with one embedded object
@interface Contact : RLMObject
@property NSString *name;

// Embed a single object.
@property Address *address;
@end

@implementation Contact
@end

// Define an object with an array of embedded objects
@interface Business : RLMObject
@property NSString *name;
// Embed an array of objects
@property RLMArray<Address *><Address> *addresses;
@end

```

#### Swift

You can define an embedded object by deriving from the
`EmbeddedObject`
class. You can use your embedded object in another model as you
would any other type.

```swift
class Person: Object {
    @Persisted(primaryKey: true) var id = 0
    @Persisted var name = ""

    // To-many relationship - a person can have many dogs
    @Persisted var dogs: List<Dog>

    // Inverse relationship - a person can be a member of many clubs
    @Persisted(originProperty: "members") var clubs: LinkingObjects<DogClub>

    // Embed a single object.
    // Embedded object properties must be marked optional.
    @Persisted var address: Address?

    convenience init(name: String, address: Address) {
        self.init()
        self.name = name
        self.address = address
    }
}

class DogClub: Object {
    @Persisted var name = ""
    @Persisted var members: List<Person>

    // DogClub has an array of regional office addresses.
    // These are embedded objects.
    @Persisted var regionalOfficeAddresses: List<Address>

    convenience init(name: String, addresses: [Address]) {
        self.init()
        self.name = name
        self.regionalOfficeAddresses.append(objectsIn: addresses)
    }
}

class Address: EmbeddedObject {
    @Persisted var street: String?
    @Persisted var city: String?
    @Persisted var country: String?
    @Persisted var postalCode: String?
}

```
