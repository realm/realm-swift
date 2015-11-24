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

extension Realm {
    /**
    A `Configuration` is used to describe the different options used to
    create a `Realm` instance.

    `Realm.Configuration` instances are just plain Swift structs, and unlike
    `Realm` and `Object`s can be freely shared between threads. Creating
    configuration objects for class subsets (by setting the `objectTypes`
    property) can be expensive, and so you will normally want to cache and reuse
    a single configuration object for each distinct configuration that you are
    using rather than creating a new one each time you open a `Realm`.
    */
    public struct Configuration {

        // MARK: Default Configuration

        /// Returns the default Configuration used to create Realms when no other
        /// configuration is explicitly specified (i.e. `Realm()`).
        public static var defaultConfiguration: Configuration {
            get {
                return fromRLMRealmConfiguration(RLMRealmConfiguration.defaultConfiguration())
            }
            set {
                RLMRealmConfiguration.setDefaultConfiguration(newValue.rlmConfiguration)
            }
        }

        // MARK: Initialization

        /**
        Initializes a `Configuration`, suitable for creating new `Realm` instances.

        :param: path               The path to the realm file.
        :param: inMemoryIdentifier A string used to identify a particular in-memory Realm.
        :param: encryptionKey      64-byte key to use to encrypt the data.
        :param: readOnly           Whether the Realm is read-only (must be true for read-only files).
        :param: schemaVersion      The current schema version.
        :param: migrationBlock     The block which migrates the Realm to the current version.
        :param: objectTypes        The subset of `Object` subclasses persisted in the Realm.
        :param: syncServerURL      The synchronization server URL.
        :param: syncIdentity       The user identity token used for synchronization.

        :returns: An initialized `Configuration`.
        */
        public init(path: String? = RLMRealmPathForFile("default.realm"),
            inMemoryIdentifier: String? = nil,
            encryptionKey: NSData? = nil,
            readOnly: Bool = false,
            schemaVersion: UInt64 = 0,
            migrationBlock: MigrationBlock? = nil,
            objectTypes: [Object.Type]? = nil,
            syncServerURL: NSURL? = nil,
            syncIdentity: String? = nil) {
                self.path = path
                if inMemoryIdentifier != nil {
                    self.inMemoryIdentifier = inMemoryIdentifier
                }
                self.encryptionKey = encryptionKey
                self.readOnly = readOnly
                self.schemaVersion = schemaVersion
                self.migrationBlock = migrationBlock
                self.objectTypes = objectTypes
                self.syncServerURL = syncServerURL
                self.syncIdentity = syncIdentity
        }

        // MARK: Configuration Properties

        /// The path to the realm file.
        /// Mutually exclusive with `inMemoryIdentifier`.
        public var path: String?  {
            set {
                _inMemoryIdentifier = nil
                _path = newValue
            }
            get {
                return _path
            }
        }

        private var _path: String?

        /// A string used to identify a particular in-memory Realm.
        /// Mutually exclusive with `path`.
        public var inMemoryIdentifier: String?  {
            set {
                _path = nil
                _inMemoryIdentifier = newValue
            }
            get {
                return _inMemoryIdentifier
            }
        }

        private var _inMemoryIdentifier: String? = nil

        /// 64-byte key to use to encrypt the data.
        public var encryptionKey: NSData? = nil

        /// Whether the Realm is read-only (must be true for read-only files).
        public var readOnly: Bool = false

        /// The current schema version.
        public var schemaVersion: UInt64 = 0

        /// The block which migrates the Realm to the current version.
        public var migrationBlock: MigrationBlock? = nil

        /// The classes persisted in the Realm.
        public var objectTypes: [Object.Type]? {
            set {
                if let types = newValue {
                    let classes = NSMutableArray() // This is necessary to due bridging bugs fixed in 2.0
                    for cls in types {
                        classes.addObject(cls)
                    }
                    self.customSchema = RLMSchema(objectClasses: classes as [AnyObject])
                } else {
                    self.customSchema = nil
                }
            }
            get {
                return self.customSchema.map { $0.objectSchema.map { $0.objectClass as! Object.Type } }
            }
        }

        // MARK: Synchronization

        /**
        The synchronization server URL.

        The URL must be of the form `realm://realm.foo.com:7800/my_realm`, where
        `my_realm` is the name of the Realm as known to the server.

        When `nil`, synchronization is disabled. Defaults to `nil`.
        */
        public var syncServerURL: NSURL? = nil

        /**
        The user identity token used for synchronization.
        Must be a 40-byte alphanumeric string (such as a hex SHA1 hash).
        */
        public var syncIdentity: String? = nil

        /// A custom schema to use for the Realm.
        private var customSchema: RLMSchema? = nil

        // MARK: Private Methods

        internal var rlmConfiguration: RLMRealmConfiguration {
            let configuration = RLMRealmConfiguration()
            if self.path != nil {
                configuration.path = self.path
            } else {
                configuration.inMemoryIdentifier = self.inMemoryIdentifier
            }
            configuration.encryptionKey = self.encryptionKey
            configuration.readOnly = self.readOnly
            configuration.schemaVersion = self.schemaVersion
            configuration.migrationBlock = self.migrationBlock.map { accessorMigrationBlock($0) }
            configuration.customSchema = self.customSchema
            configuration.syncServerURL = self.syncServerURL
            configuration.syncIdentity = self.syncIdentity
            return configuration
        }

        internal static func fromRLMRealmConfiguration(rlmConfiguration: RLMRealmConfiguration) -> Configuration {
            var configuration = Configuration(path: rlmConfiguration.path,
                inMemoryIdentifier: rlmConfiguration.inMemoryIdentifier,
                encryptionKey: rlmConfiguration.encryptionKey,
                readOnly: rlmConfiguration.readOnly,
                schemaVersion: UInt64(rlmConfiguration.schemaVersion),
                migrationBlock: map(rlmConfiguration.migrationBlock) { rlmMigration in
                    return { migration, schemaVersion in
                        rlmMigration(migration.rlmMigration, schemaVersion)
                    }
                }
            )
            configuration.customSchema = rlmConfiguration.customSchema
            configuration.syncServerURL = rlmConfiguration.syncServerURL
            configuration.syncIdentity = rlmConfiguration.syncIdentity
            return configuration
        }
    }
}

// MARK: Printable

extension Realm.Configuration: Printable {
    /// Returns a human-readable description of the configuration.
    public var description: String {
        return gsub("\\ARLMRealmConfiguration", "Configuration", rlmConfiguration.description) ?? ""
    }
}
