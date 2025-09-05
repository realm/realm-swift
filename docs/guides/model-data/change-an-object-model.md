# Change an Object Model - Swift SDK

## Overview
When you update your object schema, you must increment the schema version
and perform a migration.

> Seealso:
> This page provides general Swift and Objective-C migration examples.
If you are using Realm with SwiftUI, see the SwiftUI-specific
migration examples.
>

If your schema update adds optional properties or removes properties,
Realm can perform the migration automatically. You only need to
increment the `schemaVersion`.

For more complex schema updates, you must also manually specify the migration logic
in a `migrationBlock`. This might include changes such as:

- Adding required properties that must be populated with default values
- Combining fields
- Renaming a field
- Changing a field's type
- Converting from an object to an embedded object

> Tip:
> When developing or debugging your application, you may prefer to delete
the realm instead of migrating it. Use the
`deleteRealmIfMigrationNeeded`
flag to delete the database automatically when a schema mismatch would
require a migration.
>
> Never release an app to production with this flag set to `true`.
>

## Schema Version
A **schema version** identifies the state of a Realm Schema at some point in time. Realm tracks the schema
version of each realm and uses it to map the objects in each realm
to the correct schema.

Schema versions are integers that you may include
in the realm configuration when you open a realm. If a client
application does not specify a version number when it opens a realm then
the realm defaults to version `0`.

> Important:
> Migrations must update a realm to a higher schema version.
Realm will throw an error if a client application opens
a realm with a schema version that is lower than the realm's
current version or if the specified schema version is the same as the
realm's current version but includes different object
schemas.
>

### Migrations
Local migrations have access to the existing
Realm Schema, version, and objects and define logic that
incrementally updates the realm to its new schema version.
To perform a local migration you must specify a new schema
version that is higher than the current version and provide
a migration function when you open the out-of-date realm.

In iOS, you can update underlying data to reflect schema changes using
manual migrations. During such a
manual migration, you can define new and deleted properties when they
are added or removed from your schema.

## Automatically Update Schema
### Add a Property
Realm can automatically migrate added
properties, but you must specify an updated schema version when you make
these changes.

> Note:
> Realm does not automatically set values for new required
properties. You must use a migration block to set default values for
new required properties. For new optional properties, existing records
can have null values. This means you don't need a migration block when
adding optional properties.
>

> Example:
> A realm using schema version `1` has a `Person` object type
that has first name, last name, and age properties:
>
> #### Objective-C
>
> ```objectivec
> // In the first version of the app, the Person model
> // has separate fields for first and last names,
> // and an age property.
> @interface Person : RLMObject
> @property NSString *firstName;
> @property NSString *lastName;
> @property int age;
> @end
>
> @implementation Person
> + (NSArray<NSString *> *)requiredProperties {
>     return @[@"firstName", @"lastName", @"age"];
> }
> @end
>
> ```
>
>
> #### Swift
>
> ```swift
> // In the first version of the app, the Person model
> // has separate fields for first and last names,
> // and an age property.
> class Person: Object {
>     @Persisted var firstName = ""
>     @Persisted var lastName = ""
>     @Persisted var age = 0
> }
>
> ```
>
>
> The developer decides that the `Person` class needs an `email` field and updates
the schema.
>
> #### Objective-C
>
> ```objectivec
> // In a new version, you add a property
> // on the Person model.
> @interface Person : RLMObject
> @property NSString *firstName;
> @property NSString *lastName;
> // Add a new "email" property.
> @property NSString *email;
> // New properties can be migrated
> // automatically, but must update the schema version.
> @property int age;
> @end
>
> @implementation Person
> + (NSArray<NSString *> *)requiredProperties {
>     return @[@"firstName", @"lastName", @"email", @"age"];
> }
> @end
>
> ```
>
>
> #### Swift
>
> ```swift
> // In a new version, you add a property
> // on the Person model.
> class Person: Object {
>     @Persisted var firstName = ""
>     @Persisted var lastName = ""
>     // Add a new "email" property.
>     @Persisted var email: String?
>     // New properties can be migrated
>     // automatically, but must update the schema version.
>     @Persisted var age = 0
>
> }
>
> ```
>
>
> Realm automatically migrates the realm to conform to
the updated `Person` schema. But the developer must set the realm's
schema version to `2`.
>
> #### Objective-C
>
> ```objectivec
> // When you open the realm, specify that the schema
> // is now using a newer version.
> RLMRealmConfiguration *config = [[RLMRealmConfiguration alloc] init];
> // Set the new schema version
> config.schemaVersion = 2;
> // Use this configuration when opening realms
> [RLMRealmConfiguration setDefaultConfiguration:config];
> RLMRealm *realm = [RLMRealm defaultRealm];
>
> ```
>
>
> #### Swift
>
> ```swift
> // When you open the realm, specify that the schema
> // is now using a newer version.
> let config = Realm.Configuration(
>     schemaVersion: 2)
> // Use this configuration when opening realms
> Realm.Configuration.defaultConfiguration = config
> let realm = try! Realm()
>
> ```
>
>

