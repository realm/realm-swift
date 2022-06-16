////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
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
#if DEBUG
    @testable import RealmSwift
#else
    import RealmSwift
#endif
import Foundation

@available(*, deprecated) // Silence deprecation warnings for RealmOptional
class RealmTests: TestCase {
    enum TestError: Error {
        case intentional
    }

    func testFileURL() {
        XCTAssertEqual(try! Realm(fileURL: testRealmURL()).configuration.fileURL,
                       testRealmURL())
    }

    func testReadOnly() {
        autoreleasepool {
            XCTAssertEqual(try! Realm().configuration.readOnly, false)

            try! Realm().write {
                try! Realm().create(SwiftIntObject.self, value: [100])
            }
        }
        let config = Realm.Configuration(fileURL: defaultRealmURL(), readOnly: true)
        let readOnlyRealm = try! Realm(configuration: config)
        XCTAssertEqual(true, readOnlyRealm.configuration.readOnly)
        XCTAssertEqual(1, readOnlyRealm.objects(SwiftIntObject.self).count)

        assertThrows(try! Realm(), "Realm has different readOnly settings")
    }

    func testOpeningInvalidPathThrows() {
        assertFails(.fileAccess) {
            try Realm(configuration: Realm.Configuration(fileURL: URL(fileURLWithPath: "/dev/null/foo")))
        }
    }

    func testReadOnlyFile() {
        autoreleasepool {
            let realm = try! Realm(fileURL: testRealmURL())
            try! realm.write {
                realm.create(SwiftStringObject.self, value: ["a"])
            }
        }

        let fileManager = FileManager.default
        try! fileManager.setAttributes([ FileAttributeKey.immutable: true ], ofItemAtPath: testRealmURL().path)

        // Should not be able to open read-write
        assertFails(.fileAccess) {
            try Realm(fileURL: testRealmURL())
        }

        assertSucceeds {
            let realm = try Realm(configuration:
                Realm.Configuration(fileURL: testRealmURL(), readOnly: true))
            XCTAssertEqual(1, realm.objects(SwiftStringObject.self).count)
        }

        try! fileManager.setAttributes([ FileAttributeKey.immutable: false ], ofItemAtPath: testRealmURL().path)
    }

    func testReadOnlyRealmMustExist() {
        assertFails(.fileNotFound) {
            try Realm(configuration:
                Realm.Configuration(fileURL: defaultRealmURL(), readOnly: true))
        }
    }

    func testFilePermissionDenied() {
        autoreleasepool {
            _ = try! Realm(fileURL: testRealmURL())
        }

        // Make Realm at test path temporarily unreadable
        let fileManager = FileManager.default
        let permissions = try! fileManager
            .attributesOfItem(atPath: testRealmURL().path)[FileAttributeKey.posixPermissions] as! NSNumber
        try! fileManager.setAttributes([ FileAttributeKey.posixPermissions: 0000 ],
                                       ofItemAtPath: testRealmURL().path)

        assertFails(.filePermissionDenied) {
            try Realm(fileURL: testRealmURL())
        }

        try! fileManager.setAttributes([FileAttributeKey.posixPermissions: permissions], ofItemAtPath: testRealmURL().path)
    }

    #if !SWIFT_PACKAGE && DEBUG
    func testFileFormatUpgradeRequiredButDisabled() {
        var config = Realm.Configuration.defaultConfiguration
        let bundledRealmPath = Bundle(for: RealmTests.self).path(forResource: "fileformat-pre-null.realm",
                                                                 ofType: nil)!
        try! FileManager.default.copyItem(atPath: bundledRealmPath, toPath: config.fileURL!.path)
        config.disableFormatUpgrade = true
        assertFails(Realm.Error.fileFormatUpgradeRequired) {
            try Realm(configuration: config)
        }
    }
    #endif

    func testSchema() {
        let schema = try! Realm().schema
        XCTAssert(schema as AnyObject is Schema)
        XCTAssertEqual(1, schema.objectSchema.filter({ $0.className == "SwiftStringObject" }).count)
    }

    func testIsEmpty() {
        let realm = try! Realm()
        XCTAssert(realm.isEmpty, "Realm should be empty on creation.")

        realm.beginWrite()
        realm.create(SwiftStringObject.self, value: ["a"])
        XCTAssertFalse(realm.isEmpty, "Realm should not be empty within a write transaction after adding an object.")
        realm.cancelWrite()

        XCTAssertTrue(realm.isEmpty, "Realm should be empty after canceling a write transaction that added an object.")

        realm.beginWrite()
        realm.create(SwiftStringObject.self, value: ["a"])
        try! realm.commitWrite()
        XCTAssertFalse(realm.isEmpty,
            "Realm should not be empty after committing a write transaction that added an object.")
    }

    func testInit() {
        XCTAssertEqual(try! Realm(fileURL: testRealmURL()).configuration.fileURL,
                       testRealmURL())
    }

    func testInitFailable() {
        autoreleasepool {
            _ = try! Realm()
        }

        FileManager.default.createFile(atPath: defaultRealmURL().path,
            contents: "a".data(using: String.Encoding.utf8, allowLossyConversion: false),
            attributes: nil)

        assertFails(.fileAccess) {
            _ = try Realm()
            XCTFail("Realm creation should have failed")
        }
    }

    func testInitInMemory() {
        autoreleasepool {
            let realm = inMemoryRealm("identifier")
            try! realm.write {
                realm.create(SwiftIntObject.self, value: [1])
                return
            }
        }
        let realm = inMemoryRealm("identifier")
        XCTAssertEqual(realm.objects(SwiftIntObject.self).count, 0)

        try! realm.write {
            realm.create(SwiftIntObject.self, value: [1])
            XCTAssertEqual(realm.objects(SwiftIntObject.self).count, 1)

            inMemoryRealm("identifier").create(SwiftIntObject.self, value: [1])
            XCTAssertEqual(realm.objects(SwiftIntObject.self).count, 2)
        }

        let realm2 = inMemoryRealm("identifier2")
        XCTAssertEqual(realm2.objects(SwiftIntObject.self).count, 0)
    }

    func testInitCustomClassList() {
        let configuration = Realm.Configuration(fileURL: Realm.Configuration.defaultConfiguration.fileURL,
                                                objectTypes: [
                                                    EmbeddedTreeObject1.self,
                                                    EmbeddedTreeObject2.self,
                                                    EmbeddedTreeObject3.self,
                                                    EmbeddedParentObject.self,
                                                    SwiftStringObject.self
        ])
        let sorted = configuration.objectTypes!.sorted { $0.className() < $1.className() }
        XCTAssertTrue(sorted[0] is EmbeddedParentObject.Type)
        XCTAssertTrue(sorted[1] is EmbeddedTreeObject1.Type)
        XCTAssertTrue(sorted[2] is EmbeddedTreeObject2.Type)
        XCTAssertTrue(sorted[3] is EmbeddedTreeObject3.Type)
        XCTAssertTrue(sorted[4] is SwiftStringObject.Type)

        let realm = try! Realm(configuration: configuration)
        XCTAssertEqual(["EmbeddedParentObject", "EmbeddedTreeObject1", "EmbeddedTreeObject2", "EmbeddedTreeObject3", "SwiftStringObject"],
                       realm.schema.objectSchema.map { $0.className }.sorted())
    }

