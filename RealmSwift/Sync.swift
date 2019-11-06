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
 * How the Realm client should validate the identity of the server for secure connections.
 *
 * By default, when connecting to the Realm Object Server over HTTPS, Realm will
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
     How the SSL certificate of the Realm Object Server should be validated.
     */
    public let serverValidationPolicy: ServerValidationPolicy

    /// :nodoc:
    @available(*, unavailable, message: "Use serverValidationPolicy instead")
    public var enableSSLValidation: Bool {
        fatalError()
    }

    /// :nodoc:
    @available(*, unavailable, message: "Use fullSynchronization instead")
    public var isPartial: Bool {
        fatalError()
    }

    /**
     Whether this Realm should be a fully synchronized Realm.

     Synchronized Realms comes in two flavors: Query-based and Fully synchronized.
     A fully synchronized Realm will automatically synchronize the entire Realm in the background
     while a query-based Realm will only synchronize the data being subscribed to.
     Synchronized realms are by default query-based unless this boolean is set.
     */
    public let fullSynchronization: Bool

    /**
     The prefix that is prepended to the path in the HTTP request
     that initiates a sync connection. The value specified must match with the server's expectation.
     Changing the value of `urlPrefix` should be matched with a corresponding
     change of the server's configuration.
     If no value is specified here then the default `/realm-sync` path is used.
     */
    public let urlPrefix: String?

    internal init(config: RLMSyncConfiguration) {
        self.user = config.user
        self.realmURL = config.realmURL
        self.stopPolicy = config.stopPolicy
        if let certificateURL = config.pinnedCertificateURL {
            self.serverValidationPolicy = .pinCertificate(path: certificateURL)
        } else {
            self.serverValidationPolicy = config.enableSSLValidation ? .system : .none
        }
        self.fullSynchronization = config.fullSynchronization
        self.urlPrefix = config.urlPrefix
    }

    func asConfig() -> RLMSyncConfiguration {
        var validateSSL = true
        var certificate: URL?
        switch serverValidationPolicy {
        case .none:
            validateSSL = false
        case .system:
            break
        case .pinCertificate(let path):
            certificate = path
        }
        return RLMSyncConfiguration(user: user, realmURL: realmURL,
                                    isPartial: !fullSynchronization,
                                    urlPrefix: urlPrefix,
                                    stopPolicy: stopPolicy,
                                    enableSSLValidation: validateSSL,
                                    certificatePath: certificate)
    }

    /// :nodoc:
    @available(*, unavailable, message: "Use SyncUser.configuration() instead")
    public init(user: SyncUser, realmURL: URL, enableSSLValidation: Bool = true, isPartial: Bool = false, urlPrefix: String? = nil) {
        fatalError()
    }

    /// :nodoc:
    @available(*, unavailable, message: "Use SyncUser.configuration() instead")
    public static func automatic() -> Realm.Configuration {
        fatalError()
    }

    /// :nodoc:
    @available(*, unavailable, message: "Use SyncUser.configuration() instead")
    public static func automatic(user: SyncUser) -> Realm.Configuration {
        fatalError()
    }
}

/// A `SyncCredentials` represents data that uniquely identifies a Realm Object Server user.
public struct SyncCredentials {
    /// An account token serialized as a string
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

    /// Initialize new credentials using a JSON Web Token.
    public static func jwt(_ token: Token) -> SyncCredentials {
        return SyncCredentials(RLMSyncCredentials(jwt: token))
    }

    /// Initialize new credentials using a nickname.
    @available(*, deprecated, message: "Use usernamePassword instead.")
    public static func nickname(_ nickname: String, isAdmin: Bool = false) -> SyncCredentials {
        return SyncCredentials(RLMSyncCredentials(nickname: nickname, isAdmin: isAdmin))
    }

    /// Initialize new credentials anonymously
    public static func anonymous() -> SyncCredentials {
        return SyncCredentials(RLMSyncCredentials.anonymous())
    }

    /// Initialize new credentials using an externally-issued refresh token
    public static func customRefreshToken(_ token: String, identity: String, isAdmin: Bool = false) -> SyncCredentials {
        return SyncCredentials(RLMSyncCredentials(customRefreshToken: token, identity: identity, isAdmin: isAdmin))
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
                                    callback: @escaping (String?, Error?) -> Void) {
        self.__createOfferForRealm(at: url, accessLevel: accessLevel, expiration: expiration, callback: callback)
    }

