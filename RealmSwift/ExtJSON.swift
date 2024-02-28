import Foundation

extension Optional: ExtJSON {
}
extension Optional: ExtJSONLiteral, ExpressibleByExtJSONLiteral
where Wrapped: ExpressibleByExtJSONLiteral {
    public typealias ExtJSONValue = Optional<Wrapped.ExtJSONValue>
    
    public init(extJSONValue value: Optional<Wrapped.ExtJSONValue>) throws {
        if let value = value {
            self = try Wrapped(extJSONValue: value)
        } else {
            self = nil
        }
    }
    public var extJSONValue: Optional<Wrapped.ExtJSONValue> {
        if let wrapped = self {
            return wrapped.extJSONValue
        } else {
            return nil
        }
    }
}

// MARK: Int
extension Int: ExtJSONObjectRepresentable {
    public typealias ExtJSONValue = ExtJSONDocument
    
    public init(extJSONValue value: ExtJSONDocument) throws {
        guard let numberLong = value["$numberInt"] as? String,
            let number = Int(numberLong) else {
            throw JSONError.missingKey(key: "$numberInt")
        }
        self = number
    }
    
    public var extJSONValue: ExtJSONDocument {
        [
            "$numberInt": String(self)
        ]
    }
}

// MARK: Int64
extension Int64: ExtJSONObjectRepresentable {
    public init(extJSONValue value: ExtJSONDocument) throws {
        guard let numberLong = value["$numberLong"] as? String,
            let number = Int64(numberLong) else {
            throw JSONError.missingKey(key: "$numberLong")
        }
        self = number
    }
    
    public var extJSONValue: ExtJSONDocument {
        [
            "$numberLong": String(self)
        ]
    }
}

// MARK: ObjectId
extension ObjectId: ExtJSONObjectRepresentable {
    public convenience init(extJSONValue value: ExtJSONDocument) throws {
        guard let oid = value["$oid"] as? String else {
            throw JSONError.missingKey(key: "$oid")
        }
        try self.init(string: oid)
    }
    public var extJSONValue: ExtJSONDocument {
        [
            "$oid": self.stringValue
        ]
    }
}

// MARK: Double
extension Double: ExtJSONObjectRepresentable {
    public init(extJSONValue value: ExtJSONDocument) throws {
        guard let double = value["$numberDouble"] as? String else {
            throw JSONError.missingKey(key: "$numberDouble")
        }
        self.init(double)!
    }
    
    public var extJSONValue: ExtJSONDocument {
        [
            "$numberDouble": String(self)
        ]
    }
}

// MARK: Date
extension Date: ExtJSONObjectRepresentable {
    public init(extJSONValue value: ExtJSONDocument) throws {
        guard let date = value["$date"] as? NSDictionary,
           let epochString = date["$numberLong"] as? String,
           let epoch = Int64(epochString) else {
           throw JSONError.missingKey(key: "$date")
        }
        self.init(timeIntervalSince1970: TimeInterval(epoch)/1_000)
    }
    
    public var extJSONValue: ExtJSONDocument {
        [
            "$date": [
                "$numberLong": String(Int64(self.timeIntervalSince1970 * 1_000))
            ]
        ]
    }
}

// MARK: Data
extension Data: ExtJSONObjectRepresentable {
    public typealias ExtJSONValue = [String: Any]

    public init(extJSONValue value: ExtJSONValue) throws {
        guard let value = value["$binary"] as? [String: String],
              let value = value["base64"],
              let data = Data(base64Encoded: value) else {
            throw JSONError.missingKey(key: "base64")
        }
        self = data
    }
    
    public var extJSONValue: ExtJSONValue {
        [
            "$binary": ["base64": self.base64EncodedString()]
        ]
    }
}

extension Decimal128: ExtJSONObjectRepresentable {
    public typealias ExtJSONValue = [String: Any]
//    @BSONCodable public struct ExtJSONValue {
//        @BSONCodable(key: "numberDecimal") let numberDecimal: String
//    }
    public convenience init(extJSONValue value: ExtJSONValue) throws {
        fatalError()
//        try self.init(string: value.numberDecimal)
    }
    
    public var extJSONValue: ExtJSONValue {
        fatalError()
//        ExtJSONValue(numberDecimal: self.stringValue)
    }
}

//extension NSRegularExpression : ExtJSONObjectRepresentable {
//    public init(extJSONValue value: Dictionary<String, Any>) throws {
//        guard let regExDictionary = value["$regularExpression"] as? [String: String],
//              let pattern = regExDictionary["pattern"],
//              let options = regExDictionary["options"]
//        else {
//            throw JSONError.missingKey(key: "base64")
//        }
//        try self.init(pattern: pattern)
//    }
//    
//    public var extJSONValue: Dictionary<String, Any> {
//        [
//            "$regularExpression": ["pattern": "\(self.pattern)"]
//        ]
//    }
//}

