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

import Combine
import Realm
import Realm.Private

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
    @preconcurrency
    func linkUser(credentials: Credentials, _ completion: @Sendable @escaping (Result<User, Error>) -> Void) {
        self.__linkUser(with: ObjectiveCSupport.convert(object: credentials)) { user, error in
            if let user = user {
                completion(.success(user))
            } else {
                completion(.failure(error ?? Realm.Error.callFailed))
            }
        }
    }

    /// Links the currently authenticated user with a new identity, where the identity is defined by the credential
    /// specified as a parameter. This will only be successful if this `User` is the currently authenticated
    /// with the client from which it was created. On success a new user will be returned with the new linked credentials.
    /// @param credentials The `Credentials` used to link the user to a new identity.
    /// @returns A publisher that eventually return `Result.success` or `Error`.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func linkUser(credentials: Credentials) -> Future<User, Error> {
        return future { self.linkUser(credentials: credentials, $0) }
    }

    /// Links the currently authenticated user with a new identity, where the identity is defined by the credential
    /// specified as a parameter. This will only be successful if this `User` is the currently authenticated
    /// with the client from which it was created. On success a new user will be returned with the new linked credentials.
    /// - Parameters:
    ///   - credentials: The `Credentials` used to link the user to a new identity.
    /// - Returns:A `User` after successfully update its identity.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func linkUser(credentials: Credentials) async throws -> User {
        try await __linkUser(with: ObjectiveCSupport.convert(object: credentials))
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
public extension SyncTimeoutOptions {
    /**
    Memberwise convenience initializer for SyncTimeoutOptions. All values are
    in milliseconds, and use a default value if `nil`.

    - Parameters:
      - connectTimeout: The maximum time to allow for a connection to become
        fully established. This includes the time to resolve the network
        address, the TCP connect operation, the SSL handshake, and the
        WebSocket handshake.
      - connectionLingerTime: If session multiplexing is enabled, how long to
        keep connections open while there are no active session.
      - pingKeepalivePeriod: How long to wait between each ping message sent to
        the server. The client periodically sends ping messages to the server
        to check if the connection is still alive. Shorter periods make
        connection state change notifications more responsive at the cost of
        battery life (as the antenna will have to wake up more often).
      - pongKeepaliveTimeout: How long to wait for the server to respond to a
        ping message. Shorter values make connection state change notifications
        more responsive, but increase the chance of spurious disconnections.
      - fastReconnectLimit: When a client first connects to the server, it
        downloads all data from the server before it begins to upload local
        changes. This typically reduces the total amount of merging needed and
        gets the local client into a useful state faster. If a disconnect and
        reconnect happens within the time span of the fast reconnect limit,
        this is skipped and the session behaves as if it were continuously
        connected.
     */
    convenience init(connectTimeout: UInt? = nil,
                     connectionLingerTime: UInt? = nil,
                     pingKeepalivePeriod: UInt? = nil,
                     pongKeepaliveTimeout: UInt? = nil,
                     fastReconnectLimit: UInt? = nil) {
        self.init()
        if let connectTimeout {
            self.connectTimeout = connectTimeout
        }
        if let connectionLingerTime {
            self.connectionLingerTime = connectionLingerTime
        }
        if let pingKeepalivePeriod {
            self.pingKeepalivePeriod = pingKeepalivePeriod
        }
        if let pongKeepaliveTimeout {
            self.pongKeepaliveTimeout = pongKeepaliveTimeout
        }
        if let fastReconnectLimit {
            self.fastReconnectLimit = fastReconnectLimit
        }
    }
}

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

    /**
     Sync errors which originate from the server also produce server-side logs
     which may contain useful information. When applicable, this field contains
     the url of those logs, and `nil` otherwise.
     */
    public var serverLogURL: URL? {
        (userInfo[RLMServerLogURLKey] as? String).flatMap(URL.init)
    }

    /// Extended information about what was reverted for `.writeRejected` errors.
    public var compensatingWriteInfo: [CompensatingWriteInfo]? {
        userInfo[RLMCompensatingWriteInfoKey] as? [CompensatingWriteInfo]
    }
}

