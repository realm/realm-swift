////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

import Realm

extension RLMRealm {
    @nonobjc public class func schemaVersion(at url: URL, usingEncryptionKey key: Data? = nil) throws -> UInt64 {
        var error: NSError?
        let version = __schemaVersion(at: url, encryptionKey: key, error: &error)
        guard version != RLMNotVersioned else { throw error! }
        return version
    }

    @nonobjc public func resolve<Confined>(reference: RLMThreadSafeReference<Confined>) -> Confined? {
        return __resolve(reference as! RLMThreadSafeReference<RLMThreadConfined>) as! Confined?
    }
}

extension RLMObject {
    // Swift query convenience functions
    public class func objects(where predicateFormat: String, _ args: CVarArg...) -> RLMResults<RLMObject> {
        return objects(with: NSPredicate(format: predicateFormat, arguments: getVaList(args))) as! RLMResults<RLMObject>
    }

    public class func objects(in realm: RLMRealm,
                              where predicateFormat: String,
                              _ args: CVarArg...) -> RLMResults<RLMObject> {
        return objects(in: realm, with: NSPredicate(format: predicateFormat, arguments: getVaList(args))) as! RLMResults<RLMObject>
    }
}

public struct RLMIterator<T>: IteratorProtocol {
    private var iteratorBase: NSFastEnumerationIterator

    internal init(collection: RLMCollection) {
        iteratorBase = NSFastEnumerationIterator(collection)
    }

    public mutating func next() -> T? {
        return iteratorBase.next() as! T?
    }
}

// Sequence conformance for RLMArray and RLMResults is provided by RLMCollection's
// `makeIterator()` implementation.
extension RLMArray: Sequence {}
extension RLMResults: Sequence {}

extension RLMCollection {
    // Support Sequence-style enumeration
    public func makeIterator() -> RLMIterator<RLMObject> {
        return RLMIterator(collection: self)
    }
}

extension RLMCollection {
    // Swift query convenience functions
    public func indexOfObject(where predicateFormat: String, _ args: CVarArg...) -> UInt {
        return indexOfObject(with: NSPredicate(format: predicateFormat, arguments: getVaList(args)))
    }

    public func objects(where predicateFormat: String, _ args: CVarArg...) -> RLMResults<NSObject> {
        return objects(with: NSPredicate(format: predicateFormat, arguments: getVaList(args))) as! RLMResults<NSObject>
    }
}

extension RLMApp {
    public func login(credentials: RLMCredentials,
                      completion: @escaping RLMUserCompletionBlock) {
        return self.__login(withCredential: credentials, completion: completion)
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    public func setASAuthorizationControllerDelegateForController(controller: ASAuthorizationController) {
        return __setASAuthorizationControllerDelegateFor(controller)
    }
}

extension RLMEmailPasswordAuth {
    public func callResetPasswordFunction(_ email: String,
                                          password: String,
                                          args: [RLMBSON],
                                          completion: @escaping RLMEmailPasswordAuthOptionalErrorBlock) {
        self.__callResetPasswordFunction(email,
                                         password: password,
                                         args: args,
                                         completion: completion)
    }
}

extension RLMSyncSession {
    public func addProgressNotification(for direction: RLMSyncProgressDirection,
                                        mode: RLMSyncProgressMode,
                                        block: @escaping RLMProgressNotificationBlock) -> RLMProgressNotificationToken? {
        return self.__addProgressNotification(for: direction,
                                              mode: mode,
                                              block: block)
    }
}

extension RLMUser {
    func configuration<T: BSON>(partitionValue: T) -> RLMRealmConfiguration {
        return self.__configuration(withPartitionValue: ObjectiveCSupport.convert(object: AnyBSON(partitionValue))!)
    }

    public func linkUser(credentials: RLMCredentials, completion: @escaping RLMOptionalUserBlock) {
        return self.__linkUser(with: credentials, completion: completion)
    }

    public func mongoClient(serviceName: String) -> RLMMongoClient {
        return self.__mongoClient(withServiceName: serviceName)
    }

    public func callFunctionNamed(_ name: String, arguments: [AnyBSON], completion: @escaping (AnyBSON?, Error?) -> Void) {
        let args = arguments.map(ObjectiveCSupport.convert) as! [RLMBSON]
        return self.__callFunctionNamed(name, arguments: args ) { (bson: RLMBSON?, error: Error?) in
            completion(ObjectiveCSupport.convert(object: bson), error)
        }
    }

