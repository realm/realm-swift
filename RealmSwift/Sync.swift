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

#if !(os(iOS) && (arch(i386) || arch(arm)))
import Combine
#endif

/**
 An object representing an Atlas App Services user.

 - see: `RLMUser`
 */
public typealias User = RLMUser

public extension User {
    /// Links the currently authenticated user with a new identity, where the identity is defined by the credential
    /// specified as a parameter. This will only be successful if this `User` is the currently authenticated
    /// with the client from which it was created. On success a new user will be returned with the new linked credentials.
    /// @param credentials The `Credentials` used to link the user to a new identity.
    /// @completion A completion that eventually return `Result.success(User)` with user's data or `Result.failure(Error)`.
    func linkUser(credentials: Credentials, _ completion: @escaping (Result<User, Error>) -> Void) {
        self.__linkUser(with: ObjectiveCSupport.convert(object: credentials)) { user, error in
            if let user = user {
                completion(.success(user))
            } else {
                completion(.failure(error ?? Realm.Error.callFailed))
            }
        }
    }
}

/**
 A manager which configures and manages Atlas App Services synchronization-related
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
 Atlas App Services.

 - see: `RLMIdentityProvider`
 */
public typealias Provider = RLMIdentityProvider

/**
 * How the Realm client should validate the identity of the server for secure connections.
 *
 * By default, when connecting to Atlas App Services over HTTPS, Realm will
 * validate the server's HTTPS certificate using the system trust store and root
 * certificates. For additional protection against man-in-the-middle (MITM)
 * attacks and similar vulnerabilities, you can pin a certificate or public key,
 * and reject all others, even if they are signed by a trusted CA.
 */
@frozen public enum ServerValidationPolicy {
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
 An enum used to determines file recovery behavior in the event of a client reset.

 - see: `RLMClientResetMode`
 - see: https://docs.mongodb.com/realm/sync/error-handling/client-resets/
*/
public enum ClientResetMode {
    /// - see: `RLMClientResetModeManual`
    case manual
    /// - see: `RLMClientResetModeDiscardLocal` for more details on `.discardLocal` behavior
    ///
    /// The first `.discardLocal` function argument notifies prior to a client reset occurring.
    /// The `Realm` argument contains a frozen copy of the Realm state prior to client reset.
    /// ```
    /// user.configuration(partitionValue: "myPartition", clientResetMode: .discardLocal({ beforeRealm in
    ///    var recoveryConfig = Realm.Configuration()
    ///    recoveryConfig.fileURL = myRecoveryPath
    ///    do {
    ///        beforeRealm.writeCopy(configuration: recoveryConfig)
    ///        // The copied realm could be used later for recovery, debugging, reporting, etc.
    ///    } catch {
    ///        // handle error
    ///    }
    /// }, nil))
    /// ```
    ///  For more details on ((Realm) -> Void)? = nil,
    /// - see: `RLMClientResetBeforeBlock`
    ///
    /// The second `.discardLocal` function argument notifies after a client reset has occurred.
    /// - Within this function, the first `Realm` argument contains a frozen copy of the local Realm state prior to client reset.
    /// - Within this function, the second `Realm` argument contains the Realm state after client reset.
    /// ```
    /// user.configuration(partitionValue: "myPartition", clientResetMode: .discardLocal( nil, { beforeRealm, afterRealm in
    /// // This block could be used to add custom recovery logic, back-up a realm file, send reporting, etc.
    /// for object in before.objects(myClass.self) {
    ///     let res = after.objects(myClass.self)
    ///     if (res.filter("primaryKey == %@", object.primaryKey).first != nil) {
    ///         // ...custom recovery logic...
    ///     } else {
    ///         // ...custom recovery logic...
    ///     }
    /// }
    /// }))
    /// ```
    ///  For more details on the second block: ((Realm, Realm) -> Void)? = nil,
    /// - see: `RLMClientResetAfterBlock`
    case discardLocal(((Realm) -> Void)? = nil, ((Realm, Realm) -> Void)? = nil)
}

/**
 A `SyncConfiguration` represents configuration parameters for Realms intended to sync with
 Atlas App Services.
 */
@frozen public struct SyncConfiguration {
    /// The `SyncUser` who owns the Realm that this configuration should open.
    public var user: User {
        config.user
    }

