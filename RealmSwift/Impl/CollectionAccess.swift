////////////////////////////////////////////////////////////////////////////
//
// Copyright 2021 Realm Inc.
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

internal protocol MutableRealmCollection {
    func removeAll()
    func add(_ obj: AnyObject)
}
internal protocol MutableMapRealmCollection {
    func removeAll()
    func add(key: AnyObject, value: AnyObject)
}
extension List: MutableRealmCollection {
    func add(_ obj: AnyObject) {
        rlmArray.add(obj)
    }
}
extension MutableSet: MutableRealmCollection {
    func add(_ obj: AnyObject) {
        rlmSet.add(obj)
    }
}
extension Map: MutableMapRealmCollection {
    func add(key: AnyObject, value: AnyObject) {
        rlmDictionary.setObject(value, forKey: key as AnyObject)
    }
}

internal func assign<C: MutableRealmCollection>(value: Any, to collection: C) {
    collection.removeAll()
    if let enumeration = value as? NSFastEnumeration {
        var iterator = NSFastEnumerationIterator(enumeration)
        while let obj = iterator.next() {
            collection.add(dynamicBridgeCast(fromSwift: obj) as AnyObject)
        }
    }
}

internal func assign<C: MutableMapRealmCollection>(value: Any, to collection: C) {
    collection.removeAll()
    if let enumeration = value as? NSDictionary {
        var iterator = NSFastEnumerationIterator(enumeration)
        while let key = iterator.next() {
            collection.add(key: key as AnyObject, value: dynamicBridgeCast(fromSwift: enumeration[key]) as AnyObject)
        }
    }
}

// A protocol which all Realm Collections conform to which does not have any
// associated types so that it can be used in casts
internal protocol UntypedCollection {
    // Cast this object to an id<NSFastEnumerator> so that it can be iterated from obj-c
    func asNSFastEnumerator() -> Any
}

extension List: UntypedCollection {
    internal func asNSFastEnumerator() -> Any {
        return rlmArray
    }
}

extension MutableSet: UntypedCollection {
    internal func asNSFastEnumerator() -> Any {
        return rlmSet
    }
}

extension Map: UntypedCollection {
    internal func asNSFastEnumerator() -> Any {
        return rlmDictionary
    }
}

extension Results: UntypedCollection {
    internal func asNSFastEnumerator() -> Any {
        return rlmResults
    }
}

extension LinkingObjects: UntypedCollection {
    internal func asNSFastEnumerator() -> Any {
        return rlmResults
    }
}