    /**
     Create a sync configuration instance.

     Additional settings can be optionally specified. Descriptions of these
     settings follow.

     `enableSSLValidation` is true by default. It can be disabled for debugging
     purposes.

     - warning: The URL must be absolute (e.g. `realms://example.com/~/foo`), and cannot end with
     `.realm`, `.realm.lock` or `.realm.management`.

     - warning: NEVER disable SSL validation for a system running in production.
     */
    public func configuration(realmURL: URL? = nil, fullSynchronization: Bool = false,
                              enableSSLValidation: Bool = true, urlPrefix: String? = nil) -> Realm.Configuration {
        let config = self.__configuration(with: realmURL,
                                          fullSynchronization: fullSynchronization,
                                          enableSSLValidation: enableSSLValidation,
                                          urlPrefix: urlPrefix)
        return ObjectiveCSupport.convert(object: config)
    }

    /**
     Create a sync configuration instance.

     Additional settings can be optionally specified. Descriptions of these
     settings follow.

     `serverValidationPolicy` defaults to `.system`. It can be set to
     `.pinCertificate` to pin a specific SSL certificate, or `.none` for
     debugging purposes.

     - warning: The URL must be absolute (e.g. `realms://example.com/~/foo`), and cannot end with
     `.realm`, `.realm.lock` or `.realm.management`.

     - warning: NEVER disable SSL validation for a system running in production.
     */
    public func configuration(realmURL: URL? = nil, fullSynchronization: Bool = false,
                              serverValidationPolicy: ServerValidationPolicy,
                              urlPrefix: String? = nil) -> Realm.Configuration {
        let config = self.__configuration(with: realmURL, fullSynchronization: fullSynchronization)
        let syncConfig = config.syncConfiguration!
        syncConfig.urlPrefix = urlPrefix
        switch serverValidationPolicy {
        case .none:
            syncConfig.enableSSLValidation = false
        case .system:
            break
        case .pinCertificate(let path):
            syncConfig.pinnedCertificateURL = path
        }
        config.syncConfiguration = syncConfig
        return ObjectiveCSupport.convert(object: config)
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

// MARK: - Permissions and permission results

extension SyncPermission: RealmCollectionValue { }

/**
 An array containing sync permission results.
 */
public typealias SyncPermissionResults = [SyncPermission]

// MARK: - Partial sync subscriptions

/// The possible states of a sync subscription.
public enum SyncSubscriptionState: Equatable {
    /// The subscription is being created, but has not yet been written to the synced Realm.
    case creating

    /// The subscription has been created, and is waiting to be processed by the server.
    case pending

    /// The subscription has been processed by the server, and objects matching the subscription
    /// are now being synchronized to this client.
    case complete

    /// The subscription has been removed.
    case invalidated

    /// An error occurred while creating the subscription or while the server was processing it.
    case error(Error)

    internal init(_ rlmSubscription: RLMSyncSubscription) {
        switch rlmSubscription.state {
        case .creating:
            self = .creating
        case .pending:
            self = .pending
        case .complete:
            self = .complete
        case .invalidated:
            self = .invalidated
        case .error:
            self = .error(rlmSubscription.error!)
        }
    }

    public static func == (lhs: SyncSubscriptionState, rhs: SyncSubscriptionState) -> Bool {
        switch (lhs, rhs) {
        case (.creating, .creating), (.pending, .pending), (.complete, .complete), (.invalidated, .invalidated):
            return true
        case (.error(let e1), .error(let e2)):
            return e1 == e2
        default:
            return false
        }
    }
}

/// `SyncSubscription` represents a subscription to a set of objects in a synced Realm.
///
/// When partial sync is enabled for a synced Realm, the only objects that the server synchronizes to the
/// client are those that match a sync subscription registered by that client. A subscription consists of
/// of a query (represented by a `Results`) and an optional name.
///
/// Changes to the state of the subscription can be observed using `SyncSubscription.observe(_:options:_:)`.
///
/// Subscriptions are created using `Results.subscribe()` or `Results.subscribe(named:)`.
public struct SyncSubscription: RealmCollectionValue {
    private let rlmSubscription: RLMSyncSubscription

    /// The name of the subscription.
    ///
    /// This will be `nil` if a name was not provided when the subscription was created.
    public var name: String? { return rlmSubscription.name }

    /// The state of the subscription.
    public var state: SyncSubscriptionState { return SyncSubscriptionState(rlmSubscription) }

    /**
     The raw query which this subscription is running on the server.

     This string is a serialized representation of the Results which the
     subscription was created from. This representation does *not* use NSPredicate
     syntax, and is not guaranteed to remain consistent between versions of Realm.
     Any use of this other than manual inspection when debugging is likely to be
     incorrect.

     This is `nil` while the subscription is in the Creating state.
     */
    public var query: String? { return rlmSubscription.query }

    /**
     When this subscription was first created.

     This value will be `nil` for subscriptions created with older versions of
     Realm which did not store the creation date. Newly created subscriptions
     should always have a non-nil creation date.
     */
    public var createdAt: Date? { return rlmSubscription.createdAt }

    /**
     When this subscription was last updated.

     This value will be `nil` for subscriptions created with older versions of
     Realm which did not store the update date. Newly created subscriptions
     should always have a non-nil update date.

     The update date is the time when the subscription was last updated by a call
     to `Results.subscribe()`, and not when the set of objects which match the
     subscription last changed.
     */
    public var updatedAt: Date? { return rlmSubscription.updatedAt }

    /**
     When this subscription will be automatically removed.

     If the `timeToLive` parameter is set when creating a sync subscription, the
     subscription will be automatically removed the first time that any subscription
     is created, modified, or deleted after that time has elapsed.

     This property will be `nil` if the `timeToLive` option was not enabled.
     */
    public var expiresAt: Date? { return rlmSubscription.expiresAt }

    /**
     How long this subscription will persist after last being updated.

     If the `timeToLive` parameter is set when creating a sync subscription, the
     subscription will be automatically removed the first time that any subscription
     is created, modified, or deleted after that time has elapsed.

     This property will be nil if the `timeToLive` option was not enabled.
     */
    public var timeToLive: TimeInterval? {
        let ttl = rlmSubscription.timeToLive
        return ttl.isNaN ? nil : ttl
    }

    internal init(_ rlmSubscription: RLMSyncSubscription) {
        self.rlmSubscription = rlmSubscription
    }

    public static func == (lhs: SyncSubscription, rhs: SyncSubscription) -> Bool {
        return lhs.rlmSubscription == rhs.rlmSubscription
    }

    /// Observe the subscription for state changes.
    ///
    /// When the state of the subscription changes, `block` will be invoked and
    /// passed the new state.
    ///
    /// The token returned from this function does not hold a strong reference to
    /// this subscription object. This means that you must hold a reference to
    /// the subscription object itself along with the returned token in order to
    /// actually receive updates about the state.
    ///
    /// - parameter keyPath: The path to observe. Must be `\.state`.
    /// - parameter options: Options for the observation. Only `NSKeyValueObservingOptions.initial` option is
    ///                      is supported at this time.
    /// - parameter block: The block to be called whenever a change occurs.
    /// - returns: A token which must be held for as long as you want updates to be delivered.
    public func observe(_ keyPath: KeyPath<SyncSubscription, SyncSubscriptionState>,
                        options: NSKeyValueObservingOptions = [],
                        _ block: @escaping (SyncSubscriptionState) -> Void) -> NotificationToken {
        let observation = rlmSubscription.observe(\.state, options: options) { rlmSubscription, _ in
            block(SyncSubscriptionState(rlmSubscription))
        }
        return KeyValueObservationNotificationToken(observation)
    }

    /// Remove this subscription
    ///
    /// Removing a subscription will delete all objects from the local Realm that were matched
    /// only by that subscription and not any remaining subscriptions. The deletion is performed
    /// by the server, and so has no immediate impact on the contents of the local Realm. If the
    /// device is currently offline, the removal will not be processed until the device returns online.
    public func unsubscribe() {
        rlmSubscription.unsubscribe()
    }
}

// :nodoc:
extension SyncSubscription: CustomObjectiveCBridgeable {
    static func bridging(objCValue: Any) -> SyncSubscription {
        return ObjectiveCSupport.convert(object: RLMCastToSyncSubscription(objCValue))
    }
    var objCValue: Any {
        return 0
    }
}

extension Results {
    // MARK: Sync

    /// Subscribe to the query represented by this `Results`
    ///
    /// Subscribing to a query asks the server to synchronize all objects to the
    /// client which match the query, along with all objects which are reachable
    /// from those objects via links. This happens asynchronously, and the local
    /// client Realm may not immediately have all objects which match the query.
    /// Observe the `state` property of the returned subscription object to be
    /// notified of when the subscription has been processed by the server and
    /// all objects matching the query are available.
    ///
    /// ---
    ///
    /// Creating a new subscription with the same name and query as an existing
    /// subscription will not create a new subscription, but instead will return
    /// an object referring to the existing sync subscription. This means that
    /// performing the same subscription twice followed by removing it once will
    /// result in no subscription existing.
    ///
    /// By default trying to create a subscription with a name as an existing
    /// subscription with a different query or options will fail. If `update` is
    /// `true`, instead the existing subscription will be changed to use the
    /// query and options from the new subscription. This only works if the new
    /// subscription is for the same type of objects as the existing
    /// subscription, and trying to overwrite a subscription with a subscription
    /// of a different type of objects will still fail.
    ///
    /// ---
    ///
    /// The number of top-level objects which are included in the subscription
    /// can optionally be limited by setting the `limit` paramter. If more
    /// top-level objects than the limit match the query, only the first
    /// `limit` objects will be included. This respects the sort and distinct
    /// order of the query being subscribed to for the determination of what the
    /// "first" objects are.
    ///
    /// The limit does not count or apply to objects which are added indirectly
    /// due to being linked to by the objects in the subscription or due to
    /// being listed in `includeLinkingObjects`. If the limit is larger than the
    /// number of objects which match the query, all objects will be
    /// included.
    ///
    /// ---
    ///
    /// By default subscriptions are persistent, and last until they are
    /// explicitly removed by calling `unsubscribe()`. Subscriptions can instead
    /// be made temporary by setting the time to live to how long the
    /// subscription should remain. After that time has elapsed the subscription
    /// will be automatically removed.
    ///
    /// ---
    ///
    /// Outgoing links (i.e. `List` and `Object` properties) are automatically
    /// included in sync subscriptions. That is, if you subscribe to a query
    /// which matches one object, every object which is reachable via links
    /// from that object are also included in the subscription. By default,
    /// `LinkingObjects` properties do not work this way and instead, they only
    /// report objects which happen to be included in a subscription. Specific
    /// `LinkingObjects` properties can be explicitly included in the
    /// subscription by naming them in the `includingLinkingObjects` array. Any
    /// keypath which ends in a `LinkingObjects` property can be included in
    /// this array, including ones involving intermediate links.
    ///
    /// ---
    ///
    /// Creating a subscription is an asynchronous operation and the newly
    /// created subscription will not be reported by Realm.subscriptions() until
    /// it has transitioned from the `.creating` state to `.pending`,
    /// `.created` or `.error`.
    ///
    /// - parameter subscriptionName: An optional name for the subscription.
    /// - parameter limit: The maximum number of top-level objects to include
    /// in the subscription.
    /// - parameter update: Whether an existing subscription with the same name
    /// should be updated or if it should be an error.
    /// - parameter timeToLive: How long in seconds this subscription should
    /// remain active.
    /// - parameter includingLinkingObjects: Which `LinkingObjects` properties
    /// should pull in the contained objects.
    /// - returns: The subscription.
    public func subscribe(named subscriptionName: String? = nil, limit: Int? = nil,
                          update: Bool = false, timeToLive: TimeInterval? = nil,
                          includingLinkingObjects: [String] = []) -> SyncSubscription {
        let options = RLMSyncSubscriptionOptions()
        options.name = subscriptionName
        options.overwriteExisting = update
        if let limit = limit {
            options.limit = UInt(limit)
        }
        if let timeToLive = timeToLive {
            options.timeToLive = timeToLive
        }
        options.includeLinkingObjectProperties = includingLinkingObjects
        return SyncSubscription(rlmResults.subscribe(with: options))
    }
}

internal class KeyValueObservationNotificationToken: NotificationToken {
    public var observation: NSKeyValueObservation?

    public init(_ observation: NSKeyValueObservation) {
        super.init()
        self.observation = observation
    }

    public override func invalidate() {
        self.observation = nil
    }
}

// MARK: - Permissions

/**
 A permission which can be applied to a Realm, Class, or specific Object.

 Permissions are applied by adding the permission to the RealmPermission singleton
 object, the ClassPermission object for the desired class, or to a user-defined
 List<Permission> property on a specific Object instance. The meaning of each of
 the properties of Permission depend on what the permission is applied to, and so are
 left undocumented here. See `RealmPrivileges`, `ClassPrivileges`, and
 `ObjectPrivileges` for details about what each of the properties mean when applied to
 that type.
 */
@objc(RealmSwiftPermission)
public class Permission: Object {
    /// The Role which this Permission applies to. All users within the Role are
    /// granted the permissions specified by the fields below any
    /// objects/classes/realms which use this Permission.
    ///
    /// This property cannot be modified once set.
    @objc dynamic public var role: PermissionRole?

    /// Whether the user can read the object to which this Permission is attached.
    @objc dynamic public var canRead = false

    /// Whether the user can modify the object to which this Permission is attached.
    @objc dynamic public var canUpdate = false

    /// Whether the user can delete the object to which this Permission is attached.
    ///
    /// This field is only applicable to Permissions attached to Objects, and not
    /// to Realms or Classes.
    @objc dynamic public var canDelete = false

    /// Whether the user can add or modify Permissions for the object which this
    /// Permission is attached to.
    @objc dynamic public var canSetPermissions = false

    /// Whether the user can subscribe to queries for this object type.
    ///
    /// This field is only applicable to Permissions attached to Classes, and not
    /// to Realms or Objects.
    @objc dynamic public var canQuery = false

    /// Whether the user can create new objects of the type this Permission is attached to.
    ///
    /// This field is only applicable to Permissions attached to Classes, and not
    /// to Realms or Objects.
    @objc dynamic public var canCreate = false

    /// Whether the user can modify the schema of the Realm which this
    /// Permission is attached to.
    ///
    /// This field is only applicable to Permissions attached to Realms, and not
    /// to Realms or Objects.
    @objc dynamic public var canModifySchema = false

    /// :nodoc:
    @objc override public class func _realmObjectName() -> String {
        return "__Permission"
    }
}

/**
 A Role within the permissions system.

 A Role consists of a name for the role and a list of users which are members of the role.
 Roles are granted privileges on Realms, Classes and Objects, and in turn grant those
 privileges to all users which are members of the role.

 A role named "everyone" is automatically created in new Realms, and all new users which
 connect to the Realm are automatically added to it. Any other roles you wish to use are
 managed as normal Realm objects.
 */
@objc(RealmSwiftPermissionRole)
public class PermissionRole: Object {
    /// The name of the Role
    @objc dynamic public var name = ""
    /// The users which belong to the role
    public let users = List<PermissionUser>()

    /// :nodoc:
    @objc override public class func _realmObjectName() -> String {
        return "__Role"
    }
    /// :nodoc:
    @objc override public class func primaryKey() -> String {
        return "name"
    }
    /// :nodoc:
    @objc override public class func _realmColumnNames() -> [String: String] {
        return ["users": "members"]
    }
}

/**
 A representation of a sync user within the permissions system.

 PermissionUser objects are created automatically for each sync user which connects to
 a Realm, and can also be created manually if you wish to grant permissions to a user
 which has not yet connected to this Realm. When creating a PermissionUser manually, you
 must also manually add it to the "everyone" Role.
 */
@objc(RealmSwiftPermissionUser)
public class PermissionUser: Object {
    /// The unique Realm Object Server user ID string identifying this user. This will
    /// have the same value as `SyncUser.identity`
    @objc dynamic public var identity = ""

    /// The user's private role. This will be initialized to a role named for the user's
    /// identity that contains this user as its only member.
    @objc dynamic public var role: PermissionRole?

    /// Roles which this user belongs to.
    public let roles = LinkingObjects(fromType: PermissionRole.self, property: "users")

    /// :nodoc:
    @objc override public class func _realmObjectName() -> String {
        return "__User"
    }
    /// :nodoc:
    @objc override public class func primaryKey() -> String {
        return "identity"
    }
    /// :nodoc:
    @objc override public class func _realmColumnNames() -> [String: String] {
        return ["identity": "id", "role": "role"]
    }
}

/**
 A singleton object which describes Realm-wide permissions.

 An object of this type is automatically created in the Realm for you, and more objects
 cannot be created manually.

 See `RealmPrivileges` for the meaning of permissions applied to a Realm.
 */
@objc(RealmSwiftRealmPermission)
public class RealmPermission: Object {
    @objc private var id = 0

    /// The permissions for the Realm.
    public let permissions = List<Permission>()

    /// :nodoc:
    @objc override public class func _realmObjectName() -> String {
        return "__Realm"
    }
    /// :nodoc:
    @objc override public class func primaryKey() -> String {
        return "id"
    }
}

/**
 An object which describes class-wide permissions.

 An instance of this object is automatically created in the Realm for class in your schema,
 and should not be created manually.
 */
@objc(RealmSwiftClassPermission)
public class ClassPermission: Object {
    /// The name of the class which these permissions apply to.
    @objc dynamic public var name = ""
    /// The permissions for this class.
    public let permissions = List<Permission>()

    /// :nodoc:
    @objc override public class func _realmObjectName() -> String {
        return "__Class"
    }
    /// :nodoc:
    @objc override public class func primaryKey() -> String {
        return "name"
    }
}

private func optionSetDescription<T: OptionSet>(_ optionSet: T,
                                                _ allValues: [(T.Element, String)]) -> String {
    let valueStr = allValues.filter({ value, _ in optionSet.contains(value) })
                            .map({ _, name in name })
                            .joined(separator: ", ")
    return "\(String(describing: T.self))[\(valueStr)]"
}

/**
 A description of the actual privileges which apply to a Realm.

 This is a combination of all of the privileges granted to all of the Roles which the
 current User is a member of, obtained by calling `realm.getPrivileges()`.

 By default, all operations are permitted, and each privilege field indicates an operation
 which may be forbidden.
 */
public struct RealmPrivileges: OptionSet, CustomDebugStringConvertible {
    public let rawValue: UInt8
    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }

    /// :nodoc:
    public var debugDescription: String {
        return optionSetDescription(self, [(.read, "read"),
                                           (.update, "update"),
                                           (.setPermissions, "setPermissions"),
                                           (.modifySchema, "modifySchema")])
    }

    /// If `false`, the current User is not permitted to see the Realm at all. This can
    /// happen only if the Realm was created locally and has not yet been synchronized.
    public static let read = RealmPrivileges(rawValue: 1 << 0)

    /// If `false`, no modifications to the Realm are permitted. Write transactions can
    /// be performed locally, but any changes made will be reverted by the server.
    /// `setPermissions` and `modifySchema` will always be `false` when this is `false`.
    public static let update = RealmPrivileges(rawValue: 1 << 1)

    /// If `false`, no modifications to the permissions property of the RLMRealmPermissions
    /// object for are permitted. Write transactions can be performed locally, but any
    /// changes made will be reverted by the server.
    ///
    /// Note that if invalide privilege changes are made, `-[RLMRealm privilegesFor*:]`
    /// will return results reflecting those invalid changes until synchronization occurs.
    ///
    /// Even if this field is `true`, note that the user will be unable to grant
    /// privileges to a Role which they do not themselves have.
    ///
    /// Adding or removing Users from a Role is controlled by Update privileges on that
    /// Role, and not by this value.
    public static let setPermissions = RealmPrivileges(rawValue: 1 << 3)

    /// If `false`, the user is not permitted to add new object types to the Realm or add
    /// new properties to existing objec types. Defining new RLMObject subclasses (and not
    /// excluding them from the schema with `-[RLMRealmConfiguration setObjectClasses:]`)
    /// will result in the application crashing if the object types are not first added on
    /// the server by a more privileged user.
    public static let modifySchema = RealmPrivileges(rawValue: 1 << 6)
}

/**
 A description of the actual privileges which apply to a Class within a Realm.

 This is a combination of all of the privileges granted to all of the Roles which the
 current User is a member of, obtained by calling `realm.getPrivileges(ObjectClass.self)`
 or `realm.getPrivileges(forClassNamed: "className")`

 By default, all operations are permitted, and each privilege field indicates an operation
 which may be forbidden.
 */
public struct ClassPrivileges: OptionSet, CustomDebugStringConvertible {
    public let rawValue: UInt8
    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }

