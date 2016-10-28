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

/**
 A session object which represents communication between the client and server for a specific Realm.

 - see: `RLMSyncSession`
 */
public typealias SyncSession = RLMSyncSession

/**
 An options type which represents certain authentication actions that can be associated with certain credential types.

 - see: `RLMAuthenticationActions`
 */
public typealias AuthenticationActions = RLMAuthenticationActions

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

public typealias SyncManagementObjectStatus = RLMSyncManagementObjectStatus

#if swift(>=3.0)

/**
 A data type whose values represent different authentication providers that can be used with the Realm Object Server.

 - see: `RLMIdentityProvider`
 */
public typealias Provider = RLMIdentityProvider

/// A `Credential` represents data that uniquely identifies a Realm Object Server user.
public struct Credential {
    public typealias Token = String

    var token: Token
    var provider: Provider
    var userInfo: [String: Any]

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
                                        actions: AuthenticationActions) -> Credential {
        return Credential(RLMSyncCredential(username: username, password: password, actions: actions))
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
    public static func authenticate(with credential: Credential,
                                    server authServerURL: URL,
                                    timeout: TimeInterval = 30,
                                    onCompletion completion: @escaping UserCompletionBlock) {
        return SyncUser.__authenticate(with: RLMSyncCredential(credential),
                                   authServerURL: authServerURL,
                                   timeout: timeout,
                                   onCompletion: completion)
    }

    public func managementRealm() throws -> Realm {
        let components = NSURLComponents(url: authenticationServer!, resolvingAgainstBaseURL: false)!
        components.scheme = "realm"
        components.path = "/~/__management"

        let managementRealmUrl = components.url!

        let config = Realm.Configuration(syncConfiguration: (user: self, realmURL: managementRealmUrl), objectTypes: [PermissionChange.self])
        return try Realm(configuration: config)
    }
}

/**
 * This is the base class managing the meta info. The inheritance from the other
 * classes is assumed to be flattened out in the schema.
 */
public class PermissionBaseObject: Object {
    public dynamic var id = UUID().uuidString
    public dynamic var createdAt = Date()
    public dynamic var updatedAt = Date()

    public let statusCode = RealmOptional<Int>()
    public dynamic var statusMessage: String?

    public var status: SyncManagementObjectStatus {
        guard let statusCode = statusCode.value else {
            return .notProcessed
        }
        if statusCode == 0 {
            return .success
        }
        return .error
    }

    override public class func shouldIncludeInDefaultSchema() -> Bool {
        return false
    }
}

public final class PermissionChange: PermissionBaseObject {
    public dynamic var realmUrl = "*"
    public dynamic var userId = "*"

    public let mayRead = RealmOptional<Bool>()
    public let mayWrite = RealmOptional<Bool>()
    public let mayManage = RealmOptional<Bool>()

    public convenience init(forRealm realm: Realm?, forUser user: SyncUser?, read mayRead: Bool?, write mayWrite: Bool?, manage mayManage: Bool?) {
        self.init()

        if let realmUrl = realm?.configuration.syncConfiguration?.realmURL.absoluteString {
            self.realmUrl = realmUrl
        }

        if let userId = user?.identity {
            self.userId = userId
        }
        
        self.mayRead.value = mayRead
        self.mayWrite.value = mayWrite
        self.mayManage.value = mayManage
    }
}

#else

/**
 A data type whose values represent different authentication providers that can be used with the Realm Object Server.

 - see: `RLMIdentityProvider`
 */
public typealias Provider = String // `RLMIdentityProvider` imports as `NSString`

/// A `Credential` represents data that uniquely identifies a Realm Object Server user.
public struct Credential {
    public typealias Token = String

    var token: Token
    var provider: Provider
    var userInfo: [String: AnyObject]

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
                                        actions: AuthenticationActions) -> Credential {
        return Credential(RLMSyncCredential(username: username, password: password, actions: actions))
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
    public static func authenticateWithCredential(credential: Credential,
                                                  authServerURL: NSURL,
                                                  timeout: NSTimeInterval = 30,
                                                  onCompletion completion: UserCompletionBlock) {
        return SyncUser.__authenticateWithCredential(RLMSyncCredential(credential),
                                                 authServerURL: authServerURL,
                                                 timeout: timeout,
                                                 onCompletion: completion)
    }

    public func managementRealm() throws -> Realm {
        let components = NSURLComponents(URL: authenticationServer!, resolvingAgainstBaseURL: false)!
        components.scheme = "realm"
        components.path = "/~/__management"

        let managementRealmURL = components.URL!

        let config = Realm.Configuration(syncConfiguration: (user: self, realmURL: managementRealmURL), objectTypes: [PermissionChange.self])
        return try Realm(configuration: config)
    }
}

/**
 * This is the base class managing the meta info. The inheritance from the other
 * classes is assumed to be flattened out in the schema.
 */
public class PermissionBaseObject: Object {
    public dynamic var id = NSUUID().UUIDString
    public dynamic var createdAt = NSDate()
    public dynamic var updatedAt = NSDate()

    public let statusCode = RealmOptional<Int>()
    public dynamic var statusMessage: String?

    public var status: SyncManagementObjectStatus {
        guard let statusCode = statusCode.value else {
            return .NotProcessed
        }
        if statusCode == 0 {
            return .Success
        }
        return .Error
    }

    override public class func shouldIncludeInDefaultSchema() -> Bool {
        return false
    }
}

public final class PermissionChange: PermissionBaseObject {
    public dynamic var realmUrl = "*"
    public dynamic var userId = "*"

    public let mayRead = RealmOptional<Bool>()
    public let mayWrite = RealmOptional<Bool>()
    public let mayManage = RealmOptional<Bool>()

    public convenience init(forRealm realm: Realm?, forUser user: SyncUser?, read mayRead: Bool?, write mayWrite: Bool?, manage mayManage: Bool?) {
        self.init()

        if let realmUrl = realm?.configuration.syncConfiguration?.realmURL.absoluteString {
            self.realmUrl = realmUrl
        }

        if let userId = user?.identity {
            self.userId = userId
        }

        self.mayRead.value = mayRead
        self.mayWrite.value = mayWrite
        self.mayManage.value = mayManage
    }
}

#endif