@available(macOS 13.0, *)
extension Regex: ExtJSONObjectRepresentable {
    public init(extJSONValue value: Dictionary<String, Any>) throws {
        guard let regExDictionary = value["$regularExpression"] as? [String: String],
              let pattern = regExDictionary["pattern"],
              let options = regExDictionary["options"]
               else {
            throw JSONError.missingKey(key: "base64")
        }
        try self.init(pattern)
    }
    
    public var extJSONValue: Dictionary<String, Any> {
        [
            "$regularExpression": ["pattern": "\(self.regex)"]
        ]
    }
}

public protocol _ExtJSON {
    associatedtype ExtJSONValue: _ExtJSON
    init(extJSONValue value: ExtJSONValue) throws
    var extJSONValue: ExtJSONValue { get }
}

// MARK: Literal Conformance
public protocol _ExtJSONLiteral : _ExtJSON where ExtJSONValue == Self {
}
extension _ExtJSONLiteral {
}
extension String: _ExtJSONLiteral {
}
extension Bool: _ExtJSONLiteral {
}
// MARK: Array Conformance
//public protocol ExtJSONArrayRepresentable : MutableCollection, _ExtJSON where Element: _ExtJSON {
//    init()
//    associatedtype ExtJSONElement
//    init(extJSONValue value: [ExtJSONElement]) throws
//    var extJSONValue: [ExtJSONElement] { get }
//}
//public protocol ExtJSONObjectArrayRepresentable : ExtJSONArrayRepresentable
//    where Element: ExtJSONObjectRepresentable {
//    
//}
//public protocol ExtJSONLiteralArrayRepresentable : ExtJSONArrayRepresentable
//    where Element: _ExtJSONLiteral {
//    init(extJSONValue value: [Element]) throws
//    var extJSONValue: [Element] { get }
//}
//
//extension ExtJSONObjectArrayRepresentable where Self: MutableCollection {
//    init(extJSONValue value: [Element]) throws {}
//    var extJSONValue: [Element] {
//        []
//    }
//}
//extension Array: ExtJSONArrayRepresentable, _ExtJSON where Element: _ExtJSON {
//    public init(extJSONValue value: [Element.ExtJSONValue]) throws {
//        self.init()
//        try self.append(contentsOf: value.map(Element.init))
//    }
//    public var extJSONValue: [Element.ExtJSONValue] {
//        self.map(\.extJSONValue)
//    }
//}
//extension Array : ExtJSONObjectArrayRepresentable where Element: ExtJSONObjectRepresentable {
//}
//extension Array : ExtJSONLiteralArrayRepresentable where Element: _ExtJSONLiteral {
//}
//extension List: ExtJSONArrayRepresentable, _ExtJSON where Element: _ExtJSON {
//    public typealias ExtJSONValue = [Element.ExtJSONValue]
//    public convenience init(extJSONValue value: [Element.ExtJSONValue]) throws {
//        self.init()
//        try self.append(objectsIn: value.map(Element.init))
//    }
//    
//    public var extJSONValue: [Element.ExtJSONValue] {
//        self.map(\.extJSONValue)
//    }
//}
//
//// MARK: KeyValuePairs Conformance
//protocol ExtJSONDictionaryRepresentable : _ExtJSON {}
//extension Dictionary: ExtJSONDictionaryRepresentable, _ExtJSON where Key == String, Value: _ExtJSON {
//}
//
public protocol ExtJSONObjectRepresentable : ExpressibleByExtJSONLiteral where ExtJSONValue == [String: Any]  {
}

//extension MutableSet: ExtJSONArrayRepresentable where Element: ExtJSON {}
//extension MaxKey: ExtJSONObjectRepresentable {
//    public required init(extJSONValue value: Dictionary<String, Any>) throws {
//        
//    }
//    public var extJSONValue: Dictionary<String, Any> {
//        <#code#>
//    }
//    
//    
//}
//extension MinKey: ExtJSONObjectRepresentable {
//    
//}
/*
 expressibleByExtJsonLiteral
 –––––––
 extjsonliterals
 –––––––
 string
 bool
 array of any extjson
 document of any extjson
 
 extjsonobjectrepresentable
 –––––––
 int
 oid
 double
 data
 date
 
 extjsoncollection
 ––––––
 array of extended extjsonrep
 dictionary of extended extjsonrep
 */


public enum JSONError : Error {
    case missingKey(key: String)
    case invalidType(_ type: String)
}

