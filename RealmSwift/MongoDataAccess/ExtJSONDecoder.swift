import Foundation
import Combine

/// A decoder that converts ExtJSON data into Swift objects.
final public class ExtJSONDecoder {
    /// A dictionary for custom information that can be used during the decoding process.
    public var userInfo: [CodingUserInfoKey : Any] = [:]
    
    /// Initializes a new ExtJSONDecoder.
    public init() {
    }
}

extension ExtJSONDecoder: TopLevelDecoder {
    
    /// Decodes an instance of the specified type from ExtJSON data.
    ///
    /// - Parameters:
    ///   - type: The type of the value to decode.
    ///   - data: The ExtJSON data to decode from.
    /// - Returns: A decoded instance of the specified type.
    public func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable {
        try T(from: _ExtJSONDecoder(storage: try JSONSerialization.jsonObject(with: data, 
                                                                              options: .fragmentsAllowed),
                                    userInfo: self.userInfo))
    }
}

extension ExtJSONDecoder: @unchecked Sendable {
}

/**
 Underlying decoder for `ExtJSONDecoder`.
 
 Decoding process for `Person` where `Person` is defined as:
 
 ```swift
 struct Person : Codable, Equatable {
     struct Address : Codable, Equatable {
         let city: String
         let state: String
     }
     let name: String
     let age: Int
     let address: Address
 }
 ```
 ```
 +----------------------------+
 | ExtJSONDecoder             |
 | + func decode<Person>()    |
 +----------------------------+
 |
 | creates
 v
 +-------------------------------+
 | _ExtJSONDecoder               |
 | + container<KeyedContainer>   |
 +-------------------------------+
 |
 | creates
 v
 +-------------------------------------+
 | KeyedContainer<Person>              |
 | + func decode(name: String)         |
 | + func decode(age: Int)             |
 | + func decode(address: Address)     |
 +-------------------------------------+
 |
 | invokes
 v
 +-------------------------------------+
 | Person.init(from decoder: Decoder)  |
 | - Decodes name, age, address        |
 +-------------------------------------+
 |
 | decodes address
 v
 +-------------------------------------+
 | KeyedContainer<Address>             |
 | + func decode(city: String)         |
 | + func decode(state: String)        |
 +-------------------------------------+
 |
 | invokes
 v
 +-------------------------------------+
 | Address.init(from decoder: Decoder) |
 | - Decodes city, state               |
 +-------------------------------------+
 |
 +--------+--------+
 |                 |
 v                 v
 +------------+    +------------+
 | decode String|   | decode String|
 +------------+    +------------+
 ```
 1. ExtJSONDecoder.decode<Person>(): Initiates the decoding process for Person.
 2. _ExtJSONDecoder_ Creation: An _ExtJSONDecoder_ instance is created.
 3. KeyedContainer<Person> Creation: A KeyedContainer for Person is created to decode its properties.
 4. Person.init(from decoder: Decoder) Invocation: The initializer for Person is invoked, where name, age, and address are decoded.
 5. Address Decoding via KeyedContainer<Address>: For the address property, a KeyedContainer for Address is created.
 6. Address.init(from decoder: Decoder) Invocation: The initializer for Address is invoked to decode its properties, city and state.
 6. String Decoding: Finally, the city and state properties are decoded as strings.
 **/
private class _ExtJSONDecoder : Decoder {
    struct SingleValueContainer : SingleValueDecodingContainer {
        // MARK: SingleValueDecodingContainer
        var storage: Any?
        var codingPath: [CodingKey] = []
        
        init(storage: Any? = nil, codingPath: [CodingKey]) {
            self.storage = storage
            self.codingPath = codingPath
        }
        
        func decodeNil() -> Bool {
            storage == nil || storage is NSNull
        }
        
        func decode(_ type: Bool.Type) throws -> Bool {
            guard let storage = storage as? Bool else {
                throw DecodingError.typeMismatch(Bool.self, DecodingError.Context(codingPath: codingPath,
                                                                                  debugDescription: "Type of \(storage ?? "null") was not Bool"))
            }
            return storage
        }
        
        func decode(_ type: String.Type) throws -> String {
            guard let storage = storage as? String else {
                throw DecodingError.typeMismatch(String.self, DecodingError.Context(codingPath: codingPath,
                                                                                    debugDescription: "Type of \(storage ?? "null") was not String"))
            }
            return storage
        }
        