    var customData: Document {
        guard let rlmCustomData = self.__customData as RLMBSON?,
            let anyBSON = ObjectiveCSupport.convert(object: rlmCustomData),
            case let .document(customData) = anyBSON else {
            return [:]
        }
        return customData
    }
}

public typealias FindOptions = RLMFindOptions

extension FindOptions {
    /// Limits the fields to return for all matching documents.
    public var projection: Document? {
        get {
            return ObjectiveCSupport.convert(object: __projection)?.documentValue
        }
        set {
            __projection = newValue.map(AnyBSON.init).map(ObjectiveCSupport.convert) as? RLMBSON
        }
    }

    /// The order in which to return matching documents.
    public var sort: Document? {
        get {
            return ObjectiveCSupport.convert(object: __sort)?.documentValue
        }
        set {
            __sort = newValue.map(AnyBSON.init).map(ObjectiveCSupport.convert) as? RLMBSON
        }
    }

    /// Options to use when executing a `find` command on a `RLMMongoCollection`.
    /// - Parameters:
    ///   - limit: The maximum number of documents to return. Specifying 0 will return all documents.
    ///   - projected: Limits the fields to return for all matching documents.
    ///   - sort: The order in which to return matching documents.
    public convenience init(limit: Int?, projection: Document?, sort: Document?) {
        self.init()
        self.limit = limit ?? 0
        self.projection = projection
        self.sort = sort
    }
}

/// Options to use when executing a `findOneAndUpdate`, `findOneAndReplace`,
/// or `findOneAndDelete` command on a `MongoCollection`.
public typealias FindOneAndModifyOptions = RLMFindOneAndModifyOptions

extension FindOneAndModifyOptions {

    /// Limits the fields to return for all matching documents.
    public var projection: Document? {
        get {
            return ObjectiveCSupport.convert(object: __projection)?.documentValue
        }
        set {
            __projection = newValue.map(AnyBSON.init).map(ObjectiveCSupport.convert) as? RLMBSON
        }
    }

    /// The order in which to return matching documents.
    public var sort: Document? {
        get {
            return ObjectiveCSupport.convert(object: __sort)?.documentValue
        }
        set {
            __sort = newValue.map(AnyBSON.init).map(ObjectiveCSupport.convert) as? RLMBSON
        }
    }

    /// Options to use when executing a `findOneAndUpdate`, `findOneAndReplace`,
    /// or `findOneAndDelete` command on a `RLMMongoCollection`
    /// - Parameters:
    ///   - projection: Limits the fields to return for all matching documents.
    ///   - sort: The order in which to return matching documents.
    ///   - upsert: Whether or not to perform an upsert, default is false
    ///   (only available for findOneAndReplace and findOneAndUpdate)
    ///   - shouldReturnNewDocument: When true then the new document is returned,
    ///   Otherwise the old document is returned (default)
    ///   (only available for findOneAndReplace and findOneAndUpdate)
    public convenience init(projection: Document?,
                            sort: Document?,
                            upsert: Bool = false,
                            shouldReturnNewDocument: Bool = false) {
        self.init()
        self.projection = projection
        self.sort = sort
        self.upsert = upsert
        self.shouldReturnNewDocument = shouldReturnNewDocument
    }
}

extension RLMMongoCollection {

    public func insertOne(document: Document, completion: @escaping RLMMongoInsertBlock) {
        let bson = ObjectiveCSupport.convert(object: .document(document))
        return self.__insertOneDocument(bson as! [String: RLMBSON], completion: completion)
    }

    public func insertMany(documents: [Document], completion: @escaping RLMMongoInsertManyBlock) {
        let bson = ObjectiveCSupport.convert(object: .array(documents.map {.document($0)}))
        return self.__insertManyDocuments(bson as! [[String: RLMBSON]], completion: completion)
    }

    public func find(filter: Document, completion: @escaping RLMMongoFindBlock) {
        let bson = ObjectiveCSupport.convert(object: .document(filter))
        return self.__findWhere(bson as! [String: RLMBSON], completion: completion)
    }

    public func find(filter: Document,
                     options: FindOptions,
                     completion: @escaping RLMMongoFindBlock) {
        let bson = ObjectiveCSupport.convert(object: .document(filter))
        return self.__findWhere(bson as! [String: RLMBSON], options: options, completion: completion)
    }

