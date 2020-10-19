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

// TODO:
// ~RLMMongoCollection.h~
// ~RLMEmailPasswordAuth.h~
// ~RLMApp.h~
// ~RLMBSON.h~
// Did not wrap @property (readonly) RLMBSONType bsonType NS_REFINED_FOR_SWIFT; since it's internally used by
//     /// Convert a `RLMBSON` to an `AnyBSON`.
// static func convert(object: RLMBSON?) -> AnyBSON? {
// ~RLMSyncSession.h~
// RLMUser.h
// RLMDecimal128.h?
// RLMRealm.h

extension RLMApp {
    public func login(withCredential credentials: RLMCredentials,
                      completion: @escaping RLMUserCompletionBlock) {
        return self.__login(withCredential: credentials, completion: completion)
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    public func setASAuthorizationControllerDelegateForController(controller: ASAuthorizationController) {
        return __setASAuthorizationControllerDelegateFor(controller)
    }
}

extension RLMMongoCollection {

    public func insertOne(document: [String : RLMBSON], completion: @escaping RLMMongoInsertBlock) {
        return self.__insertOneDocument(document, completion: completion)
    }

    public func insertMany(documents: Array<[String : RLMBSON]>, completion: @escaping RLMMongoInsertManyBlock) {
        return self.__insertManyDocuments(documents, completion: completion)
    }

    public func find(filterDocument: [String : RLMBSON], completion: @escaping RLMMongoFindBlock) {
        return self.__findWhere(filterDocument, completion: completion)
    }

    public func find(filterDocument: [String: RLMBSON], options: RLMFindOptions,completion: @escaping RLMMongoFindBlock) {
        return self.__findWhere(filterDocument, options: options, completion: completion)
    }

    public func findOne(filterDocument: [String : RLMBSON], completion: @escaping RLMMongoFindOneBlock) {
        return self.__findOneDocumentWhere(filterDocument, completion: completion)
    }

    public func findOne(filterDocument: [String : RLMBSON], options: RLMFindOptions, completion: @escaping RLMMongoFindOneBlock) {
        return self.__findOneDocumentWhere(filterDocument, options: options, completion: completion)
    }

    public func aggregate(withPipeline pipeline: [[String : RLMBSON]], completion: @escaping RLMMongoFindBlock) {
        return self.__aggregate(withPipeline: pipeline, completion: completion)
    }

    public func count(filterDocument: [String : RLMBSON], completion: @escaping RLMMongoCountBlock) {
        return self.__countWhere(filterDocument, completion: completion)
    }

    public func count(filterDocument: [String : RLMBSON], limit: Int, completion: @escaping RLMMongoCountBlock) {
        return self.__countWhere(filterDocument, limit: limit, completion: completion)
    }

    public func deleteOneDocument(filterDocument: [String : RLMBSON], completion: @escaping RLMMongoCountBlock) {
        return self.__deleteOneDocumentWhere(filterDocument, completion: completion)
    }

    public func deleteManyDocuments(filterDocument: [String : RLMBSON], completion: @escaping RLMMongoCountBlock) {
        return self.__deleteManyDocumentsWhere(filterDocument, completion: completion)
    }

    public func updateOneDocument(filterDocument: [String : RLMBSON], updateDocument: [String : RLMBSON], completion: @escaping RLMMongoUpdateBlock) {
        return self.__updateOneDocumentWhere(filterDocument, updateDocument: updateDocument, completion: completion)
    }

    public func updateOneDocument(filterDocument: [String : RLMBSON], updateDocument: [String : RLMBSON], upsert: Bool, completion: @escaping RLMMongoUpdateBlock) {
        return self.__updateOneDocumentWhere(filterDocument, updateDocument: updateDocument, upsert: upsert, completion: completion)
    }

    public func updateManyDocuments(filterDocument: [String : RLMBSON], updateDocument: [String : RLMBSON], upsert: Bool, completion: @escaping RLMMongoUpdateBlock) {
        return self.__updateManyDocumentsWhere(filterDocument, updateDocument: updateDocument, upsert: upsert, completion: completion)
    }

    public func updateManyDocuments(filterDocument: [String : RLMBSON], updateDocument: [String : RLMBSON], completion: @escaping RLMMongoUpdateBlock) {
        return self.__updateManyDocumentsWhere(filterDocument, updateDocument: updateDocument, completion: completion)
    }

