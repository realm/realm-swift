////////////////////////////////////////////////////////////////////////////
//
// Copyright 2023 Realm Inc.
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

import RealmSwift

public class TestObject: Object {
    @Persisted public var name: String
}

public class SubRealm {
    public static func storeTestModel() throws {
        let realm = try Realm()
        let model = TestObject()
        model.name = "Test"
        try realm.write {
            realm.add(model)
        }
    }

    public static func findTestModel() throws -> TestObject? {
        let realm = try Realm()
        return realm.objects(TestObject.self).first
    }
}