    public func findOneDocument(filter: Document, completion: @escaping RLMMongoFindOneBlock) {
        let bson = ObjectiveCSupport.convert(object: .document(filter))
        return self.__findOneDocumentWhere(bson as! [String: RLMBSON], completion: completion)
    }

    public func findOneDocument(filter: Document,
                                options: FindOptions,
                                completion: @escaping RLMMongoFindOneBlock) {
        let bson = ObjectiveCSupport.convert(object: .document(filter))
        return self.__findOneDocumentWhere(bson as! [String: RLMBSON],
                                           options: options,
                                           completion: completion)
    }

    public func aggregate(pipeline: [Document], completion: @escaping RLMMongoFindBlock) {
        let bson = ObjectiveCSupport.convert(object: .array(pipeline.map {.document($0)}))
        return self.__aggregate(withPipeline: bson as! [[String: RLMBSON]], completion: completion)
    }

    public func count(filter: Document, completion: @escaping RLMMongoCountBlock) {
        let bson = ObjectiveCSupport.convert(object: .document(filter))
        return self.__countWhere(bson as! [String: RLMBSON], completion: completion)
    }

    public func count(filter: Document, limit: Int, completion: @escaping RLMMongoCountBlock) {
        let bson = ObjectiveCSupport.convert(object: .document(filter))
        return self.__countWhere(bson as! [String: RLMBSON], limit: limit, completion: completion)
    }

    public func deleteOneDocument(filter: Document, completion: @escaping RLMMongoCountBlock) {
        let bson = ObjectiveCSupport.convert(object: .document(filter))
        return self.__deleteOneDocumentWhere(bson as! [String: RLMBSON], completion: completion)
    }

    public func deleteManyDocuments(filter: Document, completion: @escaping RLMMongoCountBlock) {
        let bson = ObjectiveCSupport.convert(object: .document(filter))
        return self.__deleteManyDocumentsWhere(bson as! [String: RLMBSON], completion: completion)
    }

    public func updateOneDocument(filter: Document,
                                  update: Document,
                                  completion: @escaping RLMMongoUpdateBlock) {
        let filterBson = ObjectiveCSupport.convert(object: .document(filter))
        let updateBson = ObjectiveCSupport.convert(object: .document(update))

        return self.__updateOneDocumentWhere(filterBson as! [String: RLMBSON],
                                             updateDocument: updateBson as! [String: RLMBSON],
                                             completion: completion)
    }

    public func updateOneDocument(filter: Document,
                                  update: Document,
                                  upsert: Bool,
                                  completion: @escaping RLMMongoUpdateBlock) {
        let filterBson = ObjectiveCSupport.convert(object: .document(filter))
        let updateBson = ObjectiveCSupport.convert(object: .document(update))

        return self.__updateOneDocumentWhere(filterBson as! [String: RLMBSON],
                                             updateDocument: updateBson as! [String: RLMBSON],
                                             upsert: upsert,
                                             completion: completion)
    }

    public func updateManyDocuments(filter: Document,
                                    update: Document,
                                    upsert: Bool,
                                    completion: @escaping RLMMongoUpdateBlock) {
        let filterBson = ObjectiveCSupport.convert(object: .document(filter))
        let updateBson = ObjectiveCSupport.convert(object: .document(update))

        return self.__updateManyDocumentsWhere(filterBson as! [String: RLMBSON],
                                               updateDocument: updateBson as! [String: RLMBSON],
                                               upsert: upsert,
                                               completion: completion)
    }

    public func updateManyDocuments(filter: Document,
                                    update: Document,
                                    completion: @escaping RLMMongoUpdateBlock) {
        let bson = ObjectiveCSupport.convert(object: .document(filter))
        let updateBson = ObjectiveCSupport.convert(object: .document(update))

        return self.__updateManyDocumentsWhere(bson as! [String: RLMBSON],
                                               updateDocument: updateBson as! [String: RLMBSON],
                                               completion: completion)
    }

    public func findOneAndUpdate(filter: Document,
                                 update: Document,
                                 options: FindOneAndModifyOptions,
                                 completion: @escaping RLMMongoFindOneBlock) {
        let bson = ObjectiveCSupport.convert(object: .document(filter))
        let updateBson = ObjectiveCSupport.convert(object: .document(update))

        return self.__findOneAndUpdateWhere(bson as! [String: RLMBSON],
                                            updateDocument: updateBson as! [String: RLMBSON],
                                            options: options,
                                            completion: completion)
    }

