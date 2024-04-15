import Foundation
import Realm

protocol ExtJSONSerializable {
    var extJSONValue: any Codable { get }
}

protocol ExtJSONCodable: Codable {
    associatedtype ExtJSONValue: Codable
    init(from value: ExtJSONValue) throws
    var extJSONValue: ExtJSONValue { get }
}
extension ExtJSONCodable {
    var extJSONValue: any Codable { self.extJSONValue }
}
extension ExtJSONCodable where ExtJSONValue == Self {
    init(from value: Self) throws {
        self = value//.array
    }
    var extJSONValue: Self {
        self
    }
}
protocol ExtJSONSingleValue: ExtJSONSerializable {
}
typealias ExtJSONSingleValueCodable = ExtJSONSingleValue & ExtJSONCodable
protocol ExtJSONKeyedValue: ExtJSONSerializable {
}
protocol ExtJSONKeyedCodable: ExtJSONKeyedValue, ExtJSONCodable {
}
protocol ExtJSONUnkeyedValue: ExtJSONSerializable {
}
protocol ExtJSONUnkeyedCodable: ExtJSONUnkeyedValue, ExtJSONCodable, Collection
where Element: ExtJSONCodable {
}

// MARK: Array
extension Array: ExtJSONUnkeyedCodable,
                 ExtJSONUnkeyedValue,
                 ExtJSONCodable,
                 ExtJSONSerializable where Element: ExtJSONCodable {
    typealias ExtJSONValue = Self
}
extension List: ExtJSONUnkeyedCodable,
                ExtJSONUnkeyedValue,
                ExtJSONCodable,
                ExtJSONSerializable where Element: ExtJSONCodable {
    typealias ExtJSONValue = List
}

// MARK: Dictionary
extension Dictionary: ExtJSONKeyedCodable,
                      ExtJSONCodable,
                      ExtJSONKeyedValue,
                      ExtJSONSerializable where Key == String, Value: ExtJSONCodable {
    typealias ExtJSONValue = Self
}

// MARK: Optional
extension Optional: ExtJSONSingleValueCodable, ExtJSONSerializable where Wrapped: ExtJSONCodable {
    typealias ExtJSONValue = Self
}
extension NSNull: ExtJSONSingleValue, ExtJSONSerializable {
    static func initialize(from value: Any) throws -> Self {
        fatalError()
    }
    var extJSONValue: Codable {
        Optional<String>.none
    }
}

// MARK: NSNumber
extension NSNumber: ExtJSONSerializable {
    static func initialize(from value: Any) -> Self {
        fatalError()
    }
    
