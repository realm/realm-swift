import Foundation
import Realm
@_exported import RealmSwift
import Realm.Private

public protocol BSONFilter {
    var documentRef: DocumentRef { get set }
    init()
    mutating func encode() -> RawDocument
}

//package struct AnyRawDocumentRepresentable : RawDocumentRepresentable {
////    package struct SyntaxView : LiteralSyntaxView {
////        package var endIndex: String.Index
////        package var startIndex: String.Index
////        package var rawJSON: String
////        package var description: String
////        package var rawDocumentRepresentable: AnyRawDocumentRepresentable
////        
////        package init(json: String, at startIndex: String.Index, allowedObjectTypes: [any MongoDataAccess.SyntaxView.Type]) throws {
////            let syntaxView = SyntaxView.map(json: json, at: startIndex, allowedObjectTypes: allowedObjectTypes)
////            self.startIndex = syntaxView.startIndex
////            self.endIndex = syntaxView.endIndex
////            self.rawJSON = syntaxView.rawJSON
////            self.description = syntaxView.description
////            self.rawDocumentRepresentable = AnyRawDocumentRepresentable(rawDocumentRepresentable:  syntaxView.rawDocumentRepresentable)
////        }
////        package init(from value: AnyRawDocumentRepresentable) {
////            let syntaxView = value.rawDocumentRepresentable.syntaxView
////            self.startIndex = syntaxView.startIndex
////            self.endIndex = syntaxView.endIndex
////            self.rawJSON = syntaxView.rawJSON
////            self.description = syntaxView.description
////            self.rawDocumentRepresentable = value
////        }
////    }
////    let rawDocumentRepresentable: any RawDocumentRepresentable
//}

package extension RawDocumentRepresentable {
//    var syntaxViewType: any MongoDataAccess.SyntaxView.Type {
//        SyntaxView.self
//    }
//    var syntaxView: any MongoDataAccess.SyntaxView {
//        SyntaxView(from: self)
//    }
}

public protocol RawDocumentKey : RawRepresentable, CaseIterable where RawValue == String {
}
//
//public protocol RawDocumentPrimitiveRepresentable : RawDocumentRepresentable
//    where SyntaxView: MongoDataAccess.LiteralSyntaxView {
//    
//    static var decoder: [String : any MongoDataAccess.LiteralSyntaxView.Type] { get }
//    init()
//    func encode() -> RawObjectSyntaxView
//}
//
//extension RawDocumentPrimitiveRepresentable {
//    public init(from view: RawObjectSyntaxView) throws {
//        guard let view = view[Self.decoder.0] else {
//            throw BSONError.missingKey(Self.decoder.0)
//        }
//        guard let value = view.rawDocumentRepresentable as? Self else {
//            throw BSONError.invalidType(key: Self.decoder.0)
//        }
//        self = value
//    }
//}

//public protocol RawDocumentObjectRepresentable : RawDocumentRepresentable
//    where SyntaxView: MongoDataAccess.ObjectSyntaxView {
//    associatedtype RawDocumentKeys : RawDocumentKey
////    init(from view: RawObjectSyntaxView) throws
////    func encode() -> SyntaxView
////    static var decoder: [String : any MongoDataAccess.LiteralSyntaxView.Type] { get }
//}

//extension RawDocumentObjectRepresentable {
//    public init(from view: RawObjectSyntaxView) throws {
//        for key in RawDocumentKeys.allCases {
//            key
//        }
//    }
//}
extension RawDocumentRepresentable {
    fileprivate var value: Self {
        self
    }
}

public protocol KeyPathIterable {
    static var keyPaths: [PartialKeyPath<Self> : String] { get }
}

public protocol ExtJSONQueryRepresentable : ExtJSONStructuredRepresentable, KeyPathIterable {
}

//public protocol RawDocumentQueryRepresentable : RawDocumentRepresentable, KeyPathIterable, StructuredDocumentRepresentable  {
//    static var propertyTypes: [String : RawDocumentRepresentable.Type] { get }
//    
//    init(from document: inout LazyDocument<Self>) throws
//}
//extension RawDocumentQueryRepresentable {
//    public init(from document: LazyDocument<Self>) throws {
//        var document = document
//        try self.init(from: &document)
//    }
//}
//
//extension Dictionary : RawDocumentRepresentable where Self.Key == String, 
//                                                        Self.Value == any RawDocumentRepresentable {
//    public typealias SyntaxView = RawObjectSyntaxView
//}