    /**
     The value this Realm is partitioned on. The partition key is a property defined in
     Atlas App Services. All classes with a property with this value will be synchronized to the
     Realm.
     */
    public var partitionValue: AnyBSON? {
        ObjectiveCSupport.convert(object: config.partitionValue)
    }

    /**
     An enum which determines file recovery behvaior in the event of a client reset.
     - note: Defaults to `.manual`

     - see: `ClientResetMode` and `RLMClientResetMode`
     - see: https://docs.mongodb.com/realm/sync/error-handling/client-resets/
    */
    public var clientResetMode: ClientResetMode {
        switch config.clientResetMode {
        case .manual:
            return .manual
        case .discardLocal:
            return .discardLocal(ObjectiveCSupport.convert(object: config.beforeClientReset), ObjectiveCSupport.convert(object: config.afterClientReset))
        @unknown default:
            fatalError()
        }
    }

    /**
     By default, Realm.asyncOpen() swallows non-fatal connection errors such as
     a connection attempt timing out and simply retries until it succeeds. If
     this is set to `true`, instead the error will be reported to the callback
     and the async open will be cancelled.
     */
    public var cancelAsyncOpenOnNonFatalErrors: Bool {
        config.cancelAsyncOpenOnNonFatalErrors
    }

    internal let config: RLMSyncConfiguration
    internal init(config: RLMSyncConfiguration) {
        self.config = config
    }
}

/// Structure providing an interface to call an Atlas App Services function with the provided name and arguments.
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
@frozen public struct Functions {

    private let user: User

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
            let objcArgs = arguments.map(ObjectiveCSupport.convertBson)
            self.user.__callFunctionNamed(string, arguments: objcArgs) { (bson: RLMBSON?, error: Error?) in
                completionHandler(bson.map(ObjectiveCSupport.convertBson) ?? .none, error)
            }
        }
    }

    /// A closure type for receiving the completion result of a remote function call.
    public typealias ResultFunctionCompletionHandler = (Result<AnyBSON, Error>) -> Void

    /// A closure type for the dynamic remote function type.
    public typealias ResultFunction = ([AnyBSON], @escaping ResultFunctionCompletionHandler) -> Void

    /// The implementation of @dynamicMemberLookup that allows for dynamic remote function calls with a `ResultFunctionCompletionHandler` completion.
    public subscript(dynamicMember string: String) -> ResultFunction {
        return { (arguments: [AnyBSON], completionHandler: @escaping ResultFunctionCompletionHandler) in
            let objcArgs = arguments.map(ObjectiveCSupport.convertBson)
            self.user.__callFunctionNamed(string, arguments: objcArgs) { (bson: RLMBSON?, error: Error?) in
                if let b = bson.map(ObjectiveCSupport.convertBson), let bson = b {
                    completionHandler(.success(bson))
                } else {
                    completionHandler(.failure(error ?? Realm.Error.callFailed))
                }
            }
        }
    }

    /// The implementation of @dynamicMemberLookup that allows for dynamic remote function calls with a `callable` return.
    public subscript(dynamicMember string: String) -> FunctionCallable {
        FunctionCallable(name: string, user: user)
    }
}

/// Structure enabling the following syntactic sugar for user functions:
///
///     guard case let .int32(sum) = try await user.functions.sum([1, 2, 3, 4, 5]) else {
///        return
///     }
///
/// The dynamic member name (`sum` in the above example) is provided by `@dynamicMemberLookup`
/// which is directly associated with the function name.
@dynamicCallable
public struct FunctionCallable {
    fileprivate let name: String
    fileprivate let user: User

