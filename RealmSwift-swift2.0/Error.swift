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
public enum Error: ErrorType {
    /// :nodoc:
    public var _code: Int {
        return rlmError.rawValue
    }

    /// :nodoc:
    public var _domain: String {
        return RLMErrorDomain
    }

    /// The RLMError value, which can be used to derive the error's code.
    private var rlmError: RLMError {
        switch self {
        case .Fail:
            return RLMError.Fail
        case .FileAccessError:
            return RLMError.FileAccessError
        case .FilePermissionDenied:
            return RLMError.FilePermissionDenied
        case .FileExists:
            return RLMError.FileExists
        case .FileNotFound:
            return RLMError.FileNotFound
        case .IncompatibleLockFile:
            return RLMError.IncompatibleLockFile
        }
    }

    /// Error thrown by Realm if no other specific error is returned when a realm is opened.
    case Fail

    /// Error thrown by Realm for any I/O related exception scenarios when a realm is opened.
    case FileAccessError

    /// Error thrown by Realm if the user does not have permission to open or create
    /// the specified file in the specified access mode when the realm is opened.
    case FilePermissionDenied

    /// Error thrown by Realm if no_create was specified and the file did already exist
    /// when the realm is opened.
    case FileExists

    /// Error thrown by Realm if no_create was specified and the file was not found
    /// when the realm is opened.
    case FileNotFound

    /// Error thrown by Realm if the database file is currently open in another process which
    /// cannot share with the current process due to an architecture mismatch.
    case IncompatibleLockFile
}

/**
Explicitly implement pattern matching for `Realm.Error`, so that the instances can be used in the
`do … syntax`.
*/
public func ~= (lhs: Error, rhs: ErrorType) -> Bool {
    return lhs._code == rhs._code
        && lhs._domain == rhs._domain
}
