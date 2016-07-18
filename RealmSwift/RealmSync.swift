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

#if swift(>=3.0)

public extension Realm {
    func open(for user: RLMSyncUser, onCompletion completion: (NSError?, RLMSyncSession?) -> Void) {
        self.rlmRealm.open(for: user, onCompletion: completion)
    }

    func open(with token: String) {
        self.rlmRealm.open(withSyncToken: token)
    }
}

#else

public extension Realm {
    func open(for user: RLMSyncUser, onCompletion completion: (NSError?, RLMSyncSession?) -> Void) {
        self.rlmRealm.openForSyncUser(user, onCompletion: completion)
    }

    func open(with token: String) {
        self.rlmRealm.openWithSyncToken(token)
    }
}

#endif