    #if !(os(iOS) && (arch(i386) || arch(arm)))
    /// The implementation of @dynamicCallable that allows  for `Future<AnyBSON, Error>` callable return.
    ///
    ///     let cancellable = user.functions.sum([1, 2, 3, 4, 5])
    ///        .sink(receiveCompletion: { result in
    ///     }, receiveValue: { value in
    ///        // Returned value from function
    ///     })
    ///
    @available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, macCatalyst 13.0, macCatalystApplicationExtension 13.0, *)
    public func dynamicallyCall(withArguments args: [[AnyBSON]]) -> Future<AnyBSON, Error> {
        return Future<AnyBSON, Error> { promise in
            let objcArgs = args.first!.map(ObjectiveCSupport.convertBson)
            self.user.__callFunctionNamed(name, arguments: objcArgs) { (bson: RLMBSON?, error: Error?) in
                if let b = bson.map(ObjectiveCSupport.convertBson), let bson = b {
                    promise(.success(bson))
                } else {
                    promise(.failure(error ?? Realm.Error.callFailed))
                }
            }
        }
    }
    #else
    /// :nodoc:
    public func dynamicallyCall(withArguments args: [Never]) {
        //   noop
    }
    #endif
}

public extension User {

    /**
     Create a sync configuration instance.

     Additional settings can be optionally specified. Descriptions of these
     settings follow.

     `ClientResetMode` is `.manual` by default.

     - warning: NEVER disable SSL validation for a system running in production.
     */
    func configuration<T: BSON>(partitionValue: T) -> Realm.Configuration {
        let config = self.__configuration(withPartitionValue: ObjectiveCSupport.convert(object: AnyBSON(partitionValue)))
        return ObjectiveCSupport.convert(object: config)
    }

    /**
     Create a sync configuration instance.

     - parameter partitionValue: The `BSON` value the Realm is partitioned on.
     - parameter clientResetMode: Determines file recovery behavior during a client reset.
     - parameter notifyBeforeClientReset: A callback which notifies prior to a client reset occurring. See: `notifyBeforeClientReset`.
     - parameter notifyAfterClientReset: A callback which notifies after a client reset has occurred. See: `notifyAfterClientReset`.
     */
    func configuration<T: BSON>(partitionValue: T,
                                clientResetMode: ClientResetMode) -> Realm.Configuration {
        var config: RLMRealmConfiguration
        switch clientResetMode {
        case .manual:
            config = self.__configuration(withPartitionValue: ObjectiveCSupport.convert(object: AnyBSON(partitionValue)),
                                              clientResetMode: .manual)
        case .discardLocal(let beforeClientReset, let afterClientReset):
            config = self.__configuration(withPartitionValue: ObjectiveCSupport.convert(object: AnyBSON(partitionValue)),
                                              clientResetMode: .discardLocal,
                                              notifyBeforeReset: ObjectiveCSupport.convert(object: beforeClientReset),
                                              notifyAfterReset: ObjectiveCSupport.convert(object: afterClientReset))
        }
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
    func configuration(partitionValue: AnyBSON,
                       cancelAsyncOpenOnNonFatalErrors: Bool = false) -> Realm.Configuration {
        let config = self.__configuration(withPartitionValue: ObjectiveCSupport.convert(object: partitionValue))
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
        let config = self.__configuration(withPartitionValue: ObjectiveCSupport.convert(object: AnyBSON(partitionValue)))
        let syncConfig = config.syncConfiguration!
        syncConfig.cancelAsyncOpenOnNonFatalErrors = cancelAsyncOpenOnNonFatalErrors
        config.syncConfiguration = syncConfig
        return ObjectiveCSupport.convert(object: config)
    }

    /**
     The custom data of the user.
     This is configured in your Atlas App Services app.
    */
    var customData: Document {
        guard let rlmCustomData = self.__customData as RLMBSON?,
            let anyBSON = ObjectiveCSupport.convert(object: rlmCustomData),
            case let .document(customData) = anyBSON else {
            return [:]
        }

        return customData
    }

    /// A client for interacting with a remote MongoDB instance
    /// - Parameter serviceName:  The name of the MongoDB service
    /// - Returns: A `MongoClient` which is used for interacting with a remote MongoDB service
    func mongoClient(_ serviceName: String) -> MongoClient {
        return self.__mongoClient(withServiceName: serviceName)
    }

    /// Call an Atlas App Services function with the provided name and arguments.
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

#if !(os(iOS) && (arch(i386) || arch(arm)))
@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, macCatalyst 13.0, macCatalystApplicationExtension 13.0, *)
public extension User {
    /// Refresh a user's custom data. This will, in effect, refresh the user's auth session.
    /// @returns A publisher that eventually return `Dictionary` with user's data or `Error`.
    func refreshCustomData() -> Future<[AnyHashable: Any], Error> {
        return Future { self.refreshCustomData($0) }
    }

