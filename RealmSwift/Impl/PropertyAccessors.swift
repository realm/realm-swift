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
import Realm.Private

// Get a pointer to the given property's ivar on the object. This is similar to
// object_getIvar() but returns a pointer to the value rather than the value.
@_transparent
private func ptr(_ property: RLMProperty, _ obj: RLMObjectBase) -> UnsafeMutableRawPointer {
    return Unmanaged.passUnretained(obj).toOpaque().advanced(by: property.swiftIvar)
}

// MARK: - Legacy Property Accessors

internal class ListAccessor<Element: RealmCollectionValue>: RLMManagedPropertyAccessor {
    private static func bound(_ property: RLMProperty, _ obj: RLMObjectBase) -> List<Element> {
        return ptr(property, obj).assumingMemoryBound(to: List<Element>.self).pointee
    }

    @objc override class func initialize(_ property: RLMProperty, on parent: RLMObjectBase) {
        bound(property, parent)._rlmCollection = RLMManagedArray(parent: parent, property: property)
    }

    @objc override class func observe(_ property: RLMProperty, on parent: RLMObjectBase) {
        bound(property, parent).rlmArray.setParent(parent, property: property)
    }

    @objc override class func get(_ property: RLMProperty, on parent: RLMObjectBase) -> Any {
        return bound(property, parent)
    }

    @objc override class func set(_ property: RLMProperty, on parent: RLMObjectBase, to value: Any) {
        bound(property, parent).assign(value)
    }
}

internal class SetAccessor<Element: RealmCollectionValue>: RLMManagedPropertyAccessor {
    private static func bound(_ property: RLMProperty, _ obj: RLMObjectBase) -> MutableSet<Element> {
        return ptr(property, obj).assumingMemoryBound(to: MutableSet<Element>.self).pointee
    }

    @objc override class func initialize(_ property: RLMProperty, on parent: RLMObjectBase) {
        bound(property, parent)._rlmCollection = RLMManagedSet(parent: parent, property: property)
    }

    @objc override class func observe(_ property: RLMProperty, on parent: RLMObjectBase) {
        bound(property, parent).rlmSet.setParent(parent, property: property)
    }

    @objc override class func get(_ property: RLMProperty, on parent: RLMObjectBase) -> Any {
        return bound(property, parent)
    }

    @objc override class func set(_ property: RLMProperty, on parent: RLMObjectBase, to value: Any) {
        bound(property, parent).assign(value)
    }
}

internal class MapAccessor<Key: _MapKey, Value: RealmCollectionValue>: RLMManagedPropertyAccessor {
    private static func bound(_ property: RLMProperty, _ obj: RLMObjectBase) -> Map<Key, Value> {
        return ptr(property, obj).assumingMemoryBound(to: Map<Key, Value>.self).pointee
    }

    @objc override class func initialize(_ property: RLMProperty, on parent: RLMObjectBase) {
        bound(property, parent)._rlmCollection = RLMManagedDictionary(parent: parent, property: property)
    }

    @objc override class func observe(_ property: RLMProperty, on parent: RLMObjectBase) {
        bound(property, parent).rlmDictionary.setParent(parent, property: property)
    }

    @objc override class func get(_ property: RLMProperty, on parent: RLMObjectBase) -> Any {
        return bound(property, parent)
    }

    @objc override class func set(_ property: RLMProperty, on parent: RLMObjectBase, to value: Any) {
        bound(property, parent).assign(value)
    }
}

