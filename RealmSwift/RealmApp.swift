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

/**
An object representing a client which performs network calls on
Realm Cloud user api keys

- see: `RLMUserAPIKeyProviderClient`
*/
public typealias UserAPIKeyProviderClient = RLMUserAPIKeyProviderClient

/**
An object representing a client which performs network calls on
Realm Cloud user registration & password functions

- see: `RLMUsernamePasswordProviderClient`
*/
public typealias UsernamePasswordProviderClient = RLMUsernamePasswordProviderClient
/// A block type used to report an error
public typealias UsernamePasswordProviderClientErrorBlock = RLMUsernamePasswordProviderClientOptionalErrorBlock
extension UsernamePasswordProviderClient {

    /// Resets the password of an email identity using the
    /// password reset function set up in the application.
    /// - Parameters:
    ///   - email: The email address of the user.
    ///   - password: The desired new password.
    ///   - args: A list of arguments passed in as a BSON array.
    ///   - completion: A callback to be invoked once the call is complete.
    public func callResetPasswordFunction(email: String,
                                          password: String,
                                          args: [AnyBSON],
                                          _ completion: @escaping UsernamePasswordProviderClientErrorBlock) {
        let bson = ObjectiveCSupport.convert(object: .array(args))
        self.__callResetPasswordFunction(email, password: password, args: bson as! [RLMBSON], completion: completion)
    }
}

/**
An object which is used within UserAPIKeyProviderClient

- see: `RLMUserAPIKey`
*/
public typealias UserAPIKey = RLMUserAPIKey

/**
A `AppCredentials` represents data that uniquely identifies a Realm Object Server user.
*/
public typealias AppCredentials = RLMAppCredentials

/// Structure providing an interface to call a MongoDB Realm function with the provided name and arguments.
///
///     let app = RealmApp(appId: "my-app-id")
///     app.functions.sum([1, 2, 3, 4, 5]) { sum, error in
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
public struct Functions {
    weak var app: RealmApp?

    fileprivate init(app: RealmApp) {
        self.app = app
    }

    /// A closure type for receiving the completion of a remote function call.
    public typealias FunctionCompletionHandler = (AnyBSON?, Error?) -> Void

    /// A closure type for the dynamic remote function type.
    public typealias Function = ([AnyBSON], @escaping FunctionCompletionHandler) -> Void

    /// The implementation of @dynamicMemberLookup that allows for dynamic remote function calls.
    public subscript(dynamicMember string: String) -> Function {
        return { (arguments: [AnyBSON], completionHandler: @escaping FunctionCompletionHandler) in
            let objcArgs = arguments.map(ObjectiveCSupport.convert) as! [RLMBSON]
            self.app?.__callFunctionNamed(string, arguments: objcArgs) { (bson: RLMBSON?, error: Error?) in
                completionHandler(ObjectiveCSupport.convert(object: bson), error)
            }
        }
    }
}

/// The `RealmApp` has the fundamental set of methods for communicating with a Realm
/// application backend.
/// This interface provides access to login and authentication.
public typealias RealmApp = RLMApp
public extension RealmApp {

    /// Call a MongoDB Realm function with the provided name and arguments.
    ///
    ///     let app = RealmApp(appId: "my-app-id")
    ///     app.functions.sum([1, 2, 3, 4, 5]) { sum, error in
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
        return Functions(app: self)
    }

    /// A client for interacting with a remote MongoDB instance
    /// - Parameter serviceName:  The name of the MongoDB service
    /// - Returns: A `MongoClient` which is used for interacting with a remote MongoDB service
    func mongoClient(_ serviceName: String) -> MongoClient {
        return self.__mongoClient(withServiceName: serviceName)
    }
}
