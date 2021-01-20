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
        return bound(property, parent).value as Any
    }

    @objc override class func set(_ property: RLMProperty, on parent: RLMObjectBase, to value: Any) {
        let bridged: Value?
        if case Optional<Any>.none = value {
            bridged = nil
        } else if let type = Value.self as? CustomObjectiveCBridgeable.Type {
            bridged = (type.bridging(objCValue: value) as! Value)
        } else {
            bridged = (value as! Value)
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
        return value as Any
    }

    @objc override class func set(_ property: RLMProperty, on parent: RLMObjectBase, to value: Any) {
        let bridged: Value
        if let type = Value.self as? CustomObjectiveCBridgeable.Type {
            bridged = (type.bridging(objCValue: value) as! Value)
        } else {
            bridged = (value as! Value)
        }
        bound(property, parent).value = bridged
    }
}
