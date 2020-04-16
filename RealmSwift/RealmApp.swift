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

public typealias OptionalErrorCompletionBlock = ((Error?) -> Void)

/// The `RealmApp` has the fundamental set of methods for communicating with a Realm
/// application backend.

/// This interface provides access to login and authentication.
public class RealmApp {

    public typealias UserCompletionBlock = ((SyncUser?, Error?) -> Void)

    internal var app: RLMApp

    /// Returns a list of users
    public var allUsers: [String: SyncUser] {
        return app.allUsers()
    }

    /// Returns the current user if there is one
    public var currentUser: SyncUser? {
        app.currentUser()
    }

    /// Get an application with a given appId and configuration.
    /// - Parameters:
    ///   - appId: appId The unique identifier of your Realm app.
    ///   - configuration: configuration A configuration object to configure this client.
    public init(_ appId: String, _ configuration: AppConfiguration?) {
        app = RLMApp.init(appId, configuration: configuration)
    }

    /// A client for the username/password authentication provider which
    /// can be used to obtain a credential for logging in.
    ///
    /// Used to perform requests specifically related to the username/password provider.
    /// - Returns: A usernamePasswordProviderClient for performing auth functions
    public func usernamePasswordProviderClient() -> UsernamePasswordProviderClient {
        UsernamePasswordProviderClient(app.usernamePasswordProviderClient())
    }

    /// A client for the user API key authentication provider which
    /// can be used to create and modify user API keys.
    ///
    /// This client should only be used by an authenticated user.
    public func userAPIKeyProviderClient() -> UserAPIKeyProviderClient {
        UserAPIKeyProviderClient(app.userAPIKeyProviderClient())
    }

    /// Login to a user for the Realm app.
    /// - Parameters:
    ///   - credentials: The credentials identifying the user.
    ///   - completion: A callback invoked after completion.
    public func loginWithCredential(_ credentials: AppCredentials,
                                    _ completion: @escaping UserCompletionBlock) {
        app.login(withCredential: credentials.credentials, completion: completion)
    }

    /// Switches the active user to the specified user.
    ///
    /// This sets which user is used by all RLMApp operations which require a user. This is a local operation which does not access the network.
    /// An exception will be throw if the user is not valid. The current user will remain logged in.
    /// - Parameter syncUser: The user to switch to.
    /// - Returns: The user you intend to switch to
    @discardableResult
    public func switchToUser(_ syncUser: SyncUser) -> SyncUser {
        app.switch(to: syncUser)
    }

    /// Removes a specified user
    ///
    /// This logs out and destroys the session related to the user. The completion block will return an error
    /// if the user is not found or is already removed.
    /// - Parameters:
    ///   - syncUser: The user you would like to remove
    ///   - completion: A callback invoked on completion
    public func removeUser(_ syncUser: SyncUser, _ completion: @escaping OptionalErrorCompletionBlock) {
        app.remove(syncUser, completion: completion)
    }

    /// Logs out the current user
    ///
    /// The users state will be set to `Removed` is they are an anonymous user or `LoggedOut` if they are authenticated by a username / password or third party auth clients
    /// If the logout request fails, this method will still clear local authentication state.
    /// - Parameter completion: A callback invoked on completion
    public func logOut(_ completion: @escaping OptionalErrorCompletionBlock) {
        app.logOut(completion: completion)
    }

    /// Logs out the current user
    ///
    /// The users state will be set to `Removed` is they are an anonymous user or `LoggedOut` if they are authenticated by a username / password or third party auth clients
    /// If the logout request fails, this method will still clear local authentication state.
    /// - Parameters:
    ///   - syncUser: The user to log out
    ///   - completion: A callback invoked on completion
    public func logOut(_ syncUser: SyncUser, _ completion: @escaping OptionalErrorCompletionBlock) {
        app.logOut(syncUser, completion: completion)
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
        app.linkUser(syncUser, credentials: credentials.credentials, completion: completion)
    }

}
