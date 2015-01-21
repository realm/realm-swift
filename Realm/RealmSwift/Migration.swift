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
public typealias MigrationObjectEnumerateBlock = (oldObject: RLMObjectBase!, newObject: RLMObjectBase!) -> Void

public func setDefaultRealmSchemaVersion(schemaVersion: UInt, migrationBlock: MigrationBlock) {
    RLMRealm.setDefaultRealmSchemaVersion(schemaVersion, withMigrationBlock: {
        migrationBlock(migration: Migration($0), oldSchemaVersion: $1)
    })
}
public func setSchemaVersion(schemaVersion: UInt, realmPath: String, migrationBlock: MigrationBlock) {
    RLMRealm.setSchemaVersion(schemaVersion, forRealmAtPath: realmPath, withMigrationBlock: {
        migrationBlock(migration: Migration($0), oldSchemaVersion: $1)
    })
}

public func migrateRealm(path: String) -> NSError? {
    return RLMRealm.migrateRealmAtPath(path)
}

public class Migration {
    public var oldSchema: Schema { return Schema(rlmSchema: rlmMigration.oldSchema) }
    public var newSchema: Schema { return Schema(rlmSchema: rlmMigration.newSchema) }

    public func enumerate(objectClassName: String, block: MigrationObjectEnumerateBlock) {
        rlmMigration.enumerateBaseObjects(objectClassName, dynamicAccessorClass: MigrationObject.self, block: block)
    }

    public func create(className: String, withObject object: AnyObject) -> RLMObject {
        return rlmMigration.createObject(className, withObject: object)
    }

    public func delete(object: RLMObject) {
        rlmMigration.deleteObject(object)
    }

    private var rlmMigration: RLMMigration

    init(_ rlmMigration: RLMMigration) {
        self.rlmMigration = rlmMigration
    }
}

@objc(MigrationObject)
public class MigrationObject : Object {
    subscript(key: String) -> AnyObject? {
        if (self.objectSchema[key].type == RLMPropertyType.Array) {
            return listProperties[key]
        }
        return super[key]
    }

    private func initalizeListProperty(name: String, rlmArray: RLMArray) {
        var list = List<Object>()
        list._rlmArray = rlmArray
        listProperties[name] = list
    }

    private var listProperties = [String: List<Object>]()
}

