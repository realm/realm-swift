////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
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
import Realm.Private

/**
 An object representing a MongoDB Realm user.

 - see: `RLMUser`
 */
public typealias User = RLMUser

/**
 A singleton which configures and manages MongoDB Realm synchronization-related
 functionality.

 - see: `RLMSyncManager`
 */
public typealias SyncManager = RLMSyncManager

/**
 Options for configuring timeouts and intervals in the sync client.

  - see: `RLMSyncTimeoutOptions`
 */
public typealias SyncTimeoutOptions = RLMSyncTimeoutOptions

/**
 A session object which represents communication between the client and server for a specific
 Realm.

 - see: `RLMSyncSession`
 */
public typealias SyncSession = RLMSyncSession

/**
 A closure type for a closure which can be set on the `SyncManager` to allow errors to be reported
 to the application.

 - see: `RLMSyncErrorReportingBlock`
 */
public typealias ErrorReportingBlock = RLMSyncErrorReportingBlock

/**
 A closure type for a closure which is used by certain APIs to asynchronously return a `SyncUser`
 object to the application.

 - see: `RLMUserCompletionBlock`
 */
public typealias UserCompletionBlock = RLMUserCompletionBlock

/**
 An error associated with the SDK's synchronization functionality. All errors reported by
 an error handler registered on the `SyncManager` are of this type.

 - see: `RLMSyncError`
 */
public typealias SyncError = RLMSyncError

extension SyncError {
    /**
     An opaque token allowing the user to take action after certain types of
     errors have been reported.

     - see: `RLMSyncErrorActionToken`
     */
    public typealias ActionToken = RLMSyncErrorActionToken

    /**
     Given a client reset error, extract and return the recovery file path
     and the action token.

     The action token can be passed into `SyncSession.immediatelyHandleError(_:)`
     to immediately delete the local copy of the Realm which experienced the
     client reset error. The local copy of the Realm must be deleted before
     your application attempts to open the Realm again.

     The recovery file path is the path to which the current copy of the Realm
     on disk will be saved once the client reset occurs.

     - warning: Do not call `SyncSession.immediatelyHandleError(_:)` until you are
                sure that all references to the Realm and managed objects belonging
                to the Realm have been nil'ed out, and that all autorelease pools
                containing these references have been drained.

     - see: `SyncError.ActionToken`, `SyncSession.immediatelyHandleError(_:)`
     */
    public func clientResetInfo() -> (String, SyncError.ActionToken)? {
        if code == SyncError.clientResetError,
            let recoveryPath = userInfo[kRLMSyncPathOfRealmBackupCopyKey] as? String,
            let token = _nsError.__rlmSync_errorActionToken() {
            return (recoveryPath, token)
        }
        return nil
    }

    /**
     Given a permission denied error, extract and return the action token.

     This action token can be passed into `SyncSession.immediatelyHandleError(_:)`
     to immediately delete the local copy of the Realm which experienced the
     permission denied error. The local copy of the Realm must be deleted before
     your application attempts to open the Realm again.

     - warning: Do not call `SyncSession.immediatelyHandleError(_:)` until you are
                sure that all references to the Realm and managed objects belonging
                to the Realm have been nil'ed out, and that all autorelease pools
                containing these references have been drained.

     - see: `SyncError.ActionToken`, `SyncSession.immediatelyHandleError(_:)`
     */
    public func deleteRealmUserInfo() -> SyncError.ActionToken? {
        return _nsError.__rlmSync_errorActionToken()
    }
}

/**
 An error associated with network requests made to the authentication server. This type of error
 may be returned in the callback block to `SyncUser.logIn()` upon certain types of failed login
 attempts (for example, if the request is malformed or if the server is experiencing an issue).

 - see: `RLMSyncAuthError`
 */
public typealias SyncAuthError = RLMSyncAuthError

/**
 An enum which can be used to specify the level of logging.

 - see: `RLMSyncLogLevel`
 */
public typealias SyncLogLevel = RLMSyncLogLevel

/**
 A data type whose values represent different authentication providers that can be used with
 MongoDB Realm.

 - see: `RLMIdentityProvider`
 */
public typealias Provider = RLMIdentityProvider

/**
 * How the Realm client should validate the identity of the server for secure connections.
 *
 * By default, when connecting to MongoDB Realm over HTTPS, Realm will
 * validate the server's HTTPS certificate using the system trust store and root
 * certificates. For additional protection against man-in-the-middle (MITM)
 * attacks and similar vulnerabilities, you can pin a certificate or public key,
 * and reject all others, even if they are signed by a trusted CA.
 */
