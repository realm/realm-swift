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
