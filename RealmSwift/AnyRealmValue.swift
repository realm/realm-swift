////////////////////////////////////////////////////////////////////////////
//
// Copyright 2021 Realm Inc.
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

public final class AnyRealmValue: RLMValueBase {

    public enum Value: Hashable {
        case none
        case int(Int)
        case bool(Bool)
        case float(Float)
        case double(Double)
        case string(String)
        case data(Data)
        case date(Date)
        case object(Object)
        case objectId(ObjectId)
        case decimal128(Decimal128)
        case uuid(UUID)

        public var intValue: Int? {
            guard case let .int(i) = self else {
                return nil
            }
            return i
        }

        public var boolValue: Bool? {
            guard case let .bool(b) = self else {
                return nil
            }
            return b
        }

        public var floatValue: Float? {
            guard case let .float(f) = self else {
                return nil
            }
            return f
        }

        public var doubleValue: Double? {
            guard case let .double(d) = self else {
                return nil
            }
            return d
        }

        public var stringValue: String? {
            guard case let .string(s) = self else {
                return nil
            }
            return s
        }

        public var dataValue: Data? {
            guard case let .data(d) = self else {
                return nil
            }
            return d
        }

        public var dateValue: Date? {
            guard case let .date(d) = self else {
                return nil
            }
            return d
        }

        public var objectIdValue: ObjectId? {
            guard case let .objectId(o) = self else {
                return nil
            }
            return o
        }

        public var decimal128Value: Decimal128? {
            guard case let .decimal128(d) = self else {
                return nil
            }
            return d
        }

        public var uuidValue: UUID? {
            guard case let .uuid(u) = self else {
                return nil
            }
            return u
        }

        public func objectValue<T: Object>(_ objectType: T.Type) -> T? {
            guard case let .object(o) = self else {
                return nil
            }
            return o as? T
        }
    }

    public var value: Value {
        set {
            rlmValue = ObjectiveCSupport.convert(value: newValue)
        }
        get {
            ObjectiveCSupport.convert(value: rlmValue)
        }
    }

    // Used for when retrieving an AnyRealmValue via KVC
    internal convenience init(value: RLMValue?, object: RLMObjectBase, property: RLMProperty) {
        self.init()
        rlmValue = value
        attachIfNeeded(withParent: object, property: property)
    }
}
