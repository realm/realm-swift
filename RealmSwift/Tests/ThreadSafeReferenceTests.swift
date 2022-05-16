////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
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

import XCTest
import RealmSwift

class ThreadSafeReferenceTests: TestCase {
    /// Resolve a thread-safe reference confirming that you can't resolve it a second time.
    func assertResolve<T>(_ realm: Realm, _ reference: ThreadSafeReference<T>) -> T? {
        XCTAssertFalse(reference.isInvalidated)
        let object = realm.resolve(reference)
        XCTAssert(reference.isInvalidated)
        assertThrows(realm.resolve(reference), reason: "Can only resolve a thread safe reference once")
        return object
    }

    func testInvalidThreadSafeReferenceConstruction() {
        let stringObject = SwiftStringObject()
        let arrayParent = SwiftArrayPropertyObject(value: ["arrayObject", [["a"]], []])
        let arrayObject = arrayParent.array
        let setParent = SwiftMutableSetPropertyObject(value: ["setObject", [["a"]], []])
        let setObject = setParent.set

        assertThrows(ThreadSafeReference(to: stringObject), reason: "Cannot construct reference to unmanaged object")
        assertThrows(ThreadSafeReference(to: arrayObject), reason: "Cannot construct reference to unmanaged object")
        assertThrows(ThreadSafeReference(to: setObject), reason: "Cannot construct reference to unmanaged object")

        let realm = try! Realm()
        realm.beginWrite()
        realm.add(stringObject)
        realm.add(arrayParent)
        realm.add(setParent)
        realm.deleteAll()
        try! realm.commitWrite()

        assertThrows(ThreadSafeReference(to: stringObject), reason: "Cannot construct reference to invalidated object")
        assertThrows(ThreadSafeReference(to: arrayObject), reason: "Cannot construct reference to invalidated object")
        assertThrows(ThreadSafeReference(to: setObject), reason: "Cannot construct reference to invalidated object")
    }

    func testInvalidThreadSafeReferenceUsage() {
        let realm = try! Realm()
        realm.beginWrite()
        let stringObject = realm.create(SwiftStringObject.self, value: ["stringCol": "hello"])
        let ref1 = ThreadSafeReference(to: stringObject)
        try! realm.commitWrite()
        let ref2 = ThreadSafeReference(to: stringObject)
        let ref3 = ThreadSafeReference(to: stringObject)
        dispatchSyncNewThread {
            XCTAssertNil(self.realmWithTestPath().resolve(ref1))
            let realm = try! Realm()
            _ = realm.resolve(ref2)
            self.assertThrows(realm.resolve(ref2),
                              reason: "Can only resolve a thread safe reference once")
            // Assert that we can resolve a different reference to the same object.
            XCTAssertEqual(self.assertResolve(realm, ref3)!.stringCol, "hello")
        }
    }

    func testPassThreadSafeReferenceToDeletedObject() {
        let realm = try! Realm()
        let intObject = SwiftIntObject()
        try! realm.write {
            realm.add(intObject)
        }
        let ref1 = ThreadSafeReference(to: intObject)
        let ref2 = ThreadSafeReference(to: intObject)
        XCTAssertEqual(0, intObject.intCol)
        try! realm.write {
            realm.delete(intObject)
        }
        dispatchSyncNewThread {
            let realm = try! Realm()
            XCTAssertEqual(self.assertResolve(realm, ref1)!.intCol, 0)
            realm.refresh()
            XCTAssertNil(self.assertResolve(realm, ref2))
        }
    }

