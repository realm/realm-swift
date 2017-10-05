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
import Foundation

/**
 An object representing a Realm Object Server user.

 - see: `RLMSyncUser`
 */
public typealias SyncUser = RLMSyncUser

/**
 An immutable data object representing information retrieved from the Realm Object
 Server about a particular user.

 - see: `RLMSyncUserInfo`
 */
public typealias SyncUserInfo = RLMSyncUserInfo

/**
 An immutable data object representing an account belonging to a particular user.

 - see: `SyncUserInfo`, `RLMSyncUserAccountInfo`
 */
public typealias SyncUserAccountInfo = RLMSyncUserAccountInfo

/**
 A singleton which configures and manages the Realm Object Server synchronization-related
 functionality.

 - see: `RLMSyncManager`
 */
public typealias SyncManager = RLMSyncManager

extension SyncManager {
    /// The sole instance of the singleton.
    public static var shared: SyncManager {
        return __shared()
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
}

/**
 An error associated with network requests made to the authentication server. This type of error
 may be returned in the callback block to `SyncUser.logIn()` upon certain types of failed login
 attempts (for example, if the request is malformed or if the server is experiencing an issue).

 - see: `RLMSyncAuthError`
 */
public typealias SyncAuthError = RLMSyncAuthError

/**
 An error associated with retrieving or modifying user permissions to access a synchronized Realm.

 - see: `RLMSyncPermissionError`
 */
public typealias SyncPermissionError = RLMSyncPermissionError

/**
 An enum which can be used to specify the level of logging.

 - see: `RLMSyncLogLevel`
 */
public typealias SyncLogLevel = RLMSyncLogLevel

/**
 A data type whose values represent different authentication providers that can be used with
 the Realm Object Server.

 - see: `RLMIdentityProvider`
 */
public typealias Provider = RLMIdentityProvider

/**
 A `SyncConfiguration` represents configuration parameters for Realms intended to sync with
 a Realm Object Server.
 */
public struct SyncConfiguration {
    /// The `SyncUser` who owns the Realm that this configuration should open.
    public let user: SyncUser

    /**
     The URL of the Realm on the Realm Object Server that this configuration should open.

     - warning: The URL must be absolute (e.g. `realms://example.com/~/foo`), and cannot end with
                `.realm`, `.realm.lock` or `.realm.management`.
     */
    public let realmURL: URL

    /**
     A policy that determines what should happen when all references to Realms opened by this
     configuration go out of scope.
     */
    internal let stopPolicy: RLMSyncStopPolicy

    /**
     Whether the SSL certificate of the Realm Object Server should be validated.
     */
    public let enableSSLValidation: Bool

    /**
     Whether this Realm should be opened in 'partial synchronization' mode.
     Partial synchronization mode means that no objects are synchronized from the remote Realm
     except those matching queries that the user explicitly specifies.

     -warning: Partial synchronization is a tech preview. Its APIs are subject to change.
     */
    public let isPartial: Bool

    internal init(config: RLMSyncConfiguration) {
        self.user = config.user
        self.realmURL = config.realmURL
        self.stopPolicy = config.stopPolicy
        self.enableSSLValidation = config.enableSSLValidation
        self.isPartial = config.isPartial
    }

    func asConfig() -> RLMSyncConfiguration {
        let config = RLMSyncConfiguration(user: user, realmURL: realmURL)
        config.stopPolicy = stopPolicy
        config.enableSSLValidation = enableSSLValidation
        config.isPartial = isPartial
        return config
    }

    /**
     Initialize a sync configuration with a user and a Realm URL.

     Additional settings can be optionally specified. Descriptions of these
     settings follow.

     `enableSSLValidation` is true by default. It can be disabled for debugging
     purposes.

     - warning: The URL must be absolute (e.g. `realms://example.com/~/foo`), and cannot end with
                `.realm`, `.realm.lock` or `.realm.management`.

     - warning: NEVER disable SSL validation for a system running in production.
     */
    public init(user: SyncUser, realmURL: URL, enableSSLValidation: Bool = true, isPartial: Bool = false) {
        self.user = user
        self.realmURL = realmURL
        self.stopPolicy = .afterChangesUploaded
        self.enableSSLValidation = enableSSLValidation
        self.isPartial = isPartial
    }
}

/// A `SyncCredentials` represents data that uniquely identifies a Realm Object Server user.
public struct SyncCredentials {
    public typealias Token = String

    internal var token: Token
    internal var provider: Provider
    internal var userInfo: [String: Any]

    /**
     Initialize new credentials using a custom token, authentication provider, and user information
     dictionary. In most cases, the convenience initializers should be used instead.
     */
    public init(customToken token: Token, provider: Provider, userInfo: [String: Any] = [:]) {
        self.token = token
        self.provider = provider
        self.userInfo = userInfo
    }

