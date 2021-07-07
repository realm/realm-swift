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
import RealmSwift
import XCTest

#if canImport(RealmTestSupport)
import RealmTestSupport
#endif

extension SwiftEmployeeObject {
    convenience init(_ age: Int, _ name: String, _ hired: Bool) {
        self.init()
        self.age = age
        self.name = name
        self.hired = hired
    }
}

class CompanyModel: RealmProjection<SwiftCompanyObject> {
    init(object: SwiftCompanyObject) {
        super.init(object: object, associations: [.asis(projectedName: "title")])
    }
}

class ProjectionTests: TestCase {

    func addData() {
        let realm = realmWithTestPath()
        try! realm.write {
            realm.add([SwiftEmployeeObject(40, "Joe", true),
                       SwiftEmployeeObject(30, "John", false),
                       SwiftEmployeeObject(25, "Jill", true)])

            let company = SwiftCompanyObject()
            company.title = "Test title"
            realm.add([company])
            company.employees.append(objectsIn: realm.objects(SwiftEmployeeObject.self))
        }
    }

    func testCreateProjection() {
        addData()
        let realm = realmWithTestPath()
        let companies = realm.objects(SwiftCompanyObject.self)
        var models = [CompanyModel]()
        for obj in companies {
            models.append(CompanyModel(object: obj))
        }
        XCTAssertEqual(models.count, 1)
        XCTAssertEqual(models.first!.title as! String, "Test title")
        let model = CompanyModel(object: companies.first!)
        XCTAssertEqual(model.title as! String, "Test title")
    }
}
