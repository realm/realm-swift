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
     A `Configuration` instance describes the different options used to create an instance of a Realm.

     `Configuration` instances are just plain Swift structs. Unlike `Realm`s and `Object`s, they can be freely shared
     between threads as long as you do not mutate them.

     Creating configuration values for class subsets (by setting the `objectClasses` property) can be expensive. Because
     of this, you will normally want to cache and reuse a single configuration value for each distinct configuration
     rather than creating a new value each time you open a Realm.
     */
    @frozen public struct Configuration {

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

         - note: The `fileURL`, `inMemoryIdentifier`, and `syncConfiguration` parameters are mutually exclusive. Only
                 set one of them, or none if you wish to use the default file URL.

         - parameter fileURL:            The local URL to the Realm file.
         - parameter inMemoryIdentifier: A string used to identify a particular in-memory Realm.
         - parameter syncConfiguration:  For Realms intended to sync with Atlas App Services, a sync configuration.
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
         - parameter objectTypes:        The subset of `Object` and `EmbeddedObject` subclasses persisted in the Realm.
         - parameter seedFilePath:       The path to the realm file that will be copied to the fileURL when opened
                                         for the first time.
        */
        public init(fileURL: URL? = URL(fileURLWithPath: RLMRealmPathForFile("default.realm"), isDirectory: false),
                    inMemoryIdentifier: String? = nil,
                    syncConfiguration: SyncConfiguration? = nil,
                    encryptionKey: Data? = nil,
                    readOnly: Bool = false,
                    schemaVersion: UInt64 = 0,
                    migrationBlock: MigrationBlock? = nil,
                    deleteRealmIfMigrationNeeded: Bool = false,
                    shouldCompactOnLaunch: ((Int, Int) -> Bool)? = nil,
                    objectTypes: [ObjectBase.Type]? = nil,
                    seedFilePath: URL? = nil) {
                self.fileURL = fileURL
                if let inMemoryIdentifier = inMemoryIdentifier {
                    self.inMemoryIdentifier = inMemoryIdentifier
                }
                if let syncConfiguration = syncConfiguration {
                    self.syncConfiguration = syncConfiguration
                }
                self.encryptionKey = encryptionKey
                self.readOnly = readOnly
                self.schemaVersion = schemaVersion
                self.migrationBlock = migrationBlock
                self.deleteRealmIfMigrationNeeded = deleteRealmIfMigrationNeeded
                self.shouldCompactOnLaunch = shouldCompactOnLaunch
                self.objectTypes = objectTypes
                self.seedFilePath = seedFilePath
        }

        // MARK: Configuration Properties

        /**
         A configuration value used to configure a Realm for synchronization with Atlas App Services. Mutually
         exclusive with `inMemoryIdentifier`.
         */
        public var syncConfiguration: SyncConfiguration? {
            get {
                return _syncConfiguration
            }
            set {
                _inMemoryIdentifier = nil
                _syncConfiguration = newValue
            }
        }

        private var _syncConfiguration: SyncConfiguration?

        /// The local URL of the Realm file. Mutually exclusive with `inMemoryIdentifier`.
        public var fileURL: URL? {
            get {
                return _path.map { URL(fileURLWithPath: $0) }
            }
            set {
                _inMemoryIdentifier = nil
                _path = newValue?.path
            }
        }

        private var _path: String?

        /// A string used to identify a particular in-memory Realm. Mutually exclusive with `fileURL` and
        /// `syncConfiguration`.
        public var inMemoryIdentifier: String? {
            get {
                return _inMemoryIdentifier
            }
            set {
                _path = nil
                _syncConfiguration = nil
                _inMemoryIdentifier = newValue
            }
        }

        private var _inMemoryIdentifier: String?

        /// A 64-byte key to use to encrypt the data, or `nil` if encryption is not enabled.
        public var encryptionKey: Data?

        /**
         Whether to open the Realm in read-only mode.

         For non-synchronized Realms, this is required to be able to open Realm files which are not
         writeable or are in a directory which is not writeable.  This should only be used on files
         which will not be modified by anyone while they are open, and not just to get a read-only
         view of a file which may be written to by another thread or process. Opening in read-only
         mode requires disabling Realm's reader/writer coordination, so committing a write
         transaction from another process will result in crashes.

         Syncronized Realms must always be writeable (as otherwise no synchronization could happen),
         and this instead merely disallows performing write transactions on the Realm. In addition,
         it will skip some automatic writes made to the Realm, such as to initialize the Realm's
         schema. Setting `readOnly = YES` is not strictly required for Realms which the sync user
         does not have write access to, but is highly recommended as it will improve error reporting
         and catch some errors earlier.

         Realms using query-based sync cannot be opened in read-only mode.
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
        public var deleteRealmIfMigrationNeeded: Bool {
            get {
                return _deleteRealmIfMigrationNeeded
            }
            set(newValue) {
                if newValue && syncConfiguration != nil {
                    throwRealmException("Cannot set 'deleteRealmIfMigrationNeeded' when sync is enabled ('syncConfig' is set).")
                }
                _deleteRealmIfMigrationNeeded = newValue
            }
        }

        private var _deleteRealmIfMigrationNeeded: Bool = false

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
        public var objectTypes: [ObjectBase.Type]? {
            get {
                return self.customSchema.map { $0.objectSchema.compactMap { $0.objectClass as? ObjectBase.Type } }
            }
            set {
                self.customSchema = newValue.map { RLMSchema(objectClasses: $0) }
            }
        }
        /**
         The maximum number of live versions in the Realm file before an exception will
         be thrown when attempting to start a write transaction.

         Realm provides MVCC snapshot isolation, meaning that writes on one thread do
         not overwrite data being read on another thread, and instead write a new copy
         of that data. When a Realm refreshes it updates to the latest version of the
         data and releases the old versions, allowing them to be overwritten by
         subsequent write transactions.

         Under normal circumstances this is not a problem, but if the number of active
         versions grow too large, it will have a negative effect on the filesize on
         disk. This can happen when performing writes on many different threads at
         once, when holding on to frozen objects for an extended time, or when
         performing long operations on background threads which do not allow the Realm
         to refresh.

         Setting this property to a non-zero value makes it so that exceeding the set
         number of versions will instead throw an exception. This can be used with a
         low value during development to help identify places that may be problematic,
         or in production use to cause the app to crash rather than produce a Realm
         file which is too large to be oened.
         */
        public var maximumNumberOfActiveVersions: UInt?

        /**
         When opening the Realm for the first time, instead of creating an empty file,
         the Realm file will be copied from the provided seed file path and used instead.
         This can be used to open a Realm file with pre-populated data.

         If a realm file already exists at the configurations's destination path, the seed file
         will not be copied and the already existing realm will be opened instead.

         Note that to use this parameter with a synced Realm configuration
         the seed Realm must be appropriately copied to a destination with
         `Realm.writeCopy(configuration:)` first.

         This option is mutually exclusive with `inMemoryIdentifier`. Setting a `seedFilePath`
         will nil out the `inMemoryIdentifier`.
         */
        public var seedFilePath: URL?

        /**
         Configuration for Realm event recording. Events are enabled if this is set
         to a non-nil value.
         */
        public var eventConfiguration: EventConfiguration?

        /// A custom schema to use for the Realm.
        private var customSchema: RLMSchema?

        /// If `true`, disables automatic format upgrades when accessing the Realm.
        internal var disableFormatUpgrade: Bool = false

        // MARK: Flexible Sync

        /// Callback for adding subscriptions to the initialization of the Realm
        internal var initialSubscriptions: ((SyncSubscriptionSet) -> Void)?

        /// If `true` Indicates that the `initialSubscriptions` will run on every app startup.
        internal var rerunOnOpen: Bool = false

        // MARK: Private Methods

        internal var rlmConfiguration: RLMRealmConfiguration {
            let configuration = RLMRealmConfiguration()
            if let syncConfiguration = syncConfiguration {
                configuration.syncConfiguration = syncConfiguration.asConfig()
            }
            if let fileURL = fileURL {
                configuration.fileURL = fileURL
            } else if let inMemoryIdentifier = inMemoryIdentifier {
                configuration.inMemoryIdentifier = inMemoryIdentifier
            } else if syncConfiguration == nil {
                fatalError("A Realm Configuration must specify a path or an in-memory identifier.")
            }
            if let seedFilePath = seedFilePath {
                configuration.seedFilePath = seedFilePath
            } else if let inMemoryIdentifier = inMemoryIdentifier {
                configuration.inMemoryIdentifier = inMemoryIdentifier
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
            configuration.setCustomSchemaWithoutCopying(self.customSchema)
            configuration.disableFormatUpgrade = self.disableFormatUpgrade
            configuration.maximumNumberOfActiveVersions = self.maximumNumberOfActiveVersions ?? 0
            if let eventConfiguration = eventConfiguration {
                let rlmConfig = RLMEventConfiguration()
                rlmConfig.partitionPrefix = eventConfiguration.partitionPrefix
                rlmConfig.syncUser = eventConfiguration.syncUser
                rlmConfig.metadata = eventConfiguration.metadata
                rlmConfig.logger = eventConfiguration.logger
                configuration.eventConfiguration = rlmConfig
            }

            if let initialSubscriptions = initialSubscriptions {
                configuration.initialSubscriptions = ObjectiveCSupport.convert(block: initialSubscriptions)
                configuration.rerunOnOpen = rerunOnOpen
            }

            return configuration
        }

        internal static func fromRLMRealmConfiguration(_ rlmConfiguration: RLMRealmConfiguration) -> Configuration {
            var configuration = Configuration()
            configuration._path = rlmConfiguration.fileURL?.path
            configuration._inMemoryIdentifier = rlmConfiguration.inMemoryIdentifier
            if let objcSyncConfig = rlmConfiguration.syncConfiguration {
                configuration._syncConfiguration = SyncConfiguration(config: objcSyncConfig)
            } else {
                configuration._syncConfiguration = nil
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
            configuration.maximumNumberOfActiveVersions = rlmConfiguration.maximumNumberOfActiveVersions
            if let eventConfiguration = rlmConfiguration.eventConfiguration {
                configuration.eventConfiguration = EventConfiguration(metadata: eventConfiguration.metadata,
                                                                      syncUser: eventConfiguration.syncUser,
                                                                      partitionPrefix: eventConfiguration.partitionPrefix)
            }

            configuration.initialSubscriptions = ObjectiveCSupport.convert(block: rlmConfiguration.initialSubscriptions)
            configuration.rerunOnOpen = rlmConfiguration.rerunOnOpen

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

// MARK: Equatable

extension Realm.Configuration: Equatable {
    public static func == (lhs: Realm.Configuration, rhs: Realm.Configuration) -> Bool {
        lhs.encryptionKey == rhs.encryptionKey &&
            lhs.fileURL == rhs.fileURL &&
            lhs.syncConfiguration?.partitionValue == rhs.syncConfiguration?.partitionValue &&
            lhs.inMemoryIdentifier == rhs.inMemoryIdentifier &&
            lhs.readOnly == rhs.readOnly &&
            lhs.schemaVersion == rhs.schemaVersion
    }
}
