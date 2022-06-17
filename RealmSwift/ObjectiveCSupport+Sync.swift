////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
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

/**
 :nodoc:
 **/
public extension ObjectiveCSupport {
    /// Convert a `SyncConfiguration` to a `RLMSyncConfiguration`.
    static func convert(object: SyncConfiguration) -> RLMSyncConfiguration {
        return object.config
    }

    /// Convert a `RLMSyncConfiguration` to a `SyncConfiguration`.
    static func convert(object: RLMSyncConfiguration) -> SyncConfiguration {
        return SyncConfiguration(config: object)
    }

    /// Convert a `Credentials` to a `RLMCredentials`
    static func convert(object: Credentials) -> RLMCredentials {
        switch object {
        case .facebook(let accessToken):
            return RLMCredentials(facebookToken: accessToken)
        case .google(let serverAuthCode):
            return RLMCredentials(googleAuthCode: serverAuthCode)
        case .googleId(let token):
            return RLMCredentials(googleIdToken: token)
        case .apple(let idToken):
            return RLMCredentials(appleToken: idToken)
        case .emailPassword(let email, let password):
            return RLMCredentials(email: email, password: password)
        case .jwt(let token):
            return RLMCredentials(jwt: token)
        case .function(let payload):
            return RLMCredentials(functionPayload: ObjectiveCSupport.convert(object: AnyBSON(payload)) as! [String: RLMBSON])
        case .userAPIKey(let APIKey):
            return RLMCredentials(userAPIKey: APIKey)
        case .serverAPIKey(let serverAPIKey):
            return RLMCredentials(serverAPIKey: serverAPIKey)
        case .anonymous:
            return RLMCredentials.anonymous()
        }
    }
}
