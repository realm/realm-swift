import Foundation
import Combine

/// An encoder that converts SwiftObjects into ExtJSON data.
final public class ExtJSONEncoder {
    /**
     A dictionary you use to customize the encoding process
     by providing contextual information.
     */
    public var userInfo: [CodingUserInfoKey : Any] = [:]
    
    /// Initializes a new ExtJSONEncoder.
    public init() {}
}

extension ExtJSONEncoder: TopLevelEncoder {
    
    /**
     Returns a MessagePack-encoded representation of the value you supply.
     
     - Parameters:
     - value: The value to encode as MessagePack.
     - Throws: `EncodingError.invalidValue(_:_:)`
     if the value can't be encoded as a MessagePack object.
     */
    public func encode<T>(_ value: T) throws -> Data where T : Encodable {
        let encoder = _ExtJSONEncoder()
        if let value = value as? any ExtJSONCodable {
            try value.extJSONValue.encode(to: encoder)
        } else {
            try value.encode(to: encoder)
        }
        return try JSONSerialization.data(withJSONObject: encoder.container?.storage ?? NSNull(),
                                          options: .fragmentsAllowed.union(.sortedKeys))
    }
}

private class _ExtJSONEncoder: Encoder {
    protocol Container {
        associatedtype StorageType
        var storage: StorageType { get }
    }
    
    var codingPath: [CodingKey] = []
    
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    private(set) var container = Optional<any Container>.none
    
    init(codingPath: [CodingKey] = [],
         userInfo: [CodingUserInfoKey : Any] = [:]) {
        self.codingPath = codingPath
        self.userInfo = userInfo
    }
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        let container = KeyedContainer<Key>(codingPath: self.codingPath,
                                            userInfo: self.userInfo)
        self.container = container
        
        return KeyedEncodingContainer(container)
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        let container = UnkeyedContainer(codingPath: self.codingPath,
                                         userInfo: self.userInfo)
        self.container = container
        
        return container
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        let container = SingleValueContainer(codingPath: self.codingPath, userInfo: self.userInfo)
        self.container = container
        return container
    }
}

extension _ExtJSONEncoder {
    final class SingleValueContainer : Container {
        var storage: Any?
        
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
        self.storage = NSNull()
    }
    
    func encode(_ value: Bool) throws {
        self.storage = value
    }
    
    func encode(_ value: String) throws {
        self.storage = value
    }
    
    func encode<T>(_ value: T) throws where T : Encodable {
        let encoder = _ExtJSONEncoder(codingPath: codingPath,
                                      userInfo: userInfo)
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

extension _ExtJSONEncoder {
    final class KeyedContainer<Key> : Container where Key: CodingKey {
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
        _ExtJSONEncoder(codingPath: codingPath, userInfo: userInfo)
    }
    
    func superEncoder(forKey key: Key) -> Encoder {
        _ExtJSONEncoder(codingPath: codingPath, userInfo: userInfo)
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
    fileprivate final class UnkeyedContainer : Container {
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
        storage.count
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
        _ExtJSONEncoder(codingPath: codingPath, userInfo: userInfo)
    }
}

// MARK: ExtJSONSerialization
public struct ExtJSONSerialization {
    private init() {}
    
    public static func data<T>(with extJSONObject: T) throws -> Data where T: Encodable {
        try ExtJSONEncoder().encode(extJSONObject)
    }
}
