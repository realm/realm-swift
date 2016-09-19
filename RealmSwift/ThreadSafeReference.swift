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

#if swift(>=3.0)
    public protocol ThreadConfined {
        // Must also conform to `AssistedObjectiveCBridgeable`
        var realm: Realm? { get }
        var isInvalidated: Bool { get }
    }

    public class ThreadSafeReference<Confined: ThreadConfined> {
        private let swiftMetadata: Any?
        private let type: ThreadConfined.Type
        private let objectiveCReference: RLMThreadSafeReference<RLMThreadConfined>

        public init(to threadConfined: Confined) {
            // TODO: It might be necessary to check `isInvalidated` and `Realm` here. I'm not certain that bridgeing succeeds
            //       when these are false/nil.

            self.swiftMetadata = (threadConfined as! AssistedObjectiveCBridgeable).bridged.metadata
            self.type = type(of: threadConfined)
            self.objectiveCReference = RLMThreadSafeReference(threadConfined:
                (threadConfined as! AssistedObjectiveCBridgeable).bridged.objectiveCValue as! RLMThreadConfined)
        }

        fileprivate func resolve(in realm: Realm) -> Confined? {
            guard let objectiveCValue = realm.rlmRealm.__resolve(objectiveCReference) else { return nil }
            return ((Confined.self as! AssistedObjectiveCBridgeable.Type).bridging(from: objectiveCValue, with: swiftMetadata) as! Confined)
        }
    }

    extension Realm {
        public func resolve<Confined: ThreadConfined>(_ reference: ThreadSafeReference<Confined>) -> Confined? {
            return reference.resolve(in: self)
        }
    }
#else
    // TODO
#endif
