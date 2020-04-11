////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 Realm Inc.
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

import Foundation
import Realm
import Realm.Private

/**
An object representing the Realm App configuration

- see: `RLMAppConfiguration`
*/
public typealias AppConfiguration = RLMAppConfiguration

public typealias OptionalErrorCompletionBlock = ((Error?) -> ())

/// The `RealmApp` has the fundamental set of methods for communicating with a Realm
/// application backend.

/// This interface provides access to login and authentication.
public class RealmApp {
    
    public typealias UserCompletionBlock = ((SyncUser?, Error?) -> ())
    
    internal var _app: RLMApp

    /// Returns a list of users
    public var allUsers: [String:SyncUser] {
        _app.allUsers()
    }
    
    /// Returns the current user if there is one
    public var currentUser: SyncUser? {
        _app.currentUser()
    }
    
    /// Get an application with a given appId and configuration.
    /// - Parameters:
    ///   - appId: appId The unique identifier of your Realm app.
    ///   - configuration: configuration A configuration object to configure this client.
    public init(_ appId: String, _ configuration: AppConfiguration?) {
        _app = RLMApp.init(appId, configuration: configuration)
    }
    
    public func providerClient<T>() -> T where T: ProviderClient {
        if (type(of: UserAPIKeyProviderClient.self) == T.self) {
            return userAPIKeyProviderClient() as! T
        }
        
        return UserAPIKeyProviderClient(_app.userAPIKeyProviderClient()) as! T
    }
    
    /// A client for the username/password authentication provider which
    /// can be used to obtain a credential for logging in.
    ///
    /// Used to perform requests specifically related to the username/password provider.
    /// - Returns: A usernamePasswordProviderClient for performing auth functions
    public func usernamePasswordProviderClient() -> UsernamePasswordProviderClient {
        UsernamePasswordProviderClient(_app.usernamePasswordProviderClient())
    }

    /// A client for the user API key authentication provider which
    /// can be used to create and modify user API keys.
    ///
    /// This client should only be used by an authenticated user.
    public func userAPIKeyProviderClient() -> UserAPIKeyProviderClient {
        UserAPIKeyProviderClient(_app.userAPIKeyProviderClient())
    }
    
    /// Login to a user for the Realm app.
    /// - Parameters:
    ///   - credentials: The credentials identifying the user.
    ///   - completion: A callback invoked after completion.
    public func loginWithCredential(_ credentials: AppCredentials,
                                    _ completion: @escaping UserCompletionBlock) {
        _app.login(withCredential: credentials.credentials, completion: completion)
    }
    
    /// Switches the active user to the specified user.
    ///
    /// This sets which user is used by all RLMApp operations which require a user. This is a local operation which does not access the network.
    /// An exception will be throw if the user is not valid. The current user will remain logged in.
    /// - Parameter syncUser: The user to switch to.
    /// - Returns: The user you intend to switch to
    @discardableResult
    public func switchToUser(_ syncUser: SyncUser) -> SyncUser {
        _app.switch(to: syncUser)
    }
        
    /// Removes a specified user
    ///
    /// This logs out and destroys the session related to the user. The completion block will return an error
    /// if the user is not found or is already removed.
    /// - Parameters:
    ///   - syncUser: The user you would like to remove
    ///   - completion: A callback invoked on completion
    public func removeUser(_ syncUser: SyncUser, _ completion: @escaping OptionalErrorCompletionBlock) {
        _app.remove(syncUser, completion: completion)
    }

    /// Logs out the current user
    ///
    /// The users state will be set to `Removed` is they are an anonymous user or `LoggedOut` if they are authenticated by a username / password or third party auth clients
    /// If the logout request fails, this method will still clear local authentication state.
    /// - Parameter completion: A callback invoked on completion
    public func logOut(_ completion: @escaping OptionalErrorCompletionBlock) {
        _app.logOut(completion: completion)
    }
    
    /// Logs out the current user
    ///
    /// The users state will be set to `Removed` is they are an anonymous user or `LoggedOut` if they are authenticated by a username / password or third party auth clients
    /// If the logout request fails, this method will still clear local authentication state.
    /// - Parameters:
    ///   - syncUser: The user to log out
    ///   - completion: A callback invoked on completion
    public func logOut(_ syncUser: SyncUser, _ completion: @escaping OptionalErrorCompletionBlock) {
        _app.logOut(syncUser, completion: completion)
    }
    
