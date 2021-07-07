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

import XCTest
import RealmSwift

class ModernKVOTests: TestCase {
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
                               change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        changeDictionary = change
    }

    // swiftlint:disable:next cyclomatic_complexity
    func observeChange<T: Equatable>(_ obj: ModernAllTypesObject, _ key: String, _ old: T?, _ new: T?,
                                     fileName: StaticString = #file, lineNumber: UInt = #line, _ block: () -> Void) {
        let kvoOptions: NSKeyValueObservingOptions = [.old, .new]
        obj.addObserver(self, forKeyPath: key, options: kvoOptions, context: nil)
        block()
        obj.removeObserver(self, forKeyPath: key)

        XCTAssert(changeDictionary != nil, "Did not get a notification", file: (fileName), line: lineNumber)
        guard changeDictionary != nil else { return }

        let actualOld = changeDictionary![.oldKey] as? T
        let actualNew = changeDictionary![.newKey] as? T

        XCTAssert(old == actualOld,
                  "Old value: expected \(String(describing: old)), got \(String(describing: actualOld))",
                  file: (fileName), line: lineNumber)
        XCTAssert(new == actualNew,
                  "New value: expected \(String(describing: new)), got \(String(describing: actualNew))",
                  file: (fileName), line: lineNumber)

        changeDictionary = nil
    }

    func observeListChange(_ obj: NSObject, _ key: String, _ kind: NSKeyValueChange,
                           _ indexes: NSIndexSet = NSIndexSet(index: 0),
                           fileName: StaticString = #file, lineNumber: UInt = #line, _ block: () -> Void) {
        obj.addObserver(self, forKeyPath: key, options: [.old, .new], context: nil)
        block()
        obj.removeObserver(self, forKeyPath: key)
        XCTAssert(changeDictionary != nil, "Did not get a notification", file: (fileName), line: lineNumber)
        guard changeDictionary != nil else { return }

        let actualKind = NSKeyValueChange(rawValue: (changeDictionary![NSKeyValueChangeKey.kindKey] as! NSNumber).uintValue)!
        let actualIndexes = changeDictionary![NSKeyValueChangeKey.indexesKey]! as! NSIndexSet
        XCTAssert(actualKind == kind, "Change kind: expected \(kind), got \(actualKind)", file: (fileName),
            line: lineNumber)
        XCTAssert(actualIndexes.isEqual(indexes), "Changed indexes: expected \(indexes), got \(actualIndexes)",
                  file: (fileName), line: lineNumber)

        changeDictionary = nil
    }

    class CompoundListObserver: NSObject {
        let key: String
        let deletions: [Int]
        let insertions: [Int]
        public var count = 0

        init(_ key: String, _ deletions: [Int], _ insertions: [Int]) {
            self.key = key
            self.deletions = deletions
            self.insertions = insertions
        }

        override func observeValue(forKeyPath keyPath: String?, of object: Any?,
                                   change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
            XCTAssertEqual(keyPath, key)
            XCTAssertNotNil(object)
            XCTAssertNotNil(change)
            guard let change = change else { return }
            XCTAssertNotNil(change[.kindKey])
            guard let kind = (change[.kindKey] as? UInt).map(NSKeyValueChange.init(rawValue:)) else { return }
            if count == 0 {
                XCTAssertEqual(kind, .removal)
                XCTAssertEqual(Array(change[.indexesKey]! as! NSIndexSet), deletions)
            } else if count == 1 {
                XCTAssertEqual(kind, .insertion)
                XCTAssertEqual(Array(change[.indexesKey]! as! NSIndexSet), insertions)
            } else {
                XCTFail("too many notifications")
            }
            count += 1
        }
    }

    func observeCompoundListChange(_ obs: NSObject, _ obj: NSObject, _ key: String,
                                   _ values: NSArray, deletions: [Int], insertions: [Int]) {
        let observer = CompoundListObserver(key, deletions, insertions)
        if deletions.count == 0 {
            observer.count = 1
        }

        obs.addObserver(observer, forKeyPath: key, options: [.old, .new], context: nil)
        obj.setValue(values, forKey: key)
        obs.removeObserver(observer, forKeyPath: key)

        if insertions.count > 0 {
            XCTAssertEqual(observer.count, 2)
        } else {
            XCTAssertEqual(observer.count, 1)
        }
    }

    func observeSetChange(_ obj: ModernAllTypesObject, _ key: String,
                          fileName: StaticString = #file, lineNumber: UInt = #line, _ block: () -> Void) {
        obj.addObserver(self, forKeyPath: key, options: [], context: nil)
        block()
        obj.removeObserver(self, forKeyPath: key)

        XCTAssert(changeDictionary != nil, "Did not get a notification", file: (fileName), line: lineNumber)
        guard changeDictionary != nil else { return }
    }

    func getObject(_ obj: ModernAllTypesObject) -> (ModernAllTypesObject, ModernAllTypesObject) {
        return (obj, obj)
    }

    // Actual tests follow

    func testAllPropertyTypes() {
        let (obj, obs) = getObject(ModernAllTypesObject())

        let oldData = obj.binaryCol
        let data = "abc".data(using: String.Encoding.utf8, allowLossyConversion: false)!
        let oldDate = obj.dateCol
        let date = Date(timeIntervalSince1970: 1)
        let oldDecimal = obj.decimalCol
        let decimal = Decimal128(number: 2)
        let oldObjectId = obj.objectIdCol
        let objectId = ObjectId()
        let oldUUID = obj.uuidCol
        let uuid = UUID()

        observeChange(obs, "boolCol", false, true) { obj.boolCol = true }
        observeChange(obs, "int8Col", 1 as Int8, 10) { obj.int8Col = 10 }
        observeChange(obs, "int16Col", 2 as Int16, 10) { obj.int16Col = 10 }
        observeChange(obs, "int32Col", 3 as Int32, 10) { obj.int32Col = 10 }
        observeChange(obs, "int64Col", 4 as Int64, 10) { obj.int64Col = 10 }
        observeChange(obs, "floatCol", 5 as Float, 10) { obj.floatCol = 10 }
        observeChange(obs, "doubleCol", 6 as Double, 10) { obj.doubleCol = 10 }
        observeChange(obs, "stringCol", "", "abc") { obj.stringCol = "abc" }
        observeChange(obs, "objectCol", nil, obj) { obj.objectCol = obj }
        observeChange(obs, "binaryCol", oldData, data) { obj.binaryCol = data }
        observeChange(obs, "dateCol", oldDate, date) { obj.dateCol = date }
        observeChange(obs, "decimalCol", oldDecimal, decimal) { obj.decimalCol = decimal }
        observeChange(obs, "objectIdCol", oldObjectId, objectId) { obj.objectIdCol = objectId }
        observeChange(obs, "uuidCol", oldUUID, uuid) { obj.uuidCol = uuid }
        observeChange(obs, "anyCol", nil, 1) { obj.anyCol = .int(1) }

        observeListChange(obs, "arrayCol", .insertion) { obj.arrayCol.append(obj) }
        observeListChange(obs, "arrayCol", .removal) { obj.arrayCol.removeAll() }
        observeSetChange(obs, "setCol") { obj.setCol.insert(obj) }
        observeSetChange(obs, "setCol") { obj.setCol.remove(obj) }

        observeChange(obs, "optIntCol", nil, 10) { obj.optIntCol = 10 }
        observeChange(obs, "optFloatCol", nil, 10.0) { obj.optFloatCol = 10 }
        observeChange(obs, "optDoubleCol", nil, 10.0) { obj.optDoubleCol = 10 }
        observeChange(obs, "optBoolCol", nil, true) { obj.optBoolCol = true }
        observeChange(obs, "optStringCol", nil, "abc") { obj.optStringCol = "abc" }
        observeChange(obs, "optBinaryCol", nil, data) { obj.optBinaryCol = data }
        observeChange(obs, "optDateCol", nil, date) { obj.optDateCol = date }
        observeChange(obs, "optDecimalCol", nil, decimal) { obj.optDecimalCol = decimal }
        observeChange(obs, "optObjectIdCol", nil, objectId) { obj.optObjectIdCol = objectId }
        observeChange(obs, "optUuidCol", nil, uuid) { obj.optUuidCol = uuid }

        observeChange(obs, "optIntCol", 10, nil) { obj.optIntCol = nil }
        observeChange(obs, "optFloatCol", 10.0, nil) { obj.optFloatCol = nil }
        observeChange(obs, "optDoubleCol", 10.0, nil) { obj.optDoubleCol = nil }
        observeChange(obs, "optBoolCol", true, nil) { obj.optBoolCol = nil }
        observeChange(obs, "optStringCol", "abc", nil) { obj.optStringCol = nil }
        observeChange(obs, "optBinaryCol", data, nil) { obj.optBinaryCol = nil }
        observeChange(obs, "optDateCol", date, nil) { obj.optDateCol = nil }
        observeChange(obs, "optDecimalCol", decimal, nil) { obj.optDecimalCol = nil }
        observeChange(obs, "optObjectIdCol", objectId, nil) { obj.optObjectIdCol = nil }
        observeChange(obs, "optUuidCol", uuid, nil) { obj.optUuidCol = nil }

        observeListChange(obs, "arrayBool", .insertion) { obj.arrayBool.append(true) }
        observeListChange(obs, "arrayInt8", .insertion) { obj.arrayInt8.append(10) }
        observeListChange(obs, "arrayInt16", .insertion) { obj.arrayInt16.append(10) }
        observeListChange(obs, "arrayInt32", .insertion) { obj.arrayInt32.append(10) }
        observeListChange(obs, "arrayInt64", .insertion) { obj.arrayInt64.append(10) }
        observeListChange(obs, "arrayFloat", .insertion) { obj.arrayFloat.append(10) }
        observeListChange(obs, "arrayDouble", .insertion) { obj.arrayDouble.append(10) }
        observeListChange(obs, "arrayString", .insertion) { obj.arrayString.append("abc") }
        observeListChange(obs, "arrayDecimal", .insertion) { obj.arrayDecimal.append(decimal) }
        observeListChange(obs, "arrayObjectId", .insertion) { obj.arrayObjectId.append(objectId) }
        observeListChange(obs, "arrayUuid", .insertion) { obj.arrayUuid.append(uuid) }
        observeListChange(obs, "arrayAny", .insertion) { obj.arrayAny.append(.string("a")) }

        observeListChange(obs, "arrayOptBool", .insertion) { obj.arrayOptBool.append(true) }
        observeListChange(obs, "arrayOptInt8", .insertion) { obj.arrayOptInt8.append(10) }
        observeListChange(obs, "arrayOptInt16", .insertion) { obj.arrayOptInt16.append(10) }
        observeListChange(obs, "arrayOptInt32", .insertion) { obj.arrayOptInt32.append(10) }
        observeListChange(obs, "arrayOptInt64", .insertion) { obj.arrayOptInt64.append(10) }
        observeListChange(obs, "arrayOptFloat", .insertion) { obj.arrayOptFloat.append(10) }
        observeListChange(obs, "arrayOptDouble", .insertion) { obj.arrayOptDouble.append(10) }
        observeListChange(obs, "arrayOptString", .insertion) { obj.arrayOptString.append("abc") }
        observeListChange(obs, "arrayOptBinary", .insertion) { obj.arrayOptBinary.append(data) }
        observeListChange(obs, "arrayOptDate", .insertion) { obj.arrayOptDate.append(date) }
        observeListChange(obs, "arrayOptDecimal", .insertion) { obj.arrayOptDecimal.append(decimal) }
        observeListChange(obs, "arrayOptObjectId", .insertion) { obj.arrayOptObjectId.append(objectId) }
        observeListChange(obs, "arrayOptUuid", .insertion) { obj.arrayOptUuid.append(uuid) }

        observeListChange(obs, "arrayOptBool", .insertion) { obj.arrayOptBool.insert(nil, at: 0) }
        observeListChange(obs, "arrayOptInt8", .insertion) { obj.arrayOptInt8.insert(nil, at: 0) }
        observeListChange(obs, "arrayOptInt16", .insertion) { obj.arrayOptInt16.insert(nil, at: 0) }
        observeListChange(obs, "arrayOptInt32", .insertion) { obj.arrayOptInt32.insert(nil, at: 0) }
        observeListChange(obs, "arrayOptInt64", .insertion) { obj.arrayOptInt64.insert(nil, at: 0) }
        observeListChange(obs, "arrayOptFloat", .insertion) { obj.arrayOptFloat.insert(nil, at: 0) }
        observeListChange(obs, "arrayOptDouble", .insertion) { obj.arrayOptDouble.insert(nil, at: 0) }
        observeListChange(obs, "arrayOptString", .insertion) { obj.arrayOptString.insert(nil, at: 0) }
        observeListChange(obs, "arrayOptDate", .insertion) { obj.arrayOptDate.insert(nil, at: 0) }
        observeListChange(obs, "arrayOptBinary", .insertion) { obj.arrayOptBinary.insert(nil, at: 0) }
        observeListChange(obs, "arrayOptDecimal", .insertion) { obj.arrayOptDecimal.insert(nil, at: 0) }
        observeListChange(obs, "arrayOptObjectId", .insertion) { obj.arrayOptObjectId.insert(nil, at: 0) }
        observeListChange(obs, "arrayOptUuid", .insertion) { obj.arrayOptUuid.insert(nil, at: 0) }

        observeSetChange(obs, "setBool") { obj.setBool.insert(true) }
        observeSetChange(obs, "setInt8") { obj.setInt8.insert(10) }
        observeSetChange(obs, "setInt16") { obj.setInt16.insert(10) }
        observeSetChange(obs, "setInt32") { obj.setInt32.insert(10) }
        observeSetChange(obs, "setInt64") { obj.setInt64.insert(10) }
        observeSetChange(obs, "setFloat") { obj.setFloat.insert(10) }
        observeSetChange(obs, "setDouble") { obj.setDouble.insert(10) }
        observeSetChange(obs, "setString") { obj.setString.insert("abc") }
        observeSetChange(obs, "setDecimal") { obj.setDecimal.insert(decimal) }
        observeSetChange(obs, "setObjectId") { obj.setObjectId.insert(objectId) }
        observeSetChange(obs, "setUuid") { obj.setUuid.insert(uuid) }
        observeSetChange(obs, "setAny") { obj.setAny.insert(.none) }

        observeSetChange(obs, "setOptBool") { obj.setOptBool.insert(true) }
        observeSetChange(obs, "setOptInt8") { obj.setOptInt8.insert(10) }
        observeSetChange(obs, "setOptInt16") { obj.setOptInt16.insert(10) }
        observeSetChange(obs, "setOptInt32") { obj.setOptInt32.insert(10) }
        observeSetChange(obs, "setOptInt64") { obj.setOptInt64.insert(10) }
        observeSetChange(obs, "setOptFloat") { obj.setOptFloat.insert(10) }
        observeSetChange(obs, "setOptDouble") { obj.setOptDouble.insert(10) }
        observeSetChange(obs, "setOptString") { obj.setOptString.insert("abc") }
        observeSetChange(obs, "setOptBinary") { obj.setOptBinary.insert(data) }
        observeSetChange(obs, "setOptDate") { obj.setOptDate.insert(date) }
        observeSetChange(obs, "setOptDecimal") { obj.setOptDecimal.insert(decimal) }
        observeSetChange(obs, "setOptObjectId") { obj.setOptObjectId.insert(objectId) }
        observeSetChange(obs, "setOptUuid") { obj.setOptUuid.insert(uuid) }

        observeSetChange(obs, "setOptBool") { obj.setOptBool.insert(nil) }
        observeSetChange(obs, "setOptInt8") { obj.setOptInt8.insert(nil) }
        observeSetChange(obs, "setOptInt16") { obj.setOptInt16.insert(nil) }
        observeSetChange(obs, "setOptInt32") { obj.setOptInt32.insert(nil) }
        observeSetChange(obs, "setOptInt64") { obj.setOptInt64.insert(nil) }
        observeSetChange(obs, "setOptFloat") { obj.setOptFloat.insert(nil) }
        observeSetChange(obs, "setOptDouble") { obj.setOptDouble.insert(nil) }
        observeSetChange(obs, "setOptString") { obj.setOptString.insert(nil) }
        observeSetChange(obs, "setOptDate") { obj.setOptDate.insert(nil) }
        observeSetChange(obs, "setOptBinary") { obj.setOptBinary.insert(nil) }
        observeSetChange(obs, "setOptDecimal") { obj.setOptDecimal.insert(nil) }
        observeSetChange(obs, "setOptObjectId") { obj.setOptObjectId.insert(nil) }
        observeSetChange(obs, "setOptUuid") { obj.setOptUuid.insert(nil) }

        observeSetChange(obs, "mapBool") { obj.mapBool[""] = true }
        observeSetChange(obs, "mapInt8") { obj.mapInt8[""] = 10 }
        observeSetChange(obs, "mapInt16") { obj.mapInt16[""] = 10 }
        observeSetChange(obs, "mapInt32") { obj.mapInt32[""] = 10 }
        observeSetChange(obs, "mapInt64") { obj.mapInt64[""] = 10 }
        observeSetChange(obs, "mapFloat") { obj.mapFloat[""] = 10 }
        observeSetChange(obs, "mapDouble") { obj.mapDouble[""] = 10 }
        observeSetChange(obs, "mapString") { obj.mapString[""] = "abc" }
        observeSetChange(obs, "mapDecimal") { obj.mapDecimal[""] = decimal }
        observeSetChange(obs, "mapObjectId") { obj.mapObjectId[""] = objectId }
        observeSetChange(obs, "mapUuid") { obj.mapUuid[""] = uuid }
        observeSetChange(obs, "mapAny") { obj.mapAny[""] = AnyRealmValue.none }

        observeSetChange(obs, "mapOptBool") { obj.mapOptBool[""] = true }
        observeSetChange(obs, "mapOptInt8") { obj.mapOptInt8[""] = 10 }
        observeSetChange(obs, "mapOptInt16") { obj.mapOptInt16[""] = 10 }
        observeSetChange(obs, "mapOptInt32") { obj.mapOptInt32[""] = 10 }
        observeSetChange(obs, "mapOptInt64") { obj.mapOptInt64[""] = 10 }
        observeSetChange(obs, "mapOptFloat") { obj.mapOptFloat[""] = 10 }
        observeSetChange(obs, "mapOptDouble") { obj.mapOptDouble[""] = 10 }
        observeSetChange(obs, "mapOptString") { obj.mapOptString[""] = "abc" }
        observeSetChange(obs, "mapOptBinary") { obj.mapOptBinary[""] = data }
        observeSetChange(obs, "mapOptDate") { obj.mapOptDate[""] = date }
        observeSetChange(obs, "mapOptDecimal") { obj.mapOptDecimal[""] = decimal }
        observeSetChange(obs, "mapOptObjectId") { obj.mapOptObjectId[""] = objectId }
        observeSetChange(obs, "mapOptUuid") { obj.mapOptUuid[""] = uuid }

        observeSetChange(obs, "mapOptBool") { obj.mapOptBool[""] = nil }
        observeSetChange(obs, "mapOptInt8") { obj.mapOptInt8[""] = nil }
        observeSetChange(obs, "mapOptInt16") { obj.mapOptInt16[""] = nil }
        observeSetChange(obs, "mapOptInt32") { obj.mapOptInt32[""] = nil }
        observeSetChange(obs, "mapOptInt64") { obj.mapOptInt64[""] = nil }
        observeSetChange(obs, "mapOptFloat") { obj.mapOptFloat[""] = nil }
        observeSetChange(obs, "mapOptDouble") { obj.mapOptDouble[""] = nil }
        observeSetChange(obs, "mapOptString") { obj.mapOptString[""] = nil }
        observeSetChange(obs, "mapOptDate") { obj.mapOptDate[""] = nil }
        observeSetChange(obs, "mapOptBinary") { obj.mapOptBinary[""] = nil }
        observeSetChange(obs, "mapOptDecimal") { obj.mapOptDecimal[""] = nil }
        observeSetChange(obs, "mapOptObjectId") { obj.mapOptObjectId[""] = nil }
        observeSetChange(obs, "mapOptUuid") { obj.mapOptUuid[""] = nil }

        obj.arrayInt32.removeAll()
        observeCompoundListChange(obj, obs, "arrayInt32", [1],
                                  deletions: [], insertions: [0])
        observeCompoundListChange(obj, obs, "arrayInt32", [1],
                                  deletions: [0], insertions: [0])
        observeCompoundListChange(obj, obs, "arrayInt32", [1, 2, 3],
                                  deletions: [0], insertions: [0, 1, 2])
        observeCompoundListChange(obj, obs, "arrayInt32", [],
                                  deletions: [0, 1, 2], insertions: [])
        observeCompoundListChange(obj, obs, "arrayInt32", [],
                                  deletions: [], insertions: [])

        if obs.realm == nil {
            return
        }

        observeChange(obs, "invalidated", false, true) {
            self.realm.delete(obj)
        }

        let (obj2, obs2) = getObject(ModernAllTypesObject())
        observeChange(obs2, "arrayCol.invalidated", false, true) {
            self.realm.delete(obj2)
        }

        let (obj3, obs3) = getObject(ModernAllTypesObject())
        observeChange(obs3, "setCol.invalidated", false, true) {
            self.realm.delete(obj3)
        }

        let (obj4, obs4) = getObject(ModernAllTypesObject())
        observeChange(obs4, "mapAny.invalidated", false, true) {
            self.realm.delete(obj4)
        }
    }

    func testReadSharedSchemaFromObservedObject() {
        let obj = ModernAllTypesObject()
        obj.addObserver(self, forKeyPath: "boolCol", options: [.old, .new], context: nil)
        XCTAssertEqual(type(of: obj).sharedSchema(), ModernAllTypesObject.sharedSchema())
        obj.removeObserver(self, forKeyPath: "boolCol")
    }
}

class ModernKVOPersistedTests: ModernKVOTests {
    override func getObject(_ obj: ModernAllTypesObject) -> (ModernAllTypesObject, ModernAllTypesObject) {
        realm.add(obj)
        return (obj, obj)
    }
}

class ModernKVOMultipleAccessorsTests: ModernKVOTests {
    override func getObject(_ obj: ModernAllTypesObject) -> (ModernAllTypesObject, ModernAllTypesObject) {
        realm.add(obj)
        return (obj, realm.object(ofType: ModernAllTypesObject.self, forPrimaryKey: obj.pk)!)
    }
}
