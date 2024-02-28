import Foundation
import Realm
import RealmSwift
import Realm.Private

public protocol BSONFilter {
    var documentRef: DocumentRef { get set }
    init()
    mutating func encode() -> RawDocument
}

public protocol ExtJSON {
}

public protocol ExpressibleByExtJSONLiteral : ExtJSON {
    associatedtype ExtJSONValue: ExtJSONLiteral
    init(extJSONValue value: ExtJSONValue) throws
    var extJSONValue: ExtJSONValue { get }
}

/**
 String
 Int
 Data
 Date
 Bool
 Double
 Long
 Optionals
 Any
 Dictionary<String, Any>
 Array<Any>
 */
public protocol ExtJSONLiteral : ExpressibleByExtJSONLiteral {
}

let extJSONTypes: [any ExtJSONObjectRepresentable.Type] = [
    Int.self,
    Int64.self,
    Double.self,
    ObjectId.self,
    Date.self
]

extension ExpressibleByExtJSONLiteral {
    public static func from<T>(any extJSONValue: any ExpressibleByExtJSONLiteral) throws -> T {
        if self is any ExpressibleByExtJSONLiteral {
            if let extJSONValue = extJSONValue as? ExtJSONDocument {
                for type in extJSONTypes {
                    do {
                        return try type.init(extJSONValue: extJSONValue) as! T
                    } catch {
                    }
                }
            }
            
            return extJSONValue as! T
        } else {
            return try Self.init(extJSONValue: extJSONValue as! ExtJSONValue) as! T
        }
    }
//    public static func from(any extJSONValue: any ExpressibleByExtJSONLiteral) throws -> Self {
//        try Self.init(extJSONValue: extJSONValue as! Self.ExtJSONValue)
//    }
}

extension ExtJSON {
}

extension ExtJSONDocument {
//    public subscript<T>(_ key: String) -> T where T: ExtJSONLiteral {
//        get throws {
//            try T.init(extJSONValue: self[key] as! Dictionary<String, Any>)
//        }
//    }

    public subscript<T>(extJSONKey key: String) -> T? {
        get throws {
            self[key] as? T
        }
    }
    public subscript<T>(extJSONKey key: String) -> T? where T: OptionalProtocol {
        get throws {
            if let value = self[key] {
                return value as? T
            } else {
                return nil
            }
        }
    }
    public subscript<T>(extJSONKey key: String) -> T where T: ExtJSONQueryRepresentable {
        get throws {
            try T.init(extJSONValue: self[key] as! ExtJSONDocument as! T.ExtJSONValue)
        }
    }
    public subscript<T>(extJSONKey key: String) -> Array<T>? where T: ExtJSONQueryRepresentable {
        get throws {
            return try (self[key] as! Array<[String: Any]>).map(T.init)
        }
    }
    public subscript(extJSONKey key: String) -> Any? {
        get throws {
            return self[key]
        }
    }
    // Special case for Any type
//    public subscript(key: String) -> Dictionary<String, any ExtJSON> {
//        get throws {
//            (self[key] as! Dictionary<String, any ExtJSON>).reduce(into: Dictionary<String, any ExtJSON>()) { partialResult, element in
//                partialResult[element.key] = element.value
//            }
//        }
//    }
}

extension String: ExtJSONLiteral {
    public init(extJSONValue value: Self) throws {
        self = value
    }
    public var extJSONValue: Self {
        self
    }
}

extension Bool: ExtJSONLiteral {
    public init(extJSONValue value: Self) throws {
        self = value
    }
    public var extJSONValue: Self {
        self
    }
}

extension NSNull: ExtJSON {
}

