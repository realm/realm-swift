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
    A `Realm.Configuration` is used to describe the different options used to
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

        /// Returns the default Realm.Configuration used to create Realms when no other
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
        Initializes a `Realm.Configuration`, suitable for creating new `Realm` instances.

        - parameter path:               The path to the realm file.
        - parameter inMemoryIdentifier: A string used to identify a particular in-memory Realm.
        - parameter encryptionKey:      64-byte key to use to encrypt the data.
        - parameter readOnly:           Whether the Realm is read-only (must be true for read-only files).
        - parameter schemaVersion:      The current schema version.
        - parameter migrationBlock:     The block which migrates the Realm to the current version.
        - parameter objectTypes:        The subset of `Object` subclasses persisted in the Realm.
        */
        @available(*, deprecated=1, message="Use init(fileURL:...)")
        public init(path: String?,
                    inMemoryIdentifier: String? = nil,
                    encryptionKey: NSData? = nil,
                    readOnly: Bool = false,
                    schemaVersion: UInt64 = 0,
                    migrationBlock: MigrationBlock? = nil,
                    objectTypes: [Object.Type]? = nil) {
            self.fileURL = path.map(NSURL.init(fileURLWithPath:))
            if inMemoryIdentifier != nil {
                self.inMemoryIdentifier = inMemoryIdentifier
            }
            self.encryptionKey = encryptionKey
            self.readOnly = readOnly
            self.schemaVersion = schemaVersion
            self.migrationBlock = migrationBlock
            self.objectTypes = objectTypes
        }

        /**
        Initializes a `Realm.Configuration`, suitable for creating new `Realm` instances.

        - parameter fileURL:            The local URL to the realm file.
        - parameter inMemoryIdentifier: A string used to identify a particular in-memory Realm.
        - parameter encryptionKey:      64-byte key to use to encrypt the data.
        - parameter readOnly:           Whether the Realm is read-only (must be true for read-only files).
        - parameter schemaVersion:      The current schema version.
        - parameter migrationBlock:     The block which migrates the Realm to the current version.
        - parameter objectTypes:        The subset of `Object` subclasses persisted in the Realm.
        */
        public init(fileURL: NSURL? = NSURL(fileURLWithPath: RLMRealmPathForFile("default.realm"), isDirectory: false),
            inMemoryIdentifier: String? = nil,
            encryptionKey: NSData? = nil,
            readOnly: Bool = false,
            schemaVersion: UInt64 = 0,
            migrationBlock: MigrationBlock? = nil,
            objectTypes: [Object.Type]? = nil) {
                self.fileURL = fileURL
                if inMemoryIdentifier != nil {
                    self.inMemoryIdentifier = inMemoryIdentifier
                }
                self.encryptionKey = encryptionKey
                self.readOnly = readOnly
                self.schemaVersion = schemaVersion
                self.migrationBlock = migrationBlock
                self.objectTypes = objectTypes
        }

        // MARK: Configuration Properties

        /// The local URL to the realm file.
        /// Mutually exclusive with `inMemoryIdentifier`.
        public var fileURL: NSURL? {
            set {
                _inMemoryIdentifier = nil
                _path = newValue?.path
            }
            get {
                return _path.map(NSURL.init(fileURLWithPath:))
            }
        }

        /// The path to the realm file.
        /// Mutually exclusive with `inMemoryIdentifier`.
        @available(*, deprecated=1, message="Use fileURL")
        public var path: String? {
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
        public var inMemoryIdentifier: String? {
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
                self.customSchema = newValue.map { RLMSchema(objectClasses: $0) }
            }
            get {
                return self.customSchema.map { $0.objectSchema.map { $0.objectClass as! Object.Type } }
            }
        }

        /// A custom schema to use for the Realm.
        private var customSchema: RLMSchema? = nil

        /// Allows to disable automatic format upgrades when accessing the Realm.
        internal var disableFormatUpgrade: Bool = false

        // MARK: Private Methods

        internal var rlmConfiguration: RLMRealmConfiguration {
            let configuration = RLMRealmConfiguration()
            if fileURL != nil {
                configuration.fileURL = self.fileURL
            } else if inMemoryIdentifier != nil {
                configuration.inMemoryIdentifier = self.inMemoryIdentifier
            } else {
                fatalError("A Realm Configuration must specify a path or an in-memory identifier.")
            }
            configuration.encryptionKey = self.encryptionKey
            configuration.readOnly = self.readOnly
            configuration.schemaVersion = self.schemaVersion
            configuration.migrationBlock = self.migrationBlock.map { accessorMigrationBlock($0) }
            configuration.customSchema = self.customSchema
            configuration.disableFormatUpgrade = self.disableFormatUpgrade
            return configuration
        }

        internal static func fromRLMRealmConfiguration(rlmConfiguration: RLMRealmConfiguration) -> Configuration {
            var configuration = Configuration()
            configuration._path = rlmConfiguration.fileURL?.path
            configuration._inMemoryIdentifier = rlmConfiguration.inMemoryIdentifier
            configuration.encryptionKey = rlmConfiguration.encryptionKey
            configuration.readOnly = rlmConfiguration.readOnly
            configuration.schemaVersion = rlmConfiguration.schemaVersion
            configuration.migrationBlock = rlmConfiguration.migrationBlock.map { rlmMigration in
                return { migration, schemaVersion in
                    rlmMigration(migration.rlmMigration, schemaVersion)
                }
            }
            configuration.customSchema = rlmConfiguration.customSchema
            configuration.disableFormatUpgrade = rlmConfiguration.disableFormatUpgrade
            return configuration
        }
    }
}

// MARK: CustomStringConvertible

extension Realm.Configuration: CustomStringConvertible {
    /// Returns a human-readable description of the configuration.
    public var description: String {
        return gsub("\\ARLMRealmConfiguration",
                    template: "Realm.Configuration",
                    string: rlmConfiguration.description) ?? ""
    }
}