    /// :nodoc:
    public var debugDescription: String {
        return optionSetDescription(self, [(.read, "read"),
                                           (.create, "create"),
                                           (.update, "update"),
                                           (.subscribe, "subscribe"),
                                           (.setPermissions, "setPermissions")])
    }

    /// If `false`, the current User is not permitted to see objects of this type, and
    /// attempting to query this class will always return empty results.
    ///
    /// Note that Read permissions are transitive, and so it may be possible to read an
    /// object which the user does not directly have Read permissions for by following a
    /// link to it from an object they do have Read permissions for. This does not apply
    /// to any of the other permission types.
    public static let read = ClassPrivileges(rawValue: 1 << 0)

    /// If `false`, creating new objects of this type is not permitted. Write transactions
    /// creating objects can be performed locally, but the objects will be deleted by the
    /// server when synchronization occurs.
    ///
    /// For objects with Primary Keys, it may not be locally determinable if Create or
    /// Update privileges are applicable. It may appear that you are creating a new object,
    /// but an object with that Primary Key may already exist and simply not be visible to
    /// you, in which case it is actually an Update operation.
    /// Deleting an object is considered a modification, and is governed by this privilege.
    public static let create = ClassPrivileges(rawValue: 1 << 5)

    /// If `false`, no modifications to objects of this type are permitted. Write
    /// transactions modifying the objects can be performed locally, but any changes made
    /// will be reverted by the server.
    ///
    /// Deleting an object is considered a modification, and is governed by this privilege.
    public static let update = ClassPrivileges(rawValue: 1 << 1)