    func testWrite() {
        try! Realm().write {
            self.assertThrows(try! Realm().beginWrite())
            self.assertThrows(try! Realm().write { })
            try! Realm().create(SwiftStringObject.self, value: ["1"])
            XCTAssertEqual(try! Realm().objects(SwiftStringObject.self).count, 1)
        }
        XCTAssertEqual(try! Realm().objects(SwiftStringObject.self).count, 1)
    }

    func testDynamicWrite() {
        try! Realm().write {
            self.assertThrows(try! Realm().beginWrite())
            self.assertThrows(try! Realm().write { })
            try! Realm().dynamicCreate("SwiftStringObject", value: ["1"])
            XCTAssertEqual(try! Realm().objects(SwiftStringObject.self).count, 1)
        }
        XCTAssertEqual(try! Realm().objects(SwiftStringObject.self).count, 1)
    }

    func testWriteWithoutNotifying() {
        let realm = try! Realm()
        let token = realm.observe { _, _ in
            XCTFail("should not have been called")
        }

        try! realm.write(withoutNotifying: [token]) {
            realm.deleteAll()
        }

        // local realm notifications are called synchronously so no need to wait for anything
        token.invalidate()
    }

    func testDynamicWriteSubscripting() {
        try! Realm().beginWrite()
        let object = try! Realm().dynamicCreate("SwiftStringObject", value: ["1"])
        try! Realm().commitWrite()

        XCTAssertNotNil(object, "Dynamic Object Creation Failed")

        let stringVal = object["stringCol"] as! String
        XCTAssertEqual(stringVal, "1", "Object Subscripting Failed")
    }

    func testBeginWrite() {
        try! Realm().beginWrite()
        assertThrows(try! Realm().beginWrite())
        try! Realm().cancelWrite()
        try! Realm().beginWrite()
        try! Realm().create(SwiftStringObject.self, value: ["1"])
        XCTAssertEqual(try! Realm().objects(SwiftStringObject.self).count, 1)
    }

    func testWriteReturning() {
        let realm = try! Realm()
        let object = try! realm.write {
            return realm.create(SwiftStringObject.self, value: ["1"])
        }
        XCTAssertEqual(object.stringCol, "1")
    }

    func testCommitWrite() {
        try! Realm().beginWrite()
        try! Realm().create(SwiftStringObject.self, value: ["1"])
        try! Realm().commitWrite()
        XCTAssertEqual(try! Realm().objects(SwiftStringObject.self).count, 1)
        try! Realm().beginWrite()
    }

    func testCancelWrite() {
        assertThrows(try! Realm().cancelWrite())
        try! Realm().beginWrite()
        try! Realm().create(SwiftStringObject.self, value: ["1"])
        try! Realm().cancelWrite()
        XCTAssertEqual(try! Realm().objects(SwiftStringObject.self).count, 0)

        try! Realm().write {
            self.assertThrows(self.realmWithTestPath().cancelWrite())
            let object = try! Realm().create(SwiftStringObject.self)
            try! Realm().cancelWrite()
            XCTAssertTrue(object.isInvalidated)
            XCTAssertEqual(try! Realm().objects(SwiftStringObject.self).count, 0)
        }
        XCTAssertEqual(try! Realm().objects(SwiftStringObject.self).count, 0)
    }

    func testThrowsWrite() {
        assertFails(TestError.intentional) {
            try Realm().write {
                throw TestError.intentional
            }
        }
        assertFails(TestError.intentional) {
            try Realm().write {
                try! Realm().create(SwiftStringObject.self, value: ["1"])
                throw TestError.intentional
            }
        }
    }

    func testInWriteTransaction() {
        let realm = try! Realm()
        XCTAssertFalse(realm.isInWriteTransaction)
        realm.beginWrite()
        XCTAssertTrue(realm.isInWriteTransaction)
        realm.cancelWrite()
        try! realm.write {
            XCTAssertTrue(realm.isInWriteTransaction)
            realm.cancelWrite()
            XCTAssertFalse(realm.isInWriteTransaction)
        }

        realm.beginWrite()
        realm.invalidate()
        XCTAssertFalse(realm.isInWriteTransaction)
    }

    func testAddSingleObject() {
        let realm = try! Realm()
        assertThrows(realm.add(SwiftObject()))
        XCTAssertEqual(0, realm.objects(SwiftObject.self).count)
        var defaultRealmObject: SwiftObject!
        try! realm.write {
            defaultRealmObject = SwiftObject()
            realm.add(defaultRealmObject)
            XCTAssertEqual(1, realm.objects(SwiftObject.self).count)
            realm.add(defaultRealmObject)
            XCTAssertEqual(1, realm.objects(SwiftObject.self).count)
        }
        XCTAssertEqual(1, realm.objects(SwiftObject.self).count)

        let testRealm = realmWithTestPath()
        try! testRealm.write {
            self.assertThrows(testRealm.add(defaultRealmObject))
        }
    }

    func testAddWithUpdateSingleObject() {
        let realm = try! Realm()
        XCTAssertEqual(0, realm.objects(SwiftPrimaryStringObject.self).count)
        var defaultRealmObject: SwiftPrimaryStringObject!
        try! realm.write {
            defaultRealmObject = SwiftPrimaryStringObject()
            realm.add(defaultRealmObject, update: .all)
            XCTAssertEqual(1, realm.objects(SwiftPrimaryStringObject.self).count)
            realm.add(SwiftPrimaryStringObject(), update: .all)
            XCTAssertEqual(1, realm.objects(SwiftPrimaryStringObject.self).count)
        }
        XCTAssertEqual(1, realm.objects(SwiftPrimaryStringObject.self).count)

        let testRealm = realmWithTestPath()
        try! testRealm.write {
            self.assertThrows(testRealm.add(defaultRealmObject, update: .all))
        }
    }

    func testAddMultipleObjects() {
        let realm = try! Realm()
        assertThrows(realm.add([SwiftObject(), SwiftObject()]))
        XCTAssertEqual(0, realm.objects(SwiftObject.self).count)
        try! realm.write {
            let objs = [SwiftObject(), SwiftObject()]
            realm.add(objs)
            XCTAssertEqual(2, realm.objects(SwiftObject.self).count)
        }
        XCTAssertEqual(2, realm.objects(SwiftObject.self).count)

        let testRealm = realmWithTestPath()
        try! testRealm.write {
            self.assertThrows(testRealm.add(realm.objects(SwiftObject.self)))
        }
    }

    func testAddWithUpdateMultipleObjects() {
        let realm = try! Realm()
        XCTAssertEqual(0, realm.objects(SwiftPrimaryStringObject.self).count)
        try! realm.write {
            let objs = [SwiftPrimaryStringObject(), SwiftPrimaryStringObject()]
            realm.add(objs, update: .all)
            XCTAssertEqual(1, realm.objects(SwiftPrimaryStringObject.self).count)
        }
        XCTAssertEqual(1, realm.objects(SwiftPrimaryStringObject.self).count)

        let testRealm = realmWithTestPath()
        try! testRealm.write {
            self.assertThrows(testRealm.add(realm.objects(SwiftPrimaryStringObject.self), update: .all))
        }
    }