public struct ExtJSONSerialization {
    private init() {}
    public static func deserialize<T>(literal: Any) throws -> T {
        try deserialize(literal: literal as Any?) as! T
    }
    public static func deserialize<T>(literal: Any) throws -> T where T: ExtJSONObjectRepresentable {
//        let value: ExtJSONDocument = try deserialize(literal: literal)
        return try T.init(extJSONValue: literal as! ExtJSONDocument)
    }
    public static func deserialize<T>(literal: Any?) throws -> T? {
        try deserialize(literal: literal) as? T
    }
    public static func read<T>(from document: ExtJSONDocument, 
                               for key: String) throws -> T where T: ExtJSONLiteral {
        return document[key] as! T
    }
    public static func read<T>(from document: ExtJSONDocument,
                               for key: String) throws -> T where T: ExtJSONObjectRepresentable {
        return document[key] as! T
    }
    public static func read<T>(from document: ExtJSONDocument,
                               for key: String) throws -> T where T: ExtJSONQueryRepresentable {
        try T.init(extJSONValue: document[key] as! ExtJSONDocument)
    }
    public static func read<T>(from document: ExtJSONDocument,
                               for key: String) throws -> T? where T: ExtJSONQueryRepresentable {
        try? T.init(extJSONValue: document[key] as! ExtJSONDocument)
    }
    public static func read<T>(from document: ExtJSONDocument,
                               for key: String) throws -> [T] where T: ExtJSONQueryRepresentable {
        return try (document[key] as! Array<[String: Any]>).map(T.init)
    }
//    public static func read<C>(from document: ExtJSONDocument,
//                               for key: String) throws -> C where C: ExtJSONArrayRepresentable, C.Element: ExtJSONQueryRepresentable {
//        var c = C.init()
//        let parsed = (document[key] as! Array<[String: Any]>)
//        for i in 0..<parsed.count {
//            c[c.count as! C.Index] = try C.Element.init(from: parsed[i])
//        }
//        return c
//    }
    static let extJSONTypes: [any ExtJSONObjectRepresentable.Type] = {
        var types: [any ExtJSONObjectRepresentable.Type] = [
            Int.self, 
            Double.self,
            Int64.self,
            ObjectId.self,
            Date.self,
            Data.self,
            Decimal128.self,
        ]
        return types
    }()
    
    public static func deserialize(literal: Any?) throws -> Any? {
        switch literal {
        case let literal as String: return literal
        case let literal as Bool: return literal
        case let literal as NSDictionary:
            for type in extJSONTypes {
                do {
                    return try type.init(extJSONValue: literal as! Dictionary<String, Any>)
                } catch {
                }
            }
            return try literal.reduce(into: ExtJSONDocument()) { partialResult, element in
                partialResult[element.key as! String] = try deserialize(literal: element.value)
            }
        case let literal as NSArray:
            return try literal.map {
                try deserialize(literal: $0)
            }
        case let literal as [String : any ExtJSON]:
            return try literal.reduce(into: ExtJSONDocument()) { partialResult, element in
                partialResult[element.key] = try deserialize(literal: element.value)
            }
        case nil: 
            fallthrough
        case is NSNull:
            return Optional<Any>.none
        case let opt as Optional<Any>:
            return opt ?? nil
        case let literal as Int: return literal
        case let literal as Double: return literal
        case let literal as any OptionalProtocol:
            return literal
        default: throw JSONError.invalidType("\(type(of: literal))")
        }
    }
    public static func serialize(literal: Any?) throws -> Any? {
        switch literal {
        case let literal as String: return literal
        case let literal as Bool: return literal
        case let literal as any ExtJSONObjectRepresentable: return literal.extJSONValue
        case let literal as NSDictionary:
            return try literal.reduce(into: ExtJSONDocument()) { partialResult, element in
                partialResult[element.key as! String] = try serialize(literal: element.value)
            }
        case let literal as NSArray:
            return try literal.map {
                try serialize(literal: $0)
            }
        case let literal as [String : Any]:
            return try literal.reduce(into: ExtJSONDocument()) { partialResult, element in
                partialResult[element.key] = try serialize(literal: element.value)
            }
        case nil:
            fallthrough
        case is NSNull:
            return Optional<Any>.none
        case let literal as any OptionalProtocol:
            return literal
        default: fatalError()
        }
    }
    
    private static func deserialize(literal: NSDictionary) throws -> Any {
        try literal.reduce(into: ExtJSONDocument()) { partialResult, element in
            partialResult[element.key as! String] = try deserialize(literal: element.value)
        }
    }
    // anyL -> anyL:
    // t: literal -> t: literal
    // t: obj -> t: object
    
