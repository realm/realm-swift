import Foundation

public protocol RawDocumentRepresentable {
    init(from scanner: inout Scanner) throws
    var jsonLiteralView: String { get }
}

public extension RawDocumentRepresentable {
    static func ==(lhs: Self, rhs: Self) -> Bool {
        if let rhs = rhs as? Self {
            return lhs.jsonLiteralView == rhs.jsonLiteralView
        } else {
            return false
        }
    }
}

public protocol ExtJSONRepresentable {
    var extJSONValue: Data { get throws }
}
extension Dictionary: ExtJSONRepresentable where Key == String, Value: Any {
    public var extJSONValue: Data {
        fatalError()
    }
}
extension Array: ExtJSONRepresentable where Element: Any {
    public var extJSONValue: Data {
        fatalError()
    }
}

public protocol ExtJSONLiteral : ExtJSONRepresentable {
}
extension ExtJSONLiteral {
    public var extJSONValue: Data {
        get throws {
            try ExtJSONSerialization.serialize(value: self)
        }
    }
}
extension String: ExtJSONLiteral {
    public var extJSONLiteralValue: ExtJSONLiteral { self }
}
extension Bool: ExtJSONLiteral {
    public var extJSONLiteralValue: ExtJSONLiteral { self }
}
extension NSDictionary: ExtJSONLiteral {
    public var extJSONLiteralValue: ExtJSONLiteral { self }
}
extension Dictionary: ExtJSONLiteral where Key == String, Value == any ExtJSONRepresentable {
    public var extJSONLiteralValue: ExtJSONLiteral { self }
}
extension Array: ExtJSONLiteral where Element == any ExtJSONRepresentable {
    public var extJSONLiteralValue: ExtJSONLiteral { self }
}

public protocol ExtJSONStructuredRepresentable : ExtJSONRepresentable {
    static var schema: [String : Any.Type] { get }
    init(from json: any ExtJSONRepresentable) throws
    var extJSONLiteralValue: ExtJSONLiteral { get }
}
extension ExtJSONStructuredRepresentable {
    public var extJSONValue: Data {
        get throws {
            try ExtJSONSerialization.serialize(value: self)
        }
    }
}
extension Dictionary: ExtJSONStructuredRepresentable where Key == String, Value: ExtJSONStructuredRepresentable {
    public static var schema: [String : any Any.Type] {
        [:]
    }
    
    public init(from json: any ExtJSONRepresentable) throws {
        guard let json = json as? [String : any ExtJSONRepresentable] else {
            fatalError()
        }
        self = try json.reduce(into: Self()) {
            $0[$1.key] = try Value(from: $1.value)
        }
    }
    
    public var extJSONLiteralValue: ExtJSONLiteral {
        self.reduce(into: NSMutableDictionary(), { partialResult, next in
            partialResult[next.key] = next.value.extJSONLiteralValue
        })
    }
}

extension Array: ExtJSONStructuredRepresentable where Element: ExtJSONStructuredRepresentable {
    public static var schema: [String : Any.Type] {
        [:]
    }
    public init(from json: any ExtJSONRepresentable) throws {
        guard let json = json as? NSArray else {
            fatalError()
        }
        self = try json.map({ $0 as! (any ExtJSONRepresentable) }).map {
            try ExtJSONSerialization.parse(object: $0 as! [String : Any],
                                           type: Element.self)
        }
    }
    public var extJSONLiteralValue: ExtJSONLiteral {
        self as NSArray
    }
}
extension List: ExtJSONStructuredRepresentable, ExtJSONRepresentable where Element: ExtJSONStructuredRepresentable {
    public static var schema: [String : Any.Type] {
        [:]
    }
    public convenience init(from json: any ExtJSONRepresentable) throws {
        guard let json = json as? [any ExtJSONRepresentable] else {
            fatalError()
        }
        self.init()
        self.append(objectsIn: try json.map(Element.init))
    }
    
    public var extJSONLiteralValue: ExtJSONLiteral {
        self.map(\.extJSONLiteralValue) as NSArray
    }
}
extension Int: ExtJSONStructuredRepresentable {
    public static var schema: [String : Any.Type] {
        ["$numberInt": String.self]
    }
    public init(from json: any ExtJSONRepresentable) throws {
        guard let json = json as? NSDictionary,
            let numberLong = json["$numberInt"] as? String,
            let number = Int(numberLong) else {
            throw JSONError.missingKey(key: "$numberInt")
        }
        self = number
    }
    public var extJSONLiteralValue: ExtJSONLiteral {
        [
            "$numberInt": "\(self)"
        ]
    }
}
extension Int64: ExtJSONStructuredRepresentable {
    public static var schema: [String : Any.Type] {
        ["$numberLong": String.self]
    }
    public init(from json: any ExtJSONRepresentable) throws {
        guard let json = json as? NSDictionary,
            let numberLong = json["$numberLong"] as? String,
            let number = Int64(numberLong) else {
            throw JSONError.missingKey(key: "$numberLong")
        }
        self = number
    }
    public var extJSONLiteralValue: ExtJSONLiteral {
        [
            "$numberLong": "\(self)"
        ]
    }
}
extension ObjectId: ExtJSONStructuredRepresentable {
    public static var schema: [String : Any.Type] {
        ["$oid": String.self]
    }
    public convenience init(from json: any ExtJSONRepresentable) throws {
        guard let json = json as? NSDictionary,
            let oid = json["$oid"] as? String else {
            throw JSONError.missingKey(key: "$oid")
        }
        try self.init(string: oid)
    }
    
