import Foundation

extension CodingUserInfoKey {
    static var storage: CodingUserInfoKey {
        CodingUserInfoKey(rawValue: "__realm_storage")!
    }
    static var superCoder: CodingUserInfoKey {
        CodingUserInfoKey(rawValue: "__realm_super_coder")!
    }
}

// MARK: Decoder

final public class ExtJSONDecoder {
    public init() {
    }
    
    /**
     A dictionary you use to customize the encoding process
     by providing contextual information.
     */
    public var userInfo: [CodingUserInfoKey : Any] = [:]

    /**
     Returns an ExtJSON-encoded representation of the value you supply.
     
     - Parameters:
        - value: The value to encode as MessagePack.
     - Throws: `EncodingError.invalidValue(_:_:)`
                if the value can't be encoded as a MessagePack object.
     */
    public func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable {
        try T(from: _ExtJSONDecoder(storage: try JSONSerialization.jsonObject(with: data, 
                                                                              options: .fragmentsAllowed),
                                    userInfo: self.userInfo))
    }
}

private class _ExtJSONDecoder : Decoder {
    class SingleValueContainer : _ExtJSONContainer {
        var storage: Any?
        var codingPath: [CodingKey] = []
        
        init(storage: Any? = nil, codingPath: [CodingKey]) {
            self.storage = storage
            self.codingPath = codingPath
        }
    }
    
    class KeyedContainer<Key> : _ExtJSONContainer where Key: CodingKey {
        let storage: [String: Any]
        let codingPath: [CodingKey]
        let userInfo: [CodingUserInfoKey: Any]
        
        init(storage: [String: Any],
             codingPath: [CodingKey],
             userInfo: [CodingUserInfoKey: Any]) {
            self.storage = storage
            self.codingPath = codingPath
            self.userInfo = userInfo
        }
    }
    
    class UnkeyedContainer : _ExtJSONContainer {
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
        
        init(storage: [Any?], 
             codingPath: [CodingKey],
             userInfo: [CodingUserInfoKey: Any]) {
            self.storage = storage
            self.codingPath = codingPath
            self.currentIndex = 0
            self.userInfo = userInfo
        }
    }
    
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey : Any] = [:]
    var storage: Any?
    
    init(storage: Any?, 
         codingPath: [CodingKey] = [],
         userInfo: [CodingUserInfoKey : Any] = [:]) {
        self.codingPath = codingPath
        self.userInfo = userInfo
        self.userInfo[.storage] = storage
        self.userInfo[.superCoder] = self
        self.storage = storage
    }
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        guard let storage = storage as? [String: Any] else {
            fatalError()
        }
        return KeyedDecodingContainer(Self.KeyedContainer(storage: storage,
                                                          codingPath: codingPath,
                                                          userInfo: userInfo))
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        guard let storage = storage as? [Any] else {
            fatalError()
        }
        return UnkeyedContainer(storage: storage,
                                codingPath: codingPath,
                                userInfo: userInfo)
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        SingleValueContainer(storage: storage, codingPath: codingPath)
    }
}

extension _ExtJSONDecoder.SingleValueContainer: SingleValueDecodingContainer {
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
// MARK: KeyedDecodingContainer
extension _ExtJSONDecoder.KeyedContainer: KeyedDecodingContainerProtocol {
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
        try _ExtJSONDecoder.SingleValueContainer(storage: storage[key.stringValue],
                                                 codingPath: codingPath).decode(type)
    }
    
    private func nestedCodingPath(forKey key: CodingKey) -> [CodingKey] {
        return self.codingPath + [key]
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, 
                                    forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        KeyedDecodingContainer(_ExtJSONDecoder.KeyedContainer(storage: self.storage[key.stringValue] as! [String: Any],
                                                              codingPath: nestedCodingPath(forKey: key),
                                                              userInfo: userInfo))
    }
    
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        fatalError()
    }
    
    func superDecoder() throws -> Decoder {
        guard let decoder = self.userInfo[.superCoder] as? any Decoder else {
            throw DecodingError.valueNotFound(Decoder.self,
                                              DecodingError.Context(codingPath: codingPath, debugDescription: "Could not find reference to super decoder"))
        }
        return decoder
    }
    
    func superDecoder(forKey key: Key) throws -> Decoder {
        _ExtJSONDecoder(storage: storage[key.stringValue])
    }
}

extension _ExtJSONDecoder.UnkeyedContainer: UnkeyedDecodingContainer {
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
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
        fatalError()
    }
    
    func superDecoder() throws -> Decoder {
        guard let decoder = self.userInfo[.superCoder] as? any Decoder else {
            throw DecodingError.valueNotFound(Decoder.self,
                                              DecodingError.Context(codingPath: codingPath, debugDescription: "Could not find reference to super decoder"))
        }
        return decoder
    }
}

// MARK: - _ExtJSONEncoder
private class _ExtJSONEncoder {
    var codingPath: [CodingKey] = []
    
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    var container: (any _ExtJSONContainer)?
    
