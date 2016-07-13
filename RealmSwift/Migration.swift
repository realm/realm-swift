////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

import Foundation
import Realm
import Realm.Private

#if swift(>=3.0)

/**
Migration block used to migrate a Realm.

- parameter migration: `Migration` object used to perform the migration. The
                       migration object allows you to enumerate and alter any
                       existing objects which require migration.
- parameter oldSchemaVersion: The schema version of the `Realm` being migrated.
*/
public typealias MigrationBlock = (migration: Migration, oldSchemaVersion: UInt64) -> Void

/// Object class used during migrations.
public typealias MigrationObject = DynamicObject

/**
Provides both the old and new versions of an object in this Realm. Object properties can only be
accessed using subscripting.

- parameter oldObject: Object in original `Realm` (read-only).
- parameter newObject: Object in migrated `Realm` (read-write).
*/
public typealias MigrationObjectEnumerateBlock = (oldObject: MigrationObject?, newObject: MigrationObject?) -> Void

/**
Get the schema version for a Realm at a given local URL.

- parameter fileURL:       Local URL to a Realm file.
- parameter encryptionKey: Optional 64-byte encryption key for encrypted Realms.

- throws: An NSError that describes the problem.

- returns: The version of the Realm at `fileURL`.
*/
public func schemaVersionAtURL(_ fileURL: URL, encryptionKey: Data? = nil) throws -> UInt64 {
    var error: NSError?
    let version = RLMRealm.__schemaVersion(at: fileURL, encryptionKey: encryptionKey, error: &error)
    guard version != RLMNotVersioned else {
        throw error!
    }
    return version
}

/**
Performs the configuration's migration block on the Realm created by the given
configuration.

This method is called automatically when opening a Realm for the first time and does
not need to be called explicitly. You can choose to call this method to control
exactly when and how migrations are performed.

- parameter configuration: The Realm.Configuration used to create the Realm to be
                           migrated, and containing the schema version and migration
                           block used to perform the migration.

- returns: `nil` if the migration was successful, or an `NSError` object that describes the problem
           that occurred otherwise.
*/
@discardableResult
public func migrateRealm(_ configuration: Realm.Configuration = Realm.Configuration.defaultConfiguration) throws {
    if let error = RLMRealm.migrateRealm(configuration.rlmConfiguration) {
        throw error
    }
}


/**
`Migration` is the object passed into a user-defined `MigrationBlock` when updating the version
of a `Realm` instance.

This object provides access to the previous and current `Schema`s for this migration.
*/
public final class Migration {

    // MARK: Properties

    /// The migration's old `Schema`, describing the `Realm` before applying a migration.
    public var oldSchema: Schema { return Schema(rlmMigration.oldSchema) }

    /// The migration's new `Schema`, describing the `Realm` after applying a migration.
    public var newSchema: Schema { return Schema(rlmMigration.newSchema) }

    internal var rlmMigration: RLMMigration

    // MARK: Altering Objects During a Migration

    /**
    Enumerates objects of a given type in this Realm, providing both the old and new versions of
    each object. Object properties can be accessed using subscripting.

    - parameter objectClassName: The name of the `Object` class to enumerate.
    - parameter block:           The block providing both the old and new versions of an object in this Realm.
    */
    public func enumerateObjects(ofType typeName: String, _ block: MigrationObjectEnumerateBlock) {
        rlmMigration.enumerateObjects(typeName) {
            block(oldObject: unsafeBitCast($0, to: MigrationObject.self),
                  newObject: unsafeBitCast($1, to: MigrationObject.self))
        }
    }

    /**
    Create an `Object` of type `className` in the Realm being migrated.

    - parameter className: The name of the `Object` class to create.
    - parameter value:     The object used to populate the new `Object`. This can be any key/value coding
                           compliant object, or a JSON object such as those returned from the methods in
                           `NSJSONSerialization`, or an `Array` with one object for each persisted
                           property. An exception will be thrown if any required properties are not
                           present and no default is set.

    - returns: The created object.
    */
    @discardableResult
    public func createObject(ofType typeName: String, populatedWith value: AnyObject = [:]) -> MigrationObject {
        return unsafeBitCast(rlmMigration.createObject(typeName, withValue: value), to: MigrationObject.self)
    }

    /**
    Delete an object from a Realm during a migration. This can be called within
    `enumerate(_:block:)`.

    - parameter object: Object to be deleted from the Realm being migrated.
    */
    public func delete(_ object: MigrationObject) {
        RLMDeleteObjectFromRealm(object, RLMObjectBaseRealm(object))
    }