    func testPassThreadSafeReferencesToMultipleObjects() {
        let realm = try! Realm()
        let (stringObject, intObject) = (SwiftStringObject(), SwiftIntObject())
        try! realm.write {
            realm.add(stringObject)
            realm.add(intObject)
        }
        let stringObjectRef = ThreadSafeReference(to: stringObject)
        let intObjectRef = ThreadSafeReference(to: intObject)
        XCTAssertEqual("", stringObject.stringCol)
        XCTAssertEqual(0, intObject.intCol)
        dispatchSyncNewThread {
            let realm = try! Realm()
            let stringObject = self.assertResolve(realm, stringObjectRef)!
            let intObject = self.assertResolve(realm, intObjectRef)!
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

    func testPassThreadSafeReferenceToList() {
        let realm = try! Realm()
        let company = SwiftCompanyObject()
        try! realm.write {
            realm.add(company)
            company.employees.append(SwiftEmployeeObject(value: ["name": "jg"]))
        }
        XCTAssertEqual(1, company.employees.count)
        XCTAssertEqual("jg", company.employees[0].name)
        let listRef = ThreadSafeReference(to: company.employees)
        dispatchSyncNewThread {
            let realm = try! Realm()
            let employees = self.assertResolve(realm, listRef)!
            XCTAssertEqual(1, employees.count)
            XCTAssertEqual("jg", employees[0].name)

            try! realm.write {
                employees.removeAll()
                employees.append(SwiftEmployeeObject(value: ["name": "jp"]))
                employees.append(SwiftEmployeeObject(value: ["name": "az"]))
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

    func testPassThreadSafeReferenceToMutableSet() {
        let realm = try! Realm()
        let company = SwiftCompanyObject()
        try! realm.write {
            realm.add(company)
            company.employeeSet.insert(SwiftEmployeeObject(value: ["name": "jg"]))
        }
        XCTAssertEqual(1, company.employeeSet.count)
        XCTAssertEqual("jg", company.employeeSet[0].name)
        let setRef = ThreadSafeReference(to: company.employeeSet)
        dispatchSyncNewThread {
            let realm = try! Realm()
            let employeeSet = self.assertResolve(realm, setRef)!
            XCTAssertEqual(1, employeeSet.count)
            XCTAssertEqual("jg", employeeSet[0].name)

            try! realm.write {
                employeeSet.removeAll()
                employeeSet.insert(SwiftEmployeeObject(value: ["name": "jp"]))
                employeeSet.insert(SwiftEmployeeObject(value: ["name": "az"]))
            }
            XCTAssertEqual(2, employeeSet.count)
            self.assertSetContains(employeeSet, keyPath: \.name, items: ["jp", "az"])
        }
        XCTAssertEqual(1, company.employeeSet.count)
        XCTAssertEqual("jg", company.employeeSet[0].name)
        realm.refresh()
        XCTAssertEqual(2, company.employeeSet.count)
        assertSetContains(company.employeeSet, keyPath: \.name, items: ["jp", "az"])
    }

    func testPassThreadSafeReferenceToResults() {
        let realm = try! Realm()
        let allObjects = realm.objects(SwiftStringObject.self)
        let results = allObjects
            .filter("stringCol != 'C'")
            .sorted(byKeyPath: "stringCol", ascending: false)
        let resultsRef = ThreadSafeReference(to: results)
        try! realm.write {
            realm.create(SwiftStringObject.self, value: ["A"])
            realm.create(SwiftStringObject.self, value: ["B"])
            realm.create(SwiftStringObject.self, value: ["C"])
            realm.create(SwiftStringObject.self, value: ["D"])
        }
        XCTAssertEqual(4, allObjects.count)
        XCTAssertEqual(3, results.count)
        XCTAssertEqual("D", results[0].stringCol)
        XCTAssertEqual("B", results[1].stringCol)
        XCTAssertEqual("A", results[2].stringCol)
        dispatchSyncNewThread {
            let realm = try! Realm()
            let results = self.assertResolve(realm, resultsRef)!
            let allObjects = realm.objects(SwiftStringObject.self)
            XCTAssertEqual(0, allObjects.count)
            XCTAssertEqual(0, results.count)
            realm.refresh()
            XCTAssertEqual(4, allObjects.count)
            XCTAssertEqual(3, results.count)
            XCTAssertEqual("D", results[0].stringCol)
            XCTAssertEqual("B", results[1].stringCol)
            XCTAssertEqual("A", results[2].stringCol)
            try! realm.write {
                realm.delete(results[2])
                realm.delete(results[0])
                realm.create(SwiftStringObject.self, value: ["E"])
            }
            XCTAssertEqual(3, allObjects.count)
            XCTAssertEqual(2, results.count)
            XCTAssertEqual("E", results[0].stringCol)
            XCTAssertEqual("B", results[1].stringCol)
        }
        XCTAssertEqual(4, allObjects.count)
        XCTAssertEqual(3, results.count)
        XCTAssertEqual("D", results[0].stringCol)
        XCTAssertEqual("B", results[1].stringCol)
        XCTAssertEqual("A", results[2].stringCol)
        realm.refresh()
        XCTAssertEqual(3, allObjects.count)
        XCTAssertEqual(2, results.count)
        XCTAssertEqual("E", results[0].stringCol)
        XCTAssertEqual("B", results[1].stringCol)
    }

    func testPassThreadSafeReferenceToLinkingObjects() {
        let realm = try! Realm()
        let dogA = SwiftDogObject(value: ["dogName": "Cookie", "age": 10])
        let unaccessedDogB = SwiftDogObject(value: ["dogName": "Skipper", "age": 7])
        // Ensures that a `LinkingObjects` without cached results can be handed over

        try! realm.write {
            realm.add(SwiftOwnerObject(value: ["name": "Andrea", "dog": dogA]))
            realm.add(SwiftOwnerObject(value: ["name": "Mike", "dog": unaccessedDogB]))
        }
        XCTAssertEqual(1, dogA.owners.count)
        XCTAssertEqual("Andrea", dogA.owners[0].name)
        let ownersARef = ThreadSafeReference(to: dogA.owners)
        let ownersBRef = ThreadSafeReference(to: unaccessedDogB.owners)
        dispatchSyncNewThread {
            let realm = try! Realm()
            let ownersA = self.assertResolve(realm, ownersARef)!
            let ownersB = self.assertResolve(realm, ownersBRef)!

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

    func testPassThreadSafeReferenceToAnyRealmCollection() {
        let realm = try! Realm()
        let company = SwiftCompanyObject()
        try! realm.write {
            realm.add(company)
            company.employees.append(SwiftEmployeeObject(value: ["name": "A"]))
            company.employees.append(SwiftEmployeeObject(value: ["name": "B"]))
            company.employees.append(SwiftEmployeeObject(value: ["name": "C"]))
            company.employees.append(SwiftEmployeeObject(value: ["name": "D"]))
            company.employeeSet.insert(SwiftEmployeeObject(value: ["name": "A"]))
            company.employeeSet.insert(SwiftEmployeeObject(value: ["name": "B"]))
            company.employeeSet.insert(SwiftEmployeeObject(value: ["name": "C"]))
            company.employeeSet.insert(SwiftEmployeeObject(value: ["name": "D"]))
        }
        let results = AnyRealmCollection(realm.objects(SwiftEmployeeObject.self)
            .filter("name != 'C'")
            .sorted(byKeyPath: "name", ascending: false))
        let list = AnyRealmCollection(company.employees)
        let set = AnyRealmCollection(company.employeeSet)
        XCTAssertEqual(6, results.count)
        XCTAssertEqual("D", results[0].name)
        XCTAssertEqual("D", results[1].name)
        XCTAssertEqual("B", results[2].name)
        XCTAssertEqual(4, list.count)
        XCTAssertEqual("A", list[0].name)
        XCTAssertEqual("B", list[1].name)
        XCTAssertEqual("C", list[2].name)
        XCTAssertEqual("D", list[3].name)
        XCTAssertEqual(4, set.count)
        assertAnyRealmCollectionContains(set, keyPath: \.name, items: ["A", "B", "C", "D"])
        let resultsRef = ThreadSafeReference(to: results)
        let listRef = ThreadSafeReference(to: list)
        let setRef = ThreadSafeReference(to: set)
        dispatchSyncNewThread {
            let realm = try! Realm()
            let results = self.assertResolve(realm, resultsRef)!
            let list = self.assertResolve(realm, listRef)!
            let set = self.assertResolve(realm, setRef)!
            XCTAssertEqual(6, results.count)
            XCTAssertEqual("D", results[0].name)
            XCTAssertEqual("D", results[1].name)
            XCTAssertEqual("B", results[2].name)
            XCTAssertEqual(4, list.count)
            XCTAssertEqual("A", list[0].name)
            XCTAssertEqual("B", list[1].name)
            XCTAssertEqual("C", list[2].name)
            XCTAssertEqual("D", list[3].name)
            XCTAssertEqual(4, set.count)
            self.assertAnyRealmCollectionContains(set, keyPath: \.name, items: ["A", "B", "C", "D"])
        }
    }
}

// MARK: TestThreadSafeWrappersStruct
struct TestThreadSafeWrapperStruct {
    @ThreadSafe var stringObject: SwiftStringObject?
    @ThreadSafe var intObject: SwiftIntObject?
    @ThreadSafe var employees: List<SwiftEmployeeObject>?
    @ThreadSafe var stringMap: Map<String, SwiftStringObject?>?
    @ThreadSafe var employeeSet: MutableSet<SwiftEmployeeObject>?
    @ThreadSafe var owners: LinkingObjects<SwiftOwnerObject>?
    @ThreadSafe var results: Results<SwiftStringObject>?

    @ThreadSafe var arcResults: AnyRealmCollection<SwiftEmployeeObject>?
    @ThreadSafe var arcList: AnyRealmCollection<SwiftEmployeeObject>?
    @ThreadSafe var arcSet: AnyRealmCollection<SwiftEmployeeObject>?
}

// MARK: ThreadSafeWrapperTests
class ThreadSafeWrapperTests: ThreadSafeReferenceTests {
    func wrapperStruct() -> TestThreadSafeWrapperStruct {
        let realm = try! Realm()
        var stringObj: SwiftStringObject?, intObj: SwiftIntObject?
        try! realm.write({
            stringObj = realm.create(SwiftStringObject.self, value: ["stringCol": "before"])
            intObj = realm.create(SwiftIntObject.self, value: ["intCol": 1])
        })
        return TestThreadSafeWrapperStruct(stringObject: stringObj, intObject: intObj)
    }

    func testThreadSafeWrapperInvalidConstruction() {
        let unmanagedObj = SwiftStringObject(value: ["stringCol": "before"])
        assertThrows(TestThreadSafeWrapperStruct(stringObject: unmanagedObj), reason: "Only managed objects may be wrapped as thread safe.")
    }

    func testThreadSafeWrapper() {
        let testStruct = wrapperStruct()
        XCTAssertEqual(testStruct.stringObject!.stringCol, "before")
        XCTAssertEqual(testStruct.intObject!.intCol, 1)

        dispatchSyncNewThread {
            try! Realm().write({
                testStruct.stringObject!.stringCol = "after"
                testStruct.intObject!.intCol = 2
            })
        }
        XCTAssertEqual(testStruct.stringObject!.stringCol, "after")
        XCTAssertEqual(testStruct.intObject!.intCol, 2)

        // Edit value again to test the same thread safe reference isn't resolved twice
        dispatchSyncNewThread {
            try! Realm().write({
                testStruct.stringObject!.stringCol = "after, again"
                testStruct.intObject!.intCol = 3
            })
        }
        XCTAssertEqual(testStruct.stringObject!.stringCol, "after, again")
        XCTAssertEqual(testStruct.intObject!.intCol, 3)
    }

    func testThreadSafeWrapperDeleteObject() {
        let testStruct = wrapperStruct()
        XCTAssertEqual(testStruct.stringObject!.stringCol, "before")
        XCTAssertEqual(testStruct.intObject!.intCol, 1)

        dispatchSyncNewThread {
            let realm = try! Realm()
            try! realm.write({
                realm.delete(testStruct.stringObject!)
                realm.delete(testStruct.intObject!)
            })
        }
        XCTAssertNil(testStruct.stringObject)
        XCTAssertNil(testStruct.intObject)
    }

    func testThreadSafeWrapperReassign() {
        let testStruct = wrapperStruct()
        XCTAssertEqual(testStruct.stringObject!.stringCol, "before")
        XCTAssertEqual(testStruct.intObject!.intCol, 1)

        dispatchSyncNewThread {
            let realm = try! Realm()
            try! realm.write({
                let stringObj = realm.create(SwiftStringObject.self, value: ["stringCol": "after"])
                let intObj = realm.create(SwiftIntObject.self, value: ["intCol": 2])

                testStruct.stringObject = stringObj
                testStruct.intObject = intObj
            })
        }
        XCTAssertEqual(testStruct.stringObject!.stringCol, "after")
        XCTAssertEqual(testStruct.intObject!.intCol, 2)
    }

    func testThreadSafeWrapperReassignToNil() {
        let testStruct = wrapperStruct()
        XCTAssertEqual(testStruct.stringObject!.stringCol, "before")
        XCTAssertEqual(testStruct.intObject!.intCol, 1)

        dispatchSyncNewThread {
            let realm = try! Realm()
            try! realm.write({
                testStruct.stringObject = nil
                testStruct.intObject = nil
            })
        }
        XCTAssertNil(testStruct.stringObject)
        XCTAssertNil(testStruct.intObject)

        dispatchSyncNewThread {
            let realm = try! Realm()
            try! realm.write({
                testStruct.stringObject = realm.create(SwiftStringObject.self, value: ["stringCol": "after, again"])
                testStruct.intObject = realm.create(SwiftIntObject.self, value: ["intCol": 3])
            })
        }
        XCTAssertEqual(testStruct.stringObject!.stringCol, "after, again")
        XCTAssertEqual(testStruct.intObject!.intCol, 3)
    }

    func testThreadSafeWrapperNilConstruction() {
        let testStruct = TestThreadSafeWrapperStruct(stringObject: nil, intObject: nil)
        XCTAssertEqual(testStruct.stringObject, nil)
        XCTAssertEqual(testStruct.intObject, nil)

        var config = Realm.Configuration.defaultConfiguration
        config.objectTypes = [SwiftStringObject.self, SwiftIntObject.self]
        dispatchSyncNewThread {
            let realm = try! Realm(configuration: config)
            try! realm.write({
                testStruct.stringObject = realm.create(SwiftStringObject.self, value: ["stringCol": "after"])
                testStruct.intObject = realm.create(SwiftIntObject.self, value: ["intCol": 2])
            })
        }
        XCTAssertEqual(testStruct.stringObject!.stringCol, "after")
        XCTAssertEqual(testStruct.intObject!.intCol, 2)

        // Edit value again to test the same thread safe reference isn't resolved twice
        dispatchSyncNewThread {
            let realm = try! Realm(configuration: config)
            try! realm.write({
                testStruct.stringObject!.stringCol = "after, again"
                testStruct.intObject!.intCol = 3
            })
        }
        XCTAssertEqual(testStruct.stringObject!.stringCol, "after, again")
        XCTAssertEqual(testStruct.intObject!.intCol, 3)
    }

    func testThreadSafeWrapperDifferentConfig() {
        let testStruct = wrapperStruct()
        XCTAssertEqual(testStruct.stringObject!.stringCol, "before")
        XCTAssertEqual(testStruct.intObject!.intCol, 1)

        dispatchSyncNewThread {
            var config = Realm.Configuration.defaultConfiguration
            config.fileURL = config.fileURL!.deletingLastPathComponent().appendingPathComponent("newpath.realm")
            config.objectTypes = [SwiftEmployeeObject.self,
                                  SwiftStringObject.self,
                                  SwiftIntObject.self]

            let realm = try! Realm(configuration: config) // Different realm config than original
            try! realm.write({
                let stringObj = realm.create(SwiftStringObject.self, value: ["stringCol": "after"])
                let intObj = realm.create(SwiftIntObject.self, value: ["intCol": 2])

                testStruct.stringObject = stringObj
                testStruct.intObject = intObj
            })
        }
        XCTAssertEqual(testStruct.stringObject!.stringCol, "after")
        XCTAssertEqual(testStruct.intObject!.intCol, 2)
    }

    func testThreadSafeWrapperInvalidReassign() {
        let testStruct = wrapperStruct()
        XCTAssertEqual(testStruct.stringObject!.stringCol, "before")
        XCTAssertEqual(testStruct.intObject!.intCol, 1)

        dispatchSyncNewThread {
            let realm = try! Realm()
            try! realm.write {
                self.assertThrows(testStruct.stringObject = SwiftStringObject(),
                                  reason: "Only managed objects may be wrapped as thread safe.")
            }
        }
    }

    func testThreadSafeWrapperToList() {
        let realm = try! Realm()
        let company = SwiftCompanyObject()
        try! realm.write {
            realm.add(company)
            company.employees.append(SwiftEmployeeObject(value: ["name": "jg"]))
        }

        XCTAssertEqual(1, company.employees.count)
        XCTAssertEqual("jg", company.employees[0].name)
        let testStruct = TestThreadSafeWrapperStruct(employees: company.employees)
        dispatchSyncNewThread {
            let realm = try! Realm()
            XCTAssertEqual(1, testStruct.employees!.count)
            XCTAssertEqual("jg", testStruct.employees![0].name)

            try! realm.write {
                testStruct.employees!.removeAll()
                testStruct.employees!.append(SwiftEmployeeObject(value: ["name": "jp"]))
                testStruct.employees!.append(SwiftEmployeeObject(value: ["name": "az"]))
            }
            XCTAssertEqual(2, testStruct.employees!.count)
            XCTAssertEqual("jp", testStruct.employees![0].name)
            XCTAssertEqual("az", testStruct.employees![1].name)
        }
        XCTAssertEqual(2, testStruct.employees!.count)
        XCTAssertEqual("jp", testStruct.employees![0].name)
        XCTAssertEqual("az", testStruct.employees![1].name)
    }

    func testThreadSafeWrapperToMap() {
        let testStruct = TestThreadSafeWrapperStruct()
        let realm = try! Realm()
        try! realm.write {
            let mapObject = SwiftMapObject()
            mapObject.object["before"] = realm.create(SwiftStringObject.self, value: ["stringCol": "first"])
            realm.add(mapObject)
            testStruct.stringMap = mapObject.object
        }
        dispatchSyncNewThread {
            XCTAssertEqual(testStruct.stringMap?.count, 1)
            XCTAssertEqual(testStruct.stringMap?["before"]??.stringCol, "first")
            let realm = try! Realm()
            try! realm.write {
                let swiftStringObject = realm.create(SwiftStringObject.self, value: ["stringCol": "second"])
                testStruct.stringMap!["after"] = swiftStringObject
            }
        }
        XCTAssertEqual(testStruct.stringMap?.count, 2)
        XCTAssertEqual(testStruct.stringMap?["before"]??.stringCol, "first")
        XCTAssertEqual(testStruct.stringMap?["after"]??.stringCol, "second")
    }

    func testThreadSafeWrapperToMutableSet() {
        let realm = try! Realm()
        let company = SwiftCompanyObject()
        try! realm.write {
            realm.add(company)
            company.employeeSet.insert(SwiftEmployeeObject(value: ["name": "jg"]))
        }
        XCTAssertEqual(1, company.employeeSet.count)
        XCTAssertEqual("jg", company.employeeSet[0].name)
        let testStruct = TestThreadSafeWrapperStruct(employeeSet: company.employeeSet)
        dispatchSyncNewThread {
            let realm = try! Realm()
            XCTAssertEqual(1, testStruct.employeeSet!.count)
            XCTAssertEqual("jg", testStruct.employeeSet![0].name)

            try! realm.write {
                testStruct.employeeSet!.removeAll()
                testStruct.employeeSet!.insert(SwiftEmployeeObject(value: ["name": "jp"]))
                testStruct.employeeSet!.insert(SwiftEmployeeObject(value: ["name": "az"]))
            }
            XCTAssertEqual(2, testStruct.employeeSet!.count)
            self.assertSetContains(testStruct.employeeSet!, keyPath: \.name, items: ["jp", "az"])
        }
        XCTAssertEqual(2, testStruct.employeeSet!.count)
        assertSetContains(testStruct.employeeSet!, keyPath: \.name, items: ["jp", "az"])
    }

    func testThreadSafeWrapperToResults() {
        let realm = try! Realm()
        let allObjects = realm.objects(SwiftStringObject.self)
        let results = allObjects
            .filter("stringCol != 'C'")
            .sorted(byKeyPath: "stringCol", ascending: false)
        let resultsStruct = TestThreadSafeWrapperStruct(results: results)
        try! realm.write {
            realm.create(SwiftStringObject.self, value: ["A"])
            realm.create(SwiftStringObject.self, value: ["B"])
            realm.create(SwiftStringObject.self, value: ["C"])
            realm.create(SwiftStringObject.self, value: ["D"])
        }
        XCTAssertEqual(4, allObjects.count)
        XCTAssertEqual(3, resultsStruct.results!.count)
        XCTAssertEqual("D", resultsStruct.results![0].stringCol)
        XCTAssertEqual("B", resultsStruct.results![1].stringCol)
        XCTAssertEqual("A", resultsStruct.results![2].stringCol)
        dispatchSyncNewThread {
            let realm = try! Realm()
            let allObjects = realm.objects(SwiftStringObject.self)
            XCTAssertEqual(4, allObjects.count)
            XCTAssertEqual(3, resultsStruct.results!.count)
            XCTAssertEqual("D", resultsStruct.results![0].stringCol)
            XCTAssertEqual("B", resultsStruct.results![1].stringCol)
            XCTAssertEqual("A", resultsStruct.results![2].stringCol)
            try! realm.write {
                realm.delete(resultsStruct.results![2])
                realm.delete(resultsStruct.results![0])
                realm.create(SwiftStringObject.self, value: ["E"])
            }
            XCTAssertEqual(3, allObjects.count)
            XCTAssertEqual(2, resultsStruct.results!.count)
            XCTAssertEqual("E", resultsStruct.results![0].stringCol)
            XCTAssertEqual("B", resultsStruct.results![1].stringCol)
        }
        realm.refresh()
        XCTAssertEqual(3, allObjects.count)
        XCTAssertEqual(2, resultsStruct.results!.count)
        XCTAssertEqual("E", resultsStruct.results![0].stringCol)
        XCTAssertEqual("B", resultsStruct.results![1].stringCol)
    }

    func testThreadSafeWrapperLinkingObjects() {
        let realm = try! Realm()
        let dog = SwiftDogObject(value: ["dogName": "Cookie", "age": 10])

        try! realm.write {
            realm.add(SwiftOwnerObject(value: ["name": "Andrea", "dog": dog]))
        }

        let linkingObjectsStruct = TestThreadSafeWrapperStruct(owners: dog.owners)
        XCTAssertEqual(1, linkingObjectsStruct.owners!.count)
        XCTAssertEqual("Andrea", linkingObjectsStruct.owners![0].name)
        dispatchSyncNewThread {
            let realm = try! Realm()
            XCTAssertEqual(1, linkingObjectsStruct.owners!.count)
            XCTAssertEqual("Andrea", linkingObjectsStruct.owners![0].name)

            try! realm.write {
                linkingObjectsStruct.owners![0].name = "Mike"
            }
            XCTAssertEqual(1, linkingObjectsStruct.owners!.count)
            XCTAssertEqual("Mike", linkingObjectsStruct.owners![0].name)
        }
        XCTAssertEqual(1, linkingObjectsStruct.owners!.count)
        XCTAssertEqual("Mike", linkingObjectsStruct.owners![0].name)
    }

    func testThreadSafeWrapperToAnyRealmCollection() {
        let realm = try! Realm()
        let company = SwiftCompanyObject()
        try! realm.write {
            realm.add(company)
            company.employees.append(SwiftEmployeeObject(value: ["name": "A"]))
            company.employees.append(SwiftEmployeeObject(value: ["name": "B"]))
            company.employees.append(SwiftEmployeeObject(value: ["name": "C"]))
            company.employees.append(SwiftEmployeeObject(value: ["name": "D"]))
            company.employeeSet.insert(SwiftEmployeeObject(value: ["name": "A"]))
            company.employeeSet.insert(SwiftEmployeeObject(value: ["name": "B"]))
            company.employeeSet.insert(SwiftEmployeeObject(value: ["name": "C"]))
            company.employeeSet.insert(SwiftEmployeeObject(value: ["name": "D"]))
        }

        let testStruct = TestThreadSafeWrapperStruct(arcResults: AnyRealmCollection(realm.objects(SwiftEmployeeObject.self)
                                                                                            .filter("name != 'C'")
                                                                                            .sorted(byKeyPath: "name", ascending: false)),
                                                          arcList: AnyRealmCollection(company.employees),
                                                          arcSet: AnyRealmCollection(company.employeeSet))

        XCTAssertEqual(6, testStruct.arcResults!.count)
        XCTAssertEqual("D", testStruct.arcResults![0].name)
        XCTAssertEqual("D", testStruct.arcResults![1].name)
        XCTAssertEqual("B", testStruct.arcResults![2].name)
        XCTAssertEqual(4, testStruct.arcList!.count)
        XCTAssertEqual("A", testStruct.arcList![0].name)
        XCTAssertEqual("B", testStruct.arcList![1].name)
        XCTAssertEqual("C", testStruct.arcList![2].name)
        XCTAssertEqual("D", testStruct.arcList![3].name)
        XCTAssertEqual(4, testStruct.arcSet!.count)
        assertAnyRealmCollectionContains(testStruct.arcSet!, keyPath: \.name, items: ["A", "B", "C", "D"])

        dispatchSyncNewThread {
            XCTAssertEqual(6, testStruct.arcResults!.count)
            XCTAssertEqual("D", testStruct.arcResults![0].name)
            XCTAssertEqual("D", testStruct.arcResults![1].name)
            XCTAssertEqual("B", testStruct.arcResults![2].name)
            XCTAssertEqual(4, testStruct.arcList!.count)
            XCTAssertEqual("A", testStruct.arcList![0].name)
            XCTAssertEqual("B", testStruct.arcList![1].name)
            XCTAssertEqual("C", testStruct.arcList![2].name)
            XCTAssertEqual("D", testStruct.arcList![3].name)
            XCTAssertEqual(4, testStruct.arcSet!.count)
            self.assertAnyRealmCollectionContains(testStruct.arcSet!, keyPath: \.name, items: ["A", "B", "C", "D"])
        }
    }
}

extension ThreadSafeWrapperTests {
    func testThreadSafeWrapperInline() throws {
        let values = ["A", "B", "C", "D"]
        try autoreleasepool {
            let realm = try Realm()
            try realm.write {
                realm.create(SwiftStringObject.self, value: ["A"])
                realm.create(SwiftStringObject.self, value: ["B"])
                realm.create(SwiftStringObject.self, value: ["C"])
                realm.create(SwiftStringObject.self, value: ["D"])
            }
        }

        let realm = try! Realm()
        @ThreadSafe var results = realm.objects(SwiftStringObject.self)
        dispatchSyncNewThread {
            guard let results = results else {
                return XCTFail("no results")
            }
            results.indices.forEach { idx in
                XCTAssertEqual(results[idx].stringCol, values[idx])
            }
        }
        @ThreadSafe var swiftStringObject = results!.first
        dispatchSyncNewThread {
            guard let swiftStringObject = swiftStringObject else {
                return XCTFail("no results")
            }

            XCTAssertEqual(swiftStringObject.stringCol, "A")
        }
    }

    func mutateStringCol(@ThreadSafe stringObj: SwiftStringObject?) {
        dispatchSyncNewThread {
            let realm = try! Realm()
            try! realm.write {
                stringObj?.stringCol = "after"
            }
        }
    }

    func testThreadSafeFunctionArgument() {
        let realm = try! Realm()
        @ThreadSafe var stringObj = try! realm.write {
            realm.create(SwiftStringObject.self, value: ["stringCol": "before"])
        }

        XCTAssertEqual(stringObj!.stringCol, "before")
        self.mutateStringCol(stringObj: stringObj)
        realm.refresh()
        XCTAssertEqual(stringObj!.stringCol, "after")
    }

    func testThreadSafeUnmanagedArgument() {
        let stringObj = SwiftStringObject(value: ["stringCol": "before"])

        dispatchSyncNewThread {
            self.assertThrows(self.mutateStringCol(stringObj: stringObj), reason: "Only managed objects may be wrapped as thread safe.")
        }
    }

    func testThreadSafeMultipleDispatch() {
        let realm = try! Realm()
        @ThreadSafe var obj = try! realm.write {
            realm.create(SwiftStringObject.self, value: ["stringCol": "before"])
        }
        let ex = expectation(description: "executes first block")

        DispatchQueue.concurrentPerform(iterations: 100) { i in
            try! obj?.realm?.write {
                obj?.stringCol = "middle"
            }
            if i == 99 { ex.fulfill() }
        }

        waitForExpectations(timeout: 5, handler: nil)
        XCTAssertNotEqual(obj?.stringCol, "before")
    }
}