internal class LinkingObjectsAccessor<Element: ObjectBase>: RLMManagedPropertyAccessor
        where Element: RealmCollectionValue {
    private static func bound(_ property: RLMProperty, _ obj: RLMObjectBase) -> UnsafeMutablePointer<LinkingObjects<Element>> {
        return ptr(property, obj).assumingMemoryBound(to: LinkingObjects<Element>.self)
    }

    @objc override class func initialize(_ property: RLMProperty, on parent: RLMObjectBase) {
        bound(property, parent).pointee.handle =
            RLMLinkingObjectsHandle(object: parent, property: property)
    }
    @objc override class func observe(_ property: RLMProperty, on parent: RLMObjectBase) {
        if parent.lastAccessedNames != nil {
            bound(property, parent).pointee.handle = RLMLinkingObjectsHandle(object: parent, property: property)
        }
    }
    @objc override class func get(_ property: RLMProperty, on parent: RLMObjectBase) -> Any {
        return bound(property, parent).pointee
    }
}

@available(*, deprecated)
internal class RealmOptionalAccessor<Value: RealmOptionalType>: RLMManagedPropertyAccessor {
    private static func bound(_ property: RLMProperty, _ obj: RLMObjectBase) -> RealmOptional<Value> {
        return ptr(property, obj).assumingMemoryBound(to: RealmOptional<Value>.self).pointee
    }

    @objc override class func initialize(_ property: RLMProperty, on parent: RLMObjectBase) {
        RLMInitializeManagedSwiftValueStorage(bound(property, parent), parent, property)
    }

    @objc override class func observe(_ property: RLMProperty, on parent: RLMObjectBase) {
        RLMInitializeUnmanagedSwiftValueStorage(bound(property, parent), parent, property)
    }

    @objc override class func get(_ property: RLMProperty, on parent: RLMObjectBase) -> Any {
        let value = bound(property, parent).value
        return value._rlmObjcValue
    }

    @objc override class func set(_ property: RLMProperty, on parent: RLMObjectBase, to value: Any) {
        bound(property, parent).value = Value._rlmFromObjc(value)
    }
}

internal class RealmPropertyAccessor<Value: RealmPropertyType>: RLMManagedPropertyAccessor {
    private static func bound(_ property: RLMProperty, _ obj: RLMObjectBase) -> RealmProperty<Value> {
        return ptr(property, obj).assumingMemoryBound(to: RealmProperty<Value>.self).pointee
    }

    @objc override class func initialize(_ property: RLMProperty, on parent: RLMObjectBase) {
        RLMInitializeManagedSwiftValueStorage(bound(property, parent), parent, property)
    }

    @objc override class func observe(_ property: RLMProperty, on parent: RLMObjectBase) {
        RLMInitializeUnmanagedSwiftValueStorage(bound(property, parent), parent, property)
    }

    @objc override class func get(_ property: RLMProperty, on parent: RLMObjectBase) -> Any {
        return bound(property, parent).value._rlmObjcValue
    }

    @objc override class func set(_ property: RLMProperty, on parent: RLMObjectBase, to value: Any) {
        bound(property, parent).value = Value._rlmFromObjc(value)!
    }
}

// MARK: - Modern Property Accessors

internal class PersistedPropertyAccessor<T: _Persistable>: RLMManagedPropertyAccessor {
    fileprivate static func bound(_ property: RLMProperty, _ obj: RLMObjectBase) -> UnsafeMutablePointer<Persisted<T>> {
        return ptr(property, obj).assumingMemoryBound(to: Persisted<T>.self)
    }

    @objc override class func initialize(_ property: RLMProperty, on parent: RLMObjectBase) {
        bound(property, parent).pointee.initialize(parent, key: PropertyKey(property.index))
    }

    @objc override class func observe(_ property: RLMProperty, on parent: RLMObjectBase) {
        bound(property, parent).pointee.observe(parent, property: property)
    }

    @objc override class func get(_ property: RLMProperty, on parent: RLMObjectBase) -> Any {
        return bound(property, parent).pointee.get(parent)
    }

    @objc override class func set(_ property: RLMProperty, on parent: RLMObjectBase, to value: Any) {
        guard let v = T._rlmFromObjc(value) else {
            throwRealmException("Could not convert value '\(value)' to type '\(T.self)'.")
        }
        bound(property, parent).pointee.set(parent, value: v)
    }
}

