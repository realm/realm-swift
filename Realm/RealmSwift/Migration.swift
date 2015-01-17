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

import Realm

/// A block that is used to migrate objects from one version of a Realm to a newer version.
public typealias MigrationBlock = (migration: Migration, oldSchemaVersion: UInt) -> Void

/**
Specify a schema version and an associated migration block which is applied when
opening the default Realm with an old schema version.

Before you can open an existing `Realm` which has a different on-disk schema
from the schema defined in your object interfaces you must provide a migration
block which converts from the disk schema to your current object schema. At the
minimum your migration block must initialize any properties which were added to
existing objects without defaults and ensure uniqueness if a primary key
property is added to an existing object.

You should call this method before accessing any `Realm` instances which
require migration. After registering your migration block Realm will call your
block automatically as needed.

:warning: Unsuccessful migrations will throw exceptions when the migration block
          is applied. This will happen in the following cases:
    - The migration block was run and returns a schema version which is not higher
      than the previous schema version.
    - A new property without a default was added to an object and not initialized
      during the migration. You are required to either supply a default value or to
      manually populate added properties during a migration.

:param: schemaVersion  The current schema version.
:param: migrationBlock The block which migrates the Realm to the current version.
*/
public func setDefaultRealmSchemaVersion(schemaVersion: UInt, migrationBlock: MigrationBlock) {
    RLMRealm.setDefaultRealmSchemaVersion(schemaVersion, withMigrationBlock: {
        migrationBlock(migration: Migration($0), oldSchemaVersion: $1)
    })
}

/**
Specify a schema version and an associated migration block which is applied when
opening the Realm at the given path with an old schema version.

Before you can open an existing `Realm` which has a different on-disk schema
from the schema defined in your object interfaces you must provide a migration
block which converts from the disk schema to your current object schema. At the
minimum your migration block must initialize any properties which were added to
existing objects without defaults and ensure uniqueness if a primary key
property is added to an existing object.

You should call this method before accessing any `Realm` instances which
require migration. After registering your migration block Realm will call your
block automatically as needed.

:warning: Unsuccessful migrations will throw exceptions when the migration block
is applied. This will happen in the following cases:
    - The migration block was run and returns a schema version which is not higher
    than the previous schema version.
    - A new property without a default was added to an object and not initialized
    during the migration. You are required to either supply a default value or to
    manually populate added properties during a migration.

:param: schemaVersion  The current schema version.
:param: realmPath      The path of the realm whose schema version is being changed.
:param: migrationBlock The block which migrates the Realm to the current version.
*/
public func setSchemaVersion(schemaVersion: UInt, realmPath: String, migrationBlock: MigrationBlock) {
    RLMRealm.setSchemaVersion(schemaVersion, forRealmAtPath: realmPath, withMigrationBlock: {
        migrationBlock(migration: Migration($0), oldSchemaVersion: $1)
    })
}

/**
Performs the registered migration block on the Realm at the given path.

This method is called automatically when opening a Realm for the first time and does
not need to be called explicitly. You can choose to call this method to control
exactly when and how migrations are performed.

:see: setSchemaVersion(_:_:)

:param: path The path of the Realm to migrate.

:returns: The error that occurred while applying the migration, if any.
*/
public func migrateRealm(path: String) -> NSError? {
    return RLMRealm.migrateRealmAtPath(path)
}

/**
Migration encapsulates the information passed into a MigrationBlock when updating the schema version of a Realm instance.
*/
public class Migration {
    // MARK: Properties

    /// The schema that describes the Realm before the migration is applied.
    public var oldSchema: Schema { return Schema(rlmSchema: rlmMigration.oldSchema) }

    /// The schema that describes the Realm after applying the migration.
    public var newSchema: Schema { return Schema(rlmSchema: rlmMigration.newSchema) }

    // MARK: Altering objects

    /**
    Enumerates objects of the given type, providing both the old and new versions of each object.
    Object properties can be accessed using subscripting.

    :param: objectClassName The name of the `Object` subclass to enumerate.
    :param: block           The block which is yielded the old and new version of each object.
    */
    public func enumerate(objectClassName: String, block: ObjectMigrationBlock) {
        rlmMigration.enumerateObjects(objectClassName, block: block)
    }

    /**
    Create an Object of type `className` in the Realm being migrated.

    :param: className The name of the `Object` subclass to create.
    :param: object    The value used to populate the created object. This can be any key/value coding compliant
                      object, or a JSON object such as those returned from the methods in NSJSONSerialization, or
                      an NSArray with one object for each persisted property. An exception will be
                      thrown if any required properties are not present and no default is set.

                      When passing in an NSArray, all properties must be present, valid and in the same order as the properties defined in the model.

    :returns: The created Object.
    */
    public func create(className: String, withObject object: AnyObject) -> RLMObject {
        // FIXME: This should return Object
        return rlmMigration.createObject(className, withObject: object)
    }

    /**
    Delete the given object from a Realm during a migration.
    This can be called within `enumerate(_:_:)`.

    :param: object The object to be deleted from the Realm being migrated.
    */
    public func delete(object: RLMObject) {
        // FIXME: This should take Object
        rlmMigration.deleteObject(object)
    }

    private var rlmMigration: RLMMigration

    init(_ rlmMigration: RLMMigration) {
        self.rlmMigration = rlmMigration
    }
}
