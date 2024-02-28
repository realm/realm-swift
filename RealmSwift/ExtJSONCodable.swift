import Foundation

// MARK: Decoder
class _ExtJSONDecoder : Decoder {
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        guard let storage = storage as? [String: Any] else {
            fatalError()
        }
        return KeyedDecodingContainer(Self.KeyedContainer(storage: storage,
                                                          codingPath: codingPath, 
                                                          allKeys: []))
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        Self.UnkeyedContainer.init(storage: storage as! [Any], codingPath: codingPath, currentIndex: 0)
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        SingleValueContainer(storage: storage, codingPath: codingPath)
    }
    
    var codingPath: [CodingKey] = []
    
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    var container: (any _ExtJSONContainer)?
    
    var storage: Any
    init(storage: Any, codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any], container: (any _ExtJSONContainer)?) throws {
        self.codingPath = codingPath
        self.userInfo = userInfo
        self.container = container
        self.storage = storage
    }
    class SingleValueContainer : SingleValueDecodingContainer {
        var storage: Any?
        var codingPath: [CodingKey] = []
        
        init(storage: Any? = nil, codingPath: [CodingKey]) {
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
            try unwrap(self.storage)
        }
        
        func decode(_ type: String.Type) throws -> String {
            try unwrap(self.storage)
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
            switch type {
            case is any ExtJSONLiteral.Type:
                return self.storage as! T
            case let type as any ExtJSONObjectRepresentable.Type:
                return try type.init(extJSONValue: self.storage as! Dictionary<String, Any>) as! T
            default:
                let decoder = try _ExtJSONDecoder(storage: storage as! [String: Any], codingPath: codingPath, userInfo: [:], container: nil)
                return try T(from: decoder)
            }
        }
    }
    
    class KeyedContainer<Key> : _ExtJSONContainer, KeyedDecodingContainerProtocol
    where Key: CodingKey {
        var storage: [String: Any]
        
        var codingPath: [CodingKey]
        var allKeys: [Key]
        
        init(storage: [String: Any], codingPath: [CodingKey], allKeys: [CodingKey]) {
            self.storage = storage
            self.codingPath = codingPath
            self.allKeys = allKeys as! [Key]
        }
        
        func contains(_ key: Key) -> Bool {
            storage.index(forKey: key.stringValue) != nil
        }
        
        func decodeNil(forKey key: Key) throws -> Bool {
            storage.index(forKey: key.stringValue) == nil ||
                storage[key.stringValue] as? NSObject == NSNull()
        }
        
        func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
            storage[key.stringValue] as! Bool
        }
        
        func decode(_ type: String.Type, forKey key: Key) throws -> String {
            storage[key.stringValue] as! String
        }
        
        func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
            guard let value = storage[key.stringValue] as? [String: String] else {
                throw DecodingError.typeMismatch(Int.self, .init(codingPath: codingPath, debugDescription: ""))
            }
            return Double(value["$numberDouble"]!)!
        }
        
        func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
            fatalError()
        }
        
        func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
            guard let value = storage[key.stringValue] as? [String: String] else {
                throw DecodingError.typeMismatch(Int.self, .init(codingPath: codingPath, debugDescription: ""))
            }
            return Int(value["$numberInt"]!)!
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
            guard let value = storage[key.stringValue] as? [String: String] else {
                throw DecodingError.typeMismatch(Int.self, .init(codingPath: codingPath, debugDescription: ""))
            }
            return Int64(value["$numberLong"]!)!
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
                guard let value = storage[key.stringValue] as? [String: String] else {
                    throw DecodingError.typeMismatch(ObjectId.self, .init(codingPath: codingPath, debugDescription: ""))
                }
                return try ObjectId(string: value["$oid"]!) as! T
            case is Data.Type:
                guard let value = storage[key.stringValue] as? [String: [String: String]],
                      let value = value["$binary"],
                      let value = value["base64"] else {
                    throw DecodingError.typeMismatch(ObjectId.self, .init(codingPath: codingPath, debugDescription: ""))
                }
                return Data(base64Encoded: value)! as! T
            case is any Collection.Type:
                let decoder = try _ExtJSONDecoder(storage: storage[key.stringValue] as! [Any], codingPath: codingPath, userInfo: [:], container: nil)
                return try T(from: decoder)
            case is any ExtJSONLiteral.Type:
                return self.storage[key.stringValue] as! T
            case let type as any ExtJSONObjectRepresentable.Type:
                print("doing stuff")
                return try type.init(extJSONValue: self.storage[key.stringValue] as! Dictionary<String, Any>) as! T
            default:
                let decoder = try _ExtJSONDecoder(storage: storage[key.stringValue] as! [String: Any], codingPath: codingPath, userInfo: [:], container: nil)
                return try T(from: decoder)
            }
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
    
    class UnkeyedContainer : _ExtJSONContainer, UnkeyedDecodingContainer {
        init(storage: [Any], codingPath: [CodingKey], currentIndex: Int) {
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
            switch type {
            case is any ExtJSONLiteral.Type: 
                return self.storage[self.currentIndex] as! T
            case let type as any ExtJSONObjectRepresentable.Type:
                print("doing stuff")
                return try type.init(extJSONValue: self.storage[self.currentIndex] as! Dictionary<String, Any>) as! T
            default:
                let decoder = try _ExtJSONDecoder(storage: self.storage[self.currentIndex] as! Dictionary<String, Any>, codingPath: codingPath, userInfo: [:], container: nil)
                return try T.init(from: decoder)
            }
        }
        
        var storage: [Any]
        
        func decode(_ type: Bool.Type) throws -> Bool {
            fatalError()
        }
        
        typealias StorageType = [Any]
        
        var data: Data {
            fatalError()
        }
        
        var codingPath: [CodingKey]
        
        var count: Int? {
            storage.count
        }
        
        var isAtEnd: Bool {
            storage.count <= self.currentIndex
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

final public class ExtJSONDecoder {
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
    public func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable {
        switch try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) {
        case let value as [String: Any]:
            let decoder = try _ExtJSONDecoder(storage: value,
                                              codingPath: [],
                                              userInfo: self.userInfo,
                                              container: nil)
            decoder.userInfo = self.userInfo
            return try T(from: decoder)
        default:
            throw DecodingError.valueNotFound(T.self, .init(codingPath: [],
                                                                      debugDescription: "Invalid input"))
        }

    }
}
// MARK: Encoder
class _ExtJSONEncoder {
    var codingPath: [CodingKey] = []
    
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    var container: (any _ExtJSONContainer)?
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
        encoder.userInfo = self.userInfo
        try value.encode(to: encoder)
        
        return try encoder.container!.data
    }
}