    var extJSONValue: any Codable {
        if CFGetTypeID(self) == CFBooleanGetTypeID() {
            return self.boolValue
        }
        switch CFNumberGetType(self) {
        case .charType:
            return self.stringValue
        case .intType, .nsIntegerType:
            return self.intValue.extJSONValue
        case .shortType, .sInt8Type, .sInt16Type, .sInt32Type:
            return self.intValue.extJSONValue
        case .longType, .sInt64Type:
            return self.int64Value.extJSONValue
        case .doubleType, .float32Type, .float64Type, .cgFloatType, .floatType:
            return self.doubleValue.extJSONValue
        default: fatalError()
        }
    }
}
// MARK: String
extension String: ExtJSONSingleValueCodable {
    typealias ExtJSONValue = Self
}
extension NSString: ExtJSONSingleValue {
    static func initialize(from value: Any) throws -> Self {
        fatalError()
    }
    var extJSONValue: Codable {
        (self as String).extJSONValue
    }
}
// MARK: Bool
extension Bool: ExtJSONSingleValueCodable {
    typealias ExtJSONValue = Self
    init(from value: Self) throws {
        self = value
    }
    var extJSONValue: Self {
        self
    }
}
// MARK: Int
extension Int: ExtJSONKeyedCodable {
    struct ExtJSONValue: Codable {
        enum CodingKeys: String, CodingKey { case numberInt = "$numberInt" }
        let numberInt: String
    }
    init(from value: ExtJSONValue) throws {
        guard let value = Int(value.numberInt) else {
            throw DecodingError.valueNotFound(Self.self, DecodingError.Context(codingPath: [],
                                                                               debugDescription: ""))
        }
        self = value
    }
    var extJSONValue: ExtJSONValue {
        ExtJSONValue(numberInt: "\(self)")
    }
}
extension Int32: ExtJSONKeyedCodable {
    typealias ExtJSONValue = Int.ExtJSONValue
    init(from value: ExtJSONValue) throws {
        guard let value = Int32(value.numberInt) else {
            throw DecodingError.valueNotFound(Self.self, DecodingError.Context(codingPath: [],
                                                                               debugDescription: ""))
        }
        self = value
    }
    var extJSONValue: ExtJSONValue {
        ExtJSONValue(numberInt: "\(self)")
    }
}
// MARK: Int64
extension Int64 : ExtJSONKeyedCodable {
    struct ExtJSONValue: Codable {
        enum CodingKeys: String, CodingKey { case numberLong = "$numberLong" }
        let numberLong: String
    }
    init(from value: ExtJSONValue) throws {
        guard let value = Int64(value.numberLong) else {
            throw DecodingError.valueNotFound(Self.self, DecodingError.Context(codingPath: [],
                                                                               debugDescription: ""))
        }
        self = value
    }
    var extJSONValue: ExtJSONValue {
        ExtJSONValue(numberLong: "\(self)")
    }
}
// MARK: ObjectId
extension ObjectId: ExtJSONKeyedCodable {
    struct ExtJSONValue: Codable {
        enum CodingKeys: String, CodingKey { case oid = "$oid" }
        let oid: String
    }
    convenience init(from value: ExtJSONValue) throws {
        try self.init(string: value.oid)
    }
    var extJSONValue: ExtJSONValue {
        ExtJSONValue(oid: self.stringValue)
    }
}
// MARK: Double
extension Double: ExtJSONKeyedCodable {
    struct ExtJSONValue: Codable {
        enum CodingKeys: String, CodingKey { case numberDouble = "$numberDouble" }
        let numberDouble: String
    }
    init(from value: ExtJSONValue) throws {
        self = Double(value.numberDouble)!
    }
    var extJSONValue: ExtJSONValue {
        ExtJSONValue(numberDouble: String(self))
    }
}
// MARK: Decimal128
extension Decimal128: ExtJSONKeyedCodable {
    struct ExtJSONValue: Codable {
        enum CodingKeys: String, CodingKey { case numberDecimal = "$numberDecimal" }
        let numberDecimal: String
    }
    convenience init(from value: ExtJSONValue) throws {
        try self.init(string: value.numberDecimal)
    }
    var extJSONValue: ExtJSONValue {
        ExtJSONValue(numberDecimal: self.stringValue)
    }
}
// MARK: UUID
extension UUID: ExtJSONSingleValueCodable {
    typealias ExtJSONValue = String
    init(from value: String) throws {
        guard let uuid = UUID(uuidString: value) else {
            throw DecodingError.valueNotFound(Self.self, DecodingError.Context(codingPath: [],
                                                                               debugDescription: "\(value) not valid UUID"))
        }
        self = uuid
    }
    var extJSONValue: String {
        self.uuidString
    }
}
// MARK: Date
extension Date : ExtJSONKeyedCodable {
    struct ExtJSONValue: Codable {
        enum CodingKeys: String, CodingKey { case date = "$date" }
        let date: Int64
    }
    init(from value: ExtJSONValue) throws {
        self.init(timeIntervalSince1970: TimeInterval(value.date) * 1_000.0)
    }
    var extJSONValue: ExtJSONValue {
        ExtJSONValue(date: Int64(self.timeIntervalSince1970 / 1_000.0))
    }
}
extension NSDate: ExtJSONKeyedValue {
    static func initialize(from value: Any) throws -> Self {
        fatalError()
    }
    var extJSONValue: Codable {
        (self as Date).extJSONValue
    }
}

// MARK: Data
extension Data : ExtJSONKeyedCodable {
    struct ExtJSONValue: Codable {
        enum CodingKeys: String, CodingKey { case binary = "$binary" }
        struct Binary: Codable {
            let base64: String
            let subType: String
        }
        let binary: Binary
    }
    
    init(from value: ExtJSONValue) throws {
        guard let data = Data(base64Encoded: value.binary.base64) else {
            fatalError()
        }
        self = data
    }
    var extJSONValue: ExtJSONValue {
        ExtJSONValue(binary: ExtJSONValue.Binary(base64: self.base64EncodedString(), 
                                                 subType: "00"))
    }
}

// MARK: Regex
extension NSRegularExpression: ExtJSONKeyedValue {
    struct ExtJSONValue: Codable {
        enum CodingKeys: String, CodingKey {
            case regex = "$regex"
            case options = "$options"
        }
        let regex: String
        let options: String?
    }

    var extJSONValue: any Codable {
        ExtJSONValue(regex: self.pattern, options: self.options.rawValue.description)
    }
}

// MARK: MaxKey
extension MaxKey: ExtJSONSingleValue {
    struct ExtJSONValue: Codable {
        enum CodingKeys: String, CodingKey { case maxKey = "$maxKey" }
        let maxKey = 1
    }
    var extJSONValue: any Codable {
        ExtJSONValue()
    }
}

// MARK: MinKey
extension MinKey: ExtJSONSingleValue {
    struct ExtJSONValue: Codable {
        enum CodingKeys: String, CodingKey { case minKey = "$minKey" }
        let minKey: Int = 1
    }
    var extJSONValue: any Codable {
        ExtJSONValue()
    }
}
