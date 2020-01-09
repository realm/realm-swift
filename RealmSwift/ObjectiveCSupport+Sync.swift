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
    /// Convert a `SyncCredentials` to a `RLMSyncCredentials`.
    static func convert(object: SyncCredentials) -> RLMSyncCredentials {
        return RLMSyncCredentials(object)
    }

    /// Convert a `RLMSyncCredentials` to a `SyncCredentials`.
    static func convert(object: RLMSyncCredentials) -> SyncCredentials {
        return SyncCredentials(object)
    }

    /// Convert a `SyncConfiguration` to a `RLMSyncConfiguration`.
    static func convert(object: SyncConfiguration) -> RLMSyncConfiguration {
        return object.asConfig()
    }

    /// Convert a `RLMSyncConfiguration` to a `SyncConfiguration`.
    static func convert(object: RLMSyncConfiguration) -> SyncConfiguration {
        return SyncConfiguration(config: object)
    }

    /// Convert a `RLMSyncSubscription` to a `SyncSubscription`.
    static func convert(object: RLMSyncSubscription) -> SyncSubscription {
        return SyncSubscription(object)
    }
}