    public static func extJSONObject(with data: Data) throws -> Any {
        try deserialize(literal: try JSONSerialization.jsonObject(with: data))
    }
    public static func extJSONObject<T>(with data: Data) throws -> T where T : ExtJSONLiteral {
        try deserialize(literal: try JSONSerialization.jsonObject(with: data) as! T.ExtJSONValue)
    }
    public static func extJSONObject<T>(with data: Data) throws -> T where T: ExtJSONObjectRepresentable {
        let value = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
        return try T(extJSONValue: deserialize(literal: value) as! ExtJSONDocument)
    }
    public static func data(with extJSONObject: ExtJSONDocument) throws -> Data {
        try JSONSerialization.data(withJSONObject: extJSONObject.reduce(into: NSMutableDictionary()) { partialResult, element in
            partialResult[element.key] = try serialize(literal: element.value)
        })
    }
    public static func data(with extJSONObject: Any) throws -> Data {
        switch extJSONObject {
        case let object as [String : Encodable]:
            try JSONSerialization.data(withJSONObject: object.reduce(into: [String: Any](), {
                let encoder = _ExtJSONEncoder()
                try $1.value.encode(to: encoder)
                $0[$1.key] = encoder.container?.storage
            }))
//            try JSONSerialization.data(withJSONObject: object.reduce(into: NSMutableDictionary()) { partialResult, element in
//                partialResult[element.key] = try serialize(literal: element.value)
//            })
        case let array as NSArray:
            try JSONSerialization.data(withJSONObject: array.map { element in
                try serialize(literal: element)
            })
        default: throw JSONError.missingKey(key: "")
        }
    }
    public static func data<T>(with extJSONObject: T) throws -> Data where T: Encodable {
        try ExtJSONEncoder().encode(extJSONObject)
    }
}

//extension Dictionary: ExpressibleByExtJSONLiteral {
//    public typealias ExtJSONValue = Self
//    
//    public init(extJSONValue value: Self) throws {
//        self = value
//    }
//    public var extJSONValue: Self {
//        self
//    }
//}
extension Dictionary: ExtJSON {
}
extension Dictionary: ExtJSONLiteral, ExpressibleByExtJSONLiteral {
    public typealias ExtJSONValue = Self
    
    public init(extJSONValue value: Self) throws {
        self = value
    }
    public var extJSONValue: Self {
        self
    }
}
public typealias ExtJSONDocument = Dictionary<String, Any>

protocol _ExtJSONSequence : Collection where Element == any ExpressibleByExtJSONLiteral {

}
extension _ExtJSONSequence {
    public init(extJSONValue value: Self) throws {
        self = value
    }
    public var extJSONValue: Self {
        self
    }
}
// MARK: Array Conformance
extension Array: ExtJSON {
}

extension RealmSwift.List: ExtJSONLiteral, ExpressibleByExtJSONLiteral, ExtJSON
where Element: ExpressibleByExtJSONLiteral {
    public typealias ExtJSONValue = List
    
    public convenience init(extJSONValue value: List) throws {
        self.init(collection: value._rlmCollection)
    }
    public var extJSONValue: List {
        self
    }
}
public typealias ExtJSONArray = Array<any ExpressibleByExtJSONLiteral>
public protocol RawDocumentKey : RawRepresentable, CaseIterable where RawValue == String {
}

public protocol KeyPathIterable {
    static var keyPaths: [PartialKeyPath<Self> : String] { get }
}

public protocol ExtJSONQueryRepresentable : KeyPathIterable, ExtJSONObjectRepresentable {
}

struct Person: Codable {
    let name: String
    let age: Int
}

public typealias RawDocument = [String : Any]
@dynamicMemberLookup public struct RawDocumentFilter : BSONFilter {
    public init() {
        documentRef = DocumentRef()
    }
    
    public var documentRef: DocumentRef
    
    public func encode() -> RawDocument {
        self.documentRef.document
    }
    
    public subscript<V>(dynamicMember member: String) -> BSONQuery<V> {
        return BSONQuery(identifier: member, documentRef: documentRef)
    }
}

public class DocumentRef {
    public var document = RawDocument()
    
    public init() {}
}

public protocol BSONQueryable {
    associatedtype FieldType : ExpressibleByExtJSONLiteral
    var documentRef: DocumentRef { get }
    var key: String { get }
}

@dynamicMemberLookup public struct Filter<Value : ExtJSONQueryRepresentable> {
    var documentRef: DocumentRef = .init()
    
    public subscript<V>(dynamicMember member: KeyPath<Value, V>) -> BSONQuery<V> {
        guard let memberName = Value.keyPaths[member] else {
            fatalError()
        }
        var query = BSONQuery<V>(identifier: memberName, documentRef: documentRef)
        query.documentRef = documentRef
        return query
    }
}

@dynamicMemberLookup public struct BSONQuery<FieldType : ExpressibleByExtJSONLiteral> : BSONQueryable {
    public let identifier: String
    public fileprivate(set) var documentRef: DocumentRef
    public var key: String {
        prefix.isEmpty ? identifier : "\(prefix).\(identifier)"
    }
    fileprivate var prefix: String = ""
    
    public init(identifier: String, documentRef: DocumentRef) {
        self.identifier = identifier
        self.documentRef = documentRef
    }
    
    public static func ==(lhs: Self, rhs: FieldType) -> Self {
        lhs.documentRef.document[lhs.key] = rhs
        return lhs
    }
    