// MARK: Type - ObjectId
//extension ObjectId : RawDocumentRepresentable {
//    public struct SyntaxView : ObjectSyntaxView {
//        public let rawObjectSyntaxView: RawObjectSyntaxView
//        public let rawDocumentRepresentable: ObjectId
//        
//        public init(from view: RawObjectSyntaxView) throws {
//            self.rawObjectSyntaxView = view
//            guard let view = view["$oid"] as? StringLiteralSyntaxView else {
//                throw BSONError.missingKey("$oid")
//            }
//            self.rawDocumentRepresentable = try ObjectId(string: view.string)
//        }
//        
//        public init(from rawDocumentValue: ObjectId) {
//            self.rawDocumentRepresentable = rawDocumentValue
//            self.rawObjectSyntaxView = [
//                "$oid": StringLiteralSyntaxView(stringLiteral: rawDocumentRepresentable.stringValue)
//            ]
//        }
//    }
//}

//extension Int32 : RawDocumentRepresentable {
//    public var rawValue: RawDocument {
//        ["$int32": self]
//    }
//    public init(from rawDocumentValue: RawDocument) {
//        self = rawDocumentValue["$int32"] as! Int32
//    }
//}
//extension Int64 : RawDocumentRepresentable {
//    public var rawValue: RawDocument {
//        ["$int64": self]
//    }
//    public init(from rawDocumentValue: RawDocument) {
//        self = rawDocumentValue["$int64"] as! Int64
//    }
//}
//extension Bool : RawDocumentRepresentable {
//    public typealias SyntaxView = BoolSyntaxView
//}
//extension Double : RawDocumentRepresentable {
//    public var rawValue: RawDocument {
//        ["$numberDouble": self]
//    }
//    public init(from rawDocumentValue: RawDocument) {
//        self = rawDocumentValue["$numberDouble"] as! Double
//    }
//}

// MARK: Type - Regex
//@available(macOS 13.0, *)
//extension Regex : RawDocumentRepresentable {
////    public struct SyntaxView : ObjectSyntaxView {
////        public var rawDocumentRepresentable: Regex<Output>
////        
////        public var rawObjectSyntaxView: RawObjectSyntaxView
////        public typealias RawDocumentValue = Regex
////        
////        public init(from value: Regex<Output>) {
////            fatalError()
////        }
////        public init(from view: RawObjectSyntaxView) throws {
////            fatalError()
////        }
////    }
//}

// MARK: Type - Array
//extension Array : RawDocumentRepresentable where Element: RawDocumentRepresentable {
//    public typealias SyntaxView = ArraySyntaxView<Element>
//}
//extension Array : RawDocumentRepresentable where Element == any RawDocumentRepresentable {
////    public typealias SyntaxView = RawArraySyntaxView
//}
//extension Array where Element : RawDocumentRepresentable {
//    public typealias SyntaxView = ArraySyntaxView<Element>
//}
@BSONCodable struct Person {
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
    associatedtype FieldType : ExtJSONRepresentable
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

@dynamicMemberLookup public struct BSONQuery<FieldType : ExtJSONRepresentable> : BSONQueryable {
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

public extension Collection where Element : ExtJSONRepresentable {
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

public struct MongoCollection<T : ExtJSONQueryRepresentable> {
    fileprivate let mongoCollection: RLMMongoCollection
    fileprivate let database: MongoDatabase
    fileprivate init(mongoCollection: RLMMongoCollection, database: MongoDatabase) {
        self.mongoCollection = mongoCollection
        self.database = database
    }
    
    /// Encodes the provided value to BSON and inserts it. If the value is missing an identifier, one will be
    /// generated for it.
    /// - Parameters:
    ///   - object: object  A `T` value to insert.
    ///   - completion: The result of attempting to perform the insert. An Id will be returned for the inserted object on sucess
//    @preconcurrency
//    public func insertOne(_ object: T,
//                          _ completion: @Sendable @escaping (Result<T.Id, Error>) -> Void) -> Void {
//        var document = RawDocument()
//        object.encode(to: &document)
//        mongoCollection.user.callFunctionNamed("insertOne", 
//                                               arguments: document.description,
//                                               serviceName: "mongodb-atlas", completionBlock: {
//            completion($0.map({ $0. }))
//        })
//        mongoCollection.app.insertOne(document, {
//            
//        })
//    }
//    
//    @_unsafeInheritExecutor
//    public func insertOne(_ object: T) async throws -> AnyBSON {
//        try await withCheckedThrowingContinuation { continuation in
//            insertOne(object) { returnValue in
//                
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
    