    /**
    Deletes the data for the class with the given name.
    This deletes all objects of the given class, and if the Object subclass no longer exists in your program,
    cleans up any remaining metadata for the class in the Realm file.

    - parameter objectClassName: The name of the Object class to delete.

    - returns: `true` if there was any data to delete.
    */
    @discardableResult
    public func deleteData(forType typeName: String) -> Bool {
        return rlmMigration.deleteData(forClassName: typeName)
    }

    /**
    Rename property of the given class from `oldName` to `newName`.

    - parameter className: Class for which the property is to be renamed. Must be present
                           in both the old and new Realm schemas.
    - parameter oldName:   Old name for the property to be renamed. Must not be present
                           in the new Realm.
    - parameter newName:   New name for the property to be renamed. Must not be present
                           in the old Realm.
    */
    public func renameProperty(onType typeName: String, from oldName: String, to newName: String) {
        rlmMigration.renameProperty(forClass: typeName, oldName: oldName, newName: newName)
    }

    private init(_ rlmMigration: RLMMigration) {
        self.rlmMigration = rlmMigration
    }
}


// MARK: Private Helpers

internal func accessorMigrationBlock(_ migrationBlock: MigrationBlock) -> RLMMigrationBlock {
    return { migration, oldVersion in
        // set all accessor classes to MigrationObject
        for objectSchema in migration.oldSchema.objectSchema {
            objectSchema.accessorClass = MigrationObject.self
            // isSwiftClass is always `false` for object schema generated
            // from the table, but we need to pretend it's from a swift class
            // (even if it isn't) for the accessors to be initialized correctly.
            objectSchema.isSwiftClass = true
        }
        for objectSchema in migration.newSchema.objectSchema {
            objectSchema.accessorClass = MigrationObject.self
        }

        // run migration
        migrationBlock(migration: Migration(migration), oldSchemaVersion: oldVersion)
    }
}

// MARK: Unavailable

extension Migration {
    @available(*, unavailable, renamed:"enumerateObjects(ofType:_:)")
    public func enumerate(_ objectClassName: String, _ block: MigrationObjectEnumerateBlock) { }

    @available(*, unavailable, renamed:"createObject(ofType:populatedWith:)")
    public func create(_ className: String, value: AnyObject = [:]) -> MigrationObject {
        fatalError()
    }

    @available(*, unavailable, renamed:"deleteData(forType:)")
    public func deleteData(_ objectClassName: String) -> Bool {
        fatalError()
    }

    @available(*, unavailable, renamed: "renameProperty(onType:from:to:)")
    public func renamePropertyForClass(_ className: String, oldName: String, newName: String) { }
}

#else

/**
 The type of a migration block used to migrate a Realm.

 - parameter migration:  A `RLMMigration` object used to perform the migration. The
                         migration object allows you to enumerate and alter any
                         existing objects which require migration.

 - parameter oldSchemaVersion: The schema version of the Realm being migrated.
*/
public typealias MigrationBlock = (migration: Migration, oldSchemaVersion: UInt64) -> Void

/// An object class used during migrations.
public typealias MigrationObject = DynamicObject

/**
 A block type which provides both the old and new versions of an object in the Realm. Object
 properties can only be accessed using subscripting.

 - parameter oldObject: The object from the original Realm (read-only).
 - parameter newObject: The object from the migrated Realm (read-write).
*/
public typealias MigrationObjectEnumerateBlock = (oldObject: MigrationObject?, newObject: MigrationObject?) -> Void

/**
 Returns the schema version for a Realm at a given local URL.

 - parameter fileURL:       Local URL to a Realm file.
 - parameter encryptionKey: 64-byte key used to encrypt the file, or `nil` if it is unencrypted.

 - throws: An `NSError` that describes the problem.

 - returns: The version of the Realm at `fileURL`.
*/
public func schemaVersionAtURL(fileURL: NSURL, encryptionKey: NSData? = nil) throws -> UInt64 {
    var error: NSError?
    let version = RLMRealm.__schemaVersionAtURL(fileURL, encryptionKey: encryptionKey, error: &error)
    guard version != RLMNotVersioned else {
        throw error!
    }
    return version
}

/**
 Performs the given Realm configuration's migration block on a Realm at the given path.

 This method is called automatically when opening a Realm for the first time and does
 not need to be called explicitly. You can choose to call this method to control
 exactly when and how migrations are performed.

 - parameter configuration: The Realm configuration used to open and migrate the Realm.

 - returns: An `NSError` that describes an error that occurred while applying the migration, if any.
*/
public func migrateRealm(configuration: Realm.Configuration = Realm.Configuration.defaultConfiguration) -> NSError? {
    return RLMRealm.migrateRealm(configuration.rlmConfiguration)
}


