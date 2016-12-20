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

public protocol ThreadConfined {
    // Must also conform to `AssistedObjectiveCBridgeable`
    var realm: Realm? { get }
#if swift(>=3.0)
    var isInvalidated: Bool { get }
#else
    var invalidated: Bool { get }
#endif
}

public class ThreadSafeReference<Confined: ThreadConfined> {
    private let swiftMetadata: Any?
    private let type: ThreadConfined.Type

#if swift(>=3.0)
    /**
     Indicates if the reference can no longer be resolved because an attempt to resolve it has
     already occurred. References can only be resolved once.
     */
    public var isInvalidated: Bool { return objectiveCReference.isInvalidated }

    private let objectiveCReference: RLMThreadSafeReference<RLMThreadConfined>
#else
    /**
     Indicates if the reference can no longer be resolved because an attempt to resolve it has
     already occurred. References can only be resolved once.
     */
    public var invalidated: Bool { return objectiveCReference.invalidated }

    private let objectiveCReference: RLMThreadSafeReference
#endif

    public init(to threadConfined: Confined) {
        // TODO: It might be necessary to check `invalidated` and `Realm` here. I'm not certain that bridging succeeds
        //       when these are false/nil.

        let bridged = (threadConfined as! AssistedObjectiveCBridgeable).bridged
        swiftMetadata = bridged.metadata
#if swift(>=3.0)
        type = type(of: threadConfined)
#else
        type = threadConfined.dynamicType
#endif
        objectiveCReference = RLMThreadSafeReference(threadConfined: bridged.objectiveCValue as! RLMThreadConfined)
    }

    internal func resolve(in realm: Realm) -> Confined? {
#if swift(>=3.0)
        guard let objectiveCValue = realm.rlmRealm.__resolve(objectiveCReference) else { return nil }
#else
        guard let objectiveCValue = realm.rlmRealm.__resolveThreadSafeReference(objectiveCReference) else { return nil }
#endif
        return ((Confined.self as! AssistedObjectiveCBridgeable.Type).bridging(from: objectiveCValue, with: swiftMetadata) as! Confined)
    }
}

extension Realm {
#if swift(>=3.0)
    public func resolve<Confined: ThreadConfined>(_ reference: ThreadSafeReference<Confined>) -> Confined? {
        return reference.resolve(in: self)
    }
#else
    public func resolve<Confined: ThreadConfined>(reference: ThreadSafeReference<Confined>) -> Confined? {
        return reference.resolve(in: self)
    }
#endif
}
