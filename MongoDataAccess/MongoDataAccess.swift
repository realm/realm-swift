import Foundation
import Realm
@_exported import RealmSwift
import Realm.Private

public protocol BSONFilter {
    var documentRef: DocumentRef { get set }
    init()
    mutating func encode() -> Document
}

public protocol BSONCodable : BSON {
    associatedtype Filter: BSONFilter
    init(from document: Document) throws
    func encode(to document: inout Document)
}

public class DocumentRef {
    public var document = Document()
    
    public init() {}
}

@dynamicMemberLookup public struct BSONQuery<T : BSON> {
    public let identifier: String
    public var documentRef: DocumentRef
    fileprivate var prefix: String = ""
    
    fileprivate var key: String {
        prefix.isEmpty ? identifier : "\(prefix).\(identifier)"
    }
    
    public init(identifier: String, documentRef: DocumentRef) {
        self.identifier = identifier
        self.documentRef = documentRef
    }
    
    public static func ==(lhs: BSONQuery<T>, rhs: T) -> Bool {
        lhs.documentRef.document[lhs.key] = AnyBSON(rhs)
        return true
    }
    
    public subscript<V>(dynamicMember member: KeyPath<T.Filter, BSONQuery<V>>) -> BSONQuery<V> where T : BSONCodable {
        var filter = T.Filter()
        filter.documentRef = documentRef
        var query = filter[keyPath: member]
        query.documentRef = documentRef
        query.prefix = identifier
        return query
    }
}

public extension BSONQuery where T : Comparable {
    static func >(lhs: inout BSONQuery<T>, rhs: T) -> Bool {
        lhs.documentRef.document[lhs.key] = [
            "$gt" : AnyBSON(rhs)
        ]
        return true
    }
    static func <(lhs: inout BSONQuery<T>, rhs: T) -> Bool {
        lhs.documentRef.document[lhs.key] = [
            "$lt" : AnyBSON(rhs)
        ]
        return true
    }
    static func >=(lhs: inout BSONQuery<T>, rhs: T) -> Bool {
        lhs.documentRef.document[lhs.key] = [
            "$gte" : AnyBSON(rhs)
        ]
        return true
    }
    static func <=(lhs: inout BSONQuery<T>, rhs: T) -> Bool {
        lhs.documentRef.document[lhs.key] = [
            "$lte" : AnyBSON(rhs)
        ]
        return true
    }
}

public enum BSONError : Error {
    case missingKey(String)
    case invalidType(key: String)
}

extension AnyBSON {
    public init(_ string: String) {
        self = .string(string)
    }
    
    public init(_ object: any BSONCodable) {
        var document = Document()
        object.encode(to: &document)
        self = .document(document)
    }
    /// Return this BSON as a `T` if possible, otherwise nil.
    public func `as`<T: BSON>() throws -> T? {
        if let C = T.self as? any BSONCodable.Type, case let .document(document) = self {
            return try C.init(from: document) as? T
        }
        return self.value()
    }
}

public struct MongoCollection<T: BSONCodable> {
    fileprivate let mongoCollection: RLMMongoCollection
    fileprivate init(mongoCollection: RLMMongoCollection) {
        self.mongoCollection = mongoCollection
    }
    
    /// Encodes the provided value to BSON and inserts it. If the value is missing an identifier, one will be
    /// generated for it.
    /// - Parameters:
    ///   - object: object  A `T` value to insert.
    ///   - completion: The result of attempting to perform the insert. An Id will be returned for the inserted object on sucess
    @preconcurrency
    public func insertOne(_ object: T,
                          _ completion: @Sendable @escaping (Result<AnyBSON, Error>) -> Void) -> Void {
        var document = Document()
        object.encode(to: &document)
        mongoCollection.insertOne(document, completion)
    }
    
