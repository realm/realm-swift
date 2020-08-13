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

/// A `Credentials` represents data that uniquely identifies a Realm Object Server user.
public typealias Credentials = RLMCredentials

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