protocol _ExtJSONContainer {
//    var storage: [String: Any] { get }
    associatedtype StorageType
    var storage: StorageType { get }
    var data: Data { get throws }
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
        
        var data: Data {
            get throws {
                try JSONSerialization.data(withJSONObject: storage)
            }
        }
    }
}

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
    
    func encode(_ value: Double) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        self.storage = [
            "$numberDouble": value.description
        ]
    }
    
    func encode(_ value: Float) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        fatalError()
    }
    
    func encode<T>(_ value: T) throws where T : BinaryInteger & Encodable {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }
        
        switch value {
        case let value as Int:
            storage = [
                "$numberInt": value.description
            ]
        case let value as Int64:
            storage = [
                "$numberLong": value.description
            ]
        default:
            throw EncodingError.invalidValue(value,
                                             EncodingError.Context(codingPath: codingPath, debugDescription: "Invalid BinaryInteger type."))
        }
    }
    
    func encode(_ value: Int8) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }
        
        fatalError()
    }
    
    func encode(_ value: Int16) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        fatalError()
    }
    
    func encode(_ value: Int32) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        fatalError()
    }
    
    func encode(_ value: Int64) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }
        self.storage = [
            "$numberLong": value.description
        ]
    }
    
    func encode(_ value: UInt8) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }
        fatalError()
    }
    
    func encode(_ value: UInt16) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }
        fatalError()
    }
    
    func encode(_ value: UInt32) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }
        fatalError()
    }
    
    func encode(_ value: UInt64) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }
        fatalError()
    }
    
    func encode(_ value: Date) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }
        self.storage = [
            "$date": ["$numberLong": Int64(value.timeIntervalSince1970)]
        ]
    }
    
    func encode(_ value: Data) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }
        self.storage = [
            "$binary": ["base64": value.base64EncodedString()]
        ]
    }
    
    func encode(_ value: Decimal128) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }
        self.storage = [
            "$numberDecimal": value.stringValue
        ]
    }
    
    func encode(_ value: ObjectId) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }
        self.storage = [
            "$oid": value.stringValue
        ]
    }
    
    func encode<T>(_ value: T) throws where T : Encodable {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }
        let encoder = _ExtJSONEncoder()
        switch value {
//        case let value as ObjectId: 
//            self.storage = [
//                "$oid": value.stringValue
//            ]
        case let value as any ExtJSONObjectRepresentable:
            self.storage = value.extJSONValue
        case let value as Data:
            try encode(value)
        default:
            try value.encode(to: encoder)
            self.storage = encoder.container?.storage
        }
    }
}