    // create() tests are in ObjectCreationTests.swift

    func testDeleteSingleObject() {
        let realm = try! Realm()
        XCTAssertEqual(0, realm.objects(SwiftObject.self).count)
        assertThrows(realm.delete(SwiftObject()))
        var defaultRealmObject: SwiftObject!
        try! realm.write {
            defaultRealmObject = SwiftObject()
            self.assertThrows(realm.delete(defaultRealmObject))
            XCTAssertEqual(0, realm.objects(SwiftObject.self).count)
            realm.add(defaultRealmObject)
            XCTAssertEqual(1, realm.objects(SwiftObject.self).count)
            realm.delete(defaultRealmObject)
            XCTAssertEqual(0, realm.objects(SwiftObject.self).count)
        }
        assertThrows(realm.delete(defaultRealmObject))
        XCTAssertEqual(0, realm.objects(SwiftObject.self).count)

        let testRealm = realmWithTestPath()
        assertThrows(testRealm.delete(defaultRealmObject))
        try! testRealm.write {
            self.assertThrows(testRealm.delete(defaultRealmObject))
        }
    }

    func testDeleteSequenceOfObjects() {
        let realm = try! Realm()
        XCTAssertEqual(0, realm.objects(SwiftObject.self).count)
        var objs: [SwiftObject]!
        try! realm.write {
            objs = [SwiftObject(), SwiftObject()]
            realm.add(objs)
            XCTAssertEqual(2, realm.objects(SwiftObject.self).count)
            realm.delete(objs)
            XCTAssertEqual(0, realm.objects(SwiftObject.self).count)
        }
        XCTAssertEqual(0, realm.objects(SwiftObject.self).count)

        let testRealm = realmWithTestPath()
        assertThrows(testRealm.delete(objs))
        try! testRealm.write {
            self.assertThrows(testRealm.delete(objs))
        }
    }

    func testDeleteListOfObjects() {
        let realm = try! Realm()
        XCTAssertEqual(0, realm.objects(SwiftCompanyObject.self).count)
        try! realm.write {
            let obj = SwiftCompanyObject()
            obj.employees.append(SwiftEmployeeObject())
            realm.add(obj)
            XCTAssertEqual(1, realm.objects(SwiftEmployeeObject.self).count)
            realm.delete(obj.employees)
            XCTAssertEqual(0, obj.employees.count)
            XCTAssertEqual(0, realm.objects(SwiftEmployeeObject.self).count)
        }
        XCTAssertEqual(0, realm.objects(SwiftEmployeeObject.self).count)
    }

    func testDeleteMutableSetOfObjects() {
        let realm = try! Realm()
        XCTAssertEqual(0, realm.objects(SwiftCompanyObject.self).count)
        try! realm.write {
            let obj = SwiftCompanyObject()
            obj.employeeSet.insert(SwiftEmployeeObject())
            realm.add(obj)
            XCTAssertEqual(1, realm.objects(SwiftEmployeeObject.self).count)
            realm.delete(obj.employeeSet)
            XCTAssertEqual(0, obj.employeeSet.count)
            XCTAssertEqual(0, realm.objects(SwiftEmployeeObject.self).count)
        }
        XCTAssertEqual(0, realm.objects(SwiftEmployeeObject.self).count)
    }

    func testDeleteResults() {
        let realm = try! Realm(fileURL: testRealmURL())
        XCTAssertEqual(0, realm.objects(SwiftCompanyObject.self).count)
        try! realm.write {
            realm.add(SwiftIntObject(value: [1]))
            realm.add(SwiftIntObject(value: [1]))
            realm.add(SwiftIntObject(value: [2]))
            XCTAssertEqual(3, realm.objects(SwiftIntObject.self).count)
            realm.delete(realm.objects(SwiftIntObject.self).filter("intCol = 1"))
            XCTAssertEqual(1, realm.objects(SwiftIntObject.self).count)
        }
        XCTAssertEqual(1, realm.objects(SwiftIntObject.self).count)
    }

    func testDeleteAll() {
        let realm = try! Realm()
        try! realm.write {
            realm.add(SwiftObject())
            XCTAssertEqual(1, realm.objects(SwiftObject.self).count)
            realm.deleteAll()
            XCTAssertEqual(0, realm.objects(SwiftObject.self).count)
        }
        XCTAssertEqual(0, realm.objects(SwiftObject.self).count)
    }

    func testObjects() {
        try! Realm().write {
            try! Realm().create(SwiftIntObject.self, value: [100])
            try! Realm().create(SwiftIntObject.self, value: [200])
            try! Realm().create(SwiftIntObject.self, value: [300])
        }

        XCTAssertEqual(0, try! Realm().objects(SwiftStringObject.self).count)
        XCTAssertEqual(3, try! Realm().objects(SwiftIntObject.self).count)
        assertThrows(try! Realm().objects(Object.self))
    }

    func testDynamicObjects() {
        try! Realm().write {
            try! Realm().create(SwiftIntObject.self, value: [100])
            try! Realm().create(SwiftIntObject.self, value: [200])
            try! Realm().create(SwiftIntObject.self, value: [300])
        }

        XCTAssertEqual(0, try! Realm().dynamicObjects("SwiftStringObject").count)
        XCTAssertEqual(3, try! Realm().dynamicObjects("SwiftIntObject").count)
        assertThrows(try! Realm().dynamicObjects("Object"))
    }

    func testDynamicObjectProperties() {
        try! Realm().write {
            try! Realm().create(SwiftObject.self)
        }

        let object = try! Realm().dynamicObjects("SwiftObject")[0]
        let dictionary = SwiftObject.defaultValues()

        XCTAssertEqual(object["boolCol"] as? NSNumber, dictionary["boolCol"] as! NSNumber?)
        XCTAssertEqual(object["intCol"] as? NSNumber, dictionary["intCol"] as! NSNumber?)
        XCTAssertEqual(object["int8Col"] as? NSNumber, dictionary["int8Col"] as! NSNumber?)
        XCTAssertEqual(object["int16Col"] as? NSNumber, dictionary["int16Col"] as! NSNumber?)
        XCTAssertEqual(object["int32Col"] as? NSNumber, dictionary["int32Col"] as! NSNumber?)
        XCTAssertEqual(object["int64Col"] as? NSNumber, dictionary["int64Col"] as! NSNumber?)
        XCTAssertEqual(object["floatCol"] as! Float, dictionary["floatCol"] as! Float, accuracy: 0.001)
        XCTAssertEqual(object["doubleCol"] as? NSNumber, dictionary["doubleCol"] as! NSNumber?)
        XCTAssertEqual(object["stringCol"] as! String?, dictionary["stringCol"] as! String?)
        XCTAssertEqual(object["binaryCol"] as! NSData?, dictionary["binaryCol"] as! NSData?)
        XCTAssertEqual(object["dateCol"] as! Date?, dictionary["dateCol"] as! Date?)
        XCTAssertEqual((object["objectCol"] as? SwiftBoolObject)?.boolCol, false)
    }