/// Extended information about a write which was rejected by the server.
///
/// The server will sometimes reject writes made by the client for reasons such
/// as permissions, additional server-side validation failing, or because the
/// object didn't match any flexible sync subscriptions. When this happens, a
/// `.writeRejected` error is reported with a non-nil
/// ``SyncError.compensatingWriteInfo`` field with information about what
/// writes were rejected and why.
///
/// This information is intended for debugging and logging purposes only. The
/// `reason` strings are generated by the server and are not guaranteed to be
/// stable, so attempting to programmatically do anything with them will break
/// without warning.
public typealias CompensatingWriteInfo = RLMCompensatingWriteInfo
extension CompensatingWriteInfo {
    /// The primary key of the object being written to.
    public var primaryKey: AnyRealmValue {
        ObjectiveCSupport.convert(value: __primaryKey)
    }
}

/**
 An error which occurred when making a request to Atlas App Services. Most User
 and App functions which can fail report errors of this type.
 */
public typealias AppError = RLMAppError

extension AppError {
    /// When applicable, the HTTP status code which resulted in this error.
    var httpStatusCode: Int? {
        userInfo[RLMHTTPStatusCodeKey] as? Int
    }
}

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
 An enum used to determines file recovery behavior in the event of a client reset.
 Defaults to ``.recoverUnsyncedChanges``.

 - see: `RLMClientResetMode`
 - see: https://docs.mongodb.com/realm/sync/error-handling/client-resets/
*/
@frozen public enum ClientResetMode {
    /// All unsynchronized local changes are automatically discarded and the local state is
    /// automatically reverted to the most recent state from the server. Unsynchronized changes
    /// can then be recovered in the post-client-reset callback block.
    ///
    /// If ``.discardLocal`` is enabled but the client reset operation is unable to complete
    /// then the client reset process reverts to manual mode. Example: During a destructive schema change this
    /// mode will fail and invoke the manual client reset handler.
    ///
    /// - parameter beforeReset: a function invoked prior to a client reset occurring.
    /// - parameter before: a frozen copy of the local Realm state prior to client reset.
    /// - seeAlso ``RLMClientResetBeforeBlock``

    /// Example Usage
    /// ```
    /// user.configuration(partitionValue: "myPartition", clientResetMode: .discardUnsyncedChanges({ before in
    ///    var recoveryConfig = Realm.Configuration()
    ///    recoveryConfig.fileURL = myRecoveryPath
    ///    do {
    ///        before.writeCopy(configuration: recoveryConfig)
    ///        // The copied realm could be used later for recovery, debugging, reporting, etc.
    ///    } catch {
    ///        // handle error
    ///    }
    /// }, nil))
    /// ```
    ///
    /// - parameter afterReset: a function invoked  after the client reset reset process has occurred.
    /// - parameter before: a frozen copy of the local Realm state prior to client reset.
    /// - parameter after: a live instance of the realm after client reset.
    /// - seeAlso ``RLMClientResetAfterBlock``
    ///
    /// Example Usage
    /// ```
    /// user.configuration(partitionValue: "myPartition", clientResetMode: .discardUnsyncedChanges( nil, { before, after in
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
    @available(*, deprecated, message: "Use discardUnsyncedChanges")
    @preconcurrency
    case discardLocal(beforeReset: (@Sendable (_ before: Realm) -> Void)? = nil,
                      afterReset: (@Sendable (_ before: Realm, _ after: Realm) -> Void)? = nil)
    /// All unsynchronized local changes are automatically discarded and the local state is
    /// automatically reverted to the most recent state from the server. Unsynchronized changes
    /// can then be recovered in the post-client-reset callback block.
    ///
    /// If ``.discardUnsyncedChanges`` is enabled but the client reset operation is unable to complete
    /// then the client reset process reverts to manual mode. Example: During a destructive schema change this
    /// mode will fail and invoke the manual client reset handler.
    ///
    /// - parameter beforeReset: a function invoked prior to a client reset occurring.
    /// - parameter before: a frozen copy of the local Realm state prior to client reset.
    /// - seeAlso ``RLMClientResetBeforeBlock``

