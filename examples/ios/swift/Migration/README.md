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

How to create new examples:

1. Uncomment out the `-DCREATE_EXAMPLES` line in `Migration.xcconfig`.
2. Duplicate `OTHER_SWIFT_FLAGS = $(inherited) -DSCHEMA_VERSION_5;` and increase the version by 1.
3. Duplicate the most recent `Example_v`x`.swift` file.
4. Comment out the previous one. Update the current one:
   - Increase the `schemaVersion`.
   - Update the `Object` definitions according to your new example.
   - Update the migration block.
   - Create some examples for that specific schema version (they will be used in later schema version).
5. Run the app.
6. The realm file created by this run must then be added to project (`Examples` folder).

## Important notes

* The migration block is repeated in each `RealmFile_v`x`.swift` file since some parts of older migrations might change
over time as well when tables or properties get renamed or their internal structure changes. This is something a
developer has to take care of and adjust when adding new schema versions.