    @_unsafeInheritExecutor
    public func insertOne(_ object: T) async throws -> AnyBSON {
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
    
    /// Encodes the provided values to BSON and inserts them. If any values are missing identifiers,
    /// they will be generated.
    /// - Parameters:
    ///   - documents: The `Document` values in a bson array to insert.
    ///   - completion: The result of the insert, returns an array inserted document ids in order.
    @preconcurrency
    public func insertMany(_ objects: [T],
                                     _ completion: @Sendable @escaping (Result<[AnyBSON], Error>) -> Void) -> Void {
        let objects = objects.map {
            var document = Document()
            $0.encode(to: &document)
            return document
        }
        mongoCollection.insertMany(objects, completion)
    }
    
    /// Finds the documents in this collection which match the provided filter.
    /// - Parameters:
    ///   - filter: A `Document` as bson that should match the query.
    ///   - options: `FindOptions` to use when executing the command.
    ///   - completion: The resulting bson array of documents or error if one occurs
    @preconcurrency
    public func find(filter: T.Filter? = nil,
                     options: FindOptions = FindOptions(),
                     _ completion: @Sendable @escaping (Result<[T], Error>) -> Void) -> Void {
        var document = Document()
        if var filter = filter {
            document = filter.encode()
        }
        mongoCollection.find(filter: document, options: options, { result in
            do {
                completion(.success(try result.get().map { document in
                    try T(from: document)
                }))
            } catch {
                completion(.failure(error))
            }
        })
    }
    
    public func find(options: FindOptions = FindOptions(),
                     filter: ((inout T.Filter) -> Bool)? = nil) async throws -> [T] {
        try await withCheckedThrowingContinuation { continuation in
            var query = T.Filter()
            _ = filter?(&query)
            find(filter: query, options: options) { returnValue in
                switch returnValue {
                case .success(let value):
                    continuation.resume(returning: value)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    /// Returns one document from a collection or view which matches the
    /// provided filter. If multiple documents satisfy the query, this method
    /// returns the first document according to the query's sort order or natural
    /// order.
    /// - Parameters:
    ///   - filter: A `Document` as bson that should match the query.
    ///   - options: `FindOptions` to use when executing the command.
    ///   - completion: The resulting bson or error if one occurs
    @preconcurrency
    public func findOne(filter: T.Filter? = nil,
                        options: FindOptions = FindOptions(),
                        _ completion: @escaping @Sendable (Result<T?, Error>) -> Void) -> Void {
        var document = Document()
        if var filter = filter {
            document = filter.encode()
        }
        mongoCollection.findOneDocument(filter: document, options: options, { result in
            do {
                if let document = try result.get() {
                    completion(.success(try T(from: document)))
                } else {
                    completion(.success(nil))
                }
            } catch {
                completion(.failure(error))
            }
        })
    }
    
    @_unsafeInheritExecutor
    public func findOne(options: FindOptions = FindOptions(),
                        _ filter: ((inout T.Filter) -> Bool)? = nil) async throws -> T? {
        try await withCheckedThrowingContinuation { continuation in
            var query = T.Filter()
            _ = filter?(&query)
            findOne(filter: query, options: options) { returnValue in
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
    //    /// Runs an aggregation framework pipeline against this collection.
    //    /// - Parameters:
    //    ///   - pipeline: A bson array made up of `Documents` containing the pipeline of aggregation operations to perform.
    //    ///   - completion: The resulting bson array of documents or error if one occurs
    //    @preconcurrency
    //    public func aggregate(pipeline: [Document], _ completion: @escaping MongoFindBlock) {
    //        let bson = pipeline.map(ObjectiveCSupport.convert)
    //        __aggregate(withPipeline: bson) { documents, error in
    //            if let bson = documents?.map(ObjectiveCSupport.convert) {
    //                completion(.success(bson))
    //            } else {
    //                completion(.failure(error ?? Realm.Error.callFailed))
    //            }
    //        }
    //    }
    
    /// Counts the number of documents in this collection matching the provided filter.
    /// - Parameters:
    ///   - filter: A `Document` as bson that should match the query.
    ///   - limit: The max amount of documents to count
    ///   - completion: Returns the count of the documents that matched the filter.
    @preconcurrency
    public func count(filter: T? = nil,
                      limit: Int? = nil,
                      _ completion: @escaping @Sendable (Result<Int, Error>) -> Void) -> Void {
        var document = Document()
        if let filter = filter {
            filter.encode(to: &document)
        }
        mongoCollection.count(filter: document, limit: limit, completion)
    }
    
    @_unsafeInheritExecutor
    public func count(filter: T? = nil,
                      limit: Int? = nil) async  throws -> Int {
        try await withCheckedThrowingContinuation { continuation in
            count(filter: filter, limit: limit) { returnValue in
                switch returnValue {
                case .success(let value):
                    continuation.resume(returning: value)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Deletes a single matching document from the collection.
    /// - Parameters:
    ///   - filter: A `Document` as bson that should match the query.
    ///   - completion: The result of performing the deletion. Returns the count of deleted objects
    @preconcurrency
    public func deleteOne(filter: T.Filter? = nil,
                          _ completion: @escaping @Sendable (Result<Int, Error>) -> Void) -> Void {
        var document = Document()
        if var filter = filter {
            document = filter.encode()
        }
        mongoCollection.deleteOneDocument(filter: document, completion)
    }
    
    @_unsafeInheritExecutor
    public func deleteOne(filter: ((inout T.Filter) -> Bool)? = nil) async  throws -> Int {
        try await withCheckedThrowingContinuation { continuation in
            var query = T.Filter()
            _ = filter?(&query)
            deleteOne(filter: query) { returnValue in
                
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
    public func deleteMany(filter: T.Filter? = nil,
                           _ completion: @escaping @Sendable (Result<Int, Error>) -> Void) -> Void {
        var document = Document()
        if var filter = filter {
            document = filter.encode()
        }
        mongoCollection.deleteManyDocuments(filter: document, completion)
    }
    
    @_unsafeInheritExecutor
    public func deleteMany(filter: T.Filter? = nil) async throws -> Int {
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

public struct MongoDatabase<T: BSONCodable> {
    fileprivate let mongoDatabase: RLMMongoDatabase
    public func collection(named name: String) -> MongoCollection<T> {
        MongoCollection<T>(mongoCollection: mongoDatabase.collection(withName: name))
    }
}

public extension MongoClient {
    func database<T: BSONCodable>(named name: String, type: T.Type) -> MongoDatabase<T> {
        MongoDatabase<T>(mongoDatabase: self.database(named: name))
    }
}

@attached(conformance)
@attached(member, names: named(init(from:)), named(encode(to:)), arbitrary)
@available(swift 5.9)
public macro BSONCodable() = #externalMacro(module: "MongoDataAccessMacros", type: "BSONCodableMacro")
