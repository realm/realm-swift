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

// MARK: ExtJSON Object Representable

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
// TODO: Do
//extension Data: ExtJSONObjectRepresentable {
//}
extension Date: ExtJSONObjectRepresentable {
    public init(extJSONValue value: ExtJSONDocument) throws {
        guard let numberLongDictionary = value["$date"] as? NSDictionary,
            let epochString = numberLongDictionary["$numberLong"] as? String,
            let epoch = Int64(epochString) else {
            throw JSONError.missingKey(key: "$date")
        }
        self.init(timeIntervalSince1970: TimeInterval(epoch))
    }
    
    public var extJSONValue: ExtJSONDocument {
        [
            "$date": [
                "$numberLong": String(self.timeIntervalSince1970)
            ]
        ]
    }
}

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
}