    @_unsafeInheritExecutor
    public func findOne(options: FindOptions = FindOptions(),
                        _ filter: ((inout Filter<T>) -> any BSONQueryable)? = nil) async throws -> T? {
        let data: String = try await withCheckedThrowingContinuation { continuation in
            var document = RawDocument()
            if let filter = filter {
                var filterDocument = Filter<T>()
                _ = filter(&filterDocument)
                document["query"] = filterDocument.documentRef.document
            }
            document["database"] = mongoCollection.databaseName
            document["collection"] = mongoCollection.name
            mongoCollection.user.callFunctionNamed(
                "findOne",
                arguments: String(data: [document].extJSONValue, encoding: .utf8)!,
                serviceName: mongoCollection.serviceName) { data, error in
                    guard let data = data else {
                    guard let error = error else {
                        return continuation.resume(throwing: AppError(RLMAppError.Code.httpRequestFailed))
                    }
                    return continuation.resume(throwing: error)
                }
                continuation.resume(returning: data)
            }
        }

        fatalError()
//        let objectTypes = T.schema.compactMap {
//            $0.value as? any StructuredDocumentRepresentable.Type
//        }
//        var scanner: Scanner = ExtJSONScanner(string: data, objectTypes: objectTypes)
        
//        let node = try SyntaxNode(from: &scanner)
//        var document = LazyDocument<T>(from: &scanner)
        fatalError()
//        return try T(from: &document) try T.SyntaxView(from: view).rawDocumentRepresentable
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
//    /// Deletes a single matching document from the collection.
//    /// - Parameters:
//    ///   - filter: A `Document` as bson that should match the query.
//    ///   - completion: The result of performing the deletion. Returns the count of deleted objects
//    @preconcurrency
//    public func deleteOne(filter: T.Filter? = nil,
//                          _ completion: @escaping @Sendable (Result<Int, Error>) -> Void) -> Void {
//        var document = Document()
//        if var filter = filter {
//            document = filter.encode()
//        }
//        mongoCollection.deleteOneDocument(filter: document, completion)
//    }
//    
//    @_unsafeInheritExecutor
//    public func deleteOne(filter: ((inout T.Filter) -> Bool)? = nil) async throws -> Int {
//        try await withCheckedThrowingContinuation { continuation in
//            var query = T.Filter()
//            _ = filter?(&query)
//            deleteOne(filter: query) { returnValue in
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
//    /// Deletes multiple documents
//    /// - Parameters:
//    ///   - filter: Document representing the match criteria
//    ///   - completion: The result of performing the deletion. Returns the count of the deletion
//    @preconcurrency
//    public func deleteMany(filter: T.Filter? = nil,
//                           _ completion: @escaping @Sendable (Result<Int, Error>) -> Void) -> Void {
//        var document = Document()
//        if var filter = filter {
//            document = filter.encode()
//        }
//        mongoCollection.deleteManyDocuments(filter: document, completion)
//    }
//    
//    @_unsafeInheritExecutor
//    public func deleteMany(filter: T.Filter? = nil) async throws -> Int {
//        try await withCheckedThrowingContinuation { continuation in
//            deleteMany(filter: filter) { returnValue in
//                switch returnValue {
//                case .success(let value):
//                    continuation.resume(returning: value)
//                case .failure(let error):
//                    continuation.resume(throwing: error)
//                }
//            }
//        }
//    }
}

public struct MongoDatabase {
    fileprivate let mongoDatabase: RLMMongoDatabase
    public func collection<T: ExtJSONRepresentable>(named name: String, type: T.Type) -> MongoCollection<T> {
        MongoCollection<T>(mongoCollection: mongoDatabase.collection(withName: name),
                           database: self)
    }
}

public extension MongoClient {
    func database(named name: String) -> MongoDatabase {
        MongoDatabase(mongoDatabase: self.database(named: name))
    }
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

@attached(extension, conformances: ExtJSONQueryRepresentable, names: named(SyntaxView), named(keyPaths), suffixed(SyntaxView), arbitrary)
@attached(member, names: named(init(from:)), named(rawDocument), arbitrary)
@available(swift 5.9)
public macro BSONCodable(key: String? = nil) = #externalMacro(module: "MongoDataAccessMacros",
                                                              type: "BSONCodableMacro")

@attached(peer)
@available(swift 5.9)
public macro DocumentKey(_ key: String? = nil) = #externalMacro(module: "MongoDataAccessMacros",
                                                                type: "RawDocumentQueryRepresentableMacro")

