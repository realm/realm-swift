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

// MARK: - Sync-related

#if REALM_ENABLE_SYNC
extension RLMSyncManager {
    public static var shared: RLMSyncManager {
        return __shared()
    }
}

extension RLMSyncUser {
    public static var current: RLMSyncUser? {
        return __current()
    }

    public static var all: [String: RLMSyncUser] {
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

    public static func logIn(with credentials: RLMSyncCredentials,
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
