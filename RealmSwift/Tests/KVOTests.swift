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
import RealmSwift

var pkCounter = 0
func nextPrimaryKey() -> Int {
    pkCounter += 1
    return pkCounter
}

class KVOObject: Object {
    @objc dynamic var pk = nextPrimaryKey() // primary key for equality
    @objc dynamic var ignored: Int = 0

    @objc dynamic var boolCol: Bool = false
    @objc dynamic var int8Col: Int8 = 1
    @objc dynamic var int16Col: Int16 = 2
    @objc dynamic var int32Col: Int32 = 3
    @objc dynamic var int64Col: Int64 = 4
    @objc dynamic var floatCol: Float = 5
    @objc dynamic var doubleCol: Double = 6
    @objc dynamic var stringCol: String = ""
    @objc dynamic var binaryCol: Data = Data()
    @objc dynamic var dateCol: Date = Date(timeIntervalSince1970: 0)
    @objc dynamic var objectCol: KVOObject?
    let arrayCol = List<KVOObject>()
    let optIntCol = RealmOptional<Int>()
    let optFloatCol = RealmOptional<Float>()
    let optDoubleCol = RealmOptional<Double>()
    let optBoolCol = RealmOptional<Bool>()
    @objc dynamic var optStringCol: String?
    @objc dynamic var optBinaryCol: Data?
    @objc dynamic var optDateCol: Date?

    override class func primaryKey() -> String { return "pk" }
    override class func ignoredProperties() -> [String] { return ["ignored"] }
}

// Most of the testing of KVO functionality is done in the obj-c tests
// These tests just verify that it also works on Swift types
class KVOTests: TestCase {
    var realm: Realm! = nil

    override func setUp() {
        super.setUp()
        realm = try! Realm()
        realm.beginWrite()
    }

    override func tearDown() {
        realm.cancelWrite()
        realm = nil
        super.tearDown()
    }

    var changeDictionary: [NSKeyValueChangeKey: Any]?

    override func observeValue(forKeyPath keyPath: String?, of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        changeDictionary = change
    }

    func observeChange<T: Equatable>(_ obj: NSObject, _ key: String, _ old: T?, _ new: T?,
                                     fileName: StaticString = #file, lineNumber: UInt = #line, _ block: () -> Void) {
        obj.addObserver(self, forKeyPath: key, options: [.old, .new], context: nil)
        block()
        obj.removeObserver(self, forKeyPath: key)

        XCTAssert(changeDictionary != nil, "Did not get a notification", file: fileName, line: lineNumber)
        guard changeDictionary != nil else { return }

        let actualOld = changeDictionary![NSKeyValueChangeKey.oldKey]! as? T
        let actualNew = changeDictionary![NSKeyValueChangeKey.newKey]! as? T

        XCTAssert(old == actualOld,
                  "Old value: expected \(String(describing: old)), got \(String(describing: actualOld))",
                  file: fileName, line: lineNumber)
        XCTAssert(new == actualNew,
                  "New value: expected \(String(describing: new)), got \(String(describing: actualNew))",
                  file: fileName, line: lineNumber)

        changeDictionary = nil
    }

    func observeListChange(_ obj: NSObject, _ key: String, _ kind: NSKeyValueChange, _ indexes: NSIndexSet,
                           fileName: StaticString = #file, lineNumber: UInt = #line, _ block: () -> Void) {
        obj.addObserver(self, forKeyPath: key, options: [.old, .new], context: nil)
        block()
        obj.removeObserver(self, forKeyPath: key)

        XCTAssert(changeDictionary != nil, "Did not get a notification", file: fileName, line: lineNumber)
        if changeDictionary == nil {
            return
        }

        let actualKind = NSKeyValueChange(rawValue: (changeDictionary?[NSKeyValueChangeKey.kindKey] as! NSNumber).uintValue)!
        let actualIndexes = changeDictionary?[NSKeyValueChangeKey.indexesKey]! as! NSIndexSet
        XCTAssert(actualKind == kind, "Change kind: expected \(kind), got \(actualKind)", file: fileName,
            line: lineNumber)
        XCTAssert(actualIndexes.isEqual(indexes), "Changed indexes: expected \(indexes), got \(actualIndexes)",
            file: fileName, line: lineNumber)

        changeDictionary = nil
    }

    // Actual tests follow