    public subscript<V>(dynamicMember member: KeyPath<FieldType, BSONQuery<V>>) -> BSONQuery<V>
    where FieldType : KeyPathIterable {
        guard let memberName = FieldType.keyPaths[member] else {
            fatalError()
        }
        var query = BSONQuery<V>(identifier: memberName, documentRef: documentRef)
        query.documentRef = documentRef
        return query
    }
}

public extension Collection where Element : ExpressibleByExtJSONLiteral {
    func contains(_ element: BSONQuery<Element>) -> BSONQuery<Element> {
        let raw: RawDocument = [
            "$in" : self.map({ $0 })
        ]
        element.documentRef.document[element.key] = raw
        return element
    }
}

public extension BSONQueryable where FieldType : Comparable {
    static func >(lhs: Self, rhs: FieldType) -> Self {
        lhs.documentRef.document[lhs.key] = [
            "$gt" : rhs
        ]
        return lhs
    }
    static func <(lhs: Self, rhs: FieldType) -> Self {
        lhs.documentRef.document[lhs.key] = [
            "$lt" : rhs
        ]
        return lhs
    }
    static func >=(lhs: Self, rhs: FieldType) -> Self {
        lhs.documentRef.document[lhs.key] = [
            "$gte" : rhs
        ]
        return lhs
    }
    static func <=(lhs: Self, rhs: FieldType) -> Self {
        lhs.documentRef.document[lhs.key] = [
            "$lte" : rhs
        ]
        return lhs
    }
    static func ||(lhs: Self, rhs: @autoclosure (() -> any BSONQueryable)) -> Self {
        let documentBeforeLogicalOr = lhs.documentRef.document
        lhs.documentRef.document.removeAll()
        let documentAfterLogicalOr = rhs().documentRef.document
        lhs.documentRef.document.removeAll()
        lhs.documentRef.document["$or"] = [
            documentBeforeLogicalOr,
            documentAfterLogicalOr
        ]
        return lhs
    }
    static func &&<U : BSONQueryable>(lhs: Self,
                                      rhs: @autoclosure (() -> U)) -> Self {
        let documentBeforeLogicalOr = lhs.documentRef.document
        lhs.documentRef.document.removeAll()
        let documentAfterLogicalOr = rhs().documentRef.document
        lhs.documentRef.document.removeAll()
        lhs.documentRef.document["$and"] = [documentBeforeLogicalOr, documentAfterLogicalOr]
        return lhs
    }
}

public extension BSONQuery where FieldType : Collection {
    func contains(_ element: FieldType.Element) {
        
    }
    func contains(_ other: FieldType) {
        
    }
}
//
//public extension BSONQuery where FieldType == String {
//    @available(macOS 13.0, *)
//    func contains(_ regex: some RegexComponent) -> Self {
////        self.documentRef.document[self.key] = regex.regex
//        return self
//    }
//}

public enum BSONError : Error {
    case missingKey(String)
    case invalidType(key: String)
}

public struct QueryObject {
}

enum AnyBSONKey : Codable {
    case string(String)
    case objectId(ObjectId)
    case int(Int)
    
    func encode(to encoder: Encoder) throws {
        switch self {
        case .string(let a0): try a0.encode(to: encoder)
        case .objectId(let a0): try a0.encode(to: encoder)
        case .int(let a0): try a0.encode(to: encoder)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        do {
            self = .string(try container.decode(String.self))
        } catch {
        }
        do {
            self = .int(try container.decode(Int.self))
        } catch {
        }
        self = .objectId(try container.decode(ObjectId.self))
    }
}

public struct InsertOneResult : Codable {
    let insertedId: AnyBSONKey
}

public struct MongoTypedCollection<T : Codable> {
    fileprivate let mongoCollection: RLMMongoCollection
    fileprivate let database: MongoDatabase
    fileprivate init(mongoCollection: RLMMongoCollection, database: MongoDatabase) {
        self.mongoCollection = mongoCollection
        self.database = database
    }
    
