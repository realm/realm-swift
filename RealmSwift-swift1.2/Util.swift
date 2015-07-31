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

// MARK: Internal Helpers

internal func notFoundToNil(index: UInt) -> Int? {
    if index == UInt(NSNotFound) {
        return nil
    }
    return Int(index)
}

internal func throwRealmException(message: String, userInfo: [String:AnyObject] = [:]) {
    NSException(name: RLMExceptionName, reason: message, userInfo: userInfo).raise()
}

internal func throwForNegativeIndex(int: Int, parameterName: String = "index") {
    if int < 0 {
        throwRealmException("Cannot pass a negative value for '\(parameterName)'.")
    }
}

internal func gsub(pattern: String, template: String, string: String, error: NSErrorPointer = nil) -> String? {
    if let regex = NSRegularExpression(pattern: pattern, options: nil, error: error) {
        return regex.stringByReplacingMatchesInString(string, options: nil, range: NSRange(location: 0, length: count(string)), withTemplate: template)
    }
    return nil
}