public enum ServerValidationPolicy {
    /// Perform no validation and accept potentially invalid certificates.
    ///
    /// - warning: DO NOT USE THIS OPTION IN PRODUCTION.
    case none

    /// Use the default server trust evaluation based on the system-wide CA
    /// store. Any certificate signed by a trusted CA will be accepted.
    case system

    /// Use a specific pinned certificate to validate the server identify.
    ///
    /// This will only connect to a server if one of the server certificates
    /// matches the certificate stored at the given local path and that
    /// certificate has a valid trust chain.
    ///
    /// On macOS, the certificate files may be in any of the formats supported
    /// by SecItemImport(), including PEM and .cer (see SecExternalFormat for a
    /// complete list of possible formats). On iOS and other platforms, only
    /// DER .cer files are supported.
    case pinCertificate(path: URL)
}

/**
 A `SyncConfiguration` represents configuration parameters for Realms intended to sync with
 MongoDB Realm.
 */
public struct SyncConfiguration {
    /// The `SyncUser` who owns the Realm that this configuration should open.
    public let user: User

    /**
     The value this Realm is partitioned on. The partition key is a property defined in
     MongoDB Realm. All classes with a property with this value will be synchronized to the
     Realm.
     */
    public let partitionValue: AnyBSON?

    /**
     A policy that determines what should happen when all references to Realms opened by this
     configuration go out of scope.
     */
    internal let stopPolicy: RLMSyncStopPolicy

    /**
     By default, Realm.asyncOpen() swallows non-fatal connection errors such as
     a connection attempt timing out and simply retries until it succeeds. If
     this is set to `true`, instead the error will be reported to the callback
     and the async open will be cancelled.
     */
    public let cancelAsyncOpenOnNonFatalErrors: Bool

    internal init(config: RLMSyncConfiguration) {
        self.user = config.user
        self.stopPolicy = config.stopPolicy
        self.partitionValue = ObjectiveCSupport.convert(object: config.partitionValue)
        self.cancelAsyncOpenOnNonFatalErrors = config.cancelAsyncOpenOnNonFatalErrors
    }

    func asConfig() -> RLMSyncConfiguration {
        let c = RLMSyncConfiguration(user: user,
                                     partitionValue: ObjectiveCSupport.convert(object: partitionValue),
                                     stopPolicy: stopPolicy)
        c.cancelAsyncOpenOnNonFatalErrors = cancelAsyncOpenOnNonFatalErrors
        return c
    }
}

#if canImport(Combine)
import Combine
#endif

/// Structure providing an interface to call a MongoDB Realm function with the provided name and arguments.
///
///     user.functions.sum([1, 2, 3, 4, 5]) { sum, error in
///         guard case let .int64(value) = sum else {
///             print(error?.localizedDescription)
///         }
///
///         assert(value == 15)
///     }
///
/// The dynamic member name (`sum` in the above example) is directly associated with the function name.
/// The first argument is the `BSONArray` of arguments to be provided to the function.
/// The second and final argument is the completion handler to call when the function call is complete.
/// This handler is executed on a non-main global `DispatchQueue`.
@dynamicMemberLookup
public struct Functions {
    weak var user: User?

    fileprivate init(user: User) {
        self.user = user
    }

    /// A closure type for receiving the completion of a remote function call.
    public typealias FunctionCompletionHandler = (AnyBSON?, Error?) -> Void

    /// A closure type for the dynamic remote function type.
    public typealias Function = ([AnyBSON], @escaping FunctionCompletionHandler) -> Void

    /// The implementation of @dynamicMemberLookup that allows for dynamic remote function calls.
    public subscript(dynamicMember string: String) -> Function {
        return { (arguments: [AnyBSON], completionHandler: @escaping FunctionCompletionHandler) in
            let objcArgs = arguments.map(ObjectiveCSupport.convert) as! [RLMBSON]
            self.user?.__callFunctionNamed(string, arguments: objcArgs) { (bson: RLMBSON?, error: Error?) in
                completionHandler(ObjectiveCSupport.convert(object: bson), error)
            }
        }
    }

