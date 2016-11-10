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
import Foundation

/**
 An object representing a Realm Object Server user.

 - see: `RLMSyncUser`
 */
public typealias SyncUser = RLMSyncUser

/**
 A singleton which configures and manages the Realm Object Server synchronization-related functionality.

 - see: `RLMSyncManager`
 */
public typealias SyncManager = RLMSyncManager

extension SyncManager {
#if swift(>=3.0)
    /// The sole instance of the singleton.
    public static var shared: SyncManager {
        return __shared()
    }
#else
    /// The sole instance of the singleton.
    @nonobjc public static func sharedManager() -> SyncManager {
        return __sharedManager()
    }
#endif
}

/**
 A session object which represents communication between the client and server for a specific Realm.

 - see: `RLMSyncSession`
 */
public typealias SyncSession = RLMSyncSession

/**
 A closure type for a closure which can be set on the `SyncManager` to allow errors to be reported to the application.

 - see: `RLMSyncErrorReportingBlock`
 */
public typealias ErrorReportingBlock = RLMSyncErrorReportingBlock

/**
 A closure type for a closure which is used by certain APIs to asynchronously return a `User` object to the application.

 - see: `RLMUserCompletionBlock`
 */
public typealias UserCompletionBlock = RLMUserCompletionBlock

/**
 An error associated with the SDK's synchronization functionality.

 - see: `RLMSyncError`
 */
public typealias SyncError = RLMSyncError

/**
 An enum which can be used to specify the level of logging.

 - see: `RLMSyncLogLevel`
 */
public typealias SyncLogLevel = RLMSyncLogLevel

#if swift(>=3.0)

/**
 A data type whose values represent different authentication providers that can be used with the Realm Object Server.

 - see: `RLMIdentityProvider`
 */
public typealias Provider = RLMIdentityProvider

/// A `SyncConfiguration` represents configuration parameters for Realms intended to sync with a Realm Object Server.
public struct SyncConfiguration {
    /// The `SyncUser` who owns the Realm that this configuration should open.
    public let user: SyncUser

    /**
     The URL of the Realm on the Realm Object Server that this configuration should open.

     - warning: The URL must be absolute (e.g. `realms://example.com/~/foo`), and cannot end with
                `.realm`, `.realm.lock` or `.realm.management`.
     */
    public let realmURL: URL

    /// A policy that determines what should happen when all references to Realms opened by this configuration
    /// go out of scope.
    internal let stopPolicy: RLMSyncStopPolicy

    internal init(config: RLMSyncConfiguration) {
        self.user = config.user
        self.realmURL = config.realmURL
        self.stopPolicy = config.stopPolicy
    }

    func asConfig() -> RLMSyncConfiguration {
        let config = RLMSyncConfiguration(user: user, realmURL: realmURL)
        config.stopPolicy = stopPolicy
        return config
    }

    /**
     Initialize a sync configuration with a user and a Realm URL.

     - warning: The URL must be absolute (e.g. `realms://example.com/~/foo`), and cannot end with
                `.realm`, `.realm.lock` or `.realm.management`.
     */
    public init(user: SyncUser, realmURL: URL) {
        self.user = user
        self.realmURL = realmURL
        self.stopPolicy = .afterChangesUploaded
    }
}

/// A `Credential` represents data that uniquely identifies a Realm Object Server user.
public struct Credential {
    public typealias Token = String

    internal var token: Token
    internal var provider: Provider
    internal var userInfo: [String: Any]

    /// Initialize a new credential using a custom token, authentication provider, and user information dictionary. In
    /// most cases, the convenience initializers should be used instead.
    public init(customToken token: Token, provider: Provider, userInfo: [String: Any] = [:]) {
        self.token = token
        self.provider = provider
        self.userInfo = userInfo
    }

    private init(_ credential: RLMSyncCredential) {
        self.token = credential.token
        self.provider = credential.provider
        self.userInfo = credential.userInfo
    }

    /// Initialize a new credential using a Facebook account token.
    public static func facebook(token: Token) -> Credential {
        return Credential(RLMSyncCredential(facebookToken: token))
    }

    /// Initialize a new credential using a Google account token.
    public static func google(token: Token) -> Credential {
        return Credential(RLMSyncCredential(googleToken: token))
    }

    /// Initialize a new credential using an iCloud account token.
    public static func iCloud(token: Token) -> Credential {
        return Credential(RLMSyncCredential(iCloudToken: token))
    }

    /// Initialize a new credential using a Realm Object Server username and password.
    public static func usernamePassword(username: String,
                                        password: String,
                                        register: Bool = false) -> Credential {
        return Credential(RLMSyncCredential(username: username, password: password, register: register))
    }

    /// Initialize a new credential using a Realm Object Server access token.
    public static func accessToken(_ accessToken: String, identity: String) -> Credential {
        return Credential(RLMSyncCredential(accessToken: accessToken, identity: identity))
    }
}

extension RLMSyncCredential {
    fileprivate convenience init(_ credential: Credential) {
        self.init(customToken: credential.token, provider: credential.provider, userInfo: credential.userInfo)
    }
}

