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

public typealias Provider = RLMIdentityProvider

public typealias ErrorReportingBlock = RLMErrorReportingBlock

#if swift(>=3.0)

public func configureRealmServer(with appID: String,
                          logLevel: UInt,
                          globalErrorHandler: ErrorReportingBlock?) {
    RLMServer.setup(withAppID: appID, logLevel: logLevel, errorHandler: globalErrorHandler)
}

public extension Realm.Configuration {

    mutating func set(errorHandler handler: ErrorReportingBlock?) {
        serverErrorHandler = handler
    }

    mutating func set(objectServerPath path: String?, for user: User, uponConnection callback: ErrorReportingBlock? = nil) {
        serverPath = path
        serverUser = user
        serverBindCallback = callback
    }
}

public extension Realm {
    // TODO: add APIs here as they are implemented.
}


#else

public func configureRealmServerWithAppID(appID: String,
                                   logLevel: UInt,
                                   globalErrorHandler: ErrorReportingBlock?) {
    RLMServer.setupWithAppID(appID, logLevel: logLevel, errorHandler: globalErrorHandler)
}

public extension Realm.Configuration {

    mutating func setErrorHandler(handler: ErrorReportingBlock?) {
        serverErrorHandler = handler
    }

    mutating func setObjectServerPath(path: String?,
                             for user: User,
                             uponConnection callback: ErrorReportingBlock? = nil) {
        serverPath = path
        serverUser = user
        serverBindCallback = callback
    }
}

public extension Realm {
    // TODO: add APIs here as they are implemented.
}

#endif