    public func findOneAndUpdate(filter: Document,
                                 update: Document,
                                 completion: @escaping RLMMongoFindOneBlock) {
        let bson = ObjectiveCSupport.convert(object: .document(filter))
        let updateBson = ObjectiveCSupport.convert(object: .document(update))

        return self.__findOneAndUpdateWhere(bson as! [String: RLMBSON],
                                            updateDocument: updateBson as! [String: RLMBSON],
                                            completion: completion)
    }

    public func findOneAndReplace(filter: Document,
                                  replacement: Document,
                                  options: FindOneAndModifyOptions,
                                  completion: @escaping RLMMongoFindOneBlock) {
        let bson = ObjectiveCSupport.convert(object: .document(filter))
        let replacementBson = ObjectiveCSupport.convert(object: .document(replacement))
        return self.__findOneAndReplaceWhere(bson as! [String: RLMBSON],
                                             replacementDocument: replacementBson as! [String: RLMBSON],
                                             options: options,
                                             completion: completion)
    }

    public func findOneAndReplace(filter: Document,
                                  replacement: Document,
                                  completion: @escaping RLMMongoFindOneBlock) {
        let filterBson = ObjectiveCSupport.convert(object: .document(filter))
        let replacementBson = ObjectiveCSupport.convert(object: .document(replacement))
        return self.__findOneAndReplaceWhere(filterBson as! [String: RLMBSON],
                                             replacementDocument: replacementBson as! [String: RLMBSON],
                                             completion: completion)
    }

    public func findOneAndDelete(filter: Document,
                                 options: FindOneAndModifyOptions,
                                 completion: @escaping RLMMongoDeleteBlock) {
        let bson = ObjectiveCSupport.convert(object: .document(filter))
        return self.__findOneAndDeleteWhere(bson as! [String: RLMBSON],
                                            options: options,
                                            completion: completion)
    }

    public func findOneAndDelete(filter: Document, completion: @escaping RLMMongoDeleteBlock) {
        let bson = ObjectiveCSupport.convert(object: .document(filter))
        return self.__findOneAndDeleteWhere(bson as! [String: RLMBSON], completion: completion)
    }

    public func watch(delegate: RLMChangeEventDelegate, queue: DispatchQueue?) -> RLMChangeStream {
        return self.__watch(with: delegate, delegateQueue: queue)
    }

    public func watch(filterIds: [RLMObjectId],
                      delegate: RLMChangeEventDelegate,
                      queue: DispatchQueue?) -> RLMChangeStream {
        return self.__watch(withFilterIds: filterIds,
                            delegate: delegate,
                            delegateQueue: queue)
    }

    public func watch(matchFilter: [String: RLMBSON],
                      delegate: RLMChangeEventDelegate,
                      queue: DispatchQueue?) -> RLMChangeStream {
        return self.__watch(withMatchFilter: matchFilter,
                            delegate: delegate,
                            delegateQueue: queue)
    }
}

extension RLMDecimal128 {
    public static var minimumDecimalNumber: RLMDecimal128 {
        return __minimumDecimalNumber
    }

    public static var maximumDecimalNumber: RLMDecimal128 {
        return __maximumDecimalNumber
    }

    public var magnitude: RLMDecimal128 {
        return self.__magnitude
    }
}

/// Protocol representing a BSON value.
/// - SeeAlso: bsonspec.org
public protocol BSON: Equatable {
}

extension NSNull: BSON {
}

extension Int: BSON {
}

extension Int32: BSON {
}

extension Int64: BSON {
}

extension Bool: BSON {
}

extension Double: BSON {
}

extension String: BSON {
}

extension Data: BSON {
}

extension Date: BSON {
}

extension RLMDecimal128: BSON {
}

extension RLMObjectId: BSON {
}

/// A Dictionary object representing a `BSON` document.
public typealias Document = Dictionary<String, AnyBSON?>

extension Dictionary: BSON where Key == String, Value == AnyBSON? {
}

extension Array: BSON where Element == AnyBSON? {
}

extension NSRegularExpression: BSON {
}

/// MaxKey will always be the greatest value when comparing to other BSON types
public typealias MaxKey = RLMMaxKey

extension MaxKey: BSON {
}

/// MinKey will always be the smallest value when comparing to other BSON types
public typealias MinKey = RLMMinKey

extension MinKey: BSON {
}

/// Enum representing a BSON value.
/// - SeeAlso: bsonspec.org
@frozen public enum AnyBSON: BSON {
    /// A BSON double.
    case double(Double)