    public var extJSONLiteralValue: ExtJSONLiteral {
        [
            "$oid": "\(self)"
        ]
    }
}

extension Double : ExtJSONStructuredRepresentable {
    public static var schema: [String : Any.Type] {
        ["$numberDouble": String.self]
    }
    public init(from json: any ExtJSONRepresentable) throws {
        guard let json = json as? NSDictionary,
            let oid = json["$numberDouble"] as? String else {
            throw JSONError.missingKey(key: "$numberDouble")
        }
        self.init(oid)!
    }
    public var extJSONLiteralValue: ExtJSONLiteral {
        [
            "$numberDouble": "\(self)"
        ]
    }
}

extension NSArray : ExtJSONLiteral {
    public var extJSONValue: Data {
        get throws {
            try ExtJSONSerialization.serialize(value: NSNull())
        }
    }
}

extension NSNull : ExtJSONLiteral {
    public var extJSONValue: Data {
        get throws {
            try ExtJSONSerialization.serialize(value: NSNull())
        }
    }
}

extension Optional : ExtJSONStructuredRepresentable,
                        ExtJSONRepresentable where Wrapped : ExtJSONStructuredRepresentable {
    public static var schema: [String : Any.Type] {
        [:]
    }
    
    public init(from json: any ExtJSONRepresentable) throws {
        guard !(json is NSNull) else {
            self.init(nilLiteral: ())
            return
        }
        self = try Wrapped(from: json)
    }
    
    public var extJSONLiteralValue: ExtJSONLiteral {
        self?.extJSONLiteralValue ?? NSNull()
    }
}

extension Date : ExtJSONStructuredRepresentable {
    public static var schema: [String : Any.Type] {
        [
            "$date": Int64.self
        ]
    }
    
    public init(from json: any ExtJSONRepresentable) throws {
        guard let json = json as? NSDictionary,
              let numberLongDictionary = json["$date"] as? NSDictionary,
            let epochString = numberLongDictionary["$numberLong"] as? String,
            let epoch = Int64(epochString) else {
            throw JSONError.missingKey(key: "$date")
        }
        self.init(timeIntervalSince1970: TimeInterval(epoch))
    }
    
    public var extJSONLiteralValue: ExtJSONLiteral {
        [
            "$date": Int64(self.timeIntervalSince1970).extJSONLiteralValue
        ]
    }
}

public class ExtJSONSerialization {
    static let extJSONTypes: [any ExtJSONStructuredRepresentable.Type] = [
        Int.self, ObjectId.self, Int64.self, Double.self, Date.self
    ]
    
    private static func parse(object: Any) -> Any? {
        switch object {
        case _ as NSNull: return nil
        case let object as [String : Any]:
            if let matching = Self.extJSONTypes.compactMap({
                try? $0.init(from: object)
            }).first {
                return matching
            } else {
                return object.reduce(into: [String : Any](), { partialResult, kvp in
                    partialResult[kvp.key] = parse(object: kvp.value)
                })
            }
        case let object as [Any]:
            return object.map(parse(object:))
        default: return object
        }
    }
    
    package static func jsonObject(with data: Data) throws -> Any? {
        let object = try JSONSerialization.jsonObject(with: data)
        return parse(object: object)
    }
    
    public static func parse<T : ExtJSONStructuredRepresentable>(object: [String : Any], type: T.Type = T.self) throws -> T {
        try T(from: object.keys.reduce(into: RawDocument()) { newObject, key in
            if let type = T.schema[key] as? any ExtJSONStructuredRepresentable.Type {
                if let value = object[key] as? [String: Any] {
                    newObject[key] = try parse(object: value, type: type)
                } else {
                    newObject[key] = try type.init(from: object[key] as! any ExtJSONRepresentable)
                }
            } else {
                newObject[key] = parse(object: object[key])
            }
        })
    }
    
    package static func jsonObject<T : ExtJSONStructuredRepresentable>(with data: Data,
                                                                       type: T.Type = T.self) throws -> T {
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String : Any] else {
            fatalError()
        }
        return try parse(object: object)
    }
    
    public static func read<T>(key: String, from document: [String : Any], type: T.Type = T.self) throws -> T {
        guard let value = document[key] as? T else {
            throw JSONError.missingKey(key: key)
        }
        return value
    }
    
    public static func read<T>(key: String, from document: [String : Any], type: Optional<T>.Type = Optional<T>.self) throws -> T? {
        guard let value = document[key] else {
            throw JSONError.missingKey(key: key)
        }
        return value as? T
    }
    
    public static func serialize<T: ExtJSONQueryRepresentable>(value: T) throws -> Data {
        try JSONSerialization.data(withJSONObject: T.keyPaths.reduce(into: [String : Any]()) { partialResult, kvp in
            let value = value[keyPath: kvp.key]
            if let value = value as? any ExtJSONQueryRepresentable {
                partialResult[kvp.value] = try serialize(value: value)
            } else if let value = value as? ExtJSONLiteral {
                partialResult[kvp.value] = try serialize(value: value)
            } else {
                partialResult[kvp.value] = value
            }
        })
    }
    public static func serialize<T: ExtJSONStructuredRepresentable>(value: T) throws -> Data {
        try JSONSerialization.data(withJSONObject: value.extJSONLiteralValue)
    }
    public static func serialize<T: ExtJSONLiteral>(value: T) throws -> Data {
        return try JSONSerialization.data(withJSONObject: value)
    }
    public static func write<T>(key: String, value: T, to document: inout [String : Any]) {
        if let value = value as? ExtJSONStructuredRepresentable {
            
        }
    }
}

enum JSONError : Error {
    case missingKey(key: String)
}