    func testDynamicObjectOptionalProperties() {
        try! Realm().write {
            try! Realm().create(SwiftOptionalDefaultValuesObject.self)
        }

        let object = try! Realm().dynamicObjects("SwiftOptionalDefaultValuesObject")[0]
        let dictionary = SwiftOptionalDefaultValuesObject.defaultValues()

        XCTAssertEqual(object["optIntCol"] as? NSNumber, dictionary["optIntCol"] as! NSNumber?)
        XCTAssertEqual(object["optInt8Col"] as? NSNumber, dictionary["optInt8Col"] as! NSNumber?)
        XCTAssertEqual(object["optInt16Col"] as? NSNumber, dictionary["optInt16Col"] as! NSNumber?)
        XCTAssertEqual(object["optInt32Col"] as? NSNumber, dictionary["optInt32Col"] as! NSNumber?)
        XCTAssertEqual(object["optInt64Col"] as? NSNumber, dictionary["optInt64Col"] as! NSNumber?)
        XCTAssertEqual(object["optFloatCol"] as? NSNumber, dictionary["optFloatCol"] as! NSNumber?)
        XCTAssertEqual(object["optDoubleCol"] as? NSNumber, dictionary["optDoubleCol"] as! NSNumber?)
        XCTAssertEqual(object["optStringCol"] as! String?, dictionary["optStringCol"] as! String?)
        XCTAssertEqual(object["optNSStringCol"] as! String?, dictionary["optNSStringCol"] as! String?)
        XCTAssertEqual(object["optBinaryCol"] as! NSData?, dictionary["optBinaryCol"] as! NSData?)
        XCTAssertEqual(object["optDateCol"] as! Date?, dictionary["optDateCol"] as! Date?)
        XCTAssertEqual(object["optDecimalCol"] as! Decimal128?, dictionary["optDecimalCol"] as! Decimal128?)
        XCTAssertEqual(object["optObjectIdCol"] as! ObjectId?, dictionary["optObjectIdCol"] as! ObjectId?)
        XCTAssertEqual((object["optObjectCol"] as? SwiftBoolObject)?.boolCol, true)
        XCTAssertEqual(object["optUuidCol"] as! UUID, dictionary["optUuidCol"] as! UUID)
    }

    func testIterateDynamicObjects() {
        try! Realm().write {
            for _ in 1..<3 {
                try! Realm().create(SwiftObject.self)
            }
        }

        let objects = try! Realm().dynamicObjects("SwiftObject")
        let dictionary = SwiftObject.defaultValues()

        for object in objects {
            XCTAssertEqual(object["boolCol"] as? NSNumber, dictionary["boolCol"] as! NSNumber?)
            XCTAssertEqual(object["intCol"] as? NSNumber, dictionary["intCol"] as! NSNumber?)
            XCTAssertEqual(object["int8Col"] as? NSNumber, dictionary["int8Col"] as! NSNumber?)
            XCTAssertEqual(object["int16Col"] as? NSNumber, dictionary["int16Col"] as! NSNumber?)
            XCTAssertEqual(object["int32Col"] as? NSNumber, dictionary["int32Col"] as! NSNumber?)
            XCTAssertEqual(object["int64Col"] as? NSNumber, dictionary["int64Col"] as! NSNumber?)
            XCTAssertEqual(object["floatCol"] as? NSNumber, dictionary["floatCol"] as! NSNumber?)
            XCTAssertEqual(object["doubleCol"] as? NSNumber, dictionary["doubleCol"] as! NSNumber?)
            XCTAssertEqual(object["stringCol"] as! String?, dictionary["stringCol"] as! String?)
            XCTAssertEqual(object["binaryCol"] as! NSData?, dictionary["binaryCol"] as! NSData?)
            XCTAssertEqual(object["dateCol"] as! Date?, dictionary["dateCol"] as! Date?)
            XCTAssertEqual((object["objectCol"] as? SwiftBoolObject)?.boolCol, false)
        }
    }

    func testDynamicObjectListProperties() {
        try! Realm().write {
            try! Realm().create(SwiftArrayPropertyObject.self, value: ["string", [["array"]], [[2]]])
        }

        let object = try! Realm().dynamicObjects("SwiftArrayPropertyObject")[0]

        XCTAssertEqual(object["name"] as? String, "string")

        let array = object["array"] as! List<DynamicObject>
        XCTAssertEqual(array.first!["stringCol"] as? String, "array")
        XCTAssertEqual(array.last!["stringCol"] as? String, "array")

        for object in array {
            XCTAssertEqual(object["stringCol"] as? String, "array")
        }

        let intArray = object["intArray"] as! List<DynamicObject>
        XCTAssertEqual(intArray[0]["intCol"] as? Int, 2)
        XCTAssertEqual(intArray.first!["intCol"] as? Int, 2)
        XCTAssertEqual(intArray.last!["intCol"] as? Int, 2)

        for object in intArray {
            XCTAssertEqual(object["intCol"] as? Int, 2)
        }
    }

    func testDynamicObjectMutableSetProperties() {
        try! Realm().write {
            try! Realm().create(SwiftMutableSetPropertyObject.self, value: ["string", [["set"]], [[2]]])
        }

        let object = try! Realm().dynamicObjects("SwiftMutableSetPropertyObject")[0]

        XCTAssertEqual(object["name"] as? String, "string")

        let set = object["set"] as! MutableSet<DynamicObject>
        XCTAssertEqual(set.first!["stringCol"] as? String, "set")
        XCTAssertEqual(set.last!["stringCol"] as? String, "set")

        for object in set {
            XCTAssertEqual(object["stringCol"] as? String, "set")
        }

        let intSet = object["intSet"] as! MutableSet<DynamicObject>
        XCTAssertEqual(intSet[0]["intCol"] as? Int, 2)
        XCTAssertEqual(intSet.first!["intCol"] as? Int, 2)
        XCTAssertEqual(intSet.last!["intCol"] as? Int, 2)

        for object in intSet {
            XCTAssertEqual(object["intCol"] as? Int, 2)
        }
    }

    func testIntPrimaryKey() {
        func testIntPrimaryKey<O: Object>(for type: O.Type)
            where O: SwiftPrimaryKeyObjectType, O.PrimaryKey: ExpressibleByIntegerLiteral {

                let realm = try! Realm()
                try! realm.write {
                    realm.create(type, value: ["a", 1])
                    realm.create(type, value: ["b", 2])
                }

                let object = realm.object(ofType: type, forPrimaryKey: 1 as O.PrimaryKey)
                XCTAssertNotNil(object)

                let missingObject = realm.object(ofType: type, forPrimaryKey: 0 as O.PrimaryKey)
                XCTAssertNil(missingObject)
        }

        testIntPrimaryKey(for: SwiftPrimaryIntObject.self)
        testIntPrimaryKey(for: SwiftPrimaryInt8Object.self)
        testIntPrimaryKey(for: SwiftPrimaryInt16Object.self)
        testIntPrimaryKey(for: SwiftPrimaryInt32Object.self)
        testIntPrimaryKey(for: SwiftPrimaryInt64Object.self)
    }