    /// If `false`, the User is not permitted to create new subscriptions for this class.
    /// Local queries against the objects within the Realm will work, but new
    /// subscriptions will never add objects to the Realm.
    public static let subscribe = ClassPrivileges(rawValue: 1 << 4)

    /// If `false`, no modifications to the permissions property of the RLMClassPermissions
    /// object for this type are permitted. Write transactions can be performed locally,
    /// but any changes made will be reverted by the server.
    ///
    /// Note that if invalid privilege changes are made, `-[Realm privilegesFor*:]`
    /// will return results reflecting those invalid changes until synchronization occurs.
    ///
    /// Even if this field is `true`, note that the user will be unable to grant
    /// privileges to a Role which they do not themselves have.
    public static let setPermissions = ClassPrivileges(rawValue: 1 << 3)
}

/**
 A description of the actual privileges which apply to a specific Object.

 This is a combination of all of the privileges granted to all of the Roles which the
 current User is a member of, obtained by calling `realm.getPrivileges(object)`.

 By default, all operations are permitted, and each privilege field indicates an operation
 which may be forbidden.
 */
public struct ObjectPrivileges: OptionSet, CustomDebugStringConvertible {
    public let rawValue: UInt8
    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }

    /// :nodoc:
    public var debugDescription: String {
        return optionSetDescription(self, [(.read, "read"),
                                           (.update, "update"),
                                           (.delete, "delete"),
                                           (.setPermissions, "setPermissions")])
    }

    /// If `false`, the current User is not permitted to read this object directly.
    ///
    /// Objects which cannot be read by a user will appear in a Realm due to that read
    /// permissions are transitive. All objects which a readable object links to are
    /// themselves implicitly readable. If the link to an object with `read=false` is
    /// removed, the object will be deleted from the local Realm.
    public static let read = ObjectPrivileges(rawValue: 1 << 0)

    /// If `false`, modifying the fields of this type is not permitted. Write
    /// transactions modifying the objects can be performed locally, but any changes made
    /// will be reverted by the server.
    ///
    /// Note that even if this is `true`, the user may not be able to modify the
    /// `List<Permission>` property of the object (if it exists), as that is
    /// governed by `setPermissions`.
    public static let update = ObjectPrivileges(rawValue: 1 << 1)

    /// If `false`, deleting this object is not permitted. Write transactions which delete
    /// the object can be performed locally, but the server will restore it.
    ///
    /// It is possible to have `update` but not `delete` privileges, or vice versa. For
    /// objects with primary keys, `delete` but not `update` is ill-advised, as an object
    /// can be updated by deleting and recreating it.
    public static let delete = ObjectPrivileges(rawValue: 1 << 2)

    /// If `false`, modifying the privileges of this specific object is not permitted.
    ///
    /// Object-specific permissions are set by declaring a `List<Permission>`
    /// property on the `Object` subclass. Modifications to this property are
    /// controlled by `setPermissions` rather than `update`.
    ///
    /// Even if this field is `true`, note that the user will be unable to grant
    /// privileges to a Role which they do not themselves have.
    public static let setPermissions = ObjectPrivileges(rawValue: 1 << 3)
}

