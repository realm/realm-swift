//
//  ThreadSafeReferenceTests.swift
//  Realm
//
//  Created by Jaden Geller on 9/9/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import XCTest
import RealmSwift

#if swift(>=3.0)

class ThreadSafeReferenceTests: TestCase {
    func testThreadSafeReferenceToObject() {
        let realm = try! Realm()
        let object = SwiftBoolObject()
        try! realm.write {
            realm.add(object)
        }
        XCTAssertEqual(false, object.boolCol)
        let objectRef = ThreadSafeReference(to: object)
        dispatchSyncNewThread {
            let realm = try! Realm()
            let object = realm.resolve(objectRef)!
            try! realm.write {
                object.boolCol = true
            }
        }
        XCTAssertEqual(false, object.boolCol)
        realm.refresh()
        XCTAssertEqual(true, object.boolCol)
    }

    func testThreadSafeReferencesToMultipleObjects() {
        let realm = try! Realm()
        let (stringObject, intObject) = (SwiftStringObject(), SwiftIntObject())
        try! realm.write {
            realm.add(stringObject)
            realm.add(intObject)
        }
        XCTAssertEqual("", stringObject.stringCol)
        XCTAssertEqual(0, intObject.intCol)
        let stringObjectRef = ThreadSafeReference(to: stringObject)
        let intObjectRef = ThreadSafeReference(to: intObject)
        dispatchSyncNewThread {
            let realm = try! Realm()
            let stringObject = realm.resolve(stringObjectRef)!
            let intObject = realm.resolve(intObjectRef)!
            try! realm.write {
                stringObject.stringCol = "the meaning of life"
                intObject.intCol = 42
            }
        }
        XCTAssertEqual("", stringObject.stringCol)
        XCTAssertEqual(0, intObject.intCol)
        realm.refresh()
        XCTAssertEqual("the meaning of life", stringObject.stringCol)
        XCTAssertEqual(42, intObject.intCol)
    }

    func testThreadSafeReferencesToMultipleThreadConfined() {
        let realm = try! Realm()
        let results = realm.objects(SwiftStringObject.self)
            .filter("stringCol != 'C'")
            .sorted(byProperty: "stringCol", ascending: false)
        let string = SwiftStringObject(value: ["hello world"])
        try! realm.write {
            realm.add(string)
        }
        XCTAssertEqual(1, results.count)
        XCTAssertEqual("hello world", results[0].stringCol)
        let stringRef = ThreadSafeReference(to: string)
        let resultsRef = ThreadSafeReference(to: results)
        dispatchSyncNewThread {
            let realm = try! Realm()
            let string = realm.resolve(stringRef)!
            let results = realm.resolve(resultsRef)!
            XCTAssertEqual(1, results.count)
            XCTAssertEqual("hello world", results[0].stringCol)

            try! realm.write {
                string.stringCol = "sup world"
            }
            XCTAssertEqual(1, results.count)
            XCTAssertEqual("sup world", results[0].stringCol)
        }
        XCTAssertEqual(1, results.count)
        XCTAssertEqual("hello world", results[0].stringCol)
        realm.refresh()
        XCTAssertEqual(1, results.count)
        XCTAssertEqual("sup world", results[0].stringCol)
    }

    func testHandoverList() {
        let realm = try! Realm()
        let company = SwiftCompanyObject()
        try! realm.write {
            realm.add(company)
            company.employees.append(SwiftEmployeeObject(value: ["name" : "jg"]))
        }
        XCTAssertEqual(1, company.employees.count)
        XCTAssertEqual("jg", company.employees[0].name)
        let listRef = ThreadSafeReference(to: company.employees)
        dispatchSyncNewThread {
            let realm = try! Realm()
            let employees = realm.resolve(listRef)!
            XCTAssertEqual(1, employees.count)
            XCTAssertEqual("jg", employees[0].name)

            try! realm.write {
                employees.removeAll()
                employees.append(SwiftEmployeeObject(value: ["name" : "jp"]))
                employees.append(SwiftEmployeeObject(value: ["name" : "az"]))
            }
            XCTAssertEqual(2, employees.count)
            XCTAssertEqual("jp", employees[0].name)
            XCTAssertEqual("az", employees[1].name)
        }
        XCTAssertEqual(1, company.employees.count)
        XCTAssertEqual("jg", company.employees[0].name)
        realm.refresh()
        XCTAssertEqual(2, company.employees.count)
        XCTAssertEqual("jp", company.employees[0].name)
        XCTAssertEqual("az", company.employees[1].name)
    }


