# Realm Object Models - SwiftUI
## Concepts: Object Models and Relationships
Modeling data for SwiftUI builds on the same object model and relationship
concepts in the Swift SDK. If you are unfamiliar with Realm Swift SDK
data modeling concepts, see: Define a Realm Object Model - Swift SDK.

## Binding the Object Model to the UI
The Model-View-ViewModel (MVVM) design pattern advocates creating a view
model that abstracts the model from the View code. While you can certainly
do that with Realm, the Swift SDK provides tools that make it easy to
work directly with your data in SwiftUI Views. These tools include things
like:

- Property wrappers that create bindings to underlying observable objects
- A class to project and transform underlying model objects for use in
specific views

## Transforming Data for SwiftUI Views
The Realm Swift SDK provides a special type of object, called a `Projection`, to transform
and work with subsets of your data. Consider a projection similar to
a view model. It lets you pass through or transform the original
object's properties in different ways:

- Passthrough: The projection's property has the same name and type as
the original object.
- Rename: The projection's property has the same type as the original object,
but a different name.
- Keypath resolution: Use this to access specific properties of the
projected Object.
- Collection mapping: You can map some collection types to a collection of primitive values.
- Exclusion: All properties of the original Realm object not defined in
the projection model. Any changes to those properties do not trigger a
change notification when observing the projection.

When you use a Projection, you get all the benefits of Realm's
live objects:

- The class-projected object live updates
- You can observe it for changes
- You can apply changes directly to the properties in write transactions

## Define a New Object
You can define a Realm object by deriving from the
`Object` or
`EmbeddedObject`
class. The name of the class becomes the table name in the realm,
and properties of the class persist in the database. This makes it
as easy to work with persisted objects as it is to work with
regular Swift objects.

The Realm SwiftUI documentation uses a model for a fictional app,
DoggoDB. This app is a company directory of employees who have dogs. It
lets people share a few details about their dogs with other employees.

The data model includes a Person object, with a to-many
relationship to that person's Dog objects.
It also uses a special Realm Swift SDK data type, `PersistableEnum`, to store information
about the person's business unit.

```swift
class Person: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var firstName = ""
    @Persisted var lastName = ""
    @Persisted var personId = ""
    @Persisted var company = "my business"
    @Persisted var businessUnit = BusinessUnitEnum.engineering
    @Persisted var profileImageUrl: URL?
    @Persisted var dogs: List<Dog>
}

enum BusinessUnitEnum: String, PersistableEnum, CaseIterable {
    case customerEngineering = "Customer Engineering"
    case educationCommunityAndDocs = "Education, Community and Docs"
    case engineering = "Engineering"
    case financeAndOperations = "Finance and Operations"
    case humanResourcesAndRescruiting = "Human Resources and Recruiting"
    case management = "Management"
    case marketing = "Marketing"
    case product = "Product"
    case sales = "Sales"
}

class Dog: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id: UUID
    @Persisted var name = ""
    @Persisted var breed = ""
    @Persisted var weight = 0
    @Persisted var favoriteToy = ""
    @Persisted var profileImageUrl: URL?
    @Persisted var dateLastUpdated = Date()
    @Persisted(originProperty: "dogs") var person: LinkingObjects<Person>
    var firstLetter: String {
        guard let char = name.first else {
            return ""
        }
        return String(char)
    }
}

```

> Seealso:
> For complete details about defining a Realm object model, see:
>
> - Object Models
> - Relationships
> - Supported Data Types
>

## Define a Projection
Our fictional DoggoDB app has a user Profile view. This view displays
some details about the person, but we don't need all of the properties
of the `Person` model. We can create a `Projection` with only the details we want. We can also modify
the `lastName` property to use just the first initial of the last name.

```swift
class Profile: Projection<Person> {
    @Projected(\Person.firstName) var firstName // Passthrough from original object
    @Projected(\Person.lastName.localizedCapitalized.first) var lastNameInitial // Access and transform the original property
    @Projected(\Person.personId) var personId
    @Projected(\Person.businessUnit) var businessUnit
    @Projected(\Person.profileImageUrl) var profileImageUrl
    @Projected(\Person.dogs) var dogs
}

```

We can use this projection in the Profile view instead of the original
`Person` object.

Class projection works with SwiftUI property wrappers:

- `ObservedRealmObject`
- `ObservedResults`

> Seealso:
> For a complete example of using a class projection in a SwiftUI
application, see [the Projections example app](https://github.com/realm/realm-cocoa/tree/master/examples#projections).
>