### Delete a Property
To delete a property from a schema, remove the property from the object's class
and set a `schemaVersion` of the realm's configuration object. Deleting a property
will not impact existing objects.

> Example:
> A realm using schema version `1` has a `Person` object type
that has first name, last name, and age properties:
>
> #### Objective-C
>
> ```objectivec
> // In the first version of the app, the Person model
> // has separate fields for first and last names,
> // and an age property.
> @interface Person : RLMObject
> @property NSString *firstName;
> @property NSString *lastName;
> @property int age;
> @end
>
> @implementation Person
> + (NSArray<NSString *> *)requiredProperties {
>     return @[@"firstName", @"lastName", @"age"];
> }
> @end
>
> ```
>
>
> #### Swift
>
> ```swift
> // In the first version of the app, the Person model
> // has separate fields for first and last names,
> // and an age property.
> class Person: Object {
>     @Persisted var firstName = ""
>     @Persisted var lastName = ""
>     @Persisted var age = 0
> }
>
> ```
>
>
> The developer decides that the `Person` does not need the `age` field and updates the schema.
>
> #### Objective-C
>
> ```objectivec
> // In a new version, you remove a property
> // on the Person model.
> @interface Person : RLMObject
> @property NSString *firstName;
> @property NSString *lastName;
> // Remove the "age" property.
> // @property int age;
> // Removed properties can be migrated
> // automatically, but must update the schema version.
> @end
>
> @implementation Person
> + (NSArray<NSString *> *)requiredProperties {
>     return @[@"firstName", @"lastName"];
> }
> @end
>
> ```
>
>
> #### Swift
>
> ```swift
> // In a new version, you remove a property
> // on the Person model.
> class Person: Object {
>     @Persisted var firstName = ""
>     @Persisted var lastName = ""
>     // Remove the "age" property.
>     // @Persisted var age = 0
>     // Removed properties can be migrated
>     // automatically, but must update the schema version.
>
> }
>
> ```
>
>
> Realm automatically migrates the realm to conform to
the updated `Person` schema. But the developer must set the realm's
schema version to `2`.
>
> #### Objective-C
>
> ```objectivec
> // When you open the realm, specify that the schema
> // is now using a newer version.
> RLMRealmConfiguration *config = [[RLMRealmConfiguration alloc] init];
> // Set the new schema version
> config.schemaVersion = 2;
> // Use this configuration when opening realms
> [RLMRealmConfiguration setDefaultConfiguration:config];
> RLMRealm *realm = [RLMRealm defaultRealm];
>
> ```
>
>
> #### Swift
>
> ```swift
> // When you open the realm, specify that the schema
> // is now using a newer version.
> let config = Realm.Configuration(
>     schemaVersion: 2)
> // Use this configuration when opening realms
> Realm.Configuration.defaultConfiguration = config
> let realm = try! Realm()
>
> ```
>
>

> Tip:
> SwiftUI developers may see an error that a migration is required when they
add or delete properties. This is related to the lifecycle in SwiftUI.
The Views are laid out, and then the `.environment` modifier sets the
config.
>
> To resolve a migration error in these circumstances, pass
`Realm.Configuration(schemaVersion: <Your Incremented Version>)`
into the `ObservedResults` constructor.
>

## Manually Migrate Schema
For more complex schema updates, Realm requires a manual
migration for old instances of a given object to the new schema.

### Rename a Property
To rename a property during a migration, use the
`Migration.renameProperty(onType:from:to:)`
method.

Realm applies any new nullability or indexing settings
during the rename operation.

> Example:
> Rename `age` to `yearsSinceBirth` within a `migrationBlock`.
>
> #### Objective-C
>
> ```objectivec
> RLMRealmConfiguration *config = [[RLMRealmConfiguration alloc] init];
> config.schemaVersion = 2;
> config.migrationBlock = ^(RLMMigration * _Nonnull migration, uint64_t oldSchemaVersion) {
>     if (oldSchemaVersion < 2) {
>         // Rename the "age" property to "yearsSinceBirth".
>         // The renaming operation should be done outside of calls to `enumerateObjects(ofType: _:)`.
>         [migration renamePropertyForClass:[Person className] oldName:@"age" newName:@"yearsSinceBirth"];
>     }
> };
>
> ```
>
>
> #### Swift
>
> ```swift
> let config = Realm.Configuration(
>     schemaVersion: 2,
>     migrationBlock: { migration, oldSchemaVersion in
>         if oldSchemaVersion < 2 {
>             // Rename the "age" property to "yearsSinceBirth".
>             // The renaming operation should be done outside of calls to `enumerateObjects(ofType: _:)`.
>             migration.renameProperty(onType: Person.className(), from: "age", to: "yearsSinceBirth")
>         }
>     })
>
> ```
>
>