    func testOptionalIntPrimaryKey() {
        func testOptionalIntPrimaryKey<O: Object, Wrapped>(for type: O.Type, _ wrapped: Wrapped.Type)
            where Wrapped: ExpressibleByIntegerLiteral {
                let realm = try! Realm()
                try! realm.write {
                    realm.create(type, value: ["a", NSNull()])
                    realm.create(type, value: ["b", 2])
                }

                let object1a = realm.object(ofType: type, forPrimaryKey: NSNull())
                XCTAssertNotNil(object1a)

                let object1b = realm.object(ofType: type, forPrimaryKey: nil as Wrapped?)
                XCTAssertNotNil(object1b)

                let object2 = realm.object(ofType: type, forPrimaryKey: 2 as Wrapped)
                XCTAssertNotNil(object2)

                let missingObject = realm.object(ofType: type, forPrimaryKey: 0 as Wrapped)
                XCTAssertNil(missingObject)
        }

        testOptionalIntPrimaryKey(for: SwiftPrimaryOptionalIntObject.self, Int.self)
        testOptionalIntPrimaryKey(for: SwiftPrimaryOptionalInt8Object.self, Int8.self)
        testOptionalIntPrimaryKey(for: SwiftPrimaryOptionalInt16Object.self, Int16.self)
        testOptionalIntPrimaryKey(for: SwiftPrimaryOptionalInt32Object.self, Int32.self)
        testOptionalIntPrimaryKey(for: SwiftPrimaryOptionalInt64Object.self, Int64.self)
    }

    func testStringPrimaryKey() {
        let realm = try! Realm()
        try! realm.write {
            realm.create(SwiftPrimaryStringObject.self, value: ["a", 1])
            realm.create(SwiftPrimaryStringObject.self, value: ["b", 2])
        }

        // When this is directly inside the XCTAssertNotNil, it doesn't work
        let object = realm.object(ofType: SwiftPrimaryStringObject.self, forPrimaryKey: "a")
        XCTAssertNotNil(object)

        // When this is directly inside the XCTAssertNil, it fails for some reason
        let missingObject = realm.object(ofType: SwiftPrimaryStringObject.self, forPrimaryKey: "z")
        XCTAssertNil(missingObject)
    }

    func testOptionalStringPrimaryKey() {
        let realm = try! Realm()
        try! realm.write {
            realm.create(SwiftPrimaryStringObject.self, value: ["a", 1])
            realm.create(SwiftPrimaryStringObject.self, value: ["b", 2])

            realm.create(SwiftPrimaryOptionalStringObject.self, value: [NSNull(), 1])
            realm.create(SwiftPrimaryOptionalStringObject.self, value: ["b", 2])
        }

        let object1 = realm.object(ofType: SwiftPrimaryOptionalStringObject.self, forPrimaryKey: NSNull())
        XCTAssertNotNil(object1)

        let object2 = realm.object(ofType: SwiftPrimaryOptionalStringObject.self, forPrimaryKey: "b")
        XCTAssertNotNil(object2)

        let missingObject = realm.object(ofType: SwiftPrimaryOptionalStringObject.self, forPrimaryKey: "z")
        XCTAssertNil(missingObject)
    }

    func testUUIDPrimaryKey() {
        let realm = try! Realm()
        try! realm.write {
            realm.create(SwiftPrimaryUUIDObject.self, value: [UUID(uuidString: "8a12daba-8b23-11eb-8dcd-0242ac130003")!, "a"])
            realm.create(SwiftPrimaryUUIDObject.self, value: [UUID(uuidString: "85d4fbee-6ec6-47df-bfa1-615931903d7e")!, "b"])
        }

        let object1 = realm.object(ofType: SwiftPrimaryUUIDObject.self, forPrimaryKey: UUID(uuidString: "8a12daba-8b23-11eb-8dcd-0242ac130003")!)!
        XCTAssertNotNil(object1)
        XCTAssertEqual(object1.stringCol, "a")

        let object2 = realm.object(ofType: SwiftPrimaryUUIDObject.self, forPrimaryKey: UUID(uuidString: "85d4fbee-6ec6-47df-bfa1-615931903d7e")!)!
        XCTAssertNotNil(object2)
        XCTAssertEqual(object2.stringCol, "b")

        XCTAssertNil(realm.object(ofType: SwiftPrimaryUUIDObject.self, forPrimaryKey: UUID(uuidString: "4ee1fa48-8b23-11eb-8dcd-0242ac130003")!))
    }

    func testObjectIdPrimaryKey() {
        let realm = try! Realm()
        try! realm.write {
            realm.create(SwiftPrimaryObjectIdObject.self, value: [ObjectId("1234567890ab1234567890aa"), 1])
            realm.create(SwiftPrimaryObjectIdObject.self, value: [ObjectId("1234567890ab1234567890ab"), 2])
        }

        let object1 = realm.object(ofType: SwiftPrimaryObjectIdObject.self, forPrimaryKey: ObjectId("1234567890ab1234567890aa"))!
        XCTAssertNotNil(object1)
        XCTAssertEqual(object1.intCol, 1)

        let object2 = realm.object(ofType: SwiftPrimaryObjectIdObject.self, forPrimaryKey: ObjectId("1234567890ab1234567890ab"))!
        XCTAssertNotNil(object2)
        XCTAssertEqual(object2.intCol, 2)

        XCTAssertNil(realm.object(ofType: SwiftPrimaryObjectIdObject.self, forPrimaryKey: ObjectId("1234567890ab1234567890ac")))
    }

    func testDynamicObjectForPrimaryKey() {
        let realm = try! Realm()
        try! realm.write {
            realm.create(SwiftPrimaryStringObject.self, value: ["a", 1])
            realm.create(SwiftPrimaryStringObject.self, value: ["b", 2])
        }

        XCTAssertNotNil(realm.dynamicObject(ofType: "SwiftPrimaryStringObject", forPrimaryKey: "a"))
        XCTAssertNil(realm.dynamicObject(ofType: "SwiftPrimaryStringObject", forPrimaryKey: "z"))
    }

    func testDynamicObjectForPrimaryKeySubscripting() {
        let realm = try! Realm()
        try! realm.write {
            realm.create(SwiftPrimaryStringObject.self, value: ["a", 1])
        }

        let object = realm.dynamicObject(ofType: "SwiftPrimaryStringObject", forPrimaryKey: "a")

        let stringVal = object!["stringCol"] as! String

        XCTAssertEqual(stringVal, "a", "Object Subscripting Failed!")
    }

    func testObserve() {
        let realm = try! Realm()
        var notificationCalled = false
        let token = realm.observe { _, realm in
            XCTAssertEqual(realm.configuration.fileURL, self.defaultRealmURL())
            notificationCalled = true
        }
        XCTAssertFalse(notificationCalled)
        try! realm.write {}
        XCTAssertTrue(notificationCalled)
        token.invalidate()
    }

    func testRemoveNotification() {
        let realm = try! Realm()
        var notificationCalled = false
        let token = realm.observe { (_, realm) -> Void in
            XCTAssertEqual(realm.configuration.fileURL, self.defaultRealmURL())
            notificationCalled = true
        }
        token.invalidate()
        try! realm.write {}
        XCTAssertFalse(notificationCalled)
    }