    /// Example Usage
    /// ```
    /// user.configuration(partitionValue: "myPartition", clientResetMode: .discardUnsyncedChanges({ before in
    ///    var recoveryConfig = Realm.Configuration()
    ///    recoveryConfig.fileURL = myRecoveryPath
    ///    do {
    ///        before.writeCopy(configuration: recoveryConfig)
    ///        // The copied realm could be used later for recovery, debugging, reporting, etc.
    ///    } catch {
    ///        // handle error
    ///    }
    /// }, nil))
    /// ```
    ///
    /// - parameter afterReset: a function invoked  after the client reset reset process has occurred.
    /// - parameter before: a frozen copy of the local Realm state prior to client reset.
    /// - parameter after: a live instance of the realm after client reset.
    /// - seeAlso ``RLMClientResetAfterBlock``
    ///
    /// Example Usage
    /// ```
    /// user.configuration(partitionValue: "myPartition", clientResetMode: .discardUnsyncedChanges( nil, { before, after in
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
    @preconcurrency
    case discardUnsyncedChanges(beforeReset: (@Sendable (_ before: Realm) -> Void)? = nil,
                                afterReset: (@Sendable (_ before: Realm, _ after: Realm) -> Void)? = nil)
    /// The client device will download a realm realm which reflects the latest
    /// state of the server after a client reset. A recovery process is run locally in
    /// an attempt to integrate the server version with any local changes from
    /// before the client reset occurred.
    ///
    /// The changes are integrated with the following rules:
    /// 1. Objects created locally that were not synced before client reset will be integrated.
    /// 2. If an object has been deleted on the server, but was modified on the client, the delete takes precedence and the update is discarded
    /// 3. If an object was deleted on the client, but not the server, then the client delete instruction is applied.
    /// 4. In the case of conflicting updates to the same field, the client update is applied.
    ///
    /// If the recovery integration fails, the client reset process falls back to ``ClientResetMode.manual``.
    /// The recovery integration will fail if the "Client Recovery" setting is not enabled on the server.
    /// Integration may also fail in the event of an incompatible schema change.
    ///
    /// - parameter beforeReset: a function invoked prior to a client reset occurring.
    /// - parameter before: a frozen copy of the local Realm state prior to client reset.
    /// - seeAlso ``RLMClientResetBeforeBlock``

    /// Example Usage
    /// ```
    /// user.configuration(partitionValue: "myPartition", clientResetMode: .discardUnsyncedChanges({ before in
    ///    var recoveryConfig = Realm.Configuration()
    ///    recoveryConfig.fileURL = myRecoveryPath
    ///    do {
    ///        before.writeCopy(configuration: recoveryConfig)
    ///        // The copied realm could be used later for recovery, debugging, reporting, etc.
    ///    } catch {
    ///        // handle error
    ///    }
    /// }, nil))
    /// ```
    ///
    /// - parameter afterReset: a function invoked  after the client reset reset process has occurred.
    /// - parameter before: a frozen copy of the local Realm state prior to client reset.
    /// - parameter after: a live instance of the realm after client reset.
    /// - seeAlso ``RLMClientResetAfterBlock``
    ///
    /// Example Usage
    /// ```
    /// user.configuration(partitionValue: "myPartition", clientResetMode: .discardUnsyncedChanges( nil, { before, after in
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
    @preconcurrency
    case recoverUnsyncedChanges(beforeReset: (@Sendable (_ before: Realm) -> Void)? = nil,
                                afterReset: (@Sendable (_ before: Realm, _ after: Realm) -> Void)? = nil)
    /// The client device will download a realm with objects reflecting the latest version of the server. A recovery
    /// process is run locally in an attempt to integrate the server version with any local changes from before the
    /// client reset occurred.
    ///
    /// The changes are integrated with the following rules:
    /// 1. Objects created locally that were not synced before client reset will be integrated.
    /// 2. If an object has been deleted on the server, but was modified on the client, the delete takes precedence and the update is discarded
    /// 3. If an object was deleted on the client, but not the server, then the client delete instruction is applied.
    /// 4. In the case of conflicting updates to the same field, the client update is applied.
    ///
    /// If the recovery integration fails, the client reset process falls back to ``ClientResetMode.discardUnsyncedChanges``.
    /// The recovery integration will fail if the "Client Recovery" setting is not enabled on the server.
    /// Integration may also fail in the event of an incompatible schema change.
    ///
    /// - parameter beforeReset: a function invoked prior to a client reset occurring.
    /// - parameter before: a frozen copy of the local Realm state prior to client reset.
    /// - seeAlso ``RLMClientResetBeforeBlock``