### Modify Properties
> Tip:
> You can use the `deleteRealmIfMigrationNeeded`
method to delete the realm if it would require a migration. This can
be useful during development when you need to iterate quickly and don't
want to perform the migration.
>

To define custom migration logic, set the `migrationBlock`
property of the `Configuration` when opening a realm.

The migration block receives a `Migration object` that you can use to perform the migration. You
can use the Migration object's `enumerateObjects(ofType:_:)`
method to iterate over and update all instances of a given
Realm type in the realm.

> Example:
> A realm using schema version `1` has a `Person` object type
that has separate fields for first and last names:
>
> #### Objective-C
>
> ```objectivec
> // In the first version of the app, the Person model
> // has separate fields for first and last names,
> // and an age property.
> @interface Person : RLMObject
> @property NSString *firstName;
> @property NSString *lastName;
> @property int age;
> @end
>
> @implementation Person
> + (NSArray<NSString *> *)requiredProperties {
>     return @[@"firstName", @"lastName", @"age"];
> }
> @end
>
> ```
>
>
> #### Swift
>
> ```swift
> // In the first version of the app, the Person model
> // has separate fields for first and last names,
> // and an age property.
> class Person: Object {
>     @Persisted var firstName = ""
>     @Persisted var lastName = ""
>     @Persisted var age = 0
> }
>
> ```
>
>
> The developer decides that the `Person` class should use a combined
`fullName` field instead of the separate `firstName` and
`lastName` fields and updates the schema.
>
> To migrate the realm to conform to the updated `Person` schema,
the developer sets the realm's schema version to `2` and
defines a migration function to set the value of `fullName` based
on the existing `firstName` and `lastName` properties.
>
> #### Objective-C
>
> ```objectivec
> // In version 2, the Person model has one
> // combined field for the full name and age as a Int.
> // A manual migration will be required to convert from
> // version 1 to this version.
> @interface Person : RLMObject
> @property NSString *fullName;
> @property int age;
> @end
>
> @implementation Person
> + (NSArray<NSString *> *)requiredProperties {
>     return @[@"fullName", @"age"];
> }
> @end
>
> ```
>
> ```objectivec
> RLMRealmConfiguration *config = [[RLMRealmConfiguration alloc] init];
> // Set the new schema version
> config.schemaVersion = 2;
> config.migrationBlock = ^(RLMMigration * _Nonnull migration, uint64_t oldSchemaVersion) {
>     if (oldSchemaVersion < 2) {
>         // Iterate over every 'Person' object stored in the Realm file to
>         // apply the migration
>         [migration enumerateObjects:[Person className]
>                             block:^(RLMObject * _Nullable oldObject, RLMObject * _Nullable newObject) {
>             // Combine name fields into a single field
>             newObject[@"fullName"] = [NSString stringWithFormat:@"%@ %@",
>                                         oldObject[@"firstName"],
>                                         oldObject[@"lastName"]];
>         }];
>     }
> };
>
> // Tell Realm to use this new configuration object for the default Realm
> [RLMRealmConfiguration setDefaultConfiguration:config];
>
> // Now that we've told Realm how to handle the schema change, opening the realm
> // will automatically perform the migration
> RLMRealm *realm = [RLMRealm defaultRealm];
>
> ```
>
>
> #### Swift
>
> ```swift
> // In version 2, the Person model has one
> // combined field for the full name and age as a Int.
> // A manual migration will be required to convert from
> // version 1 to this version.
> class Person: Object {
>     @Persisted var fullName = ""
>     @Persisted var age = 0
> }
>
> ```
>
> ```swift
> // In application(_:didFinishLaunchingWithOptions:)
> let config = Realm.Configuration(
>     schemaVersion: 2, // Set the new schema version.
>     migrationBlock: { migration, oldSchemaVersion in
>         if oldSchemaVersion < 2 {
>             // The enumerateObjects(ofType:_:) method iterates over
>             // every Person object stored in the Realm file to apply the migration
>             migration.enumerateObjects(ofType: Person.className()) { oldObject, newObject in
>                 // combine name fields into a single field
>                 let firstName = oldObject!["firstName"] as? String
>                 let lastName = oldObject!["lastName"] as? String
>                 newObject!["fullName"] = "\(firstName!) \(lastName!)"
>             }
>         }
>     }
> )
>
> // Tell Realm to use this new configuration object for the default Realm
> Realm.Configuration.defaultConfiguration = config
>
> // Now that we've told Realm how to handle the schema change, opening the file
> // will automatically perform the migration
> let realm = try! Realm()
>
> ```
>
>
> Later, the developer decides that the `age` field should be of type `String`
rather than `Int` and updates the schema.
>
> To migrate the realm to conform to the updated `Person` schema,
the developer sets the realm's schema version to `3` and
adds a conditional to the migration function so that the function defines
how to migrate from any previous version to the new one.
>
> #### Objective-C
>
> ```objectivec
> // In version 3, the Person model has one
> // combined field for the full name and age as a String.
> // A manual migration will be required to convert from
> // version 2 to this version.
> @interface Person : RLMObject
> @property NSString *fullName;
> @property NSString *age;
> @end
>
> @implementation Person
> + (NSArray<NSString *> *)requiredProperties {
>     return @[@"fullName", @"age"];
> }
> @end
>
> ```
>
> ```objectivec
> RLMRealmConfiguration *config = [[RLMRealmConfiguration alloc] init];
> // Set the new schema version
> config.schemaVersion = 3;
> config.migrationBlock = ^(RLMMigration * _Nonnull migration, uint64_t oldSchemaVersion) {
>     if (oldSchemaVersion < 2) {
>         // Previous Migration.
>         [migration enumerateObjects:[Person className]
>                             block:^(RLMObject * _Nullable oldObject, RLMObject * _Nullable newObject) {
>             newObject[@"fullName"] = [NSString stringWithFormat:@"%@ %@",
>                                         oldObject[@"firstName"],
>                                         oldObject[@"lastName"]];
>         }];
>     }
>     if (oldSchemaVersion < 3) {
>         // New Migration
>         [migration enumerateObjects:[Person className]
>                             block:^(RLMObject * _Nullable oldObject, RLMObject * _Nullable newObject) {
>             // Make age a String instead of an Int
>             newObject[@"age"] = [oldObject[@"age"] stringValue];
>         }];
>     }
> };
>
> // Tell Realm to use this new configuration object for the default Realm
> [RLMRealmConfiguration setDefaultConfiguration:config];
>
> // Now that we've told Realm how to handle the schema change, opening the realm
> // will automatically perform the migration
> RLMRealm *realm = [RLMRealm defaultRealm];
>
> ```
>
>
> #### Swift
>
> ```swift
> // In version 3, the Person model has one
> // combined field for the full name and age as a String.
> // A manual migration will be required to convert from
> // version 2 to this version.
>  class Person: Object {
>     @Persisted var fullName = ""
>     @Persisted var age = "0"
>  }
>
> ```
>
> ```swift
> // In application(_:didFinishLaunchingWithOptions:)
> let config = Realm.Configuration(
>     schemaVersion: 3, // Set the new schema version.
>     migrationBlock: { migration, oldSchemaVersion in
>         if oldSchemaVersion < 2 {
>             // Previous Migration.
>             migration.enumerateObjects(ofType: Person.className()) { oldObject, newObject in
>                 let firstName = oldObject!["firstName"] as? String
>                 let lastName = oldObject!["lastName"] as? String
>                 newObject!["fullName"] = "\(firstName!) \(lastName!)"
>             }
>         }
>         if oldSchemaVersion < 3 {
>             // New Migration.
>             migration.enumerateObjects(ofType: Person.className()) { oldObject, newObject in
>                 // Make age a String instead of an Int
>                 newObject!["age"] = "\(oldObject!["age"] ?? 0)"
>             }
>         }
>     }
> )
>
> // Tell Realm to use this new configuration object for the default Realm
> Realm.Configuration.defaultConfiguration = config
>
> // Now that we've told Realm how to handle the schema change, opening the file
> // will automatically perform the migration
> let realm = try! Realm()
>
> ```
>
>

> Tip:
> Avoid nesting or otherwise skipping `if (oldSchemaVersion < X)` statements
in migration blocks. This ensures that all updates can be applied in the correct order,
no matter which schema version a client starts from. The goal is to define
migration logic which can transform data from any outdated schema version to
match the current schema.
>

### Convert from Object to EmbeddedObject
Embedded objects cannot exist
independently of a parent object. When changing an Object to an
EmbeddedObject, the migration block must ensure that every embedded
object has exactly one backlink to a parent object. Having no backlinks
or multiple backlinks raises the following exceptions:

```
At least one object does not have a backlink (data would get lost).
```

```
At least one object does have multiple backlinks.
```

> Seealso:
> Define an Embedded Object Property
>

## Additional Migration Examples
Please check out the additional migration examples on the
[realm-swift repo](https://github.com/realm/realm-swift/tree/master/examples/ios/swift/Migration).
