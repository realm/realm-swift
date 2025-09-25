# Model Data - Swift SDK
## Object Types & Schemas
Realm applications model data as objects composed of
field-value pairs that each contain one or more supported data types.

Realm objects are regular Swift or Objective-C classes, but
they also bring a few additional features like live queries. The Swift SDK memory maps Realm objects directly to
native Swift or Objective-C objects, which means there's no need to use
a special data access library, such as an [ORM](https://en.wikipedia.org/wiki/Object-relational_mapping). Instead, you can work with Realm objects
as you would any other class instance.

Every Realm object conforms to a specific **object type**, which is
essentially a class that defines the properties
and relationships for objects of that type.
Realm guarantees that all objects in a realm conform to
the schema for their object type and validates objects whenever they're
created, modified, or deleted.

> Example:
> The following schema defines a `Dog` object type with a string name,
optional string breed, date of birth, and primary key ID.
>
> #### Objective-C
>
> ```objectivec
> // A dog has an _id primary key, a string name, an optional
> // string breed, and a date of birth.
> @interface Dog : RLMObject
> @property RLMObjectId *_id;
> @property NSString *name;
> @property NSString *breed;
> @property NSDate *dateOfBirth;
> @end
>
> @implementation Dog
> + (NSString *)primaryKey {
>     return @"_id";
> }
>
> + (NSArray<NSString *> *)requiredProperties {
>     return @[
>         @"_id", @"name", @"dateOfBirth"
>     ];
> }
> @end
>
> ```
>
>
> #### Swift
>
> ```swift
> // A dog has an _id primary key, a string name, an optional
> // string breed, and a date of birth.
> class Dog: Object {
>     @Persisted(primaryKey: true) var _id: ObjectId
>     @Persisted var name = ""
>     @Persisted var breed: String?
>     @Persisted var dateOfBirth = Date()
> }
>
> ```
>
>

### Realm Schema
A **realm schema** is a list of valid object schemas that a realm may contain. Every Realm object must
conform to an object type that's included in its realm's schema.

By default, the Swift SDK automatically adds all classes in your project
that derive from [RLMObject](https://www.mongodb.com/docs/realm-sdks/objc/latest/Classes/RLMObject.html) or
[RLMEmbeddedObject](https://www.mongodb.com/docs/realm-sdks/objc/latest/Classes/RLMEmbeddedObject.html) to the
realm schema.

> Tip:
> To control which classes Realm adds to a realm schema, see
Provide a Subset of Classes to a Realm.
>

If a realm already contains data when you open it,
Realm validates each object to ensure that an object
schema was provided for its type and that it meets all of the
constraints specified in the schema.

> Tip:
> For code examples that show how to configure and open a realm in the
Swift SDK, see Configure & Open a Realm - Swift SDK.
>

### Model Inheritance
You can subclass Realm models to share behavior between
classes, but there are limitations. In particular, Realm
does not allow you to:

- Cast between polymorphic classes: subclass to subclass, subclass to parent, parent to subclass
- Query on multiple classes simultaneously: for example, "get all instances of parent class and subclass"
- Multi-class containers: `List` and `Results` with a mixture of parent and subclass

> Tip:
> Check out the [code samples](https://github.com/realm/realm-swift/issues/1109#issuecomment-143834756) for working
around these limitations.
>

> Version added: 10.10.0While you can't mix  and  property declarations
within a class, you can mix the notation styles across base and subclasses.
For example, a base class could have a  property,
and a subclass could have an  property, with
both persisted. However, the  property would be ignored if
the  property were within the same base or subclass.

### Swift Structs
Realm does not support Swift structs as models for a variety of
reasons. Realm's design focuses on "live" objects.
This concept is not compatible with value type structs. By design,
Realm provides features that are incompatible with these
semantics, such as:

- Live data
- Reactive APIs
- Low memory footprint of data
- Good operation performance
- Lazy and cheap access to partial data
- Lack of data serialization/deserialization
- Keeping potentially complex object graphs synchronized

That said, it is sometimes useful to detach objects from their backing
realm. This typically isn't an ideal design decision. Instead,
developers use this as a workaround for temporary limitations in our
library.

You can use key-value coding to initialize an unmanaged object as a copy of
a managed object. Then, you can work with that unmanaged object
like any other [NSObject](https://developer.apple.com/documentation/objectivec/nsobject).

```swift
let standaloneModelObject = MyModel(value: persistedModelObject)
```

## Properties
Your Realm object model is a collection of properties. On the most basic level,
when you create your model, your declarations give Realm information about
each property:

- The data type and whether the property is optional or required
- Whether Realm should store or ignore the property
- Whether the property is a primary key or should be indexed

Properties are also the mechanism for establishing relationships between Realm object types.

The Realm Swift SDK uses reflection to determine the properties
in your models at runtime. Your project must not set
`SWIFT_REFLECTION_METADATA_LEVEL = none`, or Realm cannot discover
children of types, such as properties and enum cases. Reflection is enabled
by default if your project does not specifically set a level for this setting.

## View Models with Realm
> Version added: 10.21.0

You can work with a subset of your Realm object's properties
by creating a class projection. A class projection is a class that passes
through or transforms some or all of your Realm object's
properties. Class projection enables you to build view models that use an
abstraction of your object model. This simplifies using and testing Realm objects
in your application.

With class projection, you can use a subset of your object's properties
directly in the UI or transform them. When you use a class projection for
this, you get all the benefits of Realm's live objects:

- The class-projected object live updates
- You can observe it for changes
- You can apply changes directly to the properties in write transactions

> Seealso:
> Define a Class Projection
>

## Relationships
Realm doesn't use bridge tables or explicit joins to define
relationships as you would in a relational database. Realm
handles relationships through embedded objects or reference properties to
other Realm objects. You read from and write to these
properties directly. This makes querying relationships as performant as
querying against any other property.

Realm supports **to-one**, **to-many**, and **inverse**
relationships.

### To-One Relationship
A **to-one** relationship means that an object relates to one other object.
You define a to-one relationship for an object type in its object
schema. Specify a property where the type is the related Realm
object type. For example, a dog might have a to-one relationship with
a favorite toy.

> Tip:
> To learn how to define a to-one relationship, see
Define a To-One Relationship Property.
>

### To-Many Relationship
A **to-many** relationship means that an object relates to more than one
other object. In Realm, a to-many relationship is a list of
references to other objects. For example, a person might have many dogs.

A `List` represents the to-many
relationship between two Realm
types. Lists are mutable: within a write transaction, you can add and
remove elements to and from a list. Lists are not associated with a
query and are usually declared as a property of an object model.

> Tip:
> To learn how to define a to-many relationship, see
Define a To-Many Relationship Property.
>

### Inverse Relationship
Relationship definitions in Realm are unidirectional. An
**inverse relationship** links an object back to an object that refers
to it. You must explicitly define a property in the object's model as an
inverse relationship. Inverse relationships can link back to objects in
a to-one or to-many relationship.

A `LinkingObjects` collection
represents the inverse relationship
between two Realm types. You cannot directly add or remove
items from a LinkingObjects collection.

Inverse relationships automatically update themselves with corresponding
backlinks. You can find the same set of Realm objects with a
manual query, but the inverse relationship field reduces boilerplate query
code and capacity for error.

For example, consider a task tracker with the to-many relationship "User has
many Tasks". This does not automatically create the inverse relationship
"Task belongs to User". To create the inverse relationship, add a User
property on the Task that points back to the task's owner. When you specify
the inverse relationship from task to user, you can query on that. If you
don't specify the inverse relationship, you must run a separate query to
look up the user to whom the task is assigned.

> Important:
> You cannot manually set the value of an inverse relationship property.
Instead, Realm updates implicit relationships when you add
or remove an object in the relationship.
>

Relationships can be many-to-one or many-to-many. So following inverse
relationships can result in zero, one, or many objects.

> Tip:
> To learn how to define an inverse relationship, see
Define an Inverse Relationship Property.
>