    internal init(_ credentials: RLMSyncCredentials) {
        self.token = credentials.token
        self.provider = credentials.provider
        self.userInfo = credentials.userInfo
    }

    /// Initialize new credentials using a Facebook account token.
    public static func facebook(token: Token) -> SyncCredentials {
        return SyncCredentials(RLMSyncCredentials(facebookToken: token))
    }

    /// Initialize new credentials using a Google account token.
    public static func google(token: Token) -> SyncCredentials {
        return SyncCredentials(RLMSyncCredentials(googleToken: token))
    }

    /// Initialize new credentials using a CloudKit account token.
    public static func cloudKit(token: Token) -> SyncCredentials {
        return SyncCredentials(RLMSyncCredentials(cloudKitToken: token))
    }

    /// Initialize new credentials using a Realm Object Server username and password.
    public static func usernamePassword(username: String,
                                        password: String,
                                        register: Bool = false) -> SyncCredentials {
        return SyncCredentials(RLMSyncCredentials(username: username, password: password, register: register))
    }

    /// Initialize new credentials using a Realm Object Server access token.
    public static func accessToken(_ accessToken: String, identity: String) -> SyncCredentials {
        return SyncCredentials(RLMSyncCredentials(accessToken: accessToken, identity: identity))
    }
}

extension RLMSyncCredentials {
    internal convenience init(_ credentials: SyncCredentials) {
        self.init(customToken: credentials.token, provider: credentials.provider, userInfo: credentials.userInfo)
    }
}

extension SyncUser {
    /**
     Log in a user and asynchronously retrieve a user object.

     If the log in completes successfully, the completion block will be called, and a
     `SyncUser` representing the logged-in user will be passed to it. This user object
     can be used to open `Realm`s and retrieve `SyncSession`s. Otherwise, the
     completion block will be called with an error.

     - parameter credentials: A `SyncCredentials` object representing the user to log in.
     - parameter authServerURL: The URL of the authentication server (e.g. "http://realm.example.org:9080").
     - parameter timeout: How long the network client should wait, in seconds, before timing out.
     - parameter callbackQueue: The dispatch queue upon which the callback should run. Defaults to the main queue.
     - parameter completion: A callback block to be invoked once the log in completes.
     */
    public static func logIn(with credentials: SyncCredentials,
                             server authServerURL: URL,
                             timeout: TimeInterval = 30,
                             callbackQueue queue: DispatchQueue = DispatchQueue.main,
                             onCompletion completion: @escaping UserCompletionBlock) {
        return SyncUser.__logIn(with: RLMSyncCredentials(credentials),
                                authServerURL: authServerURL,
                                timeout: timeout,
                                callbackQueue: queue,
                                onCompletion: completion)
    }

    /// A dictionary of all valid, logged-in user identities corresponding to their `SyncUser` objects.
    public static var all: [String: SyncUser] {
        return __allUsers()
    }

    /**
     The logged-in user. `nil` if none exists. Only use this property if your application expects
     no more than one logged-in user at any given time.

     - warning: Throws an Objective-C exception if more than one logged-in user exists.
     */
    public static var current: SyncUser? {
        return __current()
    }

    /**
     An optional error handler which can be set to notify the host application when
     the user encounters an error.
     
     - note: Check for `.invalidAccessToken` to see if the user has been remotely logged
             out because its refresh token expired, or because the third party authentication
             service providing the user's identity has logged the user out.

     - warning: Regardless of whether an error handler is defined, certain user errors
                will automatically cause the user to enter the logged out state.
     */
    @nonobjc public var errorHandler: ((SyncUser, SyncAuthError) -> Void)? {
        get {
            return __errorHandler
        }
        set {
            if let newValue = newValue {
                __errorHandler = { (user, error) in
                    newValue(user, error as! SyncAuthError)
                }
            } else {
                __errorHandler = nil
            }
        }
    }

    /**
     Retrieve permissions for this user. Permissions describe which synchronized
     Realms this user has access to and what they are allowed to do with them.

     Permissions are retrieved asynchronously and returned via the callback. The
     callback is run on the same thread that the method is invoked upon.

     - warning: This method must be invoked on a thread with an active run loop.

     - warning: Do not pass the `Results` returned by the callback between threads.

     - parameter callback: A callback providing either a `Results` containing the
                           permissions, or an error describing what went wrong.
     */
    public func retrievePermissions(callback: @escaping (SyncPermissionResults?, SyncPermissionError?) -> Void) {
        self.__retrievePermissions { (results, error) in
            guard let results = results else {
                callback(nil, error as! SyncPermissionError?)
                return
            }
            let upcasted: RLMResults<SyncPermission> = results
            callback(Results(upcasted as! RLMResults<AnyObject>), nil)
        }
    }