    struct Arguments : Codable {
        let database: String
        let collection: String
        let document: T
    }
    /// Encodes the provided value to BSON and inserts it. If the value is missing an identifier, one will be
    /// generated for it.
    /// - Parameters:
    ///   - object: object  A `T` value to insert.
    ///   - completion: The result of attempting to perform the insert. An Id will be returned for the inserted object on sucess
    @preconcurrency
    public func insertOne(_ object: T,
                          _ completion: @Sendable @escaping (Result<InsertOneResult, Error>) -> Void) -> Void {
        let data: Data
        do {
            var document = RawDocument()
            document["database"] = mongoCollection.databaseName
            document["collection"] = mongoCollection.name
            document["query"] = try ExtJSONEncoder().encode(object)
            data = try ExtJSONEncoder().encode([Arguments(database: mongoCollection.databaseName,
                                                         collection: mongoCollection.name,
                                                          document: object)])
        } catch {
            return completion(.failure(error))
        }

        mongoCollection.user.callFunctionNamed("insertOne",
                                               arguments: String(data: data, encoding: .utf8)!,
                                               serviceName: "mongodb-atlas", completionBlock: { data, error in
            guard let data = data else {
                guard let error = error else {
                    return completion(.failure(AppError(RLMAppError.Code.httpRequestFailed)))
                }
                return completion(.failure(error))
            }
            do {
                let object = try ExtJSONDecoder().decode(InsertOneResult.self, from: data.data(using: .utf8)!)
                completion(.success(object))
            } catch {
                return completion(.failure(error))
            }
        })
    }
    
    @_unsafeInheritExecutor
    @available(macOS 10.15, *)
    public func insertOne(_ object: T) async throws -> Any {
        try await withCheckedThrowingContinuation { continuation in
            insertOne(object) { returnValue in
                switch returnValue {
                case .success(let value):
                    continuation.resume(returning: value)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
//    
//    /// Encodes the provided values to BSON and inserts them. If any values are missing identifiers,
//    /// they will be generated.
//    /// - Parameters:
//    ///   - documents: The `Document` values in a bson array to insert.
//    ///   - completion: The result of the insert, returns an array inserted document ids in order.
//    @preconcurrency
//    public func insertMany(_ objects: [T],
//                           _ completion: @Sendable @escaping (Result<[AnyBSON], Error>) -> Void) -> Void {
//        let objects = objects.map {
//            var document = Document()
//            $0.encode(to: &document)
//            return document
//        }
//        mongoCollection.insertMany(objects, completion)
//    }
//    // MARK: Find
//    /// Finds the documents in this collection which match the provided filter.
//    /// - Parameters:
//    ///   - filter: A `Document` as bson that should match the query.
//    ///   - options: `FindOptions` to use when executing the command.
//    ///   - completion: The resulting bson array of documents or error if one occurs
//    @preconcurrency
//    public func find(filter: T.Filter? = nil,
//                     options: FindOptions = FindOptions(),
//                     _ completion: @Sendable @escaping (Result<[T], Error>) -> Void) -> Void {
//        var document = Document()
//        if var filter = filter {
//            document = filter.encode()
//        }
//        mongoCollection.find(filter: document, options: options, { result in
//            do {
//                completion(.success(try result.get().map { document in
//                    try T(from: document)
//                }))
//            } catch {
//                completion(.failure(error))
//            }
//        })
//    }
//    
//    public func find(options: FindOptions = FindOptions(),
//                     filter: ((inout T.Filter) -> any BSONQueryable)? = nil) async throws -> [T] {
//        try await withCheckedThrowingContinuation { continuation in
//            var query = T.Filter()
//            _ = filter?(&query)
//            find(filter: query, options: options) { returnValue in
//                switch returnValue {
//                case .success(let value):
//                    continuation.resume(returning: value)
//                case .failure(let error):
//                    continuation.resume(throwing: error)
//                }
//            }
//        }
//    }
//    
    // MARK: FindOne
    /// Returns one document from a collection or view which matches the
    /// provided filter. If multiple documents satisfy the query, this method
    /// returns the first document according to the query's sort order or natural
    /// order.
    /// - Parameters:
    ///   - filter: A `Document` as bson that should match the query.
    ///   - options: `FindOptions` to use when executing the command.
    ///   - completion: The resulting bson or error if one occurs
//    @preconcurrency
//    public func findOne(filter: T.Filter? = nil,
//                        options: FindOptions = FindOptions(),
//                        _ completion: @escaping @Sendable (Result<T?, Error>) -> Void) -> Void {
//        var document = RawDocument()
//        if var filter = filter {
//            document["query"] = filter.encode()
//        }
//        document["database"] = mongoCollection.databaseName
//        document["collection"] = mongoCollection.name
//        mongoCollection.user.callFunctionNamed("findOne",
//                                               arguments: document.syntaxView.description,
//                                               serviceName: mongoCollection.serviceName) { data, error in
//            guard let data = data,
//                  let view = ExtJSON(extJSON: data).parse(database: self.database) as? ObjectSyntaxView else {
//                guard let error = error else {
//                    return completion(.failure(AppError(RLMAppError.Code.httpRequestFailed)))
//                }
//                return completion(.failure(error))
//            }
//        }
//    }
    
    @dynamicMemberLookup struct Filter<T> where T: Codable {
        class Encoder : Swift.Encoder {
            class _KeyedEncodingContainer<Key>: Swift.KeyedEncodingContainerProtocol where Key: CodingKey {
                func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
                    fatalError()
                }
                
                func superEncoder() -> Swift.Encoder {
                    fatalError()
                }
                
                func superEncoder(forKey key: Key) -> Swift.Encoder {
                    fatalError()
                }
                
                var codingPath: [CodingKey]
                init(codingPath: [CodingKey]) {
                    self.codingPath = codingPath
                }
                func encodeNil(forKey key: Key) throws {
                    fatalError()
                }
                
                func encode(_ value: Bool, forKey key: Key) throws {
                    fatalError()
                }
                
                func encode(_ value: String, forKey key: Key) throws {
                    fatalError()
                }
                
                func encode(_ value: Double, forKey key: Key) throws {
                    fatalError()
                }
                
                func encode(_ value: Float, forKey key: Key) throws {
                    fatalError()
                }
                
                func encode(_ value: Int, forKey key: Key) throws {
                    fatalError()
                }
                
                func encode(_ value: Int8, forKey key: Key) throws {
                    fatalError()
                }
                
                func encode(_ value: Int16, forKey key: Key) throws {
                    fatalError()
                }
                
                func encode(_ value: Int32, forKey key: Key) throws {
                    fatalError()
                }
                
                func encode(_ value: Int64, forKey key: Key) throws {
                    fatalError()
                }
                
                func encode(_ value: UInt, forKey key: Key) throws {
                    fatalError()
                }
                
                func encode(_ value: UInt8, forKey key: Key) throws {
                    fatalError()
                }
                
                func encode(_ value: UInt16, forKey key: Key) throws {
                    fatalError()
                }
                
                func encode(_ value: UInt32, forKey key: Key) throws {
                    fatalError()
                }
                
                func encode(_ value: UInt64, forKey key: Key) throws {
                    fatalError()
                }
                
                func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
                    fatalError()
                }
                
                func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
                    fatalError()
                }
            }
            var codingPath: [CodingKey]
            
            var userInfo: [CodingUserInfoKey : Any]
            
            init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any]) {
                self.codingPath = codingPath
                self.userInfo = userInfo
            }
            
            func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
                fatalError()
            }
            