    func testHandoverResults() {
        let realm = try! Realm()
        let results = realm.objects(SwiftStringObject.self)
            .filter("stringCol != 'C'")
            .sorted(byProperty: "stringCol", ascending: false)
        try! realm.write {
            realm.create(SwiftStringObject.self, value: ["A"])
            realm.create(SwiftStringObject.self, value: ["B"])
            realm.create(SwiftStringObject.self, value: ["C"])
            realm.create(SwiftStringObject.self, value: ["D"])
        }
        XCTAssertEqual(4, realm.objects(SwiftStringObject.self).count)
        XCTAssertEqual(3, results.count)
        XCTAssertEqual("D", results[0].stringCol)
        XCTAssertEqual("B", results[1].stringCol)
        XCTAssertEqual("A", results[2].stringCol)
        let resultsRef = ThreadSafeReference(to: results)
        dispatchSyncNewThread {
            let realm = try! Realm()
            let results = realm.resolve(resultsRef)!
            XCTAssertEqual(4, realm.objects(SwiftStringObject.self).count)
            XCTAssertEqual(3, results.count)
            XCTAssertEqual("D", results[0].stringCol)
            XCTAssertEqual("B", results[1].stringCol)
            XCTAssertEqual("A", results[2].stringCol)
            try! realm.write {
                realm.delete(results[2])
                realm.delete(results[0])
                realm.create(SwiftStringObject.self, value: ["E"])
            }
            XCTAssertEqual(3, realm.objects(SwiftStringObject.self).count)
            XCTAssertEqual(2, results.count)
            XCTAssertEqual("E", results[0].stringCol)
            XCTAssertEqual("B", results[1].stringCol)
        }
        XCTAssertEqual(4, realm.objects(SwiftStringObject.self).count)
        XCTAssertEqual(3, results.count)
        XCTAssertEqual("D", results[0].stringCol)
        XCTAssertEqual("B", results[1].stringCol)
        XCTAssertEqual("A", results[2].stringCol)
        realm.refresh()
        XCTAssertEqual(3, realm.objects(SwiftStringObject.self).count)
        XCTAssertEqual(2, results.count)
        XCTAssertEqual("E", results[0].stringCol)
        XCTAssertEqual("B", results[1].stringCol)
    }

    func testHandoverLinkingObjects() {
        let realm = try! Realm()
        let dogA = SwiftDogObject(value: ["dogName" : "Cookie", "age" : 10])
        let unaccessedDogB = SwiftDogObject(value: ["dogName" : "Skipper", "age" : 7])
        // Ensures that a `LinkingObjects` without cached results can be handed over

        try! realm.write {
            realm.add(SwiftOwnerObject(value: ["name" : "Andrea", "dog" : dogA]))
            realm.add(SwiftOwnerObject(value: ["name" : "Mike", "dog" : unaccessedDogB]))
        }
        XCTAssertEqual(1, dogA.owners.count)
        XCTAssertEqual("Andrea", dogA.owners[0].name)
        let ownersARef = ThreadSafeReference(to: dogA.owners)
        let ownersBRef = ThreadSafeReference(to: unaccessedDogB.owners)
        dispatchSyncNewThread {
            let realm = try! Realm()
            let ownersA = realm.resolve(ownersARef)!
            let ownersB = realm.resolve(ownersBRef)!

            XCTAssertEqual(1, ownersA.count)
            XCTAssertEqual("Andrea", ownersA[0].name)
            XCTAssertEqual(1, ownersB.count)
            XCTAssertEqual("Mike", ownersB[0].name)

            try! realm.write {
                (ownersA[0].dog, ownersB[0].dog) = (ownersB[0].dog, ownersA[0].dog)
            }
            XCTAssertEqual(1, ownersA.count)
            XCTAssertEqual("Mike", ownersA[0].name)
            XCTAssertEqual(1, ownersB.count)
            XCTAssertEqual("Andrea", ownersB[0].name)
        }
        XCTAssertEqual(1, dogA.owners.count)
        XCTAssertEqual("Andrea", dogA.owners[0].name)
        XCTAssertEqual(1, unaccessedDogB.owners.count)
        XCTAssertEqual("Mike", unaccessedDogB.owners[0].name)
        realm.refresh()
        XCTAssertEqual(1, dogA.owners.count)
        XCTAssertEqual("Mike", dogA.owners[0].name)
        XCTAssertEqual(1, unaccessedDogB.owners.count)
        XCTAssertEqual("Andrea", unaccessedDogB.owners[0].name)
    }

    func testHandoverAnyRealmCollection() {
        let realm = try! Realm()
        let company = SwiftCompanyObject()
        try! realm.write {
            realm.add(company)
            company.employees.append(SwiftEmployeeObject(value: ["name" : "A"]))
            company.employees.append(SwiftEmployeeObject(value: ["name" : "B"]))
            company.employees.append(SwiftEmployeeObject(value: ["name" : "C"]))
            company.employees.append(SwiftEmployeeObject(value: ["name" : "D"]))
        }
        let results = AnyRealmCollection(realm.objects(SwiftEmployeeObject.self)
            .filter("name != 'C'")
            .sorted(byProperty: "name", ascending: false))
        let list = AnyRealmCollection(company.employees)
        XCTAssertEqual(3, results.count)
        XCTAssertEqual("D", results[0].name)
        XCTAssertEqual("B", results[1].name)
        XCTAssertEqual("A", results[2].name)
        XCTAssertEqual(4, list.count)
        XCTAssertEqual("A", list[0].name)
        XCTAssertEqual("B", list[1].name)
        XCTAssertEqual("C", list[2].name)
        XCTAssertEqual("D", list[3].name)
        let resultsRef = ThreadSafeReference(to: results)
        let listRef = ThreadSafeReference(to: list)
        dispatchSyncNewThread {
            let realm = try! Realm()
            let results = realm.resolve(resultsRef)!
            let list = realm.resolve(listRef)!
            XCTAssertEqual(3, results.count)
            XCTAssertEqual("D", results[0].name)
            XCTAssertEqual("B", results[1].name)
            XCTAssertEqual("A", results[2].name)
            XCTAssertEqual(4, list.count)
            XCTAssertEqual("A", list[0].name)
            XCTAssertEqual("B", list[1].name)
            XCTAssertEqual("C", list[2].name)
            XCTAssertEqual("D", list[3].name)
        }
    }

    // TODO: Add test that invalidated object resolves to `nil`.
}

#else

// TODO: Add tests for Swift 2.

#endif
