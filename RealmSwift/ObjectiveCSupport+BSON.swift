////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 Realm Inc.
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
 :nodoc:
 **/
public extension ObjectiveCSupport {
    // FIXME: remove these and rename convertBson to convert on the next major
    // version bump
    static func convert(object: AnyBSON?) -> RLMBSON? {
        if let converted = object.map(self.convertBson), !(converted is NSNull) {
            return converted
        }
        return nil
    }

    static func convert(object: RLMBSON?) -> AnyBSON? {
        if let object = object {
            let converted = convertBson(object: object)
            if converted == .null {
                return nil
            }
            return converted
        }
        return nil
    }

    /// Convert an `AnyBSON` to a `RLMBSON`.
    static func convertBson(object: AnyBSON) -> RLMBSON {
        switch object {
        case .int32(let val):
            return val as NSNumber
        case .int64(let val):
            return val as NSNumber
        case .double(let val):
            return val as NSNumber
        case .string(let val):
            return val as NSString
        case .binary(let val):
            return val as NSData
        case .datetime(let val):
            return val as NSDate
        case .timestamp(let val):
            return val as NSDate
        case .decimal128(let val):
            return val as RLMDecimal128
        case .objectId(let val):
            return val as RLMObjectId
        case .document(let val):
            return val.reduce(into: Dictionary<String, RLMBSON?>()) { (result: inout [String: RLMBSON?], kvp) in
                result[kvp.key] = kvp.value.map(convertBson) ?? NSNull()
            } as NSDictionary
        case .array(let val):
            return val.map { $0.map(convertBson) } as NSArray
        case .maxKey:
            return MaxKey()
        case .minKey:
            return MinKey()
        case .regex(let val):
            return val
        case .bool(let val):
            return val as NSNumber
        case .uuid(let val):
            return val as NSUUID
        case .null:
            return NSNull()
        }
    }

    /// Convert a `RLMBSON` to an `AnyBSON`.
    static func convertBson(object bson: RLMBSON) -> AnyBSON? {
        switch bson.__bsonType {
        case .null:
            return .null
        case .int32:
            guard let val = bson as? NSNumber else {
                return nil
            }
            return .int32(Int32(val.intValue))
        case .int64:
            guard let val = bson as? NSNumber else {
                return nil
            }
            return .int64(Int64(val.int64Value))
        case .bool:
            guard let val = bson as? NSNumber else {
                return nil
            }
            return .bool(val.boolValue)
        case .double:
            guard let val = bson as? NSNumber else {
                return nil
            }
            return .double(val.doubleValue)
        case .string:
            guard let val = bson as? NSString else {
                return nil
            }
            return .string(val as String)
        case .binary:
            guard let val = bson as? NSData else {
                return nil
            }
            return .binary(val as Data)
        case .timestamp:
            guard let val = bson as? NSDate else {
                return nil
            }
            return .timestamp(val as Date)
        case .datetime:
            guard let val = bson as? NSDate else {
                return nil
            }
            return .datetime(val as Date)
        case .objectId:
            guard let val = bson as? RLMObjectId,
                let oid = try? ObjectId(string: val.stringValue) else {
                return nil
            }
            return .objectId(oid)
        case .decimal128:
            guard let val = bson as? RLMDecimal128 else {
                return nil
            }
            return .decimal128(Decimal128(stringLiteral: val.stringValue))
        case .regularExpression:
            guard let val = bson as? NSRegularExpression else {
                return nil
            }
            return .regex(val)
        case .maxKey:
            return .maxKey
        case .minKey:
            return .minKey
        case .document:
            guard let val = bson as? Dictionary<String, RLMBSON?> else {
                return nil
            }
            return .document(val.reduce(into: Dictionary<String, AnyBSON?>()) { (result: inout [String: AnyBSON?], kvp) in
                result[kvp.key] = kvp.value.map(convert)
            })
        case .array:
            guard let val = bson as? Array<RLMBSON?> else {
                return nil
            }
            return .array(val.compactMap {
                if let value = $0 {
                    return convertBson(object: value)
                }
                return .null
            }.map { (v: AnyBSON) -> AnyBSON? in v == .null ? nil : v })
        case .UUID:
            guard let val = bson as? NSUUID else {
                return nil
            }
            return .uuid(val as UUID)
        default:
            return nil
        }
    }
}
