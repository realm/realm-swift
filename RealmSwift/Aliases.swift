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

import Foundation
import Realm.Swift

// These types don't change when wrapping in Swift
// so we just typealias them to remove the 'RLM' prefix

// MARK: Aliases

/**
 `PropertyType` is an enum describing all property types supported in Realm models.

 For more information, see [Object Models and Schemas](https://www.mongodb.com/docs/realm/sdk/swift/fundamentals/object-models-and-schemas/).

 ### Primitive types

 * `Int`
 * `Bool`
 * `Float`
 * `Double`

 ### Object types

 * `String`
 * `Data`
 * `Date`
 * `Decimal128`
 * `ObjectId`

 ### Relationships: Array (in Swift, `List`) and `Object` types

 * `Object`
 * `Array`
*/
public typealias PropertyType = RLMPropertyType

/**
 An opaque token which is returned from methods which subscribe to changes to a Realm.

 - see: `Realm.observe(_:)`
 */
public typealias NotificationToken = RLMNotificationToken

/// :nodoc:
public typealias ObjectBase = RLMObjectBase
extension ObjectBase {
    internal func _observe<T: ObjectBase>(keyPaths: [String]? = nil,
                                          on queue: DispatchQueue? = nil,
                                          _ block: @escaping (ObjectChange<T>) -> Void) -> NotificationToken {
        return RLMObjectBaseAddNotificationBlock(self, keyPaths, queue) { object, names, oldValues, newValues, error in
            assert(error == nil)
            guard let names = names, let newValues = newValues else {
                block(.deleted)
                return
            }

            block(.change(object as! T, (0..<newValues.count).map { i in
                PropertyChange(name: names[i], oldValue: oldValues?[i], newValue: newValues[i])
            }))
        }
    }

    internal func _observe<T: ObjectBase>(keyPaths: [String]? = nil,
                                          on queue: DispatchQueue? = nil,
                                          _ block: @escaping (T?) -> Void) -> NotificationToken {
        return RLMObjectBaseAddNotificationBlock(self, keyPaths, queue) { object, names, _, _, _ in
            if names == nil {
                block(nil)
            } else {
                block((object as! T))
            }
        }
    }

    internal func _observe(keyPaths: [String]? = nil,
                           on queue: DispatchQueue? = nil,
                           _ block: @escaping () -> Void) -> NotificationToken {
        return RLMObjectBaseAddNotificationBlock(self, keyPaths, queue) { _, _, _, _, _ in
            block()
        }
    }
}