    /// Links the currently authenticated user with a new identity, where the identity is defined by the credential
    /// specified as a parameter. This will only be successful if this `User` is the currently authenticated
    /// with the client from which it was created. On success a new user will be returned with the new linked credentials.
    /// @param credentials The `Credentials` used to link the user to a new identity.
    /// @returns A publisher that eventually return `Result.success` or `Error`.
    func linkUser(credentials: Credentials) -> Future<User, Error> {
        return Future { self.linkUser(credentials: credentials, $0) }
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

    /// Permanently deletes this user from your Atlas App Services app.
    /// The users state will be set to `Removed` and the session will be destroyed.
    /// If the delete request fails, the local authentication state will be untouched.
    /// @returns A publisher that eventually return `Result.success` or `Error`.
    func delete() -> Future<Void, Error> {
        return Future<Void, Error> { promise in
            self.delete { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
    }
}

/// :nodoc:
@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, macCatalyst 13.0, macCatalystApplicationExtension 13.0, *)
@frozen public struct UserSubscription: Subscription {
    private let user: User
    private let token: RLMUserSubscriptionToken

    internal init(user: User, token: RLMUserSubscriptionToken) {
        self.user = user
        self.token = token
    }

    /// A unique identifier for identifying publisher streams.
    public var combineIdentifier: CombineIdentifier {
        return CombineIdentifier(NSNumber(value: token.value))
    }

    /// This function is not implemented.
    ///
    /// Realm publishers do not support backpressure and so this function does nothing.
    public func request(_ demand: Subscribers.Demand) {
    }

    /// Stop emitting values on this subscription.
    public func cancel() {
        user.unsubscribe(token)
    }
}

/// :nodoc:
@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, macCatalyst 13.0, macCatalystApplicationExtension 13.0, *)
public class UserPublisher: Publisher {
    /// This publisher cannot fail.
    public typealias Failure = Never
    /// This publisher emits User.
    public typealias Output = User

    private let user: User

    internal init(_ user: User) {
        self.user = user
    }