    /// A BSON string.
    /// - SeeAlso: https://docs.mongodb.com/manual/reference/bson-types/#string
    case string(String)

    /// A BSON document.
    indirect case document(Document)

    /// A BSON array.
    indirect case array([AnyBSON?])

    /// A BSON binary.
    case binary(Data)

    /// A BSON ObjectId.
    /// - SeeAlso: https://docs.mongodb.com/manual/reference/bson-types/#objectid
    case objectId(RLMObjectId)

    /// A BSON boolean.
    case bool(Bool)

    /// A BSON UTC datetime.
    /// - SeeAlso: https://docs.mongodb.com/manual/reference/bson-types/#date
    case datetime(Date)

    /// A BSON regular expression.
    case regex(NSRegularExpression)

    /// A BSON int32.
    case int32(Int32)

    /// A BSON timestamp.
    /// - SeeAlso: https://docs.mongodb.com/manual/reference/bson-types/#timestamps
    case timestamp(Date)

    /// A BSON int64.
    case int64(Int64)

    /// A BSON Decimal128.
    /// - SeeAlso: https://github.com/mongodb/specifications/blob/master/source/bson-decimal128/decimal128.rst
    case decimal128(RLMDecimal128)

    /// A BSON minKey.
    case minKey

    /// A BSON maxKey.
    case maxKey

    /// A BSON null type.
    case null

    /// Initialize a `BSON` from an integer. On 64-bit systems, this will result in an `.int64`. On 32-bit systems,
    /// this will result in an `.int32`.
    public init(_ int: Int) {
        if MemoryLayout<Int>.size == 4 {
            self = .int32(Int32(int))
        } else {
            self = .int64(Int64(int))
        }
    }

    /// Initialize a `BSON` from a type `T`. If this is not a valid `BSON` type,
    /// if will be considered `BSON` null type and will return `nil`.
    public init<T: BSON>(_ bson: T) {
        switch bson {
        case let val as Int:
            self = .int64(Int64(val))
        case let val as Int32:
            self = .int32(val)
        case let val as Int64:
            self = .int64(val)
        case let val as Double:
            self = .double(val)
        case let val as String:
            self = .string(val)
        case let val as Data:
            self = .binary(val)
        case let val as Date:
            self = .datetime(val)
        case let val as RLMDecimal128:
            self = .decimal128(val)
        case let val as RLMObjectId:
            self = .objectId(val)
        case let val as Document:
            self = .document(val)
        case let val as Array<AnyBSON?>:
            self = .array(val)
        case let val as Bool:
            self = .bool(val)
        case is MaxKey:
            self = .maxKey
        case is MinKey:
            self = .minKey
        case let val as NSRegularExpression:
            self = .regex(val)
        default:
            self = .null
        }
    }

    /// If this `BSON` is an `.int32`, return it as an `Int32`. Otherwise, return nil.
    public var int32Value: Int32? {
        guard case let .int32(i) = self else {
            return nil
        }
        return i
    }

    /// If this `BSON` is a `.regex`, return it as a `RegularExpression`. Otherwise, return nil.
    public var regexValue: NSRegularExpression? {
        guard case let .regex(r) = self else {
            return nil
        }
        return r
    }

    /// If this `BSON` is an `.int64`, return it as an `Int64`. Otherwise, return nil.
    public var int64Value: Int64? {
        guard case let .int64(i) = self else {
            return nil
        }
        return i
    }

    /// If this `BSON` is an `.objectId`, return it as an `ObjectId`. Otherwise, return nil.
    public var objectIdValue: RLMObjectId? {
        guard case let .objectId(o) = self else {
            return nil
        }
        return o
    }

    /// If this `BSON` is a `.date`, return it as a `Date`. Otherwise, return nil.
    public var dateValue: Date? {
        guard case let .datetime(d) = self else {
            return nil
        }
        return d
    }

    /// If this `BSON` is an `.array`, return it as an `[BSON]`. Otherwise, return nil.
    public var arrayValue: [AnyBSON?]? {
        guard case let .array(a) = self else {
            return nil
        }
        return a
    }

