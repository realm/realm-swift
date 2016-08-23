////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
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

import Realm
import Realm.Private
import Foundation

public typealias User = RLMUser

public typealias SyncManager = RLMSyncManager

public typealias SyncSession = RLMSyncSession

public typealias Provider = RLMIdentityProvider

public typealias AuthenticationActions = RLMAuthenticationActions

public typealias ErrorReportingBlock = RLMErrorReportingBlock

public typealias UserCompletionBlock = RLMUserCompletionBlock

public typealias SyncError = RLMSyncError

#if swift(>=3.0)

public enum Credential {
    case facebook(token: String)
    case usernamePassword(username: String, password: String)
    case custom(token: String, provider: Provider, userInfo: [String : Any]?)

    fileprivate func asRLMCredential() -> RLMCredential {
        switch self {
        case let .facebook(token):
            return RLMCredential(facebookToken: token)
        case let .usernamePassword(username, password):
            return RLMCredential(username: username, password: password)
        case let .custom(token, provider, userInfo):
            return RLMCredential(customToken: token, provider: provider, userInfo: userInfo)
        }
    }
}

extension User {

    public static func authenticate(with credential: Credential,
                                    actions: AuthenticationActions,
                                    server authServerURL: URL,
                                    timeout: TimeInterval = 30,
                                    onCompletion completion: UserCompletionBlock) {
        return User.__authenticate(with: credential.asRLMCredential(),
                                   actions: actions,
                                   authServerURL: authServerURL,
                                   timeout: timeout,
                                   onCompletion: completion)
    }
}

#else

public enum Credential {
    case Facebook(token: String)
    case UsernamePassword(username: String, password: String)
    case Custom(token: String, provider: String, userInfo: [String : AnyObject]?)

    private func asRLMCredential() -> RLMCredential {
        switch self {
        case let .Facebook(token):
            return RLMCredential(facebookToken: token)
        case let .UsernamePassword(username, password):
            return RLMCredential(username: username, password: password)
        case let .Custom(token, provider, userInfo):
            return RLMCredential(customToken: token, provider: provider, userInfo: userInfo)
        }
    }
}

extension User {

    public static func authenticateWithCredential(credential: Credential,
                                                  actions: AuthenticationActions,
                                                  authServerURL: NSURL,
                                                  timeout: NSTimeInterval = 30,
                                                  onCompletion completion: UserCompletionBlock) {
        return User.__authenticateWithCredential(credential.asRLMCredential(),
                                                 actions: actions,
                                                 authServerURL: authServerURL,
                                                 timeout: timeout,
                                                 onCompletion: completion)
    }
}

#endif
