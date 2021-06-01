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
private func ptr(_ property: RLMProperty, _ obj: RLMObjectBase) -> UnsafeMutableRawPointer {
    return Unmanaged.passUnretained(obj).toOpaque().advanced(by: ivar_getOffset(property.swiftIvar!))
}

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
        assign(value: value, to: bound(property, parent))
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
        assign(value: value, to: bound(property, parent))
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
        assign(value: value, to: bound(property, parent))
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
        bound(property, parent).pointee.handle =
            RLMLinkingObjectsHandle(object: parent, property: property)
    }
    @objc override class func get(_ property: RLMProperty, on parent: RLMObjectBase) -> Any {
        return bound(property, parent).pointee
    }
}

private func isNull(_ value: Any) -> Bool {
    // nil in Any is bridged to obj-c as NSNull. In the obj-c code we usually
    // convert NSNull back to nil, which ends up as Optional<Any>.none
    if value is NSNull {
        return true
    }
    if case Optional<Any>.none = value {
        return true
    }
    return false
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
        if let value = value as? RealmEnum {
            return type(of: value)._rlmToRawValue(value)
        }
        // RealmOptional does not support any non-enum types which require custom
        // bridging from swift to objc, so no CustomObjectiveCBridgeable check here
        return value as Any
    }

    @objc override class func set(_ property: RLMProperty, on parent: RLMObjectBase, to value: Any) {
        let bridged: Value?
        if isNull(value) {
            bridged = nil
        } else if let value = value as? Value {
            bridged = value
        } else if let type = Value.self as? CustomObjectiveCBridgeable.Type {
            bridged = (type.bridging(objCValue: value) as! Value)
        } else if let type = Value.self as? RealmEnum.Type {
            bridged = (type._rlmFromRawValue(value) as! Value)
        } else {
            fatalError("Unexpected value '\(value)' of type '\(type(of: value))' for '\(Value.self)' property")
        }
        bound(property, parent).value = bridged
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
        let value = bound(property, parent).value
        if let value = value as? CustomObjectiveCBridgeable {
            return value.objCValue
        }
        // Not actually reachable as all types which can be stored on a RealmProperty
        // are CustomObjectiveCBridgeable but we can't express that in the type
        // system without making CustomObjectiveCBridgeable public
        return value as Any
    }

    @objc override class func set(_ property: RLMProperty, on parent: RLMObjectBase, to value: Any) {
        let bridged: Value
        if let value = value as? Value {
            bridged = value
        } else if let type = Value.self as? CustomObjectiveCBridgeable.Type {
            bridged = (type.bridging(objCValue: value) as! Value)
        } else {
            fatalError("Unexpected value '\(value)' of type '\(type(of: value))' for '\(Value.self)' property")
        }
        bound(property, parent).value = bridged
    }
}
