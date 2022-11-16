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
import Realm

/**
 `Property` instances represent properties managed by a Realm in the context of an object schema. Such properties may be
 persisted to a Realm file or computed from other data in the Realm.

 When using Realm, property instances allow performing migrations and introspecting the database's schema.

 Property instances map to columns in the core database.
 */
@frozen public struct Property: CustomStringConvertible {
    // MARK: Properties

    internal let rlmProperty: RLMProperty

    /// The name of the property.
    public var name: String { return rlmProperty.name }

    /// The column name of the property in the database. This will be the same as the property name when no
    /// private name is provided on the property mapping.
    public var columnName: String { return rlmProperty.columnName ?? name }

    /// The type of the property.
    public var type: PropertyType { return rlmProperty.type }

    /// Indicates whether this property is an array of the property type.
    public var isArray: Bool { return rlmProperty.array }

    /// Indicates whether this property is a set of the property type.
    public var isSet: Bool { return rlmProperty.set }

    /// Indicates whether this property is a dictionary of the property type.
    public var isMap: Bool { return rlmProperty.dictionary }

    /// Indicates whether this property is indexed.
    public var isIndexed: Bool { return rlmProperty.indexed }

    /// Indicates whether this property is optional. (Note that certain numeric types must be wrapped in a
    /// `RealmOptional` instance in order to be declared as optional.)
    public var isOptional: Bool { return rlmProperty.optional }

    /// For `Object` and `List` properties, the name of the class of object stored in the property.
    public var objectClassName: String? { return rlmProperty.objectClassName }

    /// A human-readable description of the property object.
    public var description: String { return rlmProperty.description }

    // MARK: Initializers

    internal init(_ rlmProperty: RLMProperty) {
        self.rlmProperty = rlmProperty
    }
}

// MARK: Equatable

extension Property: Equatable {
    /// Returns whether the two properties are equal.
    public static func == (lhs: Property, rhs: Property) -> Bool {
        return lhs.rlmProperty.isEqual(to: rhs.rlmProperty)
    }
}