        func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            let decoder = _ExtJSONDecoder(storage: storage,
                                          codingPath: codingPath,
                                          userInfo: [:])
            switch type {
            case let type as any ExtJSONCodable.Type:
                func decode<V: ExtJSONCodable>(_ type: V.Type) throws -> V {
                    try V(from: V.ExtJSONValue(from: decoder))
                }
                return try decode(type) as! T
            default:
                return try T(from: decoder)
            }
        }
    }
    
    struct KeyedContainer<Key> : KeyedDecodingContainerProtocol where Key: CodingKey {
        // MARK: KeyedDecodingContainer
        let decoder: _ExtJSONDecoder
        let storage: Dictionary<String, Any>
        let codingPath: [CodingKey]
        
        init(superDecoder: _ExtJSONDecoder,
             codingPath: [CodingKey]) throws {
            guard let storage = superDecoder.storage as? Dictionary<String, Any> else {
                throw DecodingError.valueNotFound(Swift.type(of: superDecoder.storage),
                                                  DecodingError.Context(codingPath: codingPath,
                                                                        debugDescription: "Value \(superDecoder.storage.debugDescription) was not correct container type."))
            }
            self.storage = storage
            self.codingPath = codingPath
            self.decoder = superDecoder
        }
        
        var allKeys: [Key] {
            storage.keys.compactMap(Key.init)
        }
        
        func contains(_ key: Key) -> Bool {
            storage.index(forKey: key.stringValue) != nil
        }
        
        func decodeNil(forKey key: Key) throws -> Bool {
            storage.index(forKey: key.stringValue) == nil ||
            storage[key.stringValue] as? NSObject == NSNull()
        }
        
        func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
            try SingleValueContainer(storage: storage[key.stringValue],
                                     codingPath: codingPath).decode(type)
        }
        
        private func nestedCodingPath(forKey key: CodingKey) -> [CodingKey] {
            return self.codingPath + [key]
        }
        
        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type,
                                        forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            try _ExtJSONDecoder(storage: self.storage[key.stringValue],
                                codingPath: nestedCodingPath(forKey: key)).container(keyedBy: type)
        }
        
        func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
            fatalError()
        }
        
        func superDecoder() throws -> Decoder {
            decoder
        }
        
        func superDecoder(forKey key: Key) throws -> Decoder {
            _ExtJSONDecoder(storage: storage[key.stringValue])
        }
    }
    
    struct UnkeyedContainer : UnkeyedDecodingContainer {
        // MARK: UnkeyedDecodingContainer
        var codingPath: [CodingKey]
        
        var count: Int? {
            storage.count
        }
        
        var isAtEnd: Bool {
            storage.count <= self.currentIndex
        }
        
        private(set) var currentIndex: Int
        var storage: [Any?]
        fileprivate let userInfo: [CodingUserInfoKey: Any]
        
        init(storage: Any?,
             codingPath: [CodingKey],
             userInfo: [CodingUserInfoKey: Any]) throws {
            guard let storage = storage as? [Any] else {
                throw DecodingError.valueNotFound(type(of: storage),
                                                  DecodingError.Context(codingPath: codingPath,
                                                                        debugDescription: "Value \(storage.debugDescription) was not correct container type."))
            }
            self.storage = storage
            self.codingPath = codingPath
            self.currentIndex = 0
            self.userInfo = userInfo
        }
        
        mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            defer {
                self.currentIndex += 1
            }
            return try _ExtJSONDecoder.SingleValueContainer(storage: self.storage[self.currentIndex],
                                                            codingPath: codingPath).decode(type)
        }
        
        
        func decodeNil() throws -> Bool {
            storage[self.currentIndex] == nil || storage[self.currentIndex] is NSNull
        }
        
        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            fatalError()
        }
        
        func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
            try UnkeyedContainer(storage: storage[self.currentIndex],
                                 codingPath: self.codingPath,
                                 userInfo: userInfo)
        }
        
        func superDecoder() throws -> Decoder {
            _ExtJSONDecoder(storage: self.storage,
                            codingPath: self.codingPath,
                            userInfo: userInfo)
        }
    }
    
    let codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey : Any]
    fileprivate var storage: Any?
    
    init(storage: Any?,
         codingPath: [CodingKey] = [],
         userInfo: [CodingUserInfoKey : Any] = [:]) {
        self.codingPath = codingPath
        self.userInfo = userInfo
        self.storage = storage
    }
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        try KeyedDecodingContainer(Self.KeyedContainer(superDecoder: self,
                                                       codingPath: codingPath))
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        try UnkeyedContainer(storage: storage,
                             codingPath: codingPath,
                             userInfo: userInfo)
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        SingleValueContainer(storage: self.storage, codingPath: codingPath)
    }
}
