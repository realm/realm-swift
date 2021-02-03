# Migration Examples

The Migration project shows several examples of migrations and migration blocks.

The purpose of this example is to provide a more in depth view of certain problems and pitfalls users might face when 
migrations get more complex and the number of versions increases.

## How to use the example

You can build and run the project since this is the default state (see `CREATE_EXAMPLES` pre-compiler flag in
 `AppDelegate`).

There is nothing much so see in terms of unit tests, console log or in the app itself. If there is no error the
migration was successful.

The files to look at are located in the `Examples` folder. Every file contains an extract of everything necessary for
this version (schema version, objects, migration).

## How to create new schema versions

(the example shows going from schema version 5 to version 6 - changes version numbers depending on your schema version)

1. Uncomment the `-DCREATE_EXAMPLES` line in `Migration.xcconfig` which activates the creation of new `.realm` files.
2. Comment `OTHER_SWIFT_FLAGS = $(inherited) -DSCHEMA_VERSION_5;` since version `5` already exists.
3. Add a new line `OTHER_SWIFT_FLAGS = $(inherited) -DSCHEMA_VERSION_6;` to create version `6`.
4. Duplicate the `Example_v5.swift` file to create a new schema version:
   - Change `SCHEMA_VERSION_5` to `SCHEMA_VERSION_6`.   
   - Change `let schemaVersion = 5` to `let schemaVersion = 6`.
   - Update the `Object` definitions according to your new example.
   - Update the `migrationBlock` and the `migrationCheck`.
   - Create some `exampleData` for this specific schema version (they will be used in later schema version).
6. Run the app.
7. The realm file created by this run must then be added to project (`Examples` folder).

## Important notes

* The migration block is repeated in each `RealmFile_v`x`.swift` file since some parts of older migrations might change
over time as well when tables or properties get renamed or their internal structure changes. This is something a
developer has to take care of and adjust when adding new schema versions.
