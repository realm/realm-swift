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
    /**
     The Realm which manages the object, or `nil` if the object is unmanaged.

     Unmanaged objects are not confined to a thread and cannot be passed to methods expecting a
     `ThreadConfined` object.
     */
    var realm: Realm? { get }

    /// Indicates if the object can no longer be accessed because it is now invalid.
    var isInvalidated: Bool { get }

    /**
    Indicates if the object is frozen.

    Frozen objects are not confined to their source thread. Forming a `ThreadSafeReference` to a
    frozen object is allowed, but is unlikely to be useful.
    */
    var isFrozen: Bool { get }

    /**
     Returns a frozen snapshot of this object.

     Unlike normal Realm live objects, the frozen copy can be read from any thread, and the values
     read will never update to reflect new writes to the Realm. Frozen collections can be queried
     like any other Realm collection. Frozen objects cannot be mutated, and cannot be observed for
     change notifications.

     Unmanaged Realm objects cannot be frozen.

     - warning: Holding onto a frozen object for an extended period while performing write
     transaction on the Realm may result in the Realm file growing to large sizes. See
     `Realm.Configuration.maximumNumberOfActiveVersions` for more information.
    */
    func freeze() -> Self

    /**
     Returns a live (mutable) reference of this object.
     Will return self if called on an already live object.
     */
    func thaw() -> Self?
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
@frozen public struct ThreadSafeReference<Confined: ThreadConfined> {
    /**
     Indicates if the reference can no longer be resolved because an attempt to resolve it has
     already occurred. References can only be resolved once.
     */
    public var isInvalidated: Bool { return objectiveCReference.isInvalidated }

    private let objectiveCReference: RLMThreadSafeReference<RLMThreadConfined>

    /**
     Create a thread-safe reference to the thread-confined object.

     - parameter threadConfined: The thread-confined object to create a thread-safe reference to.

     - note: You may continue to use and access the thread-confined object after passing it to this
             constructor.
     */
    public init(to threadConfined: Confined) {
        objectiveCReference = RLMThreadSafeReference(threadConfined: (threadConfined as! _ObjcBridgeable)._rlmObjcValue as! RLMThreadConfined)
    }

    internal func resolve(in realm: Realm) -> Confined? {
        guard let resolved = realm.rlmRealm.__resolve(objectiveCReference) as? RLMThreadConfined else { return nil }
        return (Confined.self as! _ObjcBridgeable.Type)._rlmFromObjc(resolved).flatMap { $0 as? Confined }
    }
}

// MARK: ThreadSafe propertyWrapper

/**
    A property wrapper type that may be passed between threads.

    A `@ThreadSafe` property contains a thread-safe reference to the underlying wrapped value.
    This reference is resolved to the thread on which the wrapped value is accessed. A new thread
    safe reference is created each time the property is accessed.

 - warning: This property wrapper should not be used for properties on long lived objects.
            `@ThreadSafe` properties contain a `ThreadSafeReference` which
            can pin the source version of the Realm in use. This means that this property
            wrapper is **better suited for function arguments and local variables**
            **that get captured by an aynchronously dispatched block.**

 - see: `ThreadSafeReference`
 - see: `ThreadConfined`
*/
@propertyWrapper public final class ThreadSafe<T: ThreadConfined> {
    private var threadSafeReference: ThreadSafeReference<T>?
    private var rlmConfiguration: RLMRealmConfiguration?
    private let lock = NSLock()

    /// :nodoc:
    public var wrappedValue: T? {
        get {
            lock.lock()
            guard let threadSafeReference = threadSafeReference,
                  let rlmConfig = rlmConfiguration else {
                lock.unlock()
                return nil
            }
            do {
                let rlmRealm = try RLMRealm(configuration: rlmConfig)
                let realm = Realm(rlmRealm)
                guard let value = threadSafeReference.resolve(in: realm) else {
                    self.threadSafeReference = nil
                    lock.unlock()
                    return nil
                }
                self.threadSafeReference = ThreadSafeReference(to: value)
                lock.unlock()
                return value
            // FIXME: wrappedValue should throw
            // As of Swift 5.5 property wrappers can't have throwing accessors.
            } catch let error as NSError {
                lock.unlock()
                throwRealmException(error.localizedDescription)
            }
        }
        set {
            lock.lock()
            guard let newValue = newValue else {
                threadSafeReference = nil
                lock.unlock()
                return
            }
            guard let rlmConfiguration = newValue.realm?.rlmRealm.configuration else {
                lock.unlock()
                throwRealmException("Only managed objects may be wrapped as thread safe.")
            }
            self.rlmConfiguration = rlmConfiguration
            threadSafeReference = ThreadSafeReference(to: newValue)
            lock.unlock()
        }
    }

    /// :nodoc:
    public init(wrappedValue: T?) {
        self.wrappedValue = wrappedValue
    }
}

extension Realm {
    // MARK: Thread Safe Reference

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
    public func resolve<Confined>(_ reference: ThreadSafeReference<Confined>) -> Confined? {
        return reference.resolve(in: self)
    }
}

extension ThreadSafeReference: Sendable {
}
extension RLMThreadSafeReference: @unchecked Sendable {
}
extension ThreadSafe: @unchecked Sendable {
}