    init(codingPath: [CodingKey] = [],
         userInfo: [CodingUserInfoKey : Any] = [:]) {
        self.codingPath = codingPath
        self.userInfo = userInfo
        self.userInfo[.superCoder] = self
    }
}

final public class ExtJSONEncoder {
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
    public func encode<T>(_ value: T) throws -> Data where T : Encodable {
        let encoder = _ExtJSONEncoder()
        try value.encode(to: encoder)
        return try JSONSerialization.data(withJSONObject: encoder.container?.storage ?? NSNull())
    }
    
    /**
     Returns a MessagePack-encoded representation of the value you supply.
     
     - Parameters:
        - value: The value to encode as MessagePack.
     - Throws: `EncodingError.invalidValue(_:_:)`
                if the value can't be encoded as a MessagePack object.
     */
    func encode<T>(_ value: T) throws -> Any where T: ExtJSONBuiltin {
        let encoder = _ExtJSONEncoder()
        try value.extJSONValue.encode(to: encoder)
        return encoder.container?.storage as Any
    }
}

public protocol _ExtJSONContainer {
    associatedtype StorageType
    var storage: StorageType { get }
}

extension _ExtJSONEncoder {
    final class SingleValueContainer : _ExtJSONContainer {
        var storage: Any?
        
        fileprivate var canEncodeNewValue = true
        fileprivate func checkCanEncode(value: Any?) throws {
            guard self.canEncodeNewValue else {
                let context = EncodingError.Context(codingPath: self.codingPath, debugDescription: "Attempt to encode value through single value container when previously value already encoded.")
                throw EncodingError.invalidValue(value as Any, context)
            }
        }
        
        var codingPath: [CodingKey]
        var userInfo: [CodingUserInfoKey: Any]
        
        init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any]) {
            self.codingPath = codingPath
            self.userInfo = userInfo
        }
    }
}
// MARK: SingleValueEncodingContainer
extension _ExtJSONEncoder.SingleValueContainer: SingleValueEncodingContainer {
    func encodeNil() throws {
        try checkCanEncode(value: nil)
        defer { self.canEncodeNewValue = false }
        
        self.storage = NSNull()
    }
    
    func encode(_ value: Bool) throws {
        try checkCanEncode(value: nil)
        defer { self.canEncodeNewValue = false }

        self.storage = value
    }
    
    func encode(_ value: String) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }
        
        self.storage = value
    }
    
    func encode<T>(_ value: T) throws where T : Encodable {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }
        let encoder = _ExtJSONEncoder(codingPath: codingPath, userInfo: userInfo)
        switch value {
        case let value as any ExtJSONKeyedCodable:
            try value.extJSONValue.encode(to: encoder)
        case let value as any ExtJSONSingleValueCodable:
            return storage = value
        default:
            try value.encode(to: encoder)
        }
        self.storage = encoder.container?.storage
    }
}

extension _ExtJSONEncoder: Encoder {
    fileprivate func assertCanCreateContainer() {
        precondition(self.container == nil)
    }
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        assertCanCreateContainer()
        
        let container = KeyedContainer<Key>(codingPath: self.codingPath, 
                                            userInfo: self.userInfo)
        self.container = container
        
        return KeyedEncodingContainer(container)
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        assertCanCreateContainer()
        
        let container = UnkeyedContainer(codingPath: self.codingPath,
                                         userInfo: self.userInfo)
        self.container = container
        
        return container
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        assertCanCreateContainer()
        
        let container = SingleValueContainer(codingPath: self.codingPath, userInfo: self.userInfo)
        self.container = container
        
        return container
    }
}

extension _ExtJSONEncoder {
    final class KeyedContainer<Key> : _ExtJSONContainer where Key: CodingKey {
        var storage: [String: Any] = [:]
        
        var codingPath: [CodingKey]
        var userInfo: [CodingUserInfoKey: Any]
        
        init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any]) {
            self.codingPath = codingPath
            self.userInfo = userInfo
        }
    }
}

// MARK: KeyedEncodingContainer
extension _ExtJSONEncoder.KeyedContainer: KeyedEncodingContainerProtocol {
    private func nestedCodingPath(forKey key: CodingKey) -> [CodingKey] {
        return self.codingPath + [key]
    }
    
    func encodeNil(forKey key: Key) throws {
        var container = self.nestedSingleValueContainer(forKey: key)
        try container.encodeNil()
        self.storage[key.stringValue] = NSNull()
    }
    
