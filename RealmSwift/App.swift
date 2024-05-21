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

import AuthenticationServices
import Combine
import Foundation
import Realm
import Realm.Private

/**
An object representing the Realm App configuration

- see: `RLMAppConfiguration`

- note: `AppConfiguration` options cannot be modified once the `App` using it
         is created. App's configuration values are cached when the App is created so any modifications after it
         will not have any effect.
*/
public typealias AppConfiguration = RLMAppConfiguration
public extension AppConfiguration {
    /// :nodoc:
    @available(*, deprecated, message: "localAppName and localAppVersion are not used for anything and should not be supplied")
    convenience init(baseURL: String? = nil, transport: RLMNetworkTransport? = nil,
                     localAppName: String?, localAppVersion: String?,
                     defaultRequestTimeoutMS: UInt? = nil, enableSessionMultiplexing: Bool? = nil,
                     syncTimeouts: SyncTimeoutOptions? = nil) {
        self.init(baseURL: baseURL, transport: transport, localAppName: localAppName, localAppVersion: localAppVersion)
        if let defaultRequestTimeoutMS {
            self.defaultRequestTimeoutMS = defaultRequestTimeoutMS
        }
        if let enableSessionMultiplexing {
            self.enableSessionMultiplexing = enableSessionMultiplexing
        }
        if let syncTimeouts {
            self.syncTimeouts = syncTimeouts
        }
    }

    /**
     Memberwise convenience initializer

     All fields have sensible defaults if not set and typically do not need to be customized.

     - Parameters:
       - baseURL: A custom Atlas App Services URL for when using a non-standard deployment
       - transport: A network transport used for calls to the server.
       - defaultRequestTimeoutMS: The default timeout for non-sync HTTP requests made to the server.
       - enableSessionMultiplexing: Use a single network connection per sync user rather than one per sync Realm.
       - syncTimeouts: Timeout options for sync connections.
     */
    @_disfavoredOverload // this is ambiguous with the base init if nil is explicitly passed
    convenience init(baseURL: String? = nil, transport: RLMNetworkTransport? = nil,
                     defaultRequestTimeoutMS: UInt? = nil, enableSessionMultiplexing: Bool? = nil,
                     syncTimeouts: SyncTimeoutOptions? = nil) {
        self.init(baseURL: baseURL, transport: transport)
        if let defaultRequestTimeoutMS {
            self.defaultRequestTimeoutMS = defaultRequestTimeoutMS
        }
        if let enableSessionMultiplexing {
            self.enableSessionMultiplexing = enableSessionMultiplexing
        }
        if let syncTimeouts {
            self.syncTimeouts = syncTimeouts
        }
    }
}

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

/**
 An object representing the social profile of a User.
 */
public typealias UserProfile = RLMUserProfile

