////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
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

public final class RealmApp: RLMApp<RealmFunctions> {
    /**
     Log in a user and asynchronously retrieve a user object.

     If the log in completes successfully, the completion block will be called, and a
     `SyncUser` representing the logged-in user will be passed to it. This user object
     can be used to open `Realm`s and retrieve `SyncSession`s. Otherwise, the
     completion block will be called with an error.

     - parameter credentials: A `SyncCredentials` object representing the user to log in.
     - parameter timeout: How long the network client should wait, in seconds, before timing out.
     - parameter callbackQueue: The dispatch queue upon which the callback should run. Defaults to the main queue.
     - parameter completion: A callback block to be invoked once the log in completes.
     */
    public func logIn(with credentials: SyncCredentials,
               timeout: TimeInterval = 30,
               callbackQueue queue: DispatchQueue = DispatchQueue.main,
               onCompletion completion: @escaping UserCompletionBlock) {
        return self.__logIn(with: credentials.credentials!,
                            timeout: timeout,
                            callbackQueue: queue,
                            onCompletion: completion)
    }
}

public typealias RealmAuth = RLMAuth
public extension RealmAuth {
    /**
     Log in a user and asynchronously retrieve a user object.

     If the log in completes successfully, the completion block will be called, and a
     `SyncUser` representing the logged-in user will be passed to it. This user object
     can be used to open `Realm`s and retrieve `SyncSession`s. Otherwise, the
     completion block will be called with an error.

     - parameter credentials: A `SyncCredentials` object representing the user to log in.
     - parameter timeout: How long the network client should wait, in seconds, before timing out.
     - parameter callbackQueue: The dispatch queue upon which the callback should run. Defaults to the main queue.
     - parameter completion: A callback block to be invoked once the log in completes.
     */
    func logIn(with credentials: SyncCredentials,
               timeout: TimeInterval = 30,
               callbackQueue queue: DispatchQueue = DispatchQueue.main,
               onCompletion completion: @escaping UserCompletionBlock) {
        return self.__logIn(with: credentials.credentials!,
                            timeout: timeout,
                            callbackQueue: queue,
                            onCompletion: completion)
    }
}

@dynamicMemberLookup
public final class RealmFunctions: RLMFunctions {
    public typealias FunctionSignature<T: Decodable> = ([Any], T.Type, (@escaping (Result<T, Error>) -> Void)) -> Void

    public subscript<T>(dynamicMember name: String) -> FunctionSignature<T> {
        return { (arguments, type, completionHandler) in
            self.__callFunction(name, arguments: arguments, timeout: 30, callbackQueue: DispatchQueue.main) { data, error in
                guard let data = data else {
                    completionHandler(.failure(error ?? NSError()))
                    return
                }

                do {
                    completionHandler(.success(try JSONDecoder().decode(T.self, from: data)))
                } catch let error {
                    completionHandler(.failure(error))
                }
            }
        }
    }
}

public typealias RealmServices = RLMServices
public typealias RealmPush = RLMPush
public typealias RealmMongoDBService = RLMMongoDBService
public typealias RealmTwilioService = RLMTwilioService
