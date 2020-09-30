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
        return object.asConfig()
    }

    /// Convert a `RLMSyncConfiguration` to a `SyncConfiguration`.
    static func convert(object: RLMSyncConfiguration) -> SyncConfiguration {
        return SyncConfiguration(config: object)
    }
    
    // !!!: shorten case params
    // !!!: Change objc api
    /// Convert a `Credentials` to a `RLMCredentials`
    static func convert(object: Credentials) -> RLMCredentials {
        switch object {
        case .facebook(let accessToken):
            return RLMCredentials(facebookToken: accessToken)
        case .google(let serverAuthCode):
            return RLMCredentials(googleToken: serverAuthCode)
        case .apple(let idToken):
            return RLMCredentials(appleToken: idToken)
        case .emailPassword(let email,let password):
            return RLMCredentials(email: email, password: password)
            // !!!: rename param
        case .JWT(let token):
            return RLMCredentials(jwt: token)
        case .function(payload: let payload, let error):
            return RLMCredentials(functionPayload: payload, error: error)
        case .userAPIKey(APIKey: let APIKey):
            return RLMCredentials(userAPIKey: APIKey)
        case .serverAPIKey(serverAPIKey: let serverAPIKey):
            return RLMCredentials(serverAPIKey: serverAPIKey)
        case .anonymous:
            return RLMCredentials.anonymous()
        }
    }
}