    #if canImport(Combine)
    /// The implementation of @dynamicMemberLookup that allows for dynamic remote function calls.
    @available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, macCatalyst 13.0, macCatalystApplicationExtension 13.0, *)
    public subscript(dynamicMember string: String) -> ([AnyBSON]) -> Future<AnyBSON, Error> {
        return { (arguments: [AnyBSON]) in
            return Future<AnyBSON, Error> { promise in
                self[dynamicMember: string](arguments, { bson, error in
                    if let bson = bson {
                        promise(.success(bson))
                    } else {
                        promise(.failure(error ?? Realm.Error.promiseFailed))
                    }
                })
            }
        }
    }
    #endif
}

public extension User {

    /**
     Create a sync configuration instance.

     Additional settings can be optionally specified. Descriptions of these
     settings follow.

     `enableSSLValidation` is true by default. It can be disabled for debugging
     purposes.

     - warning: NEVER disable SSL validation for a system running in production.
     */
    func configuration<T: BSON>(partitionValue: T) -> Realm.Configuration {
        let config = self.__configuration(withPartitionValue: ObjectiveCSupport.convert(object: AnyBSON(partitionValue))!)
        return ObjectiveCSupport.convert(object: config)
    }

    /**
     Create a sync configuration instance.

     - parameter partitionValue: Takes `nil` as a partition value.
     - parameter cancelAsyncOpenOnNonFatalErrors: By default, Realm.asyncOpen()
     swallows non-fatal connection errors such as a connection attempt timing
     out and simply retries until it succeeds. If this is set to `true`, instead
     the error will be reported to the callback and the async open will be
     cancelled.

     - warning: NEVER disable SSL validation for a system running in production.
     */
    func configuration(partitionValue: ExpressibleByNilLiteral?,
                       cancelAsyncOpenOnNonFatalErrors: Bool = false) -> Realm.Configuration {
        let config = self.__configuration(withPartitionValue: nil)
        let syncConfig = config.syncConfiguration!
        syncConfig.cancelAsyncOpenOnNonFatalErrors = cancelAsyncOpenOnNonFatalErrors
        config.syncConfiguration = syncConfig
        return ObjectiveCSupport.convert(object: config)
    }

    /**
     Create a sync configuration instance.

     - parameter partitionValue: The `BSON` value the Realm is partitioned on.
     - parameter cancelAsyncOpenOnNonFatalErrors: By default, Realm.asyncOpen()
     swallows non-fatal connection errors such as a connection attempt timing
     out and simply retries until it succeeds. If this is set to `true`, instead
     the error will be reported to the callback and the async open will be
     cancelled.

     - warning: NEVER disable SSL validation for a system running in production.
     */
    func configuration<T: BSON>(partitionValue: T,
                                cancelAsyncOpenOnNonFatalErrors: Bool = false) -> Realm.Configuration {
        let config = self.__configuration(withPartitionValue: ObjectiveCSupport.convert(object: AnyBSON(partitionValue))!)
        let syncConfig = config.syncConfiguration!
        syncConfig.cancelAsyncOpenOnNonFatalErrors = cancelAsyncOpenOnNonFatalErrors
        config.syncConfiguration = syncConfig
        return ObjectiveCSupport.convert(object: config)
    }

    /**
     The custom data of the user.
     This is configured in your MongoDB Realm App.
    */
    var customData: Document? {
        guard let rlmCustomData = self.__customData as RLMBSON?,
            let anyBSON = ObjectiveCSupport.convert(object: rlmCustomData),
            case let .document(customData) = anyBSON else {
            return nil
        }

        return customData
    }

    /// A client for interacting with a remote MongoDB instance
    /// - Parameter serviceName:  The name of the MongoDB service
    /// - Returns: A `MongoClient` which is used for interacting with a remote MongoDB service
    func mongoClient(_ serviceName: String) -> MongoClient {
        return self.__mongoClient(withServiceName: serviceName)
    }

    /// Call a MongoDB Realm function with the provided name and arguments.
    ///
    ///     user.functions.sum([1, 2, 3, 4, 5]) { sum, error in
    ///         guard case let .int64(value) = sum else {
    ///             print(error?.localizedDescription)
    ///         }
    ///
    ///         assert(value == 15)
    ///     }
    ///
    /// The dynamic member name (`sum` in the above example) is directly associated with the function name.
    /// The first argument is the `BSONArray` of arguments to be provided to the function.
    /// The second and final argument is the completion handler to call when the function call is complete.
    /// This handler is executed on a non-main global `DispatchQueue`.
    var functions: Functions {
        return Functions(user: self)
    }
}

public extension SyncSession {
    /**
     The current state of the session represented by a session object.

     - see: `RLMSyncSessionState`
     */
    typealias State = RLMSyncSessionState

