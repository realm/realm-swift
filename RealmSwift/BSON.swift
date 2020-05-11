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

/// Protocol representing a BSON value.
/// - SeeAlso: bsonspec.org
public protocol BSON : Equatable {
}

extension Int: BSON {
}

extension Int32: BSON {
}

extension Int64: BSON {
}

extension Bool : BSON {
}

extension Double : BSON {
}

extension String : BSON {
}

extension Data : BSON {
}

extension Date : BSON {
}

extension Decimal128 : BSON {
}

extension ObjectId : BSON {
}

public typealias Document = Dictionary<String, AnyBSON>
extension Dictionary : BSON where Key == String, Value == AnyBSON {
}

extension Array : BSON where Element == AnyBSON {
}

extension NSRegularExpression : BSON {
}

public typealias MaxKey = RLMMaxKey

extension MaxKey : BSON {
}

public typealias MinKey = RLMMinKey

extension MinKey : BSON {
}

/// Enum representing a BSON value.
/// - SeeAlso: bsonspec.org
public enum AnyBSON : BSON {
    /// A BSON double.
    case double(Double)

    /// A BSON string.
    /// - SeeAlso: https://docs.mongodb.com/manual/reference/bson-types/#string
    case string(String)

    /// A BSON document.
    case document(Document)

    /// A BSON array.
    indirect case array([AnyBSON])

    /// A BSON binary.
    case binary(Data)

    /// A BSON ObjectId.
    /// - SeeAlso: https://docs.mongodb.com/manual/reference/bson-types/#objectid
    case objectId(ObjectId)

    /// A BSON boolean.
    case bool(Bool)

    /// A BSON UTC datetime.
    /// - SeeAlso: https://docs.mongodb.com/manual/reference/bson-types/#date
    case datetime(Date)

    /// A BSON null.
    case null

    /// A BSON regular expression.
    case regex(NSRegularExpression)

    /// A BSON int32.
    case int32(Int32)

    /// A BSON timestamp.
    /// - SeeAlso: https://docs.mongodb.com/manual/reference/bson-types/#timestamps
    case timestamp(Date)

    /// A BSON int64.
    case int64(Int64)

    /// A BSON Decimal128.
    /// - SeeAlso: https://github.com/mongodb/specifications/blob/master/source/bson-decimal128/decimal128.rst
    case decimal128(Decimal128)

    /// A BSON minKey.
    case minKey

    /// A BSON maxKey.
    case maxKey

    /// Initialize a `BSON` from an integer. On 64-bit systems, this will result in an `.int64`. On 32-bit systems,
    /// this will result in an `.int32`.
    public init(_ int: Int) {
        if MemoryLayout<Int>.size == 4 {
            self = .int32(Int32(int))
        } else {
            self = .int64(Int64(int))
        }
    }

    public init<T: BSON>(_ bson: T) {
        switch bson {
        case let val as Int:
            self = .int64(Int64(val))
        case let val as Int32:
            self = .int32(val)
        case let val as Int64:
            self = .int64(val)
        case let val as Double:
            self = .double(val)
        case let val as String:
            self = .string(val)
        case let val as Data:
            self = .binary(val)
        case let val as Date:
            self = .datetime(val)
        case let val as Decimal128:
            self = .decimal128(val)
        case let val as ObjectId:
            self = .objectId(val)
        case let val as Document:
            self = .document(val)
        case let val as Array<AnyBSON>:
            self = .array(val)
        case let val as Bool:
            self = .bool(val)
        case is MaxKey:
            self = .maxKey
        case is MinKey:
            self = .minKey
        case let val as NSRegularExpression:
            self = .regex(val)
        default:
            self = .null
        }
    }

    /// If this `BSON` is an `.int32`, return it as an `Int32`. Otherwise, return nil.
    public var int32Value: Int32? {
        guard case let .int32(i) = self else {
            return nil
        }
        return i
    }

    /// If this `BSON` is a `.regex`, return it as a `RegularExpression`. Otherwise, return nil.
    public var regexValue: NSRegularExpression? {
        guard case let .regex(r) = self else {
            return nil
        }
        return r
    }

    /// If this `BSON` is an `.int64`, return it as an `Int64`. Otherwise, return nil.
    public var int64Value: Int64? {
        guard case let .int64(i) = self else {
            return nil
        }
        return i
    }

    /// If this `BSON` is an `.objectId`, return it as an `ObjectId`. Otherwise, return nil.
    public var objectIdValue: ObjectId? {
        guard case let .objectId(o) = self else {
            return nil
        }
        return o
    }

    /// If this `BSON` is a `.date`, return it as a `Date`. Otherwise, return nil.
    public var dateValue: Date? {
        guard case let .datetime(d) = self else {
            return nil
        }
        return d
    }

    /// If this `BSON` is an `.array`, return it as an `[BSON]`. Otherwise, return nil.
    public var arrayValue: [AnyBSON]? {
        guard case let .array(a) = self else {
            return nil
        }
        return a
    }

    /// If this `BSON` is a `.string`, return it as a `String`. Otherwise, return nil.
    public var stringValue: String? {
        guard case let .string(s) = self else {
            return nil
        }
        return s
    }

    /// If this `BSON` is a `.document`, return it as a `Document`. Otherwise, return nil.
    public var documentValue: Document? {
        guard case let .document(d) = self else {
            return nil
        }
        return d
    }

    /// If this `BSON` is a `.bool`, return it as an `Bool`. Otherwise, return nil.
    public var boolValue: Bool? {
        guard case let .bool(b) = self else {
            return nil
        }
        return b
    }

