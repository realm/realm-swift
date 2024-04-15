import Foundation
import Realm
import Realm.Private

public enum AnyBSONKey: ExtJSONCodable, Equatable {
    typealias ExtJSONValue = Self

    case string(String)
    case objectId(ObjectId)
    case int(Int)

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .string(let a0): try a0.encode(to: encoder)
        case .objectId(let a0): try a0.encode(to: encoder)
        case .int(let a0): try a0.encode(to: encoder)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        fatalError()
//        switch decoder.userInfo[.storage] {
//        case let value as String: self = .string(value)
//        case let value as [String: String]:
//            if value.keys.first == Int.ExtJSONValue.CodingKeys.numberInt.rawValue {
//                self = .int(try container.decode(Int.self))
//            } else {
//                self = .objectId(try container.decode(ObjectId.self))
//            }
//        default:
//            if let value = try? container.decode(String.self) {
//                self = .string(value)
//            } else if let value = try? container.decode(Int.self) {
//                self = .int(value)
//            } else {
//                self = .objectId(try container.decode(ObjectId.self))
//            }
//        }
    }
}

protocol Resolvable {
    associatedtype Success
    associatedtype Failure: Error

    var result: Result<Success, Failure> { get }
}
extension Result: Resolvable {
    var result: Result<Success, Failure> { return self }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
func withTypeCheckedThrowingContinuation<each U, V>(_ block: @escaping (repeat (each U), @escaping (V) -> Void) -> Void,
                                                     _ arguments: repeat (each U))
async throws -> V.Success where V: Resolvable {
    typealias Function<each Args> = (repeat (each Args)) -> Void
    func curry<each Args>(_ fn: @escaping (repeat each Args) -> Void,
                          arguments: repeat (each Args)) {
        fn(repeat each arguments)
    }
    return try await withCheckedThrowingContinuation { continuation in
        let rb = unsafeBitCast({ @Sendable (returnValue: Result<V.Success, V.Failure>) in
            switch returnValue.result {
            case .success(let value):
                continuation.resume(returning: value)
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }, to: Function<V>.self)
        curry(block, arguments: repeat (each arguments) as (each U), rb)
    }
}

public struct InsertOneResult : Codable {
    public let insertedId: AnyBSONKey
}

public struct MongoTypedCollection<T : Codable> {
    fileprivate let mongoCollection: RLMMongoCollection
    fileprivate let database: MongoDatabase
    fileprivate init(mongoCollection: RLMMongoCollection, database: MongoDatabase) {
        self.mongoCollection = mongoCollection
        self.database = database
    }
    
    private func call<Res>(function: String,
                           arguments: NSDictionary,
                           _ block: @Sendable @escaping (Result<Res, Error>) -> Void) where Res: Codable {
        do {
            let arguments = NSMutableDictionary(dictionary: arguments)
            arguments["database"] = database.name
            arguments["collection"] = mongoCollection.name
            try mongoCollection.user.callFunctionNamed(
                function,
                arguments: String(data: ExtJSONSerialization.data(with: [arguments]),
                                  encoding: .utf8)!,
                serviceName: mongoCollection.serviceName) { data, error in
                    guard let data = data?.data(using: .utf8) else {
                        guard let error = error else {
                            return block(.failure(AppError(RLMAppError.Code.httpRequestFailed)))
                        }
                        return block(.failure(error))
                    }
                    do {
                        block(.success(try ExtJSONDecoder().decode(Res.self, from: data)))
                    } catch {
                        block(.failure(error))
                    }
                }
        } catch {
            block(.failure(error))
        }
    }
    
    @available(macOS 10.15, *)
    @_unsafeInheritExecutor
    private func call<Res>(function: String, arguments: NSDictionary) async throws -> Res where Res: Codable {
        try await withCheckedThrowingContinuation { continuation in
            call(function: function, arguments: arguments, {
                continuation.resume(with: $0)
            })
        }
    }
    
    struct Arguments : Codable {
        let database: String
        let collection: String
        let document: T
    }

    // MARK: InsertOne
    /// Encodes the provided value to BSON and inserts it. If the value is missing an identifier, one will be
    /// generated for it.
    /// - Parameters:
    ///   - object: object  A `T` value to insert.
    ///   - completion: The result of attempting to perform the insert. An Id will be returned for the inserted object on sucess
    @preconcurrency
    public func insertOne(_ object: T,
                          _ completion: @Sendable @escaping (Result<InsertOneResult, Error>) -> Void) {
        call(function: "insertOne", arguments: ["document": object], completion)
    }
    
    @_unsafeInheritExecutor
    @available(macOS 10.15, *)
    public func insertOne(_ object: T) async throws -> InsertOneResult {
        try await withTypeCheckedThrowingContinuation(self.insertOne, object)
    }
    
    // MARK: InsertMany
    public struct InsertManyResult: Codable {
        public let insertedIds: [AnyBSONKey]
    }

    public func insertMany(_ documents: [T],
                           _ block: @Sendable @escaping (Result<InsertManyResult, Error>) -> Void) {
        call(function: "insertMany", arguments: ["documents": documents], block)
    }
    @available(macOS 10.15, *)
    @_unsafeInheritExecutor
    public func insertMany(_ documents: [T]) async throws -> InsertManyResult {
        try await withTypeCheckedThrowingContinuation(insertMany, documents)
    }
    
    // MARK: FindOne
    public func findOne(_ block: @Sendable @escaping (Result<T?, Error>) -> Void) {
        call(function: "findOne", arguments: [:], block)
    }
    public func findOne(_ filter: [String: Any],
                        options: FindOptions = FindOptions(),
                        _ block: @Sendable @escaping (Result<T, Error>) -> Void) {
        call(function: "findOne", arguments: ["query": filter], block)
    }
    public func findOne(_ filter: T,
                        options: FindOptions = FindOptions(),
                        _ block: @Sendable @escaping (Result<T, Error>) -> Void) {
        call(function: "findOne", arguments: ["query": filter], block)
    }
    
    /// Returns one document from a collection or view which matches the
    /// provided filter. If multiple documents satisfy the query, this method
    /// returns the first document according to the query's sort order or natural
    /// order.
    /// - returns: A publisher that eventually return `Document` or `nil` if document wasn't found or `Error`.
    @_unsafeInheritExecutor
    @available(macOS 10.15, *)
    public func findOne() async throws -> T? {
        try await withTypeCheckedThrowingContinuation(findOne)
    }
    
    /// Returns one document from a collection or view which matches the
    /// provided filter. If multiple documents satisfy the query, this method
    /// returns the first document according to the query's sort order or natural
    /// order.
    /// - parameter options: Options to apply to the query.
    /// - parameter filter: A `Document` as bson that should match the query.
    /// - returns: A publisher that eventually return `Document` or `nil` if document wasn't found or `Error`.
    @_unsafeInheritExecutor
    @available(macOS 10.15, *)
    public func findOne(_ filter: [String: Any],
                        options: FindOptions = FindOptions()) async throws -> T? {
        try await withTypeCheckedThrowingContinuation(findOne, filter, options)
    }
    @_unsafeInheritExecutor
    @available(macOS 10.15, *)
    public func findOne(_ filter: T,
                        options: FindOptions = FindOptions()) async throws -> T? {
        try await withTypeCheckedThrowingContinuation(findOne, filter, options)
    }
    @_unsafeInheritExecutor
    @available(macOS 10.15, *)
    public func findOne(_ filter: ((Query<T>) -> Query<Bool>),
                        options: FindOptions = FindOptions()) async throws -> T?
    where T: Object {
        try await withTypeCheckedThrowingContinuation(findOne,
                                                      buildFilter(filter(Query()).node),
                                                      options)
    }
    
    // MARK: Find
    public func find(options: FindOptions = FindOptions(),
                     _ filter: T? = nil,
                     _ block: @Sendable @escaping (Result<[T], Error>) -> Void) {
        call(function: "find", arguments: ["query": filter ?? [:]], block)
    }
    public func find(options: FindOptions = FindOptions(),
                     _ filter: [String: Any]? = nil,
                     _ block: @Sendable @escaping (Result<[T], Error>) -> Void) {
        call(function: "find", arguments: ["query": filter ?? [:]], block)
    }
    @available(macOS 10.15, *)
    @_unsafeInheritExecutor
    public func find(options: FindOptions = FindOptions(),
                     where filter: ((Query<T>) -> Query<Bool>)? = nil) async throws -> [T] {
        try await withTypeCheckedThrowingContinuation(find,
                                                      options,
                                                      filter.map { try buildFilter($0(Query()).node) } ?? [:])
    }
    
    // MARK: Count
    @available(macOS 10.15, *)
    @_unsafeInheritExecutor
    public func count(where filter: (Query<T>) -> Query<Bool>) async throws -> Int64 {
        try await call(function: "count", arguments: [
            "query": try buildFilter(filter(Query()).node),
        ])
    }

    // MARK: Update
    public struct UpdateResult: Codable {
        
        /// The number of documents that matched the filter.
        public let matchedCount: Int
        
        /// The number of documents modified.
        public let modifiedCount: Int
        
        /// The identifier of the inserted document if an upsert took place.
        public let upsertedId: AnyBSONKey?
    }
    
    @available(macOS 10.15, *)
    @_unsafeInheritExecutor
    public func updateOne(filter: ((Query<T>) -> Query<Bool>),
                          update: T,
                          upsert: Bool? = nil) async throws -> UpdateResult {
        try await call(function: "updateOne", arguments: [
            "query": buildFilter(filter(Query()).node),
            "update": update,
            "upsert": upsert ?? false,
            "database": mongoCollection.databaseName,
            "collection": mongoCollection.name
        ])
    }
    
    @available(macOS 10.15, *)
    @_unsafeInheritExecutor
    public func updateMany(filter: ((Query<T>) -> Query<Bool>),
                          update: T,
                          upsert: Bool? = nil) async throws -> UpdateResult {
        try await call(function: "updateMany", arguments: [
            "query": buildFilter(filter(Query()).node),
            "update": update,
            "upsert": upsert ?? false,
            "database": mongoCollection.databaseName,
            "collection": mongoCollection.name
        ])
    }
    
    // MARK: Delete
    public struct Deleted : Codable {
        public let deletedCount: Int
    }
    
    /// Deletes a single matching document from the collection.
    /// - Parameters:
    ///   - filter: A `Document` as bson that should match the query.
    ///   - completion: The result of performing the deletion. Returns the count of deleted objects
    @preconcurrency
    public func deleteOne(filter: T? = nil,
                          _ completion: @escaping @Sendable (Result<Deleted, Error>) -> Void) -> Void {
        call(function: "deleteOne", arguments: ["query": filter ?? [:]], completion)
    }
    
    @available(macOS 10.15, *)
    @_unsafeInheritExecutor
    public func deleteOne(filter: T? = nil) async throws -> Deleted {
        try await withTypeCheckedThrowingContinuation(deleteOne,
                                                       filter)
    }
    /// Deletes multiple documents
    /// - Parameters:
    ///   - filter: Document representing the match criteria
    ///   - completion: The result of performing the deletion. Returns the count of the deletion
    @preconcurrency
    public func deleteMany(filter: T? = nil,
                           _ completion: @escaping @Sendable (Result<Deleted, Error>) -> Void) -> Void {
        call(function: "deleteMany", arguments: ["query": filter ?? [:]], completion)
    }
    
    @_unsafeInheritExecutor
    @available(macOS 10.15, watchOS 6.0, iOS 13.0, tvOS 13.0, *)
    public func deleteMany(filter: T? = nil) async throws -> Deleted {
        try await withTypeCheckedThrowingContinuation(deleteMany, filter)
    }
}

extension MongoDatabase {
    public func collection<T: Codable>(named name: String,
                                       type: T.Type) -> MongoTypedCollection<T> {
        MongoTypedCollection<T>(mongoCollection: self.collection(withName: name),
                                database: self)
    }
}