    /// Links the currently authenticated user with a new identity, where the identity is defined by the credential
    /// specified as a parameter. This will only be successful if this `RLMSyncUser` is the currently authenticated
    /// with the client from which it was created. On success a new user will be returned with the new linked credentials.
    /// - Parameters:
    ///   - syncUser: The user which will have the credentials linked to, the user must be logged in
    ///   - credentials: The `RLMAppCredentials` used to link the user to a new identity.
    ///   - completion: The completion handler to call when the linking is complete.
    ///                 If the operation is  successful, the result will contain a new
    ///                 `RLMSyncUser` object representing the currently logged in user.
    public func linkUser(_ syncUser: SyncUser,
                         _ credentials: AppCredentials,
                         _ completion: @escaping UserCompletionBlock) {
        _app.linkUser(syncUser, credentials: credentials.credentials, completion: completion)
    }

}

public protocol ProviderClient {
    associatedtype Client = RLMProviderClient
    var providerClient: Client { get }
}

public class UserAPIKeyProviderClient: ProviderClient {
    
    public typealias OptionalUserAPIKeyCompletionBlock = ((UserAPIKey?, Error?) -> ())
    public typealias OptionalUserAPIKeysCompletionBlock = (([UserAPIKey]?, Error?) -> ())

    public typealias OptionalErrorCompletionBlock = ((Error?) -> ())

    
    public var providerClient: RLMUserAPIKeyProviderClient
    
    init(_ providerClient: RLMUserAPIKeyProviderClient) {
        self.providerClient = providerClient
    }
    
    /// Creates a user API key that can be used to authenticate as the current user.
    /// - Parameters:
    ///   - name: The name of the API key to be created.
    ///   - completion: A callback to be invoked once the call is complete.
    public func createAPIKey(_ name: String, _ completion: @escaping OptionalUserAPIKeyCompletionBlock) {
        providerClient.createApiKey(withName: name) { (userAPIKey, error) in
            guard let userAPIKey = userAPIKey else {
                completion(nil, error)
                return
            }
            completion(UserAPIKey(userAPIKey), error)
        }
    }
    
    /// Fetches a user API key associated with the current user.
    /// - Parameters:
    ///   - userAPIKey: The ObjectId of the API key to fetch.
    ///   - completion:  A callback to be invoked once the call is complete.
    public func fetchAPIKey(_ userAPIKey: UserAPIKey, _ completion: @escaping OptionalUserAPIKeyCompletionBlock) {
        providerClient.fetchApiKey(userAPIKey.objectId) { (userAPIKey, error) in
            guard let userAPIKey = userAPIKey else {
                completion(nil, error)
                return
            }
            completion(UserAPIKey(userAPIKey), error)
        }
    }

    /// Fetches the user API keys associated with the current user.
    /// - Parameter completion: A callback to be invoked once the call is complete.
    public func fetchAPIKeys(_ completion: @escaping OptionalUserAPIKeysCompletionBlock) {
        providerClient.fetchApiKeys { (apiKeys, error) in
            guard let apiKeys = apiKeys else {
                completion(nil, error)
                return
            }
            completion(apiKeys.map {UserAPIKey($0)}, error)
        }
    }
    
    /// Enables a user API key associated with the current user.
    /// - Parameters:
    ///   - userAPIKey: The ObjectId of the  API key to enable.
    ///   - completion: A callback to be invoked once the call is complete.
    public func enable(_ userAPIKey: UserAPIKey, _ completion: @escaping OptionalErrorCompletionBlock) {
        providerClient.enableApiKey(userAPIKey.objectId, completion: completion)
    }
    
    /// Disables a user API key associated with the current user.
    /// - Parameters:
    ///   - userAPIKey: The ObjectId of the API key to disable.
    ///   - completion: A callback to be invoked once the call is complete.
    public func disable(_ userAPIKey: UserAPIKey, _ completion: @escaping OptionalErrorCompletionBlock) {
        providerClient.disableApiKey(userAPIKey.objectId, completion: completion)
    }

    /// Deletes a user API key associated with the current user.
    /// - Parameters:
    ///   - userAPIKey: The ObjectId of the API key to delete.
    ///   - completion: A callback to be invoked once the call is complete.
    public func delete(_ userAPIKey: UserAPIKey, _ completion: @escaping OptionalErrorCompletionBlock) {
        providerClient.deleteApiKey(userAPIKey.objectId, completion: completion)
    }
}