    public func findOneAndUpdate(filterDocument: [String : RLMBSON], updateDocument: [String : RLMBSON], options: RLMFindOneAndModifyOptions, completion: @escaping RLMMongoFindOneBlock) {
        return self.__findOneAndUpdateWhere(filterDocument, updateDocument: updateDocument, completion: completion)
    }

    public func findOneAndUpdate(filterDocument: [String : RLMBSON], updateDocument: [String : RLMBSON], completion: @escaping RLMMongoFindOneBlock) {
        return self.__findOneAndUpdateWhere(filterDocument, updateDocument: updateDocument, completion: completion)
    }

    public func findOneAndReplace(filterDocument: [String : RLMBSON], replacementDocument: [String : RLMBSON], options: RLMFindOneAndModifyOptions, completion: @escaping RLMMongoFindOneBlock) {
        return self.__findOneAndReplaceWhere(filterDocument, replacementDocument: replacementDocument, options: options, completion: completion)
    }

    public func findOneAndReplace(filterDocument: [String : RLMBSON], replacementDocument: [String : RLMBSON], completion: @escaping RLMMongoFindOneBlock) {
        return self.__findOneAndReplaceWhere(filterDocument, replacementDocument: replacementDocument, completion: completion)
    }

    public func findOneAndDelete(filterDocument: [String : RLMBSON], options: RLMFindOneAndModifyOptions, completion: @escaping RLMMongoDeleteBlock) {
        return self.__findOneAndDeleteWhere(filterDocument, options: options, completion: completion)
    }

    public func findOneAndDelete(filterDocument: [String : RLMBSON], completion: @escaping RLMMongoDeleteBlock) {
        return self.__findOneAndDeleteWhere(filterDocument, completion: completion)
    }

    public func watch(withDelegate delegate: RLMChangeEventDelegate, queue: DispatchQueue?) -> RLMChangeStream {
        return self.__watch(with: delegate, delegateQueue: queue)
    }

    public func watch(withFilterIds filterIds: [RLMObjectId], delegate: RLMChangeEventDelegate, queue: DispatchQueue?) -> RLMChangeStream {
        return self.__watch(withFilterIds: filterIds, delegate: delegate, delegateQueue: queue)
    }

    public func watch(withMatchFilter matchFilter: [String : RLMBSON], delegate: RLMChangeEventDelegate, queue: DispatchQueue?) -> RLMChangeStream {
        return self.__watch(withMatchFilter: matchFilter, delegate: delegate, delegateQueue: queue)
    }
}

extension RLMEmailPasswordAuth {
    public func callResetPasswordFunction(email: String,
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
        return self.__addProgressNotification(for: direction, mode: mode, block: block)
    }
}

// MARK: - Sync-related

#if REALM_ENABLE_SYNC
extension RLMSyncManager {
    public static var shared: RLMSyncManager {
        return __shared()
    }
}

extension RLMUser {
    public static var current: RLMUser? {
        return __current()
    }

    public static var all: [String: RLMUser] {
        return __allUsers()
    }

    @nonobjc public var errorHandler: RLMUserErrorReportingBlock? {
        get {
            return __errorHandler
        }
        set {
            __errorHandler = newValue
        }
    }

    public static func logIn(with credentials: RLMCredentials,
                             server authServerURL: URL,
                             timeout: TimeInterval = 30,
                             callbackQueue queue: DispatchQueue = DispatchQueue.main,
                             onCompletion completion: @escaping RLMUserCompletionBlock) {
        return __logIn(with: credentials,
                       authServerURL: authServerURL,
                       timeout: timeout,
                       callbackQueue: queue,
                       onCompletion: completion)
    }

    public func configuration(realmURL: URL? = nil, fullSynchronization: Bool = false,
                              enableSSLValidation: Bool = true, urlPrefix: String? = nil) -> RLMRealmConfiguration {
        return self.__configuration(with: realmURL,
                                    fullSynchronization: fullSynchronization,
                                    enableSSLValidation: enableSSLValidation,
                                    urlPrefix: urlPrefix)
    }
}

extension RLMSyncSession {
    public func addProgressNotification(for direction: RLMSyncProgressDirection,
                                        mode: RLMSyncProgressMode,
                                        block: @escaping RLMProgressNotificationBlock) -> RLMProgressNotificationToken? {
        return __addProgressNotification(for: direction,
                                         mode: mode,
                                         block: block)
    }
}
#endif
