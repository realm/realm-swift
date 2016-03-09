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
    // swiftlint:disable:next variable_name
    dynamic var pk = nextPrimaryKey() // primary key for equality
    dynamic var ignored: Int = 0

    dynamic var boolCol: Bool = false
    dynamic var int8Col: Int8 = 1
    dynamic var int16Col: Int16 = 2
    dynamic var int32Col: Int32 = 3
    dynamic var int64Col: Int64 = 4
    dynamic var floatCol: Float = 5
    dynamic var doubleCol: Double = 6
    dynamic var stringCol: String = ""
    dynamic var binaryCol: NSData = NSData()
    dynamic var dateCol: NSDate = NSDate(timeIntervalSince1970: 0)
    dynamic var objectCol: KVOObject?
    let arrayCol = List<KVOObject>()
    let optIntCol = RealmOptional<Int>()
    let optFloatCol = RealmOptional<Float>()
    let optDoubleCol = RealmOptional<Double>()
    let optBoolCol = RealmOptional<Bool>()
    dynamic var optStringCol: String?
    dynamic var optBinaryCol: NSData?
    dynamic var optDateCol: NSDate?

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

    var changeDictionary: [NSObject: AnyObject]?
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?,
                  change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        changeDictionary = change
    }

    func observeChange(obj: NSObject, _ key: String, _ old: AnyObject, _ new: AnyObject,
                       fileName: TestLocationString = __FILE__, lineNumber: UInt = __LINE__, _ block: () -> Void) {
        obj.addObserver(self, forKeyPath: key, options: [.Old, .New], context: nil)
        block()
        obj.removeObserver(self, forKeyPath: key)

        XCTAssert(changeDictionary != nil, "Did not get a notification", file: fileName, line: lineNumber)
        if changeDictionary == nil {
            return
        }

        let actualOld: AnyObject = changeDictionary![NSKeyValueChangeOldKey]!
        let actualNew: AnyObject = changeDictionary![NSKeyValueChangeNewKey]!
        XCTAssert(actualOld.isEqual(old), "Old value: expected \(old), got \(actualOld)", file: fileName,
            line: lineNumber)
        XCTAssert(actualNew.isEqual(new), "New value: expected \(new), got \(actualNew)", file: fileName,
            line: lineNumber)

        changeDictionary = nil
    }

    func observeListChange(obj: NSObject, _ key: String, _ kind: NSKeyValueChange, _ indexes: NSIndexSet,
                           fileName: TestLocationString = __FILE__, lineNumber: UInt = __LINE__, _ block: () -> Void) {
        obj.addObserver(self, forKeyPath: key, options: [.Old, .New], context: nil)
        block()
        obj.removeObserver(self, forKeyPath: key)

        XCTAssert(changeDictionary != nil, "Did not get a notification", file: fileName, line: lineNumber)
        if changeDictionary == nil {
            return
        }

        let actualKind = NSKeyValueChange(rawValue: (changeDictionary![NSKeyValueChangeKindKey] as! NSNumber)
            .unsignedLongValue)!
        let actualIndexes = changeDictionary![NSKeyValueChangeIndexesKey]! as! NSIndexSet
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
        observeChange(obj, "objectCol", NSNull(), obj) { obj.objectCol = obj }

        let data = "abc".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
        observeChange(obj, "binaryCol", NSData(), data) { obj.binaryCol = data }

        let date = NSDate(timeIntervalSince1970: 1)
        observeChange(obj, "dateCol", NSDate(timeIntervalSince1970: 0), date) { obj.dateCol = date }

        observeListChange(obj, "arrayCol", .Insertion, NSIndexSet(index: 0)) {
            obj.arrayCol.append(obj)
        }
        observeListChange(obj, "arrayCol", .Removal, NSIndexSet(index: 0)) {
            obj.arrayCol.removeAll()
        }

        observeChange(obj, "optIntCol", NSNull(), 10) { obj.optIntCol.value = 10 }
        observeChange(obj, "optFloatCol", NSNull(), 10) { obj.optFloatCol.value = 10 }
        observeChange(obj, "optDoubleCol", NSNull(), 10) { obj.optDoubleCol.value = 10 }
        observeChange(obj, "optBoolCol", NSNull(), true) { obj.optBoolCol.value = true }
        observeChange(obj, "optStringCol", NSNull(), "abc") { obj.optStringCol = "abc" }
        observeChange(obj, "optBinaryCol", NSNull(), data) { obj.optBinaryCol = data }
        observeChange(obj, "optDateCol", NSNull(), date) { obj.optDateCol = date }

        observeChange(obj, "optIntCol", 10, NSNull()) { obj.optIntCol.value = nil }
        observeChange(obj, "optFloatCol", 10, NSNull()) { obj.optFloatCol.value = nil }
        observeChange(obj, "optDoubleCol", 10, NSNull()) { obj.optDoubleCol.value = nil }
        observeChange(obj, "optBoolCol", true, NSNull()) { obj.optBoolCol.value = nil }
        observeChange(obj, "optStringCol", "abc", NSNull()) { obj.optStringCol = nil }
        observeChange(obj, "optBinaryCol", data, NSNull()) { obj.optBinaryCol = nil }
        observeChange(obj, "optDateCol", date, NSNull()) { obj.optDateCol = nil }
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
        observeChange(obj, "objectCol", NSNull(), obj) { obj.objectCol = obj }

        let data = "abc".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
        observeChange(obj, "binaryCol", NSData(), data) { obj.binaryCol = data }

        let date = NSDate(timeIntervalSince1970: 1)
        observeChange(obj, "dateCol", NSDate(timeIntervalSince1970: 0), date) { obj.dateCol = date }

        observeListChange(obj, "arrayCol", .Insertion, NSIndexSet(index: 0)) {
            obj.arrayCol.append(obj)
        }
        observeListChange(obj, "arrayCol", .Removal, NSIndexSet(index: 0)) {
            obj.arrayCol.removeAll()
        }

        observeChange(obj, "optIntCol", NSNull(), 10) { obj.optIntCol.value = 10 }
        observeChange(obj, "optFloatCol", NSNull(), 10) { obj.optFloatCol.value = 10 }
        observeChange(obj, "optDoubleCol", NSNull(), 10) { obj.optDoubleCol.value = 10 }
        observeChange(obj, "optBoolCol", NSNull(), true) { obj.optBoolCol.value = true }
        observeChange(obj, "optStringCol", NSNull(), "abc") { obj.optStringCol = "abc" }
        observeChange(obj, "optBinaryCol", NSNull(), data) { obj.optBinaryCol = data }
        observeChange(obj, "optDateCol", NSNull(), date) { obj.optDateCol = date }

        observeChange(obj, "optIntCol", 10, NSNull()) { obj.optIntCol.value = nil }
        observeChange(obj, "optFloatCol", 10, NSNull()) { obj.optFloatCol.value = nil }
        observeChange(obj, "optDoubleCol", 10, NSNull()) { obj.optDoubleCol.value = nil }
        observeChange(obj, "optBoolCol", true, NSNull()) { obj.optBoolCol.value = nil }
        observeChange(obj, "optStringCol", "abc", NSNull()) { obj.optStringCol = nil }
        observeChange(obj, "optBinaryCol", data, NSNull()) { obj.optBinaryCol = nil }
        observeChange(obj, "optDateCol", date, NSNull()) { obj.optDateCol = nil }

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
        let obs = realm.objectForPrimaryKey(KVOObject.self, key: obj.pk)!

        observeChange(obs, "boolCol", false, true) { obj.boolCol = true }
        observeChange(obs, "int8Col", 1, 10) { obj.int8Col = 10 }
        observeChange(obs, "int16Col", 2, 10) { obj.int16Col = 10 }
        observeChange(obs, "int32Col", 3, 10) { obj.int32Col = 10 }
        observeChange(obs, "int64Col", 4, 10) { obj.int64Col = 10 }
        observeChange(obs, "floatCol", 5, 10) { obj.floatCol = 10 }
        observeChange(obs, "doubleCol", 6, 10) { obj.doubleCol = 10 }
        observeChange(obs, "stringCol", "", "abc") { obj.stringCol = "abc" }
        observeChange(obs, "objectCol", NSNull(), obj) { obj.objectCol = obj }

        let data = "abc".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
        observeChange(obs, "binaryCol", NSData(), data) { obj.binaryCol = data }

        let date = NSDate(timeIntervalSince1970: 1)
        observeChange(obs, "dateCol", NSDate(timeIntervalSince1970: 0), date) { obj.dateCol = date }

        observeListChange(obs, "arrayCol", .Insertion, NSIndexSet(index: 0)) {
            obj.arrayCol.append(obj)
        }
        observeListChange(obs, "arrayCol", .Removal, NSIndexSet(index: 0)) {
            obj.arrayCol.removeAll()
        }

        observeChange(obs, "optIntCol", NSNull(), 10) { obj.optIntCol.value = 10 }
        observeChange(obs, "optFloatCol", NSNull(), 10) { obj.optFloatCol.value = 10 }
        observeChange(obs, "optDoubleCol", NSNull(), 10) { obj.optDoubleCol.value = 10 }
        observeChange(obs, "optBoolCol", NSNull(), true) { obj.optBoolCol.value = true }
        observeChange(obs, "optStringCol", NSNull(), "abc") { obj.optStringCol = "abc" }
        observeChange(obs, "optBinaryCol", NSNull(), data) { obj.optBinaryCol = data }
        observeChange(obs, "optDateCol", NSNull(), date) { obj.optDateCol = date }

        observeChange(obs, "optIntCol", 10, NSNull()) { obj.optIntCol.value = nil }
        observeChange(obs, "optFloatCol", 10, NSNull()) { obj.optFloatCol.value = nil }
        observeChange(obs, "optDoubleCol", 10, NSNull()) { obj.optDoubleCol.value = nil }
        observeChange(obs, "optBoolCol", true, NSNull()) { obj.optBoolCol.value = nil }
        observeChange(obs, "optStringCol", "abc", NSNull()) { obj.optStringCol = nil }
        observeChange(obs, "optBinaryCol", data, NSNull()) { obj.optBinaryCol = nil }
        observeChange(obs, "optDateCol", date, NSNull()) { obj.optDateCol = nil }

        observeChange(obs, "invalidated", false, true) {
            self.realm.delete(obj)
        }

        let obj2 = KVOObject()
        realm.add(obj2)
        let obs2 = realm.objectForPrimaryKey(KVOObject.self, key: obj2.pk)!
        observeChange(obs2, "arrayCol.invalidated", false, true) {
            self.realm.delete(obj2)
        }
    }
}