    func testAllPropertyTypesStandalone() {
        let obj = KVOObject()
        observeChange(obj, "boolCol", false, true) { obj.boolCol = true }
        observeChange(obj, "int8Col", 1, 10) { obj.int8Col = 10 }
        observeChange(obj, "int16Col", 2, 10) { obj.int16Col = 10 }
        observeChange(obj, "int32Col", 3, 10) { obj.int32Col = 10 }
        observeChange(obj, "int64Col", 4, 10) { obj.int64Col = 10 }
        observeChange(obj, "floatCol", 5, 10) { obj.floatCol = 10 }
        observeChange(obj, "doubleCol", 6, 10) { obj.doubleCol = 10 }
        observeChange(obj, "stringCol", "", "abc") { obj.stringCol = "abc" }
        observeChange(obj, "objectCol", nil, obj) { obj.objectCol = obj }

        let data = "abc".data(using: String.Encoding.utf8, allowLossyConversion: false)!
        observeChange(obj, "binaryCol", Data(), data) { obj.binaryCol = data }

        let date = Date(timeIntervalSince1970: 1)
        observeChange(obj, "dateCol", Date(timeIntervalSince1970: 0), date) { obj.dateCol = date }

        observeListChange(obj, "arrayCol", .insertion, NSIndexSet(index: 0)) {
            obj.arrayCol.append(obj)
        }
        observeListChange(obj, "arrayCol", .removal, NSIndexSet(index: 0)) {
            obj.arrayCol.removeAll()
        }

        observeChange(obj, "optIntCol", nil, 10) { obj.optIntCol.value = 10 }
        observeChange(obj, "optFloatCol", nil, 10 as Float) { obj.optFloatCol.value = 10 }
        observeChange(obj, "optDoubleCol", nil, 10.0) { obj.optDoubleCol.value = 10 }
        observeChange(obj, "optBoolCol", nil, true) { obj.optBoolCol.value = true }
        observeChange(obj, "optStringCol", nil, "abc") { obj.optStringCol = "abc" }
        observeChange(obj, "optBinaryCol", nil, data) { obj.optBinaryCol = data }
        observeChange(obj, "optDateCol", nil, date) { obj.optDateCol = date }

        observeChange(obj, "optIntCol", 10, nil) { obj.optIntCol.value = nil }
        observeChange(obj, "optFloatCol", 10 as Float, nil) { obj.optFloatCol.value = nil }
        observeChange(obj, "optDoubleCol", 10.0, nil) { obj.optDoubleCol.value = nil }
        observeChange(obj, "optBoolCol", true, nil) { obj.optBoolCol.value = nil }
        observeChange(obj, "optStringCol", "abc", nil) { obj.optStringCol = nil }
        observeChange(obj, "optBinaryCol", data, nil) { obj.optBinaryCol = nil }
        observeChange(obj, "optDateCol", date, nil) { obj.optDateCol = nil }
    }

    func testAllPropertyTypesPersisted() {
        let obj = KVOObject()
        realm.add(obj)

        observeChange(obj, "boolCol", false, true) { obj.boolCol = true }
        observeChange(obj, "int8Col", 1, 10) { obj.int8Col = 10 }
        observeChange(obj, "int16Col", 2, 10) { obj.int16Col = 10 }
        observeChange(obj, "int32Col", 3, 10) { obj.int32Col = 10 }
        observeChange(obj, "int64Col", 4, 10) { obj.int64Col = 10 }
        observeChange(obj, "floatCol", 5, 10) { obj.floatCol = 10 }
        observeChange(obj, "doubleCol", 6, 10) { obj.doubleCol = 10 }
        observeChange(obj, "stringCol", "", "abc") { obj.stringCol = "abc" }
        observeChange(obj, "objectCol", nil, obj) { obj.objectCol = obj }

        let data = "abc".data(using: String.Encoding.utf8, allowLossyConversion: false)!
        observeChange(obj, "binaryCol", Data(), data) { obj.binaryCol = data }

        let date = Date(timeIntervalSince1970: 1)
        observeChange(obj, "dateCol", Date(timeIntervalSince1970: 0), date) { obj.dateCol = date }

        observeListChange(obj, "arrayCol", .insertion, NSIndexSet(index: 0)) {
            obj.arrayCol.append(obj)
        }
        observeListChange(obj, "arrayCol", .removal, NSIndexSet(index: 0)) {
            obj.arrayCol.removeAll()
        }

        observeChange(obj, "optIntCol", nil, 10) { obj.optIntCol.value = 10 }
        observeChange(obj, "optFloatCol", nil, 10) { obj.optFloatCol.value = 10 }
        observeChange(obj, "optDoubleCol", nil, 10) { obj.optDoubleCol.value = 10 }
        observeChange(obj, "optBoolCol", nil, true) { obj.optBoolCol.value = true }
        observeChange(obj, "optStringCol", nil, "abc") { obj.optStringCol = "abc" }
        observeChange(obj, "optBinaryCol", nil, data) { obj.optBinaryCol = data }
        observeChange(obj, "optDateCol", nil, date) { obj.optDateCol = date }

        observeChange(obj, "optIntCol", 10, nil) { obj.optIntCol.value = nil }
        observeChange(obj, "optFloatCol", 10, nil) { obj.optFloatCol.value = nil }
        observeChange(obj, "optDoubleCol", 10, nil) { obj.optDoubleCol.value = nil }
        observeChange(obj, "optBoolCol", true, nil) { obj.optBoolCol.value = nil }
        observeChange(obj, "optStringCol", "abc", nil) { obj.optStringCol = nil }
        observeChange(obj, "optBinaryCol", data, nil) { obj.optBinaryCol = nil }
        observeChange(obj, "optDateCol", date, nil) { obj.optDateCol = nil }

        observeChange(obj, "invalidated", false, true) {
            self.realm.delete(obj)
        }

        let obj2 = KVOObject()
        realm.add(obj2)
        observeChange(obj2, "arrayCol.invalidated", false, true) {
            self.realm.delete(obj2)
        }
    }