    /**
     Create a permission offer for a Realm.

     A permission offer is used to grant access to a Realm this user manages to another
     user. Creating a permission offer produces a string token which can be passed to the
     recepient in any suitable way (for example, via e-mail).

     The operation will take place asynchronously. The token can be accepted by the recepient
     using the `SyncUser.acceptOffer(forToken:, callback:)` method.

     - parameter url: The URL of the Realm for which the permission offer should pertain. This
                      may be the URL of any Realm which this user is allowed to manage. If the URL
                      has a `~` wildcard it will be replaced with this user's user identity.
     - parameter accessLevel: What access level to grant to whoever accepts the token.
     - parameter expiration: Optionally, a date which indicates when the offer expires. If the
                             recepient attempts to accept the offer after the date it will be rejected.
                             If nil, the offer will never expire.
     - parameter callback: A callback indicating whether the operation succeeded or failed. If it
                           succeeded the token will be passed in as a string.
     */
    public func createOfferForRealm(at url: URL,
                                    accessLevel: SyncAccessLevel,
                                    expiration: Date? = nil,
                                    callback: @escaping (String?, SyncPermissionError?) -> Void) {
        self.__createOfferForRealm(at: url, accessLevel: accessLevel, expiration: expiration) { (token, error) in
            guard let token = token else {
                callback(nil, error as! SyncPermissionError?)
                return
            }
            callback(token, nil)
        }
    }
}

/**
 A value which represents a permission granted to a user to interact
 with a Realm. These values are passed into APIs on `SyncUser`, and
 returned from `SyncPermissionResults`.

 - see: `RLMSyncPermission`
 */
public typealias SyncPermission = RLMSyncPermission

/**
 An enumeration describing possible access levels.

 - see: `RLMSyncAccessLevel`
 */
public typealias SyncAccessLevel = RLMSyncAccessLevel

public extension SyncSession {
    /**
     The transfer direction (upload or download) tracked by a given progress notification block.

     Progress notification blocks can be registered on sessions if your app wishes to be informed
     how many bytes have been uploaded or downloaded, for example to show progress indicator UIs.
     */
    public enum ProgressDirection {
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
    public enum ProgressMode {
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
    public typealias ProgressNotificationToken = RLMProgressNotificationToken

    /**
     A struct encapsulating progress information, as well as useful helper methods.
     */
    public struct Progress {
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

        fileprivate init(transferred: UInt, transferrable: UInt) {
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
    public func addProgressNotification(for direction: ProgressDirection,
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
    /**
     If the Realm is a partially synchronized Realm, fetch and synchronize the objects
     of a given object type that match the given query (in string format).

     The results will be returned asynchronously in the callback.
     Use `Results.observe(_:)` to be notified to changes to the set of synchronized objects.

     -warning: Partial synchronization is a tech preview. Its APIs are subject to change.
     */
    public func subscribe<T: Object>(to objects: T.Type, where: String,
                                     completion: @escaping (Results<T>?, Swift.Error?) -> Void) {
        rlmRealm.subscribe(toObjects: objects, where: `where`) { (results, error) in
            completion(results.map { Results<T>($0) }, error)
        }
    }
}

// MARK: - Permissions and permission results

extension SyncPermission: RealmCollectionValue { }

/**
 A `Results` collection containing sync permission results.
 */
public typealias SyncPermissionResults = Results<SyncPermission>

/**
 A property upon which a `SyncPermissionResults` can be sorted or queried.
 The raw value string can be used to construct predicates and queries
 manually.

 - warning: If building `NSPredicate`s using format strings including these
            raw values, use `%K` instead of `%@` as the substitution
            parameter.

 - see: `RLMSyncPermissionSortProperty`
 */
public typealias SyncPermissionSortProperty = RLMSyncPermissionSortProperty

extension SortDescriptor {
    /**
     Construct a sort descriptor using a `SyncPermissionSortProperty`.
     */
    public init(sortProperty: SyncPermissionSortProperty, ascending: Bool = true) {
        self.init(keyPath: sortProperty.rawValue, ascending: ascending)
    }
}

#if swift(>=3.1)
extension Results where Element == SyncPermission {
    /**
     Return a `Results<SyncPermissionValue>` containing the objects represented
     by the results, but sorted on the specified property.

     - see: `sorted(byKeyPath:, ascending:)`
     */
    public func sorted(bySortProperty sortProperty: SyncPermissionSortProperty,
                       ascending: Bool = true) -> Results<Element> {
        return sorted(by: [SortDescriptor(sortProperty: sortProperty, ascending: ascending)])
    }
}
#endif

// MARK: - Migration assistance

/// :nodoc:
@available(*, unavailable, renamed: "SyncPermission")
public final class SyncPermissionValue { }
