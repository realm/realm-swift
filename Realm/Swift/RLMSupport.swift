////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
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

extension RLMRealm {
    /**
     Returns the schema version for a Realm at a given local URL.

     - see: `+ [RLMRealm schemaVersionAtURL:encryptionKey:error:]`
     */
    @nonobjc public class func schemaVersion(at url: URL, usingEncryptionKey key: Data? = nil) throws -> UInt64 {
        var error: NSError?
        let version = __schemaVersion(at: url, encryptionKey: key, error: &error)
        guard version != RLMNotVersioned else { throw error! }
        return version
    }

    /**
     Returns the same object as the one referenced when the `RLMThreadSafeReference` was first created,
     but resolved for the current Realm for this thread. Returns `nil` if this object was deleted after
     the reference was created.

     - see `- [RLMRealm resolveThreadSafeReference:]`
     */
    @nonobjc public func resolve<Confined>(reference: RLMThreadSafeReference<Confined>) -> Confined? {
        return __resolve(reference as! RLMThreadSafeReference<RLMThreadConfined>) as! Confined?
    }
}

extension RLMObject {
    /**
     Returns all objects of this object type matching the given predicate from the default Realm.

     - see `+ [RLMObject objectsWithPredicate:]`
     */
    public class func objects(where predicateFormat: String, _ args: CVarArg...) -> RLMResults<RLMObject> {
        return objects(with: NSPredicate(format: predicateFormat, arguments: getVaList(args))) as! RLMResults<RLMObject>
    }

    /**
     Returns all objects of this object type matching the given predicate from the specified Realm.

     - see `+ [RLMObject objectsInRealm:withPredicate:]`
     */
    public class func objects(in realm: RLMRealm,
                              where predicateFormat: String,
                              _ args: CVarArg...) -> RLMResults<RLMObject> {
        return objects(in: realm, with: NSPredicate(format: predicateFormat, arguments: getVaList(args))) as! RLMResults<RLMObject>
    }
}

public protocol _RandomAccessIterator {
    /**
     Returns a `RLMCollectionIterator` that yields successive elements in the collection.
     This enables support for sequence-style enumeration of `RLMObject` subclasses in Swift.
     */
    func makeIterator() -> RLMRandomAccessIterator;
}

extension _RandomAccessIterator where Self: RLMCollection {
    public func makeIterator() -> RLMRandomAccessIterator {
        return RLMRandomAccessIterator(self)
    }
}

public typealias RLMDictionarySingleEntry = (key: String, value: RLMObject)
public protocol _MapIterator {
    func makeIterator() -> RLMDictionaryIterator;
}

extension _MapIterator where Self: RLMCollection {
    public func makeIterator() -> RLMDictionaryIterator {
        return RLMDictionaryIterator(self)
    }
}

// Sequence conformance for RLMArray, RLMDictionary, RLMSet and RLMResults is provided by RLMCollection's
// `makeIterator()` implementation.
extension RLMArray: Sequence, _RandomAccessIterator { }
extension RLMDictionary: Sequence, _MapIterator {}
extension RLMSet: Sequence, _RandomAccessIterator {}
extension RLMResults: Sequence, _RandomAccessIterator {}

/**
 This struct enables sequence-style enumeration for RLMObjects in Swift via `RLMCollection.makeIterator`
 */
public struct RLMRandomAccessIterator: IteratorProtocol {
    private var iteratorBase: NSFastEnumerationIterator

    internal init(_ collection: RLMCollection) {
        iteratorBase = NSFastEnumerationIterator(collection)
    }

    public mutating func next() -> RLMObject? {
        return iteratorBase.next() as! RLMObject?
    }
}

public struct RLMDictionaryIterator: IteratorProtocol {
    private var iteratorBase: NSFastEnumerationIterator
    private let dictionary: RLMDictionary<AnyObject, AnyObject>

    internal init(_ collection: RLMCollection) {
        dictionary = collection as! RLMDictionary<AnyObject, AnyObject>
        iteratorBase = NSFastEnumerationIterator(collection)
    }

    public mutating func next() -> RLMDictionarySingleEntry? {
        let key = iteratorBase.next()
        if let key = key as? RLMDictionaryKey {
            return (key: key as! String, value: dictionary[key]) as? RLMDictionarySingleEntry
        }
        if key != nil {
            fatalError("unsupported key type")
        }
        return nil
    }
}

// Swift query convenience functions
extension RLMCollection {
    /**
     Returns the index of the first object in the collection matching the predicate.
     */
    public func indexOfObject(where predicateFormat: String, _ args: CVarArg...) -> UInt {
        guard let index = indexOfObject?(with: NSPredicate(format: predicateFormat, arguments: getVaList(args))) else {
            fatalError("This RLMCollection does not support indexOfObject(where:)")
        }
        return index
    }

    /**
     Returns all objects matching the given predicate in the collection.
     */
    public func objects(where predicateFormat: String, _ args: CVarArg...) -> RLMResults<NSObject> {
        return objects(with: NSPredicate(format: predicateFormat, arguments: getVaList(args))) as! RLMResults<NSObject>
    }
}