    func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
        let container = _ExtJSONEncoder.SingleValueContainer(codingPath: self.nestedCodingPath(forKey: key),
                                                             userInfo: self.userInfo)
        try container.encode(value)
        self.storage[key.stringValue] = container.storage
    }
    
    private func nestedSingleValueContainer(forKey key: Key) -> SingleValueEncodingContainer {
        _ExtJSONEncoder.SingleValueContainer(codingPath: self.nestedCodingPath(forKey: key),
                                             userInfo: self.userInfo)
    }
    
    func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        let container = _ExtJSONEncoder.UnkeyedContainer(codingPath: self.nestedCodingPath(forKey: key),
                                                         userInfo: self.userInfo)
        self.storage[key.stringValue] = container.storage

        return container
    }
    
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, 
                                    forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        let container = _ExtJSONEncoder.KeyedContainer<NestedKey>(codingPath: self.nestedCodingPath(forKey: key), userInfo: self.userInfo)
        self.storage[key.stringValue] = container.storage

        return KeyedEncodingContainer(container)
    }
    
    func superEncoder() -> Encoder {
        guard let encoder = self.userInfo[.superCoder] as? any Encoder else {
            throwRealmException("Could not find reference to super encoder")
        }
        return encoder
    }
    
    func superEncoder(forKey key: Key) -> Encoder {
        fatalError("Unimplemented") // FIXME
    }
}

struct AnyCodingKey: CodingKey, Equatable {
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
    
    init<Key>(_ base: Key) where Key : CodingKey {
        if let intValue = base.intValue {
            self.init(intValue: intValue)!
        } else {
            self.init(stringValue: base.stringValue)!
        }
    }
}

extension _ExtJSONEncoder {
    fileprivate final class UnkeyedContainer : _ExtJSONContainer {
        var storage: [Any?] = []
        
        var codingPath: [CodingKey]
        
        var nestedCodingPath: [CodingKey] {
            return self.codingPath + [AnyCodingKey(intValue: self.count)!]
        }
        
        var userInfo: [CodingUserInfoKey: Any]
        
        init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any]) {
            self.codingPath = codingPath
            self.userInfo = userInfo
        }
    }
}

// MARK: UnkeyedEncodingContainer
extension _ExtJSONEncoder.UnkeyedContainer: UnkeyedEncodingContainer {
    var count: Int {
        return storage.count
    }
    
    func encodeNil() throws {
        self.storage.append(nil)
    }
    
    func encode<T>(_ value: T) throws where T : Encodable {
        let container = _ExtJSONEncoder.SingleValueContainer(codingPath: self.nestedCodingPath,
                                                             userInfo: self.userInfo)
        try container.encode(value)
        self.storage.append(container.storage)
    }
    
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        let container = _ExtJSONEncoder.KeyedContainer<NestedKey>(codingPath: self.nestedCodingPath,
                                                                  userInfo: self.userInfo)
        self.storage.append(container.storage)
        
        return KeyedEncodingContainer(container)
    }
    
    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        let container = _ExtJSONEncoder.UnkeyedContainer(codingPath: self.nestedCodingPath, 
                                                         userInfo: self.userInfo)
        self.storage.append(container.storage)

        return container
    }
    
    func superEncoder() -> Encoder {
        fatalError("Unimplemented") // FIXME
    }
}

// MARK: ExtJSONSerialization
public struct ExtJSONSerialization {
    private init() {}
    
    public static func extJSONObject(with data: Data) throws -> Any {
        func decode(_ object: Any) throws -> Any? {
            switch object {
            case let (key, value) as (String, Any):
                return (key, try decode(value))
            case let object as [String: Any]:
                return try (object.map(decode) as? [(String, Any)])
                    .map {
                        Dictionary(uniqueKeysWithValues: $0)
                    }
            case let object as [Any]:
                return try object.map(decode)
                //            case let object as (any _ExtJSON)?:
                //                return try object.map { try ExtJSONDecoder().decode(type(of: $0.extJSONValue),
                //                                                                    from: object) }
            default:
                guard let value = object as? Decodable else {
                    throw DecodingError.typeMismatch(type(of: object),
                                                     .init(codingPath: [],
                                                           debugDescription: String(describing: type(of: object))))
                }
                return try type(of: value).init(from: _ExtJSONDecoder(storage: value))
                //                return try ExtJSONDecoder().decode(type(of: value), from: value)
            }
        }
        return try decode(JSONSerialization.jsonObject(with: data)) as Any
    }
    
    public static func data(with extJSONObject: Any) throws -> Data {
        func encode(_ object: Any) throws -> Any? {
            switch object {
            case let (key, value) as (String, Any?):
                return (key, try value.map(encode) ?? NSNull())
            case let object as [String: Any]:
                return try (object.map(encode) as? [(String, Any?)])
                    .map {
                        Dictionary(uniqueKeysWithValues: $0)
                    }
            case let object as [Any]:
                return try object.map(encode)
            case let object as (any ExtJSONBuiltin)?:
                return try object.map { try ExtJSONEncoder().encode($0) }
            default:
                let encoder = _ExtJSONEncoder()
                guard let value = object as? Encodable else {
                    throw DecodingError.typeMismatch(type(of: object),
                                                     .init(codingPath: [],
                                                           debugDescription: String(describing: type(of: object))))
                }
                try value.encode(to: encoder)
                return encoder.container?.storage
            }
        }
        let encoded = try encode(extJSONObject)
        return try JSONSerialization.data(withJSONObject: encoded as Any)
    }
    
    public static func data<T>(with extJSONObject: T) throws -> Data where T: Encodable {
        try ExtJSONEncoder().encode(extJSONObject)
    }
}