    /**
     The current state of a sync session's connection.

     - see: `RLMSyncConnectionState`
     */
    typealias ConnectionState = RLMSyncConnectionState

    /**
     The transfer direction (upload or download) tracked by a given progress notification block.

     Progress notification blocks can be registered on sessions if your app wishes to be informed
     how many bytes have been uploaded or downloaded, for example to show progress indicator UIs.
     */
    enum ProgressDirection {
        /// For monitoring upload progress.
        case upload
        /// For monitoring download progress.
        case download
    }

    /**
     The desired behavior of a progress notification block.

     Progress notification blocks can be registered on sessions if your app wishes to be informed
     how many bytes have been uploaded or downloaded, for example to show progress indicator UIs.
     */
    enum ProgressMode {
        /**
         The block will be called forever, or until it is unregistered by calling
         `ProgressNotificationToken.invalidate()`.

         Notifications will always report the latest number of transferred bytes, and the
         most up-to-date number of total transferrable bytes.
         */
        case reportIndefinitely
        /**
         The block will, upon registration, store the total number of bytes
         to be transferred. When invoked, it will always report the most up-to-date number
         of transferrable bytes out of that original number of transferrable bytes.

         When the number of transferred bytes reaches or exceeds the
         number of transferrable bytes, the block will be unregistered.
         */
        case forCurrentlyOutstandingWork
    }

    /**
     A token corresponding to a progress notification block.

     Call `invalidate()` on the token to stop notifications. If the notification block has already
     been automatically stopped, calling `invalidate()` does nothing. `invalidate()` should be called
     before the token is destroyed.
     */
    typealias ProgressNotificationToken = RLMProgressNotificationToken

    /**
     A struct encapsulating progress information, as well as useful helper methods.
     */
    struct Progress {
        /// The number of bytes that have been transferred.
        public let transferredBytes: Int

        /**
         The total number of transferrable bytes (bytes that have been transferred,
         plus bytes pending transfer).

         If the notification block is tracking downloads, this number represents the size of the
         changesets generated by all other clients using the Realm.
         If the notification block is tracking uploads, this number represents the size of the
         changesets representing the local changes on this client.
         */
        public let transferrableBytes: Int

        /// The fraction of bytes transferred out of all transferrable bytes. If this value is 1,
        /// no bytes are waiting to be transferred (either all bytes have already been transferred,
        /// or there are no bytes to be transferred in the first place).
        public var fractionTransferred: Double {
            if transferrableBytes == 0 {
                return 1
            }
            let percentage = Double(transferredBytes) / Double(transferrableBytes)
            return percentage > 1 ? 1 : percentage
        }

        /// Whether all pending bytes have already been transferred.
        public var isTransferComplete: Bool {
            return transferredBytes >= transferrableBytes
        }

        internal init(transferred: UInt, transferrable: UInt) {
            transferredBytes = Int(transferred)
            transferrableBytes = Int(transferrable)
        }
    }

    /**
     Register a progress notification block.

     If the session has already received progress information from the
     synchronization subsystem, the block will be called immediately. Otherwise, it
     will be called as soon as progress information becomes available.

     Multiple blocks can be registered with the same session at once. Each block
     will be invoked on a side queue devoted to progress notifications.

     The token returned by this method must be retained as long as progress
     notifications are desired, and the `invalidate()` method should be called on it
     when notifications are no longer needed and before the token is destroyed.

     If no token is returned, the notification block will never be called again.
     There are a number of reasons this might be true. If the session has previously
     experienced a fatal error it will not accept progress notification blocks. If
     the block was configured in the `forCurrentlyOutstandingWork` mode but there
     is no additional progress to report (for example, the number of transferrable bytes
     and transferred bytes are equal), the block will not be called again.

     - parameter direction: The transfer direction (upload or download) to track in this progress notification block.
     - parameter mode:      The desired behavior of this progress notification block.
     - parameter block:     The block to invoke when notifications are available.

     - returns: A token which must be held for as long as you want notifications to be delivered.

     - see: `ProgressDirection`, `Progress`, `ProgressNotificationToken`
     */
    func addProgressNotification(for direction: ProgressDirection,
                                 mode: ProgressMode,
                                 block: @escaping (Progress) -> Void) -> ProgressNotificationToken? {
        return __addProgressNotification(for: (direction == .upload ? .upload : .download),
                                         mode: (mode == .reportIndefinitely
                                            ? .reportIndefinitely
                                            : .forCurrentlyOutstandingWork)) { transferred, transferrable in
                                                block(Progress(transferred: transferred, transferrable: transferrable))
        }
    }
}

