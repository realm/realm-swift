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

#if swift(>=3.0)

/**
Enumeration that describes the error codes within the Realm error domain.
The values can be used to catch a variety of _recoverable_ errors, especially those
happening when initializing a Realm instance.

    let realm: Realm?
    do {
        realm = Realm()
    } catch RealmSwift.Error.IncompatibleLockFile() {
        print("Realm Browser app may be attached to Realm on device?")
    }

*/
public enum Error: ErrorProtocol {
    // swiftlint:disable variable_name
    /// :nodoc:
    public var _code: Int {
        return rlmError.rawValue
    }

    /// :nodoc:
    public var _domain: String {
        return RLMErrorDomain
    }
    // swiftlint:enable variable_name

    /// The RLMError value, which can be used to derive the error's code.
    private var rlmError: RLMError {
        switch self {
        case .Fail:
            return .fail
        case .FileAccess:
            return .fileAccess
        case .FilePermissionDenied:
            return .filePermissionDenied
        case .FileExists:
            return .fileExists
        case .FileNotFound:
            return .fileNotFound
        case .IncompatibleLockFile:
            return .incompatibleLockFile
        case .FileFormatUpgradeRequired:
            return .fileFormatUpgradeRequired
        case .AddressSpaceExhausted:
            return .addressSpaceExhausted
        case .SchemaMismatch:
            return .schemaMismatch
        }
    }

    /// Error thrown by Realm if no other specific error is returned when a realm is opened.
    case Fail

    /// Error thrown by Realm for any I/O related exception scenarios when a realm is opened.
    case FileAccess

    /// Error thrown by Realm if the user does not have permission to open or create
    /// the specified file in the specified access mode when the realm is opened.
    case FilePermissionDenied

    /// Error thrown by Realm if the file already exists when a copy should be written.
    case FileExists

    /// Error thrown by Realm if no file was found when a realm was opened as
    /// read-only or if the directory part of the specified path was not found
    /// when a copy should be written.
    case FileNotFound

    /// Error thrown by Realm if the database file is currently open in another process which
    /// cannot share with the current process due to an architecture mismatch.
    case IncompatibleLockFile

    /// Error thrown by Realm if a file format upgrade is required to open the file,
    /// but upgrades were explicitly disabled.
    case FileFormatUpgradeRequired

    /// Error thrown by Realm if there is insufficient available address space.
    case AddressSpaceExhausted

    /** Error thrown by Realm if there is a schema version mismatch, so that a migration is required. */
    case SchemaMismatch
}

// MARK: Equatable

extension Error: Equatable {}

/// Returns whether the two errors are identical
public func == (lhs: ErrorProtocol, rhs: ErrorProtocol) -> Bool { // swiftlint:disable:this valid_docs
    return lhs._code == rhs._code
        && lhs._domain == rhs._domain
}

// MARK: Pattern Matching

/**
Explicitly implement pattern matching for `Realm.Error`, so that the instances can be used in the
`do … syntax`.
*/
public func ~= (lhs: Error, rhs: ErrorProtocol) -> Bool { // swiftlint:disable:this valid_docs
    return lhs == rhs
}

#else

/**
 `Error` is an enum representing all recoverable errors. It is associated with the
 Realm error domain specified in `RLMErrorDomain`.

 `Error` is a Swift `ErrorType`:

 ```swift
 let realm: Realm?
 do {
     realm = try Realm()
 } catch RealmSwift.Error.IncompatibleLockFile() {
     print("Incompatible lock file. The Realm Browser app might be attached to a Realm on the device.")
 }
 ```
*/
public enum Error: ErrorType {
    // swiftlint:disable variable_name
    /// :nodoc:
    public var _code: Int {
        return rlmError.rawValue
    }

    /// :nodoc:
    public var _domain: String {
        return RLMErrorDomain
    }
    // swiftlint:enable variable_name

    /// The `RLMError` value, which can be used to derive the error code.
    private var rlmError: RLMError {
        switch self {
        case .Fail:
            return RLMError.Fail
        case .FileAccess:
            return RLMError.FileAccess
        case .FilePermissionDenied:
            return RLMError.FilePermissionDenied
        case .FileExists:
            return RLMError.FileExists
        case .FileNotFound:
            return RLMError.FileNotFound
        case .IncompatibleLockFile:
            return RLMError.IncompatibleLockFile
        case .FileFormatUpgradeRequired:
            return RLMError.FileFormatUpgradeRequired
        case .AddressSpaceExhausted:
            return RLMError.AddressSpaceExhausted
        case .SchemaMismatch:
            return RLMError.SchemaMismatch
        }
    }

    /// Denotes a general error that occurred when trying to open a Realm.
    case Fail

    /// Denotes a file I/O error that occurred when trying to open a Realm.
    case FileAccess

    /// Denotes a file permission error that ocurred when trying to open a Realm.
    ///
    /// This error can occur if the user does not have permission to open or create
    /// the specified file in the specified access mode when opening a Realm.
    case FilePermissionDenied

    /// Denotes an error where a file was to be written to disk, but another file with the same name
    /// already exists.
    case FileExists

    /// Denotes an error that occurs if a file could not be found.
    ///
    /// This error may occur if a Realm file could not be found on disk when trying to open a
    /// Realm as read-only, or if the directory part of the specified path was not found when
    /// trying to write a copy.
    case FileNotFound

    /// Denotes an error that occurs if the database file is currently open in another
    /// process which cannot share with the current process due to an
    /// architecture mismatch.
    ///
    /// This error may occur if trying to share a Realm file between an i386 (32-bit) iOS
    /// Simulator and the Realm Browser application. In this case, please use the 64-bit
    /// version of the iOS Simulator.
    case IncompatibleLockFile

    /// Denotes an error that occurs if a file format upgrade is required to open the file,
    /// but upgrades were explicitly disabled.
    case FileFormatUpgradeRequired

    /// Denotes an error that occurs when there is insufficient available address space.
    case AddressSpaceExhausted

    /// Denotes an error that occurs if there is a schema version mismatch, so that a migration is required.
    case SchemaMismatch
}

// MARK: Equatable

extension Error: Equatable {}

/// Returns a Boolean indicating whether the errors are identical.
public func == (lhs: ErrorType, rhs: ErrorType) -> Bool { // swiftlint:disable:this valid_docs
    return lhs._code == rhs._code
        && lhs._domain == rhs._domain
}

// MARK: Pattern Matching

/**
 Pattern matching matching for `Realm.Error`, so that the instances can be used with Swift's
 `do { ... } catch { ... }` syntax.
*/
public func ~= (lhs: Error, rhs: ErrorType) -> Bool { // swiftlint:disable:this valid_docs
    return lhs == rhs
}

#endif
