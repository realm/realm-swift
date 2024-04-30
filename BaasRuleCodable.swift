

import RealmSwift

class _ReverseDecoder : Decoder {
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        return KeyedDecodingContainer(Self.KeyedContainer(storage: storage,
                                                          codingPath: codingPath,
                                                          allKeys: []))
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        Self.UnkeyedContainer.init(storage: storage,
                                   codingPath: codingPath,
                                   currentIndex: 0)
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        SingleValueContainer(storage: storage, codingPath: codingPath)
    }
    
    var codingPath: [CodingKey] = []
    
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    var storage: RLMObjectSchema
    
    init(codingPath: [CodingKey],
         userInfo: [CodingUserInfoKey : Any],
         className: String) throws {
        self.codingPath = codingPath
        self.storage = RLMObjectSchema(className: className,
                                       objectClass: NSNull.self,
                                       properties: [])
    }
    
    class SingleValueContainer : SingleValueDecodingContainer {
        var storage: RLMObjectSchema
        var codingPath: [CodingKey] = []
        
        init(storage: RLMObjectSchema, codingPath: [CodingKey]) {
            self.storage = storage
            self.codingPath = codingPath
        }
        private func unwrap<T>(_ value: Any?) throws -> T {
            guard let value = value else {
                throw DecodingError.valueNotFound(T.self, .init(codingPath: codingPath,
                                                                debugDescription: ""))
            }
            guard let value = value as? T else {
                throw DecodingError.typeMismatch(T.self, .init(codingPath: codingPath,
                                                               debugDescription: ""))
            }
            return value
        }
        private func unwrapObject(_ value: Any?) throws -> [String : Any] {
            guard let value = value else {
                throw DecodingError.valueNotFound([String: Any].self, .init(codingPath: codingPath,
                                                                            debugDescription: ""))
            }
            guard let value = value as? [String: Any] else {
                throw DecodingError.typeMismatch([String: Any].self, .init(codingPath: codingPath,
                                                                           debugDescription: ""))
            }
            return value
        }
        
        func decodeNil() -> Bool {
            return storage == nil
        }
        
        func decode(_ type: Bool.Type) throws -> Bool {
            fatalError()
        }
        
        func decode(_ type: String.Type) throws -> String {
            return ""
        }
        
        func decode(_ type: Double.Type) throws -> Double {
            guard let stringValue = try unwrapObject(self.storage)["$numberDouble"] as? String else {
                throw DecodingError.typeMismatch([String: Any].self, .init(codingPath: codingPath,
                                                                           debugDescription: ""))
            }
            guard let doubleValue = Double(stringValue) else {
                throw DecodingError.typeMismatch([String: Any].self, .init(codingPath: codingPath,
                                                                           debugDescription: ""))
            }
            return doubleValue
        }
        
        func decode(_ type: Float.Type) throws -> Float {
            guard let stringValue = try unwrapObject(self.storage)["$numberDouble"] as? String else {
                throw DecodingError.typeMismatch([String: Any].self, .init(codingPath: codingPath,
                                                                           debugDescription: ""))
            }
            guard let floatValue = Float(stringValue) else {
                throw DecodingError.typeMismatch([String: Any].self, .init(codingPath: codingPath,
                                                                           debugDescription: ""))
            }
            return floatValue
        }
        
        func decode(_ type: Int.Type) throws -> Int {
            guard let stringValue = try unwrapObject(self.storage)["$numberInt"] as? String else {
                throw DecodingError.typeMismatch([String: Any].self, .init(codingPath: codingPath,
                                                                           debugDescription: ""))
            }
            guard let intValue = Int(stringValue) else {
                throw DecodingError.typeMismatch([String: Any].self, .init(codingPath: codingPath,
                                                                           debugDescription: ""))
            }
            return intValue
        }
        
        func decode(_ type: Int8.Type) throws -> Int8 {
            fatalError()
        }
        
        func decode(_ type: Int16.Type) throws -> Int16 {
            fatalError()
        }
        
        func decode(_ type: Int32.Type) throws -> Int32 {
            fatalError()
        }
        
        func decode(_ type: Int64.Type) throws -> Int64 {
            fatalError()
        }
        
        func decode(_ type: UInt.Type) throws -> UInt {
            fatalError()
        }
        
        func decode(_ type: UInt8.Type) throws -> UInt8 {
            fatalError()
        }
        
        func decode(_ type: UInt16.Type) throws -> UInt16 {
            fatalError()
        }
        
        func decode(_ type: UInt32.Type) throws -> UInt32 {
            fatalError()
        }
        
        func decode(_ type: UInt64.Type) throws -> UInt64 {
            fatalError()
        }
        
        func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            fatalError()
//            switch type {
//            case is any ExtJSONLiteral.Type:
//                return self.storage as! T
//            case let type as any ExtJSONObjectRepresentable.Type:
//                return try type.init(extJSONValue: self.storage as! Dictionary<String, Any>) as! T
//            default:
//                let decoder = try _ExtJSONDecoder(storage: storage as! [String: Any], codingPath: codingPath, userInfo: [:], container: nil)
//                return try T(from: decoder)
//            }
        }
    }
    
    class KeyedContainer<Key> : KeyedDecodingContainerProtocol
    where Key: CodingKey {
        var storage: RLMObjectSchema
        
        var codingPath: [CodingKey]
        var allKeys: [Key]
        
        init(storage: RLMObjectSchema, codingPath: [CodingKey], allKeys: [CodingKey]) {
            self.storage = storage
            self.codingPath = codingPath
            self.allKeys = allKeys as! [Key]
        }
        
        func contains(_ key: Key) -> Bool {
            true
        }
        
        var isOpt = false
        func decodeNil(forKey key: Key) throws -> Bool {
            isOpt = true
            return false
//            storage.index(forKey: key.stringValue) == nil ||
//                storage[key.stringValue] as? NSObject == NSNull()
        }
        
        func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
            fatalError()
//            storage[key.stringValue] as! Bool
        }
        
        func decode(_ type: String.Type, forKey key: Key) throws -> String {
            defer { isOpt = false }
            storage.properties.append(RLMProperty(name: key.stringValue,
                                                  type: .string,
                                                  objectClassName: nil,
                                                  linkOriginPropertyName: nil,
                                                  indexed: false,
                                                  optional: isOpt))
//            storage.storage.schema.properties[key.stringValue] = Rule.Schema.Property(bsonType: bsonType(.string),
//                                                            items: nil)
            return ""
        }
        
        func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
            storage.properties.append(RLMProperty(name: key.stringValue,
                                                  type: .double,
                                                  objectClassName: nil,
                                                  linkOriginPropertyName: nil,
                                                  indexed: false,
                                                  optional: false))