            func unkeyedContainer() -> UnkeyedEncodingContainer {
                fatalError()
            }
            
            func singleValueContainer() -> SingleValueEncodingContainer {
                fatalError()
            }
        }
        subscript<V>(dynamicMember member: KeyPath<T, V>) -> V {
            fatalError()
        }
    }
    struct D<T: Codable> : ExpressibleByDictionaryLiteral {
        typealias Key = PartialKeyPath<T>
        
        init(dictionaryLiteral elements: (PartialKeyPath<T>, F<T>)...) {
            
        }
    }
    func f(_ d: D<Person>) {
        f([
            \.name: F<Person>.name
        ])
    }
    
    @dynamicMemberLookup public struct F<V> {
        public static func greaterThan() -> Self {
            fatalError()
        }
        
        public static subscript<W>(dynamicMember member: KeyPath<V, W>) -> Self {
            fatalError()
        }
    }
//    public typealias Tuple<V> = (KeyPath<T, V>, F<V>)
//    public func findOne(options: FindOptions = FindOptions(),
//                                _ filter: T? = nil) async throws -> T? {
//        withCheckedThrowingContinuation { continuation in
//            findOne(nil) {
//                
//            }
//        }
//    }
    @_unsafeInheritExecutor
    @available(macOS 10.15, *)
    public func findOne(options: FindOptions = FindOptions(),
                        _ filter: T? = nil) async throws -> T? {
        let data: String = try await withCheckedThrowingContinuation { continuation in
            var document = RawDocument()
            if let filter = filter {
//                var filterDocument = Filter<T>()
//                _ = filter(&filterDocument)
                document["query"] = filter//filterDocument.documentRef.document
            }
            document["database"] = mongoCollection.databaseName
            document["collection"] = mongoCollection.name
            do {
                try mongoCollection.user.callFunctionNamed(
                    "findOne",
                    arguments: String(data: ExtJSONSerialization.data(with: [document]),
                                      encoding: .utf8)!,
                    serviceName: mongoCollection.serviceName) { data, error in
                        guard let data = data else {
                            guard let error = error else {
                                return continuation.resume(throwing: AppError(RLMAppError.Code.httpRequestFailed))
                            }
                            return continuation.resume(throwing: error)
                        }
                        continuation.resume(returning: data)
                    }
            } catch {
                return continuation.resume(throwing: error)
            }
        }
        do {
            return try ExtJSONDecoder().decode(T.self, from: data.data(using: .utf8)!)
        } catch {
            return nil
        }
    }
    