    /// Example Usage
    /// ```
    /// user.configuration(partitionValue: "myPartition", clientResetMode: .discardUnsyncedChanges({ before in
    ///    var recoveryConfig = Realm.Configuration()
    ///    recoveryConfig.fileURL = myRecoveryPath
    ///    do {
    ///        before.writeCopy(configuration: recoveryConfig)
    ///        // The copied realm could be used later for recovery, debugging, reporting, etc.
    ///    } catch {
    ///        // handle error
    ///    }
    /// }, nil))
    /// ```
    ///
    /// - parameter afterReset: a function invoked  after the client reset reset process has occurred.
    /// - parameter before: a frozen copy of the local Realm state prior to client reset.
    /// - parameter after: a live instance of the realm after client reset.
    /// - seeAlso ``RLMClientResetAfterBlock``
    ///
    /// Example Usage
    /// ```
    /// user.configuration(partitionValue: "myPartition", clientResetMode: .discardUnsyncedChanges( nil, { before, after in
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
    @preconcurrency
    case recoverOrDiscardUnsyncedChanges(beforeReset: (@Sendable (_ before: Realm) -> Void)? = nil,
                                         afterReset: (@Sendable (_ before: Realm, _ after: Realm) -> Void)? = nil)
    /// - seeAlso: ``RLMClientResetModeManual``
    ///
    /// The manual client reset mode handler can be set in two places:
    /// 1. As an ErrorReportingBlock argument in the ClientResetMode enum (``ErrorReportingBlock?` = nil`).
    /// 2. As an ErrorReportingBlock in the ``SyncManager.errorHandler`` property.
    /// - seeAlso: ``RLMSyncManager.errorHandler``
    ///
    /// During an ``RLMSyncErrorClientResetError`` the block executed is determined by the following rules
    /// - If an error reporting block is set in ``ClientResetMode`` and the ``SyncManager``, the ``ClientResetMode`` block will be executed.
    /// - If an error reporting block is set in either the ``ClientResetMode`` or the ``SyncManager``, but not both, the single block will execute.
    /// - If no block is set in either location, the client reset will not be handled. The application will likely need to be restarted and unsynced local changes may be lost.
    /// - note: The ``SyncManager.errorHandler`` is still invoked under all ``RLMSyncError``s *other than* ``RLMSyncErrorClientResetError``.
    /// - seeAlso ``RLMSyncError`` for an exhaustive list.
    @preconcurrency
    case manual(errorHandler: ErrorReportingBlock? = nil)
}


/**
 A configuration controlling how the initial subscriptions are populated when a Realm file is first opened.

 - see: `RLMInitialSubscriptionsConfiguration`
 */
public typealias InitialSubscriptionsConfiguration = RLMInitialSubscriptionsConfiguration

/**
 A `SyncConfiguration` represents configuration parameters for Realms intended to sync with
 Atlas App Services.
 */
@frozen public struct SyncConfiguration: Sendable {
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
     An enum which determines file recovery behavior in the event of a client reset.
     - note: Defaults to ``.recoverUnsyncedChanges``

