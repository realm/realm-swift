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
import Realm

/**
 A `RealmProperty` instance represents an polymorphic value for supported types.

 To change the underlying value stored by a `RealmProperty` instance, mutate the instance's `value` property.

 - Note:
 An `RealmProperty` should not be declared as `@objc dynamic` on a Realm Object. Use `let` instead.
 */
public final class RealmProperty<Value: RealmPropertyType>: RLMValueBase {
    /**
     Used for getting / setting the underlying value.

      - Usage:
     ```
        class MyObject: Object {
            let myAnyValue = RealmProperty<AnyRealmValue>()
        }
        // Setting
        myObject.myAnyValue.value = .string("hello")
        // Getting
        if case let .string(s) = myObject.myAnyValue.value {
            print(s) // Prints 'Hello'
        }
     ```
     */
    public var value: Value {
        set {
            rlmValue = dynamicBridgeCast(fromSwift: newValue)
        }
        get {
            dynamicBridgeCast(fromObjectiveC: rlmValue ?? NSNull())
        }
    }

    internal convenience init(value: RLMValue?) {
        self.init()
        rlmValue = value
    }

    // Used for when retrieving an AnyRealmValue via KVC
    internal convenience init(value: RLMValue?, object: RLMObjectBase, property: RLMProperty) {
        self.init()
        rlmValue = value
        attach(withParent: object, property: property)
    }
}

/// A protocol describing types that can parameterize a `RealmPropertyType`.
public protocol RealmPropertyType { }
/// A protocol describing types that can be represented as optional in a `RealmProperty<>`
internal protocol OptionalRealmPropertyType { }

extension AnyRealmValue: RealmPropertyType { }
extension Optional: RealmPropertyType where Wrapped: OptionalRealmPropertyType { }

extension Int: OptionalRealmPropertyType { }
extension Int8: OptionalRealmPropertyType { }
extension Int16: OptionalRealmPropertyType { }
extension Int32: OptionalRealmPropertyType { }
extension Int64: OptionalRealmPropertyType { }
extension Float: OptionalRealmPropertyType { }
extension Double: OptionalRealmPropertyType { }
extension Bool: OptionalRealmPropertyType { }