    func testAutorefresh() {
        let realm = try! Realm()
        XCTAssertTrue(realm.autorefresh, "Autorefresh should default to true")
        realm.autorefresh = false
        XCTAssertFalse(realm.autorefresh)
        realm.autorefresh = true
        XCTAssertTrue(realm.autorefresh)

        // test that autoreresh is applied
        // we have two notifications, one for opening the realm, and a second when performing our transaction
        let notificationFired = expectation(description: "notification fired")
        let token = realm.observe { _, realm in
            XCTAssertNotNil(realm, "Realm should not be nil")
            notificationFired.fulfill()
        }

        dispatchSyncNewThread {
            let realm = try! Realm()
            try! realm.write {
                realm.create(SwiftStringObject.self, value: ["string"])
            }
        }
        waitForExpectations(timeout: 1, handler: nil)
        token.invalidate()

        // get object
        let results = realm.objects(SwiftStringObject.self)
        XCTAssertEqual(results.count, Int(1), "There should be 1 object of type StringObject")
        XCTAssertEqual(results[0].stringCol, "string", "Value of first column should be 'string'")
    }

    func testRefresh() {
        let realm = try! Realm()
        realm.autorefresh = false

        // test that autoreresh is not applied
        // we have two notifications, one for opening the realm, and a second when performing our transaction
        let notificationFired = expectation(description: "notification fired")
        var token: NotificationToken!
        token = realm.observe { _, realm in
            XCTAssertNotNil(realm, "Realm should not be nil")
            token.invalidate()
            notificationFired.fulfill()
        }

        let results = realm.objects(SwiftStringObject.self)
        XCTAssertEqual(results.count, Int(0), "There should be 1 object of type StringObject")

        dispatchSyncNewThread {
            try! Realm().write {
                _ = try! Realm().create(SwiftStringObject.self, value: ["string"])
            }
        }
        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(results.count, Int(0), "There should be 1 object of type StringObject")

        // refresh
        realm.refresh()

        XCTAssertEqual(results.count, Int(1), "There should be 1 object of type StringObject")
        XCTAssertEqual(results[0].stringCol, "string", "Value of first column should be 'string'")
    }

    func testInvalidate() {
        let realm = try! Realm()
        let object = SwiftObject()
        try! realm.write {
            realm.add(object)
            return
        }
        realm.invalidate()
        XCTAssertEqual(object.isInvalidated, true)

        try! realm.write {
            realm.add(SwiftObject())
            return
        }
        XCTAssertEqual(realm.objects(SwiftObject.self).count, 2)
        XCTAssertEqual(object.isInvalidated, true)
    }

    func testWriteCopyToPath() throws {
        let realm = try Realm()
        try realm.write {
            realm.add(SwiftObject())
        }
        let fileURL = defaultRealmURL().deletingLastPathComponent().appendingPathComponent("copy.realm")
        try realm.writeCopy(toFile: fileURL)
        try autoreleasepool {
            let copy = try Realm(fileURL: fileURL)
            XCTAssertEqual(1, copy.objects(SwiftObject.self).count)

            let frozenCopy = copy.freeze()
            XCTAssertEqual(1, frozenCopy.objects(SwiftObject.self).count)
            XCTAssertTrue(frozenCopy.isFrozen)
            XCTAssertTrue(frozenCopy.objects(SwiftObject.self).isFrozen)
        }
        try FileManager.default.removeItem(at: fileURL)
    }

    func testWriteCopyForConfiguration() {
        do {
            var localConfig = Realm.Configuration()
            localConfig.fileURL = defaultRealmURL().deletingLastPathComponent().appendingPathComponent("original.realm")

            let realm = try Realm(configuration: localConfig)
            try! realm.write {
                realm.add(SwiftBoolObject())
            }

            XCTAssertEqual(realm.objects(SwiftBoolObject.self).count, 1)

            var destinationConfig = Realm.Configuration()
            destinationConfig.fileURL = defaultRealmURL().deletingLastPathComponent().appendingPathComponent("destination.realm")

            try realm.writeCopy(configuration: destinationConfig)

            let destinationRealm = try Realm(configuration: destinationConfig)
            XCTAssertEqual(destinationRealm.objects(SwiftBoolObject.self).count, 1)

            try! destinationRealm.write {
                destinationRealm.add(SwiftBoolObject())
            }

            XCTAssertEqual(destinationRealm.objects(SwiftBoolObject.self).count, 2)

            let frozenRealm = destinationRealm.freeze()
            XCTAssertTrue(frozenRealm.isFrozen)
            XCTAssertTrue(frozenRealm.objects(SwiftBoolObject.self).isFrozen)

            try FileManager.default.removeItem(at: localConfig.fileURL!)
            try FileManager.default.removeItem(at: destinationConfig.fileURL!)
        } catch {
            print(error.localizedDescription)
            XCTFail("Got an error: \(error)")
        }
    }

    func testSeedFilePath() throws {
        var localConfig = Realm.Configuration()
        localConfig.fileURL = defaultRealmURL().deletingLastPathComponent().appendingPathComponent("original.realm")

        try autoreleasepool {
            let realm = try Realm(configuration: localConfig)
            try realm.write {
                realm.add(SwiftBoolObject())
            }
            XCTAssertEqual(realm.objects(SwiftBoolObject.self).count, 1)
        }

        var destinationConfig = Realm.Configuration()
        destinationConfig.fileURL = defaultRealmURL().deletingLastPathComponent().appendingPathComponent("destination.realm")
        destinationConfig.seedFilePath = defaultRealmURL().deletingLastPathComponent().appendingPathComponent("original.realm")

        try autoreleasepool {
            // Should copy the seed file over before opening
            let destinationRealm = try Realm(configuration: destinationConfig)
            XCTAssertEqual(destinationRealm.objects(SwiftBoolObject.self).count, 1)

            try destinationRealm.write {
                destinationRealm.add(SwiftBoolObject())
            }

            XCTAssertEqual(destinationRealm.objects(SwiftBoolObject.self).count, 2)
        }

        try autoreleasepool {
            let realm = try Realm(configuration: localConfig)
            try realm.write {
                realm.deleteAll()
            }
            XCTAssertEqual(realm.objects(SwiftBoolObject.self).count, 0)
        }

        try autoreleasepool {
            // Should not have copied the seed file as the Realm already exists
            let destinationRealm = try Realm(configuration: destinationConfig)
            XCTAssertEqual(destinationRealm.objects(SwiftBoolObject.self).count, 2)
        }
    }

    func testEquals() {
        let realm = try! Realm()
        XCTAssertTrue(try! realm == Realm())

        let testRealm = realmWithTestPath()
        XCTAssertFalse(realm == testRealm)

        dispatchSyncNewThread {
            let otherThreadRealm = try! Realm()
            XCTAssertFalse(realm == otherThreadRealm)
        }
    }

