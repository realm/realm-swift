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

    public enum Value {
        case none
        case int(Int)
        case float(Float)
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

        public var floatValue: Float? {
            guard case let .float(f) = self else {
                return nil
            }
            return f
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
}

// !!!: @Eric move to own objc support file
//ObjectiveCSupport+AnyRealmType

public extension ObjectiveCSupport {

    static func convert(value: AnyRealmValue.Value?) -> RLMValue? {
        switch value {
            case let .int(i):
                return i as NSNumber
            case let .float(f):
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
                return o.unsafeCastToRLMObject()

            default:
                return nil
        }
    }

    static func convert(value: RLMValue?) -> AnyRealmValue.Value {
        guard let value = value else {
            return .none
        }

        switch value.__valueType {
            case RLMPropertyType.int:
                guard let val = value as? NSNumber else {
                    return .none
                }
                return .int(val.intValue)
            case RLMPropertyType.float:
                guard let val = value as? NSNumber else {
                    return .none
                }
                return .float(val.floatValue)
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
                guard let val = value as? RLMObjectBase else {
                    return .none
                }
                return .object(Object.bridging(from: val, with: nil))
            default:
                return .none
        }
    }
}