extension UserProfile {
    /**
     The metadata of the user.
     The auth provider of the user is responsible for populating this `Document`.
    */
    public var metadata: Document {
        guard let rlmMetadata = self.__metadata as RLMBSON?,
            let anyBSON = ObjectiveCSupport.convert(object: rlmMetadata),
            case let .document(metadata) = anyBSON else {
            return [:]
        }

        return metadata
    }
}

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
        __callResetPasswordFunction(email, password: password, args: bson as! [RLMBSON], completion: completion)
    }

    /**
     Resets the password of an email identity using the
     password reset function set up in the application.

     @param email  The email address of the user.
     @param password The desired new password.
     @param args A list of arguments passed in as a BSON array.
     @returns A publisher that eventually return `Result.success` or `Error`.
    */
    @available(macOS 10.15, watchOS 6.0, iOS 13.0, tvOS 13.0, *)
    public func callResetPasswordFunction(email: String, password: String, args: [AnyBSON]) -> Future<Void, Error> {
        promisify {
            self.callResetPasswordFunction(email: email, password: password, args: args, $0)
        }
    }

    /// Resets the password of an email identity using the
    /// password reset function set up in the application.
    /// - Parameters:
    ///   - email: The email address of the user.
    ///   - password: The desired new password.
    ///   - args: A list of arguments passed in as a BSON array.
    @available(macOS 10.15, watchOS 6.0, iOS 13.0, tvOS 13.0, *)
    public func callResetPasswordFunction(email: String,
                                          password: String,
                                          args: [AnyBSON]) async throws {
        let bson = ObjectiveCSupport.convert(object: .array(args))
        return try await __callResetPasswordFunction(email, password: password, args: bson as! [RLMBSON])
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
extension UserAPIKey {
    /// The ObjectId of the API key.
    public var objectId: ObjectId {
        __objectId as! ObjectId
    }
}

/**
`Credentials`is an enum representing supported authentication types for Atlas App Services.
Example Usage:
```
let credentials = Credentials.JWT(token: myToken)
```
*/
@frozen public enum Credentials: Sendable {
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
    /// Credentials for an Atlas App Services function using a mongodb document as a json payload.
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
    Updates the base url used by Atlas device sync, in case the need to roam between servers (cloud and/or edge server).
     - parameter url: The new base url to connect to. Setting `nil` will reset the base url to the default url.
     - parameter completion: A callback invoked after completion.
     - note: Updating the base URL will trigger a client reset.
     */
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @_spi(RealmSwiftExperimental) func updateBaseUrl(to url: String?, _ completion: @Sendable @escaping (Error?) -> Void) {
        self.__updateBaseURL(url, completion: completion)
    }

    /**
    Updates the base url used by Atlas device sync, in case the need to roam between servers (cloud and/or edge server).
     - parameter url: The new base url to connect to. Setting `nil` will reset the base url to the default url.
     - parameter completion: A callback invoked after completion.
     - note: Updating the base URL will trigger a client reset.
     - returns A publisher that eventually return `Result.success` or `Error`.
     */
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @_spi(RealmSwiftExperimental) func updateBaseUrl(to url: String?) -> Future<Void, Error> {
        promisify {
            self.__updateBaseURL(url, completion: $0)
        }
    }

    /**
     Login to a user for the Realm app.
     
     - parameter credentials: The credentials identifying the user.
     - parameter completion: A callback invoked after completion. Will return `Result.success(User)` or `Result.failure(Error)`.
     */
    @preconcurrency
    func login(credentials: Credentials, _ completion: @Sendable @escaping (Result<User, Error>) -> Void) {
        self.__login(withCredential: ObjectiveCSupport.convert(object: credentials)) { user, error in
            if let user = user {
                completion(.success(user))
            } else {
                completion(.failure(error ?? Realm.Error.callFailed))
            }
        }
    }

    /**
    Updates the base url used by Atlas device sync, in case the need to roam between servers (cloud and/or edge server).
     - parameter url: The new base url to connect to. Setting `nil` will reset the base url to the default url.
     - parameter completion: A callback invoked after completion. Will return `Result.success` or `Result.failure(Error)`.
     - note: Updating the base URL will trigger a client reset.
     */
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @_spi(RealmSwiftExperimental) func updateBaseUrl(to url: String?, _ completion: @Sendable @escaping (Result<Void, Error>) -> Void) {
        self.__updateBaseURL(url, completion: { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        })
    }

    /**
    Login to a user for the Realm app.
    - parameter credentials: The credentials identifying the user.
    - returns: A publisher that eventually return `User` or `Error`.
     */
    @available(macOS 10.15, watchOS 6.0, iOS 13.0, tvOS 13.0, *)
    func login(credentials: Credentials) -> Future<User, Error> {
        return future { self.login(credentials: credentials, $0) }
    }

    /**
    Login to a user for the Realm app.
     - parameter credentials: The credentials identifying the user.
     */
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func login(credentials: Credentials) async throws -> User {
        try await __login(withCredential: ObjectiveCSupport.convert(object: credentials))
    }

    /**
    Updates the base url used by Atlas device sync, in case the need to roam between servers (cloud and/or edge server).
     - parameter url: The new base url to connect to. Setting `nil` will reset the base url to the default url.
     - note: Updating the base URL will trigger a client reset.
     */
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @_spi(RealmSwiftExperimental) func updateBaseUrl(to url: String?) async throws {
        try await __updateBaseURL(url)
    }
}

/// Use this delegate to be provided a callback once authentication has succeed or failed
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public typealias ASLoginDelegate = RLMASLoginDelegate

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
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

/// :nodoc:
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@frozen public struct AppSubscription: Subscription {
    private let token: RLMAppSubscriptionToken
    internal init(token: RLMAppSubscriptionToken) {
        self.token = token
    }

    /// A unique identifier for identifying publisher streams.
    public var combineIdentifier: CombineIdentifier {
        return CombineIdentifier(token)
    }

    /// This function is not implemented.
    ///
    /// Realm publishers do not support backpressure and so this function does nothing.
    public func request(_ demand: Subscribers.Demand) {
    }

    /// Stop emitting values on this subscription.
    public func cancel() {
        token.unsubscribe()
    }
}

/// :nodoc:
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public struct AppPublisher: Publisher, @unchecked Sendable { // DispatchQueue
    /// This publisher cannot fail.
    public typealias Failure = Never
    /// This publisher emits App.
    public typealias Output = App

    private let app: App

    private let scheduler: any Scheduler

    internal init<S: Scheduler>(_ app: App, scheduler: S) {
        self.app = app
        self.scheduler = scheduler
    }

    /// :nodoc:
    public func receive<S: Sendable>(subscriber: S) where S: Subscriber, S.Failure == Never, Output == S.Input {
        let token = app.subscribe { app in
            self.scheduler.schedule {
                _ = subscriber.receive(app)
            }
        }

        subscriber.receive(subscription: AppSubscription(token: token))
    }

    /// :nodoc:
    public func receive<S: Scheduler>(on scheduler: S) -> Self {
        return Self(app, scheduler: scheduler)
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension App: ObservableObject {
    /// A publisher that emits Void each time the app changes.
    ///
    /// Despite the name, this actually emits *after* the app has changed.
    public var objectWillChange: AppPublisher {
        return AppPublisher(self, scheduler: DispatchQueue.main)
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
internal func promisify(_ fn: @escaping (@escaping @Sendable (Error?) -> Void) -> Void) -> Future<Void, Error> {
    return future { promise in
        fn { error in
            if let error = error {
                promise(.failure(error))
            } else {
                promise(.success(()))
            }
        }
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension EmailPasswordAuth {
    /**
     Registers a new email identity with the username/password provider,
     and sends a confirmation email to the provided address.

     @param email The email address of the user to register.
     @param password The password that the user created for the new username/password identity.
     @returns A publisher that eventually return `Result.success` or `Error`.
    */
    func registerUser(email: String, password: String) -> Future<Void, Error> {
        promisify {
            self.registerUser(email: email, password: password, completion: $0)
        }
    }

    /**
     Confirms an email identity with the username/password provider.

     @param token The confirmation token that was emailed to the user.
     @param tokenId The confirmation token id that was emailed to the user.
     @returns A publisher that eventually return `Result.success` or `Error`.
    */
    func confirmUser(_ token: String, tokenId: String) -> Future<Void, Error> {
        promisify {
            self.confirmUser(token, tokenId: tokenId, completion: $0)
        }
    }

    /**
     Re-sends a confirmation email to a user that has registered but
     not yet confirmed their email address.
     @param email The email address of the user to re-send a confirmation for.
     @returns A publisher that eventually return `Result.success` or `Error`.
    */
    func resendConfirmationEmail(email: String) -> Future<Void, Error> {
        promisify {
            self.resendConfirmationEmail(email, completion: $0)
        }
    }

    /**
     Retries custom confirmation function for a given email address.

     @param email The email address of the user to retry custom confirmation logic.
     @returns A publisher that eventually return `Result.success` or `Error`.
     */
    func retryCustomConfirmation(email: String) -> Future<Void, Error> {
        promisify {
            self.retryCustomConfirmation(email, completion: $0)
        }
    }

    /**
     Sends a password reset email to the given email address.
     @param email The email address of the user to send a password reset email for.
     @returns A publisher that eventually return `Result.success` or `Error`.
    */
    func sendResetPasswordEmail(email: String) -> Future<Void, Error> {
        promisify {
            self.sendResetPasswordEmail(email, completion: $0)
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
        promisify {
            self.resetPassword(to: to, token: token, tokenId: tokenId, completion: $0)
        }
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension APIKeyAuth {
    /**
     Creates a user API key that can be used to authenticate as the current user.
     @param name The name of the API key to be created.
     @returns A publisher that eventually return `UserAPIKey` or `Error`.
     */
    func createAPIKey(named: String) -> Future<UserAPIKey, Error> {
        return future { self.createAPIKey(named: named, completion: $0) }
    }

    /**
     Fetches a user API key associated with the current user.
     @param objectId The ObjectId of the API key to fetch.
     @returns A publisher that eventually return `UserAPIKey` or `Error`.
     */
    func fetchAPIKey(_ objectId: ObjectId) -> Future<UserAPIKey, Error> {
        return future { self.fetchAPIKey(objectId, $0) }
    }

    /**
     Fetches the user API keys associated with the current user.
     @returns A publisher that eventually return `[UserAPIKey]` or `Error`.
     */
    func fetchAPIKeys() -> Future<[UserAPIKey], Error> {
        return future { self.fetchAPIKeys($0) }
    }

    /**
     Deletes a user API key associated with the current user.
     @param objectId The ObjectId of the API key to delete.
     @returns A publisher that eventually return `Result.success` or `Error`.
     */
    func deleteAPIKey(_ objectId: ObjectId) -> Future<Void, Error> {
        promisify {
            self.deleteAPIKey(objectId, completion: $0)
        }
    }

    /**
     Enables a user API key associated with the current user.
     @param objectId The ObjectId of the  API key to enable.
     @returns A publisher that eventually return `Result.success` or `Error`.
     */
    func enableAPIKey(_ objectId: ObjectId) -> Future<Void, Error> {
        promisify {
            self.enableAPIKey(objectId, completion: $0)
        }
    }

    /**
     Disables a user API key associated with the current user.
     @param objectId The ObjectId of the API key to disable.
     @returns A publisher that eventually return `Result.success` or `Error`.
     */
    func disableAPIKey(_ objectId: ObjectId) -> Future<Void, Error> {
        promisify {
            self.disableAPIKey(objectId, completion: $0)
        }
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension PushClient {
    /// Request to register device token to the server
    /// @param token device token
    /// @param user - device's user
    /// @returns A publisher that eventually return `Result.success` or `Error`.
    func registerDevice(token: String, user: User) -> Future<Void, Error> {
        promisify {
            self.registerDevice(token: token, user: user, completion: $0)
        }
    }

    /// Request to deregister a device for a user
    /// @param user - devoce's user
    /// @returns A publisher that eventually return `Result.success` or `Error`.
    func deregisterDevice(user: User) -> Future<Void, Error> {
        promisify {
            self.deregisterDevice(user: user, completion: $0)
        }
    }
}

public extension APIKeyAuth {
    /**
     Creates a user API key that can be used to authenticate as the current user.
     @param name The name of the API key to be created.
     @completion A completion that eventually return `Result.success(UserAPIKey)` or `Result.failure(Error)`.
     */
    @preconcurrency
    func createAPIKey(named: String, completion: @escaping @Sendable (Result<UserAPIKey, Error>) -> Void) {
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
    @preconcurrency
    func fetchAPIKey(_ objectId: ObjectId, _ completion: @escaping @Sendable (Result<UserAPIKey, Error>) -> Void) {
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
    @preconcurrency
    func fetchAPIKeys(_ completion: @escaping @Sendable (Result<[UserAPIKey], Error>) -> Void) {
        fetchAPIKeys { (userApiKeys, error) in
            if let userApiKeys = userApiKeys {
                completion(.success(userApiKeys))
            } else {
                completion(.failure(error ?? Realm.Error.callFailed))
            }
        }
    }
}
