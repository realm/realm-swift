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
import Realm.Private

public typealias MigrationBlock = (migration: Migration, oldSchemaVersion: UInt) -> Void
public typealias MigrationObjectEnumerateBlock = (oldObject: MigrationObject, newObject: MigrationObject) -> Void

public func setDefaultRealmSchemaVersion(schemaVersion: UInt, migrationBlock: MigrationBlock) {
    RLMRealm.setDefaultRealmSchemaVersion(schemaVersion, withMigrationBlock: accessorMigrationBlock(migrationBlock))
}

public func setSchemaVersion(schemaVersion: UInt, realmPath: String, migrationBlock: MigrationBlock) {
    RLMRealm.setSchemaVersion(schemaVersion, forRealmAtPath: realmPath, withMigrationBlock: accessorMigrationBlock(migrationBlock))
}

public func migrateRealm(path: String) -> NSError? {
    return RLMRealm.migrateRealmAtPath(path)
}

public class Migration {
    public var oldSchema: Schema { return Schema(rlmSchema: rlmMigration.oldSchema) }
    public var newSchema: Schema { return Schema(rlmSchema: rlmMigration.newSchema) }

    public func enumerate(objectClassName: String, block: MigrationObjectEnumerateBlock) {
        rlmMigration.enumerateObjects(objectClassName, block: {
            block(oldObject: unsafeBitCast($0, MigrationObject.self), newObject: unsafeBitCast($1, MigrationObject.self));
        })
    }

    public func create(className: String, withObject object: AnyObject) -> MigrationObject {
        return unsafeBitCast(rlmMigration.createObject(className, withObject: object), MigrationObject.self)
    }

    public func delete(object: RLMObject) {
        rlmMigration.deleteObject(object)
    }

    private var rlmMigration: RLMMigration

    init(_ rlmMigration: RLMMigration) {
        self.rlmMigration = rlmMigration
    }
}

public class MigrationObject : Object {
    subscript(key: String) -> AnyObject? {
        if (self.objectSchema[key].type == RLMPropertyType.Array) {
            return listProperties[key]
        }
        return super[key]
    }

    public func initalizeListPropertyWithName(name: String, rlmArray: RLMArray) {
        listProperties[name] = List<Object>(rlmArray)
    }

    private var listProperties = [String: List<Object>]()
}

private func accessorMigrationBlock(migrationBlock: MigrationBlock) -> RLMMigrationBlock {
    return { migration, oldVersion in
        for objectSchema in migration.oldSchema.objectSchema {
            (objectSchema as RLMObjectSchema).accessorClass = MigrationObject.self
        }

        // copy old schema and reset after enumeration
        let savedSchema = migration.newSchema.copy() as RLMSchema
        for objectSchema in migration.newSchema.objectSchema {
            (objectSchema as RLMObjectSchema).accessorClass = MigrationObject.self
        }

        // run migration
        migrationBlock(migration: Migration(migration), oldSchemaVersion: oldVersion)

        // reset old schema
        migration.realm.schema = savedSchema
    }
}


