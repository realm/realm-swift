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

 For more information, see [Object Models and Schemas](https://www.mongodb.com/docs/atlas/device-sdks/sdk/swift/model-data/object-models/).

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
            block(.init(object: object as? T, names: names, oldValues: oldValues, newValues: newValues))
        }
    }

    internal func _observe<T: ObjectBase>(keyPaths: [String]? = nil,
                                          on queue: DispatchQueue? = nil,
                                          _ block: @escaping (T?) -> Void) -> NotificationToken {
        return RLMObjectBaseAddNotificationBlock(self, keyPaths, queue) { object, _, _, _, _ in
            block(object as? T)
        }
    }

    internal func _observe(keyPaths: [String]? = nil,
                           on queue: DispatchQueue? = nil,
                           _ block: @escaping () -> Void) -> NotificationToken {
        return RLMObjectBaseAddNotificationBlock(self, keyPaths, queue) { _, _, _, _, _ in
            block()
        }
    }

    @available(macOS 10.15, tvOS 13.0, iOS 13.0, watchOS 6.0, *)
    internal func _observe<A: Actor, T: ObjectBase>(
        keyPaths: [String]? = nil, on actor: isolated A,
        _ block: @Sendable @escaping (isolated A, ObjectChange<T>) -> Void
    ) async -> NotificationToken {
        let token = RLMObjectNotificationToken()
        token.observe(self, keyPaths: keyPaths) { object, names, oldValues, newValues, error in
            assert(error == nil)
            actor.invokeIsolated(block, .init(object: object as? T, names: names,
                        oldValues: oldValues, newValues: newValues))
        }
        await withTaskCancellationHandler(operation: token.registrationComplete,
                                          onCancel: { token.invalidate() })
        return token
    }
}
