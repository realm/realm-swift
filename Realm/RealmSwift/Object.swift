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
import Realm.Private

public class Object : RLMObjectBase, Equatable {
    // This is called by the obj-c accessor creation code, and if it's not
    // overriden in Swift, the inline property initializers don't get called,
    // and we require them for List<> properties
    public override init(realm: RLMRealm, schema: RLMObjectSchema, defaultValues: Bool) {
        super.init(realm: realm, schema: schema, defaultValues: defaultValues)
    }

    public override init(object: AnyObject, schema: RLMSchema) {
        super.init(object: object, schema: schema)
    }

    public override init(objectSchema: RLMObjectSchema) {
        super.init(objectSchema: objectSchema)
    }

    // And overriding that hides these
    public override init(object: AnyObject) {
        super.init(object: object)
    }

    public override init() {
        super.init()
    }

    public class func createInRealm(realm: Realm, withObject object: AnyObject) -> Self {
        return unsafeBitCast(RLMCreateObjectInRealmWithValue(realm.rlmRealm, className(), object, .allZeros), self)
    }
}

public func == <T: Object>(lhs: T, rhs: T) -> Bool {
    return lhs.isEqualToObject(rhs)
}

public class ObjectUtil : NSObject {
    // Get the names of all properties in the object which are of type List<>
    @objc private class func getGenericListPropertyNames(obj: AnyObject) -> NSArray {
        let reflection = reflect(obj)

        var properties = [String]()

        // Skip the first property (super):
        // super is an implicit property on Swift objects
        for i in 1..<reflection.count {
            let mirror = reflection[i].1
            if mirror.valueType is RLMListBase.Type {
                properties.append(reflection[i].0)
            }
        }

        return properties
    }

}