extension _ExtJSONEncoder: Encoder {
    fileprivate func assertCanCreateContainer() {
        precondition(self.container == nil)
    }
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        assertCanCreateContainer()
        
        let container = KeyedContainer<Key>(codingPath: self.codingPath, userInfo: self.userInfo)
        self.container = container
        
        return KeyedEncodingContainer(container)
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        assertCanCreateContainer()
        
        let container = UnkeyedContainer(codingPath: self.codingPath, userInfo: self.userInfo)
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

// MARK: KeyedContainer
extension _ExtJSONEncoder {
    final class KeyedContainer<Key> : _ExtJSONContainer where Key: CodingKey {
        var storage: [String: any _ExtJSONContainer] = [:]
        
        var codingPath: [CodingKey]
        var userInfo: [CodingUserInfoKey: Any]
        
        func nestedCodingPath(forKey key: CodingKey) -> [CodingKey] {
            return self.codingPath + [key]
        }
        
        init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any]) {
            self.codingPath = codingPath
            self.userInfo = userInfo
        }
        var data: Data {
            get throws {
                try JSONSerialization.data(withJSONObject: storage.storage)
            }
        }
    }
}

extension _ExtJSONEncoder.KeyedContainer: KeyedEncodingContainerProtocol {
    func encodeNil(forKey key: Key) throws {
        var container = self.nestedSingleValueContainer(forKey: key)
        try container.encodeNil()
    }
    
