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

/**
Migration block used to migrate a Realm.

:param: migration        `Migration` object used to perform the migration. The
                         migration object allows you to enumerate and alter any
                         existing objects which require migration.
:param: oldSchemaVersion The schema version of the `Realm` being migrated.
*/
public typealias MigrationBlock = (migration: Migration, oldSchemaVersion: UInt64) -> Void

/// Object class used during migrations
public typealias MigrationObject = DynamicObject

/**
Provides both the old and new versions of an object in this Realm. Objects properties can only be
accessed using subscripting.

:param: oldObject Object in original `Realm` (read-only)
:param: newObject Object in migrated `Realm` (read-write)
*/
public typealias MigrationObjectEnumerateBlock = (oldObject: MigrationObject?, newObject: MigrationObject?) -> Void

/**
Specify a schema version and an associated migration block which is applied when
opening the default Realm with an old schema version.

Before you can open an existing `Realm` which has a different on-disk schema
from the schema defined in your object interfaces, you must provide a migration
block which converts from the disk schema to your current object schema. At the
minimum your migration block must initialize any properties which were added to
existing objects without defaults and ensure uniqueness if a primary key
property is added to an existing object.

You should call this method before accessing any `Realm` instances which
require migration. After registering your migration block, Realm will call your
block automatically as needed.

:warning: Unsuccessful migrations will throw exceptions when the migration block is applied.
          This will happen in the following cases:

          - The given `schemaVersion` is lower than the target Realm's current schema version.
          - A new property without a default was added to an object and not initialized
            during the migration. You are required to either supply a default value or to
            manually populate added properties during a migration.

:param: version The current schema version.
:param: block   The block which migrates the Realm to the current version.
*/
public func setDefaultRealmSchemaVersion(schemaVersion: UInt64, migrationBlock: MigrationBlock) {
    RLMRealm.setDefaultRealmSchemaVersion(schemaVersion, withMigrationBlock: accessorMigrationBlock(migrationBlock))
}

/**
Specify a schema version and an associated migration block which is applied when
opening a Realm at the specified path with an old schema version.

Before you can open an existing `Realm` which has a different on-disk schema
from the schema defined in your object interfaces, you must provide a migration
block which converts from the disk schema to your current object schema. At the
minimum your migration block must initialize any properties which were added to
existing objects without defaults and ensure uniqueness if a primary key
property is added to an existing object.

You should call this method before accessing any `Realm` instances which
require migration. After registering your migration block, Realm will call your
block automatically as needed.

:param: version   The current schema version.
:param: realmPath The path of the Realms to migrate.
:param: block     The block which migrates the Realm to the current version.
*/
public func setSchemaVersion(schemaVersion: UInt64, realmPath: String, migrationBlock: MigrationBlock) {
    RLMRealm.setSchemaVersion(schemaVersion, forRealmAtPath: realmPath, withMigrationBlock: accessorMigrationBlock(migrationBlock))
}

/**
Get the schema version for a Realm at a given path.
:param: realmPath     Path to a Realm file.
:param: encryptionKey Optional 64-byte encryption key for encrypted Realms.
:param: error         If an error occurs, upon return contains an `NSError` object
                      that describes the problem. If you are not interested in
                      possible errors, omit the argument, or pass in `nil`.
:returns: The version of the Realm at `realmPath` or `nil` if the version cannot be read.
*/
public func schemaVersionAtPath(realmPath: String, encryptionKey: NSData? = nil, error: NSErrorPointer = nil) -> UInt64? {
    let version = RLMRealm.schemaVersionAtPath(realmPath, encryptionKey: encryptionKey, error: error)
    if version == RLMNotVersioned {
        return nil
    }
    return version
}

/**
Performs the registered migration block on a Realm at the given path.

This method is called automatically when opening a Realm for the first time and does
not need to be called explicitly. You can choose to call this method to control
exactly when and how migrations are performed.

:param: path          The path of the Realm to migrate.
:param: encryptionKey Optional 64-byte encryption key for encrypted Realms.
                      If the Realms at the given path are not encrypted, omit the argument or pass
                      in `nil`.

:returns: `nil` if the migration was successful, or an `NSError` object that describes the problem
          that occured otherwise.
*/
public func migrateRealm(path: String, encryptionKey: NSData? = nil) -> NSError? {
    if let encryptionKey = encryptionKey {
        return RLMRealm.migrateRealmAtPath(path, encryptionKey: encryptionKey)
    } else {
        return RLMRealm.migrateRealmAtPath(path)
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

    private var rlmMigration: RLMMigration

    // MARK: Altering Objects During a Migration

    /**
    Enumerates objects of a given type in this Realm, providing both the old and new versions of
    each object. Object properties can be accessed using subscripting.
    
    :param: className The name of the `Object` class to enumerate.
    :param: block     The block providing both the old and new versions of an object in this Realm.
    */
    public func enumerate(objectClassName: String, _ block: MigrationObjectEnumerateBlock) {
        rlmMigration.enumerateObjects(objectClassName) {
            block(oldObject: unsafeBitCast($0, MigrationObject.self), newObject: unsafeBitCast($1, MigrationObject.self))
        }
    }

    /**
    Create an `Object` of type `className` in the Realm being migrated.

    :param: className The name of the `Object` class to create.
    :param: object    The object used to populate the object. This can be any key/value coding
                      compliant object, or a JSON object such as those returned from the methods in
                      `NSJSONSerialization`, or an `Array` with one object for each persisted
                      property. An exception will be thrown if any required properties are not
                      present and no default is set.
    
    :returns: The created object.
    */
    public func create(className: String, value: AnyObject = [:]) -> MigrationObject {
        return unsafeBitCast(rlmMigration.createObject(className, withValue: value), MigrationObject.self)
    }

    /**
    Delete an object from a Realm during a migration. This can be called within
    `enumerate(_:block:)`.

    :param: object Object to be deleted from the Realm being migrated.
    */
    public func delete(object: MigrationObject) {
        RLMDeleteObjectFromRealm(object, RLMObjectBaseRealm(object))
    }

    /**
    Deletes the data for the class with the given name.
    This deletes all objects of the given class, and if the Object subclass no longer exists in your program,
    cleans up any remaining metadata for the class in the Realm file.

    :param:   name The name of the Object class to delete.

    :returns: whether there was any data to delete.
    */
    public func deleteData(objectClassName: String) -> Bool {
        return rlmMigration.deleteDataForClassName(objectClassName)
    }

    private init(_ rlmMigration: RLMMigration) {
        self.rlmMigration = rlmMigration
    }
}


// MARK: Private Helpers

private func accessorMigrationBlock(migrationBlock: MigrationBlock) -> RLMMigrationBlock {
    return { migration, oldVersion in
        // set all accessor classes to MigrationObject
        for objectSchema in migration.oldSchema.objectSchema {
            if let objectSchema = objectSchema as? RLMObjectSchema {
                objectSchema.accessorClass = MigrationObject.self
                // isSwiftClass is always `false` for object schema generated
                // from the table, but we need to pretend it's from a swift class
                // (even if it isn't) for the accessors to be initialized correctly.
                objectSchema.isSwiftClass = true
            }
        }
        for objectSchema in migration.newSchema.objectSchema {
            if let objectSchema = objectSchema as? RLMObjectSchema {
                objectSchema.accessorClass = MigrationObject.self
            }
        }

        // run migration
        migrationBlock(migration: Migration(migration), oldSchemaVersion: oldVersion)
    }
}