internal class PersistedListAccessor<Element: RealmCollectionValue & _Persistable>: PersistedPropertyAccessor<List<Element>> {
    @objc override class func set(_ property: RLMProperty, on parent: RLMObjectBase, to value: Any) {
        bound(property, parent).pointee.get(parent).assign(value)
    }

    // When promoting an existing object to managed we want to promote the existing
    // Swift collection object if it exists
    @objc override class func promote(_ property: RLMProperty, on parent: RLMObjectBase) {
        let key = PropertyKey(property.index)
        if let existing = bound(property, parent).pointee.initializeCollection(parent, key: key) {
            existing._rlmCollection = RLMGetSwiftPropertyArray(parent, key)
        }
    }
}

internal class PersistedSetAccessor<Element: RealmCollectionValue & _Persistable>: PersistedPropertyAccessor<MutableSet<Element>> {
    @objc override class func set(_ property: RLMProperty, on parent: RLMObjectBase, to value: Any) {
        bound(property, parent).pointee.get(parent).assign(value)
    }
    @objc override class func promote(_ property: RLMProperty, on parent: RLMObjectBase) {
        let key = PropertyKey(property.index)
        if let existing = bound(property, parent).pointee.initializeCollection(parent, key: key) {
            existing._rlmCollection = RLMGetSwiftPropertyArray(parent, key)
        }
    }
}

internal class PersistedMapAccessor<Key: _MapKey, Value: RealmCollectionValue & _Persistable>: PersistedPropertyAccessor<Map<Key, Value>> {
    @objc override class func set(_ property: RLMProperty, on parent: RLMObjectBase, to value: Any) {
        bound(property, parent).pointee.get(parent).assign(value)
    }
    @objc override class func promote(_ property: RLMProperty, on parent: RLMObjectBase) {
        let key = PropertyKey(property.index)
        if let existing = bound(property, parent).pointee.initializeCollection(parent, key: key) {
            existing._rlmCollection = RLMGetSwiftPropertyMap(parent, PropertyKey(property.index))
        }
    }
}

internal class PersistedLinkingObjectsAccessor<Element: ObjectBase & RealmCollectionValue & _Persistable>: RLMManagedPropertyAccessor {
    private static func bound(_ property: RLMProperty, _ obj: RLMObjectBase) -> UnsafeMutablePointer<Persisted<LinkingObjects<Element>>> {
        return ptr(property, obj).assumingMemoryBound(to: Persisted<LinkingObjects<Element>>.self)
    }

    @objc override class func initialize(_ property: RLMProperty, on parent: RLMObjectBase) {
        bound(property, parent).pointee.initialize(parent, key: PropertyKey(property.index))
    }
    @objc override class func observe(_ property: RLMProperty, on parent: RLMObjectBase) {
        if parent.lastAccessedNames != nil {
            bound(property, parent).pointee.observe(parent, property: property)
        }
    }
    @objc override class func get(_ property: RLMProperty, on parent: RLMObjectBase) -> Any {
        return bound(property, parent).pointee.get(parent)
    }
}

// Dynamic getters return the Swift type for Collections, and the obj-c type
// for enums and AnyRealmValue. This difference is probably a mistake but it's
// a breaking change to adjust.
internal class BridgedPersistedPropertyAccessor<T: _Persistable>: PersistedPropertyAccessor<T> {
    @objc override class func get(_ property: RLMProperty, on parent: RLMObjectBase) -> Any {
        return bound(property, parent).pointee.get(parent)._rlmObjcValue
    }
}

internal class CustomPersistablePropertyAccessor<T: _Persistable>: BridgedPersistedPropertyAccessor<T> {
    @objc override class func set(_ property: RLMProperty, on parent: RLMObjectBase, to value: Any) {
        if coerceToNil(value) == nil {
            super.set(property, on: parent, to: T._rlmDefaultValue())
        } else {
            super.set(property, on: parent, to: value)
        }
    }
}
