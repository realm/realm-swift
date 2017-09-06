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
     An enum that describes the different kinds of Realms that can be created.
     */
    public enum Kind: Equatable {
        /**
         Describes a non-synchronized Realm backed by a file saved to disk. The URL
         is the local filesystem URL to the Realm file.
         */
        case file(URL)
        /**
         Describes a non-synchronized Realm backed by memory. The string is used to
         identify the Realm.
         */
        case inMemory(String)
        /**
         Describes a synchronized Realm. The sync configuration is used to specify
         additional configuration details.
         
         - see: `SyncConfiguration`
         */
        case synced(SyncConfiguration)

        /// :nodoc:
        public static func == (lhs: Kind, rhs: Kind) -> Bool {
            switch (lhs, rhs) {
            case let (.file(lhsURL), .file(rhsURL)):
                return lhsURL == rhsURL
            case let (.inMemory(lhsIdentifier), .inMemory(rhsIdentifier)):
                return lhsIdentifier == rhsIdentifier
            case let (.synced(lhsSyncConfig), .synced(rhsSyncConfig)):
                return lhsSyncConfig == rhsSyncConfig
            default:
                return false
            }
        }
    }

    /**
     A `Configuration` instance describes the different options used to create an instance of a Realm.

     `Configuration` instances are just plain Swift structs. Unlike `Realm`s and `Object`s, they can be freely shared
     between threads as long as you do not mutate them.

     Creating configuration values for class subsets (by setting the `objectClasses` property) can be expensive. Because
     of this, you will normally want to cache and reuse a single configuration value for each distinct configuration
     rather than creating a new value each time you open a Realm.
     */
    public struct Configuration {

        // MARK: Default Configuration

        /**
         The default `Configuration` used to create Realms when no configuration is explicitly specified (i.e.
         `Realm()`)
         */
        public static var defaultConfiguration: Configuration {
            get {
                return fromRLMRealmConfiguration(RLMRealmConfiguration.default())
            }
            set {
                RLMRealmConfiguration.setDefault(newValue.rlmConfiguration)
            }
        }

        // MARK: Initialization

        /**
         Creates a `Configuration` which can be used to create new `Realm` instances.

         - parameter kind:               The kind of Realm this configuration specifies. Defaults to a file-backed
                                         Realm stored at the default Realm file path.
         - parameter encryptionKey:      An optional 64-byte key to use to encrypt the data.
         - parameter readOnly:           Whether the Realm is read-only (must be true for read-only files).
         - parameter schemaVersion:      The current schema version.
         - parameter migrationBlock:     The block which migrates the Realm to the current version.
         - parameter deleteRealmIfMigrationNeeded: If `true`, recreate the Realm file with the provided
                                                   schema if a migration is required.
         - parameter shouldCompactOnLaunch: A block called when opening a Realm for the first time during the
                                            life of a process to determine if it should be compacted before being
                                            returned to the user. It is passed the total file size (data + free space)
                                            and the total bytes used by data in the file.

                                            Return `true ` to indicate that an attempt to compact the file should be made.
                                            The compaction will be skipped if another process is accessing it.
         - parameter objectTypes:        The subset of `Object` subclasses persisted in the Realm.

         - see: `Realm.Kind`
        */
        public init(kind: Kind = .file(URL(fileURLWithPath: RLMRealmPathForFile("default.realm"), isDirectory: false)),
                    encryptionKey: Data? = nil,
                    readOnly: Bool = false,
                    schemaVersion: UInt64 = 0,
                    migrationBlock: MigrationBlock? = nil,
                    deleteRealmIfMigrationNeeded: Bool = false,
                    shouldCompactOnLaunch: ((Int, Int) -> Bool)? = nil,
                    objectTypes: [Object.Type]? = nil) {
            self.kind = kind
            self.encryptionKey = encryptionKey
            self.readOnly = readOnly
            self.schemaVersion = schemaVersion
            self.migrationBlock = migrationBlock
            self.deleteRealmIfMigrationNeeded = deleteRealmIfMigrationNeeded
            self.shouldCompactOnLaunch = shouldCompactOnLaunch
            self.objectTypes = objectTypes
        }

        // MARK: Configuration Properties

        /**
         The kind of Realm this configuration value describes.
         
         - see: `Realm.Kind`
         */
        public var kind: Kind

        /// A 64-byte key to use to encrypt the data, or `nil` if encryption is not enabled.
        public var encryptionKey: Data?

        /**
         Whether to open the Realm in read-only mode.

         This is required to be able to open Realm files which are not writeable or are in a directory which is not
         writeable. This should only be used on files which will not be modified by anyone while they are open, and not
         just to get a read-only view of a file which may be written to by another thread or process. Opening in
         read-only mode requires disabling Realm's reader/writer coordination, so committing a write transaction from
         another process will result in crashes.
         */
        public var readOnly: Bool = false

        /// The current schema version.
        public var schemaVersion: UInt64 = 0

        /// The block which migrates the Realm to the current version.
        public var migrationBlock: MigrationBlock?

        /**
         Whether to recreate the Realm file with the provided schema if a migration is required. This is the case when
         the stored schema differs from the provided schema or the stored schema version differs from the version on
         this configuration. Setting this property to `true` deletes the file if a migration would otherwise be required
         or executed.

         - note: Setting this property to `true` doesn't disable file format migrations.
         */
        public var deleteRealmIfMigrationNeeded: Bool = false

        /**
         A block called when opening a Realm for the first time during the
         life of a process to determine if it should be compacted before being
         returned to the user. It is passed the total file size (data + free space)
         and the total bytes used by data in the file.

         Return `true ` to indicate that an attempt to compact the file should be made.
         The compaction will be skipped if another process is accessing it.
         */
        public var shouldCompactOnLaunch: ((Int, Int) -> Bool)?

        /// The classes managed by the Realm.
        public var objectTypes: [Object.Type]? {
            set {
                self.customSchema = newValue.map { RLMSchema(objectClasses: $0) }
            }
            get {
                return self.customSchema.map { $0.objectSchema.map { $0.objectClass as! Object.Type } }
            }
        }

        /// A custom schema to use for the Realm.
        private var customSchema: RLMSchema?

        /// If `true`, disables automatic format upgrades when accessing the Realm.
        internal var disableFormatUpgrade: Bool = false

        // MARK: Private Methods

        internal var rlmConfiguration: RLMRealmConfiguration {
            let configuration = RLMRealmConfiguration()
            switch kind {
            case let .file(fileURL):
                configuration.fileURL = fileURL
            case let .inMemory(identifier):
                configuration.inMemoryIdentifier = identifier
            case let .synced(syncConfig):
                configuration.syncConfiguration = syncConfig.asConfig()
            }
            configuration.encryptionKey = self.encryptionKey
            configuration.readOnly = self.readOnly
            configuration.schemaVersion = self.schemaVersion
            configuration.migrationBlock = self.migrationBlock.map { accessorMigrationBlock($0) }
            configuration.deleteRealmIfMigrationNeeded = self.deleteRealmIfMigrationNeeded
            if let shouldCompactOnLaunch = self.shouldCompactOnLaunch {
                configuration.shouldCompactOnLaunch = ObjectiveCSupport.convert(object: shouldCompactOnLaunch)
            } else {
                configuration.shouldCompactOnLaunch = nil
            }
            configuration.customSchema = self.customSchema
            configuration.disableFormatUpgrade = self.disableFormatUpgrade
            return configuration
        }

        internal static func fromRLMRealmConfiguration(_ rlmConfiguration: RLMRealmConfiguration) -> Configuration {
            var configuration = Configuration()
            if let filePath = rlmConfiguration.fileURL?.path {
                configuration.kind = .file(URL(fileURLWithPath: filePath))
            } else if let objcSyncConfig = rlmConfiguration.syncConfiguration {
                configuration.kind = .synced(SyncConfiguration(config: objcSyncConfig))
            } else if let identifier = rlmConfiguration.inMemoryIdentifier {
                configuration.kind = .inMemory(identifier)
            } else {
                throwRealmException("Realm configuration did not have one of file URL, in-memory identifier, or sync "
                    + "configuration specified.")
            }
            configuration.encryptionKey = rlmConfiguration.encryptionKey
            configuration.readOnly = rlmConfiguration.readOnly
            configuration.schemaVersion = rlmConfiguration.schemaVersion
            configuration.migrationBlock = rlmConfiguration.migrationBlock.map { rlmMigration in
                return { migration, schemaVersion in
                    rlmMigration(migration.rlmMigration, schemaVersion)
                }
            }
            configuration.deleteRealmIfMigrationNeeded = rlmConfiguration.deleteRealmIfMigrationNeeded
            configuration.shouldCompactOnLaunch = rlmConfiguration.shouldCompactOnLaunch.map(ObjectiveCSupport.convert)
            configuration.customSchema = rlmConfiguration.customSchema
            configuration.disableFormatUpgrade = rlmConfiguration.disableFormatUpgrade
            return configuration
        }
    }
}

