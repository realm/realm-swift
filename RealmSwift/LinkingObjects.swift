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

import Foundation
import Realm

/**
 `LinkingObjects` is an auto-updating container type. It represents zero or more objects that are linked to its owning
 model object through a property relationship.

 `LinkingObjects` can be queried with the same predicates as `List<Element>` and `Results<Element>`.

 `LinkingObjects` always reflects the current state of the Realm on the current thread, including during write
 transactions on the current thread. The one exception to this is when using `for...in` enumeration, which will always
 enumerate over the linking objects that were present when the enumeration is begun, even if some of them are deleted or
 modified to no longer link to the target object during the enumeration.

 `LinkingObjects` can only be used as a property on `Object` models. Properties of this type must be declared as `let`
 and cannot be `dynamic`.
 */
@frozen public struct LinkingObjects<Element: ObjectBase & RealmCollectionValue>: RealmCollectionImpl {
    // MARK: Initializers

    /**
     Creates an instance of a `LinkingObjects`. This initializer should only be called when declaring a property on a
     Realm model.

     - parameter type:         The type of the object owning the property the linking objects should refer to.
     - parameter propertyName: The property name of the property the linking objects should refer to.
     */
    public init(fromType _: Element.Type, property propertyName: String) {
        self.propertyName = propertyName
    }

    /// A human-readable description of the objects represented by the linking objects.
    public var description: String {
        if realm == nil {
            var this = self
            return withUnsafePointer(to: &this) {
                return "LinkingObjects<\(Element.className())> <\($0)> (\n\n)"
            }
        }
        return RLMDescriptionWithMaxDepth("LinkingObjects", collection, RLMDescriptionMaxDepth)
    }

    // MARK: Object Retrieval

    /**
     Returns the object at the given `index`.

     - parameter index: The index.
     */
    public subscript(index: Int) -> Element {
        if let lastAccessedNames = lastAccessedNames {
            return Element.keyPathRecorder(with: lastAccessedNames)
        }
        throwForNegativeIndex(index)
        return collection[UInt(index)] as! Element
    }

    // MARK: Equatable

    public static func == (lhs: LinkingObjects<Element>, rhs: LinkingObjects<Element>) -> Bool {
        lhs.collection.isEqual(rhs.collection)
    }

    // MARK: Implementation

    internal init(propertyName: String, handle: RLMLinkingObjectsHandle?) {
        self.propertyName = propertyName
        self.handle = handle
    }
    internal init(collection: RLMCollection) {
        self.propertyName = ""
        self.handle = RLMLinkingObjectsHandle(linkingObjects: collection as! RLMResults<AnyObject>)
    }

    internal var collection: RLMCollection {
        return handle?.results ?? RLMResults<AnyObject>.emptyDetached()
    }

    internal var propertyName: String
    internal var handle: RLMLinkingObjectsHandle?
    internal var lastAccessedNames: NSMutableArray?
}