//            storage.storage.schema.properties[key.stringValue] = Rule.Schema.Property(bsonType: bsonType(.double),
//                                                            items: nil)
            return 0
        }
        
        func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
            storage.properties.append(RLMProperty(name: key.stringValue,
                                                  type: .float,
                                                  objectClassName: nil,
                                                  linkOriginPropertyName: nil,
                                                  indexed: false,
                                                  optional: false))
            return 0
        }
        
        func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
            defer { isOpt = false }
            storage.properties.append(RLMProperty(name: key.stringValue,
                                                  type: .int,
                                                  objectClassName: nil,
                                                  linkOriginPropertyName: nil,
                                                  indexed: false,
                                                  optional: isOpt))
            return 0
        }
        
        func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
            fatalError()
        }
        
        func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
            fatalError()
        }
        
        func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
            fatalError()
        }
        
        func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
            fatalError()
        }
        
        func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
            fatalError()
        }
        
        func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
            fatalError()
        }
        
        func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
            fatalError()
        }
        
        func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
            fatalError()
        }
        
        func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
            fatalError()
        }
        
        func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
            switch type {
            case is ObjectId.Type:
                storage.properties.append(RLMProperty(name: key.stringValue, 
                                                      type: .objectId,
                                                      objectClassName: nil,
                                                      linkOriginPropertyName: nil,
                                                      indexed: false,
                                                      optional: false))
                return ObjectId.generate() as! T
            case is Data.Type:
                storage.properties.append(RLMProperty(name: key.stringValue,
                                                      type: .data,
                                                      objectClassName: nil,
                                                      linkOriginPropertyName: nil,
                                                      indexed: false,
                                                      optional: false))
                return Data() as! T
            case is any Collection.Type:
                let property = RLMProperty(name: key.stringValue,
                                           type: .any,
                                           objectClassName: nil,
                                           linkOriginPropertyName: nil,
                                           indexed: false,
                                           optional: type is any OptionalProtocol.Type)
                property.array = true
                storage.properties.append(property)
            default:
                let property = RLMProperty(name: key.stringValue,
                                           type: .any,
                                           objectClassName: String(describing: type),
                                           linkOriginPropertyName: nil,
                                           indexed: false,
                                           optional: type is any OptionalProtocol.Type)
                property.dictionary = true
                storage.properties.append(property)
            }
            return try ReverseDecoder().decode(type).0
        }
        
        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            fatalError()
        }
        
        func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
            fatalError()
        }
        
        func superDecoder() throws -> Decoder {
            fatalError()
        }
        
        func superDecoder(forKey key: Key) throws -> Decoder {
            fatalError()
        }
        
        var data: Data {
            fatalError()
        }
    }
    
    class UnkeyedContainer : UnkeyedDecodingContainer {
        init(storage: RLMObjectSchema, codingPath: [CodingKey], currentIndex: Int) {
            self.storage = storage
            self.codingPath = codingPath
            self.currentIndex = currentIndex
        }
        func decode(_ type: String.Type) throws -> String {
            fatalError()
        }
        
        func decode(_ type: Double.Type) throws -> Double {
            fatalError()
        }
        
        func decode(_ type: Float.Type) throws -> Float {
            fatalError()
        }
        
        func decode(_ type: Int.Type) throws -> Int {
            fatalError()
        }
        
        func decode(_ type: Int8.Type) throws -> Int8 {
            fatalError()
        }
        
        func decode(_ type: Int16.Type) throws -> Int16 {
            fatalError()
        }
        
        func decode(_ type: Int32.Type) throws -> Int32 {
            fatalError()
        }
        
        func decode(_ type: Int64.Type) throws -> Int64 {
            fatalError()
        }
        
        func decode(_ type: UInt.Type) throws -> UInt {
            fatalError()
        }
        
        func decode(_ type: UInt8.Type) throws -> UInt8 {
            fatalError()
        }
        
        func decode(_ type: UInt16.Type) throws -> UInt16 {
            fatalError()
        }
        
        func decode(_ type: UInt32.Type) throws -> UInt32 {
            fatalError()
        }
        
        func decode(_ type: UInt64.Type) throws -> UInt64 {
            fatalError()
        }
        
        func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            defer {
                self.currentIndex += 1
            }
            fatalError()
//            switch type {
//            case is any ExtJSONLiteral.Type:
//                return self.storage[self.currentIndex] as! T
//            case let type as any ExtJSONObjectRepresentable.Type:
//                print("doing stuff")
//                return try type.init(extJSONValue: self.storage[self.currentIndex] as! Dictionary<String, Any>) as! T
//            default:
//                let decoder = try _ExtJSONDecoder(storage: self.storage[self.currentIndex] as! Dictionary<String, Any>, codingPath: codingPath, userInfo: [:], container: nil)
//                return try T.init(from: decoder)
//            }
        }
        
        var storage: RLMObjectSchema
        
        func decode(_ type: Bool.Type) throws -> Bool {
            fatalError()
        }
        
        typealias StorageType = [Any]
        
        var data: Data {
            fatalError()
        }
        
        var codingPath: [CodingKey]
        
        var count: Int? {
            return 0
        }
        
        var isAtEnd: Bool {
            true
        }
        
        var currentIndex: Int
        
        func decodeNil() throws -> Bool {
            fatalError()
        }
        
        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            fatalError()
        }
        
        func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
            fatalError()
        }
        
        func superDecoder() throws -> Decoder {
            fatalError()
        }
    }
}