// MARK: CustomStringConvertible

extension Realm.Configuration: CustomStringConvertible {
    /// A human-readable description of the configuration value.
    public var description: String {
        return gsub(pattern: "\\ARLMRealmConfiguration",
                    template: "Realm.Configuration",
                    string: rlmConfiguration.description) ?? ""
    }
}

// MARK: Migration assistance

public extension Realm.Configuration {
    @available(*, unavailable, message: "Get or set `Realm.Configuration.kind` instead.")
    var fileURL: URL? {
        get { fatalError() }
        set { fatalError() }
    }

    @available(*, unavailable, message: "Get or set `Realm.Configuration.kind` instead.")
    var inMemoryIdentifier: String? {
        get { fatalError() }
        set { fatalError() }
    }

    @available(*, unavailable, message: "Get or set `Realm.Configuration.kind` instead.")
    var syncConfiguration: SyncConfiguration? {
        get { fatalError() }
        set { fatalError() }
    }

    @available(*, unavailable, message: "`fileURL`, `inMemoryIdentifier`, and `syncConfiguration` arguments have been replaced with `kind`.")
    public init(fileURL: URL? = nil,
                inMemoryIdentifier: String? = nil,
                syncConfiguration: SyncConfiguration? = nil,
                encryptionKey: Data? = nil,
                readOnly: Bool = false,
                schemaVersion: UInt64 = 0,
                migrationBlock: MigrationBlock? = nil,
                deleteRealmIfMigrationNeeded: Bool = false,
                shouldCompactOnLaunch: ((Int, Int) -> Bool)? = nil,
                objectTypes: [Object.Type]? = nil) {
        fatalError()
    }
}