//    @_unsafeInheritExecutor
//    public func findOne(options: FindOptions = FindOptions(),
//                        _ filter: ((inout Filter<T>) -> any BSONQueryable)? = nil) async throws -> T? where T: ObjectBase {
//        let data: String = try await withCheckedThrowingContinuation { continuation in
//            var document = RawDocument()
//            if let filter = filter {
//                var filterDocument = Filter<T>()
//                _ = filter(&filterDocument)
//                
//                guard let schema = T.sharedSchema() else {
//                    fatalError()
//                }
//                let namesAndClassNames: [(String, String?)] = schema.properties.filter {
//                    if let objectClassName = $0.objectClassName, let schema = RLMSchema.partialPrivateShared().schema(forClassName: objectClassName), !schema.isEmbedded {
//                        return true
//                    }
//                    return false
//                }.map { ($0.name, $0.objectClassName) }
//                document["pipeline"] = [
//                    [
//                        "$match": filterDocument.documentRef.document,
////                        "$limit": 1
//                    ]
//                ]
//                + namesAndClassNames.map {
//                    ["$lookup": [
//                        "from": $0.1!,
//                        "localField": $0.0,
//                        "foreignField": "_id",
//                        "as": $0.0
//                    ]]
//                }
////                + namesAndClassNames.map {
////                    ["$unwind": "$\($0.0)"]//[
////                        "path":"$\($0.0)",
//////                        "includeArrayIndex": "0",
////                        "preserveNullAndEmptyArrays": true
////                    ]]
////                }
//            }
//            print(document.syntaxView.description)
//            document["database"] = mongoCollection.databaseName
//            document["collection"] = mongoCollection.name
//            mongoCollection.user.callFunctionNamed(
//                "aggregate",
//                arguments: [document].syntaxView.description,
//                serviceName: mongoCollection.serviceName) { data, error in
//                    guard let data = data else {
//                    guard let error = error else {
//                        return continuation.resume(throwing: AppError(RLMAppError.Code.httpRequestFailed))
//                    }
//                    return continuation.resume(throwing: error)
//                }
//                continuation.resume(returning: data)
//            }
//        }
//        let view = await ExtJSON(extJSON: data).parse(database: self.database)
//        guard let view = view as? RawArraySyntaxView else {
//            return nil
//        }
//        return try T.SyntaxView(from: view[0] as! RawObjectSyntaxView).rawDocumentRepresentable
//    }
//    //
//    //    /// Runs an aggregation framework pipeline against this collection.
//    //    /// - Parameters:
//    //    ///   - pipeline: A bson array made up of `Documents` containing the pipeline of aggregation operations to perform.
//    //    ///   - completion: The resulting bson array of documents or error if one occurs
//    //    @preconcurrency
//    //    public func aggregate(pipeline: [Document], _ completion: @escaping MongoFindBlock) {
//    //        let bson = pipeline.map(ObjectiveCSupport.convert)
//    //        __aggregate(withPipeline: bson) { documents, error in
//    //            if let bson = documents?.map(ObjectiveCSupport.convert) {
//    //                completion(.success(bson))
//    //            } else {
//    //                completion(.failure(error ?? Realm.Error.callFailed))
//    //            }
//    //        }
//    //    }
//    
//    /// Counts the number of documents in this collection matching the provided filter.
//    /// - Parameters:
//    ///   - filter: A `Document` as bson that should match the query.
//    ///   - limit: The max amount of documents to count
//    ///   - completion: Returns the count of the documents that matched the filter.
//    @preconcurrency
//    public func count(filter: T? = nil,
//                      limit: Int? = nil,
//                      _ completion: @escaping @Sendable (Result<Int, Error>) -> Void) -> Void {
//        var document = Document()
//        if let filter = filter {
//            filter.encode(to: &document)
//        }
//        mongoCollection.count(filter: document, limit: limit, completion)
//    }
//    
//    @_unsafeInheritExecutor
//    public func count(filter: T? = nil,
//                      limit: Int? = nil) async  throws -> Int {
//        try await withCheckedThrowingContinuation { continuation in
//            count(filter: filter, limit: limit) { returnValue in
//                switch returnValue {
//                case .success(let value):
//                    continuation.resume(returning: value)
//                case .failure(let error):
//                    continuation.resume(throwing: error)
//                }
//            }
//        }
//    }
//    
    /// Deletes a single matching document from the collection.
    /// - Parameters:
    ///   - filter: A `Document` as bson that should match the query.
    ///   - completion: The result of performing the deletion. Returns the count of deleted objects
    @preconcurrency
    public func deleteOne(filter: T? = nil,
                          _ completion: @escaping @Sendable (Result<Int, Error>) -> Void) -> Void {
        do {
            mongoCollection.deleteOneDocument(filter: [:], completion)
        } catch {
            
        }
    }
    
    @available(macOS 10.15, *)
    @_unsafeInheritExecutor
    public func deleteOne(filter: ((inout T) -> Bool)? = nil) async throws -> Int {
        try await withCheckedThrowingContinuation { continuation in
//            var query = T.Filter()
//            _ = filter?(&query)
            deleteOne(filter: nil) { returnValue in
                switch returnValue {
                case .success(let value):
                    continuation.resume(returning: value)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Deletes multiple documents
    /// - Parameters:
    ///   - filter: Document representing the match criteria
    ///   - completion: The result of performing the deletion. Returns the count of the deletion
    @preconcurrency
    public func deleteMany(filter: T? = nil,
                           _ completion: @escaping @Sendable (Result<Int, Error>) -> Void) -> Void {
//        var document = Document()
//        if var filter = filter {
//            document = filter.encode()
//        }
        mongoCollection.deleteManyDocuments(filter: [:], completion)
    }
    
    @_unsafeInheritExecutor
    @available(macOS 10.15, *)
    public func deleteMany(filter: T? = nil) async throws -> Int {
        try await withCheckedThrowingContinuation { continuation in
            deleteMany(filter: filter) { returnValue in
                switch returnValue {
                case .success(let value):
                    continuation.resume(returning: value)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

extension MongoDatabase {
//    fileprivate let mongoDatabase: RLMMongoDatabase
    public func collection<T: Codable>(named name: String, type: T.Type) -> MongoTypedCollection<T> {
        MongoTypedCollection<T>(mongoCollection: self.collection(withName: name),
                                database: self)
    }
}

public extension MongoClient {
//    func database(named name: String) -> MongoDatabase {
//        MongoDatabase(mongoDatabase: self.database(named: name))
//    }
}

//extension ExtJSON {
//    func parse(database: MongoDatabase) async -> any SyntaxView {
//        let ast = parse()
//        if let ast = ast as? any ObjectSyntaxView {
////            for field in ast.fieldList.fields where field.value is DBRefSyntaxView {
////                guard let dbRefView = field.value as? DBRefSyntaxView else {
////                    continue
////                }
////                guard let type = configuration.schema.first(where: {
////                    "\($0)" == dbRefView.collectionName.string
////                }) else {
////                    continue
////                }
////                
////                let collection = database.collection(named: dbRefView.collectionName.string, type: RawDocument.self)
////                await collection.findOne {
////                    $0._id == dbRefView._id.rawDocumentRepresentable
////                }
////            }
//        }
//        return ast
//    }
//}

@attached(extension, conformances: ExtJSONQueryRepresentable, names: prefixed(_), arbitrary)
@attached(member, 
          names: named(init(extJSONValue:)),
          prefixed(_), arbitrary, suffixed(Key))
@available(swift 5.9)
public macro BSONCodable() = #externalMacro(module: "MongoDataAccessMacros",
                                            type: "BSONCodableMacro")
//@attached(extension, conformances: ExtJSONQueryRepresentable, names: arbitrary)
//@attached(member, names: named(init(extJSONValue:)), named(rawDocument), arbitrary)
@attached(peer, names: suffixed(Key), prefixed(_))
@available(swift 5.9)
public macro BSONCodable(key: String) = #externalMacro(module: "MongoDataAccessMacros",
                                                       type: "BSONCodableMacro")
@attached(peer, names: suffixed(Key), prefixed(_))
@available(swift 5.9)
public macro BSONCodable(ignore: Bool) = #externalMacro(module: "MongoDataAccessMacros",
                                                          type: "BSONCodableMacro")

@attached(peer)
@available(swift 5.9)
public macro DocumentKey(_ key: String? = nil) = #externalMacro(module: "MongoDataAccessMacros",
                                                                type: "RawDocumentQueryRepresentableMacro")