extension Realm {
    /// :nodoc:
    @available(*, unavailable, message: "Use Results.subscribe()")
    public func subscribe<T: Object>(to objects: T.Type, where: String,
                                     completion: @escaping (Results<T>?, Swift.Error?) -> Void) {
        fatalError()
    }

    /**
     Get the SyncSession used by this Realm. Will be nil if this is not a
     synchronized Realm.
    */
    public var syncSession: SyncSession? {
        return SyncSession(for: rlmRealm)
    }
}

#if canImport(Combine)
@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, macCatalyst 13.0, macCatalystApplicationExtension 13.0, *)
public extension App {
    /// Login to a user for the Realm app.
    /// @param credentials The credentials identifying the user.
    /// @returns A publisher that eventually return `User` or `Error`.
    func login(credentials: Credentials) -> Future<User, Error> {
        return Future { promise in
            self.login(credentials: credentials) { user, error in
                if let user = user {
                promise(.success(user))
                } else {
                    promise(.failure(error ?? Realm.Error.promiseFailed))
                }
            }
        }
    }
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, macCatalyst 13.0, macCatalystApplicationExtension 13.0, *)
public extension User {
    /// Refresh a user's custom data. This will, in effect, refresh the user's auth session.
    /// @returns A publisher that eventually return `Dictionary` with user's data or `Error`.
    func refreshCustomData() -> Future<[AnyHashable: Any], Error> {
        return Future { promise in
            self.refreshCustomData { customData, error in
                if let customData = customData {
                    promise(.success(customData))
                } else {
                    promise(.failure(error ?? Realm.Error.promiseFailed))
                }
            }
        }
    }

    /// Links the currently authenticated user with a new identity, where the identity is defined by the credential
    /// specified as a parameter. This will only be successful if this `User` is the currently authenticated
    /// with the client from which it was created. On success a new user will be returned with the new linked credentials.
    /// @param credentials The `Credentials` used to link the user to a new identity.
    /// @returns A publisher that eventually return `Result.success` or `Error`.
    func linkUser(with credentials: Credentials) -> Future<User, Error> {
        return Future { promise in
            self.linkUser(with: credentials) { user, error in
                if let user = user {
                    promise(.success(user))
                } else {
                    promise(.failure(error ?? Realm.Error.promiseFailed))
                }
            }
        }
    }

