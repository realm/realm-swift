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

/**
`Credentials`is an enum representing supported authentication types for MongoDB Realm.
Example Usage:
```
let credentials = Credentials.JWT(token: myToken)
```
*/
@frozen public enum Credentials {
    /// Credentials from a Facebook access token.
    case facebook(accessToken: String)
    /// Credentials from a Google serverAuthCode.
    case google(serverAuthCode: String)
    /// Credentials from a Google idToken.
    case googleId(token: String)
    /// Credentials from an Apple id token.
    case apple(idToken: String)
    /// Credentials from an email and password.
    case emailPassword(email: String, password: String)
    /// Credentials from a JSON Web Token
    case jwt(token: String)
    /// Credentials for a MongoDB Realm function using a mongodb document as a json payload.
    /// If the json can not be successfully serialised and error will be produced and the object will be nil.
    case function(payload: Document)
    /// Credentials from a user api key.
    case userAPIKey(String)
    /// Credentials from a sever api key.
    case serverAPIKey(String)
    /// Represents anonymous credentials
    case anonymous
}

/// The `App` has the fundamental set of methods for communicating with a Realm
/// application backend.
/// This interface provides access to login and authentication.
public typealias App = RLMApp

public extension App {
    /**
     Login to a user for the Realm app.
     
     @param credentials The credentials identifying the user.
     @param completion A callback invoked after completion. Will return `Result.success(User)` or `Result.failure(Error)`.
     */
    func login(credentials: Credentials, _ completion: @escaping (Result<User, Error>) -> Void) {
        self.__login(withCredential: ObjectiveCSupport.convert(object: credentials)) { user, error in
            if let user = user {
                completion(.success(user))
            } else {
                completion(.failure(error ?? Realm.Error.callFailed))
            }
        }
    }
}

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

#if !(os(iOS) && (arch(i386) || arch(arm)))
import Combine

/// :nodoc:
@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, macCatalyst 13.0, macCatalystApplicationExtension 13.0, *)
@frozen public struct AppSubscription: Subscription {
    private let app: App
    private let token: RLMAppSubscriptionToken

    internal init(app: App, token: RLMAppSubscriptionToken) {
        self.app = app
        self.token = token
    }

    /// A unique identifier for identifying publisher streams.
    public var combineIdentifier: CombineIdentifier {
        return CombineIdentifier(NSNumber(value: token.value))
    }

    /// This function is not implemented.
    ///
    /// Realm publishers do not support backpressure and so this function does nothing.
    public func request(_ demand: Subscribers.Demand) {
    }

    /// Stop emitting values on this subscription.
    public func cancel() {
        app.unsubscribe(token)
    }
}

/// :nodoc:
@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, macCatalyst 13.0, macCatalystApplicationExtension 13.0, *)
public struct AppPublisher: Publisher {
    /// This publisher cannot fail.
    public typealias Failure = Never
    /// This publisher emits App.
    public typealias Output = App

    private let app: App
    private let callbackQueue: DispatchQueue

    internal init(_ app: App, callbackQueue: DispatchQueue = .main) {
        self.app = app
        self.callbackQueue = callbackQueue
    }

    /// :nodoc:
    public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Never, Output == S.Input {
        let token = app.subscribe { _ in
            self.callbackQueue.async {
                _ = subscriber.receive(self.app)
            }
        }

        subscriber.receive(subscription: AppSubscription(app: app, token: token))
    }

    /// :nodoc:
    public func receive<S: Scheduler>(on scheduler: S) -> Self {
        guard let queue = scheduler as? DispatchQueue else {
            fatalError("Cannot subscribe on scheduler \(scheduler): only serial dispatch queues are currently implemented.")
        }

        return Self(app, callbackQueue: queue)
    }
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, macCatalyst 13.0, macCatalystApplicationExtension 13.0, *)
extension App: ObservableObject {
    /// A publisher that emits Void each time the app changes.
    ///
    /// Despite the name, this actually emits *after* the app has changed.
    public var objectWillChange: AppPublisher {
        return AppPublisher(self)
    }
}

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
     Retries custom confirmation function for a given email address.

     @param email The email address of the user to retry custom confirmation logic.
     @returns A publisher that eventually return `Result.success` or `Error`.
     */
    func retryCustomConfirmation(email: String) -> Future<Void, Error> {
        return Future<Void, Error> { promise in
            self.retryCustomConfirmation(email) { error in
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
        return Future { self.createAPIKey(named: named, completion: $0) }
    }

    /**
     Fetches a user API key associated with the current user.
     @param objectId The ObjectId of the API key to fetch.
     @returns A publisher that eventually return `UserAPIKey` or `Error`.
     */
    func fetchAPIKey(_ objectId: ObjectId) -> Future<UserAPIKey, Error> {
        return Future { self.fetchAPIKey(objectId, $0) }
    }

    /**
     Fetches the user API keys associated with the current user.
     @returns A publisher that eventually return `[UserAPIKey]` or `Error`.
     */
    func fetchAPIKeys() -> Future<[UserAPIKey], Error> {
        return Future { self.fetchAPIKeys($0) }
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
        return Future { self.login(credentials: credentials, $0) }
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

public extension APIKeyAuth {
    /**
     Creates a user API key that can be used to authenticate as the current user.
     @param name The name of the API key to be created.
     @completion A completion that eventually return `Result.success(UserAPIKey)` or `Result.failure(Error)`.
     */
    func createAPIKey(named: String, completion: @escaping (Result<UserAPIKey, Error>) -> Void) {
        createAPIKey(named: named) { (userApiKey, error) in
            if let userApiKey = userApiKey {
                completion(.success(userApiKey))
            } else {
                completion(.failure(error ?? Realm.Error.callFailed))
            }
        }
    }

    /**
     Fetches a user API key associated with the current user.
     @param objectId The ObjectId of the API key to fetch.
     @completion A completion that eventually return `Result.success(UserAPIKey)` or `Result.failure(Error)`.
     */
    func fetchAPIKey(_ objectId: ObjectId, _ completion: @escaping (Result<UserAPIKey, Error>) -> Void) {
        fetchAPIKey(objectId) { (userApiKey, error) in
            if let userApiKey = userApiKey {
                completion(.success(userApiKey))
            } else {
                completion(.failure(error ?? Realm.Error.callFailed))
            }
        }
    }

    /**
     Fetches the user API keys associated with the current user.
     @completion A completion that eventually return `Result.success([UserAPIKey])` or `Result.failure(Error)`.
     */
    func fetchAPIKeys(_ completion: @escaping (Result<[UserAPIKey], Error>) -> Void) {
        fetchAPIKeys { (userApiKeys, error) in
            if let userApiKeys = userApiKeys {
                completion(.success(userApiKeys))
            } else {
                completion(.failure(error ?? Realm.Error.callFailed))
            }
        }
    }
}

#if swift(>=5.5) && canImport(_Concurrency)
@available(macOS 12.0, tvOS 15.0, iOS 15.0, watchOS 8.0, *)
extension App {
    /// Login to a user for the Realm app.
    /// @param credentials The credentials identifying the user.
    /// @returns A publisher that eventually return `User` or `Error`.
    public func login(credentials: Credentials) async throws -> User {
        return try await withCheckedThrowingContinuation { continuation in
            self.login(credentials: credentials, continuation.resume)
        }
    }
}
#endif
