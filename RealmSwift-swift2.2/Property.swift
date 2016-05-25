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
 `Property` instances represent properties persisted to Realm in the context of an object schema.

 When using Realm, `Property` instances allow performing migrations and introspecting the database's schema.

 These property instances map to columns in the core database.
*/
public final class Property: CustomStringConvertible {

    // MARK: Properties

    internal let rlmProperty: RLMProperty

    /// The name of the property.
    public var name: String { return rlmProperty.name }

    /// The type of the property.
    public var type: PropertyType { return rlmProperty.type }

    /// Indicates whether this property is indexed.
    public var indexed: Bool { return rlmProperty.indexed }

    /// Indicates whether this property is optional. (Note that certain numeric types must be wrapped in a
    /// `RealmOptional` instance in order to be declared as optional.)
    public var optional: Bool { return rlmProperty.optional }

    /// For `Object` and `List` properties, the name of the class of object stored in the property.
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

/// Returns whether the two property objects are equal.
public func == (lhs: Property, rhs: Property) -> Bool { // swiftlint:disable:this valid_docs
    return lhs.rlmProperty.isEqualToProperty(rhs.rlmProperty)
}