/**
  A client for the username/password authentication provider which
  can be used to obtain a credential for logging in,
  and to perform requests specifically related to the username/password provider.
*/
public class UsernamePasswordProviderClient: ProviderClient {
    
    public var providerClient: RLMUsernamePasswordProviderClient
    
    init(_ providerClient: RLMUsernamePasswordProviderClient) {
        self.providerClient = providerClient
    }
    
    /// Registers a new email identity with the username/password provider,
    /// and sends a confirmation email to the provided address.
    /// - Parameters:
    ///   - email: The email address of the user to register.
    ///   - password: The password that the user created for the new username/password identity.
    ///   - completion: A callback to be invoked once the call is complete.
    public func register(withEmail email: String,
                         _ password: String,
                         _ completion: @escaping OptionalErrorCompletionBlock) {
        providerClient.registerEmail(email, password: password, completion: completion)
    }
    
    /// Confirms an email identity with the username/password provider.
    /// - Parameters:
    ///   - token: The confirmation token that was emailed to the user.
    ///   - tokenId: The confirmation token id that was emailed to the user.
    ///   - completion: A callback to be invoked once the call is complete.
    public func confirm(withToken token: String,
                        _ tokenId: String,
                        _ completion: @escaping OptionalErrorCompletionBlock) {
        providerClient.confirmUser(token, tokenId: tokenId, completion: completion)
    }

    /// Re-sends a confirmation email to a user that has registered but
    /// not yet confirmed their email address.
    /// - Parameters:
    ///   - email: The email address of the user to re-send a confirmation for.
    ///   - completion: A callback to be invoked once the call is complete.
    public func resendConfirmationEmail(_ email: String, _ completion: @escaping OptionalErrorCompletionBlock) {
        providerClient.resendConfirmationEmail(email, completion: completion)
    }
    
    /// Sends a password reset email to the given email address.
    /// - Parameters:
    ///   - email: The email address of the user to send a password reset email for.
    ///   - completion: A callback to be invoked once the call is complete.
    public func sendResetPasswordEmail(_ email: String, _ completion: @escaping OptionalErrorCompletionBlock) {
        providerClient.sendResetPasswordEmail(email, completion: completion)
    }
    
    /// Resets the password of an email identity using the
    /// password reset token emailed to a user.
    /// - Parameters:
    ///   - password: The new password.
    ///   - token: The password reset token that was emailed to the user.
    ///   - tokenId: The password reset token id that was emailed to the user.
    ///   - completion: A callback to be invoked once the call is complete.
    public func resetPassword(to password: String,
                              _ token: String,
                              _ tokenId: String,
                              _ completion: @escaping OptionalErrorCompletionBlock) {
        providerClient.resetPassword(to: password, token: token, tokenId: tokenId, completion: completion)
    }
    
    /// Resets the password of an email identity using the
    /// password reset function set up in the application.
    ///
    /// TODO: Add an overloaded version of this method that takes
    /// TODO: raw, non-serialized args.
    /// - Parameters:
    ///   - email: The email address of the user.
    ///   - password: The desired new password.
    ///   - args: A pre-serialized list of arguments. Must be a JSON array.
    ///   - completion: A callback to be invoked once the call is complete.
    public func callResetPasswordFunction(_ email: String,
                                          password: String,
                                          args: String,
                                          _ completion: @escaping OptionalErrorCompletionBlock) {
        providerClient.callResetPasswordFunction(email, password: password, args: args, completion: completion)
    }
    
}

/**
An object representing the Stitch User API Key used by userAPIKeyProviderClient()

- see: `RLMUserAPIKey`
*/
public struct UserAPIKey {
    
    // The ObjectId of the user
    public var objectId: ObjectId {
        do {
            return try ObjectId(string: userAPIKey.objectId.stringValue)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    // The name of the key.
    public var name: String {
        userAPIKey.name
    }
    
    // The actual key. Will only be included in
    // the response when an API key is first created.
    public var key: String? {
        userAPIKey.key
    }
    
    // Indicates if the API key is disabled or not
    public var disabled: Bool {
        userAPIKey.disabled
    }
    
    internal var userAPIKey: RLMUserAPIKey
    
    init(_ userAPIKey: RLMUserAPIKey) {
        self.userAPIKey = userAPIKey
    }
}