extension Realm {
    // MARK: Sync - Permissions

    /**
    Returns the computed privileges which the current user has for this Realm.

    This combines all privileges granted on the Realm by all Roles which the
    current User is a member of into the final privileges which will be
    enforced by the server.

    The privilege calculation is done locally using cached data, and inherently
    may be stale. It is possible that this method may indicate that an
    operation is permitted but the server will still reject it if permission is
    revoked before the changes have been integrated on the server.

    Non-synchronized and fully-synchronized Realms always have permission to
    perform all operations.

     - returns: The privileges which the current user has for the current Realm.
     */
    public func getPrivileges() -> RealmPrivileges {
        return RealmPrivileges(rawValue: RLMGetComputedPermissions(rlmRealm, nil))
    }

    /**
    Returns the computed privileges which the current user has for the given object.

    This combines all privileges granted on the object by all Roles which the
    current User is a member of into the final privileges which will be
    enforced by the server.

    The privilege calculation is done locally using cached data, and inherently
    may be stale. It is possible that this method may indicate that an
    operation is permitted but the server will still reject it if permission is
    revoked before the changes have been integrated on the server.

    Non-synchronized and fully-synchronized Realms always have permission to
    perform all operations.

    The object must be a valid object managed by this Realm. Passing in an
    invalidated object, an unmanaged object, or an object managed by a
    different Realm will throw an exception.

     - parameter object: A managed object to get the privileges for.
     - returns: The privileges which the current user has for the given object.
    */
    public func getPrivileges(_ object: Object) -> ObjectPrivileges {
        return ObjectPrivileges(rawValue: RLMGetComputedPermissions(rlmRealm, object))
    }