    func testAllPropertyTypesMultipleAccessors() {
        let obj = KVOObject()
        realm.add(obj)
        let obs = realm.object(ofType: KVOObject.self, forPrimaryKey: obj.pk)!

        observeChange(obs, "boolCol", false, true) { obj.boolCol = true }
        observeChange(obs, "int8Col", 1, 10) { obj.int8Col = 10 }
        observeChange(obs, "int16Col", 2, 10) { obj.int16Col = 10 }
        observeChange(obs, "int32Col", 3, 10) { obj.int32Col = 10 }
        observeChange(obs, "int64Col", 4, 10) { obj.int64Col = 10 }
        observeChange(obs, "floatCol", 5, 10) { obj.floatCol = 10 }
        observeChange(obs, "doubleCol", 6, 10) { obj.doubleCol = 10 }
        observeChange(obs, "stringCol", "", "abc") { obj.stringCol = "abc" }
        observeChange(obs, "objectCol", nil, obj) { obj.objectCol = obj }

        let data = "abc".data(using: String.Encoding.utf8, allowLossyConversion: false)!
        observeChange(obs, "binaryCol", Data(), data) { obj.binaryCol = data }

        let date = Date(timeIntervalSince1970: 1)
        observeChange(obs, "dateCol", Date(timeIntervalSince1970: 0), date) { obj.dateCol = date }

        observeListChange(obs, "arrayCol", .insertion, NSIndexSet(index: 0)) {
            obj.arrayCol.append(obj)
        }
        observeListChange(obs, "arrayCol", .removal, NSIndexSet(index: 0)) {
            obj.arrayCol.removeAll()
        }

        observeChange(obs, "optIntCol", nil, 10) { obj.optIntCol.value = 10 }
        observeChange(obs, "optFloatCol", nil, 10) { obj.optFloatCol.value = 10 }
        observeChange(obs, "optDoubleCol", nil, 10) { obj.optDoubleCol.value = 10 }
        observeChange(obs, "optBoolCol", nil, true) { obj.optBoolCol.value = true }
        observeChange(obs, "optStringCol", nil, "abc") { obj.optStringCol = "abc" }
        observeChange(obs, "optBinaryCol", nil, data) { obj.optBinaryCol = data }
        observeChange(obs, "optDateCol", nil, date) { obj.optDateCol = date }

        observeChange(obs, "optIntCol", 10, nil) { obj.optIntCol.value = nil }
        observeChange(obs, "optFloatCol", 10, nil) { obj.optFloatCol.value = nil }
        observeChange(obs, "optDoubleCol", 10, nil) { obj.optDoubleCol.value = nil }
        observeChange(obs, "optBoolCol", true, nil) { obj.optBoolCol.value = nil }
        observeChange(obs, "optStringCol", "abc", nil) { obj.optStringCol = nil }
        observeChange(obs, "optBinaryCol", data, nil) { obj.optBinaryCol = nil }
        observeChange(obs, "optDateCol", date, nil) { obj.optDateCol = nil }

        observeChange(obs, "invalidated", false, true) {
            self.realm.delete(obj)
        }

        let obj2 = KVOObject()
        realm.add(obj2)
        let obs2 = realm.object(ofType: KVOObject.self, forPrimaryKey: obj2.pk)!
        observeChange(obs2, "arrayCol.invalidated", false, true) {
            self.realm.delete(obj2)
        }
    }

    func testReadSharedSchemaFromObservedObject() {
        let obj = KVOObject()
        obj.addObserver(self, forKeyPath: "boolCol", options: [.old, .new], context: nil)
        XCTAssertEqual(type(of: obj).sharedSchema(), KVOObject.sharedSchema())
        obj.removeObserver(self, forKeyPath: "boolCol")
    }
}
