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

import Realm

public func ==(lhs: Schema, rhs: Schema) -> Bool {
    return lhs.rlmSchema.isEqualToSchema(rhs.rlmSchema)
}

public class Schema: Equatable {
    // MARK: Properties

    var rlmSchema: RLMSchema
    public var objectSchema: [ObjectSchema] { return rlmSchema.objectSchema as [ObjectSchema] }

    // MARK: Initializers

    init(rlmSchema: RLMSchema) {
        self.rlmSchema = rlmSchema
    }

    // MARK: ObjectSchema Retrieval

    public subscript(className: String) -> ObjectSchema? {
        if let rlmObjectSchema = rlmSchema.schemaForClassName(className) {
            return ObjectSchema(rlmObjectSchema: rlmObjectSchema)
        }
        return nil
    }
}