    /// :nodoc:
    public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Never, Output == S.Input {
        let token = user.subscribe { _ in
            _ = subscriber.receive(self.user)
        }

        subscriber.receive(subscription: UserSubscription(user: user, token: token))
    }
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, macCatalyst 13.0, macCatalystApplicationExtension 13.0, *)
extension User: ObservableObject {
    /// A publisher that emits Void each time the user changes.
    ///
    /// Despite the name, this actually emits *after* the user has changed.
    public var objectWillChange: UserPublisher {
        return UserPublisher(self)
    }
}
#endif

public extension User {
    /// Refresh a user's custom data. This will, in effect, refresh the user's auth session.
    /// @completion A completion that eventually return `Result.success(Dictionary)` with user's data or `Result.failure(Error)`.
    func refreshCustomData(_ completion: @escaping (Result<[AnyHashable: Any], Error>) -> Void) {
        self.refreshCustomData { customData, error in
            if let customData = customData {
                completion(.success(customData))
            } else {
                completion(.failure(error ?? Realm.Error.callFailed))
            }
        }
    }
}

#if swift(>=5.6) && canImport(_Concurrency)
@available(macOS 10.15, tvOS 13.0, iOS 13.0, watchOS 6.0, *)
public extension User {
    /// Links the currently authenticated user with a new identity, where the identity is defined by the credential
    /// specified as a parameter. This will only be successful if this `User` is the currently authenticated
    /// with the client from which it was created. On success a new user will be returned with the new linked credentials.
    /// - Parameters:
    ///   - credentials: The `Credentials` used to link the user to a new identity.
    /// - Returns:A `User` after successfully update its identity.
    func linkUser(credentials: Credentials) async throws -> User {
        return try await withCheckedThrowingContinuation { continuation in
            linkUser(credentials: credentials, continuation.resume)
        }
    }
}

@available(macOS 10.15, tvOS 13.0, iOS 13.0, watchOS 6.0, *)
extension FunctionCallable {
    /// The implementation of @dynamicMemberLookup that allows  for `async await` callable return.
    ///
    ///     guard case let .int32(sum) = try await user.functions.sum([1, 2, 3, 4, 5]) else {
    ///        return
    ///     }
    ///
    public func dynamicallyCall(withArguments args: [[AnyBSON]]) async throws -> AnyBSON {
        try await withCheckedThrowingContinuation { continuation in
            let objcArgs = args.first!.map(ObjectiveCSupport.convertBson)
            self.user.__callFunctionNamed(name, arguments: objcArgs) { (bson: RLMBSON?, error: Error?) in
                if let b = bson.map(ObjectiveCSupport.convertBson), let bson = b {
                    continuation.resume(returning: bson)
                } else {
                    continuation.resume(throwing: error ?? Realm.Error.callFailed)
                }
            }
        }
    }
}
#endif // swift(>=5.6)

extension User {
    /**
     Create a flexible sync configuration instance, which can be used to open a realm  which
     supports flexible sync.

     It won't be possible to combine flexible and partition sync in the same app, which means if you open
     a realm with a flexible sync configuration, you won't be able to open a realm with a PBS configuration
     and the other way around.

     @return A `Realm.Configuration` instance with a flexible sync configuration.
     */
    public func flexibleSyncConfiguration() -> Realm.Configuration {
        let config = self.__flexibleSyncConfiguration()
        return ObjectiveCSupport.convert(object: config)
    }

    /**
     Create a flexible sync configuration instance, which can be used to open a realm  which
     supports flexible sync.

     It won't be possible to combine flexible and partition sync in the same app, which means if you open
     a realm with a flexible sync configuration, you won't be able to open a realm with a PBS configuration
     and the other way around.

     Using `rerunOnOpen` covers the cases where you want to re-run dynamic queries, for example time ranges.
     ```
     var config = user.flexibleSyncConfiguration(initialSubscriptions: { subscriptions in
         subscriptions.append(QuerySubscription<User>() {
             $0.birthdate < Date() && $0.birthdate > Calendar.current.date(byAdding: .year, value: 21)!
         })
     }, rerunOnOpen: true)
     ```

     - parameter initialSubscriptions: A block which receives a subscription set instance, that can be used to add an
                                       initial set of subscriptions which will be executed when the Realm is first opened.
     - parameter rerunOnOpen:          If true, allows to run the initial set of subscriptions specified, on every app startup.
                                       This can be used to re-run dynamic time ranges and other queries that require a
                                       re-computation of a static variable.


     @return A `Realm.Configuration` instance with a flexible sync configuration.
     */
    public func flexibleSyncConfiguration(initialSubscriptions: @escaping ((SyncSubscriptionSet) -> Void), rerunOnOpen: Bool = false) -> Realm.Configuration {
        let config = self.__flexibleSyncConfiguration(initialSubscriptions: ObjectiveCSupport.convert(block: initialSubscriptions), rerunOnOpen: rerunOnOpen)
        return ObjectiveCSupport.convert(object: config)
    }
}