    func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
        let container = _ExtJSONEncoder.SingleValueContainer(codingPath: self.nestedCodingPath(forKey: key),
                                                             userInfo: self.userInfo)
        try container.encode(value)
        self.storage[key.stringValue] = container
    }
    
    private func nestedSingleValueContainer(forKey key: Key) -> SingleValueEncodingContainer {
        let container = _ExtJSONEncoder.SingleValueContainer(codingPath: self.nestedCodingPath(forKey: key),
                                                             userInfo: self.userInfo)
        
        return container
    }
    
    func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        let container = _ExtJSONEncoder.UnkeyedContainer(codingPath: self.nestedCodingPath(forKey: key), userInfo: self.userInfo)
        self.storage[key.stringValue] = container

        return container
    }
    
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        let container = _ExtJSONEncoder.KeyedContainer<NestedKey>(codingPath: self.nestedCodingPath(forKey: key), userInfo: self.userInfo)
        self.storage[key.stringValue] = container

        return KeyedEncodingContainer(container)
    }
    
    func superEncoder() -> Encoder {
        fatalError("Unimplemented") // FIXME
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

extension AnyCodingKey: Hashable {
    var hashValue: Int {
        return self.intValue?.hashValue ?? self.stringValue.hashValue
    }
}

extension Array : _ExtJSONContainer where Element == any _ExtJSONContainer {
    var data: Data {
        get throws {
            fatalError()
        }
    }
    
    var storage: [Any] {
        self.map {
            if let value = $0.storage as? any _ExtJSONContainer {
                value.storage
            } else {
                $0.storage
            }
        }
    }
}
extension Dictionary : _ExtJSONContainer where Key == String, Value == any _ExtJSONContainer {
    var data: Data {
        get throws {
            fatalError()
        }
    }
    
    var storage: [String: Any] {
        self.reduce(into: [String: Any](), {
            if let value = $1.value.storage as? any _ExtJSONContainer {
                $0[$1.key] = value.storage
            } else {
                $0[$1.key] = $1.value.storage
            }
        })
    }
}

extension _ExtJSONEncoder {
    final class UnkeyedContainer : _ExtJSONContainer {
        var storage: [any _ExtJSONContainer] = []
        
        var count: Int {
            return storage.count
        }
        
        var codingPath: [CodingKey]
        
        var nestedCodingPath: [CodingKey] {
            return self.codingPath + [AnyCodingKey(intValue: self.count)!]
        }
        
        var userInfo: [CodingUserInfoKey: Any]
        
        init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any]) {
            self.codingPath = codingPath
            self.userInfo = userInfo
        }
        var data: Data {
            get throws {
                try JSONSerialization.data(withJSONObject: storage.storage)
            }
        }
    }
}

extension _ExtJSONEncoder.UnkeyedContainer: UnkeyedEncodingContainer {
    func encodeNil() throws {
        var container = self.nestedSingleValueContainer()
        try container.encodeNil()
    }
    
    func encode<T>(_ value: T) throws where T : Encodable {
        var container = self.nestedSingleValueContainer()
        try container.encode(value)
    }
    
    private func nestedSingleValueContainer() -> SingleValueEncodingContainer {
        let container = _ExtJSONEncoder.SingleValueContainer(codingPath: self.nestedCodingPath, userInfo: self.userInfo)
        self.storage.append(container)

        return container
    }
    
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        let container = _ExtJSONEncoder.KeyedContainer<NestedKey>(codingPath: self.nestedCodingPath,
                                                                  userInfo: self.userInfo)
        self.storage.append(container)
        
        return KeyedEncodingContainer(container)
    }
    
    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        let container = _ExtJSONEncoder.UnkeyedContainer(codingPath: self.nestedCodingPath, 
                                                         userInfo: self.userInfo)
        self.storage.append(container)
        
        return container
    }
    
    func superEncoder() -> Encoder {
        fatalError("Unimplemented") // FIXME
    }
}


//extension _MessagePackEncoder.KeyedContainer: _ExtJSONEncodingContainer {
//    var data: Data {
//        var data = Data()
//        
//        let length = storage.count
//        if let uint16 = UInt16(exactly: length) {
//            if length <= 15 {
//                data.append(0x80 + UInt8(length))
//            } else {
//                data.append(0xde)
//                data.append(contentsOf: uint16.bytes)
//            }
//        } else if let uint32 = UInt32(exactly: length) {
//            data.append(0xdf)
//            data.append(contentsOf: uint32.bytes)
//        } else {
//            fatalError()
//        }
//        
//        for (key, container) in self.storage {
//            let keyContainer = _MessagePackEncoder.SingleValueContainer(codingPath: self.codingPath, userInfo: self.userInfo)
//            try! keyContainer.encode(key.stringValue)
//            data.append(keyContainer.data)
//            
//            data.append(container.data)
//        }
//        
//        return data
//    }
//}