    func testCatchSpecificErrors() {
        do {
            _ = try Realm(configuration: Realm.Configuration(fileURL: URL(fileURLWithPath: "/dev/null/foo")))
            XCTFail("Error should be thrown")
        } catch Realm.Error.fileAccess {
            // Success to catch the error
        } catch {
            XCTFail("Failed to bridge RLMError to Realm.Error")
        }
        do {
            _ = try Realm(configuration: Realm.Configuration(fileURL: defaultRealmURL(), readOnly: true))
            XCTFail("Error should be thrown")
        } catch Realm.Error.fileNotFound {
            // Success to catch the error
        } catch {
            XCTFail("Failed to bridge RLMError to Realm.Error")
        }
    }

    func testExists() {
        let config = Realm.Configuration()
        XCTAssertFalse(Realm.fileExists(for: config))
        autoreleasepool { _ = try! Realm(configuration: config) }
        XCTAssertTrue(Realm.fileExists(for: config))
        XCTAssertTrue(try! Realm.deleteFiles(for: config))
        XCTAssertFalse(Realm.fileExists(for: config))
    }

    func testThaw() {
        XCTAssertEqual(try! Realm().objects(SwiftBoolObject.self).count, 0)
        let realm = try! Realm()
        let frozenRealm = realm.freeze()
        XCTAssert(frozenRealm.isFrozen)

        dispatchSyncNewThread {
            let thawedRealm = frozenRealm.thaw()
            XCTAssertFalse(thawedRealm.isFrozen)
            try! thawedRealm.write {
                try! Realm().create(SwiftBoolObject.self, value: ["boolCol": true])
            }
        }
        XCTAssertEqual(try! Realm().objects(SwiftBoolObject.self).count, 0)
        realm.refresh()
        XCTAssertEqual(try! Realm().objects(SwiftBoolObject.self).count, 1)
    }

// MARK: - Async Transactions

