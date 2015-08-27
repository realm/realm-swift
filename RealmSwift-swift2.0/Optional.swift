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

public protocol RealmOptionalType {}
extension Int: RealmOptionalType {}
extension Int16: RealmOptionalType {}
extension Int32: RealmOptionalType {}
extension Int64: RealmOptionalType {}
extension Float: RealmOptionalType {}
extension Double: RealmOptionalType {}
extension Bool: RealmOptionalType {}

import Realm

public final class RealmOptional<T: RealmOptionalType> : RLMOptionalBase {
    public var value: T? {
        get {
            return underlyingValue as! T?
        }
        set {
            if let value = newValue {
                self.underlyingValue = value as! AnyObject
            } else {
                self.underlyingValue = nil
            }
        }
    }

    public init(_ v: T? = nil) {
        super.init()
        value = v
    }
}
