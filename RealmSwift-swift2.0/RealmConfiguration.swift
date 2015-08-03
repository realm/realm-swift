////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
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
A `RealmConfiguration` is used to describe the different options used to 
create a `Realm` instance.
*/
public struct RealmConfiguration {

    // MARK: Default Configuration

    /// Returns the default Realm Configuration.
    public static var defaultConfiguration: RealmConfiguration {
        get {
            return fromRLMConfiguration(RLMConfiguration.defaultConfiguration())
        }
        set {
            RLMConfiguration.setDefaultConfiguration(newValue.rlmConfiguration)
        }
    }

    // MARK: Configuration Properties

    /// The path to the realm file.
    public var path: String? = Realm.defaultPath

    /// A string used to identify a particular in-memory Realm.
    public var inMemoryIdentifier: String? = nil

    /// 64-byte key to use to encrypt the data.
    public var encryptionKey: NSData? = nil

    /// Whether the Realm is read-only (must be used for read-only files).
    public var readOnly: Bool = false

    /// The current schema version.
    public var schemaVersion: UInt64 = 0

    /// The block which migrates the Realm to the current version.
    public var migrationBlock: MigrationBlock? = nil

    // MARK: Private Methods

    internal var rlmConfiguration: RLMConfiguration {
        let configuration = RLMConfiguration()
        configuration.path = self.path
        configuration.inMemoryIdentifier = self.inMemoryIdentifier
        configuration.encryptionKey = self.encryptionKey
        configuration.readOnly = self.readOnly
        configuration.schemaVersion = UInt(self.schemaVersion)
        configuration.migrationBlock = self.migrationBlock.map { accessorMigrationBlock($0) }
        return configuration
    }

    private static func fromRLMConfiguration(rlmConfiguration: RLMConfiguration) -> RealmConfiguration {
        var configuration = RealmConfiguration()
        configuration.path = rlmConfiguration.path
        configuration.inMemoryIdentifier = rlmConfiguration.inMemoryIdentifier
        configuration.encryptionKey = rlmConfiguration.encryptionKey
        configuration.readOnly = rlmConfiguration.readOnly
        configuration.schemaVersion = UInt64(rlmConfiguration.schemaVersion)
        if let rlmMigrationBlock = rlmConfiguration.migrationBlock {
            configuration.migrationBlock = { migration, schemaVersion in
                rlmMigrationBlock(migration.rlmMigration, schemaVersion)
            }
        }
        return configuration
    }
}

// MARK: CustomStringConvertible

extension RealmConfiguration: CustomStringConvertible {
    /// Returns a human-readable description of the configuration.
    public var description: String {
        return gsub("\\ARLMConfiguration", template: "RealmConfiguration", string: rlmConfiguration.description) ?? ""
    }
}
