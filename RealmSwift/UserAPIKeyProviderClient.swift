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

public class UserAPIKeyProviderClient: ProviderClient {

    public typealias OptionalUserAPIKeyCompletionBlock = ((UserAPIKey?, Error?) -> Void)
    public typealias OptionalUserAPIKeysCompletionBlock = (([UserAPIKey]?, Error?) -> Void)

    public typealias OptionalErrorCompletionBlock = ((Error?) -> Void)


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