/**
 `Migration` instances encapsulate information intended to facilitate a schema migration.

 A `Migration` instance is passed into a user-defined `MigrationBlock` block when updating
 the version of a Realm. This instance provides access to the old and new database schemas, the
 objects in the Realm, and provides functionality for modifying the Realm during the migration.
*/
public final class Migration {

    // MARK: Properties

    /// Returns the old schema, describing the Realm before applying a migration.
    public var oldSchema: Schema { return Schema(rlmMigration.oldSchema) }

    /// Returns the new schema, describing the Realm after applying a migration.
    public var newSchema: Schema { return Schema(rlmMigration.newSchema) }

    internal var rlmMigration: RLMMigration

    // MARK: Altering Objects During a Migration

    /**
     Enumerates all the objects of a given type in this Realm, providing both the old and new versions of
     each object. Object properties can be accessed using subscripting.

     - parameter objectClassName: The name of the `Object` class to enumerate.
     - parameter block:           The block providing both the old and new versions of an object in this Realm.
     */
    public func enumerate(objectClassName: String, _ block: MigrationObjectEnumerateBlock) {
        rlmMigration.enumerateObjects(objectClassName) {
            block(oldObject: unsafeBitCast($0, MigrationObject.self),
                  newObject: unsafeBitCast($1, MigrationObject.self))
        }
    }

    /**
     Creates and returns an `Object` of type `className` in the Realm being migrated.

     The `value` argument is used to populate the object. It can be a key-value coding compliant object, an array or
     dictionary returned from the methods in `NSJSONSerialization`, or an `Array` containing one element for each
     managed property. An exception will be thrown if any required properties are not present and those properties were
     not defined with default values.

     When passing in an `Array` as the `value` argument, all properties must be present, valid and in the same order as
     the properties defined in the model.

     - parameter className: The name of the `Object` class to create.
     - parameter value:     The value used to populate the created object.

     - returns: The newly created object.
     */
    public func create(className: String, value: AnyObject = [:]) -> MigrationObject {
        return unsafeBitCast(rlmMigration.createObject(className, withValue: value), MigrationObject.self)
    }

    /**
     Deletes an object from a Realm during a migration.

     It is permitted to call this method from within the block passed to `enumerate(_:block:)`.

     - parameter object: An object to be deleted from the Realm being migrated.
     */
    public func delete(object: MigrationObject) {
        RLMDeleteObjectFromRealm(object, RLMObjectBaseRealm(object))
    }

    /**
     Deletes the data for the class with the given name.

     All objects of the given class will be deleted. If the `Object` subclass no longer exists in your program, any
     remaining metadata for the class will be removed from the Realm file.

     - parameter objectClassName: The name of the `Object` class to delete.

     - returns: A Boolean value indicating whether there was any data to delete.
     */
    public func deleteData(objectClassName: String) -> Bool {
        return rlmMigration.deleteDataForClassName(objectClassName)
    }

    /**
     Renames a property of the given class from `oldName` to `newName`.

     - parameter className: The name of the class whose property should be renamed. This class must be present
                            in both the old and new Realm schemas.
     - parameter oldName:   The old name for the property to be renamed. There must not be a property with this name in
                            the class as defined by the new Realm schema.
     - parameter newName:   The new name for the property to be renamed. There must not be a property with this name in
                            the class as defined by the old Realm schema.
    */
    public func renamePropertyForClass(className: String, oldName: String, newName: String) {
        rlmMigration.renamePropertyForClass(className, oldName: oldName, newName: newName)
    }

    private init(_ rlmMigration: RLMMigration) {
        self.rlmMigration = rlmMigration
    }
}


// MARK: Private Helpers

internal func accessorMigrationBlock(migrationBlock: MigrationBlock) -> RLMMigrationBlock {
    return { migration, oldVersion in
        // set all accessor classes to MigrationObject
        for objectSchema in migration.oldSchema.objectSchema {
            objectSchema.accessorClass = MigrationObject.self
            // isSwiftClass is always `false` for object schema generated
            // from the table, but we need to pretend it's from a swift class
            // (even if it isn't) for the accessors to be initialized correctly.
            objectSchema.isSwiftClass = true
        }
        for objectSchema in migration.newSchema.objectSchema {
            objectSchema.accessorClass = MigrationObject.self
        }

        // run migration
        migrationBlock(migration: Migration(migration), oldSchemaVersion: oldVersion)
    }
}

#endif
