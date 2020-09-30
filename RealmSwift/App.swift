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

- see: `RLMAPIKeyAuth`
*/
public typealias APIKeyAuth = RLMAPIKeyAuth

/**
An object representing a client which performs network calls on
Realm Cloud user registration & password functions

- see: `RLMEmailPasswordAuth`
*/
public typealias EmailPasswordAuth = RLMEmailPasswordAuth

/// A block type used to report an error
public typealias EmailPasswordAuthOptionalErrorBlock = RLMEmailPasswordAuthOptionalErrorBlock
extension EmailPasswordAuth {

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
                                          _ completion: @escaping EmailPasswordAuthOptionalErrorBlock) {
        let bson = ObjectiveCSupport.convert(object: .array(args))
        self.__callResetPasswordFunction(email, password: password, args: bson as! [RLMBSON], completion: completion)
    }
}

/**
An object representing a client which performs network calls on
Realm Cloud for registering devices to push notifications
 
- see `RLMPushClient`
 */
public typealias PushClient = RLMPushClient

/// An object which is used within UserAPIKeyProviderClient
public typealias UserAPIKey = RLMUserAPIKey

// !!!: Remove
/// A `Credentials` represents data that uniquely identifies a Realm Object Server user.
//public typealias Credentials = RLMCredentials

// !!!: Add comments
public enum Credentials {

    case facebook(accessToken: String)
    case google(serverAuthCode: String)
    case apple(idToken: String)
    case emailPassword(email: String, password: String)
    case JWT(token: String)
    // !!!: Should be NSError??
    case function(payload: Dictionary<String, String>, error: NSErrorPointer)
    case userAPIKey(APIKey: String)
    case serverAPIKey(serverAPIKey: String)
    case anonymous
}

/// The `App` has the fundamental set of methods for communicating with a Realm
/// application backend.
/// This interface provides access to login and authentication.
public typealias App = RLMApp

/// Use this delegate to be provided a callback once authentication has succeed or failed
@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
public typealias ASLoginDelegate = RLMASLoginDelegate

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
extension App {
    /**
     Sets the ASAuthorizationControllerDelegate to be handled by `App`
     - Parameter controller: The ASAuthorizationController in which you want `App` to consume its delegate.

     Usage:
     ```
     let app = App(id: "my-app-id")
     let appleIDProvider = ASAuthorizationAppleIDProvider()
     let request = appleIDProvider.createRequest()
     request.requestedScopes = [.fullName, .email]

     let authorizationController = ASAuthorizationController(authorizationRequests: [request])
     app.setASAuthorizationControllerDelegate(controller: authorizationController)
     authorizationController.presentationContextProvider = self
     authorizationController.performRequests()
     ```
    */
    public func setASAuthorizationControllerDelegate(for controller: ASAuthorizationController) {
        self.__setASAuthorizationControllerDelegateFor(controller)
    }
}