    /// If this `BSON` is a `.binary`, return it as a `Binary`. Otherwise, return nil.
    public var binaryValue: Data? {
        guard case let .binary(b) = self else {
            return nil
        }
        return b
    }

    /// If this `BSON` is a `.double`, return it as a `Double`. Otherwise, return nil.
    public var doubleValue: Double? {
        guard case let .double(d) = self else {
            return nil
        }
        return d
    }

    /// If this `BSON` is a `.decimal128`, return it as a `Decimal128`. Otherwise, return nil.
    public var decimal128Value: Decimal128? {
        guard case let .decimal128(d) = self else {
            return nil
        }
        return d
    }

    /// If this `BSON` is a `.timestamp`, return it as a `Timestamp`. Otherwise, return nil.
    public var timestampValue: Date? {
        guard case let .timestamp(t) = self else {
            return nil
        }
        return t
    }

    /// Return this BSON as an `Int` if possible.
    /// This will coerce non-integer numeric cases (e.g. `.double`) into an `Int` if such coercion would be lossless.
    public func asInt() -> Int? {
        switch self {
        case let .int32(value):
            return Int(value)
        case let .int64(value):
            return Int(exactly: value)
        case let .double(value):
            return Int(exactly: value)
        default:
            return nil
        }
    }

    /// Return this BSON as an `Int32` if possible.
    /// This will coerce numeric cases (e.g. `.double`) into an `Int32` if such coercion would be lossless.
    public func asInt32() -> Int32? {
        switch self {
        case let .int32(value):
            return value
        case let .int64(value):
            return Int32(exactly: value)
        case let .double(value):
            return Int32(exactly: value)
        default:
            return nil
        }
    }

    /// Return this BSON as an `Int64` if possible.
    /// This will coerce numeric cases (e.g. `.double`) into an `Int64` if such coercion would be lossless.
    public func asInt64() -> Int64? {
        switch self {
        case let .int32(value):
            return Int64(value)
        case let .int64(value):
            return value
        case let .double(value):
            return Int64(exactly: value)
        default:
            return nil
        }
    }

    /// Return this BSON as a `Double` if possible.
    /// This will coerce numeric cases (e.g. `.decimal128`) into a `Double` if such coercion would be lossless.
    public func asDouble() -> Double? {
        switch self {
        case let .double(d):
            return d
        default:
            guard let intValue = self.asInt() else {
                return nil
            }
            return Double(intValue)
        }
    }

    /// Return this BSON as a `Decimal128` if possible.
    /// This will coerce numeric cases (e.g. `.double`) into a `Decimal128` if such coercion would be lossless.
    public func asDecimal128() -> Decimal128? {
        switch self {
        case let .decimal128(d):
            return d
        case let .int64(i):
            return try? Decimal128(string: String(i))
        case let .int32(i):
            return try? Decimal128(string: String(i))
        case let .double(d):
            return try? Decimal128(string: String(d))
        default:
            return nil
        }
    }

    public func value<T: BSON>() -> T? {
        switch self {
        case .int32(let val):
            if T.self == Int.self && MemoryLayout<Int>.size == 4 {
                return Int(val) as? T
            }
            return val as? T
        case .int64(let val):
            if T.self == Int.self && MemoryLayout<Int>.size != 4 {
                return Int(val) as? T
            }
            return val as? T
        case .bool(let val):
            return val as? T
        case .double(let val):
            return val as? T
        case .string(let val):
            return val as? T
        case .binary(let val):
            return val as? T
        case .datetime(let val):
            return val as? T
        case .decimal128(let val):
            return val as? T
        case .objectId(let val):
            return val as? T
        case .document(let val):
            return val as? T
        case .array(let val):
            return val as? T
        case .maxKey:
            return MaxKey() as? T
        case .minKey:
            return MinKey() as? T
        case .regex(let val):
            return val as? T
        default:
            return nil
        }
    }
}

extension AnyBSON: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension AnyBSON: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

extension AnyBSON: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .double(value)
    }
}

extension AnyBSON: ExpressibleByIntegerLiteral {
    /// Initialize a `BSON` from an integer. On 64-bit systems, this will result in an `.int64`. On 32-bit systems,
    /// this will result in an `.int32`.
    public init(integerLiteral value: Int) {
        self.init(value)
    }
}

extension AnyBSON: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, AnyBSON)...) {
        self = .document(Document(uniqueKeysWithValues: elements))
    }
}

extension AnyBSON: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: AnyBSON...) {
        self = .array(elements)
    }
}

extension AnyBSON: Equatable {}

extension AnyBSON: Hashable {}

internal func BSONToRLMBSON(_ bson: AnyBSON?) -> RLMBSON? {
    switch bson {
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
    case .decimal128(let val):
        return val as RLMDecimal128
    case .objectId(let val):
        return val as RLMObjectId
    case .document(let val):
        return val as NSDictionary
    case .array(let val):
        return val as NSArray
    case .maxKey:
        return MaxKey()
    case .minKey:
        return MinKey()
    case .regex(let val):
        return val
    case .bool(let val):
        return val as NSNumber
    default:
        return nil
    }
}

internal func RLMBSONToBSON(_ bson: RLMBSON?) -> AnyBSON? {
    guard let bson = bson else {
        return nil
    }

    switch (bson.__bsonType) {
    case .null:
        return nil
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
        guard let val = bson as? Document else {
            return nil
        }
        return .document(val)
    case .array:
        guard let val = bson as? Array<AnyBSON> else {
            return nil
        }
        return .array(val)
    default:
        return nil
    }
}
