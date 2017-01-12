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

/**
 Objects of types which conform to `ThreadConfined` can be managed by a Realm, which will make
 them bound to a thread-specific `Realm` instance. Managed objects must be explicitly exported
 and imported to be passed between threads.

 Managed instances of objects conforming to this protocol can be converted to a thread-safe
 reference for transport between threads by passing to the `ThreadSafeReference(to:)` constructor.

 Note that only types defined by Realm can meaningfully conform to this protocol, and defining new
 classes which attempt to conform to it will not make them work with `ThreadSafeReference`.
 */
public protocol ThreadConfined {
    // Must also conform to `AssistedObjectiveCBridgeable`

    /**
     The Realm which manages the object, or `nil` if the object is unmanaged.

     Unmanaged objects are not confined to a thread and cannot be passed to methods expecting a
     `ThreadConfined` object.
     */
    var realm: Realm? { get }
#if swift(>=3.0)
    /// Indicates if the object can no longer be accessed because it is now invalid.
    var isInvalidated: Bool { get }
#else
    /// Indicates if the object can no longer be accessed because it is now invalid.
    var invalidated: Bool { get }
#endif
}

/**
 An object intended to be passed between threads containing a thread-safe reference to its
 thread-confined object.

 To resolve a thread-safe reference on a target Realm on a different thread, pass to
 `Realm.resolve(_:)`.

 - warning: A `ThreadSafeReference` object must be resolved at most once.
            Failing to resolve a `ThreadSafeReference` will result in the source version of the
            Realm being pinned until the reference is deallocated.

 - note: Prefer short-lived `ThreadSafeReference`s as the data for the version of the source Realm
         will be retained until all references have been resolved or deallocated.

 - see: `ThreadConfined`
 - see: `Realm.resolve(_:)`
 */
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

    /**
     Create a thread-safe reference to the thread-confined object.

     - parameter threadConfined: The thread-confined object to create a thread-safe reference to.

     - note: You may continue to use and access the thread-confined object after passing it to this
             constructor.
     */
    public init(to threadConfined: Confined) {
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
    /**
     Returns the same object as the one referenced when the `ThreadSafeReference` was first
     created, but resolved for the current Realm for this thread. Returns `nil` if this object was
     deleted after the reference was created.

     - parameter reference: The thread-safe reference to the thread-confined object to resolve in
                            this Realm.

     - warning: A `ThreadSafeReference` object must be resolved at most once.
                Failing to resolve a `ThreadSafeReference` will result in the source version of the
                Realm being pinned until the reference is deallocated.
                An exception will be thrown if a reference is resolved more than once.

     - warning: Cannot call within a write transaction.

     - note: Will refresh this Realm if the source Realm was at a later version than this one.

     - see: `ThreadSafeReference(to:)`
     */
    public func resolve<Confined: ThreadConfined>(_ reference: ThreadSafeReference<Confined>) -> Confined? {
        return reference.resolve(in: self)
    }
#else
    /**
     Returns the same object as the one referenced when the `ThreadSafeReference` was first
     created, but resolved for the current Realm for this thread. Returns `nil` if this object was
     deleted after the reference was created.

     - parameter reference: The thread-safe reference to the thread-confined object to resolve in
                            this Realm.

     - warning: A `ThreadSafeReference` object must be resolved at most once.
                Failing to resolve a `ThreadSafeReference` will result in the source version of the
                Realm being pinned until the reference is deallocated.
                An exception will be thrown if a reference is resolved more than once.

     - warning: Cannot call within a write transaction.

     - note: Will refresh this Realm if the source Realm was at a later version than this one.

     - see: `ThreadSafeReference(to:)`
     */
    public func resolve<Confined: ThreadConfined>(reference: ThreadSafeReference<Confined>) -> Confined? {
        return reference.resolve(in: self)
    }
#endif
}