    /// Removes the user
    /// This logs out and destroys the session related to this user. The completion block will return an error
    /// if the user is not found or is already removed.
    /// @returns A publisher that eventually return `Result.success` or `Error`.
    func remove() -> Future<Void, Error> {
        return Future<Void, Error> { promise in
            self.remove { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
    }

    /// Logs out the current user
    /// The users state will be set to `Removed` is they are an anonymous user or `LoggedOut` if they are authenticated by a username / password or third party auth clients
    //// If the logout request fails, this method will still clear local authentication state.
    /// @returns A publisher that eventually return `Result.success` or `Error`.
    func logOut() -> Future<Void, Error> {
        return Future<Void, Error> { promise in
            self.logOut { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
    }
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, macCatalyst 13.0, macCatalystApplicationExtension 13.0, *)
public extension MongoCollection {
    /// Encodes the provided value to BSON and inserts it. If the value is missing an identifier, one will be
    /// generated for it.
    /// @param document:  A `Document` value to insert.
    /// @returns A publisher that eventually return `ObjectId` of inserted document or `Error`.
    func insertOne(_ document: Document) -> Future<ObjectId, Error> {
        return Future { promise in
            self.insertOne(document) { objectId, error in
                if let objectId = objectId {
                    promise(.success(try! ObjectId(string: objectId.stringValue)))
                } else {
                    promise(.failure(error ?? Realm.Error.promiseFailed))
                }
            }
        }
    }

    /// Encodes the provided values to BSON and inserts them. If any values are missing identifiers,
    /// they will be generated.
    /// @param documents: The `Document` values in a bson array to insert.
    /// @returns A publisher that eventually return `[ObjectId]` of inserted documents or `Error`.
    func insertMany(_ documents: [Document]) -> Future<[ObjectId], Error> {
        return Future { promise in
            self.insertMany(documents) { objectIds, error in
                if let objectIds = objectIds?.map({ try! ObjectId(string: $0.stringValue) }) {
                    promise(.success(objectIds))
                } else {
                    promise(.failure(error ?? Realm.Error.promiseFailed))
                }
            }
        }
    }

    /// Finds the documents in this collection which match the provided filter.
    /// @param filter: A `Document` as bson that should match the query.
    /// @param options: `FindOptions` to use when executing the command.
    /// @returns A publisher that eventually return `[ObjectId]` of documents or `Error`.
    func find(filter: Document, options: FindOptions) -> Future<[Document], Error> {
        return Future { promise in
            self.find(filter: filter, options: options) { documents, error in
                let bson: [Document]? = documents?.map { $0.mapValues { ObjectiveCSupport.convert(object: $0) } }
                if let bson = bson {
                    promise(.success(bson))
                } else {
                    promise(.failure(error ?? Realm.Error.promiseFailed))
                }
            }
        }
    }

    /// Finds the documents in this collection which match the provided filter.
    /// @param filter: A `Document` as bson that should match the query.
    /// @returns A publisher that eventually return `[ObjectId]` of documents or `Error`.
    func find(filter: Document) -> Future<[Document], Error> {
        return Future { promise in
            self.find(filter: filter) { documents, error in
                let bson: [Document]? = documents?.map { $0.mapValues { ObjectiveCSupport.convert(object: $0) } }
                if let bson = bson {
                    promise(.success(bson))
                } else {
                    promise(.failure(error ?? Realm.Error.promiseFailed))
                }
            }
        }
    }

    /// Returns one document from a collection or view which matches the
    /// provided filter. If multiple documents satisfy the query, this method
    /// returns the first document according to the query's sort order or natural
    /// order.
    /// @param filter: A `Document` as bson that should match the query.
    /// @param options: `FindOptions` to use when executing the command.
    /// @returns A publisher that eventually return `Document` or `Error`.
    func findOneDocument(filter: Document, options: FindOptions) -> Future<[Document], Error> {
        return Future { promise in
            self.find(filter: filter) { documents, error in
                let bson: [Document]? = documents?.map { $0.mapValues { ObjectiveCSupport.convert(object: $0) } }
                if let bson = bson {
                    promise(.success(bson))
                } else {
                    promise(.failure(error ?? Realm.Error.promiseFailed))
                }
            }
        }
    }

    /// Returns one document from a collection or view which matches the
    /// provided filter. If multiple documents satisfy the query, this method
    /// returns the first document according to the query's sort order or natural
    /// order.
    /// @param filter: A `Document` as bson that should match the query.
    /// @returns A publisher that eventually return `Document` or `Error`.
    func findOneDocument(filter: Document) -> Future<Document, Error> {
        return Future { promise in
            self.findOneDocument(filter: filter) { document, error in
                let bson: Document? = document?.mapValues({ ObjectiveCSupport.convert(object: $0) })
                if let bson = bson {
                    promise(.success(bson))
                } else {
                    promise(.failure(error ?? Realm.Error.promiseFailed))
                }
            }
        }
    }

    /// Runs an aggregation framework pipeline against this collection.
    /// @param pipeline: A bson array made up of `Documents` containing the pipeline of aggregation operations to perform.
    /// @returns A publisher that eventually return `Document` or `Error`.
    func aggregate(pipeline: [Document]) -> Future<[Document], Error> {
        return Future { promise in
            self.aggregate(pipeline: pipeline) { documents, error in
                let bson: [Document]? = documents?.map { $0.mapValues { ObjectiveCSupport.convert(object: $0) } }
                if let bson = bson {
                    promise(.success(bson))
                } else {
                    promise(.failure(error ?? Realm.Error.promiseFailed))
                }
            }
        }
    }

    /// Counts the number of documents in this collection matching the provided filter.
    /// @param filter: A `Document` as bson that should match the query.
    /// @param limit: The max amount of documents to count
    /// @returns A publisher that eventually return `Int` count of documents or `Error`.
    func count(filter: Document, limit: Int) -> Future<Int, Error> {
        return Future { promise in
            self.count(filter: filter, limit: limit) { count, error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(count))
                }
            }
        }
    }

    /// Counts the number of documents in this collection matching the provided filter.
    /// @param filter: A `Document` as bson that should match the query.
    /// @returns A publisher that eventually return `Int` count of documents or `Error`.
    func count(filter: Document) -> Future<Int, Error> {
        return Future { promise in
            self.count(filter: filter) { count, error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(count))
                }
            }
        }
    }

