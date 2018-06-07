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

extension Realm {
    /**
     Struct that describes the error codes within the Realm error domain.
     The values can be used to catch a variety of _recoverable_ errors, especially those
     happening when initializing a Realm instance.

     ```swift
     let realm: Realm?
     do {
         realm = try Realm()
     } catch Realm.Error.incompatibleLockFile {
         print("Realm Browser app may be attached to Realm on device?")
     }
     ```
    */
    public struct Error {
        public typealias Code = RLMError.Code

        /// Error thrown by Realm if no other specific error is returned when a realm is opened.
        public static let fail: Code = .fail

        /// Error thrown by Realm for any I/O related exception scenarios when a realm is opened.
        public static let fileAccess: Code = .fileAccess

        /// Error thrown by Realm if the user does not have permission to open or create
        /// the specified file in the specified access mode when the realm is opened.
        public static let filePermissionDenied: Code = .filePermissionDenied

        /// Error thrown by Realm if the file already exists when a copy should be written.
        public static let fileExists: Code = .fileExists

        /// Error thrown by Realm if no file was found when a realm was opened as
        /// read-only or if the directory part of the specified path was not found
        /// when a copy should be written.
        public static let fileNotFound: Code = .fileNotFound

        /// Error thrown by Realm if the database file is currently open in another process which
        /// cannot share with the current process due to an architecture mismatch.
        public static let incompatibleLockFile: Code = .incompatibleLockFile

        /// Error thrown by Realm if a file format upgrade is required to open the file,
        /// but upgrades were explicitly disabled.
        public static let fileFormatUpgradeRequired: Code = .fileFormatUpgradeRequired

        /// Error thrown by Realm if there is insufficient available address space.
        public static let addressSpaceExhausted: Code = .addressSpaceExhausted

        /// Error thrown by Realm if there is a schema version mismatch, so that a migration is required.
        public static let schemaMismatch: Code = .schemaMismatch

        /// Error thrown by Realm when attempting to open an incompatible synchronized Realm file.
        ///
        /// This error occurs when the Realm file was created with an older version of Realm and an automatic
        /// migration to the current version is not possible. When such an error occurs, the original file is moved
        /// to a backup location, and future attempts to open the synchronized Realm will result in a new file being
        /// created. If you wish to migrate any data from the backup Realm, you can open it using the provided
        /// Realm configuration.
        public static let incompatibleSyncedFile: Code = .incompatibleSyncedFile

        /// :nodoc:
        public var code: Code {
            return (_nsError as! RLMError).code
        }

        /// :nodoc:
        public let _nsError: NSError

        /// :nodoc:
        public init(_nsError error: NSError) {
            _nsError = error
        }

        /// Realm configuration that can be used to open the backup copy of a Realm file
        ///
        //// Only applicable to `incompatibleSyncedFile`. Will be `nil` for all other errors.
        public var backupConfiguration: Realm.Configuration? {
            let configuration = userInfo[RLMBackupRealmConfigurationErrorKey] as! RLMRealmConfiguration?
            return configuration.map(Realm.Configuration.fromRLMRealmConfiguration)
        }
    }
}

/// :nodoc:
// Provide bridging from errors with domain RLMErrorDomain to Error.
extension Realm.Error: _BridgedStoredNSError {
    /// :nodoc:
    public static let _nsErrorDomain = RLMErrorDomain
    /// :nodoc:
    public static let errorDomain = RLMErrorDomain
}

// MARK: Equatable

extension Realm.Error: Equatable {}

/// Returns a Boolean indicating whether the errors are identical.
public func == (lhs: Error, rhs: Error) -> Bool {
    return lhs._code == rhs._code
        && lhs._domain == rhs._domain
}

// MARK: Pattern Matching

/**
 Pattern matching matching for `Realm.Error`, so that the instances can be used with Swift's
 `do { ... } catch { ... }` syntax.
*/
public func ~= (lhs: Realm.Error, rhs: Error) -> Bool {
    return lhs == rhs
}
