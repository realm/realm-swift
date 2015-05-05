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
This class represents properties persisted to Realm in an ObjectSchema.

When using Realm, Property objects allow performing migrations and
introspecting the database's schema.

These properties map to columns in the core database.
*/
public final class Property: Printable {

    // MARK: Properties

    internal let rlmProperty: RLMProperty

    /// Property name.
    public var name: String { return rlmProperty.name }

    /// Property type.
    public var type: PropertyType { return rlmProperty.type }

    /// Whether this property is indexed.
    public var indexed: Bool { return rlmProperty.indexed }

    /// Object class name - specify object types for `Object` and `List` properties.
    public var objectClassName: String? { return rlmProperty.objectClassName }

    /// Returns a human-readable description of this property.
    public var description: String { return rlmProperty.description }

    // MARK: Initializers

    internal init(_ rlmProperty: RLMProperty) {
        self.rlmProperty = rlmProperty
    }
}

// MARK: Equatable

extension Property: Equatable {}

/// Returns whether the two properties are equal.
public func ==(lhs: Property, rhs: Property) -> Bool {
    return lhs.rlmProperty.isEqualToProperty(rhs.rlmProperty)
}