    /**
    Returns the computed privileges which the current user has for the given class.

    This combines all privileges granted on the class by all Roles which the
    current User is a member of into the final privileges which will be
    enforced by the server.

    The privilege calculation is done locally using cached data, and inherently
    may be stale. It is possible that this method may indicate that an
    operation is permitted but the server will still reject it if permission is
    revoked before the changes have been integrated on the server.

    Non-synchronized and fully-synchronized Realms always have permission to
    perform all operations.

     - parameter cls: An Object subclass to get the privileges for.
     - returns: The privileges which the current user has for the given class.
    */
    public func getPrivileges<T: Object>(_ cls: T.Type) -> ClassPrivileges {
        return ClassPrivileges(rawValue: RLMGetComputedPermissions(rlmRealm, cls.className()))
    }

    /**
    Returns the computed privileges which the current user has for the named class.

    This combines all privileges granted on the class by all Roles which the
    current User is a member of into the final privileges which will be
    enforced by the server.

    The privilege calculation is done locally using cached data, and inherently
    may be stale. It is possible that this method may indicate that an
    operation is permitted but the server will still reject it if permission is
    revoked before the changes have been integrated on the server.

    Non-synchronized and fully-synchronized Realms always have permission to
    perform all operations.

     - parameter className: The name of an Object subclass to get the privileges for.
     - returns: The privileges which the current user has for the named class.
    */
    public func getPrivileges(forClassNamed className: String) -> ClassPrivileges {
        return ClassPrivileges(rawValue: RLMGetComputedPermissions(rlmRealm, className))
    }

