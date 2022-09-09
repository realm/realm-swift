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

import Foundation
import Realm.Private

/**
 Gets the components of a given key path as a string.

 - warning: Objects that declare properties with the old `@objc dynamic` syntax are not fully supported
 by this function, and it is recommended that you use `@Persisted` to declare your properties if you wish to use
 this function to its full benefit.

 Example:
 ```
 let name = ObjectBase._name(for: \Person.dogs[0].name) // "dogs.name"
 // Note that the above KeyPath expression is only supported with properties declared
 // with `@Persisted`.
 let nested = ObjectBase._name(for: \Person.address.city.zip) // "address.city.zip"
 ```
 */
public func _name<T: ObjectBase>(for keyPath: PartialKeyPath<T>) -> String {
    return name(for: keyPath)
}

/**
 Gets the components of a given key path as a string.

 - warning: Objects that declare properties with the old `@objc dynamic` syntax are not fully supported
 by this function, and it is recommended that you use `@Persisted` to declare your properties if you wish to use
 this function to its full benefit.

 Example:
 ```
 let name = PersonProjection._name(for: \PersonProjection.dogs[0].name) // "dogs.name"
 // Note that the above KeyPath expression is only supported with properties declared
 // with `@Persisted`.
 let nested = ObjectBase._name(for: \Person.address.city.zip) // "address.city.zip"
 ```
 */
public func _name<O: ObjectBase, T>(for keyPath: PartialKeyPath<T>) -> String where T: Projection<O> {
    return name(for: keyPath)
}

private func name<T: KeypathRecorder>(for keyPath: PartialKeyPath<T>) -> String {
    if let name = keyPath._kvcKeyPathString {
        return name
    }
    let names = NSMutableArray()
    let value = T.keyPathRecorder(with: names)[keyPath: keyPath]
    if let collection = value as? PropertyNameConvertible,
       let propertyInfo = collection.propertyInformation, propertyInfo.isLegacy {
        names.add(propertyInfo.key)
    }

    if let storage = value as? RLMSwiftValueStorage {
        names.add(RLMSwiftValueStorageGetPropertyName(storage))
    }
    return names.componentsJoined(by: ".")
}

/// Create a valid element for a collection, as a keypath recorder if that type supports it.
internal func elementKeyPathRecorder<T: RealmCollectionValue>(
        for type: T.Type, with lastAccessedNames: NSMutableArray) -> T {
    if let type = type as? KeypathRecorder.Type {
        return type.keyPathRecorder(with: lastAccessedNames) as! T
    }
    return T._rlmDefaultValue()
}

// MARK: - Implementation

/// Protocol which allows a collection to produce its property name
internal protocol PropertyNameConvertible {
    /// A mutable array referenced from the enclosing parent that contains the last accessed property names.
    var lastAccessedNames: NSMutableArray? { get set }
    /// `key` is the property name for this collection.
    /// `isLegacy` will be true if the property is declared with old property syntax.
    var propertyInformation: (key: String, isLegacy: Bool)? { get }
}

internal protocol KeypathRecorder {
    // Return an instance of Self which is initialized for keypath recording
    // using the given target array.
    static func keyPathRecorder(with lastAccessedNames: NSMutableArray) -> Self
}

extension Optional: KeypathRecorder where Wrapped: KeypathRecorder {
    internal static func keyPathRecorder(with lastAccessedNames: NSMutableArray) -> Self {
        return Wrapped.keyPathRecorder(with: lastAccessedNames)
    }
}

extension ObjectBase: KeypathRecorder {
    internal static func keyPathRecorder(with lastAccessedNames: NSMutableArray) -> Self {
        let obj = Self()
        obj.lastAccessedNames = lastAccessedNames
        let objectSchema = ObjectSchema(RLMObjectBaseObjectSchema(obj)!)
        (objectSchema.rlmObjectSchema.properties + objectSchema.rlmObjectSchema.computedProperties)
            .map { (prop: $0, accessor: $0.swiftAccessor) }
            .forEach { $0.accessor?.observe($0.prop, on: obj) }
        return obj
    }
}

extension Projection: KeypathRecorder {
    internal static func keyPathRecorder(with lastAccessedNames: NSMutableArray) -> Self {
        let obj = Self(projecting: PersistedType())
        obj.rootObject.lastAccessedNames = lastAccessedNames
        let objectSchema = ObjectSchema(RLMObjectBaseObjectSchema(obj.rootObject)!)
        (objectSchema.rlmObjectSchema.properties + objectSchema.rlmObjectSchema.computedProperties)
            .map { (prop: $0, accessor: $0.swiftAccessor) }
            .forEach { $0.accessor?.observe($0.prop, on: obj.rootObject) }
        return obj
    }
}

extension _DefaultConstructible {
    internal static func keyPathRecorder(with lastAccessedNames: NSMutableArray) -> Self {
        let obj = Self()
        if var obj = obj as? PropertyNameConvertible {
            obj.lastAccessedNames = lastAccessedNames
        }
        return obj
    }
}

extension List: KeypathRecorder where Element: _Persistable {}
extension List: PropertyNameConvertible {
    var propertyInformation: (key: String, isLegacy: Bool)? {
        return (key: rlmArray.propertyKey, isLegacy: rlmArray.isLegacyProperty)
    }
}

extension Map: KeypathRecorder where Value: _Persistable {}
extension Map: PropertyNameConvertible {
    var propertyInformation: (key: String, isLegacy: Bool)? {
        return (key: rlmDictionary.propertyKey, isLegacy: rlmDictionary.isLegacyProperty)
    }
}

extension MutableSet: KeypathRecorder where Element: _Persistable {}
extension MutableSet: PropertyNameConvertible {
    var propertyInformation: (key: String, isLegacy: Bool)? {
        return (key: rlmSet.propertyKey, isLegacy: rlmSet.isLegacyProperty)
    }
}

extension LinkingObjects: KeypathRecorder where Element: _Persistable {
    static func keyPathRecorder(with lastAccessedNames: NSMutableArray) -> LinkingObjects<Element> {
        var obj = Self(propertyName: "", handle: nil)
        obj.lastAccessedNames = lastAccessedNames
        return obj
    }
}
extension LinkingObjects: PropertyNameConvertible {
    var propertyInformation: (key: String, isLegacy: Bool)? {
        guard let handle = handle else { return nil }
        return (key: handle._propertyKey, isLegacy: handle._isLegacyProperty)
    }
}