#if canImport(Combine)
import Combine

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, macCatalyst 13.0, macCatalystApplicationExtension 13.0, *)
public extension EmailPasswordAuth {
    /**
     Registers a new email identity with the username/password provider,
     and sends a confirmation email to the provided address.

     @param email The email address of the user to register.
     @param password The password that the user created for the new username/password identity.
     @returns A publisher that eventually return `Result.success` or `Error`.
    */
    func registerUser(email: String, password: String) -> Future<Void, Error> {
        return Future<Void, Error> { promise in
            self.registerUser(email: email, password: password) { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
    }

    /**
     Confirms an email identity with the username/password provider.

     @param token The confirmation token that was emailed to the user.
     @param tokenId The confirmation token id that was emailed to the user.
     @returns A publisher that eventually return `Result.success` or `Error`.
    */
    func confirmUser(_ token: String, tokenId: String) -> Future<Void, Error> {
        return Future<Void, Error> { promise in
            self.confirmUser(token, tokenId: tokenId) { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
    }

    /**
     Re-sends a confirmation email to a user that has registered but
     not yet confirmed their email address.
     @param email The email address of the user to re-send a confirmation for.
     @returns A publisher that eventually return `Result.success` or `Error`.
    */
    func resendConfirmationEmail(email: String) -> Future<Void, Error> {
        return Future<Void, Error> { promise in
            self.resendConfirmationEmail(email) { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
    }

    /**
     Sends a password reset email to the given email address.
     @param email The email address of the user to send a password reset email for.
     @returns A publisher that eventually return `Result.success` or `Error`.
    */
    func sendResetPasswordEmail(email: String) -> Future<Void, Error> {
        return Future<Void, Error> { promise in
            self.sendResetPasswordEmail(email) { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
    }

    /**
     Resets the password of an email identity using the
     password reset token emailed to a user.

     @param password The new password.
     @param token The password reset token that was emailed to the user.
     @param tokenId The password reset token id that was emailed to the user.
     @returns A publisher that eventually return `Result.success` or `Error`.
    */
    func resetPassword(to: String, token: String, tokenId: String) -> Future<Void, Error> {
        return Future<Void, Error> { promise in
            self.resetPassword(to: to, token: token, tokenId: tokenId) { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
    }

    /**
     Resets the password of an email identity using the
     password reset function set up in the application.

     @param email  The email address of the user.
     @param password The desired new password.
     @param args A list of arguments passed in as a BSON array.
     @returns A publisher that eventually return `Result.success` or `Error`.
    */
    func callResetPasswordFunction(email: String, password: String, args: [AnyBSON]) -> Future<Void, Error> {
        return Future<Void, Error> { promise in
            self.callResetPasswordFunction(email: email, password: password, args: args) { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
    }
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, macCatalyst 13.0, macCatalystApplicationExtension 13.0, *)
public extension APIKeyAuth {
    /**
     Creates a user API key that can be used to authenticate as the current user.
     @param name The name of the API key to be created.
     @returns A publisher that eventually return `UserAPIKey` or `Error`.
     */
    func createAPIKey(named: String) -> Future<UserAPIKey, Error> {
        return Future { promise in
            self.createAPIKey(named: named) { (userApiKey, error) in
                if let userApiKey = userApiKey {
                    promise(.success(userApiKey))
                } else {
                    promise(.failure(error ?? Realm.Error.promiseFailed))
                }
            }
        }
    }

    /**
     Fetches a user API key associated with the current user.
     @param objectId The ObjectId of the API key to fetch.
     @returns A publisher that eventually return `UserAPIKey` or `Error`.
     */
    func fetchAPIKey(_ objectId: ObjectId) -> Future<UserAPIKey, Error> {
        return Future { promise in
            self.fetchAPIKey(objectId) { (userApiKey, error) in
                if let userApiKey = userApiKey {
                    promise(.success(userApiKey))
                } else {
                    promise(.failure(error ?? Realm.Error.promiseFailed))
                }
            }
        }
    }

    /**
     Fetches the user API keys associated with the current user.
     @returns A publisher that eventually return `[UserAPIKey]` or `Error`.
     */
    func fetchAPIKeys() -> Future<[UserAPIKey], Error> {
        return Future { promise in
            self.fetchAPIKeys { (userApiKeys, error) in
                if let userApiKeys = userApiKeys {
                    promise(.success(userApiKeys))
                } else {
                    promise(.failure(error ?? Realm.Error.promiseFailed))
                }
            }
        }
    }

    /**
     Deletes a user API key associated with the current user.
     @param objectId The ObjectId of the API key to delete.
     @returns A publisher that eventually return `Result.success` or `Error`.
     */
    func deleteAPIKey(_ objectId: ObjectId) -> Future<Void, Error> {
        return Future { promise in
            self.deleteAPIKey(objectId) { (error) in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(Void()))
                }
            }
        }
    }

    /**
     Enables a user API key associated with the current user.
     @param objectId The ObjectId of the  API key to enable.
     @returns A publisher that eventually return `Result.success` or `Error`.
     */
    func enableAPIKey(_ objectId: ObjectId) -> Future<Void, Error> {
        return Future { promise in
            self.enableAPIKey(objectId) { (error) in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(Void()))
                }
            }
        }
    }

    /**
     Disables a user API key associated with the current user.
     @param objectId The ObjectId of the API key to disable.
     @returns A publisher that eventually return `Result.success` or `Error`.
     */
    func disableAPIKey(_ objectId: ObjectId) -> Future<Void, Error> {
        return Future { promise in
            self.disableAPIKey(objectId) { (error) in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(Void()))
                }
            }
        }
    }
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, macCatalyst 13.0, macCatalystApplicationExtension 13.0, *)
public extension App {
    /// Login to a user for the Realm app.
    /// @param credentials The credentials identifying the user.
    /// @returns A publisher that eventually return `User` or `Error`.
    func login(credentials: Credentials) -> Future<User, Error> {
        return Future { promise in
//            self.login(credentials: credentials) { user, error in
            self.login(credentials: ObjectiveCSupport.convert(object: credentials)) { user, error in
                if let user = user {
                promise(.success(user))
                } else {
                    promise(.failure(error ?? Realm.Error.promiseFailed))
                }
            }
        }
    }
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, macCatalyst 13.0, macCatalystApplicationExtension 13.0, *)
public extension PushClient {
    /// Request to register device token to the server
    /// @param token device token
    /// @param user - device's user
    /// @returns A publisher that eventually return `Result.success` or `Error`.
    func registerDevice(token: String, user: User) -> Future<Void, Error> {
        return Future { promise in
            self.registerDevice(token: token, user: user) { (error) in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(Void()))
                }
            }
        }
    }

    /// Request to deregister a device for a user
    /// @param user - devoce's user
    /// @returns A publisher that eventually return `Result.success` or `Error`.
    func deregisterDevice(user: User) -> Future<Void, Error> {
        return Future { promise in
            self.deregisterDevice(user: user) { (error) in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(Void()))
                }
            }
        }
    }
}
#endif // canImport(Combine)