    /// If this `BSON` is a `.string`, return it as a `String`. Otherwise, return nil.
    public var stringValue: String? {
        guard case let .string(s) = self else {
            return nil
        }
        return s
    }

    /// If this `BSON` is a `.document`, return it as a `Document`. Otherwise, return nil.
    public var documentValue: Document? {
        guard case let .document(d) = self else {
            return nil
        }
        return d
    }

    /// If this `BSON` is a `.bool`, return it as an `Bool`. Otherwise, return nil.
    public var boolValue: Bool? {
        guard case let .bool(b) = self else {
            return nil
        }
        return b
    }

    /// If this `BSON` is a `.binary`, return it as a `Binary`. Otherwise, return nil.
    public var binaryValue: Data? {
        guard case let .binary(b) = self else {
            return nil
        }
        return b
    }

    /// If this `BSON` is a `.double`, return it as a `Double`. Otherwise, return nil.
    public var doubleValue: Double? {
        guard case let .double(d) = self else {
            return nil
        }
        return d
    }

    /// If this `BSON` is a `.decimal128`, return it as a `Decimal128`. Otherwise, return nil.
    public var decimal128Value: RLMDecimal128? {
        guard case let .decimal128(d) = self else {
            return nil
        }
        return d
    }

    /// If this `BSON` is a `.timestamp`, return it as a `Timestamp`. Otherwise, return nil.
    public var timestampValue: Date? {
        guard case let .timestamp(t) = self else {
            return nil
        }
        return t
    }

    /// If this `BSON` is a `.null` return true. Otherwise, false.
    public var isNull: Bool {
        return self == .null
    }

    /// Return this BSON as an `Int` if possible.
    /// This will coerce non-integer numeric cases (e.g. `.double`) into an `Int` if such coercion would be lossless.
    public func asInt() -> Int? {
        switch self {
        case let .int32(value):
            return Int(value)
        case let .int64(value):
            return Int(exactly: value)
        case let .double(value):
            return Int(exactly: value)
        default:
            return nil
        }
    }

    /// Return this BSON as an `Int32` if possible.
    /// This will coerce numeric cases (e.g. `.double`) into an `Int32` if such coercion would be lossless.
    public func asInt32() -> Int32? {
        switch self {
        case let .int32(value):
            return value
        case let .int64(value):
            return Int32(exactly: value)
        case let .double(value):
            return Int32(exactly: value)
        default:
            return nil
        }
    }

    /// Return this BSON as an `Int64` if possible.
    /// This will coerce numeric cases (e.g. `.double`) into an `Int64` if such coercion would be lossless.
    public func asInt64() -> Int64? {
        switch self {
        case let .int32(value):
            return Int64(value)
        case let .int64(value):
            return value
        case let .double(value):
            return Int64(exactly: value)
        default:
            return nil
        }
    }

    /// Return this BSON as a `Double` if possible.
    /// This will coerce numeric cases (e.g. `.decimal128`) into a `Double` if such coercion would be lossless.
    public func asDouble() -> Double? {
        switch self {
        case let .double(d):
            return d
        default:
            guard let intValue = self.asInt() else {
                return nil
            }
            return Double(intValue)
        }
    }

    /// Return this BSON as a `Decimal128` if possible.
    /// This will coerce numeric cases (e.g. `.double`) into a `Decimal128` if such coercion would be lossless.
    public func asDecimal128() -> RLMDecimal128? {
        switch self {
        case let .decimal128(d):
            return d
        case let .int64(i):
            return try? RLMDecimal128(string: String(i))
        case let .int32(i):
            return try? RLMDecimal128(string: String(i))
        case let .double(d):
            return try? RLMDecimal128(string: String(d))
        default:
            return nil
        }
    }

    /// Return this BSON as a `T` if possible, otherwise nil.
    public func value<T: BSON>() -> T? {
        switch self {
        case .int32(let val):
            if T.self == Int.self && MemoryLayout<Int>.size == 4 {
                return Int(val) as? T
            }
            return val as? T
        case .int64(let val):
            if T.self == Int.self && MemoryLayout<Int>.size != 4 {
                return Int(val) as? T
            }
            return val as? T
        case .bool(let val):
            return val as? T
        case .double(let val):
            return val as? T
        case .string(let val):
            return val as? T
        case .binary(let val):
            return val as? T
        case .datetime(let val):
            return val as? T
        case .decimal128(let val):
            return val as? T
        case .objectId(let val):
            return val as? T
        case .document(let val):
            return val as? T
        case .array(let val):
            return val as? T
        case .maxKey:
            return MaxKey() as? T
        case .minKey:
            return MinKey() as? T
        case .regex(let val):
            return val as? T
        default:
            return nil
        }
    }
}

extension AnyBSON: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension AnyBSON: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

extension AnyBSON: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .double(value)
    }
}

