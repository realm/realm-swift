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

public extension ObjectiveCSupport {

    /// Convert an object boxed in `AnyRealmValue` to its
    /// Objective-C representation.
    /// - Parameter value: The AnyRealmValue with the object.
    /// - Returns: Conversion of `value` to its Objective-C representation.
    static func convert(value: AnyRealmValue?) -> RLMValue? {
        switch value {
        case let .int(i):
            return i as NSNumber
        case let .bool(b):
            return b as NSNumber
        case let .float(f):
            return f as NSNumber
        case let .double(f):
            return f as NSNumber
        case let .string(s):
            return s as NSString
        case let .data(d):
            return d as NSData
        case let .date(d):
            return d as NSDate
        case let .objectId(o):
            return o as RLMObjectId
        case let .decimal128(o):
            return o as RLMDecimal128
        case let .uuid(u):
            return u as NSUUID
        case let .object(o):
            return o
        default:
            return nil
        }
    }

    /// Takes an RLMValue, converts it to its Swift type and
    /// stores it in `AnyRealmValue`.
    /// - Parameter value: The RLMValue.
    /// - Returns: The converted RLMValue type as an AnyRealmValue enum.
    static func convert(value: RLMValue?) -> AnyRealmValue {
        guard let value = value else {
            return .none
        }

        switch value.rlm_valueType {
        case RLMPropertyType.int:
            guard let val = value as? NSNumber else {
                return .none
            }
            return .int(val.intValue)
        case RLMPropertyType.bool:
            guard let val = value as? NSNumber else {
                return .none
            }
            return .bool(val.boolValue)
        case RLMPropertyType.float:
            guard let val = value as? NSNumber else {
                return .none
            }
            return .float(val.floatValue)
        case RLMPropertyType.double:
            guard let val = value as? NSNumber else {
                return .none
            }
            return .double(val.doubleValue)
        case RLMPropertyType.string:
            guard let val = value as? String else {
                return .none
            }
            return .string(val)
        case RLMPropertyType.data:
            guard let val = value as? Data else {
                return .none
            }
            return .data(val)
        case RLMPropertyType.date:
            guard let val = value as? Date else {
                return .none
            }
            return .date(val)
        case RLMPropertyType.objectId:
            guard let val = value as? ObjectId else {
                return .none
            }
            return .objectId(val)
        case RLMPropertyType.decimal128:
            guard let val = value as? Decimal128 else {
                return .none
            }
            return .decimal128(val)
        case RLMPropertyType.UUID:
            guard let val = value as? UUID else {
                return .none
            }
            return .uuid(val)
        case RLMPropertyType.object:
            guard let val = value as? Object else {
                return .none
            }
            return .object(val)
        default:
            return .none
        }
    }
}