     - see: ``ClientResetMode`` and ``RLMClientResetMode``
     - see: https://docs.mongodb.com/realm/sync/error-handling/client-resets/
    */
    public var clientResetMode: ClientResetMode {
        switch config.clientResetMode {
        case .manual:
            return .manual(errorHandler: config.manualClientResetHandler)
        case  .discardUnsyncedChanges, .discardLocal:
            return .discardUnsyncedChanges(beforeReset: ObjectiveCSupport.convert(object: config.beforeClientReset),
                                           afterReset: ObjectiveCSupport.convert(object: config.afterClientReset))
        case .recoverUnsyncedChanges:
            return .recoverUnsyncedChanges(beforeReset: ObjectiveCSupport.convert(object: config.beforeClientReset),
                                           afterReset: ObjectiveCSupport.convert(object: config.afterClientReset))
        case .recoverOrDiscardUnsyncedChanges:
            return .recoverOrDiscardUnsyncedChanges(beforeReset: ObjectiveCSupport.convert(object: config.beforeClientReset),
                                                    afterReset: ObjectiveCSupport.convert(object: config.afterClientReset))
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

    /**
     A configuration that controls how initial subscriptions are populated when the Realm is opened.
     */
    public var initialSubscriptions: InitialSubscriptionsConfiguration? {
        config.initialSubscriptions
    }

    // Although RLMSyncConfiguration objects are mutable, we don't expose a way
    // to mutate the one wrapped by this struct, which makes this safe
    #if compiler(<6)
    internal let config: RLMSyncConfiguration
    #else
    nonisolated(unsafe) internal let config: RLMSyncConfiguration
    #endif
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
@frozen public struct Functions: Sendable {
    private let user: User
    fileprivate init(user: User) {
        self.user = user
    }

    /// A closure type for receiving the completion of a remote function call.
    public typealias FunctionCompletionHandler = @Sendable (AnyBSON?, Error?) -> Void

    /// A closure type for the dynamic remote function type.
    public typealias Function = @Sendable ([AnyBSON], @escaping FunctionCompletionHandler) -> Void

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
    public typealias ResultFunctionCompletionHandler = @Sendable (Result<AnyBSON, Error>) -> Void

    /// A closure type for the dynamic remote function type.
    public typealias ResultFunction = @Sendable ([AnyBSON], @escaping ResultFunctionCompletionHandler) -> Void

    /// The implementation of @dynamicMemberLookup that allows for dynamic remote function calls with a `ResultFunctionCompletionHandler` completion.
    @preconcurrency
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
public struct FunctionCallable: Sendable {
    fileprivate let name: String
    fileprivate let user: User

    /// :nodoc:
    @available(*, deprecated, message: "Specify args separately without wrapping them in an array")
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func dynamicallyCall(withArguments args: [[AnyBSON]]) -> Future<AnyBSON, Error> {
        return future { promise in
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

    /// The implementation of @dynamicCallable that allows  for `Future<AnyBSON, Error>` callable return.
    ///
    ///     let cancellable = user.functions.sum(1, 2, 3, 4, 5)
    ///        .sink(receiveCompletion: { result in
    ///     }, receiveValue: { value in
    ///        // Returned value from function
    ///     })
    ///
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func dynamicallyCall(withArguments args: [AnyBSON]) -> Future<AnyBSON, Error> {
        return future { promise in
            let objcArgs = args.map(ObjectiveCSupport.convertBson)
            self.user.__callFunctionNamed(name, arguments: objcArgs) { (bson: RLMBSON?, error: Error?) in
                if let b = bson.map(ObjectiveCSupport.convertBson), let bson = b {
                    promise(.success(bson))
                } else {
                    promise(.failure(error ?? Realm.Error.callFailed))
                }
            }
        }
    }
}

private func setSyncFields(_ config: RLMRealmConfiguration, clientResetMode: ClientResetMode,
                           cancelAsyncOpenOnNonFatalErrors: Bool) {
    let syncConfig = config.syncConfiguration!
    syncConfig.cancelAsyncOpenOnNonFatalErrors = cancelAsyncOpenOnNonFatalErrors
    switch clientResetMode {
    case .manual(let block):
        syncConfig.clientResetMode = .manual
        syncConfig.manualClientResetHandler = block
    case .discardUnsyncedChanges(let beforeBlock, let afterBlock),
            .discardLocal(let beforeBlock, let afterBlock):
        syncConfig.clientResetMode = .discardUnsyncedChanges
        syncConfig.beforeClientReset = ObjectiveCSupport.convert(object: beforeBlock)
        syncConfig.afterClientReset = ObjectiveCSupport.convert(object: afterBlock)
    case .recoverUnsyncedChanges(let beforeBlock, let afterBlock):
        syncConfig.clientResetMode = .recoverUnsyncedChanges
        syncConfig.beforeClientReset = ObjectiveCSupport.convert(object: beforeBlock)
        syncConfig.afterClientReset = ObjectiveCSupport.convert(object: afterBlock)
    case .recoverOrDiscardUnsyncedChanges(let beforeBlock, let afterBlock):
        syncConfig.clientResetMode = .recoverOrDiscardUnsyncedChanges
        syncConfig.beforeClientReset = ObjectiveCSupport.convert(object: beforeBlock)
        syncConfig.afterClientReset = ObjectiveCSupport.convert(object: afterBlock)
    }

    config.syncConfiguration = syncConfig
}

public extension User {
    /**
     Create a sync configuration instance.

     - parameter partitionValue: The `BSON` value the Realm is partitioned on.
     - parameter clientResetMode: Determines file recovery behavior during a client reset. `.recoverUnsyncedChanges` by default.
     - parameter cancelAsyncOpenOnNonFatalErrors: By default, Realm.asyncOpen()
     swallows non-fatal connection errors such as a connection attempt timing
     out and simply retries until it succeeds. If this is set to `true`, instead
     the error will be reported to the callback and the async open will be
     cancelled.
     */
    @preconcurrency
    func configuration<T: BSON>(partitionValue: T,
                                clientResetMode: ClientResetMode = .recoverUnsyncedChanges(beforeReset: nil, afterReset: nil),
                                cancelAsyncOpenOnNonFatalErrors: Bool = false) -> Realm.Configuration {
        return configuration(partitionValue: AnyBSON(partitionValue),
                             clientResetMode: clientResetMode,
                             cancelAsyncOpenOnNonFatalErrors: cancelAsyncOpenOnNonFatalErrors)
    }

    /**
     Create a sync configuration instance.

     - parameter partitionValue: Takes `nil` as a partition value.
     - parameter clientResetMode: Determines file recovery behavior during a client reset. `.recoverUnsyncedChanges` by default.
     - parameter cancelAsyncOpenOnNonFatalErrors: By default, Realm.asyncOpen()
     swallows non-fatal connection errors such as a connection attempt timing
     out and simply retries until it succeeds. If this is set to `true`, instead
     the error will be reported to the callback and the async open will be
     cancelled.
     */
    @preconcurrency
    func configuration(partitionValue: AnyBSON,
                       clientResetMode: ClientResetMode = .recoverUnsyncedChanges(beforeReset: nil, afterReset: nil),
                       cancelAsyncOpenOnNonFatalErrors: Bool = false) -> Realm.Configuration {
        let config = __configuration(withPartitionValue: ObjectiveCSupport.convert(object: partitionValue))
        setSyncFields(config, clientResetMode: clientResetMode, cancelAsyncOpenOnNonFatalErrors: cancelAsyncOpenOnNonFatalErrors)
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
    enum ProgressDirection: Sendable {
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
    enum ProgressMode: Sendable {
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
     A struct encapsulating progress information.
     */
    struct Progress: Sendable {
        private let _transferredBytes: Int // NEXT-MAJOR remove storage fields and deprecated props
        private let _transferrableBytes: Int // NEXT-MAJOR remove storage fields and deprecated props

        /// The number of bytes that have been transferred.
        @available(*, deprecated, message: "Use progressEstimate")
        public var transferredBytes: Int { return _transferredBytes }

        /**
         The total number of transferrable bytes (bytes that have been transferred,
         plus bytes pending transfer).

         If the notification block is tracking downloads, this number represents the size of the
         changesets generated by all other clients using the Realm.
         If the notification block is tracking uploads, this number represents the size of the
         changesets representing the local changes on this client.
         */
        @available(*, deprecated, message: "Use progressEstimate")
        public var transferrableBytes: Int { return _transferrableBytes }

        /**
         A value between 0.0 and 1.0 representing the estimated transfer progress. This value is precise for
         uploads, but will be based on historical data and certain heuristics applied by the server for downloads.
         
         Whenever the progress reporting mode is `forCurrentlyOutstandingWork`, that value
         will monotonically increase until it reaches 1.0. If the progress mode is `reportIndefinitely`, the
         value may either increase or decrease as new data needs to be transferred.
         */
        public let progressEstimate: Double

        /// The fraction of bytes transferred out of all transferrable bytes. If this value is 1,
        /// no bytes are waiting to be transferred (either all bytes have already been transferred,
        /// or there are no bytes to be transferred in the first place).
        @available(*, deprecated, message: "Use progressEstimate", renamed: "progressEstimate")
        public var fractionTransferred: Double {
            return progressEstimate
        }

        /// Whether all pending data has already been transferred.
        public var isTransferComplete: Bool {
            return progressEstimate == 1.0
        }

        internal init(transferred: UInt, transferrable: UInt, estimate: Double) {
            _transferredBytes = Int(transferred)
            _transferrableBytes = Int(transferrable)
            progressEstimate = estimate
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
    @preconcurrency
    func addProgressNotification(for direction: ProgressDirection,
                                 mode: ProgressMode,
                                 block: @Sendable @escaping (Progress) -> Void) -> ProgressNotificationToken? {
        return __addSyncProgressNotification(for: (direction == .upload ? .upload : .download),
                                             mode: (mode == .reportIndefinitely
                                                    ? .reportIndefinitely
                                                    : .forCurrentlyOutstandingWork)) { progress in
            block(Progress(transferred: progress.transferredBytes, transferrable: progress.transferrableBytes, estimate: progress.progressEstimate))
        }
    }

    /**
     Wait for pending uploads or downloads to complete or the session to expire, and dispatch the callback onto the specified queue.
     - parameter direction: The transfer direction (upload or download) to wait for.
     - parameter queue:     The queue to dispatch the callback onto.
     - parameter block:     The block to invoke when waiting is complete.

     - see: `ProgressDirection`
     - warning: This method is not meant to be used except in special cases, notably for testing.
     */
    func wait(for direction: ProgressDirection,
              queue: DispatchQueue? = nil,
              block: @Sendable @escaping (Error?) -> Void) {
        switch direction {
        case .upload:
            __waitForUploadCompletion(on: queue, callback: block)
        case .download:
            __waitForDownloadCompletion(on: queue, callback: block)
        }
    }

    /**
     Wait for pending uploads or downloads to complete or the session to expire.
     - parameter direction: The transfer direction (upload or download) to wait for.

     - see: `ProgressDirection`
     - warning: This method is not meant to be used except in special cases, notably for testing.
     */
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func wait(for direction: ProgressDirection) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            wait(for: direction) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
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

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension User {
    /// Refresh a user's custom data. This will, in effect, refresh the user's auth session.
    /// @returns A publisher that eventually return `Dictionary` with user's data or `Error`.
    func refreshCustomData() -> Future<[AnyHashable: Any], Error> {
        return future { self.refreshCustomData($0) }
    }


    /// Removes the user
    /// This logs out and destroys the session related to this user. The completion block will return an error
    /// if the user is not found or is already removed.
    /// @returns A publisher that eventually return `Result.success` or `Error`.
    func remove() -> Future<Void, Error> {
        promisify(remove(completion:))
    }

    /// Logs out the current user
    /// The users state will be set to `Removed` is they are an anonymous user or `LoggedOut` if they are authenticated by a username / password or third party auth clients
    //// If the logout request fails, this method will still clear local authentication state.
    /// @returns A publisher that eventually return `Result.success` or `Error`.
    func logOut() -> Future<Void, Error> {
        promisify(logOut(completion:))
    }

    /// Permanently deletes this user from your Atlas App Services app.
    /// The users state will be set to `Removed` and the session will be destroyed.
    /// If the delete request fails, the local authentication state will be untouched.
    /// @returns A publisher that eventually return `Result.success` or `Error`.
    func delete() -> Future<Void, Error> {
        promisify(delete(completion:))
    }
}

/// :nodoc:
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@frozen public struct UserSubscription: Subscription {
    private let token: RLMUserSubscriptionToken

    internal init(token: RLMUserSubscriptionToken) {
        self.token = token
    }

    /// A unique identifier for identifying publisher streams.
    public var combineIdentifier: CombineIdentifier {
        return CombineIdentifier(token)
    }

    /// This function is not implemented.
    ///
    /// Realm publishers do not support backpressure and so this function does nothing.
    public func request(_ demand: Subscribers.Demand) {
    }

    /// Stop emitting values on this subscription.
    public func cancel() {
        token.unsubscribe()
    }
}

/// :nodoc:
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
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
        let token = user.subscribe { user in
            _ = subscriber.receive(user)
        }

        subscriber.receive(subscription: UserSubscription(token: token))
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension User {
    /// A publisher that emits Void each time the user changes.
    ///
    /// Despite the name, this actually emits *after* the user has changed.
    public var objectWillChange: AnyPublisher<UserPublisher.Output, UserPublisher.Failure> {
        return UserPublisher(self).receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }
}

#if compiler(>=6)
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension User: @retroactive ObservableObject {}
#else
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension User: ObservableObject {}
#endif

public extension User {
    /// Refresh a user's custom data. This will, in effect, refresh the user's auth session.
    /// @completion A completion that eventually return `Result.success(Dictionary)` with user's data or `Result.failure(Error)`.
    @preconcurrency
    func refreshCustomData(_ completion: @escaping @Sendable (Result<[AnyHashable: Any], Error>) -> Void) {
        self.__refreshCustomData { customData, error in
            if let customData = customData {
                completion(.success(customData))
            } else {
                completion(.failure(error ?? Realm.Error.callFailed))
            }
        }
    }

    /// Refresh a user's custom data. This will, in effect, refresh the user's auth session.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @discardableResult
    func refreshCustomData() async throws -> Document {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.__refreshCustomData { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
        return customData
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension FunctionCallable {
    /// :nodoc:
    @available(*, deprecated, message: "Specify args separately without wrapping them in an array")
    public func dynamicallyCall(withArguments args: [[AnyBSON]]) async throws -> AnyBSON {
        let objcArgs = args.first!.map(ObjectiveCSupport.convertBson)
        let ret = try await user.__callFunctionNamed(name, arguments: objcArgs)
        if let bson = ObjectiveCSupport.convertBson(object: ret) {
            return bson
        }
        throw Realm.Error.callFailed
    }

    /// The implementation of @dynamicMemberLookup that allows  for `async await` callable return.
    ///
    ///     guard case let .int32(sum) = try await user.functions.sum(1, 2, 3, 4, 5) else {
    ///        return
    ///     }
    ///
    public func dynamicallyCall(withArguments args: [AnyBSON]) async throws -> AnyBSON {
        let objcArgs = args.map(ObjectiveCSupport.convertBson)
        let ret = try await user.__callFunctionNamed(name, arguments: objcArgs)
        if let bson = ObjectiveCSupport.convertBson(object: ret) {
            return bson
        }
        throw Realm.Error.callFailed
    }
}

extension User {
    /**
     Create a flexible sync configuration instance, which can be used to open a realm  which
     supports flexible sync.

     It won't be possible to combine flexible and partition sync in the same app, which means if you open
     a realm with a flexible sync configuration, you won't be able to open a realm with a PBS configuration
     and the other way around.

     - parameter clientResetMode: Determines file recovery behavior during a client reset. `.recoverUnsyncedChanges` by default.
     - parameter cancelAsyncOpenOnNonFatalErrors: By default, Realm.asyncOpen()
     swallows non-fatal connection errors such as a connection attempt timing
     out and simply retries until it succeeds. If this is set to `true`, instead
     the error will be reported to the callback and the async open will be
     cancelled.

     - returns A `Realm.Configuration` instance with a flexible sync configuration.
     */
    public func flexibleSyncConfiguration(clientResetMode: ClientResetMode = .recoverUnsyncedChanges(),
                                          cancelAsyncOpenOnNonFatalErrors: Bool = false) -> Realm.Configuration {
        let config = __flexibleSyncConfiguration()
        setSyncFields(config, clientResetMode: clientResetMode, cancelAsyncOpenOnNonFatalErrors: cancelAsyncOpenOnNonFatalErrors)
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

     - parameter clientResetMode: Determines file recovery behavior during a client reset. `.recoverUnsyncedChanges` by default.
     - parameter initialSubscriptions: A block which receives a subscription set instance, that can be used to add an
                                       initial set of subscriptions which will be executed when the Realm is first opened.
     - parameter rerunOnOpen:          If true, allows to run the initial set of subscriptions specified, on every app startup.
                                       This can be used to re-run dynamic time ranges and other queries that require a
                                       re-computation of a static variable.
     - parameter cancelAsyncOpenOnNonFatalErrors: By default, Realm.asyncOpen()
     swallows non-fatal connection errors such as a connection attempt timing
     out and simply retries until it succeeds. If this is set to `true`, instead
     the error will be reported to the callback and the async open will be
     cancelled.


     - returns A `Realm.Configuration` instance with a flexible sync configuration.
     */
    @preconcurrency
    public func flexibleSyncConfiguration(clientResetMode: ClientResetMode = .recoverUnsyncedChanges(),
                                          cancelAsyncOpenOnNonFatalErrors: Bool = false,
                                          initialSubscriptions: @escaping @Sendable (SyncSubscriptionSet) -> Void,
                                          rerunOnOpen: Bool = false) -> Realm.Configuration {
        let config = __flexibleSyncConfiguration(initialSubscriptions: ObjectiveCSupport.convert(block: initialSubscriptions),
                                                 rerunOnOpen: rerunOnOpen)
        setSyncFields(config, clientResetMode: clientResetMode, cancelAsyncOpenOnNonFatalErrors: cancelAsyncOpenOnNonFatalErrors)
        return ObjectiveCSupport.convert(object: config)
    }
}