final private class ReverseDecoder {
    public init() {
    }
    
    /**
     A dictionary you use to customize the encoding process
     by providing contextual information.
     */
    public var userInfo: [CodingUserInfoKey : Any] = [:]

    /**
     Returns a MessagePack-encoded representation of the value you supply.
     
     - Parameters:
        - value: The value to encode as MessagePack.
     - Throws: `EncodingError.invalidValue(_:_:)`
                if the value can't be encoded as a MessagePack object.
     */
    public func decode<T>(_ type: T.Type) throws -> (T, RLMObjectSchema) where T : Decodable {
        let decoder = try _ReverseDecoder(codingPath: [],
                                          userInfo: self.userInfo,
                                          className: String(describing: type))
        let t = try T(from: decoder)
        return (t, decoder.storage)
    }
}

/// MARK: Encoder
class _BaasRuleEncoder {
    var codingPath: [CodingKey] = []
    
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    var container: [String: Rule] = [:]
}
//
final class BaasRuleEncoder {
    public init() {}
    
    /**
     A dictionary you use to customize the encoding process
     by providing contextual information.
     */
    public var userInfo: [CodingUserInfoKey : Any] = [:]

    /**
     Returns a MessagePack-encoded representation of the value you supply.
     
     - Parameters:
        - value: The value to encode as MessagePack.
     - Throws: `EncodingError.invalidValue(_:_:)`
                if the value can't be encoded as a MessagePack object.
     */
    public func encode<T>(_ type: T.Type) throws -> RLMObjectSchema where T : Codable {
        let encoder = _BaasRuleEncoder()
        encoder.userInfo = self.userInfo
        let reverseDecoder = try ReverseDecoder().decode(type)
        let schema = reverseDecoder.1
        schema.primaryKeyProperty = schema.properties.first {
            $0.name == "_id"
        } ?? RLMProperty(name: "_id", 
                         type: .objectId,
                         objectClassName: nil,
                         linkOriginPropertyName: nil,
                         indexed: false,
                         optional: false)
        return schema
    }
}