    /**
    Returns the class-wide permissions for the given class.

     - parameter cls: An Object subclass to get the permissions for.
     - returns: The class-wide permissions for the given class.
     - requires: This must only be called on a Realm using query-based sync.
    */
    public func permissions<T: Object>(forType cls: T.Type) -> List<Permission> {
        return permissions(forClassNamed: cls._realmObjectName() ?? cls.className())
    }

    /**
    Returns the class-wide permissions for the named class.

     - parameter cls: The name of an Object subclass to get the permissions for.
     - returns: The class-wide permissions for the named class.
     - requires: className must name a class in this Realm's schema.
     - requires: This must only be called on a Realm using query-based sync.
    */
    public func permissions(forClassNamed className: String) -> List<Permission> {
        let classPermission = object(ofType: ClassPermission.self, forPrimaryKey: className)!
        return classPermission.permissions
    }

    /**
    Returns the Realm-wide permissions.

     - requires: This must only be called on a Realm using query-based sync.
    */
    public var permissions: List<Permission> {
        return object(ofType: RealmPermission.self, forPrimaryKey: 0)!.permissions
    }

    // MARK: Sync - Subscriptions

    /**
    Returns this list of the query-based sync subscriptions made for this Realm.

    This list includes all subscriptions which are currently in the states
    `.pending`, `.created`, and `.error`. Newly created subscriptions which are
    still in the `.creating` state are not included, and calling this
    immediately after calling `Results.subscribe()` will typically not include
    that subscription. Similarly, because unsubscription happens asynchronously,
    this may continue to include subscriptions after
    `SyncSubscription.unsubscribe()` is called on them.

     - requires: This must only be called on a Realm using query-based sync.
    */
    public func subscriptions() -> Results<SyncSubscription> {
        return Results(rlmRealm.subscriptions() as! RLMResults<AnyObject>)
    }

