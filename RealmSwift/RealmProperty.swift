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
public final class RealmProperty<Value: RealmPropertyType>: RLMSwiftValueStorage {
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
        get {
            staticBridgeCast(fromObjectiveC: RLMGetSwiftValueStorage(self) ?? NSNull())
        }
        set {
            RLMSetSwiftValueStorage(self, staticBridgeCast(fromSwift: newValue))
        }
    }

    /// :nodoc:
    @objc public override var description: String {
        String(describing: value)
    }
}

extension RealmProperty: Equatable where Value: Equatable {
    public static func == (lhs: RealmProperty<Value>, rhs: RealmProperty<Value>) -> Bool {
        return lhs.value == rhs.value
    }
}

extension RealmProperty: Codable where Value: Codable {
    public convenience init(from decoder: Decoder) throws {
        self.init()
        self.value = try decoder.decodeOptional(Value.self)
    }

    public func encode(to encoder: Encoder) throws {
        try self.value.encode(to: encoder)
    }
}

/// A protocol describing types that can parameterize a `RealmPropertyType`.
public protocol RealmPropertyType: _ObjcBridgeable, _RealmSchemaDiscoverable { }

extension AnyRealmValue: RealmPropertyType { }
extension Optional: RealmPropertyType where Wrapped: RealmOptionalType & _RealmSchemaDiscoverable { }