extension SyncUser {
    /// Given a credential and server URL, log in a user and asynchronously return a `SyncUser` object which can be used to
    /// open Realms and Sessions.
    public static func logIn(with credential: Credential,
                             server authServerURL: URL,
                             timeout: TimeInterval = 30,
                             onCompletion completion: @escaping UserCompletionBlock) {
        return SyncUser.__logIn(with: RLMSyncCredential(credential),
                                authServerURL: authServerURL,
                                timeout: timeout,
                                onCompletion: completion)
    }

    /// An array of all valid, logged-in users.
    public static var all: [SyncUser] {
        return __allUsers()
    }

    /**
     The logged-in user. `nil` if none exists.

     - warning: Throws an Objective-C exception if more than one logged-in user exists.
     */
    public static var current: SyncUser? {
        return __current()
    }
}

#else

/**
 A data type whose values represent different authentication providers that can be used with the Realm Object Server.

 - see: `RLMIdentityProvider`
 */
public typealias Provider = String // `RLMIdentityProvider` imports as `NSString`

/// A `SyncConfiguration` represents configuration parameters for Realms intended to sync with a Realm Object Server.
public struct SyncConfiguration {
    /// The `SyncUser` who owns the Realm that this configuration should open.
    public let user: SyncUser

    /**
     The URL of the Realm on the Realm Object Server that this configuration should open.

     - warning: The URL must be absolute (e.g. `realms://example.com/~/foo`), and cannot end with
                `.realm`, `.realm.lock` or `.realm.management`.
     */
    public let realmURL: NSURL

    /// A policy that determines what should happen when all references to Realms opened by this configuration
    /// go out of scope.
    internal let stopPolicy: RLMSyncStopPolicy

    internal init(config: RLMSyncConfiguration) {
        self.user = config.user
        self.realmURL = config.realmURL
        self.stopPolicy = config.stopPolicy
    }

    func asConfig() -> RLMSyncConfiguration {
        let config = RLMSyncConfiguration(user: user, realmURL: realmURL)
        config.stopPolicy = stopPolicy
        return config
    }

    /**
     Initialize a sync configuration with a user and a Realm URL.

     - warning: The URL must be absolute (e.g. `realms://example.com/~/foo`), and cannot end with
                `.realm`, `.realm.lock` or `.realm.management`.
     */
    public init(user: SyncUser, realmURL: NSURL) {
        self.user = user
        self.realmURL = realmURL
        self.stopPolicy = .AfterChangesUploaded
    }
}

/// A `Credential` represents data that uniquely identifies a Realm Object Server user.
public struct Credential {
    public typealias Token = String

    internal var token: Token
    internal var provider: Provider
    internal var userInfo: [String: AnyObject]

    // swiftlint:disable valid_docs

    /// Initialize a new credential using a custom token, authentication provider, and user information dictionary. In
    /// most cases, the convenience initializers should be used instead.
    public init(customToken token: Token, provider: Provider, userInfo: [String: AnyObject] = [:]) {
        self.token = token
        self.provider = provider
        self.userInfo = userInfo
    }

    private init(_ credential: RLMSyncCredential) {
        self.token = credential.token
        self.provider = credential.provider
        self.userInfo = credential.userInfo
    }

    /// Initialize a new credential using a Facebook account token.
    public static func facebook(token: Token) -> Credential {
        return Credential(RLMSyncCredential(facebookToken: token))
    }

    /// Initialize a new credential using a Google account token.
    public static func google(token: Token) -> Credential {
        return Credential(RLMSyncCredential(googleToken: token))
    }

    /// Initialize a new credential using an iCloud account token.
    public static func iCloud(token: Token) -> Credential {
        return Credential(RLMSyncCredential(ICloudToken: token))
    }

    /// Initialize a new credential using a Realm Object Server username and password.
    public static func usernamePassword(username: String,
                                        password: String,
                                        register: Bool = false) -> Credential {
        return Credential(RLMSyncCredential(username: username, password: password, register: register))
    }

    /// Initialize a new credential using a Realm Object Server access token.
    public static func accessToken(accessToken: String, identity: String) -> Credential {
        return Credential(RLMSyncCredential(accessToken: accessToken, identity: identity))
    }
}

extension RLMSyncCredential {
    private convenience init(_ credential: Credential) {
        self.init(customToken: credential.token, provider: credential.provider, userInfo: credential.userInfo)
    }
}

extension SyncUser {
    /// Given a credential and server URL, log in a user and asynchronously return a `SyncUser` object which can be used to
    /// open Realms and Sessions.
    public static func logInWithCredential(credential: Credential,
                                           authServerURL: NSURL,
                                           timeout: NSTimeInterval = 30,
                                           onCompletion completion: UserCompletionBlock) {
        return __logInWithCredential(RLMSyncCredential(credential),
                                     authServerURL: authServerURL,
                                     timeout: timeout,
                                     onCompletion: completion)
    }

    /// An array of all valid, logged-in users.
    @nonobjc public static func allUsers() -> [SyncUser] {
        return __allUsers()
    }

    /**
     The logged-in user. `nil` if none exists.

     - warning: Throws an Objective-C exception if more than one logged-in user exists.
     */
    @nonobjc public static func currentUser() -> SyncUser? {
        return __currentUser()
    }
}

#endif
