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
import Realm.Private

/**
 This class represents Realm model object schemas.

 When using Realm, `ObjectSchema` instances allow performing migrations and introspecting the database's schema.

 Object schemas map to tables in the core database.
 */
@frozen public struct ObjectSchema: CustomStringConvertible {

    // MARK: Properties

    internal let rlmObjectSchema: RLMObjectSchema

    /**
     An array of `Property` instances representing the managed properties of a class described by the schema.

     - see: `Property`
     */
    public var properties: [Property] {
        return rlmObjectSchema.properties.map { Property($0) }
    }

    /// The name of the class the schema describes.
    public var className: String { return rlmObjectSchema.className }

    /// The object class the schema describes.
    public var objectClass: AnyClass { return rlmObjectSchema.objectClass }

    /// Whether this object is embedded.
    public var isEmbedded: Bool { return rlmObjectSchema.isEmbedded }

    /// Whether this object is asymmetric.
    public var isAsymmetric: Bool { return rlmObjectSchema.isAsymmetric }

    /// The property which serves as the primary key for the class the schema describes, if any.
    public var primaryKeyProperty: Property? {
        if let rlmProperty = rlmObjectSchema.primaryKeyProperty {
            return Property(rlmProperty)
        }
        return nil
    }

    /// A human-readable description of the properties contained in the object schema.
    public var description: String { return rlmObjectSchema.description }

    // MARK: Initializers

    internal init(_ rlmObjectSchema: RLMObjectSchema) {
        self.rlmObjectSchema = rlmObjectSchema
    }

    // MARK: Property Retrieval

    /// Returns the property with the given name, if it exists.
    public subscript(propertyName: String) -> Property? {
        if let rlmProperty = rlmObjectSchema[propertyName] {
            return Property(rlmProperty)
        }
        return nil
    }
}

// MARK: Equatable

extension ObjectSchema: Equatable {
    /// Returns whether the two object schemas are equal.
    public static func == (lhs: ObjectSchema, rhs: ObjectSchema) -> Bool {
        return lhs.rlmObjectSchema.isEqual(to: rhs.rlmObjectSchema)
    }
}