    func testAsyncTransactionShouldWrite() {
        let realm = try! Realm()
        let asyncComplete = expectation(description: "async transaction complete")

        realm.writeAsync {
            realm.create(SwiftStringObject.self, value: ["string"])
        } onComplete: { _ in
            let object = realm.objects(SwiftStringObject.self).first
            XCTAssertEqual(object?.stringCol, "string")
            asyncComplete.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testAsyncTransactionShouldWriteOnCommit() {
        let realm = try! Realm()
        let writeComplete = expectation(description: "async transaction complete")

        DispatchQueue.main.async {
            let realm = try! Realm()
            realm.beginAsyncWrite {
                realm.create(SwiftStringObject.self, value: ["string"])

                realm.commitAsyncWrite { _ in
                    let object = realm.objects(SwiftStringObject.self).first
                    XCTAssertEqual(object?.stringCol, "string")
                    writeComplete.fulfill()
                }
            }
        }

        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(realm.objects(SwiftStringObject.self).count, 1)
    }

    func testAsyncTransactionShouldCancel() {
        let realm = try! Realm()
        let asyncComplete = expectation(description: "async transaction complete")
        asyncComplete.isInverted = true

        let asyncTransactionId = realm.beginAsyncWrite {
            realm.create(SwiftStringObject.self, value: ["string"])
            realm.commitAsyncWrite { _ in
                asyncComplete.fulfill()
            }
        }

        try! realm.cancelAsyncWrite(asyncTransactionId)

        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertNil(realm.objects(SwiftStringObject.self).first)
    }

    func testAsyncTransactionShouldCancelWithoutCommit() {
        let realm = try! Realm()
        let asyncComplete = expectation(description: "async transaction complete")

        XCTAssertNil(realm.objects(SwiftStringObject.self).first)

        realm.beginAsyncWrite {
            realm.create(SwiftStringObject.self, value: ["string"])
            asyncComplete.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertNil(realm.objects(SwiftStringObject.self).first)
    }

    func testAsyncTransactionShouldNotAutoCommitOnCanceledTransaction() {
        let realm = try! Realm()
        let waitComplete = expectation(description: "async wait complete")
        let writeComplete = expectation(description: "async transaction complete")
        writeComplete.isInverted = true

        DispatchQueue.main.async {
            let realm = try! Realm()
            let transactionId = realm.writeAsync({
                realm.create(SwiftStringObject.self, value: ["string"])
            }, onComplete: { _ in
                writeComplete.fulfill()
            })
            try! realm.cancelAsyncWrite(transactionId)
            waitComplete.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertNil(realm.objects(SwiftStringObject.self).first)
    }

    func testAsyncTransactionShouldAutorefresh() {
        let realm = try! Realm()
        realm.autorefresh = false

        // test that autoreresh is not applied
        // we have two notifications, one for opening the realm, and a second when performing our transaction
        let notificationFired = expectation(description: "notification fired")
        var token: NotificationToken!
        token = realm.observe { _, realm in
            XCTAssertNotNil(realm, "Realm should not be nil")
            token.invalidate()
            notificationFired.fulfill()
        }

        let results = realm.objects(SwiftStringObject.self)
        XCTAssertEqual(results.count, 0)

        realm.writeAsync {
            realm.create(SwiftStringObject.self, value: ["string"])
        }

        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(results.count, 1)

        // refresh
        realm.refresh()

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].stringCol, "string")
    }

    func testAsyncTransactionSyncCommit() {
        let realm = try! Realm()
        let asyncComplete = expectation(description: "async transaction complete")
        XCTAssertEqual(0, realm.objects(SwiftStringObject.self).count)

        realm.beginAsyncWrite {
            realm.create(SwiftStringObject.self, value: ["string"])
            realm.commitAsyncWrite(allowGrouping: true) { _ in
                asyncComplete.fulfill()
            }
        }

        realm.beginAsyncWrite {
            realm.create(SwiftStringObject.self, value: ["string 2"])
            realm.commitAsyncWrite()
        }

        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(2, realm.objects(SwiftStringObject.self).count)
    }

    func testAsyncTransactionSyncAfterAsyncWithoutCommit() {
        let realm = try! Realm()
        XCTAssertEqual(0, realm.objects(SwiftStringObject.self).count)
        let asyncComplete = expectation(description: "async transaction complete")

        realm.beginAsyncWrite {
            realm.create(SwiftStringObject.self, value: ["string"])
            asyncComplete.fulfill()
        }

        try! realm.write {
            realm.create(SwiftStringObject.self, value: ["string 2"])
        }

        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(1, realm.objects(SwiftStringObject.self).count)
        XCTAssertEqual("string 2", realm.objects(SwiftStringObject.self).first?.stringCol)
    }

    func testAsyncTransactionWriteWithSync() {
        let realm = try! Realm()
        let asyncComplete = expectation(description: "async transaction complete")

        XCTAssertEqual(0, realm.objects(SwiftStringObject.self).count)

        try! realm.write {
            realm.create(SwiftStringObject.self, value: ["string"])
        }

        realm.beginWrite()
        realm.create(SwiftStringObject.self, value: ["string 2"])
        realm.commitAsyncWrite { _ in
            asyncComplete.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(2, realm.objects(SwiftStringObject.self).count)
    }

    func testAsyncTransactionMixedWithSync() {
        let realm = try! Realm()
        let asyncComplete = expectation(description: "async transaction complete")

        XCTAssertEqual(0, realm.objects(SwiftStringObject.self).count)

        realm.writeAsync {
            realm.create(SwiftStringObject.self, value: ["string"])
        }

        realm.writeAsync {
            realm.create(SwiftStringObject.self, value: ["string 2"])
        } onComplete: { _ in
            asyncComplete.fulfill()
        }

        realm.beginWrite()
        realm.create(SwiftStringObject.self, value: ["string 3"])
        try! realm.commitWrite()

        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(3, realm.objects(SwiftStringObject.self).count)
    }

    func testAsyncTransactionMixedWithCancelledSync() {
        let realm = try! Realm()
        let asyncComplete = expectation(description: "async transaction complete")

        XCTAssertEqual(0, realm.objects(SwiftStringObject.self).count)

        realm.writeAsync {
            realm.create(SwiftStringObject.self, value: ["string"])
        }

        realm.writeAsync {
            realm.create(SwiftStringObject.self, value: ["string 2"])
        } onComplete: { _ in
            asyncComplete.fulfill()
        }

        realm.beginWrite()
        realm.create(SwiftStringObject.self, value: ["string 3"])
        realm.cancelWrite()

        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(2, realm.objects(SwiftStringObject.self).count)
    }

    func testAsyncTransactionChangeNotification() {
        let realm = try! Realm()
        let asyncWriteComplete = expectation(description: "async write complete")
        asyncWriteComplete.expectedFulfillmentCount = 2
        let updateComplete = expectation(description: "update complete")
        updateComplete.expectedFulfillmentCount = 2

        let resultsUnderTest = realm.objects(SwiftStringObject.self)
        let token = resultsUnderTest.observe(on: nil) { change in
            switch change {
            case .initial:
                return // ignore
            case .update(_, deletions: _, insertions: _, modifications: _):
                updateComplete.fulfill()
            case .error:
                XCTFail("should not get here for this test")
            }
        }

        realm.writeAsync {
            realm.create(SwiftStringObject.self, value: ["string 1"])
        } onComplete: { _ in
            asyncWriteComplete.fulfill()
        }

        realm.writeAsync {
            realm.create(SwiftStringObject.self, value: ["string 2"])
        } onComplete: { _ in
            asyncWriteComplete.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(2, realm.objects(SwiftStringObject.self).count)
        token.invalidate()
    }

    func testBeginAsyncTransactionInAsyncTransaction() {
        let realm = try! Realm()
        let transaction1 = expectation(description: "async transaction 1 complete")
        let transaction2 = expectation(description: "async transaction 2 complete")
        XCTAssertEqual(0, realm.objects(SwiftStringObject.self).count)

        realm.beginAsyncWrite {
            realm.create(SwiftStringObject.self, value: ["string"])

            realm.beginAsyncWrite {
                realm.create(SwiftStringObject.self, value: ["string 2"])
                realm.commitAsyncWrite { _ in
                    transaction1.fulfill()
                }
            }
            realm.commitAsyncWrite { _ in
                transaction2.fulfill()
            }
        }

        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(2, realm.objects(SwiftStringObject.self).count)
    }

    func testAsyncTransactionFromSyncTransaction() {
        let realm = try! Realm()
        let transaction1 = expectation(description: "async transaction 1 complete")

        realm.beginWrite()
        realm.create(SwiftStringObject.self, value: ["string"])

        realm.beginAsyncWrite {
            realm.create(SwiftStringObject.self, value: ["string 2"])
            realm.commitAsyncWrite { _ in
                transaction1.fulfill()
            }
        }

        try! realm.commitWrite()

        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(2, realm.objects(SwiftStringObject.self).count)
    }

    func testAsyncTransactionCancel() {
        let waitComplete = expectation(description: "async wait complete")
        let expectation = XCTestExpectation(description: "testAsyncTransactionCancel expectation")
        expectation.expectedFulfillmentCount = 3
        let unexpectation = XCTestExpectation(description: "should not fulfill")
        unexpectation.isInverted = true

        DispatchQueue.main.async {
            let realm = try! Realm()
            realm.beginAsyncWrite {
                realm.create(SwiftStringObject.self, value: ["string"])
                expectation.fulfill()
            }
            realm.beginAsyncWrite {
                realm.create(SwiftStringObject.self, value: ["string"])
                realm.commitAsyncWrite()
                expectation.fulfill()
            }
            realm.beginAsyncWrite {
                realm.create(SwiftStringObject.self, value: ["string"])
                expectation.fulfill()
                realm.commitAsyncWrite()
            }
            let asyncTransactionIdB = realm.beginAsyncWrite {
                unexpectation.fulfill()
            }
            try! realm.cancelAsyncWrite(asyncTransactionIdB)
            self.wait(for: [expectation, unexpectation], timeout: 3)
            waitComplete.fulfill()
        }

        let realm = try! Realm()
        self.wait(for: [waitComplete], timeout: 4)
        XCTAssertEqual(2, realm.objects(SwiftStringObject.self).count)
    }

    func testAsyncTransactionCommit() {
        let realm = try! Realm()
        let changesAddedExpectation = expectation(description: "testAsyncTransactionCommit expectation")
        changesAddedExpectation.expectedFulfillmentCount = 2

        realm.beginAsyncWrite {
            realm.create(SwiftStringObject.self, value: ["with 'commit' should commit"])
            realm.commitAsyncWrite()
            changesAddedExpectation.fulfill()
        }
        realm.beginAsyncWrite {
            realm.create(SwiftStringObject.self, value: ["without 'commit' should not commit"])
            changesAddedExpectation.fulfill()
        }
        let asyncTransactionId = realm.beginAsyncWrite {
            realm.create(SwiftStringObject.self, value: ["'cancel' after 'begin' should not commit"])
            realm.commitAsyncWrite()
            changesAddedExpectation.fulfill()
        }
        try! realm.cancelAsyncWrite(asyncTransactionId)

        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(1, realm.objects(SwiftStringObject.self).count)
    }

    func testAsyncTransactionShouldWriteObjectFromOutsideOfTransaction() {
        let realm = try! Realm()
        let asyncComplete = expectation(description: "async transaction complete")
        let objU = SwiftStringObject(value: ["string U"])

        realm.beginAsyncWrite {
            realm.create(SwiftStringObject.self, value: ["string I"])
            realm.add(objU)
            realm.commitAsyncWrite { _ in
                asyncComplete.fulfill()
            }
        }

        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertNotNil(realm.objects(SwiftStringObject.self).first { $0.stringCol == "string U" })
        XCTAssertNotNil(realm.objects(SwiftStringObject.self).first { $0.stringCol == "string I" })
    }

    func testAsyncTransactionShouldChangeExistingObject() {
        let realm = try! Realm()
        let asyncComplete = expectation(description: "async transaction complete")
        try! realm.write({
            realm.create(SwiftStringObject.self, value: ["string A"])
        })
        let objA = realm.objects(SwiftStringObject.self).first(where: { $0.stringCol == "string A" })!

        realm.beginAsyncWrite {
            objA.stringCol = "string B"
            realm.commitAsyncWrite { _ in
                asyncComplete.fulfill()
            }
        }

        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertNil(realm.objects(SwiftStringObject.self).first { $0.stringCol == "string A" })
        XCTAssertNotNil(realm.objects(SwiftStringObject.self).first { $0.stringCol == "string B" })
    }
}
