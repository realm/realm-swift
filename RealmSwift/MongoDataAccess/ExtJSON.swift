import Foundation

protocol ExtJSONBuiltin {
    static func initialize(from value: Any) throws -> Self
    var extJSONValue: any Codable { get }
}
protocol ExtJSONCodable: Codable, ExtJSONBuiltin {
    associatedtype ExtJSONValue: Codable
    init(from value: ExtJSONValue) throws
    var extJSONValue: ExtJSONValue { get }
}
extension ExtJSONCodable {
    static func initialize(from value: Any) throws -> Self {
        try Self.init(from: value as! ExtJSONValue)
    }
    var extJSONValue: any Codable { self.extJSONValue }
    var isLiteral: Bool {
        false
    }
}
extension ExtJSONCodable where ExtJSONValue == Self {
    init(from value: Self) throws {
        self = value//.array
    }
    var extJSONValue: Self {
        self//ExtJSONValue(array: self)
    }
    var isLiteral: Bool {
        true
    }
}
protocol ExtJSONSingleValue: ExtJSONBuiltin {
}
typealias ExtJSONSingleValueCodable = ExtJSONSingleValue & ExtJSONCodable
protocol ExtJSONKeyedValue: ExtJSONBuiltin {
}
protocol ExtJSONKeyedCodable: ExtJSONKeyedValue, ExtJSONCodable {
}
protocol ExtJSONUnkeyedValue: ExtJSONBuiltin {
}
protocol ExtJSONUnkeyedCodable: ExtJSONUnkeyedValue, ExtJSONCodable, Collection
where Element: ExtJSONCodable {
}

// MARK: Array
extension Array: ExtJSONUnkeyedCodable,
                    ExtJSONUnkeyedValue,
                    ExtJSONCodable,
                    ExtJSONBuiltin where Element: ExtJSONCodable {
    typealias ExtJSONValue = Self
}
extension List: ExtJSONUnkeyedCodable,
                ExtJSONUnkeyedValue,
                ExtJSONCodable,
                ExtJSONBuiltin where Element: ExtJSONCodable {
    typealias ExtJSONValue = List
}

// MARK: Optional
extension Optional: ExtJSONSingleValueCodable, ExtJSONBuiltin where Wrapped: ExtJSONCodable {
    typealias ExtJSONValue = Self
}
extension NSNull: ExtJSONSingleValue, ExtJSONBuiltin {
    static func initialize(from value: Any) throws -> Self {
        fatalError()
    }
    var extJSONValue: Codable {
        Optional<String>.none
    }
}
extension NSNumber: ExtJSONBuiltin {
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
    init(from value: Self) throws {
        self = value
    }
    var extJSONValue: Self {
        self
    }
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
//
// MARK: Date
extension Date : ExtJSONKeyedCodable {
    struct ExtJSONValue: Codable {
        enum CodingKeys: String, CodingKey { case date = "$date" }
        let date: Int64
    }
    init(from value: ExtJSONValue) throws {
        self.init(timeIntervalSince1970: TimeInterval(value.date) / 1_000)
    }
    var extJSONValue: ExtJSONValue {
        ExtJSONValue(date: Int64(self.timeIntervalSince1970 * 1_000.0))
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
