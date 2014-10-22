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

public class ObjectSchema {
    // MARK: Properties

    var rlmObjectSchema: RLMObjectSchema
    public var className: String { return rlmObjectSchema.className }
    public var properties: [Property] { return rlmObjectSchema.properties as [Property] }

    // MARK: Initializers

    init(rlmObjectSchema: RLMObjectSchema) {
        self.rlmObjectSchema = rlmObjectSchema
    }

    // MARK: Property Retrieval

    public subscript(propertyName: String) -> Property {
        return Property(rlmProperty: rlmObjectSchema[className])
    }
}