    /**
    Returns the named query-based sync subscription, if it exists.

    Subscriptions are created asynchronously, so calling this immediately after
    calling Results.subscribe(named:)` will typically return `nil`. Only
    subscriptions which are currently in the states `.pending`, `.created`,
    and `.error` can be retrieved with this method.

     - requires: This must only be called on a Realm using query-based sync.
    */
    public func subscription(named: String) -> SyncSubscription? {
        return rlmRealm.subscription(withName: named).map(SyncSubscription.init)
    }
}

extension List where Element == Permission {
    /**
    Returns the Permission object for the named Role in this List, creating it if needed.

    This function should be used in preference to manually querying the List for
    the applicable Permission as it ensures that there is exactly one Permission
    for the given Role, merging duplicates and inserting new ones as needed.

     - warning: This can only be called on a managed List<Permission>.
     - warning: The managing Realm must be in a write transaction.

     - parameter roleName: The name of the Role to obtain the Permission for.
     - returns: A Permission object contained in this List for the named Role.
    */
    public func findOrCreate(forRoleNamed roleName: String) -> Permission {
        precondition(realm != nil, "Cannot be called on an unmanaged object")
        return RLMPermissionForRole(_rlmArray, realm!.create(PermissionRole.self, value: [roleName], update: .modified)) as! Permission
    }

    /**
    Returns the Permission object for the named Role in this List, creating it if needed.

    This function should be used in preference to manually querying the List for
    the applicable Permission as it ensures that there is exactly one Permission
    for the given Role, merging duplicates and inserting new ones as needed.

     - warning: This can only be called on a managed List<Permission>.
     - warning: The managing Realm must be in a write transaction.

     - parameter roleName: The name of the Role to obtain the Permission for.
     - returns: A Permission object contained in this List for the named Role.
    */
    public func findOrCreate(forRole role: PermissionRole) -> Permission {
        precondition(realm != nil, "Cannot be called on an unmanaged object")
        return RLMPermissionForRole(_rlmArray, role) as! Permission
    }
}
