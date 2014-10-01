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

// MARK: Migration Block

public typealias MigrationBlock = (migration: Migration, oldSchemaVersion: UInt) -> UInt

func rlmMigrationBlockFromMigrationBlock(migrationBlock: MigrationBlock) -> RLMMigrationBlock {
    return { rlmMigration, oldSchemaVersion in
        return migrationBlock(migration: Migration(rlmMigration: rlmMigration), oldSchemaVersion: oldSchemaVersion)
    }
}

public class Migration {
    // MARK: Properties

    var rlmMigration: RLMMigration
    public var oldSchema: Schema { return Schema(rlmSchema: rlmMigration.oldSchema) }
    public var newSchema: Schema { return Schema(rlmSchema: rlmMigration.newSchema) }

    // MARK: Initializers

    init(rlmMigration: RLMMigration) {
        self.rlmMigration = rlmMigration
    }

    // MARK: Enumerate

    public func enumerate(objectClassName: String, block: ObjectMigrationBlock) {
        rlmMigration.enumerateObjects(objectClassName, block: block)
    }
}
