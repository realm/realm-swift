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
 `Schema` instances represent collections of model object schemas managed by a Realm.

 When using Realm, `Schema` instances allow performing migrations and introspecting the database's schema.

 Schemas map to collections of tables in the core database.
 */
@frozen public struct Schema: CustomStringConvertible {

    // MARK: Properties

    internal let rlmSchema: RLMSchema

    /**
     An array of `ObjectSchema`s for all object types in the Realm.

     This property is intended to be used during migrations for dynamic introspection.
     */
    public var objectSchema: [ObjectSchema] {
        return rlmSchema.objectSchema.map(ObjectSchema.init)
    }

    /// A human-readable description of the object schemas contained within.
    public var description: String { return rlmSchema.description }

    // MARK: Initializers

    internal init(_ rlmSchema: RLMSchema) {
        self.rlmSchema = rlmSchema
    }

    // MARK: ObjectSchema Retrieval

    /// Looks up and returns an `ObjectSchema` for the given class name in the Realm, if it exists.
    public subscript(className: String) -> ObjectSchema? {
        if let rlmObjectSchema = rlmSchema.schema(forClassName: className) {
            return ObjectSchema(rlmObjectSchema)
        }
        return nil
    }
}

// MARK: Equatable

extension Schema: Equatable {
    /// Returns whether the two schemas are equal.
    public static func == (lhs: Schema, rhs: Schema) -> Bool {
        return lhs.rlmSchema.isEqual(to: rhs.rlmSchema)
    }
}