extension AnyBSON: ExpressibleByIntegerLiteral {
    /// Initialize a `BSON` from an integer. On 64-bit systems, this will result in an `.int64`. On 32-bit systems,
    /// this will result in an `.int32`.
    public init(integerLiteral value: Int) {
        self.init(value)
    }
}

extension AnyBSON: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, AnyBSON?)...) {
        self = .document(Document(uniqueKeysWithValues: elements))
    }
}

extension AnyBSON: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: AnyBSON?...) {
        self = .array(elements)
    }
}

extension AnyBSON: Equatable {}

extension AnyBSON: Hashable {}

/**
 :nodoc:
 **/
private class ObjectiveCSupport {
    /// Convert an `AnyBSON` to a `RLMBSON`.
    static func convert(object: AnyBSON?) -> RLMBSON? {
        guard let object = object else {
            return nil
        }

        switch object {
        case .int32(let val):
            return val as NSNumber
        case .int64(let val):
            return val as NSNumber
        case .double(let val):
            return val as NSNumber
        case .string(let val):
            return val as NSString
        case .binary(let val):
            return val as NSData
        case .datetime(let val):
            return val as NSDate
        case .decimal128(let val):
            return val as RLMDecimal128
        case .objectId(let val):
            return val as RLMObjectId
        case .document(let val):
            return val.reduce(into: Dictionary<String, RLMBSON?>()) { (result: inout [String: RLMBSON?], kvp) in
                result[kvp.key] = convert(object: kvp.value) ?? NSNull()
            } as NSDictionary
        case .array(let val):
            return val.map(convert) as NSArray
        case .maxKey:
            return MaxKey()
        case .minKey:
            return MinKey()
        case .regex(let val):
            return val
        case .bool(let val):
            return val as NSNumber
        default:
            return nil
        }
    }

    /// Convert a `RLMBSON` to an `AnyBSON`.
    static func convert(object: RLMBSON?) -> AnyBSON? {
        guard let bson = object else {
            return nil
        }

        switch bson.__bsonType {
        case .null:
            return nil
        case .int32:
            guard let val = bson as? NSNumber else {
                return nil
            }
            return .int32(Int32(val.intValue))
        case .int64:
            guard let val = bson as? NSNumber else {
                return nil
            }
            return .int64(Int64(val.int64Value))
        case .bool:
            guard let val = bson as? NSNumber else {
                return nil
            }
            return .bool(val.boolValue)
        case .double:
            guard let val = bson as? NSNumber else {
                return nil
            }
            return .double(val.doubleValue)
        case .string:
            guard let val = bson as? NSString else {
                return nil
            }
            return .string(val as String)
        case .binary:
            guard let val = bson as? NSData else {
                return nil
            }
            return .binary(val as Data)
        case .timestamp:
            guard let val = bson as? NSDate else {
                return nil
            }
            return .timestamp(val as Date)
        case .datetime:
            guard let val = bson as? NSDate else {
                return nil
            }
            return .datetime(val as Date)
        case .objectId:
            guard let val = bson as? RLMObjectId else {
                return nil
            }
            return .objectId(val)
        case .decimal128:
            guard let val = bson as? RLMDecimal128 else {
                return nil
            }
            return .decimal128(val)
        case .regularExpression:
            guard let val = bson as? NSRegularExpression else {
                return nil
            }
            return .regex(val)
        case .maxKey:
            return .maxKey
        case .minKey:
            return .minKey
        case .document:
            guard let val = bson as? Dictionary<String, RLMBSON?> else {
                return nil
            }
            return .document(val.reduce(into: Dictionary<String, AnyBSON?>()) { (result: inout [String: AnyBSON?], kvp) in
                result[kvp.key] = convert(object: kvp.value)
            })
        case .array:
            guard let val = bson as? Array<RLMBSON?> else {
                return nil
            }
            return .array(val.map(convert))
        default:
            return nil
        }
    }
}
