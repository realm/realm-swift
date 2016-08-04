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

public typealias Credential = RLMCredential

public typealias User = RLMUser

public typealias SessionInfo = RLMSessionInfo

public typealias Provider = RLMSyncIdentityProvider

public typealias ErrorReportingBlock = ((NSError?) -> Void)

#if swift(>=3.0)

    // TODO: implement Swift 3 API once we enter GM.

#else

public struct Sync {

    static func setupWithAppID(appID: String,
                               logLevel: UInt,
                               globalErrorHandler: ErrorReportingBlock) {
        RLMSync.setupWithAppID(appID, logLevel: logLevel, errorHandler: globalErrorHandler)
    }

    private init() { }
}

public extension Realm.Configuration {

    func setErrorHandler(handler: ErrorReportingBlock?) {
        rlmConfiguration.setErrorHandler(handler)
    }

    func setSyncPath(path: String?, for user: User) {
        rlmConfiguration.setSyncPath(path, forSyncUser: user)
    }

    var syncServerURL : NSURL? {
        return rlmConfiguration.syncServerURL
    }
}

public extension Realm {
    // TODO: add APIs here as they are implemented.

}

#endif
