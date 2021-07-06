//
//  File.swift
//
//
//  Created by Pavel Yakimenko on 01/07/2021.
//

import Foundation
import Realm
import RealmSwift
import XCTest

#if canImport(RealmTestSupport)
import RealmTestSupport
#endif
//import XCTest
//
//import RealmSwift
//
//#if canImport(RealmTestSupport)
//import RealmTestSupport
//#endif

//class SwiftEmployeeObject: Object {
//    @objc dynamic var name = ""
//    @objc dynamic var age = 0
//    @objc dynamic var hired = false
//
//    convenience init(_ age: Int, _ name: String, _ hired: Bool) {
//        self.init()
//        self.age = age
//        self.name = name
//        self.hired = hired
//    }
//}
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
