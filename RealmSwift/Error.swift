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
    public typealias Error = RLMError
}

extension Realm.Error {
    /// This error could be returned by completion block when no success and no error were produced
    public static let callFailed = Realm.Error(Realm.Error.fail, userInfo: [NSLocalizedDescriptionKey: "Call failed"])

    /// The file URL which produced this error, or `nil` if not applicable
    public var fileURL: URL? {
        return (userInfo[NSFilePathErrorKey] as? String).flatMap(URL.init(fileURLWithPath:))
    }
}

// MARK: Equatable

extension Realm.Error: Equatable {}

// FIXME: we should not be defining this but it's a breaking change to remove
/// Returns a Boolean indicating whether the errors are identical.
public func == (lhs: Error, rhs: Error) -> Bool {
    return lhs._code == rhs._code
        && lhs._domain == rhs._domain
}