    /// Deletes a single matching document from the collection.
    /// @param filter: A `Document` as bson that should match the query.
    /// @returns A publisher that eventually return `Int` count of deleted documents or `Error`.
    func deleteOneDocument(filter: Document) -> Future<Int, Error> {
        return Future { promise in
            self.deleteOneDocument(filter: filter) { count, error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(count))
                }
            }
        }
    }

    /// Deletes multiple documents
    /// @param filter: Document representing the match criteria
    /// @returns A publisher that eventually return `Int` count of deleted documents or `Error`.
    func deleteManyDocuments(filter: Document) -> Future<Int, Error> {
        return Future { promise in
            self.deleteManyDocuments(filter: filter) { count, error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(count))
                }
            }
        }
    }

    /// Updates a single document matching the provided filter in this collection.
    /// @param filter: A bson `Document` representing the match criteria.
    /// @param update: A bson `Document` representing the update to be applied to a matching document.
    /// @param upsert: When true, creates a new document if no document matches the query.
    /// @returns A publisher that eventually return `UpdateResult` or `Error`.
    func updateOneDocument(filter: Document, update: Document, upsert: Bool) -> Future<UpdateResult, Error> {
        return Future { promise in
            self.updateOneDocument(filter: filter, update: update, upsert: upsert) { updateResult, error in
                if let updateResult = updateResult {
                    promise(.success(updateResult))
                } else {
                    promise(.failure(error ?? Realm.Error.promiseFailed))
                }
            }
        }
    }

    /// Updates a single document matching the provided filter in this collection.
    /// @param filter: A bson `Document` representing the match criteria.
    /// @param update: A bson `Document` representing the update to be applied to a matching document.
    /// @returns A publisher that eventually return `UpdateResult` or `Error`.
    func updateOneDocument(filter: Document, update: Document) -> Future<UpdateResult, Error> {
        return Future { promise in
            self.updateOneDocument(filter: filter, update: update) { updateResult, error in
                if let updateResult = updateResult {
                    promise(.success(updateResult))
                } else {
                    promise(.failure(error ?? Realm.Error.promiseFailed))
                }
            }
        }
    }

    /// Updates multiple documents matching the provided filter in this collection.
    /// @param filter: A bson `Document` representing the match criteria.
    /// @param update: A bson `Document` representing the update to be applied to a matching document.
    /// @param upsert: When true, creates a new document if no document matches the query.
    /// @returns A publisher that eventually return `UpdateResult` or `Error`.
    func updateManyDocuments(filter: Document, update: Document, upsert: Bool) -> Future<UpdateResult, Error> {
        return Future { promise in
            self.updateManyDocuments(filter: filter, update: update, upsert: upsert) { updateResult, error in
                if let updateResult = updateResult {
                    promise(.success(updateResult))
                } else {
                    promise(.failure(error ?? Realm.Error.promiseFailed))
                }
            }
        }
    }

    /// Updates multiple documents matching the provided filter in this collection.
    /// @param filter: A bson `Document` representing the match criteria.
    /// @param update: A bson `Document` representing the update to be applied to a matching document.
    /// @returns A publisher that eventually return `UpdateResult` or `Error`.
    func updateManyDocuments(filter: Document, update: Document) -> Future<UpdateResult, Error> {
        return Future { promise in
            self.updateManyDocuments(filter: filter, update: update) { updateResult, error in
                if let updateResult = updateResult {
                    promise(.success(updateResult))
                } else {
                    promise(.failure(error ?? Realm.Error.promiseFailed))
                }
            }
        }
    }

    /// Updates a single document in a collection based on a query filter and
    /// returns the document in either its pre-update or post-update form. Unlike
    /// `updateOneDocument`, this action allows you to atomically find, update, and
    /// return a document with the same command. This avoids the risk of other
    /// update operations changing the document between separate find and update
    /// operations.
    /// @param filter: A bson `Document` representing the match criteria.
    /// @param update: A bson `Document` representing the update to be applied to a matching document.
    /// @param options: `RemoteFindOneAndModifyOptions` to use when executing the command.
    /// @returns A publisher that eventually return `Document` or `nil` if document wasn't found or `Error`.
    func findOneAndUpdate(filter: Document, update: Document, options: FindOneAndModifyOptions) -> Future<Document?, Error> {
        return Future { promise in
            self.findOneAndUpdate(filter: filter, update: update, options: options) { updateResult, error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    let bson: Document? = updateResult?.mapValues({ ObjectiveCSupport.convert(object: $0) })
                    promise(.success(bson))
                }
            }
        }
    }

    /// Updates a single document in a collection based on a query filter and
    /// returns the document in either its pre-update or post-update form. Unlike
    /// `updateOneDocument`, this action allows you to atomically find, update, and
    /// return a document with the same command. This avoids the risk of other
    /// update operations changing the document between separate find and update
    /// operations.
    /// @param filter: A bson `Document` representing the match criteria.
    /// @param update: A bson `Document` representing the update to be applied to a matching document.
    /// @returns A publisher that eventually return `Document` or `nil` if document wasn't found or `Error`.
    func findOneAndUpdate(filter: Document, update: Document) -> Future<Document?, Error> {
        return Future { promise in
            self.findOneAndUpdate(filter: filter, update: update) { updateResult, error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    let bson: Document? = updateResult?.mapValues({ ObjectiveCSupport.convert(object: $0) })
                    promise(.success(bson))
                }
            }
        }
    }

    /// Overwrites a single document in a collection based on a query filter and
    /// returns the document in either its pre-replacement or post-replacement
    /// form. Unlike `updateOneDocument`, this action allows you to atomically find,
    /// replace, and return a document with the same command. This avoids the
    /// risk of other update operations changing the document between separate
    /// find and update operations.
    /// @param filter: A `Document` that should match the query.
    /// @param replacement: A `Document` describing the replacement.
    /// @param options: `FindOneAndModifyOptions` to use when executing the command.
    /// @returns A publisher that eventually return `Document` or `nil` if document wasn't found or `Error`.
    func findOneAndReplace(filter: Document, replacement: Document, options: FindOneAndModifyOptions) -> Future<Document?, Error> {
        return Future { promise in
            self.findOneAndReplace(filter: filter, replacement: replacement, options: options) { updateResult, error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    let bson: Document? = updateResult?.mapValues({ ObjectiveCSupport.convert(object: $0) })
                    promise(.success(bson))
                }
            }
        }
    }

    /// Overwrites a single document in a collection based on a query filter and
    /// returns the document in either its pre-replacement or post-replacement
    /// form. Unlike `updateOneDocument`, this action allows you to atomically find,
    /// replace, and return a document with the same command. This avoids the
    /// risk of other update operations changing the document between separate
    /// find and update operations.
    /// @param filter: A `Document` that should match the query.
    /// @param replacement: A `Document` describing the replacement.
    /// @returns A publisher that eventually return `Document` or `nil` if document wasn't found or `Error`.
    func findOneAndReplace(filter: Document, replacement: Document) -> Future<Document?, Error> {
        return Future { promise in
            self.findOneAndReplace(filter: filter, replacement: replacement) { updateResult, error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    let bson: Document? = updateResult?.mapValues({ ObjectiveCSupport.convert(object: $0) })
                    promise(.success(bson))
                }
            }
        }
    }

    /// Removes a single document from a collection based on a query filter and
    /// returns a document with the same form as the document immediately before
    /// it was deleted. Unlike `deleteOneDocument`, this action allows you to atomically
    /// find and delete a document with the same command. This avoids the risk of
    /// other update operations changing the document between separate find and
    /// delete operations.
    /// @param filter: A `Document` that should match the query.
    /// @param options: `FindOneAndModifyOptions` to use when executing the command.
    /// @returns A publisher that eventually return `Document` or `nil` if document wasn't found or `Error`.
    func findOneAndDelete(filter: Document, options: FindOneAndModifyOptions) -> Future<Document?, Error> {
        return Future { promise in
            self.findOneAndDelete(filter: filter, options: options) { deleteResult, error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    let bson: Document? = deleteResult?.mapValues({ ObjectiveCSupport.convert(object: $0) })
                    promise(.success(bson))
                }
            }
        }
    }

    /// Removes a single document from a collection based on a query filter and
    /// returns a document with the same form as the document immediately before
    /// it was deleted. Unlike `deleteOneDocument`, this action allows you to atomically
    /// find and delete a document with the same command. This avoids the risk of
    /// other update operations changing the document between separate find and
    /// delete operations.
    /// @param filter: A `Document` that should match the query.
    /// @returns A publisher that eventually return `Document` or `nil` if document wasn't found or `Error`.
    func findOneAndDelete(filter: Document) -> Future<Document?, Error> {
        return Future { promise in
            self.findOneAndDelete(filter: filter) { deleteResult, error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    let bson: Document? = deleteResult?.mapValues({ ObjectiveCSupport.convert(object: $0) })
                    promise(.success(bson))
                }
            }
        }
    }
}
#endif
