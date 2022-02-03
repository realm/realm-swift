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
// distributed under the License is distributed on an "(aS Is)" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

import XCTest
import RealmSwift

// This file is generated from a template. Do not edit directly.
// swiftlint:disable large_tuple vertical_parameter_alignment

class QueryTests: TestCase {
    private var realm: Realm!

    // MARK: Test data population

    private func objects() -> Results<ModernAllTypesObject> {
        realm.objects(ModernAllTypesObject.self)
    }

    private func getOrCreate<T: Object>(_ type: T.Type) -> T {
        if let object = realm.objects(T.self).first {
            return object
        }
        let object = T()
        try! realm.write {
            realm.add(object)
        }
        return object
    }

    private func collectionObject() -> ModernCollectionObject {
        return getOrCreate(ModernCollectionObject.self)
    }

    private func setAnyRealmValueCol(with value: AnyRealmValue, object: ModernAllTypesObject) {
        try! realm.write {
            object.anyCol = value
        }
    }

    private var circleObject: ModernCircleObject {
        return getOrCreate(ModernCircleObject.self)
    }

    override func setUp() {
        realm = inMemoryRealm("QueryTests")
        try! realm.write {
            let object = ModernAllTypesObject()

            object.boolCol = false
            object.intCol = 6
            object.int8Col = Int8(9)
            object.int16Col = Int16(17)
            object.int32Col = Int32(33)
            object.int64Col = Int64(65)
            object.floatCol = Float(6.55444333)
            object.doubleCol = 234.567
            object.stringCol = "Foó"
            object.binaryCol = Data(count: 128)
            object.dateCol = Date(timeIntervalSince1970: 2000000)
            object.decimalCol = Decimal128(234.567)
            object.objectIdCol = ObjectId("61184062c1d8f096a3695045")
            object.uuidCol = UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!
            object.intEnumCol = .value2
            object.stringEnumCol = .value2
            object.optBoolCol = false
            object.optIntCol = 6
            object.optInt8Col = Int8(9)
            object.optInt16Col = Int16(17)
            object.optInt32Col = Int32(33)
            object.optInt64Col = Int64(65)
            object.optFloatCol = Float(6.55444333)
            object.optDoubleCol = 234.567
            object.optStringCol = "Foó"
            object.optBinaryCol = Data(count: 128)
            object.optDateCol = Date(timeIntervalSince1970: 2000000)
            object.optDecimalCol = Decimal128(234.567)
            object.optObjectIdCol = ObjectId("61184062c1d8f096a3695045")
            object.optUuidCol = UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!
            object.optIntEnumCol = .value2
            object.optStringEnumCol = .value2

            object.arrayBool.append(objectsIn: [true, true])
            object.arrayInt.append(objectsIn: [5, 6])
            object.arrayInt8.append(objectsIn: [Int8(8), Int8(9)])
            object.arrayInt16.append(objectsIn: [Int16(16), Int16(17)])
            object.arrayInt32.append(objectsIn: [Int32(32), Int32(33)])
            object.arrayInt64.append(objectsIn: [Int64(64), Int64(65)])
            object.arrayFloat.append(objectsIn: [Float(5.55444333), Float(6.55444333)])
            object.arrayDouble.append(objectsIn: [123.456, 234.567])
            object.arrayString.append(objectsIn: ["Foo", "Foó"])
            object.arrayBinary.append(objectsIn: [Data(count: 64), Data(count: 128)])
            object.arrayDate.append(objectsIn: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)])
            object.arrayDecimal.append(objectsIn: [Decimal128(123.456), Decimal128(234.567)])
            object.arrayObjectId.append(objectsIn: [ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045")])
            object.arrayUuid.append(objectsIn: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])
            object.arrayAny.append(objectsIn: [AnyRealmValue.objectId(ObjectId("61184062c1d8f096a3695046")), AnyRealmValue.string("Hello")])
            object.arrayOptBool.append(objectsIn: [true, true])
            object.arrayOptInt.append(objectsIn: [5, 6])
            object.arrayOptInt8.append(objectsIn: [Int8(8), Int8(9)])
            object.arrayOptInt16.append(objectsIn: [Int16(16), Int16(17)])
            object.arrayOptInt32.append(objectsIn: [Int32(32), Int32(33)])
            object.arrayOptInt64.append(objectsIn: [Int64(64), Int64(65)])
            object.arrayOptFloat.append(objectsIn: [Float(5.55444333), Float(6.55444333)])
            object.arrayOptDouble.append(objectsIn: [123.456, 234.567])
            object.arrayOptString.append(objectsIn: ["Foo", "Foó"])
            object.arrayOptBinary.append(objectsIn: [Data(count: 64), Data(count: 128)])
            object.arrayOptDate.append(objectsIn: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)])
            object.arrayOptDecimal.append(objectsIn: [Decimal128(123.456), Decimal128(234.567)])
            object.arrayOptObjectId.append(objectsIn: [ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045")])
            object.arrayOptUuid.append(objectsIn: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])

            object.setBool.insert(objectsIn: [true, true])
            object.setInt.insert(objectsIn: [5, 6])
            object.setInt8.insert(objectsIn: [Int8(8), Int8(9)])
            object.setInt16.insert(objectsIn: [Int16(16), Int16(17)])
            object.setInt32.insert(objectsIn: [Int32(32), Int32(33)])
            object.setInt64.insert(objectsIn: [Int64(64), Int64(65)])
            object.setFloat.insert(objectsIn: [Float(5.55444333), Float(6.55444333)])
            object.setDouble.insert(objectsIn: [123.456, 234.567])
            object.setString.insert(objectsIn: ["Foo", "Foó"])
            object.setBinary.insert(objectsIn: [Data(count: 64), Data(count: 128)])
            object.setDate.insert(objectsIn: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)])
            object.setDecimal.insert(objectsIn: [Decimal128(123.456), Decimal128(234.567)])
            object.setObjectId.insert(objectsIn: [ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045")])
            object.setUuid.insert(objectsIn: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])
            object.setAny.insert(objectsIn: [AnyRealmValue.objectId(ObjectId("61184062c1d8f096a3695046")), AnyRealmValue.string("Hello")])
            object.setOptBool.insert(objectsIn: [true, true])
            object.setOptInt.insert(objectsIn: [5, 6])
            object.setOptInt8.insert(objectsIn: [Int8(8), Int8(9)])
            object.setOptInt16.insert(objectsIn: [Int16(16), Int16(17)])
            object.setOptInt32.insert(objectsIn: [Int32(32), Int32(33)])
            object.setOptInt64.insert(objectsIn: [Int64(64), Int64(65)])
            object.setOptFloat.insert(objectsIn: [Float(5.55444333), Float(6.55444333)])
            object.setOptDouble.insert(objectsIn: [123.456, 234.567])
            object.setOptString.insert(objectsIn: ["Foo", "Foó"])
            object.setOptBinary.insert(objectsIn: [Data(count: 64), Data(count: 128)])
            object.setOptDate.insert(objectsIn: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)])
            object.setOptDecimal.insert(objectsIn: [Decimal128(123.456), Decimal128(234.567)])
            object.setOptObjectId.insert(objectsIn: [ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045")])
            object.setOptUuid.insert(objectsIn: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])

            object.mapBool["foo"] = true
            object.mapBool["bar"] = true
            object.mapInt["foo"] = 5
            object.mapInt["bar"] = 6
            object.mapInt8["foo"] = Int8(8)
            object.mapInt8["bar"] = Int8(9)
            object.mapInt16["foo"] = Int16(16)
            object.mapInt16["bar"] = Int16(17)
            object.mapInt32["foo"] = Int32(32)
            object.mapInt32["bar"] = Int32(33)
            object.mapInt64["foo"] = Int64(64)
            object.mapInt64["bar"] = Int64(65)
            object.mapFloat["foo"] = Float(5.55444333)
            object.mapFloat["bar"] = Float(6.55444333)
            object.mapDouble["foo"] = 123.456
            object.mapDouble["bar"] = 234.567
            object.mapString["foo"] = "Foo"
            object.mapString["bar"] = "Foó"
            object.mapBinary["foo"] = Data(count: 64)
            object.mapBinary["bar"] = Data(count: 128)
            object.mapDate["foo"] = Date(timeIntervalSince1970: 1000000)
            object.mapDate["bar"] = Date(timeIntervalSince1970: 2000000)
            object.mapDecimal["foo"] = Decimal128(123.456)
            object.mapDecimal["bar"] = Decimal128(234.567)
            object.mapObjectId["foo"] = ObjectId("61184062c1d8f096a3695046")
            object.mapObjectId["bar"] = ObjectId("61184062c1d8f096a3695045")
            object.mapUuid["foo"] = UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!
            object.mapUuid["bar"] = UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!
            object.mapAny["foo"] = AnyRealmValue.objectId(ObjectId("61184062c1d8f096a3695046"))
            object.mapAny["bar"] = AnyRealmValue.string("Hello")
            object.mapOptBool["foo"] = true
            object.mapOptBool["bar"] = true
            object.mapOptInt["foo"] = 5
            object.mapOptInt["bar"] = 6
            object.mapOptInt8["foo"] = Int8(8)
            object.mapOptInt8["bar"] = Int8(9)
            object.mapOptInt16["foo"] = Int16(16)
            object.mapOptInt16["bar"] = Int16(17)
            object.mapOptInt32["foo"] = Int32(32)
            object.mapOptInt32["bar"] = Int32(33)
            object.mapOptInt64["foo"] = Int64(64)
            object.mapOptInt64["bar"] = Int64(65)
            object.mapOptFloat["foo"] = Float(5.55444333)
            object.mapOptFloat["bar"] = Float(6.55444333)
            object.mapOptDouble["foo"] = 123.456
            object.mapOptDouble["bar"] = 234.567
            object.mapOptString["foo"] = "Foo"
            object.mapOptString["bar"] = "Foó"
            object.mapOptBinary["foo"] = Data(count: 64)
            object.mapOptBinary["bar"] = Data(count: 128)
            object.mapOptDate["foo"] = Date(timeIntervalSince1970: 1000000)
            object.mapOptDate["bar"] = Date(timeIntervalSince1970: 2000000)
            object.mapOptDecimal["foo"] = Decimal128(123.456)
            object.mapOptDecimal["bar"] = Decimal128(234.567)
            object.mapOptObjectId["foo"] = ObjectId("61184062c1d8f096a3695046")
            object.mapOptObjectId["bar"] = ObjectId("61184062c1d8f096a3695045")
            object.mapOptUuid["foo"] = UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!
            object.mapOptUuid["bar"] = UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!

            realm.add(object)

            let collObj = ModernCollectionsOfEnums()

            collObj.listInt.append(objectsIn: [.value1, .value2])
            collObj.listInt8.append(objectsIn: [.value1, .value2])
            collObj.listInt16.append(objectsIn: [.value1, .value2])
            collObj.listInt32.append(objectsIn: [.value1, .value2])
            collObj.listInt64.append(objectsIn: [.value1, .value2])
            collObj.listFloat.append(objectsIn: [.value1, .value2])
            collObj.listDouble.append(objectsIn: [.value1, .value2])
            collObj.listString.append(objectsIn: [.value1, .value2])
            collObj.listIntOpt.append(objectsIn: [.value1, .value2])
            collObj.listInt8Opt.append(objectsIn: [.value1, .value2])
            collObj.listInt16Opt.append(objectsIn: [.value1, .value2])
            collObj.listInt32Opt.append(objectsIn: [.value1, .value2])
            collObj.listInt64Opt.append(objectsIn: [.value1, .value2])
            collObj.listFloatOpt.append(objectsIn: [.value1, .value2])
            collObj.listDoubleOpt.append(objectsIn: [.value1, .value2])
            collObj.listStringOpt.append(objectsIn: [.value1, .value2])

            collObj.setInt.insert(objectsIn: [.value1, .value2])
            collObj.setInt8.insert(objectsIn: [.value1, .value2])
            collObj.setInt16.insert(objectsIn: [.value1, .value2])
            collObj.setInt32.insert(objectsIn: [.value1, .value2])
            collObj.setInt64.insert(objectsIn: [.value1, .value2])
            collObj.setFloat.insert(objectsIn: [.value1, .value2])
            collObj.setDouble.insert(objectsIn: [.value1, .value2])
            collObj.setString.insert(objectsIn: [.value1, .value2])
            collObj.setIntOpt.insert(objectsIn: [.value1, .value2])
            collObj.setInt8Opt.insert(objectsIn: [.value1, .value2])
            collObj.setInt16Opt.insert(objectsIn: [.value1, .value2])
            collObj.setInt32Opt.insert(objectsIn: [.value1, .value2])
            collObj.setInt64Opt.insert(objectsIn: [.value1, .value2])
            collObj.setFloatOpt.insert(objectsIn: [.value1, .value2])
            collObj.setDoubleOpt.insert(objectsIn: [.value1, .value2])
            collObj.setStringOpt.insert(objectsIn: [.value1, .value2])

            collObj.mapInt["foo"] = .value1
            collObj.mapInt["bar"] = .value2
            collObj.mapInt8["foo"] = .value1
            collObj.mapInt8["bar"] = .value2
            collObj.mapInt16["foo"] = .value1
            collObj.mapInt16["bar"] = .value2
            collObj.mapInt32["foo"] = .value1
            collObj.mapInt32["bar"] = .value2
            collObj.mapInt64["foo"] = .value1
            collObj.mapInt64["bar"] = .value2
            collObj.mapFloat["foo"] = .value1
            collObj.mapFloat["bar"] = .value2
            collObj.mapDouble["foo"] = .value1
            collObj.mapDouble["bar"] = .value2
            collObj.mapString["foo"] = .value1
            collObj.mapString["bar"] = .value2
            collObj.mapIntOpt["foo"] = .value1
            collObj.mapIntOpt["bar"] = .value2
            collObj.mapInt8Opt["foo"] = .value1
            collObj.mapInt8Opt["bar"] = .value2
            collObj.mapInt16Opt["foo"] = .value1
            collObj.mapInt16Opt["bar"] = .value2
            collObj.mapInt32Opt["foo"] = .value1
            collObj.mapInt32Opt["bar"] = .value2
            collObj.mapInt64Opt["foo"] = .value1
            collObj.mapInt64Opt["bar"] = .value2
            collObj.mapFloatOpt["foo"] = .value1
            collObj.mapFloatOpt["bar"] = .value2
            collObj.mapDoubleOpt["foo"] = .value1
            collObj.mapDoubleOpt["bar"] = .value2
            collObj.mapStringOpt["foo"] = .value1
            collObj.mapStringOpt["bar"] = .value2

            realm.add(collObj)
        }
    }

    override func tearDown() {
        realm = nil
    }

    private func createKeypathCollectionAggregatesObject(_ parent: ModernAllTypesObject) {
        try! realm.write {
            realm.delete(parent.arrayCol)
            let children = [ModernAllTypesObject(), ModernAllTypesObject(), ModernAllTypesObject()]
            parent.arrayCol.append(objectsIn: children)

            initForKeypathCollectionAggregates(children, \.intCol)
            initForKeypathCollectionAggregates(children, \.int8Col)
            initForKeypathCollectionAggregates(children, \.int16Col)
            initForKeypathCollectionAggregates(children, \.int32Col)
            initForKeypathCollectionAggregates(children, \.int64Col)
            initForKeypathCollectionAggregates(children, \.floatCol)
            initForKeypathCollectionAggregates(children, \.doubleCol)
            initForKeypathCollectionAggregates(children, \.dateCol)
            initForKeypathCollectionAggregates(children, \.decimalCol)
            initForKeypathCollectionAggregates(children, \.intEnumCol)
            initForKeypathCollectionAggregates(children, \.optIntCol)
            initForKeypathCollectionAggregates(children, \.optInt8Col)
            initForKeypathCollectionAggregates(children, \.optInt16Col)
            initForKeypathCollectionAggregates(children, \.optInt32Col)
            initForKeypathCollectionAggregates(children, \.optInt64Col)
            initForKeypathCollectionAggregates(children, \.optFloatCol)
            initForKeypathCollectionAggregates(children, \.optDoubleCol)
            initForKeypathCollectionAggregates(children, \.optDateCol)
            initForKeypathCollectionAggregates(children, \.optDecimalCol)
            initForKeypathCollectionAggregates(children, \.optIntEnumCol)
        }
    }

    private func initForKeypathCollectionAggregates<T: QueryValue>(
            _ objects: [ModernAllTypesObject],
            _ keyPath: ReferenceWritableKeyPath<ModernAllTypesObject, T>) {
        for (obj, value) in zip(objects, T.queryValues()) {
            obj[keyPath: keyPath] = value
        }
    }

    private func initLinkedCollectionAggregatesObject() {
        realm.beginWrite()
        realm.deleteAll()

        let parentLinkToModernCollectionsOfEnums = realm.create(LinkToModernCollectionsOfEnums.self)
        let objModernCollectionsOfEnums = ModernCollectionsOfEnums()
        parentLinkToModernCollectionsOfEnums["objectCol"] = objModernCollectionsOfEnums
        let parentModernAllTypesObject = realm.create(ModernAllTypesObject.self)
        let objModernAllTypesObject = ModernAllTypesObject()
        parentModernAllTypesObject["objectCol"] = objModernAllTypesObject
        _ = realm.create(LinkToModernCollectionsOfEnums.self)

        objModernAllTypesObject["arrayBool"] = Bool.queryValues()
        objModernAllTypesObject["arrayInt"] = Int.queryValues()
        objModernAllTypesObject["arrayInt8"] = Int8.queryValues()
        objModernAllTypesObject["arrayInt16"] = Int16.queryValues()
        objModernAllTypesObject["arrayInt32"] = Int32.queryValues()
        objModernAllTypesObject["arrayInt64"] = Int64.queryValues()
        objModernAllTypesObject["arrayFloat"] = Float.queryValues()
        objModernAllTypesObject["arrayDouble"] = Double.queryValues()
        objModernAllTypesObject["arrayString"] = String.queryValues()
        objModernAllTypesObject["arrayBinary"] = Data.queryValues()
        objModernAllTypesObject["arrayDate"] = Date.queryValues()
        objModernAllTypesObject["arrayDecimal"] = Decimal128.queryValues()
        objModernAllTypesObject["arrayObjectId"] = ObjectId.queryValues()
        objModernAllTypesObject["arrayUuid"] = UUID.queryValues()
        objModernAllTypesObject["arrayAny"] = AnyRealmValue.queryValues()
        objModernCollectionsOfEnums["listInt"] = EnumInt.queryValues()
        objModernCollectionsOfEnums["listInt8"] = EnumInt8.queryValues()
        objModernCollectionsOfEnums["listInt16"] = EnumInt16.queryValues()
        objModernCollectionsOfEnums["listInt32"] = EnumInt32.queryValues()
        objModernCollectionsOfEnums["listInt64"] = EnumInt64.queryValues()
        objModernCollectionsOfEnums["listFloat"] = EnumFloat.queryValues()
        objModernCollectionsOfEnums["listDouble"] = EnumDouble.queryValues()
        objModernCollectionsOfEnums["listString"] = EnumString.queryValues()
        objModernAllTypesObject["arrayOptBool"] = Bool?.queryValues()
        objModernAllTypesObject["arrayOptInt"] = Int?.queryValues()
        objModernAllTypesObject["arrayOptInt8"] = Int8?.queryValues()
        objModernAllTypesObject["arrayOptInt16"] = Int16?.queryValues()
        objModernAllTypesObject["arrayOptInt32"] = Int32?.queryValues()
        objModernAllTypesObject["arrayOptInt64"] = Int64?.queryValues()
        objModernAllTypesObject["arrayOptFloat"] = Float?.queryValues()
        objModernAllTypesObject["arrayOptDouble"] = Double?.queryValues()
        objModernAllTypesObject["arrayOptString"] = String?.queryValues()
        objModernAllTypesObject["arrayOptBinary"] = Data?.queryValues()
        objModernAllTypesObject["arrayOptDate"] = Date?.queryValues()
        objModernAllTypesObject["arrayOptDecimal"] = Decimal128?.queryValues()
        objModernAllTypesObject["arrayOptObjectId"] = ObjectId?.queryValues()
        objModernAllTypesObject["arrayOptUuid"] = UUID?.queryValues()
        objModernCollectionsOfEnums["listIntOpt"] = EnumInt?.queryValues()
        objModernCollectionsOfEnums["listInt8Opt"] = EnumInt8?.queryValues()
        objModernCollectionsOfEnums["listInt16Opt"] = EnumInt16?.queryValues()
        objModernCollectionsOfEnums["listInt32Opt"] = EnumInt32?.queryValues()
        objModernCollectionsOfEnums["listInt64Opt"] = EnumInt64?.queryValues()
        objModernCollectionsOfEnums["listFloatOpt"] = EnumFloat?.queryValues()
        objModernCollectionsOfEnums["listDoubleOpt"] = EnumDouble?.queryValues()
        objModernCollectionsOfEnums["listStringOpt"] = EnumString?.queryValues()
        objModernAllTypesObject["setBool"] = Bool.queryValues()
        objModernAllTypesObject["setInt"] = Int.queryValues()
        objModernAllTypesObject["setInt8"] = Int8.queryValues()
        objModernAllTypesObject["setInt16"] = Int16.queryValues()
        objModernAllTypesObject["setInt32"] = Int32.queryValues()
        objModernAllTypesObject["setInt64"] = Int64.queryValues()
        objModernAllTypesObject["setFloat"] = Float.queryValues()
        objModernAllTypesObject["setDouble"] = Double.queryValues()
        objModernAllTypesObject["setString"] = String.queryValues()
        objModernAllTypesObject["setBinary"] = Data.queryValues()
        objModernAllTypesObject["setDate"] = Date.queryValues()
        objModernAllTypesObject["setDecimal"] = Decimal128.queryValues()
        objModernAllTypesObject["setObjectId"] = ObjectId.queryValues()
        objModernAllTypesObject["setUuid"] = UUID.queryValues()
        objModernAllTypesObject["setAny"] = AnyRealmValue.queryValues()
        objModernCollectionsOfEnums["setInt"] = EnumInt.queryValues()
        objModernCollectionsOfEnums["setInt8"] = EnumInt8.queryValues()
        objModernCollectionsOfEnums["setInt16"] = EnumInt16.queryValues()
        objModernCollectionsOfEnums["setInt32"] = EnumInt32.queryValues()
        objModernCollectionsOfEnums["setInt64"] = EnumInt64.queryValues()
        objModernCollectionsOfEnums["setFloat"] = EnumFloat.queryValues()
        objModernCollectionsOfEnums["setDouble"] = EnumDouble.queryValues()
        objModernCollectionsOfEnums["setString"] = EnumString.queryValues()
        objModernAllTypesObject["setOptBool"] = Bool?.queryValues()
        objModernAllTypesObject["setOptInt"] = Int?.queryValues()
        objModernAllTypesObject["setOptInt8"] = Int8?.queryValues()
        objModernAllTypesObject["setOptInt16"] = Int16?.queryValues()
        objModernAllTypesObject["setOptInt32"] = Int32?.queryValues()
        objModernAllTypesObject["setOptInt64"] = Int64?.queryValues()
        objModernAllTypesObject["setOptFloat"] = Float?.queryValues()
        objModernAllTypesObject["setOptDouble"] = Double?.queryValues()
        objModernAllTypesObject["setOptString"] = String?.queryValues()
        objModernAllTypesObject["setOptBinary"] = Data?.queryValues()
        objModernAllTypesObject["setOptDate"] = Date?.queryValues()
        objModernAllTypesObject["setOptDecimal"] = Decimal128?.queryValues()
        objModernAllTypesObject["setOptObjectId"] = ObjectId?.queryValues()
        objModernAllTypesObject["setOptUuid"] = UUID?.queryValues()
        objModernCollectionsOfEnums["setIntOpt"] = EnumInt?.queryValues()
        objModernCollectionsOfEnums["setInt8Opt"] = EnumInt8?.queryValues()
        objModernCollectionsOfEnums["setInt16Opt"] = EnumInt16?.queryValues()
        objModernCollectionsOfEnums["setInt32Opt"] = EnumInt32?.queryValues()
        objModernCollectionsOfEnums["setInt64Opt"] = EnumInt64?.queryValues()
        objModernCollectionsOfEnums["setFloatOpt"] = EnumFloat?.queryValues()
        objModernCollectionsOfEnums["setDoubleOpt"] = EnumDouble?.queryValues()
        objModernCollectionsOfEnums["setStringOpt"] = EnumString?.queryValues()
        populateMap(objModernAllTypesObject.mapBool)
        populateMap(objModernAllTypesObject.mapInt)
        populateMap(objModernAllTypesObject.mapInt8)
        populateMap(objModernAllTypesObject.mapInt16)
        populateMap(objModernAllTypesObject.mapInt32)
        populateMap(objModernAllTypesObject.mapInt64)
        populateMap(objModernAllTypesObject.mapFloat)
        populateMap(objModernAllTypesObject.mapDouble)
        populateMap(objModernAllTypesObject.mapString)
        populateMap(objModernAllTypesObject.mapBinary)
        populateMap(objModernAllTypesObject.mapDate)
        populateMap(objModernAllTypesObject.mapDecimal)
        populateMap(objModernAllTypesObject.mapObjectId)
        populateMap(objModernAllTypesObject.mapUuid)
        populateMap(objModernAllTypesObject.mapAny)
        populateMap(objModernCollectionsOfEnums.mapInt)
        populateMap(objModernCollectionsOfEnums.mapInt8)
        populateMap(objModernCollectionsOfEnums.mapInt16)
        populateMap(objModernCollectionsOfEnums.mapInt32)
        populateMap(objModernCollectionsOfEnums.mapInt64)
        populateMap(objModernCollectionsOfEnums.mapFloat)
        populateMap(objModernCollectionsOfEnums.mapDouble)
        populateMap(objModernCollectionsOfEnums.mapString)
        populateMap(objModernAllTypesObject.mapOptBool)
        populateMap(objModernAllTypesObject.mapOptInt)
        populateMap(objModernAllTypesObject.mapOptInt8)
        populateMap(objModernAllTypesObject.mapOptInt16)
        populateMap(objModernAllTypesObject.mapOptInt32)
        populateMap(objModernAllTypesObject.mapOptInt64)
        populateMap(objModernAllTypesObject.mapOptFloat)
        populateMap(objModernAllTypesObject.mapOptDouble)
        populateMap(objModernAllTypesObject.mapOptString)
        populateMap(objModernAllTypesObject.mapOptBinary)
        populateMap(objModernAllTypesObject.mapOptDate)
        populateMap(objModernAllTypesObject.mapOptDecimal)
        populateMap(objModernAllTypesObject.mapOptObjectId)
        populateMap(objModernAllTypesObject.mapOptUuid)
        populateMap(objModernCollectionsOfEnums.mapIntOpt)
        populateMap(objModernCollectionsOfEnums.mapInt8Opt)
        populateMap(objModernCollectionsOfEnums.mapInt16Opt)
        populateMap(objModernCollectionsOfEnums.mapInt32Opt)
        populateMap(objModernCollectionsOfEnums.mapInt64Opt)
        populateMap(objModernCollectionsOfEnums.mapFloatOpt)
        populateMap(objModernCollectionsOfEnums.mapDoubleOpt)
        populateMap(objModernCollectionsOfEnums.mapStringOpt)

        try! realm.commitWrite()
    }

    private func populateMap<T: QueryValue>(_ map: Map<String, T>) {
        let values = T.queryValues()
        map["foo"] = values[2]
        map["bar"] = values[1]
        map["baz"] = values[0]
    }

    // MARK: - Assertion Helpers

    private func assertCount<T: Object>(_ expectedCount: Int,
                                        _ query: ((Query<T>) -> Query<Bool>)) {
        let results = realm.objects(T.self).where(query)
        XCTAssertEqual(results.count, expectedCount)
    }

    private func assertPredicate<T: _RealmSchemaDiscoverable>(
            _ predicate: String, _ values: [Any],
            _ query: ((Query<T>) -> Query<Bool>)) {
        let (queryStr, constructedValues) = query(Query<T>._constructForTesting())._constructPredicate()
        XCTAssertEqual(queryStr, predicate)
        XCTAssertEqual(constructedValues.count, values.count)
        XCTAssertEqual(NSPredicate(format: queryStr, argumentArray: constructedValues),
                       NSPredicate(format: predicate, argumentArray: values))
    }

    private func assertQuery(_ predicate: String, _ value: Any,
                             count expectedCount: Int,
                             _ query: ((Query<ModernAllTypesObject>) -> Query<Bool>)) {
        assertCount(expectedCount, query)
        assertPredicate(predicate, [value], query)
    }

    private func assertQuery<T: Object>(_ type: T.Type,
                             _ predicate: String, _ value: Any,
                             count expectedCount: Int,
                             _ query: ((Query<T>) -> Query<Bool>)) {
        assertCount(expectedCount, query)
        assertPredicate(predicate, [value], query)
    }

    private func assertQuery(_ predicate: String, values: [Any] = [],
                             count expectedCount: Int,
                             _ query: ((Query<ModernAllTypesObject>) -> Query<Bool>)) {
        assertCount(expectedCount, query)
        assertPredicate(predicate, values, query)
    }

    private func assertQuery<T: Object>(_ type: T.Type, _ predicate: String,
                                        values: [Any] = [],
                                        count expectedCount: Int,
                                        _ query: ((Query<T>) -> Query<Bool>)) {
        assertCount(expectedCount, query)
        assertPredicate(predicate, values, query)
    }

    private func assertCollectionQuery(predicate: String,
                                       value: Any,
                                       query: ((Query<ModernAllTypesObject>) -> Query<Bool>)) {
        assertPredicate(predicate, [value], query)
        XCTAssertEqual(collectionObject().list.where(query).count, 1)
        XCTAssertEqual(collectionObject().set.where(query).count, 1)
    }

    private func assertMapQuery(predicate: String,
                                values: [Any] = [],
                                count expectedCount: Int,
                                query: ((Query<ModernAllTypesObject?>) -> Query<Bool>)) {
        let results = collectionObject().map.where(query)
        XCTAssertEqual(results.count, expectedCount)
        assertPredicate(predicate, values, query)
    }

    // MARK: - Basic Comparison

    func validateEquals<T: _Persistable>(_ name: String, _ lhs: (Query<ModernAllTypesObject>) -> Query<T>, _ value: T) {
        assertQuery("(\(name) == %@)", value, count: 1) {
            lhs($0) == value
        }
        assertQuery("(\(name) != %@)", value, count: 0) {
            lhs($0) != value
        }
    }
    func validateEqualsNil<T: _RealmSchemaDiscoverable & ExpressibleByNilLiteral>(_ name: String, _ lhs: (Query<ModernAllTypesObject>) -> Query<T>) {
        assertQuery("(\(name) == %@)", NSNull(), count: 0) {
            lhs($0) == nil
        }
        assertQuery("(\(name) != %@)", NSNull(), count: 1) {
            lhs($0) != nil
        }
    }

    func testEquals() {
        validateEquals("boolCol", \Query<ModernAllTypesObject>.boolCol, false)
        validateEquals("intCol", \Query<ModernAllTypesObject>.intCol, 6)
        validateEquals("int8Col", \Query<ModernAllTypesObject>.int8Col, Int8(9))
        validateEquals("int16Col", \Query<ModernAllTypesObject>.int16Col, Int16(17))
        validateEquals("int32Col", \Query<ModernAllTypesObject>.int32Col, Int32(33))
        validateEquals("int64Col", \Query<ModernAllTypesObject>.int64Col, Int64(65))
        validateEquals("floatCol", \Query<ModernAllTypesObject>.floatCol, Float(6.55444333))
        validateEquals("doubleCol", \Query<ModernAllTypesObject>.doubleCol, 234.567)
        validateEquals("stringCol", \Query<ModernAllTypesObject>.stringCol, "Foó")
        validateEquals("binaryCol", \Query<ModernAllTypesObject>.binaryCol, Data(count: 128))
        validateEquals("dateCol", \Query<ModernAllTypesObject>.dateCol, Date(timeIntervalSince1970: 2000000))
        validateEquals("decimalCol", \Query<ModernAllTypesObject>.decimalCol, Decimal128(234.567))
        validateEquals("objectIdCol", \Query<ModernAllTypesObject>.objectIdCol, ObjectId("61184062c1d8f096a3695045"))
        validateEquals("uuidCol", \Query<ModernAllTypesObject>.uuidCol, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)
        validateEquals("intEnumCol", \Query<ModernAllTypesObject>.intEnumCol, ModernIntEnum.value2)
        validateEquals("stringEnumCol", \Query<ModernAllTypesObject>.stringEnumCol, ModernStringEnum.value2)
        validateEquals("optBoolCol", \Query<ModernAllTypesObject>.optBoolCol, false)
        validateEquals("optIntCol", \Query<ModernAllTypesObject>.optIntCol, 6)
        validateEquals("optInt8Col", \Query<ModernAllTypesObject>.optInt8Col, Int8(9))
        validateEquals("optInt16Col", \Query<ModernAllTypesObject>.optInt16Col, Int16(17))
        validateEquals("optInt32Col", \Query<ModernAllTypesObject>.optInt32Col, Int32(33))
        validateEquals("optInt64Col", \Query<ModernAllTypesObject>.optInt64Col, Int64(65))
        validateEquals("optFloatCol", \Query<ModernAllTypesObject>.optFloatCol, Float(6.55444333))
        validateEquals("optDoubleCol", \Query<ModernAllTypesObject>.optDoubleCol, 234.567)
        validateEquals("optStringCol", \Query<ModernAllTypesObject>.optStringCol, "Foó")
        validateEquals("optBinaryCol", \Query<ModernAllTypesObject>.optBinaryCol, Data(count: 128))
        validateEquals("optDateCol", \Query<ModernAllTypesObject>.optDateCol, Date(timeIntervalSince1970: 2000000))
        validateEquals("optDecimalCol", \Query<ModernAllTypesObject>.optDecimalCol, Decimal128(234.567))
        validateEquals("optObjectIdCol", \Query<ModernAllTypesObject>.optObjectIdCol, ObjectId("61184062c1d8f096a3695045"))
        validateEquals("optUuidCol", \Query<ModernAllTypesObject>.optUuidCol, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)
        validateEquals("optIntEnumCol", \Query<ModernAllTypesObject>.optIntEnumCol, ModernIntEnum.value2)
        validateEquals("optStringEnumCol", \Query<ModernAllTypesObject>.optStringEnumCol, ModernStringEnum.value2)

        validateEqualsNil("optBoolCol", \Query<ModernAllTypesObject>.optBoolCol)
        validateEqualsNil("optIntCol", \Query<ModernAllTypesObject>.optIntCol)
        validateEqualsNil("optInt8Col", \Query<ModernAllTypesObject>.optInt8Col)
        validateEqualsNil("optInt16Col", \Query<ModernAllTypesObject>.optInt16Col)
        validateEqualsNil("optInt32Col", \Query<ModernAllTypesObject>.optInt32Col)
        validateEqualsNil("optInt64Col", \Query<ModernAllTypesObject>.optInt64Col)
        validateEqualsNil("optFloatCol", \Query<ModernAllTypesObject>.optFloatCol)
        validateEqualsNil("optDoubleCol", \Query<ModernAllTypesObject>.optDoubleCol)
        validateEqualsNil("optStringCol", \Query<ModernAllTypesObject>.optStringCol)
        validateEqualsNil("optBinaryCol", \Query<ModernAllTypesObject>.optBinaryCol)
        validateEqualsNil("optDateCol", \Query<ModernAllTypesObject>.optDateCol)
        validateEqualsNil("optDecimalCol", \Query<ModernAllTypesObject>.optDecimalCol)
        validateEqualsNil("optObjectIdCol", \Query<ModernAllTypesObject>.optObjectIdCol)
        validateEqualsNil("optUuidCol", \Query<ModernAllTypesObject>.optUuidCol)
        validateEqualsNil("optIntEnumCol", \Query<ModernAllTypesObject>.optIntEnumCol)
        validateEqualsNil("optStringEnumCol", \Query<ModernAllTypesObject>.optStringEnumCol)
    }

    func testEqualAnyRealmValue() {
        let circleObject = self.circleObject
        let object = objects()[0]
        setAnyRealmValueCol(with: .none, object: object)
        assertQuery("(anyCol == %@)", AnyRealmValue.none, count: 1) {
            $0.anyCol == .none
        }
        setAnyRealmValueCol(with: .int(123), object: object)
        assertQuery("(anyCol == %@)", AnyRealmValue.int(123), count: 1) {
            $0.anyCol == .int(123)
        }
        setAnyRealmValueCol(with: .bool(true), object: object)
        assertQuery("(anyCol == %@)", AnyRealmValue.bool(true), count: 1) {
            $0.anyCol == .bool(true)
        }
        setAnyRealmValueCol(with: .float(123.456), object: object)
        assertQuery("(anyCol == %@)", AnyRealmValue.float(123.456), count: 1) {
            $0.anyCol == .float(123.456)
        }
        setAnyRealmValueCol(with: .double(123.456), object: object)
        assertQuery("(anyCol == %@)", AnyRealmValue.double(123.456), count: 1) {
            $0.anyCol == .double(123.456)
        }
        setAnyRealmValueCol(with: .string("FooBar"), object: object)
        assertQuery("(anyCol == %@)", AnyRealmValue.string("FooBar"), count: 1) {
            $0.anyCol == .string("FooBar")
        }
        setAnyRealmValueCol(with: .data(Data(count: 64)), object: object)
        assertQuery("(anyCol == %@)", AnyRealmValue.data(Data(count: 64)), count: 1) {
            $0.anyCol == .data(Data(count: 64))
        }
        setAnyRealmValueCol(with: .date(Date(timeIntervalSince1970: 1000000)), object: object)
        assertQuery("(anyCol == %@)", AnyRealmValue.date(Date(timeIntervalSince1970: 1000000)), count: 1) {
            $0.anyCol == .date(Date(timeIntervalSince1970: 1000000))
        }
        setAnyRealmValueCol(with: .object(circleObject), object: object)
        assertQuery("(anyCol == %@)", AnyRealmValue.object(circleObject), count: 1) {
            $0.anyCol == .object(circleObject)
        }
        setAnyRealmValueCol(with: .objectId(ObjectId("61184062c1d8f096a3695046")), object: object)
        assertQuery("(anyCol == %@)", AnyRealmValue.objectId(ObjectId("61184062c1d8f096a3695046")), count: 1) {
            $0.anyCol == .objectId(ObjectId("61184062c1d8f096a3695046"))
        }
        setAnyRealmValueCol(with: .decimal128(123.456), object: object)
        assertQuery("(anyCol == %@)", AnyRealmValue.decimal128(123.456), count: 1) {
            $0.anyCol == .decimal128(123.456)
        }
        setAnyRealmValueCol(with: .uuid(UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!), object: object)
        assertQuery("(anyCol == %@)", AnyRealmValue.uuid(UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!), count: 1) {
            $0.anyCol == .uuid(UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!)
        }
    }

    func testEqualObject() {
        let nestedObject = ModernAllTypesObject()
        let object = objects().first!
        try! realm.write {
            object.objectCol = nestedObject
        }
        assertQuery("(objectCol == %@)", nestedObject, count: 1) {
            $0.objectCol == nestedObject
        }
    }

    func testEqualEmbeddedObject() {
        let object = ModernEmbeddedParentObject()
        let nestedObject = ModernEmbeddedTreeObject1()
        nestedObject.value = 123
        object.object = nestedObject
        try! realm.write {
            realm.add(object)
        }

        let result1 = realm.objects(ModernEmbeddedParentObject.self).where {
            $0.object == nestedObject
        }
        XCTAssertEqual(result1.count, 1)

        let nestedObject2 = ModernEmbeddedTreeObject1()
        nestedObject2.value = 123
        let result2 = realm.objects(ModernEmbeddedParentObject.self).where {
            $0.object == nestedObject2
        }
        XCTAssertEqual(result2.count, 0)
    }

    func testNotEqualAnyRealmValue() {
        let circleObject = self.circleObject
        let object = objects()[0]
        setAnyRealmValueCol(with: .none, object: object)
        assertQuery("(anyCol != %@)", AnyRealmValue.none, count: 0) {
            $0.anyCol != .none
        }
        setAnyRealmValueCol(with: .int(123), object: object)
        assertQuery("(anyCol != %@)", AnyRealmValue.int(123), count: 0) {
            $0.anyCol != .int(123)
        }
        setAnyRealmValueCol(with: .bool(true), object: object)
        assertQuery("(anyCol != %@)", AnyRealmValue.bool(true), count: 0) {
            $0.anyCol != .bool(true)
        }
        setAnyRealmValueCol(with: .float(123.456), object: object)
        assertQuery("(anyCol != %@)", AnyRealmValue.float(123.456), count: 0) {
            $0.anyCol != .float(123.456)
        }
        setAnyRealmValueCol(with: .double(123.456), object: object)
        assertQuery("(anyCol != %@)", AnyRealmValue.double(123.456), count: 0) {
            $0.anyCol != .double(123.456)
        }
        setAnyRealmValueCol(with: .string("FooBar"), object: object)
        assertQuery("(anyCol != %@)", AnyRealmValue.string("FooBar"), count: 0) {
            $0.anyCol != .string("FooBar")
        }
        setAnyRealmValueCol(with: .data(Data(count: 64)), object: object)
        assertQuery("(anyCol != %@)", AnyRealmValue.data(Data(count: 64)), count: 0) {
            $0.anyCol != .data(Data(count: 64))
        }
        setAnyRealmValueCol(with: .date(Date(timeIntervalSince1970: 1000000)), object: object)
        assertQuery("(anyCol != %@)", AnyRealmValue.date(Date(timeIntervalSince1970: 1000000)), count: 0) {
            $0.anyCol != .date(Date(timeIntervalSince1970: 1000000))
        }
        setAnyRealmValueCol(with: .object(circleObject), object: object)
        assertQuery("(anyCol != %@)", AnyRealmValue.object(circleObject), count: 0) {
            $0.anyCol != .object(circleObject)
        }
        setAnyRealmValueCol(with: .objectId(ObjectId("61184062c1d8f096a3695046")), object: object)
        assertQuery("(anyCol != %@)", AnyRealmValue.objectId(ObjectId("61184062c1d8f096a3695046")), count: 0) {
            $0.anyCol != .objectId(ObjectId("61184062c1d8f096a3695046"))
        }
        setAnyRealmValueCol(with: .decimal128(123.456), object: object)
        assertQuery("(anyCol != %@)", AnyRealmValue.decimal128(123.456), count: 0) {
            $0.anyCol != .decimal128(123.456)
        }
        setAnyRealmValueCol(with: .uuid(UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!), object: object)
        assertQuery("(anyCol != %@)", AnyRealmValue.uuid(UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!), count: 0) {
            $0.anyCol != .uuid(UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!)
        }
    }

    func testNotEqualObject() {
        let nestedObject = ModernAllTypesObject()
        let object = objects().first!
        try! realm.write {
            object.objectCol = nestedObject
        }
        // Count will be one because nestedObject.objectCol will be nil
        assertQuery("(objectCol != %@)", nestedObject, count: 1) {
            $0.objectCol != nestedObject
        }
    }

    func testNotEqualEmbeddedObject() {
        let object = ModernEmbeddedParentObject()
        let nestedObject = ModernEmbeddedTreeObject1()
        nestedObject.value = 123
        object.object = nestedObject
        try! realm.write {
            realm.add(object)
        }

        let result1 = realm.objects(ModernEmbeddedParentObject.self).where {
            $0.object != nestedObject
        }
        XCTAssertEqual(result1.count, 0)

        let nestedObject2 = ModernEmbeddedTreeObject1()
        nestedObject2.value = 123
        let result2 = realm.objects(ModernEmbeddedParentObject.self).where {
            $0.object != nestedObject2
        }
        XCTAssertEqual(result2.count, 1)
    }

    func validateNumericComparisons<T: _Persistable>(_ name: String, _ lhs: (Query<ModernAllTypesObject>) -> Query<T>,
                                                     _ value: T, count: Int = 1) where T.PersistedType: _QueryNumeric {
        assertQuery("(\(name) > %@)", value, count: 0) {
            lhs($0) > value
        }
        assertQuery("(\(name) >= %@)", value, count: count) {
            lhs($0) >= value
        }
        assertQuery("(\(name) < %@)", value, count: 0) {
            lhs($0) < value
        }
        assertQuery("(\(name) <= %@)", value, count: count) {
            lhs($0) <= value
        }
    }

    func testNumericComparisons() {
        validateNumericComparisons("intCol", \Query<ModernAllTypesObject>.intCol, 6)
        validateNumericComparisons("int8Col", \Query<ModernAllTypesObject>.int8Col, Int8(9))
        validateNumericComparisons("int16Col", \Query<ModernAllTypesObject>.int16Col, Int16(17))
        validateNumericComparisons("int32Col", \Query<ModernAllTypesObject>.int32Col, Int32(33))
        validateNumericComparisons("int64Col", \Query<ModernAllTypesObject>.int64Col, Int64(65))
        validateNumericComparisons("floatCol", \Query<ModernAllTypesObject>.floatCol, Float(6.55444333))
        validateNumericComparisons("doubleCol", \Query<ModernAllTypesObject>.doubleCol, 234.567)
        validateNumericComparisons("dateCol", \Query<ModernAllTypesObject>.dateCol, Date(timeIntervalSince1970: 2000000))
        validateNumericComparisons("decimalCol", \Query<ModernAllTypesObject>.decimalCol, Decimal128(234.567))
        validateNumericComparisons("intEnumCol", \Query<ModernAllTypesObject>.intEnumCol, .value2)
        validateNumericComparisons("optIntCol", \Query<ModernAllTypesObject>.optIntCol, 6)
        validateNumericComparisons("optInt8Col", \Query<ModernAllTypesObject>.optInt8Col, Int8(9))
        validateNumericComparisons("optInt16Col", \Query<ModernAllTypesObject>.optInt16Col, Int16(17))
        validateNumericComparisons("optInt32Col", \Query<ModernAllTypesObject>.optInt32Col, Int32(33))
        validateNumericComparisons("optInt64Col", \Query<ModernAllTypesObject>.optInt64Col, Int64(65))
        validateNumericComparisons("optFloatCol", \Query<ModernAllTypesObject>.optFloatCol, Float(6.55444333))
        validateNumericComparisons("optDoubleCol", \Query<ModernAllTypesObject>.optDoubleCol, 234.567)
        validateNumericComparisons("optDateCol", \Query<ModernAllTypesObject>.optDateCol, Date(timeIntervalSince1970: 2000000))
        validateNumericComparisons("optDecimalCol", \Query<ModernAllTypesObject>.optDecimalCol, Decimal128(234.567))
        validateNumericComparisons("optIntEnumCol", \Query<ModernAllTypesObject>.optIntEnumCol, .value2)

        validateNumericComparisons("optIntCol", \Query<ModernAllTypesObject>.optIntCol, nil, count: 0)
        validateNumericComparisons("optInt8Col", \Query<ModernAllTypesObject>.optInt8Col, nil, count: 0)
        validateNumericComparisons("optInt16Col", \Query<ModernAllTypesObject>.optInt16Col, nil, count: 0)
        validateNumericComparisons("optInt32Col", \Query<ModernAllTypesObject>.optInt32Col, nil, count: 0)
        validateNumericComparisons("optInt64Col", \Query<ModernAllTypesObject>.optInt64Col, nil, count: 0)
        validateNumericComparisons("optFloatCol", \Query<ModernAllTypesObject>.optFloatCol, nil, count: 0)
        validateNumericComparisons("optDoubleCol", \Query<ModernAllTypesObject>.optDoubleCol, nil, count: 0)
        validateNumericComparisons("optDateCol", \Query<ModernAllTypesObject>.optDateCol, nil, count: 0)
        validateNumericComparisons("optDecimalCol", \Query<ModernAllTypesObject>.optDecimalCol, nil, count: 0)
        validateNumericComparisons("optIntEnumCol", \Query<ModernAllTypesObject>.optIntEnumCol, nil, count: 0)
    }

    func testGreaterThanAnyRealmValue() {
        let object = objects()[0]
        setAnyRealmValueCol(with: .int(123), object: object)
        assertQuery("(anyCol > %@)", AnyRealmValue.int(123), count: 0) {
            $0.anyCol > .int(123)
        }
        assertQuery("(anyCol >= %@)", AnyRealmValue.int(123), count: 1) {
            $0.anyCol >= .int(123)
        }
        setAnyRealmValueCol(with: .float(123.456), object: object)
        assertQuery("(anyCol > %@)", AnyRealmValue.float(123.456), count: 0) {
            $0.anyCol > .float(123.456)
        }
        assertQuery("(anyCol >= %@)", AnyRealmValue.float(123.456), count: 1) {
            $0.anyCol >= .float(123.456)
        }
        setAnyRealmValueCol(with: .double(123.456), object: object)
        assertQuery("(anyCol > %@)", AnyRealmValue.double(123.456), count: 0) {
            $0.anyCol > .double(123.456)
        }
        assertQuery("(anyCol >= %@)", AnyRealmValue.double(123.456), count: 1) {
            $0.anyCol >= .double(123.456)
        }
        setAnyRealmValueCol(with: .date(Date(timeIntervalSince1970: 1000000)), object: object)
        assertQuery("(anyCol > %@)", AnyRealmValue.date(Date(timeIntervalSince1970: 1000000)), count: 0) {
            $0.anyCol > .date(Date(timeIntervalSince1970: 1000000))
        }
        assertQuery("(anyCol >= %@)", AnyRealmValue.date(Date(timeIntervalSince1970: 1000000)), count: 1) {
            $0.anyCol >= .date(Date(timeIntervalSince1970: 1000000))
        }
        setAnyRealmValueCol(with: .decimal128(123.456), object: object)
        assertQuery("(anyCol > %@)", AnyRealmValue.decimal128(123.456), count: 0) {
            $0.anyCol > .decimal128(123.456)
        }
        assertQuery("(anyCol >= %@)", AnyRealmValue.decimal128(123.456), count: 1) {
            $0.anyCol >= .decimal128(123.456)
        }
    }

    func testLessThanAnyRealmValue() {
        let object = objects()[0]
        setAnyRealmValueCol(with: .int(123), object: object)
        assertQuery("(anyCol < %@)", AnyRealmValue.int(123), count: 0) {
            $0.anyCol < .int(123)
        }
        assertQuery("(anyCol <= %@)", AnyRealmValue.int(123), count: 1) {
            $0.anyCol <= .int(123)
        }
        setAnyRealmValueCol(with: .float(123.456), object: object)
        assertQuery("(anyCol < %@)", AnyRealmValue.float(123.456), count: 0) {
            $0.anyCol < .float(123.456)
        }
        assertQuery("(anyCol <= %@)", AnyRealmValue.float(123.456), count: 1) {
            $0.anyCol <= .float(123.456)
        }
        setAnyRealmValueCol(with: .double(123.456), object: object)
        assertQuery("(anyCol < %@)", AnyRealmValue.double(123.456), count: 0) {
            $0.anyCol < .double(123.456)
        }
        assertQuery("(anyCol <= %@)", AnyRealmValue.double(123.456), count: 1) {
            $0.anyCol <= .double(123.456)
        }
        setAnyRealmValueCol(with: .date(Date(timeIntervalSince1970: 1000000)), object: object)
        assertQuery("(anyCol < %@)", AnyRealmValue.date(Date(timeIntervalSince1970: 1000000)), count: 0) {
            $0.anyCol < .date(Date(timeIntervalSince1970: 1000000))
        }
        assertQuery("(anyCol <= %@)", AnyRealmValue.date(Date(timeIntervalSince1970: 1000000)), count: 1) {
            $0.anyCol <= .date(Date(timeIntervalSince1970: 1000000))
        }
        setAnyRealmValueCol(with: .decimal128(123.456), object: object)
        assertQuery("(anyCol < %@)", AnyRealmValue.decimal128(123.456), count: 0) {
            $0.anyCol < .decimal128(123.456)
        }
        assertQuery("(anyCol <= %@)", AnyRealmValue.decimal128(123.456), count: 1) {
            $0.anyCol <= .decimal128(123.456)
        }
    }

    private func validateNumericContains<T: _RealmSchemaDiscoverable & QueryValue & Comparable>(
            _ name: String, _ lhs: (Query<ModernAllTypesObject>) -> Query<T>) {
        let values = T.queryValues()
        assertQuery("((\(name) >= %@) && (\(name) < %@))", values: [values[0], values[2]], count: 1) {
            lhs($0).contains(values[0]..<values[2])
        }
        assertQuery("((\(name) >= %@) && (\(name) < %@))", values: [values[0], values[1]], count: 0) {
            lhs($0).contains(values[0]..<values[1])
        }
        assertQuery("(\(name) BETWEEN {%@, %@})", values: [values[0], values[2]], count: 1) {
            lhs($0).contains(values[0]...values[2])
        }
        assertQuery("(\(name) BETWEEN {%@, %@})", values: [values[0], values[1]], count: 1) {
            lhs($0).contains(values[0]...values[1])
        }
    }
    private func validateNumericContains<T: _RealmSchemaDiscoverable & OptionalProtocol>(
            _ name: String, _ lhs: (Query<ModernAllTypesObject>) -> Query<T>) where T.Wrapped: Comparable & QueryValue {
        let values = T.Wrapped.queryValues()
        assertQuery("((\(name) >= %@) && (\(name) < %@))", values: [values[0], values[2]], count: 1) {
            lhs($0).contains(values[0]..<values[2])
        }
        assertQuery("((\(name) >= %@) && (\(name) < %@))", values: [values[0], values[1]], count: 0) {
            lhs($0).contains(values[0]..<values[1])
        }
        assertQuery("(\(name) BETWEEN {%@, %@})", values: [values[0], values[2]], count: 1) {
            lhs($0).contains(values[0]...values[2])
        }
        assertQuery("(\(name) BETWEEN {%@, %@})", values: [values[0], values[1]], count: 1) {
            lhs($0).contains(values[0]...values[1])
        }
    }

    func testNumericContains() {
        validateNumericContains("intCol", \Query<ModernAllTypesObject>.intCol)
        validateNumericContains("int8Col", \Query<ModernAllTypesObject>.int8Col)
        validateNumericContains("int16Col", \Query<ModernAllTypesObject>.int16Col)
        validateNumericContains("int32Col", \Query<ModernAllTypesObject>.int32Col)
        validateNumericContains("int64Col", \Query<ModernAllTypesObject>.int64Col)
        validateNumericContains("floatCol", \Query<ModernAllTypesObject>.floatCol)
        validateNumericContains("doubleCol", \Query<ModernAllTypesObject>.doubleCol)
        validateNumericContains("dateCol", \Query<ModernAllTypesObject>.dateCol)
        validateNumericContains("decimalCol", \Query<ModernAllTypesObject>.decimalCol)
        validateNumericContains("intEnumCol", \Query<ModernAllTypesObject>.intEnumCol)
        validateNumericContains("optIntCol", \Query<ModernAllTypesObject>.optIntCol)
        validateNumericContains("optInt8Col", \Query<ModernAllTypesObject>.optInt8Col)
        validateNumericContains("optInt16Col", \Query<ModernAllTypesObject>.optInt16Col)
        validateNumericContains("optInt32Col", \Query<ModernAllTypesObject>.optInt32Col)
        validateNumericContains("optInt64Col", \Query<ModernAllTypesObject>.optInt64Col)
        validateNumericContains("optFloatCol", \Query<ModernAllTypesObject>.optFloatCol)
        validateNumericContains("optDoubleCol", \Query<ModernAllTypesObject>.optDoubleCol)
        validateNumericContains("optDateCol", \Query<ModernAllTypesObject>.optDateCol)
        validateNumericContains("optDecimalCol", \Query<ModernAllTypesObject>.optDecimalCol)
        validateNumericContains("optIntEnumCol", \Query<ModernAllTypesObject>.optIntEnumCol)
    }

    // MARK: - Strings

    let stringModifiers: [(String, StringOptions)] = [
        ("", []),
        ("[c]", [.caseInsensitive]),
        ("[d]", [.diacriticInsensitive]),
        ("[cd]", [.caseInsensitive, .diacriticInsensitive]),
    ]

    private func validateStringOperations<T>(_ name: String, _ lhs: (Query<ModernAllTypesObject>) -> Query<T>,
                                             _ values: (T, T, T), count: Int)
            where T: _Persistable, T.PersistedType: _QueryString {
        let (full, prefix, suffix) = values
        for (modifier, options) in stringModifiers {
            assertQuery("(\(name) ==\(modifier) %@)", full, count: count) {
                lhs($0).equals(full, options: [options])
            }
            assertQuery("(NOT \(name) ==\(modifier) %@)", full, count: 1 - count) {
                !lhs($0).equals(full, options: [options])
            }
            assertQuery("(\(name) !=\(modifier) %@)", full, count: 1 - count) {
                lhs($0).notEquals(full, options: [options])
            }
            assertQuery("(NOT \(name) !=\(modifier) %@)", full, count: count) {
                !lhs($0).notEquals(full, options: [options])
            }

            assertQuery("(\(name) CONTAINS\(modifier) %@)", full, count: count) {
                lhs($0).contains(full, options: [options])
            }
            assertQuery("(NOT \(name) CONTAINS\(modifier) %@)", full, count: 1 - count) {
                !lhs($0).contains(full, options: [options])
            }

            assertQuery("(\(name) BEGINSWITH\(modifier) %@)", prefix, count: count) {
                lhs($0).starts(with: prefix, options: [options])
            }
            assertQuery("(NOT \(name) BEGINSWITH\(modifier) %@)", prefix, count: 1 - count) {
                !lhs($0).starts(with: prefix, options: [options])
            }

            assertQuery("(\(name) ENDSWITH\(modifier) %@)", suffix, count: count) {
                lhs($0).ends(with: suffix, options: [options])
            }
            assertQuery("(NOT \(name) ENDSWITH\(modifier) %@)", suffix, count: 1 - count) {
                !lhs($0).ends(with: suffix, options: [options])
            }
        }
    }

    func testStringOperations() {
        validateStringOperations("stringCol", \Query<ModernAllTypesObject>.stringCol, ("Foó", "Fo", "oó"), count: 1)
        validateStringOperations("stringEnumCol", \Query<ModernAllTypesObject>.stringEnumCol.rawValue, ("Foó", "Fo", "oó"), count: 0)
        validateStringOperations("optStringCol", \Query<ModernAllTypesObject>.optStringCol, ("Foó", "Fo", "oó"), count: 1)
        validateStringOperations("optStringEnumCol", \Query<ModernAllTypesObject>.optStringEnumCol.rawValue, ("Foó", "Fo", "oó"), count: 0)
    }

    private func validateStringLike<T>(_ name: String, _ lhs: (Query<ModernAllTypesObject>) -> Query<T>, _ strings: [(T, Int, Int)], canMatch: Bool)
            where T: _Persistable, T.PersistedType: _QueryString {
        for (str, sensitiveCount, insensitiveCount) in strings {
            assertQuery("(\(name) LIKE %@)", str, count: canMatch ? sensitiveCount : 0) {
                lhs($0).like(str)
            }
            assertQuery("(\(name) LIKE[c] %@)", str, count: canMatch ? insensitiveCount : 0) {
                lhs($0).like(str, caseInsensitive: true)
            }
        }
    }

    func testStringLike() {
        let likeStrings: [(String, Int, Int)] = [
            ("Foó", 1, 1),
            ("f*", 0, 1),
            ("*ó", 1, 1),
            ("f?ó", 0, 1),
            ("f*ó", 0, 1),
            ("f??ó", 0, 0),
            ("*o*", 1, 1),
            ("*O*", 0, 1),
            ("?o?", 1, 1),
            ("?O?", 0, 1)
        ]
        let likeStringsOptional = Array(likeStrings.map { (String?.some($0.0), $0.1, $0.2) })
        validateStringLike("stringCol", \Query<ModernAllTypesObject>.stringCol, likeStrings, canMatch: true)
        validateStringLike("stringEnumCol", \Query<ModernAllTypesObject>.stringEnumCol.rawValue, likeStrings, canMatch: false)
        validateStringLike("optStringCol", \Query<ModernAllTypesObject>.optStringCol, likeStringsOptional, canMatch: true)
        validateStringLike("optStringEnumCol", \Query<ModernAllTypesObject>.optStringEnumCol.rawValue, likeStringsOptional, canMatch: false)
    }

    // MARK: - Data

    func testBinarySearchQueries() {
        let zeroData = Data(count: 28)
        let oneData = Data(repeating: 1, count: 28)
        assertQuery("(binaryCol BEGINSWITH %@)", zeroData, count: 1) {
            $0.binaryCol.starts(with: zeroData)
        }

        assertQuery("(NOT binaryCol BEGINSWITH %@)", zeroData, count: 0) {
            !$0.binaryCol.starts(with: zeroData)
        }

        assertQuery("(binaryCol ENDSWITH %@)", zeroData, count: 1) {
            $0.binaryCol.ends(with: zeroData)
        }

        assertQuery("(NOT binaryCol ENDSWITH %@)", zeroData, count: 0) {
            !$0.binaryCol.ends(with: zeroData)
        }

        assertQuery("(binaryCol CONTAINS %@)", zeroData, count: 1) {
            $0.binaryCol.contains(zeroData)
        }

        assertQuery("(NOT binaryCol CONTAINS %@)", zeroData, count: 0) {
            !$0.binaryCol.contains(zeroData)
        }

        assertQuery("(binaryCol == %@)", zeroData, count: 0) {
            $0.binaryCol.equals(zeroData)
        }

        assertQuery("(NOT binaryCol == %@)", zeroData, count: 1) {
            !$0.binaryCol.equals(zeroData)
        }

        assertQuery("(binaryCol != %@)", zeroData, count: 1) {
            $0.binaryCol.notEquals(zeroData)
        }

        assertQuery("(NOT binaryCol != %@)", zeroData, count: 0) {
            !$0.binaryCol.notEquals(zeroData)
        }

        assertQuery("(binaryCol BEGINSWITH %@)", oneData, count: 0) {
            $0.binaryCol.starts(with: oneData)
        }

        assertQuery("(binaryCol ENDSWITH %@)", oneData, count: 0) {
            $0.binaryCol.ends(with: oneData)
        }

        assertQuery("(binaryCol CONTAINS %@)", oneData, count: 0) {
            $0.binaryCol.contains(oneData)
        }

        assertQuery("(NOT binaryCol CONTAINS %@)", oneData, count: 1) {
            !$0.binaryCol.contains(oneData)
        }

        assertQuery("(binaryCol CONTAINS %@)", oneData, count: 0) {
            $0.binaryCol.contains(oneData)
        }

        assertQuery("(NOT binaryCol CONTAINS %@)", oneData, count: 1) {
            !$0.binaryCol.contains(oneData)
        }

        assertQuery("(binaryCol == %@)", oneData, count: 0) {
            $0.binaryCol.equals(oneData)
        }

        assertQuery("(NOT binaryCol == %@)", oneData, count: 1) {
            !$0.binaryCol.equals(oneData)
        }

        assertQuery("(binaryCol != %@)", oneData, count: 1) {
            $0.binaryCol.notEquals(oneData)
        }

        assertQuery("(NOT binaryCol != %@)", oneData, count: 0) {
            !$0.binaryCol.notEquals(oneData)
        }

        assertQuery("(optBinaryCol BEGINSWITH %@)", zeroData, count: 1) {
            $0.optBinaryCol.starts(with: zeroData)
        }

        assertQuery("(NOT optBinaryCol BEGINSWITH %@)", zeroData, count: 0) {
            !$0.optBinaryCol.starts(with: zeroData)
        }

        assertQuery("(optBinaryCol ENDSWITH %@)", zeroData, count: 1) {
            $0.optBinaryCol.ends(with: zeroData)
        }

        assertQuery("(NOT optBinaryCol ENDSWITH %@)", zeroData, count: 0) {
            !$0.optBinaryCol.ends(with: zeroData)
        }

        assertQuery("(optBinaryCol CONTAINS %@)", zeroData, count: 1) {
            $0.optBinaryCol.contains(zeroData)
        }

        assertQuery("(NOT optBinaryCol CONTAINS %@)", zeroData, count: 0) {
            !$0.optBinaryCol.contains(zeroData)
        }

        assertQuery("(optBinaryCol == %@)", zeroData, count: 0) {
            $0.optBinaryCol.equals(zeroData)
        }

        assertQuery("(NOT optBinaryCol == %@)", zeroData, count: 1) {
            !$0.optBinaryCol.equals(zeroData)
        }

        assertQuery("(optBinaryCol != %@)", zeroData, count: 1) {
            $0.optBinaryCol.notEquals(zeroData)
        }

        assertQuery("(NOT optBinaryCol != %@)", zeroData, count: 0) {
            !$0.optBinaryCol.notEquals(zeroData)
        }

        assertQuery("(optBinaryCol BEGINSWITH %@)", oneData, count: 0) {
            $0.optBinaryCol.starts(with: oneData)
        }

        assertQuery("(optBinaryCol ENDSWITH %@)", oneData, count: 0) {
            $0.optBinaryCol.ends(with: oneData)
        }

        assertQuery("(optBinaryCol CONTAINS %@)", oneData, count: 0) {
            $0.optBinaryCol.contains(oneData)
        }

        assertQuery("(NOT optBinaryCol CONTAINS %@)", oneData, count: 1) {
            !$0.optBinaryCol.contains(oneData)
        }

        assertQuery("(optBinaryCol CONTAINS %@)", oneData, count: 0) {
            $0.optBinaryCol.contains(oneData)
        }

        assertQuery("(NOT optBinaryCol CONTAINS %@)", oneData, count: 1) {
            !$0.optBinaryCol.contains(oneData)
        }

        assertQuery("(optBinaryCol == %@)", oneData, count: 0) {
            $0.optBinaryCol.equals(oneData)
        }

        assertQuery("(NOT optBinaryCol == %@)", oneData, count: 1) {
            !$0.optBinaryCol.equals(oneData)
        }

        assertQuery("(optBinaryCol != %@)", oneData, count: 1) {
            $0.optBinaryCol.notEquals(oneData)
        }

        assertQuery("(NOT optBinaryCol != %@)", oneData, count: 0) {
            !$0.optBinaryCol.notEquals(oneData)
        }

    }

    // MARK: - Array/Set

    private func validateCollectionContains<Root: Object, T: RealmCollection>(_ name: String, _ lhs: (Query<Root>) -> Query<T>)
            where T.Element: QueryValue {
        let values = T.Element.queryValues()

        assertQuery(Root.self, "(%@ IN \(name))", values[0], count: 1) {
            lhs($0).contains(values[0])
        }
        assertQuery(Root.self, "(%@ IN \(name))", values[2], count: 0) {
            lhs($0).contains(values[2])
        }

        assertQuery(Root.self, "(NOT %@ IN \(name))", values[0], count: 0) {
            !lhs($0).contains(values[0])
        }
        assertQuery(Root.self, "(NOT %@ IN \(name))", values[2], count: 1) {
            !lhs($0).contains(values[2])
        }
    }
    private func validateCollectionContainsNil<Root: Object, T: RealmCollection>(_ name: String, _ lhs: (Query<Root>) -> Query<T>)
            where T.Element: QueryValue & ExpressibleByNilLiteral {
        assertQuery(Root.self, "(%@ IN \(name))", NSNull(), count: 0) {
            lhs($0).contains(nil)
        }
        assertQuery(Root.self, "(NOT %@ IN \(name))", NSNull(), count: 1) {
            !lhs($0).contains(nil)
        }
    }
    private func validateCollectionContains<Root: Object, T: RealmKeyedCollection>(_ name: String, _ lhs: (Query<Root>) -> Query<T>)
            where T.Value: QueryValue {
        let values = T.Value.queryValues()

        assertQuery(Root.self, "(%@ IN \(name))", values[0], count: 1) {
            lhs($0).contains(values[0])
        }
        assertQuery(Root.self, "(%@ IN \(name))", values[2], count: 0) {
            lhs($0).contains(values[2])
        }

        assertQuery(Root.self, "(NOT %@ IN \(name))", values[0], count: 0) {
            !lhs($0).contains(values[0])
        }
        assertQuery(Root.self, "(NOT %@ IN \(name))", values[2], count: 1) {
            !lhs($0).contains(values[2])
        }
    }
    private func validateCollectionContainsNil<Root: Object, T: RealmKeyedCollection>(_ name: String, _ lhs: (Query<Root>) -> Query<T>)
            where T.Value: QueryValue & ExpressibleByNilLiteral {
        assertQuery(Root.self, "(%@ IN \(name))", NSNull(), count: 0) {
            lhs($0).contains(nil)
        }
        assertQuery(Root.self, "(NOT %@ IN \(name))", NSNull(), count: 1) {
            !lhs($0).contains(nil)
        }
    }

    func testCollectionContainsElement() {
        validateCollectionContains("arrayBool", \Query<ModernAllTypesObject>.arrayBool)
        validateCollectionContains("arrayInt", \Query<ModernAllTypesObject>.arrayInt)
        validateCollectionContains("arrayInt8", \Query<ModernAllTypesObject>.arrayInt8)
        validateCollectionContains("arrayInt16", \Query<ModernAllTypesObject>.arrayInt16)
        validateCollectionContains("arrayInt32", \Query<ModernAllTypesObject>.arrayInt32)
        validateCollectionContains("arrayInt64", \Query<ModernAllTypesObject>.arrayInt64)
        validateCollectionContains("arrayFloat", \Query<ModernAllTypesObject>.arrayFloat)
        validateCollectionContains("arrayDouble", \Query<ModernAllTypesObject>.arrayDouble)
        validateCollectionContains("arrayString", \Query<ModernAllTypesObject>.arrayString)
        validateCollectionContains("arrayBinary", \Query<ModernAllTypesObject>.arrayBinary)
        validateCollectionContains("arrayDate", \Query<ModernAllTypesObject>.arrayDate)
        validateCollectionContains("arrayDecimal", \Query<ModernAllTypesObject>.arrayDecimal)
        validateCollectionContains("arrayObjectId", \Query<ModernAllTypesObject>.arrayObjectId)
        validateCollectionContains("arrayUuid", \Query<ModernAllTypesObject>.arrayUuid)
        validateCollectionContains("arrayAny", \Query<ModernAllTypesObject>.arrayAny)
        validateCollectionContains("listInt", \Query<ModernCollectionsOfEnums>.listInt)
        validateCollectionContains("listInt8", \Query<ModernCollectionsOfEnums>.listInt8)
        validateCollectionContains("listInt16", \Query<ModernCollectionsOfEnums>.listInt16)
        validateCollectionContains("listInt32", \Query<ModernCollectionsOfEnums>.listInt32)
        validateCollectionContains("listInt64", \Query<ModernCollectionsOfEnums>.listInt64)
        validateCollectionContains("listFloat", \Query<ModernCollectionsOfEnums>.listFloat)
        validateCollectionContains("listDouble", \Query<ModernCollectionsOfEnums>.listDouble)
        validateCollectionContains("listString", \Query<ModernCollectionsOfEnums>.listString)
        validateCollectionContains("arrayOptBool", \Query<ModernAllTypesObject>.arrayOptBool)
        validateCollectionContains("arrayOptInt", \Query<ModernAllTypesObject>.arrayOptInt)
        validateCollectionContains("arrayOptInt8", \Query<ModernAllTypesObject>.arrayOptInt8)
        validateCollectionContains("arrayOptInt16", \Query<ModernAllTypesObject>.arrayOptInt16)
        validateCollectionContains("arrayOptInt32", \Query<ModernAllTypesObject>.arrayOptInt32)
        validateCollectionContains("arrayOptInt64", \Query<ModernAllTypesObject>.arrayOptInt64)
        validateCollectionContains("arrayOptFloat", \Query<ModernAllTypesObject>.arrayOptFloat)
        validateCollectionContains("arrayOptDouble", \Query<ModernAllTypesObject>.arrayOptDouble)
        validateCollectionContains("arrayOptString", \Query<ModernAllTypesObject>.arrayOptString)
        validateCollectionContains("arrayOptBinary", \Query<ModernAllTypesObject>.arrayOptBinary)
        validateCollectionContains("arrayOptDate", \Query<ModernAllTypesObject>.arrayOptDate)
        validateCollectionContains("arrayOptDecimal", \Query<ModernAllTypesObject>.arrayOptDecimal)
        validateCollectionContains("arrayOptObjectId", \Query<ModernAllTypesObject>.arrayOptObjectId)
        validateCollectionContains("arrayOptUuid", \Query<ModernAllTypesObject>.arrayOptUuid)
        validateCollectionContains("listIntOpt", \Query<ModernCollectionsOfEnums>.listIntOpt)
        validateCollectionContains("listInt8Opt", \Query<ModernCollectionsOfEnums>.listInt8Opt)
        validateCollectionContains("listInt16Opt", \Query<ModernCollectionsOfEnums>.listInt16Opt)
        validateCollectionContains("listInt32Opt", \Query<ModernCollectionsOfEnums>.listInt32Opt)
        validateCollectionContains("listInt64Opt", \Query<ModernCollectionsOfEnums>.listInt64Opt)
        validateCollectionContains("listFloatOpt", \Query<ModernCollectionsOfEnums>.listFloatOpt)
        validateCollectionContains("listDoubleOpt", \Query<ModernCollectionsOfEnums>.listDoubleOpt)
        validateCollectionContains("listStringOpt", \Query<ModernCollectionsOfEnums>.listStringOpt)
        validateCollectionContains("setBool", \Query<ModernAllTypesObject>.setBool)
        validateCollectionContains("setInt", \Query<ModernAllTypesObject>.setInt)
        validateCollectionContains("setInt8", \Query<ModernAllTypesObject>.setInt8)
        validateCollectionContains("setInt16", \Query<ModernAllTypesObject>.setInt16)
        validateCollectionContains("setInt32", \Query<ModernAllTypesObject>.setInt32)
        validateCollectionContains("setInt64", \Query<ModernAllTypesObject>.setInt64)
        validateCollectionContains("setFloat", \Query<ModernAllTypesObject>.setFloat)
        validateCollectionContains("setDouble", \Query<ModernAllTypesObject>.setDouble)
        validateCollectionContains("setString", \Query<ModernAllTypesObject>.setString)
        validateCollectionContains("setBinary", \Query<ModernAllTypesObject>.setBinary)
        validateCollectionContains("setDate", \Query<ModernAllTypesObject>.setDate)
        validateCollectionContains("setDecimal", \Query<ModernAllTypesObject>.setDecimal)
        validateCollectionContains("setObjectId", \Query<ModernAllTypesObject>.setObjectId)
        validateCollectionContains("setUuid", \Query<ModernAllTypesObject>.setUuid)
        validateCollectionContains("setAny", \Query<ModernAllTypesObject>.setAny)
        validateCollectionContains("setInt", \Query<ModernCollectionsOfEnums>.setInt)
        validateCollectionContains("setInt8", \Query<ModernCollectionsOfEnums>.setInt8)
        validateCollectionContains("setInt16", \Query<ModernCollectionsOfEnums>.setInt16)
        validateCollectionContains("setInt32", \Query<ModernCollectionsOfEnums>.setInt32)
        validateCollectionContains("setInt64", \Query<ModernCollectionsOfEnums>.setInt64)
        validateCollectionContains("setFloat", \Query<ModernCollectionsOfEnums>.setFloat)
        validateCollectionContains("setDouble", \Query<ModernCollectionsOfEnums>.setDouble)
        validateCollectionContains("setString", \Query<ModernCollectionsOfEnums>.setString)
        validateCollectionContains("setOptBool", \Query<ModernAllTypesObject>.setOptBool)
        validateCollectionContains("setOptInt", \Query<ModernAllTypesObject>.setOptInt)
        validateCollectionContains("setOptInt8", \Query<ModernAllTypesObject>.setOptInt8)
        validateCollectionContains("setOptInt16", \Query<ModernAllTypesObject>.setOptInt16)
        validateCollectionContains("setOptInt32", \Query<ModernAllTypesObject>.setOptInt32)
        validateCollectionContains("setOptInt64", \Query<ModernAllTypesObject>.setOptInt64)
        validateCollectionContains("setOptFloat", \Query<ModernAllTypesObject>.setOptFloat)
        validateCollectionContains("setOptDouble", \Query<ModernAllTypesObject>.setOptDouble)
        validateCollectionContains("setOptString", \Query<ModernAllTypesObject>.setOptString)
        validateCollectionContains("setOptBinary", \Query<ModernAllTypesObject>.setOptBinary)
        validateCollectionContains("setOptDate", \Query<ModernAllTypesObject>.setOptDate)
        validateCollectionContains("setOptDecimal", \Query<ModernAllTypesObject>.setOptDecimal)
        validateCollectionContains("setOptObjectId", \Query<ModernAllTypesObject>.setOptObjectId)
        validateCollectionContains("setOptUuid", \Query<ModernAllTypesObject>.setOptUuid)
        validateCollectionContains("setIntOpt", \Query<ModernCollectionsOfEnums>.setIntOpt)
        validateCollectionContains("setInt8Opt", \Query<ModernCollectionsOfEnums>.setInt8Opt)
        validateCollectionContains("setInt16Opt", \Query<ModernCollectionsOfEnums>.setInt16Opt)
        validateCollectionContains("setInt32Opt", \Query<ModernCollectionsOfEnums>.setInt32Opt)
        validateCollectionContains("setInt64Opt", \Query<ModernCollectionsOfEnums>.setInt64Opt)
        validateCollectionContains("setFloatOpt", \Query<ModernCollectionsOfEnums>.setFloatOpt)
        validateCollectionContains("setDoubleOpt", \Query<ModernCollectionsOfEnums>.setDoubleOpt)
        validateCollectionContains("setStringOpt", \Query<ModernCollectionsOfEnums>.setStringOpt)
        validateCollectionContains("mapBool", \Query<ModernAllTypesObject>.mapBool)
        validateCollectionContains("mapInt", \Query<ModernAllTypesObject>.mapInt)
        validateCollectionContains("mapInt8", \Query<ModernAllTypesObject>.mapInt8)
        validateCollectionContains("mapInt16", \Query<ModernAllTypesObject>.mapInt16)
        validateCollectionContains("mapInt32", \Query<ModernAllTypesObject>.mapInt32)
        validateCollectionContains("mapInt64", \Query<ModernAllTypesObject>.mapInt64)
        validateCollectionContains("mapFloat", \Query<ModernAllTypesObject>.mapFloat)
        validateCollectionContains("mapDouble", \Query<ModernAllTypesObject>.mapDouble)
        validateCollectionContains("mapString", \Query<ModernAllTypesObject>.mapString)
        validateCollectionContains("mapBinary", \Query<ModernAllTypesObject>.mapBinary)
        validateCollectionContains("mapDate", \Query<ModernAllTypesObject>.mapDate)
        validateCollectionContains("mapDecimal", \Query<ModernAllTypesObject>.mapDecimal)
        validateCollectionContains("mapObjectId", \Query<ModernAllTypesObject>.mapObjectId)
        validateCollectionContains("mapUuid", \Query<ModernAllTypesObject>.mapUuid)
        validateCollectionContains("mapAny", \Query<ModernAllTypesObject>.mapAny)
        validateCollectionContains("mapInt", \Query<ModernCollectionsOfEnums>.mapInt)
        validateCollectionContains("mapInt8", \Query<ModernCollectionsOfEnums>.mapInt8)
        validateCollectionContains("mapInt16", \Query<ModernCollectionsOfEnums>.mapInt16)
        validateCollectionContains("mapInt32", \Query<ModernCollectionsOfEnums>.mapInt32)
        validateCollectionContains("mapInt64", \Query<ModernCollectionsOfEnums>.mapInt64)
        validateCollectionContains("mapFloat", \Query<ModernCollectionsOfEnums>.mapFloat)
        validateCollectionContains("mapDouble", \Query<ModernCollectionsOfEnums>.mapDouble)
        validateCollectionContains("mapString", \Query<ModernCollectionsOfEnums>.mapString)
        validateCollectionContains("mapOptBool", \Query<ModernAllTypesObject>.mapOptBool)
        validateCollectionContains("mapOptInt", \Query<ModernAllTypesObject>.mapOptInt)
        validateCollectionContains("mapOptInt8", \Query<ModernAllTypesObject>.mapOptInt8)
        validateCollectionContains("mapOptInt16", \Query<ModernAllTypesObject>.mapOptInt16)
        validateCollectionContains("mapOptInt32", \Query<ModernAllTypesObject>.mapOptInt32)
        validateCollectionContains("mapOptInt64", \Query<ModernAllTypesObject>.mapOptInt64)
        validateCollectionContains("mapOptFloat", \Query<ModernAllTypesObject>.mapOptFloat)
        validateCollectionContains("mapOptDouble", \Query<ModernAllTypesObject>.mapOptDouble)
        validateCollectionContains("mapOptString", \Query<ModernAllTypesObject>.mapOptString)
        validateCollectionContains("mapOptBinary", \Query<ModernAllTypesObject>.mapOptBinary)
        validateCollectionContains("mapOptDate", \Query<ModernAllTypesObject>.mapOptDate)
        validateCollectionContains("mapOptDecimal", \Query<ModernAllTypesObject>.mapOptDecimal)
        validateCollectionContains("mapOptObjectId", \Query<ModernAllTypesObject>.mapOptObjectId)
        validateCollectionContains("mapOptUuid", \Query<ModernAllTypesObject>.mapOptUuid)
        validateCollectionContains("mapIntOpt", \Query<ModernCollectionsOfEnums>.mapIntOpt)
        validateCollectionContains("mapInt8Opt", \Query<ModernCollectionsOfEnums>.mapInt8Opt)
        validateCollectionContains("mapInt16Opt", \Query<ModernCollectionsOfEnums>.mapInt16Opt)
        validateCollectionContains("mapInt32Opt", \Query<ModernCollectionsOfEnums>.mapInt32Opt)
        validateCollectionContains("mapInt64Opt", \Query<ModernCollectionsOfEnums>.mapInt64Opt)
        validateCollectionContains("mapFloatOpt", \Query<ModernCollectionsOfEnums>.mapFloatOpt)
        validateCollectionContains("mapDoubleOpt", \Query<ModernCollectionsOfEnums>.mapDoubleOpt)
        validateCollectionContains("mapStringOpt", \Query<ModernCollectionsOfEnums>.mapStringOpt)

        validateCollectionContainsNil("arrayOptBool", \Query<ModernAllTypesObject>.arrayOptBool)
        validateCollectionContainsNil("arrayOptInt", \Query<ModernAllTypesObject>.arrayOptInt)
        validateCollectionContainsNil("arrayOptInt8", \Query<ModernAllTypesObject>.arrayOptInt8)
        validateCollectionContainsNil("arrayOptInt16", \Query<ModernAllTypesObject>.arrayOptInt16)
        validateCollectionContainsNil("arrayOptInt32", \Query<ModernAllTypesObject>.arrayOptInt32)
        validateCollectionContainsNil("arrayOptInt64", \Query<ModernAllTypesObject>.arrayOptInt64)
        validateCollectionContainsNil("arrayOptFloat", \Query<ModernAllTypesObject>.arrayOptFloat)
        validateCollectionContainsNil("arrayOptDouble", \Query<ModernAllTypesObject>.arrayOptDouble)
        validateCollectionContainsNil("arrayOptString", \Query<ModernAllTypesObject>.arrayOptString)
        validateCollectionContainsNil("arrayOptBinary", \Query<ModernAllTypesObject>.arrayOptBinary)
        validateCollectionContainsNil("arrayOptDate", \Query<ModernAllTypesObject>.arrayOptDate)
        validateCollectionContainsNil("arrayOptDecimal", \Query<ModernAllTypesObject>.arrayOptDecimal)
        validateCollectionContainsNil("arrayOptObjectId", \Query<ModernAllTypesObject>.arrayOptObjectId)
        validateCollectionContainsNil("arrayOptUuid", \Query<ModernAllTypesObject>.arrayOptUuid)
        validateCollectionContainsNil("listIntOpt", \Query<ModernCollectionsOfEnums>.listIntOpt)
        validateCollectionContainsNil("listInt8Opt", \Query<ModernCollectionsOfEnums>.listInt8Opt)
        validateCollectionContainsNil("listInt16Opt", \Query<ModernCollectionsOfEnums>.listInt16Opt)
        validateCollectionContainsNil("listInt32Opt", \Query<ModernCollectionsOfEnums>.listInt32Opt)
        validateCollectionContainsNil("listInt64Opt", \Query<ModernCollectionsOfEnums>.listInt64Opt)
        validateCollectionContainsNil("listFloatOpt", \Query<ModernCollectionsOfEnums>.listFloatOpt)
        validateCollectionContainsNil("listDoubleOpt", \Query<ModernCollectionsOfEnums>.listDoubleOpt)
        validateCollectionContainsNil("listStringOpt", \Query<ModernCollectionsOfEnums>.listStringOpt)
        validateCollectionContainsNil("setOptBool", \Query<ModernAllTypesObject>.setOptBool)
        validateCollectionContainsNil("setOptInt", \Query<ModernAllTypesObject>.setOptInt)
        validateCollectionContainsNil("setOptInt8", \Query<ModernAllTypesObject>.setOptInt8)
        validateCollectionContainsNil("setOptInt16", \Query<ModernAllTypesObject>.setOptInt16)
        validateCollectionContainsNil("setOptInt32", \Query<ModernAllTypesObject>.setOptInt32)
        validateCollectionContainsNil("setOptInt64", \Query<ModernAllTypesObject>.setOptInt64)
        validateCollectionContainsNil("setOptFloat", \Query<ModernAllTypesObject>.setOptFloat)
        validateCollectionContainsNil("setOptDouble", \Query<ModernAllTypesObject>.setOptDouble)
        validateCollectionContainsNil("setOptString", \Query<ModernAllTypesObject>.setOptString)
        validateCollectionContainsNil("setOptBinary", \Query<ModernAllTypesObject>.setOptBinary)
        validateCollectionContainsNil("setOptDate", \Query<ModernAllTypesObject>.setOptDate)
        validateCollectionContainsNil("setOptDecimal", \Query<ModernAllTypesObject>.setOptDecimal)
        validateCollectionContainsNil("setOptObjectId", \Query<ModernAllTypesObject>.setOptObjectId)
        validateCollectionContainsNil("setOptUuid", \Query<ModernAllTypesObject>.setOptUuid)
        validateCollectionContainsNil("setIntOpt", \Query<ModernCollectionsOfEnums>.setIntOpt)
        validateCollectionContainsNil("setInt8Opt", \Query<ModernCollectionsOfEnums>.setInt8Opt)
        validateCollectionContainsNil("setInt16Opt", \Query<ModernCollectionsOfEnums>.setInt16Opt)
        validateCollectionContainsNil("setInt32Opt", \Query<ModernCollectionsOfEnums>.setInt32Opt)
        validateCollectionContainsNil("setInt64Opt", \Query<ModernCollectionsOfEnums>.setInt64Opt)
        validateCollectionContainsNil("setFloatOpt", \Query<ModernCollectionsOfEnums>.setFloatOpt)
        validateCollectionContainsNil("setDoubleOpt", \Query<ModernCollectionsOfEnums>.setDoubleOpt)
        validateCollectionContainsNil("setStringOpt", \Query<ModernCollectionsOfEnums>.setStringOpt)
        validateCollectionContainsNil("mapOptBool", \Query<ModernAllTypesObject>.mapOptBool)
        validateCollectionContainsNil("mapOptInt", \Query<ModernAllTypesObject>.mapOptInt)
        validateCollectionContainsNil("mapOptInt8", \Query<ModernAllTypesObject>.mapOptInt8)
        validateCollectionContainsNil("mapOptInt16", \Query<ModernAllTypesObject>.mapOptInt16)
        validateCollectionContainsNil("mapOptInt32", \Query<ModernAllTypesObject>.mapOptInt32)
        validateCollectionContainsNil("mapOptInt64", \Query<ModernAllTypesObject>.mapOptInt64)
        validateCollectionContainsNil("mapOptFloat", \Query<ModernAllTypesObject>.mapOptFloat)
        validateCollectionContainsNil("mapOptDouble", \Query<ModernAllTypesObject>.mapOptDouble)
        validateCollectionContainsNil("mapOptString", \Query<ModernAllTypesObject>.mapOptString)
        validateCollectionContainsNil("mapOptBinary", \Query<ModernAllTypesObject>.mapOptBinary)
        validateCollectionContainsNil("mapOptDate", \Query<ModernAllTypesObject>.mapOptDate)
        validateCollectionContainsNil("mapOptDecimal", \Query<ModernAllTypesObject>.mapOptDecimal)
        validateCollectionContainsNil("mapOptObjectId", \Query<ModernAllTypesObject>.mapOptObjectId)
        validateCollectionContainsNil("mapOptUuid", \Query<ModernAllTypesObject>.mapOptUuid)
        validateCollectionContainsNil("mapIntOpt", \Query<ModernCollectionsOfEnums>.mapIntOpt)
        validateCollectionContainsNil("mapInt8Opt", \Query<ModernCollectionsOfEnums>.mapInt8Opt)
        validateCollectionContainsNil("mapInt16Opt", \Query<ModernCollectionsOfEnums>.mapInt16Opt)
        validateCollectionContainsNil("mapInt32Opt", \Query<ModernCollectionsOfEnums>.mapInt32Opt)
        validateCollectionContainsNil("mapInt64Opt", \Query<ModernCollectionsOfEnums>.mapInt64Opt)
        validateCollectionContainsNil("mapFloatOpt", \Query<ModernCollectionsOfEnums>.mapFloatOpt)
        validateCollectionContainsNil("mapDoubleOpt", \Query<ModernCollectionsOfEnums>.mapDoubleOpt)
        validateCollectionContainsNil("mapStringOpt", \Query<ModernCollectionsOfEnums>.mapStringOpt)
    }

    func testListContainsObject() {
        let obj = objects().first!
        let colObj = collectionObject()
        let result1 = realm.objects(ModernCollectionObject.self).where {
            $0.list.contains(obj)
        }
        XCTAssertEqual(result1.count, 0)
        try! realm.write {
            colObj.list.append(obj)
        }
        let result2 = realm.objects(ModernCollectionObject.self).where {
            $0.list.contains(obj)
        }
        XCTAssertEqual(result2.count, 1)
    }

    func testCollectionContainsRange() {
        assertQuery(ModernAllTypesObject.self, "((arrayInt.@min >= %@) && (arrayInt.@max <= %@))",
                    values: [5, 6], count: 1) {
            $0.arrayInt.contains(5...6)
        }
        assertQuery(ModernAllTypesObject.self, "((arrayInt.@min >= %@) && (arrayInt.@max < %@))",
                    values: [5, 6], count: 0) {
            $0.arrayInt.contains(5..<6)
        }
        assertQuery(ModernAllTypesObject.self, "((arrayInt8.@min >= %@) && (arrayInt8.@max <= %@))",
                    values: [Int8(8), Int8(9)], count: 1) {
            $0.arrayInt8.contains(Int8(8)...Int8(9))
        }
        assertQuery(ModernAllTypesObject.self, "((arrayInt8.@min >= %@) && (arrayInt8.@max < %@))",
                    values: [Int8(8), Int8(9)], count: 0) {
            $0.arrayInt8.contains(Int8(8)..<Int8(9))
        }
        assertQuery(ModernAllTypesObject.self, "((arrayInt16.@min >= %@) && (arrayInt16.@max <= %@))",
                    values: [Int16(16), Int16(17)], count: 1) {
            $0.arrayInt16.contains(Int16(16)...Int16(17))
        }
        assertQuery(ModernAllTypesObject.self, "((arrayInt16.@min >= %@) && (arrayInt16.@max < %@))",
                    values: [Int16(16), Int16(17)], count: 0) {
            $0.arrayInt16.contains(Int16(16)..<Int16(17))
        }
        assertQuery(ModernAllTypesObject.self, "((arrayInt32.@min >= %@) && (arrayInt32.@max <= %@))",
                    values: [Int32(32), Int32(33)], count: 1) {
            $0.arrayInt32.contains(Int32(32)...Int32(33))
        }
        assertQuery(ModernAllTypesObject.self, "((arrayInt32.@min >= %@) && (arrayInt32.@max < %@))",
                    values: [Int32(32), Int32(33)], count: 0) {
            $0.arrayInt32.contains(Int32(32)..<Int32(33))
        }
        assertQuery(ModernAllTypesObject.self, "((arrayInt64.@min >= %@) && (arrayInt64.@max <= %@))",
                    values: [Int64(64), Int64(65)], count: 1) {
            $0.arrayInt64.contains(Int64(64)...Int64(65))
        }
        assertQuery(ModernAllTypesObject.self, "((arrayInt64.@min >= %@) && (arrayInt64.@max < %@))",
                    values: [Int64(64), Int64(65)], count: 0) {
            $0.arrayInt64.contains(Int64(64)..<Int64(65))
        }
        assertQuery(ModernAllTypesObject.self, "((arrayFloat.@min >= %@) && (arrayFloat.@max <= %@))",
                    values: [Float(5.55444333), Float(6.55444333)], count: 1) {
            $0.arrayFloat.contains(Float(5.55444333)...Float(6.55444333))
        }
        assertQuery(ModernAllTypesObject.self, "((arrayFloat.@min >= %@) && (arrayFloat.@max < %@))",
                    values: [Float(5.55444333), Float(6.55444333)], count: 0) {
            $0.arrayFloat.contains(Float(5.55444333)..<Float(6.55444333))
        }
        assertQuery(ModernAllTypesObject.self, "((arrayDouble.@min >= %@) && (arrayDouble.@max <= %@))",
                    values: [123.456, 234.567], count: 1) {
            $0.arrayDouble.contains(123.456...234.567)
        }
        assertQuery(ModernAllTypesObject.self, "((arrayDouble.@min >= %@) && (arrayDouble.@max < %@))",
                    values: [123.456, 234.567], count: 0) {
            $0.arrayDouble.contains(123.456..<234.567)
        }
        assertQuery(ModernAllTypesObject.self, "((arrayDate.@min >= %@) && (arrayDate.@max <= %@))",
                    values: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)], count: 1) {
            $0.arrayDate.contains(Date(timeIntervalSince1970: 1000000)...Date(timeIntervalSince1970: 2000000))
        }
        assertQuery(ModernAllTypesObject.self, "((arrayDate.@min >= %@) && (arrayDate.@max < %@))",
                    values: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)], count: 0) {
            $0.arrayDate.contains(Date(timeIntervalSince1970: 1000000)..<Date(timeIntervalSince1970: 2000000))
        }
        assertQuery(ModernAllTypesObject.self, "((arrayDecimal.@min >= %@) && (arrayDecimal.@max <= %@))",
                    values: [Decimal128(123.456), Decimal128(234.567)], count: 1) {
            $0.arrayDecimal.contains(Decimal128(123.456)...Decimal128(234.567))
        }
        assertQuery(ModernAllTypesObject.self, "((arrayDecimal.@min >= %@) && (arrayDecimal.@max < %@))",
                    values: [Decimal128(123.456), Decimal128(234.567)], count: 0) {
            $0.arrayDecimal.contains(Decimal128(123.456)..<Decimal128(234.567))
        }
        assertQuery(ModernCollectionsOfEnums.self, "((listInt.@min >= %@) && (listInt.@max <= %@))",
                    values: [EnumInt.value1.rawValue, EnumInt.value2.rawValue], count: 1) {
            $0.listInt.rawValue.contains(EnumInt.value1.rawValue...EnumInt.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((listInt.@min >= %@) && (listInt.@max < %@))",
                    values: [EnumInt.value1.rawValue, EnumInt.value2.rawValue], count: 0) {
            $0.listInt.rawValue.contains(EnumInt.value1.rawValue..<EnumInt.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((listInt8.@min >= %@) && (listInt8.@max <= %@))",
                    values: [EnumInt8.value1.rawValue, EnumInt8.value2.rawValue], count: 1) {
            $0.listInt8.rawValue.contains(EnumInt8.value1.rawValue...EnumInt8.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((listInt8.@min >= %@) && (listInt8.@max < %@))",
                    values: [EnumInt8.value1.rawValue, EnumInt8.value2.rawValue], count: 0) {
            $0.listInt8.rawValue.contains(EnumInt8.value1.rawValue..<EnumInt8.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((listInt16.@min >= %@) && (listInt16.@max <= %@))",
                    values: [EnumInt16.value1.rawValue, EnumInt16.value2.rawValue], count: 1) {
            $0.listInt16.rawValue.contains(EnumInt16.value1.rawValue...EnumInt16.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((listInt16.@min >= %@) && (listInt16.@max < %@))",
                    values: [EnumInt16.value1.rawValue, EnumInt16.value2.rawValue], count: 0) {
            $0.listInt16.rawValue.contains(EnumInt16.value1.rawValue..<EnumInt16.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((listInt32.@min >= %@) && (listInt32.@max <= %@))",
                    values: [EnumInt32.value1.rawValue, EnumInt32.value2.rawValue], count: 1) {
            $0.listInt32.rawValue.contains(EnumInt32.value1.rawValue...EnumInt32.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((listInt32.@min >= %@) && (listInt32.@max < %@))",
                    values: [EnumInt32.value1.rawValue, EnumInt32.value2.rawValue], count: 0) {
            $0.listInt32.rawValue.contains(EnumInt32.value1.rawValue..<EnumInt32.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((listInt64.@min >= %@) && (listInt64.@max <= %@))",
                    values: [EnumInt64.value1.rawValue, EnumInt64.value2.rawValue], count: 1) {
            $0.listInt64.rawValue.contains(EnumInt64.value1.rawValue...EnumInt64.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((listInt64.@min >= %@) && (listInt64.@max < %@))",
                    values: [EnumInt64.value1.rawValue, EnumInt64.value2.rawValue], count: 0) {
            $0.listInt64.rawValue.contains(EnumInt64.value1.rawValue..<EnumInt64.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((listFloat.@min >= %@) && (listFloat.@max <= %@))",
                    values: [EnumFloat.value1.rawValue, EnumFloat.value2.rawValue], count: 1) {
            $0.listFloat.rawValue.contains(EnumFloat.value1.rawValue...EnumFloat.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((listFloat.@min >= %@) && (listFloat.@max < %@))",
                    values: [EnumFloat.value1.rawValue, EnumFloat.value2.rawValue], count: 0) {
            $0.listFloat.rawValue.contains(EnumFloat.value1.rawValue..<EnumFloat.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((listDouble.@min >= %@) && (listDouble.@max <= %@))",
                    values: [EnumDouble.value1.rawValue, EnumDouble.value2.rawValue], count: 1) {
            $0.listDouble.rawValue.contains(EnumDouble.value1.rawValue...EnumDouble.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((listDouble.@min >= %@) && (listDouble.@max < %@))",
                    values: [EnumDouble.value1.rawValue, EnumDouble.value2.rawValue], count: 0) {
            $0.listDouble.rawValue.contains(EnumDouble.value1.rawValue..<EnumDouble.value2.rawValue)
        }
        assertQuery(ModernAllTypesObject.self, "((arrayOptInt.@min >= %@) && (arrayOptInt.@max <= %@))",
                    values: [5, 6], count: 1) {
            $0.arrayOptInt.contains(5...6)
        }
        assertQuery(ModernAllTypesObject.self, "((arrayOptInt.@min >= %@) && (arrayOptInt.@max < %@))",
                    values: [5, 6], count: 0) {
            $0.arrayOptInt.contains(5..<6)
        }
        assertQuery(ModernAllTypesObject.self, "((arrayOptInt8.@min >= %@) && (arrayOptInt8.@max <= %@))",
                    values: [Int8(8), Int8(9)], count: 1) {
            $0.arrayOptInt8.contains(Int8(8)...Int8(9))
        }
        assertQuery(ModernAllTypesObject.self, "((arrayOptInt8.@min >= %@) && (arrayOptInt8.@max < %@))",
                    values: [Int8(8), Int8(9)], count: 0) {
            $0.arrayOptInt8.contains(Int8(8)..<Int8(9))
        }
        assertQuery(ModernAllTypesObject.self, "((arrayOptInt16.@min >= %@) && (arrayOptInt16.@max <= %@))",
                    values: [Int16(16), Int16(17)], count: 1) {
            $0.arrayOptInt16.contains(Int16(16)...Int16(17))
        }
        assertQuery(ModernAllTypesObject.self, "((arrayOptInt16.@min >= %@) && (arrayOptInt16.@max < %@))",
                    values: [Int16(16), Int16(17)], count: 0) {
            $0.arrayOptInt16.contains(Int16(16)..<Int16(17))
        }
        assertQuery(ModernAllTypesObject.self, "((arrayOptInt32.@min >= %@) && (arrayOptInt32.@max <= %@))",
                    values: [Int32(32), Int32(33)], count: 1) {
            $0.arrayOptInt32.contains(Int32(32)...Int32(33))
        }
        assertQuery(ModernAllTypesObject.self, "((arrayOptInt32.@min >= %@) && (arrayOptInt32.@max < %@))",
                    values: [Int32(32), Int32(33)], count: 0) {
            $0.arrayOptInt32.contains(Int32(32)..<Int32(33))
        }
        assertQuery(ModernAllTypesObject.self, "((arrayOptInt64.@min >= %@) && (arrayOptInt64.@max <= %@))",
                    values: [Int64(64), Int64(65)], count: 1) {
            $0.arrayOptInt64.contains(Int64(64)...Int64(65))
        }
        assertQuery(ModernAllTypesObject.self, "((arrayOptInt64.@min >= %@) && (arrayOptInt64.@max < %@))",
                    values: [Int64(64), Int64(65)], count: 0) {
            $0.arrayOptInt64.contains(Int64(64)..<Int64(65))
        }
        assertQuery(ModernAllTypesObject.self, "((arrayOptFloat.@min >= %@) && (arrayOptFloat.@max <= %@))",
                    values: [Float(5.55444333), Float(6.55444333)], count: 1) {
            $0.arrayOptFloat.contains(Float(5.55444333)...Float(6.55444333))
        }
        assertQuery(ModernAllTypesObject.self, "((arrayOptFloat.@min >= %@) && (arrayOptFloat.@max < %@))",
                    values: [Float(5.55444333), Float(6.55444333)], count: 0) {
            $0.arrayOptFloat.contains(Float(5.55444333)..<Float(6.55444333))
        }
        assertQuery(ModernAllTypesObject.self, "((arrayOptDouble.@min >= %@) && (arrayOptDouble.@max <= %@))",
                    values: [123.456, 234.567], count: 1) {
            $0.arrayOptDouble.contains(123.456...234.567)
        }
        assertQuery(ModernAllTypesObject.self, "((arrayOptDouble.@min >= %@) && (arrayOptDouble.@max < %@))",
                    values: [123.456, 234.567], count: 0) {
            $0.arrayOptDouble.contains(123.456..<234.567)
        }
        assertQuery(ModernAllTypesObject.self, "((arrayOptDate.@min >= %@) && (arrayOptDate.@max <= %@))",
                    values: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)], count: 1) {
            $0.arrayOptDate.contains(Date(timeIntervalSince1970: 1000000)...Date(timeIntervalSince1970: 2000000))
        }
        assertQuery(ModernAllTypesObject.self, "((arrayOptDate.@min >= %@) && (arrayOptDate.@max < %@))",
                    values: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)], count: 0) {
            $0.arrayOptDate.contains(Date(timeIntervalSince1970: 1000000)..<Date(timeIntervalSince1970: 2000000))
        }
        assertQuery(ModernAllTypesObject.self, "((arrayOptDecimal.@min >= %@) && (arrayOptDecimal.@max <= %@))",
                    values: [Decimal128(123.456), Decimal128(234.567)], count: 1) {
            $0.arrayOptDecimal.contains(Decimal128(123.456)...Decimal128(234.567))
        }
        assertQuery(ModernAllTypesObject.self, "((arrayOptDecimal.@min >= %@) && (arrayOptDecimal.@max < %@))",
                    values: [Decimal128(123.456), Decimal128(234.567)], count: 0) {
            $0.arrayOptDecimal.contains(Decimal128(123.456)..<Decimal128(234.567))
        }
        assertQuery(ModernCollectionsOfEnums.self, "((listIntOpt.@min >= %@) && (listIntOpt.@max <= %@))",
                    values: [EnumInt.value1.rawValue, EnumInt.value2.rawValue], count: 1) {
            $0.listIntOpt.rawValue.contains(EnumInt.value1.rawValue...EnumInt.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((listIntOpt.@min >= %@) && (listIntOpt.@max < %@))",
                    values: [EnumInt.value1.rawValue, EnumInt.value2.rawValue], count: 0) {
            $0.listIntOpt.rawValue.contains(EnumInt.value1.rawValue..<EnumInt.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((listInt8Opt.@min >= %@) && (listInt8Opt.@max <= %@))",
                    values: [EnumInt8.value1.rawValue, EnumInt8.value2.rawValue], count: 1) {
            $0.listInt8Opt.rawValue.contains(EnumInt8.value1.rawValue...EnumInt8.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((listInt8Opt.@min >= %@) && (listInt8Opt.@max < %@))",
                    values: [EnumInt8.value1.rawValue, EnumInt8.value2.rawValue], count: 0) {
            $0.listInt8Opt.rawValue.contains(EnumInt8.value1.rawValue..<EnumInt8.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((listInt16Opt.@min >= %@) && (listInt16Opt.@max <= %@))",
                    values: [EnumInt16.value1.rawValue, EnumInt16.value2.rawValue], count: 1) {
            $0.listInt16Opt.rawValue.contains(EnumInt16.value1.rawValue...EnumInt16.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((listInt16Opt.@min >= %@) && (listInt16Opt.@max < %@))",
                    values: [EnumInt16.value1.rawValue, EnumInt16.value2.rawValue], count: 0) {
            $0.listInt16Opt.rawValue.contains(EnumInt16.value1.rawValue..<EnumInt16.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((listInt32Opt.@min >= %@) && (listInt32Opt.@max <= %@))",
                    values: [EnumInt32.value1.rawValue, EnumInt32.value2.rawValue], count: 1) {
            $0.listInt32Opt.rawValue.contains(EnumInt32.value1.rawValue...EnumInt32.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((listInt32Opt.@min >= %@) && (listInt32Opt.@max < %@))",
                    values: [EnumInt32.value1.rawValue, EnumInt32.value2.rawValue], count: 0) {
            $0.listInt32Opt.rawValue.contains(EnumInt32.value1.rawValue..<EnumInt32.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((listInt64Opt.@min >= %@) && (listInt64Opt.@max <= %@))",
                    values: [EnumInt64.value1.rawValue, EnumInt64.value2.rawValue], count: 1) {
            $0.listInt64Opt.rawValue.contains(EnumInt64.value1.rawValue...EnumInt64.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((listInt64Opt.@min >= %@) && (listInt64Opt.@max < %@))",
                    values: [EnumInt64.value1.rawValue, EnumInt64.value2.rawValue], count: 0) {
            $0.listInt64Opt.rawValue.contains(EnumInt64.value1.rawValue..<EnumInt64.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((listFloatOpt.@min >= %@) && (listFloatOpt.@max <= %@))",
                    values: [EnumFloat.value1.rawValue, EnumFloat.value2.rawValue], count: 1) {
            $0.listFloatOpt.rawValue.contains(EnumFloat.value1.rawValue...EnumFloat.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((listFloatOpt.@min >= %@) && (listFloatOpt.@max < %@))",
                    values: [EnumFloat.value1.rawValue, EnumFloat.value2.rawValue], count: 0) {
            $0.listFloatOpt.rawValue.contains(EnumFloat.value1.rawValue..<EnumFloat.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((listDoubleOpt.@min >= %@) && (listDoubleOpt.@max <= %@))",
                    values: [EnumDouble.value1.rawValue, EnumDouble.value2.rawValue], count: 1) {
            $0.listDoubleOpt.rawValue.contains(EnumDouble.value1.rawValue...EnumDouble.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((listDoubleOpt.@min >= %@) && (listDoubleOpt.@max < %@))",
                    values: [EnumDouble.value1.rawValue, EnumDouble.value2.rawValue], count: 0) {
            $0.listDoubleOpt.rawValue.contains(EnumDouble.value1.rawValue..<EnumDouble.value2.rawValue)
        }
        assertQuery(ModernAllTypesObject.self, "((setInt.@min >= %@) && (setInt.@max <= %@))",
                    values: [5, 6], count: 1) {
            $0.setInt.contains(5...6)
        }
        assertQuery(ModernAllTypesObject.self, "((setInt.@min >= %@) && (setInt.@max < %@))",
                    values: [5, 6], count: 0) {
            $0.setInt.contains(5..<6)
        }
        assertQuery(ModernAllTypesObject.self, "((setInt8.@min >= %@) && (setInt8.@max <= %@))",
                    values: [Int8(8), Int8(9)], count: 1) {
            $0.setInt8.contains(Int8(8)...Int8(9))
        }
        assertQuery(ModernAllTypesObject.self, "((setInt8.@min >= %@) && (setInt8.@max < %@))",
                    values: [Int8(8), Int8(9)], count: 0) {
            $0.setInt8.contains(Int8(8)..<Int8(9))
        }
        assertQuery(ModernAllTypesObject.self, "((setInt16.@min >= %@) && (setInt16.@max <= %@))",
                    values: [Int16(16), Int16(17)], count: 1) {
            $0.setInt16.contains(Int16(16)...Int16(17))
        }
        assertQuery(ModernAllTypesObject.self, "((setInt16.@min >= %@) && (setInt16.@max < %@))",
                    values: [Int16(16), Int16(17)], count: 0) {
            $0.setInt16.contains(Int16(16)..<Int16(17))
        }
        assertQuery(ModernAllTypesObject.self, "((setInt32.@min >= %@) && (setInt32.@max <= %@))",
                    values: [Int32(32), Int32(33)], count: 1) {
            $0.setInt32.contains(Int32(32)...Int32(33))
        }
        assertQuery(ModernAllTypesObject.self, "((setInt32.@min >= %@) && (setInt32.@max < %@))",
                    values: [Int32(32), Int32(33)], count: 0) {
            $0.setInt32.contains(Int32(32)..<Int32(33))
        }
        assertQuery(ModernAllTypesObject.self, "((setInt64.@min >= %@) && (setInt64.@max <= %@))",
                    values: [Int64(64), Int64(65)], count: 1) {
            $0.setInt64.contains(Int64(64)...Int64(65))
        }
        assertQuery(ModernAllTypesObject.self, "((setInt64.@min >= %@) && (setInt64.@max < %@))",
                    values: [Int64(64), Int64(65)], count: 0) {
            $0.setInt64.contains(Int64(64)..<Int64(65))
        }
        assertQuery(ModernAllTypesObject.self, "((setFloat.@min >= %@) && (setFloat.@max <= %@))",
                    values: [Float(5.55444333), Float(6.55444333)], count: 1) {
            $0.setFloat.contains(Float(5.55444333)...Float(6.55444333))
        }
        assertQuery(ModernAllTypesObject.self, "((setFloat.@min >= %@) && (setFloat.@max < %@))",
                    values: [Float(5.55444333), Float(6.55444333)], count: 0) {
            $0.setFloat.contains(Float(5.55444333)..<Float(6.55444333))
        }
        assertQuery(ModernAllTypesObject.self, "((setDouble.@min >= %@) && (setDouble.@max <= %@))",
                    values: [123.456, 234.567], count: 1) {
            $0.setDouble.contains(123.456...234.567)
        }
        assertQuery(ModernAllTypesObject.self, "((setDouble.@min >= %@) && (setDouble.@max < %@))",
                    values: [123.456, 234.567], count: 0) {
            $0.setDouble.contains(123.456..<234.567)
        }
        assertQuery(ModernAllTypesObject.self, "((setDate.@min >= %@) && (setDate.@max <= %@))",
                    values: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)], count: 1) {
            $0.setDate.contains(Date(timeIntervalSince1970: 1000000)...Date(timeIntervalSince1970: 2000000))
        }
        assertQuery(ModernAllTypesObject.self, "((setDate.@min >= %@) && (setDate.@max < %@))",
                    values: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)], count: 0) {
            $0.setDate.contains(Date(timeIntervalSince1970: 1000000)..<Date(timeIntervalSince1970: 2000000))
        }
        assertQuery(ModernAllTypesObject.self, "((setDecimal.@min >= %@) && (setDecimal.@max <= %@))",
                    values: [Decimal128(123.456), Decimal128(234.567)], count: 1) {
            $0.setDecimal.contains(Decimal128(123.456)...Decimal128(234.567))
        }
        assertQuery(ModernAllTypesObject.self, "((setDecimal.@min >= %@) && (setDecimal.@max < %@))",
                    values: [Decimal128(123.456), Decimal128(234.567)], count: 0) {
            $0.setDecimal.contains(Decimal128(123.456)..<Decimal128(234.567))
        }
        assertQuery(ModernCollectionsOfEnums.self, "((setInt.@min >= %@) && (setInt.@max <= %@))",
                    values: [EnumInt.value1.rawValue, EnumInt.value2.rawValue], count: 1) {
            $0.setInt.rawValue.contains(EnumInt.value1.rawValue...EnumInt.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((setInt.@min >= %@) && (setInt.@max < %@))",
                    values: [EnumInt.value1.rawValue, EnumInt.value2.rawValue], count: 0) {
            $0.setInt.rawValue.contains(EnumInt.value1.rawValue..<EnumInt.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((setInt8.@min >= %@) && (setInt8.@max <= %@))",
                    values: [EnumInt8.value1.rawValue, EnumInt8.value2.rawValue], count: 1) {
            $0.setInt8.rawValue.contains(EnumInt8.value1.rawValue...EnumInt8.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((setInt8.@min >= %@) && (setInt8.@max < %@))",
                    values: [EnumInt8.value1.rawValue, EnumInt8.value2.rawValue], count: 0) {
            $0.setInt8.rawValue.contains(EnumInt8.value1.rawValue..<EnumInt8.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((setInt16.@min >= %@) && (setInt16.@max <= %@))",
                    values: [EnumInt16.value1.rawValue, EnumInt16.value2.rawValue], count: 1) {
            $0.setInt16.rawValue.contains(EnumInt16.value1.rawValue...EnumInt16.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((setInt16.@min >= %@) && (setInt16.@max < %@))",
                    values: [EnumInt16.value1.rawValue, EnumInt16.value2.rawValue], count: 0) {
            $0.setInt16.rawValue.contains(EnumInt16.value1.rawValue..<EnumInt16.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((setInt32.@min >= %@) && (setInt32.@max <= %@))",
                    values: [EnumInt32.value1.rawValue, EnumInt32.value2.rawValue], count: 1) {
            $0.setInt32.rawValue.contains(EnumInt32.value1.rawValue...EnumInt32.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((setInt32.@min >= %@) && (setInt32.@max < %@))",
                    values: [EnumInt32.value1.rawValue, EnumInt32.value2.rawValue], count: 0) {
            $0.setInt32.rawValue.contains(EnumInt32.value1.rawValue..<EnumInt32.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((setInt64.@min >= %@) && (setInt64.@max <= %@))",
                    values: [EnumInt64.value1.rawValue, EnumInt64.value2.rawValue], count: 1) {
            $0.setInt64.rawValue.contains(EnumInt64.value1.rawValue...EnumInt64.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((setInt64.@min >= %@) && (setInt64.@max < %@))",
                    values: [EnumInt64.value1.rawValue, EnumInt64.value2.rawValue], count: 0) {
            $0.setInt64.rawValue.contains(EnumInt64.value1.rawValue..<EnumInt64.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((setFloat.@min >= %@) && (setFloat.@max <= %@))",
                    values: [EnumFloat.value1.rawValue, EnumFloat.value2.rawValue], count: 1) {
            $0.setFloat.rawValue.contains(EnumFloat.value1.rawValue...EnumFloat.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((setFloat.@min >= %@) && (setFloat.@max < %@))",
                    values: [EnumFloat.value1.rawValue, EnumFloat.value2.rawValue], count: 0) {
            $0.setFloat.rawValue.contains(EnumFloat.value1.rawValue..<EnumFloat.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((setDouble.@min >= %@) && (setDouble.@max <= %@))",
                    values: [EnumDouble.value1.rawValue, EnumDouble.value2.rawValue], count: 1) {
            $0.setDouble.rawValue.contains(EnumDouble.value1.rawValue...EnumDouble.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((setDouble.@min >= %@) && (setDouble.@max < %@))",
                    values: [EnumDouble.value1.rawValue, EnumDouble.value2.rawValue], count: 0) {
            $0.setDouble.rawValue.contains(EnumDouble.value1.rawValue..<EnumDouble.value2.rawValue)
        }
        assertQuery(ModernAllTypesObject.self, "((setOptInt.@min >= %@) && (setOptInt.@max <= %@))",
                    values: [5, 6], count: 1) {
            $0.setOptInt.contains(5...6)
        }
        assertQuery(ModernAllTypesObject.self, "((setOptInt.@min >= %@) && (setOptInt.@max < %@))",
                    values: [5, 6], count: 0) {
            $0.setOptInt.contains(5..<6)
        }
        assertQuery(ModernAllTypesObject.self, "((setOptInt8.@min >= %@) && (setOptInt8.@max <= %@))",
                    values: [Int8(8), Int8(9)], count: 1) {
            $0.setOptInt8.contains(Int8(8)...Int8(9))
        }
        assertQuery(ModernAllTypesObject.self, "((setOptInt8.@min >= %@) && (setOptInt8.@max < %@))",
                    values: [Int8(8), Int8(9)], count: 0) {
            $0.setOptInt8.contains(Int8(8)..<Int8(9))
        }
        assertQuery(ModernAllTypesObject.self, "((setOptInt16.@min >= %@) && (setOptInt16.@max <= %@))",
                    values: [Int16(16), Int16(17)], count: 1) {
            $0.setOptInt16.contains(Int16(16)...Int16(17))
        }
        assertQuery(ModernAllTypesObject.self, "((setOptInt16.@min >= %@) && (setOptInt16.@max < %@))",
                    values: [Int16(16), Int16(17)], count: 0) {
            $0.setOptInt16.contains(Int16(16)..<Int16(17))
        }
        assertQuery(ModernAllTypesObject.self, "((setOptInt32.@min >= %@) && (setOptInt32.@max <= %@))",
                    values: [Int32(32), Int32(33)], count: 1) {
            $0.setOptInt32.contains(Int32(32)...Int32(33))
        }
        assertQuery(ModernAllTypesObject.self, "((setOptInt32.@min >= %@) && (setOptInt32.@max < %@))",
                    values: [Int32(32), Int32(33)], count: 0) {
            $0.setOptInt32.contains(Int32(32)..<Int32(33))
        }
        assertQuery(ModernAllTypesObject.self, "((setOptInt64.@min >= %@) && (setOptInt64.@max <= %@))",
                    values: [Int64(64), Int64(65)], count: 1) {
            $0.setOptInt64.contains(Int64(64)...Int64(65))
        }
        assertQuery(ModernAllTypesObject.self, "((setOptInt64.@min >= %@) && (setOptInt64.@max < %@))",
                    values: [Int64(64), Int64(65)], count: 0) {
            $0.setOptInt64.contains(Int64(64)..<Int64(65))
        }
        assertQuery(ModernAllTypesObject.self, "((setOptFloat.@min >= %@) && (setOptFloat.@max <= %@))",
                    values: [Float(5.55444333), Float(6.55444333)], count: 1) {
            $0.setOptFloat.contains(Float(5.55444333)...Float(6.55444333))
        }
        assertQuery(ModernAllTypesObject.self, "((setOptFloat.@min >= %@) && (setOptFloat.@max < %@))",
                    values: [Float(5.55444333), Float(6.55444333)], count: 0) {
            $0.setOptFloat.contains(Float(5.55444333)..<Float(6.55444333))
        }
        assertQuery(ModernAllTypesObject.self, "((setOptDouble.@min >= %@) && (setOptDouble.@max <= %@))",
                    values: [123.456, 234.567], count: 1) {
            $0.setOptDouble.contains(123.456...234.567)
        }
        assertQuery(ModernAllTypesObject.self, "((setOptDouble.@min >= %@) && (setOptDouble.@max < %@))",
                    values: [123.456, 234.567], count: 0) {
            $0.setOptDouble.contains(123.456..<234.567)
        }
        assertQuery(ModernAllTypesObject.self, "((setOptDate.@min >= %@) && (setOptDate.@max <= %@))",
                    values: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)], count: 1) {
            $0.setOptDate.contains(Date(timeIntervalSince1970: 1000000)...Date(timeIntervalSince1970: 2000000))
        }
        assertQuery(ModernAllTypesObject.self, "((setOptDate.@min >= %@) && (setOptDate.@max < %@))",
                    values: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)], count: 0) {
            $0.setOptDate.contains(Date(timeIntervalSince1970: 1000000)..<Date(timeIntervalSince1970: 2000000))
        }
        assertQuery(ModernAllTypesObject.self, "((setOptDecimal.@min >= %@) && (setOptDecimal.@max <= %@))",
                    values: [Decimal128(123.456), Decimal128(234.567)], count: 1) {
            $0.setOptDecimal.contains(Decimal128(123.456)...Decimal128(234.567))
        }
        assertQuery(ModernAllTypesObject.self, "((setOptDecimal.@min >= %@) && (setOptDecimal.@max < %@))",
                    values: [Decimal128(123.456), Decimal128(234.567)], count: 0) {
            $0.setOptDecimal.contains(Decimal128(123.456)..<Decimal128(234.567))
        }
        assertQuery(ModernCollectionsOfEnums.self, "((setIntOpt.@min >= %@) && (setIntOpt.@max <= %@))",
                    values: [EnumInt.value1.rawValue, EnumInt.value2.rawValue], count: 1) {
            $0.setIntOpt.rawValue.contains(EnumInt.value1.rawValue...EnumInt.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((setIntOpt.@min >= %@) && (setIntOpt.@max < %@))",
                    values: [EnumInt.value1.rawValue, EnumInt.value2.rawValue], count: 0) {
            $0.setIntOpt.rawValue.contains(EnumInt.value1.rawValue..<EnumInt.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((setInt8Opt.@min >= %@) && (setInt8Opt.@max <= %@))",
                    values: [EnumInt8.value1.rawValue, EnumInt8.value2.rawValue], count: 1) {
            $0.setInt8Opt.rawValue.contains(EnumInt8.value1.rawValue...EnumInt8.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((setInt8Opt.@min >= %@) && (setInt8Opt.@max < %@))",
                    values: [EnumInt8.value1.rawValue, EnumInt8.value2.rawValue], count: 0) {
            $0.setInt8Opt.rawValue.contains(EnumInt8.value1.rawValue..<EnumInt8.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((setInt16Opt.@min >= %@) && (setInt16Opt.@max <= %@))",
                    values: [EnumInt16.value1.rawValue, EnumInt16.value2.rawValue], count: 1) {
            $0.setInt16Opt.rawValue.contains(EnumInt16.value1.rawValue...EnumInt16.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((setInt16Opt.@min >= %@) && (setInt16Opt.@max < %@))",
                    values: [EnumInt16.value1.rawValue, EnumInt16.value2.rawValue], count: 0) {
            $0.setInt16Opt.rawValue.contains(EnumInt16.value1.rawValue..<EnumInt16.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((setInt32Opt.@min >= %@) && (setInt32Opt.@max <= %@))",
                    values: [EnumInt32.value1.rawValue, EnumInt32.value2.rawValue], count: 1) {
            $0.setInt32Opt.rawValue.contains(EnumInt32.value1.rawValue...EnumInt32.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((setInt32Opt.@min >= %@) && (setInt32Opt.@max < %@))",
                    values: [EnumInt32.value1.rawValue, EnumInt32.value2.rawValue], count: 0) {
            $0.setInt32Opt.rawValue.contains(EnumInt32.value1.rawValue..<EnumInt32.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((setInt64Opt.@min >= %@) && (setInt64Opt.@max <= %@))",
                    values: [EnumInt64.value1.rawValue, EnumInt64.value2.rawValue], count: 1) {
            $0.setInt64Opt.rawValue.contains(EnumInt64.value1.rawValue...EnumInt64.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((setInt64Opt.@min >= %@) && (setInt64Opt.@max < %@))",
                    values: [EnumInt64.value1.rawValue, EnumInt64.value2.rawValue], count: 0) {
            $0.setInt64Opt.rawValue.contains(EnumInt64.value1.rawValue..<EnumInt64.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((setFloatOpt.@min >= %@) && (setFloatOpt.@max <= %@))",
                    values: [EnumFloat.value1.rawValue, EnumFloat.value2.rawValue], count: 1) {
            $0.setFloatOpt.rawValue.contains(EnumFloat.value1.rawValue...EnumFloat.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((setFloatOpt.@min >= %@) && (setFloatOpt.@max < %@))",
                    values: [EnumFloat.value1.rawValue, EnumFloat.value2.rawValue], count: 0) {
            $0.setFloatOpt.rawValue.contains(EnumFloat.value1.rawValue..<EnumFloat.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((setDoubleOpt.@min >= %@) && (setDoubleOpt.@max <= %@))",
                    values: [EnumDouble.value1.rawValue, EnumDouble.value2.rawValue], count: 1) {
            $0.setDoubleOpt.rawValue.contains(EnumDouble.value1.rawValue...EnumDouble.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((setDoubleOpt.@min >= %@) && (setDoubleOpt.@max < %@))",
                    values: [EnumDouble.value1.rawValue, EnumDouble.value2.rawValue], count: 0) {
            $0.setDoubleOpt.rawValue.contains(EnumDouble.value1.rawValue..<EnumDouble.value2.rawValue)
        }
    }

    func testListContainsAnyInObject() {
        assertQuery(ModernAllTypesObject.self, "(ANY arrayBool IN %@)",
                    values: [NSArray(array: [true, true])], count: 1) {
            $0.arrayBool.containsAny(in: [true, true])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayInt IN %@)",
                    values: [NSArray(array: [5, 6])], count: 1) {
            $0.arrayInt.containsAny(in: [5, 6])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayInt8 IN %@)",
                    values: [NSArray(array: [Int8(8), Int8(9)])], count: 1) {
            $0.arrayInt8.containsAny(in: [Int8(8), Int8(9)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayInt16 IN %@)",
                    values: [NSArray(array: [Int16(16), Int16(17)])], count: 1) {
            $0.arrayInt16.containsAny(in: [Int16(16), Int16(17)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayInt32 IN %@)",
                    values: [NSArray(array: [Int32(32), Int32(33)])], count: 1) {
            $0.arrayInt32.containsAny(in: [Int32(32), Int32(33)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayInt64 IN %@)",
                    values: [NSArray(array: [Int64(64), Int64(65)])], count: 1) {
            $0.arrayInt64.containsAny(in: [Int64(64), Int64(65)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayFloat IN %@)",
                    values: [NSArray(array: [Float(5.55444333), Float(6.55444333)])], count: 1) {
            $0.arrayFloat.containsAny(in: [Float(5.55444333), Float(6.55444333)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayDouble IN %@)",
                    values: [NSArray(array: [123.456, 234.567])], count: 1) {
            $0.arrayDouble.containsAny(in: [123.456, 234.567])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayString IN %@)",
                    values: [NSArray(array: ["Foo", "Foó"])], count: 1) {
            $0.arrayString.containsAny(in: ["Foo", "Foó"])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayBinary IN %@)",
                    values: [NSArray(array: [Data(count: 64), Data(count: 128)])], count: 1) {
            $0.arrayBinary.containsAny(in: [Data(count: 64), Data(count: 128)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayDate IN %@)",
                    values: [NSArray(array: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)])], count: 1) {
            $0.arrayDate.containsAny(in: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayDecimal IN %@)",
                    values: [NSArray(array: [Decimal128(123.456), Decimal128(234.567)])], count: 1) {
            $0.arrayDecimal.containsAny(in: [Decimal128(123.456), Decimal128(234.567)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayObjectId IN %@)",
                    values: [NSArray(array: [ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045")])], count: 1) {
            $0.arrayObjectId.containsAny(in: [ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045")])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayUuid IN %@)",
                    values: [NSArray(array: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])], count: 1) {
            $0.arrayUuid.containsAny(in: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayAny IN %@)",
                    values: [NSArray(array: [AnyRealmValue.objectId(ObjectId("61184062c1d8f096a3695046")), AnyRealmValue.string("Hello")])], count: 1) {
            $0.arrayAny.containsAny(in: [AnyRealmValue.objectId(ObjectId("61184062c1d8f096a3695046")), AnyRealmValue.string("Hello")])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY listInt IN %@)",
                    values: [NSArray(array: [EnumInt.value1, EnumInt.value2])], count: 1) {
            $0.listInt.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY listInt8 IN %@)",
                    values: [NSArray(array: [EnumInt8.value1, EnumInt8.value2])], count: 1) {
            $0.listInt8.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY listInt16 IN %@)",
                    values: [NSArray(array: [EnumInt16.value1, EnumInt16.value2])], count: 1) {
            $0.listInt16.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY listInt32 IN %@)",
                    values: [NSArray(array: [EnumInt32.value1, EnumInt32.value2])], count: 1) {
            $0.listInt32.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY listInt64 IN %@)",
                    values: [NSArray(array: [EnumInt64.value1, EnumInt64.value2])], count: 1) {
            $0.listInt64.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY listFloat IN %@)",
                    values: [NSArray(array: [EnumFloat.value1, EnumFloat.value2])], count: 1) {
            $0.listFloat.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY listDouble IN %@)",
                    values: [NSArray(array: [EnumDouble.value1, EnumDouble.value2])], count: 1) {
            $0.listDouble.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY listString IN %@)",
                    values: [NSArray(array: [EnumString.value1, EnumString.value2])], count: 1) {
            $0.listString.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayOptBool IN %@)",
                    values: [NSArray(array: [true, true])], count: 1) {
            $0.arrayOptBool.containsAny(in: [true, true])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayOptInt IN %@)",
                    values: [NSArray(array: [5, 6])], count: 1) {
            $0.arrayOptInt.containsAny(in: [5, 6])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayOptInt8 IN %@)",
                    values: [NSArray(array: [Int8(8), Int8(9)])], count: 1) {
            $0.arrayOptInt8.containsAny(in: [Int8(8), Int8(9)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayOptInt16 IN %@)",
                    values: [NSArray(array: [Int16(16), Int16(17)])], count: 1) {
            $0.arrayOptInt16.containsAny(in: [Int16(16), Int16(17)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayOptInt32 IN %@)",
                    values: [NSArray(array: [Int32(32), Int32(33)])], count: 1) {
            $0.arrayOptInt32.containsAny(in: [Int32(32), Int32(33)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayOptInt64 IN %@)",
                    values: [NSArray(array: [Int64(64), Int64(65)])], count: 1) {
            $0.arrayOptInt64.containsAny(in: [Int64(64), Int64(65)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayOptFloat IN %@)",
                    values: [NSArray(array: [Float(5.55444333), Float(6.55444333)])], count: 1) {
            $0.arrayOptFloat.containsAny(in: [Float(5.55444333), Float(6.55444333)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayOptDouble IN %@)",
                    values: [NSArray(array: [123.456, 234.567])], count: 1) {
            $0.arrayOptDouble.containsAny(in: [123.456, 234.567])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayOptString IN %@)",
                    values: [NSArray(array: ["Foo", "Foó"])], count: 1) {
            $0.arrayOptString.containsAny(in: ["Foo", "Foó"])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayOptBinary IN %@)",
                    values: [NSArray(array: [Data(count: 64), Data(count: 128)])], count: 1) {
            $0.arrayOptBinary.containsAny(in: [Data(count: 64), Data(count: 128)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayOptDate IN %@)",
                    values: [NSArray(array: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)])], count: 1) {
            $0.arrayOptDate.containsAny(in: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayOptDecimal IN %@)",
                    values: [NSArray(array: [Decimal128(123.456), Decimal128(234.567)])], count: 1) {
            $0.arrayOptDecimal.containsAny(in: [Decimal128(123.456), Decimal128(234.567)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayOptObjectId IN %@)",
                    values: [NSArray(array: [ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045")])], count: 1) {
            $0.arrayOptObjectId.containsAny(in: [ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045")])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayOptUuid IN %@)",
                    values: [NSArray(array: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])], count: 1) {
            $0.arrayOptUuid.containsAny(in: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY listIntOpt IN %@)",
                    values: [NSArray(array: [EnumInt.value1, EnumInt.value2])], count: 1) {
            $0.listIntOpt.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY listInt8Opt IN %@)",
                    values: [NSArray(array: [EnumInt8.value1, EnumInt8.value2])], count: 1) {
            $0.listInt8Opt.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY listInt16Opt IN %@)",
                    values: [NSArray(array: [EnumInt16.value1, EnumInt16.value2])], count: 1) {
            $0.listInt16Opt.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY listInt32Opt IN %@)",
                    values: [NSArray(array: [EnumInt32.value1, EnumInt32.value2])], count: 1) {
            $0.listInt32Opt.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY listInt64Opt IN %@)",
                    values: [NSArray(array: [EnumInt64.value1, EnumInt64.value2])], count: 1) {
            $0.listInt64Opt.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY listFloatOpt IN %@)",
                    values: [NSArray(array: [EnumFloat.value1, EnumFloat.value2])], count: 1) {
            $0.listFloatOpt.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY listDoubleOpt IN %@)",
                    values: [NSArray(array: [EnumDouble.value1, EnumDouble.value2])], count: 1) {
            $0.listDoubleOpt.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY listStringOpt IN %@)",
                    values: [NSArray(array: [EnumString.value1, EnumString.value2])], count: 1) {
            $0.listStringOpt.containsAny(in: [.value1, .value2])
        }

        let colObj = ModernCollectionObject()
        let obj = objects().first!
        colObj.list.append(obj)
        try! realm.write {
            realm.add(colObj)
        }

        assertQuery(ModernCollectionObject.self, "(ANY list IN %@)", values: [NSArray(array: [obj])], count: 1) {
            $0.list.containsAny(in: [obj])
        }
    }

    func testCollectionFromProperty() {
        let colObj = ModernCollectionObject()
        let obj = objects().first!
        colObj.set.insert(obj)
        colObj.list.append(obj)
        try! realm.write {
            realm.add(colObj)
        }

        assertCollectionQuery(predicate: "(boolCol == %@)", value: false) {
            $0.boolCol == false
        }
        assertCollectionQuery(predicate: "(intCol == %@)", value: 6) {
            $0.intCol == 6
        }
        assertCollectionQuery(predicate: "(int8Col == %@)", value: Int8(9)) {
            $0.int8Col == Int8(9)
        }
        assertCollectionQuery(predicate: "(int16Col == %@)", value: Int16(17)) {
            $0.int16Col == Int16(17)
        }
        assertCollectionQuery(predicate: "(int32Col == %@)", value: Int32(33)) {
            $0.int32Col == Int32(33)
        }
        assertCollectionQuery(predicate: "(int64Col == %@)", value: Int64(65)) {
            $0.int64Col == Int64(65)
        }
        assertCollectionQuery(predicate: "(floatCol == %@)", value: Float(6.55444333)) {
            $0.floatCol == Float(6.55444333)
        }
        assertCollectionQuery(predicate: "(doubleCol == %@)", value: 234.567) {
            $0.doubleCol == 234.567
        }
        assertCollectionQuery(predicate: "(stringCol == %@)", value: "Foó") {
            $0.stringCol == "Foó"
        }
        assertCollectionQuery(predicate: "(binaryCol == %@)", value: Data(count: 128)) {
            $0.binaryCol == Data(count: 128)
        }
        assertCollectionQuery(predicate: "(dateCol == %@)", value: Date(timeIntervalSince1970: 2000000)) {
            $0.dateCol == Date(timeIntervalSince1970: 2000000)
        }
        assertCollectionQuery(predicate: "(decimalCol == %@)", value: Decimal128(234.567)) {
            $0.decimalCol == Decimal128(234.567)
        }
        assertCollectionQuery(predicate: "(objectIdCol == %@)", value: ObjectId("61184062c1d8f096a3695045")) {
            $0.objectIdCol == ObjectId("61184062c1d8f096a3695045")
        }
        assertCollectionQuery(predicate: "(uuidCol == %@)", value: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!) {
            $0.uuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!
        }
        assertCollectionQuery(predicate: "(intEnumCol == %@)", value: ModernIntEnum.value2) {
            $0.intEnumCol == .value2
        }
        assertCollectionQuery(predicate: "(stringEnumCol == %@)", value: ModernStringEnum.value2) {
            $0.stringEnumCol == .value2
        }
        assertCollectionQuery(predicate: "(optBoolCol == %@)", value: false) {
            $0.optBoolCol == false
        }
        assertCollectionQuery(predicate: "(optIntCol == %@)", value: 6) {
            $0.optIntCol == 6
        }
        assertCollectionQuery(predicate: "(optInt8Col == %@)", value: Int8(9)) {
            $0.optInt8Col == Int8(9)
        }
        assertCollectionQuery(predicate: "(optInt16Col == %@)", value: Int16(17)) {
            $0.optInt16Col == Int16(17)
        }
        assertCollectionQuery(predicate: "(optInt32Col == %@)", value: Int32(33)) {
            $0.optInt32Col == Int32(33)
        }
        assertCollectionQuery(predicate: "(optInt64Col == %@)", value: Int64(65)) {
            $0.optInt64Col == Int64(65)
        }
        assertCollectionQuery(predicate: "(optFloatCol == %@)", value: Float(6.55444333)) {
            $0.optFloatCol == Float(6.55444333)
        }
        assertCollectionQuery(predicate: "(optDoubleCol == %@)", value: 234.567) {
            $0.optDoubleCol == 234.567
        }
        assertCollectionQuery(predicate: "(optStringCol == %@)", value: "Foó") {
            $0.optStringCol == "Foó"
        }
        assertCollectionQuery(predicate: "(optBinaryCol == %@)", value: Data(count: 128)) {
            $0.optBinaryCol == Data(count: 128)
        }
        assertCollectionQuery(predicate: "(optDateCol == %@)", value: Date(timeIntervalSince1970: 2000000)) {
            $0.optDateCol == Date(timeIntervalSince1970: 2000000)
        }
        assertCollectionQuery(predicate: "(optDecimalCol == %@)", value: Decimal128(234.567)) {
            $0.optDecimalCol == Decimal128(234.567)
        }
        assertCollectionQuery(predicate: "(optObjectIdCol == %@)", value: ObjectId("61184062c1d8f096a3695045")) {
            $0.optObjectIdCol == ObjectId("61184062c1d8f096a3695045")
        }
        assertCollectionQuery(predicate: "(optUuidCol == %@)", value: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!) {
            $0.optUuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!
        }
        assertCollectionQuery(predicate: "(optIntEnumCol == %@)", value: ModernIntEnum.value2) {
            $0.optIntEnumCol == .value2
        }
        assertCollectionQuery(predicate: "(optStringEnumCol == %@)", value: ModernStringEnum.value2) {
            $0.optStringEnumCol == .value2
        }
    }

    func testSetContainsObject() {
        let obj = objects().first!
        let colObj = collectionObject()
        let result1 = realm.objects(ModernCollectionObject.self).where {
            $0.set.contains(obj)
        }
        XCTAssertEqual(result1.count, 0)
        try! realm.write {
            colObj.set.insert(obj)
        }
        let result2 = realm.objects(ModernCollectionObject.self).where {
            $0.set.contains(obj)
        }
        XCTAssertEqual(result2.count, 1)
    }

    func testSetContainsAnyInObject() {
        assertQuery(ModernAllTypesObject.self, "(ANY setBool IN %@)",
                    values: [NSArray(array: [true, true])], count: 1) {
            $0.setBool.containsAny(in: [true, true])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setInt IN %@)",
                    values: [NSArray(array: [5, 6])], count: 1) {
            $0.setInt.containsAny(in: [5, 6])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setInt8 IN %@)",
                    values: [NSArray(array: [Int8(8), Int8(9)])], count: 1) {
            $0.setInt8.containsAny(in: [Int8(8), Int8(9)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setInt16 IN %@)",
                    values: [NSArray(array: [Int16(16), Int16(17)])], count: 1) {
            $0.setInt16.containsAny(in: [Int16(16), Int16(17)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setInt32 IN %@)",
                    values: [NSArray(array: [Int32(32), Int32(33)])], count: 1) {
            $0.setInt32.containsAny(in: [Int32(32), Int32(33)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setInt64 IN %@)",
                    values: [NSArray(array: [Int64(64), Int64(65)])], count: 1) {
            $0.setInt64.containsAny(in: [Int64(64), Int64(65)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setFloat IN %@)",
                    values: [NSArray(array: [Float(5.55444333), Float(6.55444333)])], count: 1) {
            $0.setFloat.containsAny(in: [Float(5.55444333), Float(6.55444333)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setDouble IN %@)",
                    values: [NSArray(array: [123.456, 234.567])], count: 1) {
            $0.setDouble.containsAny(in: [123.456, 234.567])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setString IN %@)",
                    values: [NSArray(array: ["Foo", "Foó"])], count: 1) {
            $0.setString.containsAny(in: ["Foo", "Foó"])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setBinary IN %@)",
                    values: [NSArray(array: [Data(count: 64), Data(count: 128)])], count: 1) {
            $0.setBinary.containsAny(in: [Data(count: 64), Data(count: 128)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setDate IN %@)",
                    values: [NSArray(array: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)])], count: 1) {
            $0.setDate.containsAny(in: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setDecimal IN %@)",
                    values: [NSArray(array: [Decimal128(123.456), Decimal128(234.567)])], count: 1) {
            $0.setDecimal.containsAny(in: [Decimal128(123.456), Decimal128(234.567)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setObjectId IN %@)",
                    values: [NSArray(array: [ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045")])], count: 1) {
            $0.setObjectId.containsAny(in: [ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045")])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setUuid IN %@)",
                    values: [NSArray(array: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])], count: 1) {
            $0.setUuid.containsAny(in: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setAny IN %@)",
                    values: [NSArray(array: [AnyRealmValue.objectId(ObjectId("61184062c1d8f096a3695046")), AnyRealmValue.string("Hello")])], count: 1) {
            $0.setAny.containsAny(in: [AnyRealmValue.objectId(ObjectId("61184062c1d8f096a3695046")), AnyRealmValue.string("Hello")])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY setInt IN %@)",
                    values: [NSArray(array: [EnumInt.value1, EnumInt.value2])], count: 1) {
            $0.setInt.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY setInt8 IN %@)",
                    values: [NSArray(array: [EnumInt8.value1, EnumInt8.value2])], count: 1) {
            $0.setInt8.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY setInt16 IN %@)",
                    values: [NSArray(array: [EnumInt16.value1, EnumInt16.value2])], count: 1) {
            $0.setInt16.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY setInt32 IN %@)",
                    values: [NSArray(array: [EnumInt32.value1, EnumInt32.value2])], count: 1) {
            $0.setInt32.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY setInt64 IN %@)",
                    values: [NSArray(array: [EnumInt64.value1, EnumInt64.value2])], count: 1) {
            $0.setInt64.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY setFloat IN %@)",
                    values: [NSArray(array: [EnumFloat.value1, EnumFloat.value2])], count: 1) {
            $0.setFloat.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY setDouble IN %@)",
                    values: [NSArray(array: [EnumDouble.value1, EnumDouble.value2])], count: 1) {
            $0.setDouble.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY setString IN %@)",
                    values: [NSArray(array: [EnumString.value1, EnumString.value2])], count: 1) {
            $0.setString.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setOptBool IN %@)",
                    values: [NSArray(array: [true, true])], count: 1) {
            $0.setOptBool.containsAny(in: [true, true])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setOptInt IN %@)",
                    values: [NSArray(array: [5, 6])], count: 1) {
            $0.setOptInt.containsAny(in: [5, 6])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setOptInt8 IN %@)",
                    values: [NSArray(array: [Int8(8), Int8(9)])], count: 1) {
            $0.setOptInt8.containsAny(in: [Int8(8), Int8(9)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setOptInt16 IN %@)",
                    values: [NSArray(array: [Int16(16), Int16(17)])], count: 1) {
            $0.setOptInt16.containsAny(in: [Int16(16), Int16(17)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setOptInt32 IN %@)",
                    values: [NSArray(array: [Int32(32), Int32(33)])], count: 1) {
            $0.setOptInt32.containsAny(in: [Int32(32), Int32(33)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setOptInt64 IN %@)",
                    values: [NSArray(array: [Int64(64), Int64(65)])], count: 1) {
            $0.setOptInt64.containsAny(in: [Int64(64), Int64(65)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setOptFloat IN %@)",
                    values: [NSArray(array: [Float(5.55444333), Float(6.55444333)])], count: 1) {
            $0.setOptFloat.containsAny(in: [Float(5.55444333), Float(6.55444333)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setOptDouble IN %@)",
                    values: [NSArray(array: [123.456, 234.567])], count: 1) {
            $0.setOptDouble.containsAny(in: [123.456, 234.567])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setOptString IN %@)",
                    values: [NSArray(array: ["Foo", "Foó"])], count: 1) {
            $0.setOptString.containsAny(in: ["Foo", "Foó"])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setOptBinary IN %@)",
                    values: [NSArray(array: [Data(count: 64), Data(count: 128)])], count: 1) {
            $0.setOptBinary.containsAny(in: [Data(count: 64), Data(count: 128)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setOptDate IN %@)",
                    values: [NSArray(array: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)])], count: 1) {
            $0.setOptDate.containsAny(in: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setOptDecimal IN %@)",
                    values: [NSArray(array: [Decimal128(123.456), Decimal128(234.567)])], count: 1) {
            $0.setOptDecimal.containsAny(in: [Decimal128(123.456), Decimal128(234.567)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setOptObjectId IN %@)",
                    values: [NSArray(array: [ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045")])], count: 1) {
            $0.setOptObjectId.containsAny(in: [ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045")])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setOptUuid IN %@)",
                    values: [NSArray(array: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])], count: 1) {
            $0.setOptUuid.containsAny(in: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY setIntOpt IN %@)",
                    values: [NSArray(array: [EnumInt.value1, EnumInt.value2])], count: 1) {
            $0.setIntOpt.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY setInt8Opt IN %@)",
                    values: [NSArray(array: [EnumInt8.value1, EnumInt8.value2])], count: 1) {
            $0.setInt8Opt.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY setInt16Opt IN %@)",
                    values: [NSArray(array: [EnumInt16.value1, EnumInt16.value2])], count: 1) {
            $0.setInt16Opt.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY setInt32Opt IN %@)",
                    values: [NSArray(array: [EnumInt32.value1, EnumInt32.value2])], count: 1) {
            $0.setInt32Opt.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY setInt64Opt IN %@)",
                    values: [NSArray(array: [EnumInt64.value1, EnumInt64.value2])], count: 1) {
            $0.setInt64Opt.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY setFloatOpt IN %@)",
                    values: [NSArray(array: [EnumFloat.value1, EnumFloat.value2])], count: 1) {
            $0.setFloatOpt.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY setDoubleOpt IN %@)",
                    values: [NSArray(array: [EnumDouble.value1, EnumDouble.value2])], count: 1) {
            $0.setDoubleOpt.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY setStringOpt IN %@)",
                    values: [NSArray(array: [EnumString.value1, EnumString.value2])], count: 1) {
            $0.setStringOpt.containsAny(in: [.value1, .value2])
        }

        let colObj = ModernCollectionObject()
        let obj = objects().first!
        colObj.set.insert(obj)
        try! realm.write {
            realm.add(colObj)
        }

        assertQuery(ModernCollectionObject.self, "(ANY set IN %@)", values: [NSArray(array: [obj])], count: 1) {
            $0.set.containsAny(in: [obj])
        }
    }

    // MARK: - Map

    private func validateAllKeys<Root: Object, T: RealmKeyedCollection>(_ name: String, _ lhs: (Query<Root>) -> Query<T>)
            where T.Key == String {
        assertQuery(Root.self, "(\(name).@allKeys == %@)", "foo", count: 1) {
            lhs($0).keys == "foo"
        }

        assertQuery(Root.self, "(\(name).@allKeys != %@)", "foo", count: 1) {
            lhs($0).keys != "foo"
        }

        assertQuery(Root.self, "(\(name).@allKeys CONTAINS[cd] %@)", "foo", count: 1) {
            lhs($0).keys.contains("foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(Root.self, "(\(name).@allKeys CONTAINS %@)", "foo", count: 1) {
            lhs($0).keys.contains("foo")
        }

        assertQuery(Root.self, "(\(name).@allKeys BEGINSWITH[cd] %@)", "foo", count: 1) {
            lhs($0).keys.starts(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(Root.self, "(\(name).@allKeys BEGINSWITH %@)", "foo", count: 1) {
            lhs($0).keys.starts(with: "foo")
        }

        assertQuery(Root.self, "(\(name).@allKeys ENDSWITH[cd] %@)", "foo", count: 1) {
            lhs($0).keys.ends(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(Root.self, "(\(name).@allKeys ENDSWITH %@)", "foo", count: 1) {
            lhs($0).keys.ends(with: "foo")
        }

        assertQuery(Root.self, "(\(name).@allKeys LIKE[c] %@)", "foo", count: 1) {
            lhs($0).keys.like("foo", caseInsensitive: true)
        }

        assertQuery(Root.self, "(\(name).@allKeys LIKE %@)", "foo", count: 1) {
            lhs($0).keys.like("foo")
        }
    }

    func testMapAllKeys() {
        validateAllKeys("mapBool", \Query<ModernAllTypesObject>.mapBool)
        validateAllKeys("mapInt", \Query<ModernAllTypesObject>.mapInt)
        validateAllKeys("mapInt8", \Query<ModernAllTypesObject>.mapInt8)
        validateAllKeys("mapInt16", \Query<ModernAllTypesObject>.mapInt16)
        validateAllKeys("mapInt32", \Query<ModernAllTypesObject>.mapInt32)
        validateAllKeys("mapInt64", \Query<ModernAllTypesObject>.mapInt64)
        validateAllKeys("mapFloat", \Query<ModernAllTypesObject>.mapFloat)
        validateAllKeys("mapDouble", \Query<ModernAllTypesObject>.mapDouble)
        validateAllKeys("mapString", \Query<ModernAllTypesObject>.mapString)
        validateAllKeys("mapBinary", \Query<ModernAllTypesObject>.mapBinary)
        validateAllKeys("mapDate", \Query<ModernAllTypesObject>.mapDate)
        validateAllKeys("mapDecimal", \Query<ModernAllTypesObject>.mapDecimal)
        validateAllKeys("mapObjectId", \Query<ModernAllTypesObject>.mapObjectId)
        validateAllKeys("mapUuid", \Query<ModernAllTypesObject>.mapUuid)
        validateAllKeys("mapAny", \Query<ModernAllTypesObject>.mapAny)
        validateAllKeys("mapInt", \Query<ModernCollectionsOfEnums>.mapInt)
        validateAllKeys("mapInt8", \Query<ModernCollectionsOfEnums>.mapInt8)
        validateAllKeys("mapInt16", \Query<ModernCollectionsOfEnums>.mapInt16)
        validateAllKeys("mapInt32", \Query<ModernCollectionsOfEnums>.mapInt32)
        validateAllKeys("mapInt64", \Query<ModernCollectionsOfEnums>.mapInt64)
        validateAllKeys("mapFloat", \Query<ModernCollectionsOfEnums>.mapFloat)
        validateAllKeys("mapDouble", \Query<ModernCollectionsOfEnums>.mapDouble)
        validateAllKeys("mapString", \Query<ModernCollectionsOfEnums>.mapString)
        validateAllKeys("mapOptBool", \Query<ModernAllTypesObject>.mapOptBool)
        validateAllKeys("mapOptInt", \Query<ModernAllTypesObject>.mapOptInt)
        validateAllKeys("mapOptInt8", \Query<ModernAllTypesObject>.mapOptInt8)
        validateAllKeys("mapOptInt16", \Query<ModernAllTypesObject>.mapOptInt16)
        validateAllKeys("mapOptInt32", \Query<ModernAllTypesObject>.mapOptInt32)
        validateAllKeys("mapOptInt64", \Query<ModernAllTypesObject>.mapOptInt64)
        validateAllKeys("mapOptFloat", \Query<ModernAllTypesObject>.mapOptFloat)
        validateAllKeys("mapOptDouble", \Query<ModernAllTypesObject>.mapOptDouble)
        validateAllKeys("mapOptString", \Query<ModernAllTypesObject>.mapOptString)
        validateAllKeys("mapOptBinary", \Query<ModernAllTypesObject>.mapOptBinary)
        validateAllKeys("mapOptDate", \Query<ModernAllTypesObject>.mapOptDate)
        validateAllKeys("mapOptDecimal", \Query<ModernAllTypesObject>.mapOptDecimal)
        validateAllKeys("mapOptObjectId", \Query<ModernAllTypesObject>.mapOptObjectId)
        validateAllKeys("mapOptUuid", \Query<ModernAllTypesObject>.mapOptUuid)
        validateAllKeys("mapIntOpt", \Query<ModernCollectionsOfEnums>.mapIntOpt)
        validateAllKeys("mapInt8Opt", \Query<ModernCollectionsOfEnums>.mapInt8Opt)
        validateAllKeys("mapInt16Opt", \Query<ModernCollectionsOfEnums>.mapInt16Opt)
        validateAllKeys("mapInt32Opt", \Query<ModernCollectionsOfEnums>.mapInt32Opt)
        validateAllKeys("mapInt64Opt", \Query<ModernCollectionsOfEnums>.mapInt64Opt)
        validateAllKeys("mapFloatOpt", \Query<ModernCollectionsOfEnums>.mapFloatOpt)
        validateAllKeys("mapDoubleOpt", \Query<ModernCollectionsOfEnums>.mapDoubleOpt)
        validateAllKeys("mapStringOpt", \Query<ModernCollectionsOfEnums>.mapStringOpt)
    }

    func testMapAllValues() {
        assertQuery(ModernAllTypesObject.self, "(mapBool.@allValues == %@)", true, count: 1) {
            $0.mapBool.values == true
        }

        assertQuery(ModernAllTypesObject.self, "(mapBool.@allValues != %@)", true, count: 0) {
            $0.mapBool.values != true
        }

        assertQuery(ModernAllTypesObject.self, "(mapInt.@allValues == %@)", 5, count: 1) {
            $0.mapInt.values == 5
        }

        assertQuery(ModernAllTypesObject.self, "(mapInt.@allValues != %@)", 5, count: 1) {
            $0.mapInt.values != 5
        }
        assertQuery(ModernAllTypesObject.self, "(mapInt.@allValues > %@)", 5, count: 1) {
            $0.mapInt.values > 5
        }

        assertQuery(ModernAllTypesObject.self, "(mapInt.@allValues >= %@)", 5, count: 1) {
            $0.mapInt.values >= 5
        }
        assertQuery(ModernAllTypesObject.self, "(mapInt.@allValues < %@)", 5, count: 0) {
            $0.mapInt.values < 5
        }

        assertQuery(ModernAllTypesObject.self, "(mapInt.@allValues <= %@)", 5, count: 1) {
            $0.mapInt.values <= 5
        }

        assertQuery(ModernAllTypesObject.self, "(mapInt8.@allValues == %@)", Int8(8), count: 1) {
            $0.mapInt8.values == Int8(8)
        }

        assertQuery(ModernAllTypesObject.self, "(mapInt8.@allValues != %@)", Int8(8), count: 1) {
            $0.mapInt8.values != Int8(8)
        }
        assertQuery(ModernAllTypesObject.self, "(mapInt8.@allValues > %@)", Int8(8), count: 1) {
            $0.mapInt8.values > Int8(8)
        }

        assertQuery(ModernAllTypesObject.self, "(mapInt8.@allValues >= %@)", Int8(8), count: 1) {
            $0.mapInt8.values >= Int8(8)
        }
        assertQuery(ModernAllTypesObject.self, "(mapInt8.@allValues < %@)", Int8(8), count: 0) {
            $0.mapInt8.values < Int8(8)
        }

        assertQuery(ModernAllTypesObject.self, "(mapInt8.@allValues <= %@)", Int8(8), count: 1) {
            $0.mapInt8.values <= Int8(8)
        }

        assertQuery(ModernAllTypesObject.self, "(mapInt16.@allValues == %@)", Int16(16), count: 1) {
            $0.mapInt16.values == Int16(16)
        }

        assertQuery(ModernAllTypesObject.self, "(mapInt16.@allValues != %@)", Int16(16), count: 1) {
            $0.mapInt16.values != Int16(16)
        }
        assertQuery(ModernAllTypesObject.self, "(mapInt16.@allValues > %@)", Int16(16), count: 1) {
            $0.mapInt16.values > Int16(16)
        }

        assertQuery(ModernAllTypesObject.self, "(mapInt16.@allValues >= %@)", Int16(16), count: 1) {
            $0.mapInt16.values >= Int16(16)
        }
        assertQuery(ModernAllTypesObject.self, "(mapInt16.@allValues < %@)", Int16(16), count: 0) {
            $0.mapInt16.values < Int16(16)
        }

        assertQuery(ModernAllTypesObject.self, "(mapInt16.@allValues <= %@)", Int16(16), count: 1) {
            $0.mapInt16.values <= Int16(16)
        }

        assertQuery(ModernAllTypesObject.self, "(mapInt32.@allValues == %@)", Int32(32), count: 1) {
            $0.mapInt32.values == Int32(32)
        }

        assertQuery(ModernAllTypesObject.self, "(mapInt32.@allValues != %@)", Int32(32), count: 1) {
            $0.mapInt32.values != Int32(32)
        }
        assertQuery(ModernAllTypesObject.self, "(mapInt32.@allValues > %@)", Int32(32), count: 1) {
            $0.mapInt32.values > Int32(32)
        }

        assertQuery(ModernAllTypesObject.self, "(mapInt32.@allValues >= %@)", Int32(32), count: 1) {
            $0.mapInt32.values >= Int32(32)
        }
        assertQuery(ModernAllTypesObject.self, "(mapInt32.@allValues < %@)", Int32(32), count: 0) {
            $0.mapInt32.values < Int32(32)
        }

        assertQuery(ModernAllTypesObject.self, "(mapInt32.@allValues <= %@)", Int32(32), count: 1) {
            $0.mapInt32.values <= Int32(32)
        }

        assertQuery(ModernAllTypesObject.self, "(mapInt64.@allValues == %@)", Int64(64), count: 1) {
            $0.mapInt64.values == Int64(64)
        }

        assertQuery(ModernAllTypesObject.self, "(mapInt64.@allValues != %@)", Int64(64), count: 1) {
            $0.mapInt64.values != Int64(64)
        }
        assertQuery(ModernAllTypesObject.self, "(mapInt64.@allValues > %@)", Int64(64), count: 1) {
            $0.mapInt64.values > Int64(64)
        }

        assertQuery(ModernAllTypesObject.self, "(mapInt64.@allValues >= %@)", Int64(64), count: 1) {
            $0.mapInt64.values >= Int64(64)
        }
        assertQuery(ModernAllTypesObject.self, "(mapInt64.@allValues < %@)", Int64(64), count: 0) {
            $0.mapInt64.values < Int64(64)
        }

        assertQuery(ModernAllTypesObject.self, "(mapInt64.@allValues <= %@)", Int64(64), count: 1) {
            $0.mapInt64.values <= Int64(64)
        }

        assertQuery(ModernAllTypesObject.self, "(mapFloat.@allValues == %@)", Float(5.55444333), count: 1) {
            $0.mapFloat.values == Float(5.55444333)
        }

        assertQuery(ModernAllTypesObject.self, "(mapFloat.@allValues != %@)", Float(5.55444333), count: 1) {
            $0.mapFloat.values != Float(5.55444333)
        }
        assertQuery(ModernAllTypesObject.self, "(mapFloat.@allValues > %@)", Float(5.55444333), count: 1) {
            $0.mapFloat.values > Float(5.55444333)
        }

        assertQuery(ModernAllTypesObject.self, "(mapFloat.@allValues >= %@)", Float(5.55444333), count: 1) {
            $0.mapFloat.values >= Float(5.55444333)
        }
        assertQuery(ModernAllTypesObject.self, "(mapFloat.@allValues < %@)", Float(5.55444333), count: 0) {
            $0.mapFloat.values < Float(5.55444333)
        }

        assertQuery(ModernAllTypesObject.self, "(mapFloat.@allValues <= %@)", Float(5.55444333), count: 1) {
            $0.mapFloat.values <= Float(5.55444333)
        }

        assertQuery(ModernAllTypesObject.self, "(mapDouble.@allValues == %@)", 123.456, count: 1) {
            $0.mapDouble.values == 123.456
        }

        assertQuery(ModernAllTypesObject.self, "(mapDouble.@allValues != %@)", 123.456, count: 1) {
            $0.mapDouble.values != 123.456
        }
        assertQuery(ModernAllTypesObject.self, "(mapDouble.@allValues > %@)", 123.456, count: 1) {
            $0.mapDouble.values > 123.456
        }

        assertQuery(ModernAllTypesObject.self, "(mapDouble.@allValues >= %@)", 123.456, count: 1) {
            $0.mapDouble.values >= 123.456
        }
        assertQuery(ModernAllTypesObject.self, "(mapDouble.@allValues < %@)", 123.456, count: 0) {
            $0.mapDouble.values < 123.456
        }

        assertQuery(ModernAllTypesObject.self, "(mapDouble.@allValues <= %@)", 123.456, count: 1) {
            $0.mapDouble.values <= 123.456
        }

        assertQuery(ModernAllTypesObject.self, "(mapString.@allValues == %@)", "Foo", count: 1) {
            $0.mapString.values == "Foo"
        }

        assertQuery(ModernAllTypesObject.self, "(mapString.@allValues != %@)", "Foo", count: 1) {
            $0.mapString.values != "Foo"
        }

        assertQuery(ModernAllTypesObject.self, "(mapString.@allValues CONTAINS[cd] %@)", "Foo", count: 1) {
            $0.mapString.values.contains("Foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(ModernAllTypesObject.self, "(mapString.@allValues CONTAINS %@)", "Foo", count: 1) {
            $0.mapString.values.contains("Foo")
        }

        assertQuery(ModernAllTypesObject.self, "(mapString.@allValues BEGINSWITH[cd] %@)", "Foo", count: 1) {
            $0.mapString.values.starts(with: "Foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(ModernAllTypesObject.self, "(mapString.@allValues BEGINSWITH %@)", "Foo", count: 1) {
            $0.mapString.values.starts(with: "Foo")
        }

        assertQuery(ModernAllTypesObject.self, "(mapString.@allValues ENDSWITH[cd] %@)", "Foo", count: 1) {
            $0.mapString.values.ends(with: "Foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(ModernAllTypesObject.self, "(mapString.@allValues ENDSWITH %@)", "Foo", count: 1) {
            $0.mapString.values.ends(with: "Foo")
        }

        assertQuery(ModernAllTypesObject.self, "(mapString.@allValues LIKE[c] %@)", "Foo", count: 1) {
            $0.mapString.values.like("Foo", caseInsensitive: true)
        }

        assertQuery(ModernAllTypesObject.self, "(mapString.@allValues LIKE %@)", "Foo", count: 1) {
            $0.mapString.values.like("Foo")
        }
        assertQuery(ModernAllTypesObject.self, "(mapBinary.@allValues == %@)", Data(count: 64), count: 1) {
            $0.mapBinary.values == Data(count: 64)
        }

        assertQuery(ModernAllTypesObject.self, "(mapBinary.@allValues != %@)", Data(count: 64), count: 1) {
            $0.mapBinary.values != Data(count: 64)
        }

        assertQuery(ModernAllTypesObject.self, "(mapDate.@allValues == %@)", Date(timeIntervalSince1970: 1000000), count: 1) {
            $0.mapDate.values == Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(ModernAllTypesObject.self, "(mapDate.@allValues != %@)", Date(timeIntervalSince1970: 1000000), count: 1) {
            $0.mapDate.values != Date(timeIntervalSince1970: 1000000)
        }
        assertQuery(ModernAllTypesObject.self, "(mapDate.@allValues > %@)", Date(timeIntervalSince1970: 1000000), count: 1) {
            $0.mapDate.values > Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(ModernAllTypesObject.self, "(mapDate.@allValues >= %@)", Date(timeIntervalSince1970: 1000000), count: 1) {
            $0.mapDate.values >= Date(timeIntervalSince1970: 1000000)
        }
        assertQuery(ModernAllTypesObject.self, "(mapDate.@allValues < %@)", Date(timeIntervalSince1970: 1000000), count: 0) {
            $0.mapDate.values < Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(ModernAllTypesObject.self, "(mapDate.@allValues <= %@)", Date(timeIntervalSince1970: 1000000), count: 1) {
            $0.mapDate.values <= Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(ModernAllTypesObject.self, "(mapDecimal.@allValues == %@)", Decimal128(123.456), count: 1) {
            $0.mapDecimal.values == Decimal128(123.456)
        }

        assertQuery(ModernAllTypesObject.self, "(mapDecimal.@allValues != %@)", Decimal128(123.456), count: 1) {
            $0.mapDecimal.values != Decimal128(123.456)
        }
        assertQuery(ModernAllTypesObject.self, "(mapDecimal.@allValues > %@)", Decimal128(123.456), count: 1) {
            $0.mapDecimal.values > Decimal128(123.456)
        }

        assertQuery(ModernAllTypesObject.self, "(mapDecimal.@allValues >= %@)", Decimal128(123.456), count: 1) {
            $0.mapDecimal.values >= Decimal128(123.456)
        }
        assertQuery(ModernAllTypesObject.self, "(mapDecimal.@allValues < %@)", Decimal128(123.456), count: 0) {
            $0.mapDecimal.values < Decimal128(123.456)
        }

        assertQuery(ModernAllTypesObject.self, "(mapDecimal.@allValues <= %@)", Decimal128(123.456), count: 1) {
            $0.mapDecimal.values <= Decimal128(123.456)
        }

        assertQuery(ModernAllTypesObject.self, "(mapObjectId.@allValues == %@)", ObjectId("61184062c1d8f096a3695046"), count: 1) {
            $0.mapObjectId.values == ObjectId("61184062c1d8f096a3695046")
        }

        assertQuery(ModernAllTypesObject.self, "(mapObjectId.@allValues != %@)", ObjectId("61184062c1d8f096a3695046"), count: 1) {
            $0.mapObjectId.values != ObjectId("61184062c1d8f096a3695046")
        }

        assertQuery(ModernAllTypesObject.self, "(mapUuid.@allValues == %@)", UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, count: 1) {
            $0.mapUuid.values == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!
        }

        assertQuery(ModernAllTypesObject.self, "(mapUuid.@allValues != %@)", UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, count: 1) {
            $0.mapUuid.values != UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!
        }

        assertQuery(ModernAllTypesObject.self, "(mapAny.@allValues == %@)", AnyRealmValue.objectId(ObjectId("61184062c1d8f096a3695046")), count: 1) {
            $0.mapAny.values == AnyRealmValue.objectId(ObjectId("61184062c1d8f096a3695046"))
        }

        assertQuery(ModernAllTypesObject.self, "(mapAny.@allValues != %@)", AnyRealmValue.objectId(ObjectId("61184062c1d8f096a3695046")), count: 1) {
            $0.mapAny.values != AnyRealmValue.objectId(ObjectId("61184062c1d8f096a3695046"))
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapInt.@allValues == %@)", EnumInt.value1, count: 1) {
            $0.mapInt.values == .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapInt.@allValues != %@)", EnumInt.value1, count: 1) {
            $0.mapInt.values != .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(mapInt.@allValues > %@)", EnumInt.value1, count: 1) {
            $0.mapInt.values > .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapInt.@allValues >= %@)", EnumInt.value1, count: 1) {
            $0.mapInt.values >= .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(mapInt.@allValues < %@)", EnumInt.value1, count: 0) {
            $0.mapInt.values < .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapInt.@allValues <= %@)", EnumInt.value1, count: 1) {
            $0.mapInt.values <= .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapInt8.@allValues == %@)", EnumInt8.value1, count: 1) {
            $0.mapInt8.values == .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapInt8.@allValues != %@)", EnumInt8.value1, count: 1) {
            $0.mapInt8.values != .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(mapInt8.@allValues > %@)", EnumInt8.value1, count: 1) {
            $0.mapInt8.values > .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapInt8.@allValues >= %@)", EnumInt8.value1, count: 1) {
            $0.mapInt8.values >= .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(mapInt8.@allValues < %@)", EnumInt8.value1, count: 0) {
            $0.mapInt8.values < .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapInt8.@allValues <= %@)", EnumInt8.value1, count: 1) {
            $0.mapInt8.values <= .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapInt16.@allValues == %@)", EnumInt16.value1, count: 1) {
            $0.mapInt16.values == .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapInt16.@allValues != %@)", EnumInt16.value1, count: 1) {
            $0.mapInt16.values != .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(mapInt16.@allValues > %@)", EnumInt16.value1, count: 1) {
            $0.mapInt16.values > .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapInt16.@allValues >= %@)", EnumInt16.value1, count: 1) {
            $0.mapInt16.values >= .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(mapInt16.@allValues < %@)", EnumInt16.value1, count: 0) {
            $0.mapInt16.values < .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapInt16.@allValues <= %@)", EnumInt16.value1, count: 1) {
            $0.mapInt16.values <= .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapInt32.@allValues == %@)", EnumInt32.value1, count: 1) {
            $0.mapInt32.values == .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapInt32.@allValues != %@)", EnumInt32.value1, count: 1) {
            $0.mapInt32.values != .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(mapInt32.@allValues > %@)", EnumInt32.value1, count: 1) {
            $0.mapInt32.values > .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapInt32.@allValues >= %@)", EnumInt32.value1, count: 1) {
            $0.mapInt32.values >= .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(mapInt32.@allValues < %@)", EnumInt32.value1, count: 0) {
            $0.mapInt32.values < .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapInt32.@allValues <= %@)", EnumInt32.value1, count: 1) {
            $0.mapInt32.values <= .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapInt64.@allValues == %@)", EnumInt64.value1, count: 1) {
            $0.mapInt64.values == .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapInt64.@allValues != %@)", EnumInt64.value1, count: 1) {
            $0.mapInt64.values != .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(mapInt64.@allValues > %@)", EnumInt64.value1, count: 1) {
            $0.mapInt64.values > .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapInt64.@allValues >= %@)", EnumInt64.value1, count: 1) {
            $0.mapInt64.values >= .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(mapInt64.@allValues < %@)", EnumInt64.value1, count: 0) {
            $0.mapInt64.values < .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapInt64.@allValues <= %@)", EnumInt64.value1, count: 1) {
            $0.mapInt64.values <= .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapFloat.@allValues == %@)", EnumFloat.value1, count: 1) {
            $0.mapFloat.values == .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapFloat.@allValues != %@)", EnumFloat.value1, count: 1) {
            $0.mapFloat.values != .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(mapFloat.@allValues > %@)", EnumFloat.value1, count: 1) {
            $0.mapFloat.values > .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapFloat.@allValues >= %@)", EnumFloat.value1, count: 1) {
            $0.mapFloat.values >= .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(mapFloat.@allValues < %@)", EnumFloat.value1, count: 0) {
            $0.mapFloat.values < .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapFloat.@allValues <= %@)", EnumFloat.value1, count: 1) {
            $0.mapFloat.values <= .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapDouble.@allValues == %@)", EnumDouble.value1, count: 1) {
            $0.mapDouble.values == .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapDouble.@allValues != %@)", EnumDouble.value1, count: 1) {
            $0.mapDouble.values != .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(mapDouble.@allValues > %@)", EnumDouble.value1, count: 1) {
            $0.mapDouble.values > .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapDouble.@allValues >= %@)", EnumDouble.value1, count: 1) {
            $0.mapDouble.values >= .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(mapDouble.@allValues < %@)", EnumDouble.value1, count: 0) {
            $0.mapDouble.values < .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapDouble.@allValues <= %@)", EnumDouble.value1, count: 1) {
            $0.mapDouble.values <= .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapString.@allValues == %@)", EnumString.value1, count: 1) {
            $0.mapString.values == .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapString.@allValues != %@)", EnumString.value1, count: 1) {
            $0.mapString.values != .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapString.@allValues CONTAINS[cd] %@)", EnumString.value1, count: 1) {
            $0.mapString.values.contains(.value1, options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapString.@allValues CONTAINS %@)", EnumString.value1, count: 1) {
            $0.mapString.values.contains(.value1)
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapString.@allValues BEGINSWITH[cd] %@)", EnumString.value1, count: 1) {
            $0.mapString.values.starts(with: .value1, options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapString.@allValues BEGINSWITH %@)", EnumString.value1, count: 1) {
            $0.mapString.values.starts(with: .value1)
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapString.@allValues ENDSWITH[cd] %@)", EnumString.value1, count: 1) {
            $0.mapString.values.ends(with: .value1, options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapString.@allValues ENDSWITH %@)", EnumString.value1, count: 1) {
            $0.mapString.values.ends(with: .value1)
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapString.@allValues LIKE[c] %@)", EnumString.value1, count: 1) {
            $0.mapString.values.like(.value1, caseInsensitive: true)
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapString.@allValues LIKE %@)", EnumString.value1, count: 1) {
            $0.mapString.values.like(.value1)
        }
        assertQuery(ModernAllTypesObject.self, "(mapOptBool.@allValues == %@)", true, count: 1) {
            $0.mapOptBool.values == true
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptBool.@allValues != %@)", true, count: 0) {
            $0.mapOptBool.values != true
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptInt.@allValues == %@)", 5, count: 1) {
            $0.mapOptInt.values == 5
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptInt.@allValues != %@)", 5, count: 1) {
            $0.mapOptInt.values != 5
        }
        assertQuery(ModernAllTypesObject.self, "(mapOptInt.@allValues > %@)", 5, count: 1) {
            $0.mapOptInt.values > 5
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptInt.@allValues >= %@)", 5, count: 1) {
            $0.mapOptInt.values >= 5
        }
        assertQuery(ModernAllTypesObject.self, "(mapOptInt.@allValues < %@)", 5, count: 0) {
            $0.mapOptInt.values < 5
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptInt.@allValues <= %@)", 5, count: 1) {
            $0.mapOptInt.values <= 5
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptInt8.@allValues == %@)", Int8(8), count: 1) {
            $0.mapOptInt8.values == Int8(8)
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptInt8.@allValues != %@)", Int8(8), count: 1) {
            $0.mapOptInt8.values != Int8(8)
        }
        assertQuery(ModernAllTypesObject.self, "(mapOptInt8.@allValues > %@)", Int8(8), count: 1) {
            $0.mapOptInt8.values > Int8(8)
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptInt8.@allValues >= %@)", Int8(8), count: 1) {
            $0.mapOptInt8.values >= Int8(8)
        }
        assertQuery(ModernAllTypesObject.self, "(mapOptInt8.@allValues < %@)", Int8(8), count: 0) {
            $0.mapOptInt8.values < Int8(8)
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptInt8.@allValues <= %@)", Int8(8), count: 1) {
            $0.mapOptInt8.values <= Int8(8)
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptInt16.@allValues == %@)", Int16(16), count: 1) {
            $0.mapOptInt16.values == Int16(16)
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptInt16.@allValues != %@)", Int16(16), count: 1) {
            $0.mapOptInt16.values != Int16(16)
        }
        assertQuery(ModernAllTypesObject.self, "(mapOptInt16.@allValues > %@)", Int16(16), count: 1) {
            $0.mapOptInt16.values > Int16(16)
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptInt16.@allValues >= %@)", Int16(16), count: 1) {
            $0.mapOptInt16.values >= Int16(16)
        }
        assertQuery(ModernAllTypesObject.self, "(mapOptInt16.@allValues < %@)", Int16(16), count: 0) {
            $0.mapOptInt16.values < Int16(16)
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptInt16.@allValues <= %@)", Int16(16), count: 1) {
            $0.mapOptInt16.values <= Int16(16)
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptInt32.@allValues == %@)", Int32(32), count: 1) {
            $0.mapOptInt32.values == Int32(32)
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptInt32.@allValues != %@)", Int32(32), count: 1) {
            $0.mapOptInt32.values != Int32(32)
        }
        assertQuery(ModernAllTypesObject.self, "(mapOptInt32.@allValues > %@)", Int32(32), count: 1) {
            $0.mapOptInt32.values > Int32(32)
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptInt32.@allValues >= %@)", Int32(32), count: 1) {
            $0.mapOptInt32.values >= Int32(32)
        }
        assertQuery(ModernAllTypesObject.self, "(mapOptInt32.@allValues < %@)", Int32(32), count: 0) {
            $0.mapOptInt32.values < Int32(32)
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptInt32.@allValues <= %@)", Int32(32), count: 1) {
            $0.mapOptInt32.values <= Int32(32)
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptInt64.@allValues == %@)", Int64(64), count: 1) {
            $0.mapOptInt64.values == Int64(64)
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptInt64.@allValues != %@)", Int64(64), count: 1) {
            $0.mapOptInt64.values != Int64(64)
        }
        assertQuery(ModernAllTypesObject.self, "(mapOptInt64.@allValues > %@)", Int64(64), count: 1) {
            $0.mapOptInt64.values > Int64(64)
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptInt64.@allValues >= %@)", Int64(64), count: 1) {
            $0.mapOptInt64.values >= Int64(64)
        }
        assertQuery(ModernAllTypesObject.self, "(mapOptInt64.@allValues < %@)", Int64(64), count: 0) {
            $0.mapOptInt64.values < Int64(64)
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptInt64.@allValues <= %@)", Int64(64), count: 1) {
            $0.mapOptInt64.values <= Int64(64)
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptFloat.@allValues == %@)", Float(5.55444333), count: 1) {
            $0.mapOptFloat.values == Float(5.55444333)
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptFloat.@allValues != %@)", Float(5.55444333), count: 1) {
            $0.mapOptFloat.values != Float(5.55444333)
        }
        assertQuery(ModernAllTypesObject.self, "(mapOptFloat.@allValues > %@)", Float(5.55444333), count: 1) {
            $0.mapOptFloat.values > Float(5.55444333)
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptFloat.@allValues >= %@)", Float(5.55444333), count: 1) {
            $0.mapOptFloat.values >= Float(5.55444333)
        }
        assertQuery(ModernAllTypesObject.self, "(mapOptFloat.@allValues < %@)", Float(5.55444333), count: 0) {
            $0.mapOptFloat.values < Float(5.55444333)
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptFloat.@allValues <= %@)", Float(5.55444333), count: 1) {
            $0.mapOptFloat.values <= Float(5.55444333)
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptDouble.@allValues == %@)", 123.456, count: 1) {
            $0.mapOptDouble.values == 123.456
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptDouble.@allValues != %@)", 123.456, count: 1) {
            $0.mapOptDouble.values != 123.456
        }
        assertQuery(ModernAllTypesObject.self, "(mapOptDouble.@allValues > %@)", 123.456, count: 1) {
            $0.mapOptDouble.values > 123.456
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptDouble.@allValues >= %@)", 123.456, count: 1) {
            $0.mapOptDouble.values >= 123.456
        }
        assertQuery(ModernAllTypesObject.self, "(mapOptDouble.@allValues < %@)", 123.456, count: 0) {
            $0.mapOptDouble.values < 123.456
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptDouble.@allValues <= %@)", 123.456, count: 1) {
            $0.mapOptDouble.values <= 123.456
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptString.@allValues == %@)", "Foo", count: 1) {
            $0.mapOptString.values == "Foo"
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptString.@allValues != %@)", "Foo", count: 1) {
            $0.mapOptString.values != "Foo"
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptString.@allValues CONTAINS[cd] %@)", "Foo", count: 1) {
            $0.mapOptString.values.contains("Foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptString.@allValues CONTAINS %@)", "Foo", count: 1) {
            $0.mapOptString.values.contains("Foo")
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptString.@allValues BEGINSWITH[cd] %@)", "Foo", count: 1) {
            $0.mapOptString.values.starts(with: "Foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptString.@allValues BEGINSWITH %@)", "Foo", count: 1) {
            $0.mapOptString.values.starts(with: "Foo")
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptString.@allValues ENDSWITH[cd] %@)", "Foo", count: 1) {
            $0.mapOptString.values.ends(with: "Foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptString.@allValues ENDSWITH %@)", "Foo", count: 1) {
            $0.mapOptString.values.ends(with: "Foo")
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptString.@allValues LIKE[c] %@)", "Foo", count: 1) {
            $0.mapOptString.values.like("Foo", caseInsensitive: true)
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptString.@allValues LIKE %@)", "Foo", count: 1) {
            $0.mapOptString.values.like("Foo")
        }
        assertQuery(ModernAllTypesObject.self, "(mapOptBinary.@allValues == %@)", Data(count: 64), count: 1) {
            $0.mapOptBinary.values == Data(count: 64)
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptBinary.@allValues != %@)", Data(count: 64), count: 1) {
            $0.mapOptBinary.values != Data(count: 64)
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptDate.@allValues == %@)", Date(timeIntervalSince1970: 1000000), count: 1) {
            $0.mapOptDate.values == Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptDate.@allValues != %@)", Date(timeIntervalSince1970: 1000000), count: 1) {
            $0.mapOptDate.values != Date(timeIntervalSince1970: 1000000)
        }
        assertQuery(ModernAllTypesObject.self, "(mapOptDate.@allValues > %@)", Date(timeIntervalSince1970: 1000000), count: 1) {
            $0.mapOptDate.values > Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptDate.@allValues >= %@)", Date(timeIntervalSince1970: 1000000), count: 1) {
            $0.mapOptDate.values >= Date(timeIntervalSince1970: 1000000)
        }
        assertQuery(ModernAllTypesObject.self, "(mapOptDate.@allValues < %@)", Date(timeIntervalSince1970: 1000000), count: 0) {
            $0.mapOptDate.values < Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptDate.@allValues <= %@)", Date(timeIntervalSince1970: 1000000), count: 1) {
            $0.mapOptDate.values <= Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptDecimal.@allValues == %@)", Decimal128(123.456), count: 1) {
            $0.mapOptDecimal.values == Decimal128(123.456)
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptDecimal.@allValues != %@)", Decimal128(123.456), count: 1) {
            $0.mapOptDecimal.values != Decimal128(123.456)
        }
        assertQuery(ModernAllTypesObject.self, "(mapOptDecimal.@allValues > %@)", Decimal128(123.456), count: 1) {
            $0.mapOptDecimal.values > Decimal128(123.456)
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptDecimal.@allValues >= %@)", Decimal128(123.456), count: 1) {
            $0.mapOptDecimal.values >= Decimal128(123.456)
        }
        assertQuery(ModernAllTypesObject.self, "(mapOptDecimal.@allValues < %@)", Decimal128(123.456), count: 0) {
            $0.mapOptDecimal.values < Decimal128(123.456)
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptDecimal.@allValues <= %@)", Decimal128(123.456), count: 1) {
            $0.mapOptDecimal.values <= Decimal128(123.456)
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptObjectId.@allValues == %@)", ObjectId("61184062c1d8f096a3695046"), count: 1) {
            $0.mapOptObjectId.values == ObjectId("61184062c1d8f096a3695046")
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptObjectId.@allValues != %@)", ObjectId("61184062c1d8f096a3695046"), count: 1) {
            $0.mapOptObjectId.values != ObjectId("61184062c1d8f096a3695046")
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptUuid.@allValues == %@)", UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, count: 1) {
            $0.mapOptUuid.values == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!
        }

        assertQuery(ModernAllTypesObject.self, "(mapOptUuid.@allValues != %@)", UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, count: 1) {
            $0.mapOptUuid.values != UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapIntOpt.@allValues == %@)", EnumInt.value1, count: 1) {
            $0.mapIntOpt.values == .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapIntOpt.@allValues != %@)", EnumInt.value1, count: 1) {
            $0.mapIntOpt.values != .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(mapIntOpt.@allValues > %@)", EnumInt.value1, count: 1) {
            $0.mapIntOpt.values > .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapIntOpt.@allValues >= %@)", EnumInt.value1, count: 1) {
            $0.mapIntOpt.values >= .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(mapIntOpt.@allValues < %@)", EnumInt.value1, count: 0) {
            $0.mapIntOpt.values < .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapIntOpt.@allValues <= %@)", EnumInt.value1, count: 1) {
            $0.mapIntOpt.values <= .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapInt8Opt.@allValues == %@)", EnumInt8.value1, count: 1) {
            $0.mapInt8Opt.values == .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapInt8Opt.@allValues != %@)", EnumInt8.value1, count: 1) {
            $0.mapInt8Opt.values != .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(mapInt8Opt.@allValues > %@)", EnumInt8.value1, count: 1) {
            $0.mapInt8Opt.values > .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapInt8Opt.@allValues >= %@)", EnumInt8.value1, count: 1) {
            $0.mapInt8Opt.values >= .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(mapInt8Opt.@allValues < %@)", EnumInt8.value1, count: 0) {
            $0.mapInt8Opt.values < .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapInt8Opt.@allValues <= %@)", EnumInt8.value1, count: 1) {
            $0.mapInt8Opt.values <= .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapInt16Opt.@allValues == %@)", EnumInt16.value1, count: 1) {
            $0.mapInt16Opt.values == .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapInt16Opt.@allValues != %@)", EnumInt16.value1, count: 1) {
            $0.mapInt16Opt.values != .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(mapInt16Opt.@allValues > %@)", EnumInt16.value1, count: 1) {
            $0.mapInt16Opt.values > .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapInt16Opt.@allValues >= %@)", EnumInt16.value1, count: 1) {
            $0.mapInt16Opt.values >= .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(mapInt16Opt.@allValues < %@)", EnumInt16.value1, count: 0) {
            $0.mapInt16Opt.values < .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapInt16Opt.@allValues <= %@)", EnumInt16.value1, count: 1) {
            $0.mapInt16Opt.values <= .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapInt32Opt.@allValues == %@)", EnumInt32.value1, count: 1) {
            $0.mapInt32Opt.values == .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapInt32Opt.@allValues != %@)", EnumInt32.value1, count: 1) {
            $0.mapInt32Opt.values != .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(mapInt32Opt.@allValues > %@)", EnumInt32.value1, count: 1) {
            $0.mapInt32Opt.values > .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapInt32Opt.@allValues >= %@)", EnumInt32.value1, count: 1) {
            $0.mapInt32Opt.values >= .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(mapInt32Opt.@allValues < %@)", EnumInt32.value1, count: 0) {
            $0.mapInt32Opt.values < .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapInt32Opt.@allValues <= %@)", EnumInt32.value1, count: 1) {
            $0.mapInt32Opt.values <= .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapInt64Opt.@allValues == %@)", EnumInt64.value1, count: 1) {
            $0.mapInt64Opt.values == .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapInt64Opt.@allValues != %@)", EnumInt64.value1, count: 1) {
            $0.mapInt64Opt.values != .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(mapInt64Opt.@allValues > %@)", EnumInt64.value1, count: 1) {
            $0.mapInt64Opt.values > .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapInt64Opt.@allValues >= %@)", EnumInt64.value1, count: 1) {
            $0.mapInt64Opt.values >= .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(mapInt64Opt.@allValues < %@)", EnumInt64.value1, count: 0) {
            $0.mapInt64Opt.values < .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapInt64Opt.@allValues <= %@)", EnumInt64.value1, count: 1) {
            $0.mapInt64Opt.values <= .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapFloatOpt.@allValues == %@)", EnumFloat.value1, count: 1) {
            $0.mapFloatOpt.values == .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapFloatOpt.@allValues != %@)", EnumFloat.value1, count: 1) {
            $0.mapFloatOpt.values != .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(mapFloatOpt.@allValues > %@)", EnumFloat.value1, count: 1) {
            $0.mapFloatOpt.values > .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapFloatOpt.@allValues >= %@)", EnumFloat.value1, count: 1) {
            $0.mapFloatOpt.values >= .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(mapFloatOpt.@allValues < %@)", EnumFloat.value1, count: 0) {
            $0.mapFloatOpt.values < .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapFloatOpt.@allValues <= %@)", EnumFloat.value1, count: 1) {
            $0.mapFloatOpt.values <= .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapDoubleOpt.@allValues == %@)", EnumDouble.value1, count: 1) {
            $0.mapDoubleOpt.values == .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapDoubleOpt.@allValues != %@)", EnumDouble.value1, count: 1) {
            $0.mapDoubleOpt.values != .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(mapDoubleOpt.@allValues > %@)", EnumDouble.value1, count: 1) {
            $0.mapDoubleOpt.values > .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapDoubleOpt.@allValues >= %@)", EnumDouble.value1, count: 1) {
            $0.mapDoubleOpt.values >= .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(mapDoubleOpt.@allValues < %@)", EnumDouble.value1, count: 0) {
            $0.mapDoubleOpt.values < .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapDoubleOpt.@allValues <= %@)", EnumDouble.value1, count: 1) {
            $0.mapDoubleOpt.values <= .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapStringOpt.@allValues == %@)", EnumString.value1, count: 1) {
            $0.mapStringOpt.values == .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapStringOpt.@allValues != %@)", EnumString.value1, count: 1) {
            $0.mapStringOpt.values != .value1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapStringOpt.@allValues CONTAINS[cd] %@)", EnumString.value1, count: 1) {
            $0.mapStringOpt.values.contains(.value1, options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapStringOpt.@allValues CONTAINS %@)", EnumString.value1, count: 1) {
            $0.mapStringOpt.values.contains(.value1)
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapStringOpt.@allValues BEGINSWITH[cd] %@)", EnumString.value1, count: 1) {
            $0.mapStringOpt.values.starts(with: .value1, options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapStringOpt.@allValues BEGINSWITH %@)", EnumString.value1, count: 1) {
            $0.mapStringOpt.values.starts(with: .value1)
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapStringOpt.@allValues ENDSWITH[cd] %@)", EnumString.value1, count: 1) {
            $0.mapStringOpt.values.ends(with: .value1, options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapStringOpt.@allValues ENDSWITH %@)", EnumString.value1, count: 1) {
            $0.mapStringOpt.values.ends(with: .value1)
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapStringOpt.@allValues LIKE[c] %@)", EnumString.value1, count: 1) {
            $0.mapStringOpt.values.like(.value1, caseInsensitive: true)
        }

        assertQuery(ModernCollectionsOfEnums.self, "(mapStringOpt.@allValues LIKE %@)", EnumString.value1, count: 1) {
            $0.mapStringOpt.values.like(.value1)
        }
    }

    func testMapContainsRange() {
        assertQuery(ModernAllTypesObject.self, "((mapInt.@min >= %@) && (mapInt.@max <= %@))",
                    values: [5, 6], count: 1) {
            $0.mapInt.contains(5...6)
        }
        assertQuery(ModernAllTypesObject.self, "((mapInt.@min >= %@) && (mapInt.@max < %@))",
                    values: [5, 6], count: 0) {
            $0.mapInt.contains(5..<6)
        }
        assertQuery(ModernAllTypesObject.self, "((mapInt8.@min >= %@) && (mapInt8.@max <= %@))",
                    values: [Int8(8), Int8(9)], count: 1) {
            $0.mapInt8.contains(Int8(8)...Int8(9))
        }
        assertQuery(ModernAllTypesObject.self, "((mapInt8.@min >= %@) && (mapInt8.@max < %@))",
                    values: [Int8(8), Int8(9)], count: 0) {
            $0.mapInt8.contains(Int8(8)..<Int8(9))
        }
        assertQuery(ModernAllTypesObject.self, "((mapInt16.@min >= %@) && (mapInt16.@max <= %@))",
                    values: [Int16(16), Int16(17)], count: 1) {
            $0.mapInt16.contains(Int16(16)...Int16(17))
        }
        assertQuery(ModernAllTypesObject.self, "((mapInt16.@min >= %@) && (mapInt16.@max < %@))",
                    values: [Int16(16), Int16(17)], count: 0) {
            $0.mapInt16.contains(Int16(16)..<Int16(17))
        }
        assertQuery(ModernAllTypesObject.self, "((mapInt32.@min >= %@) && (mapInt32.@max <= %@))",
                    values: [Int32(32), Int32(33)], count: 1) {
            $0.mapInt32.contains(Int32(32)...Int32(33))
        }
        assertQuery(ModernAllTypesObject.self, "((mapInt32.@min >= %@) && (mapInt32.@max < %@))",
                    values: [Int32(32), Int32(33)], count: 0) {
            $0.mapInt32.contains(Int32(32)..<Int32(33))
        }
        assertQuery(ModernAllTypesObject.self, "((mapInt64.@min >= %@) && (mapInt64.@max <= %@))",
                    values: [Int64(64), Int64(65)], count: 1) {
            $0.mapInt64.contains(Int64(64)...Int64(65))
        }
        assertQuery(ModernAllTypesObject.self, "((mapInt64.@min >= %@) && (mapInt64.@max < %@))",
                    values: [Int64(64), Int64(65)], count: 0) {
            $0.mapInt64.contains(Int64(64)..<Int64(65))
        }
        assertQuery(ModernAllTypesObject.self, "((mapFloat.@min >= %@) && (mapFloat.@max <= %@))",
                    values: [Float(5.55444333), Float(6.55444333)], count: 1) {
            $0.mapFloat.contains(Float(5.55444333)...Float(6.55444333))
        }
        assertQuery(ModernAllTypesObject.self, "((mapFloat.@min >= %@) && (mapFloat.@max < %@))",
                    values: [Float(5.55444333), Float(6.55444333)], count: 0) {
            $0.mapFloat.contains(Float(5.55444333)..<Float(6.55444333))
        }
        assertQuery(ModernAllTypesObject.self, "((mapDouble.@min >= %@) && (mapDouble.@max <= %@))",
                    values: [123.456, 234.567], count: 1) {
            $0.mapDouble.contains(123.456...234.567)
        }
        assertQuery(ModernAllTypesObject.self, "((mapDouble.@min >= %@) && (mapDouble.@max < %@))",
                    values: [123.456, 234.567], count: 0) {
            $0.mapDouble.contains(123.456..<234.567)
        }
        assertQuery(ModernAllTypesObject.self, "((mapDate.@min >= %@) && (mapDate.@max <= %@))",
                    values: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)], count: 1) {
            $0.mapDate.contains(Date(timeIntervalSince1970: 1000000)...Date(timeIntervalSince1970: 2000000))
        }
        assertQuery(ModernAllTypesObject.self, "((mapDate.@min >= %@) && (mapDate.@max < %@))",
                    values: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)], count: 0) {
            $0.mapDate.contains(Date(timeIntervalSince1970: 1000000)..<Date(timeIntervalSince1970: 2000000))
        }
        assertQuery(ModernAllTypesObject.self, "((mapDecimal.@min >= %@) && (mapDecimal.@max <= %@))",
                    values: [Decimal128(123.456), Decimal128(234.567)], count: 1) {
            $0.mapDecimal.contains(Decimal128(123.456)...Decimal128(234.567))
        }
        assertQuery(ModernAllTypesObject.self, "((mapDecimal.@min >= %@) && (mapDecimal.@max < %@))",
                    values: [Decimal128(123.456), Decimal128(234.567)], count: 0) {
            $0.mapDecimal.contains(Decimal128(123.456)..<Decimal128(234.567))
        }
        assertQuery(ModernCollectionsOfEnums.self, "((mapInt.@min >= %@) && (mapInt.@max <= %@))",
                    values: [EnumInt.value1.rawValue, EnumInt.value2.rawValue], count: 1) {
            $0.mapInt.rawValue.contains(EnumInt.value1.rawValue...EnumInt.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((mapInt.@min >= %@) && (mapInt.@max < %@))",
                    values: [EnumInt.value1.rawValue, EnumInt.value2.rawValue], count: 0) {
            $0.mapInt.rawValue.contains(EnumInt.value1.rawValue..<EnumInt.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((mapInt8.@min >= %@) && (mapInt8.@max <= %@))",
                    values: [EnumInt8.value1.rawValue, EnumInt8.value2.rawValue], count: 1) {
            $0.mapInt8.rawValue.contains(EnumInt8.value1.rawValue...EnumInt8.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((mapInt8.@min >= %@) && (mapInt8.@max < %@))",
                    values: [EnumInt8.value1.rawValue, EnumInt8.value2.rawValue], count: 0) {
            $0.mapInt8.rawValue.contains(EnumInt8.value1.rawValue..<EnumInt8.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((mapInt16.@min >= %@) && (mapInt16.@max <= %@))",
                    values: [EnumInt16.value1.rawValue, EnumInt16.value2.rawValue], count: 1) {
            $0.mapInt16.rawValue.contains(EnumInt16.value1.rawValue...EnumInt16.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((mapInt16.@min >= %@) && (mapInt16.@max < %@))",
                    values: [EnumInt16.value1.rawValue, EnumInt16.value2.rawValue], count: 0) {
            $0.mapInt16.rawValue.contains(EnumInt16.value1.rawValue..<EnumInt16.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((mapInt32.@min >= %@) && (mapInt32.@max <= %@))",
                    values: [EnumInt32.value1.rawValue, EnumInt32.value2.rawValue], count: 1) {
            $0.mapInt32.rawValue.contains(EnumInt32.value1.rawValue...EnumInt32.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((mapInt32.@min >= %@) && (mapInt32.@max < %@))",
                    values: [EnumInt32.value1.rawValue, EnumInt32.value2.rawValue], count: 0) {
            $0.mapInt32.rawValue.contains(EnumInt32.value1.rawValue..<EnumInt32.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((mapInt64.@min >= %@) && (mapInt64.@max <= %@))",
                    values: [EnumInt64.value1.rawValue, EnumInt64.value2.rawValue], count: 1) {
            $0.mapInt64.rawValue.contains(EnumInt64.value1.rawValue...EnumInt64.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((mapInt64.@min >= %@) && (mapInt64.@max < %@))",
                    values: [EnumInt64.value1.rawValue, EnumInt64.value2.rawValue], count: 0) {
            $0.mapInt64.rawValue.contains(EnumInt64.value1.rawValue..<EnumInt64.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((mapFloat.@min >= %@) && (mapFloat.@max <= %@))",
                    values: [EnumFloat.value1.rawValue, EnumFloat.value2.rawValue], count: 1) {
            $0.mapFloat.rawValue.contains(EnumFloat.value1.rawValue...EnumFloat.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((mapFloat.@min >= %@) && (mapFloat.@max < %@))",
                    values: [EnumFloat.value1.rawValue, EnumFloat.value2.rawValue], count: 0) {
            $0.mapFloat.rawValue.contains(EnumFloat.value1.rawValue..<EnumFloat.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((mapDouble.@min >= %@) && (mapDouble.@max <= %@))",
                    values: [EnumDouble.value1.rawValue, EnumDouble.value2.rawValue], count: 1) {
            $0.mapDouble.rawValue.contains(EnumDouble.value1.rawValue...EnumDouble.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((mapDouble.@min >= %@) && (mapDouble.@max < %@))",
                    values: [EnumDouble.value1.rawValue, EnumDouble.value2.rawValue], count: 0) {
            $0.mapDouble.rawValue.contains(EnumDouble.value1.rawValue..<EnumDouble.value2.rawValue)
        }
        assertQuery(ModernAllTypesObject.self, "((mapOptInt.@min >= %@) && (mapOptInt.@max <= %@))",
                    values: [5, 6], count: 1) {
            $0.mapOptInt.contains(5...6)
        }
        assertQuery(ModernAllTypesObject.self, "((mapOptInt.@min >= %@) && (mapOptInt.@max < %@))",
                    values: [5, 6], count: 0) {
            $0.mapOptInt.contains(5..<6)
        }
        assertQuery(ModernAllTypesObject.self, "((mapOptInt8.@min >= %@) && (mapOptInt8.@max <= %@))",
                    values: [Int8(8), Int8(9)], count: 1) {
            $0.mapOptInt8.contains(Int8(8)...Int8(9))
        }
        assertQuery(ModernAllTypesObject.self, "((mapOptInt8.@min >= %@) && (mapOptInt8.@max < %@))",
                    values: [Int8(8), Int8(9)], count: 0) {
            $0.mapOptInt8.contains(Int8(8)..<Int8(9))
        }
        assertQuery(ModernAllTypesObject.self, "((mapOptInt16.@min >= %@) && (mapOptInt16.@max <= %@))",
                    values: [Int16(16), Int16(17)], count: 1) {
            $0.mapOptInt16.contains(Int16(16)...Int16(17))
        }
        assertQuery(ModernAllTypesObject.self, "((mapOptInt16.@min >= %@) && (mapOptInt16.@max < %@))",
                    values: [Int16(16), Int16(17)], count: 0) {
            $0.mapOptInt16.contains(Int16(16)..<Int16(17))
        }
        assertQuery(ModernAllTypesObject.self, "((mapOptInt32.@min >= %@) && (mapOptInt32.@max <= %@))",
                    values: [Int32(32), Int32(33)], count: 1) {
            $0.mapOptInt32.contains(Int32(32)...Int32(33))
        }
        assertQuery(ModernAllTypesObject.self, "((mapOptInt32.@min >= %@) && (mapOptInt32.@max < %@))",
                    values: [Int32(32), Int32(33)], count: 0) {
            $0.mapOptInt32.contains(Int32(32)..<Int32(33))
        }
        assertQuery(ModernAllTypesObject.self, "((mapOptInt64.@min >= %@) && (mapOptInt64.@max <= %@))",
                    values: [Int64(64), Int64(65)], count: 1) {
            $0.mapOptInt64.contains(Int64(64)...Int64(65))
        }
        assertQuery(ModernAllTypesObject.self, "((mapOptInt64.@min >= %@) && (mapOptInt64.@max < %@))",
                    values: [Int64(64), Int64(65)], count: 0) {
            $0.mapOptInt64.contains(Int64(64)..<Int64(65))
        }
        assertQuery(ModernAllTypesObject.self, "((mapOptFloat.@min >= %@) && (mapOptFloat.@max <= %@))",
                    values: [Float(5.55444333), Float(6.55444333)], count: 1) {
            $0.mapOptFloat.contains(Float(5.55444333)...Float(6.55444333))
        }
        assertQuery(ModernAllTypesObject.self, "((mapOptFloat.@min >= %@) && (mapOptFloat.@max < %@))",
                    values: [Float(5.55444333), Float(6.55444333)], count: 0) {
            $0.mapOptFloat.contains(Float(5.55444333)..<Float(6.55444333))
        }
        assertQuery(ModernAllTypesObject.self, "((mapOptDouble.@min >= %@) && (mapOptDouble.@max <= %@))",
                    values: [123.456, 234.567], count: 1) {
            $0.mapOptDouble.contains(123.456...234.567)
        }
        assertQuery(ModernAllTypesObject.self, "((mapOptDouble.@min >= %@) && (mapOptDouble.@max < %@))",
                    values: [123.456, 234.567], count: 0) {
            $0.mapOptDouble.contains(123.456..<234.567)
        }
        assertQuery(ModernAllTypesObject.self, "((mapOptDate.@min >= %@) && (mapOptDate.@max <= %@))",
                    values: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)], count: 1) {
            $0.mapOptDate.contains(Date(timeIntervalSince1970: 1000000)...Date(timeIntervalSince1970: 2000000))
        }
        assertQuery(ModernAllTypesObject.self, "((mapOptDate.@min >= %@) && (mapOptDate.@max < %@))",
                    values: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)], count: 0) {
            $0.mapOptDate.contains(Date(timeIntervalSince1970: 1000000)..<Date(timeIntervalSince1970: 2000000))
        }
        assertQuery(ModernAllTypesObject.self, "((mapOptDecimal.@min >= %@) && (mapOptDecimal.@max <= %@))",
                    values: [Decimal128(123.456), Decimal128(234.567)], count: 1) {
            $0.mapOptDecimal.contains(Decimal128(123.456)...Decimal128(234.567))
        }
        assertQuery(ModernAllTypesObject.self, "((mapOptDecimal.@min >= %@) && (mapOptDecimal.@max < %@))",
                    values: [Decimal128(123.456), Decimal128(234.567)], count: 0) {
            $0.mapOptDecimal.contains(Decimal128(123.456)..<Decimal128(234.567))
        }
        assertQuery(ModernCollectionsOfEnums.self, "((mapIntOpt.@min >= %@) && (mapIntOpt.@max <= %@))",
                    values: [EnumInt.value1.rawValue, EnumInt.value2.rawValue], count: 1) {
            $0.mapIntOpt.rawValue.contains(EnumInt.value1.rawValue...EnumInt.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((mapIntOpt.@min >= %@) && (mapIntOpt.@max < %@))",
                    values: [EnumInt.value1.rawValue, EnumInt.value2.rawValue], count: 0) {
            $0.mapIntOpt.rawValue.contains(EnumInt.value1.rawValue..<EnumInt.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((mapInt8Opt.@min >= %@) && (mapInt8Opt.@max <= %@))",
                    values: [EnumInt8.value1.rawValue, EnumInt8.value2.rawValue], count: 1) {
            $0.mapInt8Opt.rawValue.contains(EnumInt8.value1.rawValue...EnumInt8.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((mapInt8Opt.@min >= %@) && (mapInt8Opt.@max < %@))",
                    values: [EnumInt8.value1.rawValue, EnumInt8.value2.rawValue], count: 0) {
            $0.mapInt8Opt.rawValue.contains(EnumInt8.value1.rawValue..<EnumInt8.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((mapInt16Opt.@min >= %@) && (mapInt16Opt.@max <= %@))",
                    values: [EnumInt16.value1.rawValue, EnumInt16.value2.rawValue], count: 1) {
            $0.mapInt16Opt.rawValue.contains(EnumInt16.value1.rawValue...EnumInt16.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((mapInt16Opt.@min >= %@) && (mapInt16Opt.@max < %@))",
                    values: [EnumInt16.value1.rawValue, EnumInt16.value2.rawValue], count: 0) {
            $0.mapInt16Opt.rawValue.contains(EnumInt16.value1.rawValue..<EnumInt16.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((mapInt32Opt.@min >= %@) && (mapInt32Opt.@max <= %@))",
                    values: [EnumInt32.value1.rawValue, EnumInt32.value2.rawValue], count: 1) {
            $0.mapInt32Opt.rawValue.contains(EnumInt32.value1.rawValue...EnumInt32.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((mapInt32Opt.@min >= %@) && (mapInt32Opt.@max < %@))",
                    values: [EnumInt32.value1.rawValue, EnumInt32.value2.rawValue], count: 0) {
            $0.mapInt32Opt.rawValue.contains(EnumInt32.value1.rawValue..<EnumInt32.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((mapInt64Opt.@min >= %@) && (mapInt64Opt.@max <= %@))",
                    values: [EnumInt64.value1.rawValue, EnumInt64.value2.rawValue], count: 1) {
            $0.mapInt64Opt.rawValue.contains(EnumInt64.value1.rawValue...EnumInt64.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((mapInt64Opt.@min >= %@) && (mapInt64Opt.@max < %@))",
                    values: [EnumInt64.value1.rawValue, EnumInt64.value2.rawValue], count: 0) {
            $0.mapInt64Opt.rawValue.contains(EnumInt64.value1.rawValue..<EnumInt64.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((mapFloatOpt.@min >= %@) && (mapFloatOpt.@max <= %@))",
                    values: [EnumFloat.value1.rawValue, EnumFloat.value2.rawValue], count: 1) {
            $0.mapFloatOpt.rawValue.contains(EnumFloat.value1.rawValue...EnumFloat.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((mapFloatOpt.@min >= %@) && (mapFloatOpt.@max < %@))",
                    values: [EnumFloat.value1.rawValue, EnumFloat.value2.rawValue], count: 0) {
            $0.mapFloatOpt.rawValue.contains(EnumFloat.value1.rawValue..<EnumFloat.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((mapDoubleOpt.@min >= %@) && (mapDoubleOpt.@max <= %@))",
                    values: [EnumDouble.value1.rawValue, EnumDouble.value2.rawValue], count: 1) {
            $0.mapDoubleOpt.rawValue.contains(EnumDouble.value1.rawValue...EnumDouble.value2.rawValue)
        }
        assertQuery(ModernCollectionsOfEnums.self, "((mapDoubleOpt.@min >= %@) && (mapDoubleOpt.@max < %@))",
                    values: [EnumDouble.value1.rawValue, EnumDouble.value2.rawValue], count: 0) {
            $0.mapDoubleOpt.rawValue.contains(EnumDouble.value1.rawValue..<EnumDouble.value2.rawValue)
        }
    }

    func testMapContainsObject() {
        let obj = objects().first!
        let colObj = collectionObject()
        let result1 = realm.objects(ModernCollectionObject.self).where {
            $0.map.contains(obj)
        }
        XCTAssertEqual(result1.count, 0)
        try! realm.write {
            colObj.map["foo"] = obj
        }
        let result2 = realm.objects(ModernCollectionObject.self).where {
            $0.map.contains(obj)
        }
        XCTAssertEqual(result2.count, 1)
    }

    private func validateMapSubscriptEquality<Root: Object, T: RealmKeyedCollection>(_ name: String, _ lhs: (Query<Root>) -> Query<T>, value: T.Value)
            where T.Key == String {
        assertQuery(Root.self, "(\(name)[%@] == %@)", values: ["foo", value], count: 1) {
            lhs($0)["foo"] == value
        }
        assertQuery(Root.self, "(\(name)[%@] != %@)", values: ["foo", value], count: 0) {
            lhs($0)["foo"] != value
        }
    }

    private func validateMapSubscriptNumericComparisons<Root: Object, T: RealmKeyedCollection>(_ name: String, _ lhs: (Query<Root>) -> Query<T>, value: T.Value)
            where T.Value: _Persistable, T.Value.PersistedType: _QueryNumeric, T.Key == String {
        assertQuery(Root.self, "(\(name)[%@] > %@)", values: ["foo", value], count: 0) {
            lhs($0)["foo"] > value
        }
        assertQuery(Root.self, "(\(name)[%@] >= %@)", values: ["foo", value], count: 1) {
            lhs($0)["foo"] >= value
        }
        assertQuery(Root.self, "(\(name)[%@] < %@)", values: ["foo", value], count: 0) {
            lhs($0)["foo"] < value
        }
        assertQuery(Root.self, "(\(name)[%@] <= %@)", values: ["foo", value], count: 1) {
            lhs($0)["foo"] <= value
        }
    }

    private func validateMapSubscriptStringComparisons<Root: Object, T: RealmKeyedCollection>(_ name: String, _ lhs: (Query<Root>) -> Query<T>, value: T.Value)
            where T.Value: _Persistable, T.Value.PersistedType: _QueryString, T.Key == String {
        assertQuery(Root.self, "(\(name)[%@] CONTAINS[cd] %@)", values: ["foo", value], count: 1) {
            lhs($0)["foo"].contains(value, options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(Root.self, "(\(name)[%@] CONTAINS %@)", values: ["foo", value], count: 1) {
            lhs($0)["foo"].contains(value)
        }

        assertQuery(Root.self, "(NOT \(name)[%@] CONTAINS %@)", values: ["foo", value], count: 0) {
            !lhs($0)["foo"].contains(value)
        }

        assertQuery(Root.self, "(\(name)[%@] BEGINSWITH[cd] %@)", values: ["foo", value], count: 1) {
            lhs($0)["foo"].starts(with: value, options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(Root.self, "(\(name)[%@] BEGINSWITH %@)", values: ["foo", value], count: 1) {
            lhs($0)["foo"].starts(with: value)
        }

        assertQuery(Root.self, "(\(name)[%@] ENDSWITH[cd] %@)", values: ["foo", value], count: 1) {
            lhs($0)["foo"].ends(with: value, options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(Root.self, "(\(name)[%@] ENDSWITH %@)", values: ["foo", value], count: 1) {
            lhs($0)["foo"].ends(with: value)
        }

        assertQuery(Root.self, "(\(name)[%@] LIKE[c] %@)", values: ["foo", value], count: 1) {
            lhs($0)["foo"].like(value, caseInsensitive: true)
        }

        assertQuery(Root.self, "(\(name)[%@] LIKE %@)", values: ["foo", value], count: 1) {
            lhs($0)["foo"].like(value)
        }
    }

    func testMapAllKeysAllValuesSubscript() {
        validateMapSubscriptEquality("mapBool", \Query<ModernAllTypesObject>.mapBool, value: true)

        validateMapSubscriptEquality("mapInt", \Query<ModernAllTypesObject>.mapInt, value: 5)
        validateMapSubscriptNumericComparisons("mapInt", \Query<ModernAllTypesObject>.mapInt, value: 5)

        validateMapSubscriptEquality("mapInt8", \Query<ModernAllTypesObject>.mapInt8, value: Int8(8))
        validateMapSubscriptNumericComparisons("mapInt8", \Query<ModernAllTypesObject>.mapInt8, value: Int8(8))

        validateMapSubscriptEquality("mapInt16", \Query<ModernAllTypesObject>.mapInt16, value: Int16(16))
        validateMapSubscriptNumericComparisons("mapInt16", \Query<ModernAllTypesObject>.mapInt16, value: Int16(16))

        validateMapSubscriptEquality("mapInt32", \Query<ModernAllTypesObject>.mapInt32, value: Int32(32))
        validateMapSubscriptNumericComparisons("mapInt32", \Query<ModernAllTypesObject>.mapInt32, value: Int32(32))

        validateMapSubscriptEquality("mapInt64", \Query<ModernAllTypesObject>.mapInt64, value: Int64(64))
        validateMapSubscriptNumericComparisons("mapInt64", \Query<ModernAllTypesObject>.mapInt64, value: Int64(64))

        validateMapSubscriptEquality("mapFloat", \Query<ModernAllTypesObject>.mapFloat, value: Float(5.55444333))
        validateMapSubscriptNumericComparisons("mapFloat", \Query<ModernAllTypesObject>.mapFloat, value: Float(5.55444333))

        validateMapSubscriptEquality("mapDouble", \Query<ModernAllTypesObject>.mapDouble, value: 123.456)
        validateMapSubscriptNumericComparisons("mapDouble", \Query<ModernAllTypesObject>.mapDouble, value: 123.456)

        validateMapSubscriptEquality("mapString", \Query<ModernAllTypesObject>.mapString, value: "Foo")
        validateMapSubscriptStringComparisons("mapString", \Query<ModernAllTypesObject>.mapString, value: "Foo")

        validateMapSubscriptEquality("mapBinary", \Query<ModernAllTypesObject>.mapBinary, value: Data(count: 64))

        validateMapSubscriptEquality("mapDate", \Query<ModernAllTypesObject>.mapDate, value: Date(timeIntervalSince1970: 1000000))
        validateMapSubscriptNumericComparisons("mapDate", \Query<ModernAllTypesObject>.mapDate, value: Date(timeIntervalSince1970: 1000000))

        validateMapSubscriptEquality("mapDecimal", \Query<ModernAllTypesObject>.mapDecimal, value: Decimal128(123.456))
        validateMapSubscriptNumericComparisons("mapDecimal", \Query<ModernAllTypesObject>.mapDecimal, value: Decimal128(123.456))

        validateMapSubscriptEquality("mapObjectId", \Query<ModernAllTypesObject>.mapObjectId, value: ObjectId("61184062c1d8f096a3695046"))

        validateMapSubscriptEquality("mapUuid", \Query<ModernAllTypesObject>.mapUuid, value: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!)

        validateMapSubscriptEquality("mapAny", \Query<ModernAllTypesObject>.mapAny, value: AnyRealmValue.objectId(ObjectId("61184062c1d8f096a3695046")))

        validateMapSubscriptEquality("mapInt", \Query<ModernCollectionsOfEnums>.mapInt, value: .value1)
        validateMapSubscriptNumericComparisons("mapInt", \Query<ModernCollectionsOfEnums>.mapInt, value: .value1)

        validateMapSubscriptEquality("mapInt8", \Query<ModernCollectionsOfEnums>.mapInt8, value: .value1)
        validateMapSubscriptNumericComparisons("mapInt8", \Query<ModernCollectionsOfEnums>.mapInt8, value: .value1)

        validateMapSubscriptEquality("mapInt16", \Query<ModernCollectionsOfEnums>.mapInt16, value: .value1)
        validateMapSubscriptNumericComparisons("mapInt16", \Query<ModernCollectionsOfEnums>.mapInt16, value: .value1)

        validateMapSubscriptEquality("mapInt32", \Query<ModernCollectionsOfEnums>.mapInt32, value: .value1)
        validateMapSubscriptNumericComparisons("mapInt32", \Query<ModernCollectionsOfEnums>.mapInt32, value: .value1)

        validateMapSubscriptEquality("mapInt64", \Query<ModernCollectionsOfEnums>.mapInt64, value: .value1)
        validateMapSubscriptNumericComparisons("mapInt64", \Query<ModernCollectionsOfEnums>.mapInt64, value: .value1)

        validateMapSubscriptEquality("mapFloat", \Query<ModernCollectionsOfEnums>.mapFloat, value: .value1)
        validateMapSubscriptNumericComparisons("mapFloat", \Query<ModernCollectionsOfEnums>.mapFloat, value: .value1)

        validateMapSubscriptEquality("mapDouble", \Query<ModernCollectionsOfEnums>.mapDouble, value: .value1)
        validateMapSubscriptNumericComparisons("mapDouble", \Query<ModernCollectionsOfEnums>.mapDouble, value: .value1)

        validateMapSubscriptEquality("mapString", \Query<ModernCollectionsOfEnums>.mapString, value: .value1)
        validateMapSubscriptStringComparisons("mapString", \Query<ModernCollectionsOfEnums>.mapString, value: .value1)

        validateMapSubscriptEquality("mapOptBool", \Query<ModernAllTypesObject>.mapOptBool, value: true)

        validateMapSubscriptEquality("mapOptInt", \Query<ModernAllTypesObject>.mapOptInt, value: 5)
        validateMapSubscriptNumericComparisons("mapOptInt", \Query<ModernAllTypesObject>.mapOptInt, value: 5)

        validateMapSubscriptEquality("mapOptInt8", \Query<ModernAllTypesObject>.mapOptInt8, value: Int8(8))
        validateMapSubscriptNumericComparisons("mapOptInt8", \Query<ModernAllTypesObject>.mapOptInt8, value: Int8(8))

        validateMapSubscriptEquality("mapOptInt16", \Query<ModernAllTypesObject>.mapOptInt16, value: Int16(16))
        validateMapSubscriptNumericComparisons("mapOptInt16", \Query<ModernAllTypesObject>.mapOptInt16, value: Int16(16))

        validateMapSubscriptEquality("mapOptInt32", \Query<ModernAllTypesObject>.mapOptInt32, value: Int32(32))
        validateMapSubscriptNumericComparisons("mapOptInt32", \Query<ModernAllTypesObject>.mapOptInt32, value: Int32(32))

        validateMapSubscriptEquality("mapOptInt64", \Query<ModernAllTypesObject>.mapOptInt64, value: Int64(64))
        validateMapSubscriptNumericComparisons("mapOptInt64", \Query<ModernAllTypesObject>.mapOptInt64, value: Int64(64))

        validateMapSubscriptEquality("mapOptFloat", \Query<ModernAllTypesObject>.mapOptFloat, value: Float(5.55444333))
        validateMapSubscriptNumericComparisons("mapOptFloat", \Query<ModernAllTypesObject>.mapOptFloat, value: Float(5.55444333))

        validateMapSubscriptEquality("mapOptDouble", \Query<ModernAllTypesObject>.mapOptDouble, value: 123.456)
        validateMapSubscriptNumericComparisons("mapOptDouble", \Query<ModernAllTypesObject>.mapOptDouble, value: 123.456)

        validateMapSubscriptEquality("mapOptString", \Query<ModernAllTypesObject>.mapOptString, value: "Foo")
        validateMapSubscriptStringComparisons("mapOptString", \Query<ModernAllTypesObject>.mapOptString, value: "Foo")

        validateMapSubscriptEquality("mapOptBinary", \Query<ModernAllTypesObject>.mapOptBinary, value: Data(count: 64))

        validateMapSubscriptEquality("mapOptDate", \Query<ModernAllTypesObject>.mapOptDate, value: Date(timeIntervalSince1970: 1000000))
        validateMapSubscriptNumericComparisons("mapOptDate", \Query<ModernAllTypesObject>.mapOptDate, value: Date(timeIntervalSince1970: 1000000))

        validateMapSubscriptEquality("mapOptDecimal", \Query<ModernAllTypesObject>.mapOptDecimal, value: Decimal128(123.456))
        validateMapSubscriptNumericComparisons("mapOptDecimal", \Query<ModernAllTypesObject>.mapOptDecimal, value: Decimal128(123.456))

        validateMapSubscriptEquality("mapOptObjectId", \Query<ModernAllTypesObject>.mapOptObjectId, value: ObjectId("61184062c1d8f096a3695046"))

        validateMapSubscriptEquality("mapOptUuid", \Query<ModernAllTypesObject>.mapOptUuid, value: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!)

        validateMapSubscriptEquality("mapIntOpt", \Query<ModernCollectionsOfEnums>.mapIntOpt, value: .value1)
        validateMapSubscriptNumericComparisons("mapIntOpt", \Query<ModernCollectionsOfEnums>.mapIntOpt, value: .value1)

        validateMapSubscriptEquality("mapInt8Opt", \Query<ModernCollectionsOfEnums>.mapInt8Opt, value: .value1)
        validateMapSubscriptNumericComparisons("mapInt8Opt", \Query<ModernCollectionsOfEnums>.mapInt8Opt, value: .value1)

        validateMapSubscriptEquality("mapInt16Opt", \Query<ModernCollectionsOfEnums>.mapInt16Opt, value: .value1)
        validateMapSubscriptNumericComparisons("mapInt16Opt", \Query<ModernCollectionsOfEnums>.mapInt16Opt, value: .value1)

        validateMapSubscriptEquality("mapInt32Opt", \Query<ModernCollectionsOfEnums>.mapInt32Opt, value: .value1)
        validateMapSubscriptNumericComparisons("mapInt32Opt", \Query<ModernCollectionsOfEnums>.mapInt32Opt, value: .value1)

        validateMapSubscriptEquality("mapInt64Opt", \Query<ModernCollectionsOfEnums>.mapInt64Opt, value: .value1)
        validateMapSubscriptNumericComparisons("mapInt64Opt", \Query<ModernCollectionsOfEnums>.mapInt64Opt, value: .value1)

        validateMapSubscriptEquality("mapFloatOpt", \Query<ModernCollectionsOfEnums>.mapFloatOpt, value: .value1)
        validateMapSubscriptNumericComparisons("mapFloatOpt", \Query<ModernCollectionsOfEnums>.mapFloatOpt, value: .value1)

        validateMapSubscriptEquality("mapDoubleOpt", \Query<ModernCollectionsOfEnums>.mapDoubleOpt, value: .value1)
        validateMapSubscriptNumericComparisons("mapDoubleOpt", \Query<ModernCollectionsOfEnums>.mapDoubleOpt, value: .value1)

        validateMapSubscriptEquality("mapStringOpt", \Query<ModernCollectionsOfEnums>.mapStringOpt, value: .value1)
        validateMapSubscriptStringComparisons("mapStringOpt", \Query<ModernCollectionsOfEnums>.mapStringOpt, value: .value1)

    }

    func testMapSubscriptObject() {
        assertThrows(assertQuery(ModernCollectionObject.self, "", count: 0) {
            $0.map["foo"].objectCol.intCol == 5
        }, reason: "Cannot apply key path to Map subscripts.")
    }

    func testMapContainsAnyInObject() {
        assertQuery(ModernAllTypesObject.self, "(ANY mapBool IN %@)",
                    values: [NSArray(array: [true, true])], count: 1) {
            $0.mapBool.containsAny(in: [true, true])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY mapInt IN %@)",
                    values: [NSArray(array: [5, 6])], count: 1) {
            $0.mapInt.containsAny(in: [5, 6])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY mapInt8 IN %@)",
                    values: [NSArray(array: [Int8(8), Int8(9)])], count: 1) {
            $0.mapInt8.containsAny(in: [Int8(8), Int8(9)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY mapInt16 IN %@)",
                    values: [NSArray(array: [Int16(16), Int16(17)])], count: 1) {
            $0.mapInt16.containsAny(in: [Int16(16), Int16(17)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY mapInt32 IN %@)",
                    values: [NSArray(array: [Int32(32), Int32(33)])], count: 1) {
            $0.mapInt32.containsAny(in: [Int32(32), Int32(33)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY mapInt64 IN %@)",
                    values: [NSArray(array: [Int64(64), Int64(65)])], count: 1) {
            $0.mapInt64.containsAny(in: [Int64(64), Int64(65)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY mapFloat IN %@)",
                    values: [NSArray(array: [Float(5.55444333), Float(6.55444333)])], count: 1) {
            $0.mapFloat.containsAny(in: [Float(5.55444333), Float(6.55444333)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY mapDouble IN %@)",
                    values: [NSArray(array: [123.456, 234.567])], count: 1) {
            $0.mapDouble.containsAny(in: [123.456, 234.567])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY mapString IN %@)",
                    values: [NSArray(array: ["Foo", "Foó"])], count: 1) {
            $0.mapString.containsAny(in: ["Foo", "Foó"])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY mapBinary IN %@)",
                    values: [NSArray(array: [Data(count: 64), Data(count: 128)])], count: 1) {
            $0.mapBinary.containsAny(in: [Data(count: 64), Data(count: 128)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY mapDate IN %@)",
                    values: [NSArray(array: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)])], count: 1) {
            $0.mapDate.containsAny(in: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY mapDecimal IN %@)",
                    values: [NSArray(array: [Decimal128(123.456), Decimal128(234.567)])], count: 1) {
            $0.mapDecimal.containsAny(in: [Decimal128(123.456), Decimal128(234.567)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY mapObjectId IN %@)",
                    values: [NSArray(array: [ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045")])], count: 1) {
            $0.mapObjectId.containsAny(in: [ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045")])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY mapUuid IN %@)",
                    values: [NSArray(array: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])], count: 1) {
            $0.mapUuid.containsAny(in: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY mapAny IN %@)",
                    values: [NSArray(array: [AnyRealmValue.objectId(ObjectId("61184062c1d8f096a3695046")), AnyRealmValue.string("Hello")])], count: 1) {
            $0.mapAny.containsAny(in: [AnyRealmValue.objectId(ObjectId("61184062c1d8f096a3695046")), AnyRealmValue.string("Hello")])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY mapInt IN %@)",
                    values: [NSArray(array: [EnumInt.value1, EnumInt.value2])], count: 1) {
            $0.mapInt.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY mapInt8 IN %@)",
                    values: [NSArray(array: [EnumInt8.value1, EnumInt8.value2])], count: 1) {
            $0.mapInt8.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY mapInt16 IN %@)",
                    values: [NSArray(array: [EnumInt16.value1, EnumInt16.value2])], count: 1) {
            $0.mapInt16.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY mapInt32 IN %@)",
                    values: [NSArray(array: [EnumInt32.value1, EnumInt32.value2])], count: 1) {
            $0.mapInt32.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY mapInt64 IN %@)",
                    values: [NSArray(array: [EnumInt64.value1, EnumInt64.value2])], count: 1) {
            $0.mapInt64.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY mapFloat IN %@)",
                    values: [NSArray(array: [EnumFloat.value1, EnumFloat.value2])], count: 1) {
            $0.mapFloat.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY mapDouble IN %@)",
                    values: [NSArray(array: [EnumDouble.value1, EnumDouble.value2])], count: 1) {
            $0.mapDouble.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY mapString IN %@)",
                    values: [NSArray(array: [EnumString.value1, EnumString.value2])], count: 1) {
            $0.mapString.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY mapOptBool IN %@)",
                    values: [NSArray(array: [true, true])], count: 1) {
            $0.mapOptBool.containsAny(in: [true, true])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY mapOptInt IN %@)",
                    values: [NSArray(array: [5, 6])], count: 1) {
            $0.mapOptInt.containsAny(in: [5, 6])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY mapOptInt8 IN %@)",
                    values: [NSArray(array: [Int8(8), Int8(9)])], count: 1) {
            $0.mapOptInt8.containsAny(in: [Int8(8), Int8(9)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY mapOptInt16 IN %@)",
                    values: [NSArray(array: [Int16(16), Int16(17)])], count: 1) {
            $0.mapOptInt16.containsAny(in: [Int16(16), Int16(17)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY mapOptInt32 IN %@)",
                    values: [NSArray(array: [Int32(32), Int32(33)])], count: 1) {
            $0.mapOptInt32.containsAny(in: [Int32(32), Int32(33)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY mapOptInt64 IN %@)",
                    values: [NSArray(array: [Int64(64), Int64(65)])], count: 1) {
            $0.mapOptInt64.containsAny(in: [Int64(64), Int64(65)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY mapOptFloat IN %@)",
                    values: [NSArray(array: [Float(5.55444333), Float(6.55444333)])], count: 1) {
            $0.mapOptFloat.containsAny(in: [Float(5.55444333), Float(6.55444333)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY mapOptDouble IN %@)",
                    values: [NSArray(array: [123.456, 234.567])], count: 1) {
            $0.mapOptDouble.containsAny(in: [123.456, 234.567])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY mapOptString IN %@)",
                    values: [NSArray(array: ["Foo", "Foó"])], count: 1) {
            $0.mapOptString.containsAny(in: ["Foo", "Foó"])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY mapOptBinary IN %@)",
                    values: [NSArray(array: [Data(count: 64), Data(count: 128)])], count: 1) {
            $0.mapOptBinary.containsAny(in: [Data(count: 64), Data(count: 128)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY mapOptDate IN %@)",
                    values: [NSArray(array: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)])], count: 1) {
            $0.mapOptDate.containsAny(in: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY mapOptDecimal IN %@)",
                    values: [NSArray(array: [Decimal128(123.456), Decimal128(234.567)])], count: 1) {
            $0.mapOptDecimal.containsAny(in: [Decimal128(123.456), Decimal128(234.567)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY mapOptObjectId IN %@)",
                    values: [NSArray(array: [ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045")])], count: 1) {
            $0.mapOptObjectId.containsAny(in: [ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045")])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY mapOptUuid IN %@)",
                    values: [NSArray(array: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])], count: 1) {
            $0.mapOptUuid.containsAny(in: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY mapIntOpt IN %@)",
                    values: [NSArray(array: [EnumInt.value1, EnumInt.value2])], count: 1) {
            $0.mapIntOpt.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY mapInt8Opt IN %@)",
                    values: [NSArray(array: [EnumInt8.value1, EnumInt8.value2])], count: 1) {
            $0.mapInt8Opt.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY mapInt16Opt IN %@)",
                    values: [NSArray(array: [EnumInt16.value1, EnumInt16.value2])], count: 1) {
            $0.mapInt16Opt.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY mapInt32Opt IN %@)",
                    values: [NSArray(array: [EnumInt32.value1, EnumInt32.value2])], count: 1) {
            $0.mapInt32Opt.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY mapInt64Opt IN %@)",
                    values: [NSArray(array: [EnumInt64.value1, EnumInt64.value2])], count: 1) {
            $0.mapInt64Opt.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY mapFloatOpt IN %@)",
                    values: [NSArray(array: [EnumFloat.value1, EnumFloat.value2])], count: 1) {
            $0.mapFloatOpt.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY mapDoubleOpt IN %@)",
                    values: [NSArray(array: [EnumDouble.value1, EnumDouble.value2])], count: 1) {
            $0.mapDoubleOpt.containsAny(in: [.value1, .value2])
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY mapStringOpt IN %@)",
                    values: [NSArray(array: [EnumString.value1, EnumString.value2])], count: 1) {
            $0.mapStringOpt.containsAny(in: [.value1, .value2])
        }

        let colObj = ModernCollectionObject()
        let obj = objects().first!
        colObj.map["foo"] = obj
        try! realm.write {
            realm.add(colObj)
        }

        assertQuery(ModernCollectionObject.self, "(ANY map IN %@)", values: [NSArray(array: [obj])], count: 1) {
            $0.map.containsAny(in: [obj])
        }
    }

    func testMapFromProperty() {
        let colObj = ModernCollectionObject()
        let obj = objects().first!
        colObj.map["foo"] = obj
        try! realm.write {
            realm.add(colObj)
        }

        assertMapQuery(predicate: "(boolCol == %@)",
                       values: [false],
                       count: 1) {
            $0.boolCol == false
        }
        assertMapQuery(predicate: "(intCol == %@)",
                       values: [6],
                       count: 1) {
            $0.intCol == 6
        }
        assertMapQuery(predicate: "(int8Col == %@)",
                       values: [Int8(9)],
                       count: 1) {
            $0.int8Col == Int8(9)
        }
        assertMapQuery(predicate: "(int16Col == %@)",
                       values: [Int16(17)],
                       count: 1) {
            $0.int16Col == Int16(17)
        }
        assertMapQuery(predicate: "(int32Col == %@)",
                       values: [Int32(33)],
                       count: 1) {
            $0.int32Col == Int32(33)
        }
        assertMapQuery(predicate: "(int64Col == %@)",
                       values: [Int64(65)],
                       count: 1) {
            $0.int64Col == Int64(65)
        }
        assertMapQuery(predicate: "(floatCol == %@)",
                       values: [Float(6.55444333)],
                       count: 1) {
            $0.floatCol == Float(6.55444333)
        }
        assertMapQuery(predicate: "(doubleCol == %@)",
                       values: [234.567],
                       count: 1) {
            $0.doubleCol == 234.567
        }
        assertMapQuery(predicate: "(stringCol == %@)",
                       values: ["Foó"],
                       count: 1) {
            $0.stringCol == "Foó"
        }
        assertMapQuery(predicate: "(binaryCol == %@)",
                       values: [Data(count: 128)],
                       count: 1) {
            $0.binaryCol == Data(count: 128)
        }
        assertMapQuery(predicate: "(dateCol == %@)",
                       values: [Date(timeIntervalSince1970: 2000000)],
                       count: 1) {
            $0.dateCol == Date(timeIntervalSince1970: 2000000)
        }
        assertMapQuery(predicate: "(decimalCol == %@)",
                       values: [Decimal128(234.567)],
                       count: 1) {
            $0.decimalCol == Decimal128(234.567)
        }
        assertMapQuery(predicate: "(objectIdCol == %@)",
                       values: [ObjectId("61184062c1d8f096a3695045")],
                       count: 1) {
            $0.objectIdCol == ObjectId("61184062c1d8f096a3695045")
        }
        assertMapQuery(predicate: "(uuidCol == %@)",
                       values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!],
                       count: 1) {
            $0.uuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!
        }
        assertMapQuery(predicate: "(intEnumCol == %@)",
                       values: [ModernIntEnum.value2],
                       count: 1) {
            $0.intEnumCol == .value2
        }
        assertMapQuery(predicate: "(stringEnumCol == %@)",
                       values: [ModernStringEnum.value2],
                       count: 1) {
            $0.stringEnumCol == .value2
        }
        assertMapQuery(predicate: "(optBoolCol == %@)",
                       values: [false],
                       count: 1) {
            $0.optBoolCol == false
        }
        assertMapQuery(predicate: "(optIntCol == %@)",
                       values: [6],
                       count: 1) {
            $0.optIntCol == 6
        }
        assertMapQuery(predicate: "(optInt8Col == %@)",
                       values: [Int8(9)],
                       count: 1) {
            $0.optInt8Col == Int8(9)
        }
        assertMapQuery(predicate: "(optInt16Col == %@)",
                       values: [Int16(17)],
                       count: 1) {
            $0.optInt16Col == Int16(17)
        }
        assertMapQuery(predicate: "(optInt32Col == %@)",
                       values: [Int32(33)],
                       count: 1) {
            $0.optInt32Col == Int32(33)
        }
        assertMapQuery(predicate: "(optInt64Col == %@)",
                       values: [Int64(65)],
                       count: 1) {
            $0.optInt64Col == Int64(65)
        }
        assertMapQuery(predicate: "(optFloatCol == %@)",
                       values: [Float(6.55444333)],
                       count: 1) {
            $0.optFloatCol == Float(6.55444333)
        }
        assertMapQuery(predicate: "(optDoubleCol == %@)",
                       values: [234.567],
                       count: 1) {
            $0.optDoubleCol == 234.567
        }
        assertMapQuery(predicate: "(optStringCol == %@)",
                       values: ["Foó"],
                       count: 1) {
            $0.optStringCol == "Foó"
        }
        assertMapQuery(predicate: "(optBinaryCol == %@)",
                       values: [Data(count: 128)],
                       count: 1) {
            $0.optBinaryCol == Data(count: 128)
        }
        assertMapQuery(predicate: "(optDateCol == %@)",
                       values: [Date(timeIntervalSince1970: 2000000)],
                       count: 1) {
            $0.optDateCol == Date(timeIntervalSince1970: 2000000)
        }
        assertMapQuery(predicate: "(optDecimalCol == %@)",
                       values: [Decimal128(234.567)],
                       count: 1) {
            $0.optDecimalCol == Decimal128(234.567)
        }
        assertMapQuery(predicate: "(optObjectIdCol == %@)",
                       values: [ObjectId("61184062c1d8f096a3695045")],
                       count: 1) {
            $0.optObjectIdCol == ObjectId("61184062c1d8f096a3695045")
        }
        assertMapQuery(predicate: "(optUuidCol == %@)",
                       values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!],
                       count: 1) {
            $0.optUuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!
        }
        assertMapQuery(predicate: "(optIntEnumCol == %@)",
                       values: [ModernIntEnum.value2],
                       count: 1) {
            $0.optIntEnumCol == .value2
        }
        assertMapQuery(predicate: "(optStringEnumCol == %@)",
                       values: [ModernStringEnum.value2],
                       count: 1) {
            $0.optStringEnumCol == .value2
        }
    }

    // MARK: - Linking Objects

    func testLinkingObjects() {
        let objects = Array(self.objects())
        assertQuery("(%@ IN linkingObjects)", objects.first!, count: 0) {
            $0.linkingObjects.contains(objects.first!)
        }

        assertQuery("(ANY linkingObjects IN %@)", objects, count: 0) {
            $0.linkingObjects.containsAny(in: objects)
        }

        assertQuery("(NOT %@ IN linkingObjects)", objects.first!, count: 1) {
            !$0.linkingObjects.contains(objects.first!)
        }

        assertQuery("(NOT ANY linkingObjects IN %@)", objects, count: 1) {
            !$0.linkingObjects.containsAny(in: objects)
        }
    }

    // MARK: - Compound

    func testCompoundAnd() {
        assertQuery("((boolCol == %@) && (optBoolCol == %@))", values: [false, false], count: 1) {
            $0.boolCol == false && $0.optBoolCol == false
        }
        assertQuery("((boolCol == %@) && (optBoolCol == %@))", values: [false, false], count: 1) {
            ($0.boolCol == false) && ($0.optBoolCol == false)
        }

        // List

        assertQuery("((boolCol == %@) && (%@ IN arrayBool))", values: [false, true], count: 1) {
            $0.boolCol == false && $0.arrayBool.contains(true)
        }
        assertQuery("((boolCol != %@) && (%@ IN arrayBool))", values: [true, true], count: 1) {
            $0.boolCol != true && $0.arrayBool.contains(true)
        }
        assertQuery("((boolCol == %@) && (%@ IN arrayOptBool))", values: [false, true], count: 1) {
            $0.boolCol == false && $0.arrayOptBool.contains(true)
        }
        assertQuery("((boolCol != %@) && (%@ IN arrayOptBool))", values: [true, true], count: 1) {
            $0.boolCol != true && $0.arrayOptBool.contains(true)
        }

        // Set

        assertQuery("((boolCol == %@) && (%@ IN setBool))", values: [false, true], count: 1) {
            $0.boolCol == false && $0.setBool.contains(true)
        }
        assertQuery("((boolCol != %@) && (%@ IN setBool))", values: [true, true], count: 1) {
            $0.boolCol != true && $0.setBool.contains(true)
        }
        assertQuery("((boolCol == %@) && (%@ IN setOptBool))", values: [false, true], count: 1) {
            $0.boolCol == false && $0.setOptBool.contains(true)
        }
        assertQuery("((boolCol != %@) && (%@ IN setOptBool))", values: [true, true], count: 1) {
            $0.boolCol != true && $0.setOptBool.contains(true)
        }

        // Map

        assertQuery("((boolCol == %@) && (%@ IN mapBool))", values: [false, true], count: 1) {
            $0.boolCol == false && $0.mapBool.contains(true)
        }
        assertQuery("((boolCol != %@) && (mapBool[%@] == %@))",
                    values: [true, "foo", true], count: 1) {
            ($0.boolCol != true) && ($0.mapBool["foo"] == true)
        }
        assertQuery("(((boolCol != %@) && (mapBool[%@] == %@)) && (mapBool[%@] == %@))",
                    values: [true, "foo", true, "bar", true], count: 1) {
            ($0.boolCol != true) &&
            ($0.mapBool["foo"] == true) &&
            ($0.mapBool["bar"] == true)
        }
        assertQuery("((boolCol == %@) && (%@ IN mapOptBool))", values: [false, true], count: 1) {
            $0.boolCol == false && $0.mapOptBool.contains(true)
        }
        assertQuery("((boolCol != %@) && (mapOptBool[%@] == %@))",
                    values: [true, "foo", true], count: 1) {
            ($0.boolCol != true) && ($0.mapOptBool["foo"] == true)
        }
        assertQuery("(((boolCol != %@) && (mapOptBool[%@] == %@)) && (mapOptBool[%@] == %@))",
                    values: [true, "foo", true, "bar", true], count: 1) {
            ($0.boolCol != true) &&
            ($0.mapOptBool["foo"] == true) &&
            ($0.mapOptBool["bar"] == true)
        }

        // Aggregates

        let sumarrayInt = 5 + 6
        assertQuery("((((((arrayInt.@min <= %@) && (arrayInt.@max >= %@)) && (arrayInt.@sum == %@)) && (arrayInt.@count != %@)) && (arrayInt.@avg > %@)) && (arrayInt.@avg < %@))",
                    values: [5, 6, sumarrayInt, 0, 5, 6], count: 1) {
            ($0.arrayInt.min <= 5) &&
            ($0.arrayInt.max >= 6) &&
            ($0.arrayInt.sum == sumarrayInt) &&
            ($0.arrayInt.count != 0) &&
            ($0.arrayInt.avg > 5) &&
            ($0.arrayInt.avg < 6)
        }
        let sumarrayOptInt = 5 + 6
        assertQuery("((((((arrayOptInt.@min <= %@) && (arrayOptInt.@max >= %@)) && (arrayOptInt.@sum == %@)) && (arrayOptInt.@count != %@)) && (arrayOptInt.@avg > %@)) && (arrayOptInt.@avg < %@))",
                    values: [5, 6, sumarrayOptInt, 0, 5, 6], count: 1) {
            ($0.arrayOptInt.min <= 5) &&
            ($0.arrayOptInt.max >= 6) &&
            ($0.arrayOptInt.sum == sumarrayOptInt) &&
            ($0.arrayOptInt.count != 0) &&
            ($0.arrayOptInt.avg > 5) &&
            ($0.arrayOptInt.avg < 6)
        }
        let summapInt = 5 + 6
        assertQuery("((((((mapInt.@min <= %@) && (mapInt.@max >= %@)) && (mapInt.@sum == %@)) && (mapInt.@count != %@)) && (mapInt.@avg > %@)) && (mapInt.@avg < %@))",
                    values: [5, 6, summapInt, 0, 5, 6], count: 1) {
            ($0.mapInt.min <= 5) &&
            ($0.mapInt.max >= 6) &&
            ($0.mapInt.sum == summapInt) &&
            ($0.mapInt.count != 0) &&
            ($0.mapInt.avg > 5) &&
            ($0.mapInt.avg < 6)
        }
        let summapOptInt = 5 + 6
        assertQuery("((((((mapOptInt.@min <= %@) && (mapOptInt.@max >= %@)) && (mapOptInt.@sum == %@)) && (mapOptInt.@count != %@)) && (mapOptInt.@avg > %@)) && (mapOptInt.@avg < %@))",
                    values: [5, 6, summapOptInt, 0, 5, 6], count: 1) {
            ($0.mapOptInt.min <= 5) &&
            ($0.mapOptInt.max >= 6) &&
            ($0.mapOptInt.sum == summapOptInt) &&
            ($0.mapOptInt.count != 0) &&
            ($0.mapOptInt.avg > 5) &&
            ($0.mapOptInt.avg < 6)
        }

        // Keypath Collection Aggregates

        let object = objects().first!
        createKeypathCollectionAggregatesObject(object)

        let sumdoubleCol = 123.456 + 234.567 + 345.678
        assertQuery("((((((arrayCol.@min.doubleCol <= %@) && (arrayCol.@max.doubleCol >= %@)) && (arrayCol.@sum.doubleCol == %@)) && (arrayCol.@min.doubleCol != %@)) && (arrayCol.@avg.doubleCol > %@)) && (arrayCol.@avg.doubleCol < %@))",
                    values: [123.456, 345.678, sumdoubleCol, 234.567, 123.456, 345.678], count: 1) {
            $0.arrayCol.doubleCol.min <= 123.456 &&
            $0.arrayCol.doubleCol.max >= 345.678 &&
            $0.arrayCol.doubleCol.sum == sumdoubleCol &&
            $0.arrayCol.doubleCol.min != 234.567 &&
            $0.arrayCol.doubleCol.avg > 123.456 &&
            $0.arrayCol.doubleCol.avg < 345.678
        }

        let sumoptDoubleCol = 123.456 + 234.567 + 345.678
        assertQuery("((((((arrayCol.@min.optDoubleCol <= %@) && (arrayCol.@max.optDoubleCol >= %@)) && (arrayCol.@sum.optDoubleCol == %@)) && (arrayCol.@min.optDoubleCol != %@)) && (arrayCol.@avg.optDoubleCol > %@)) && (arrayCol.@avg.optDoubleCol < %@))",
                    values: [123.456, 345.678, sumoptDoubleCol, 234.567, 123.456, 345.678], count: 1) {
            $0.arrayCol.optDoubleCol.min <= 123.456 &&
            $0.arrayCol.optDoubleCol.max >= 345.678 &&
            $0.arrayCol.optDoubleCol.sum == sumoptDoubleCol &&
            $0.arrayCol.optDoubleCol.min != 234.567 &&
            $0.arrayCol.optDoubleCol.avg > 123.456 &&
            $0.arrayCol.optDoubleCol.avg < 345.678
        }
    }

    func testCompoundOr() {
        assertQuery("((boolCol == %@) || (optBoolCol == %@))", values: [false, false], count: 1) {
            $0.boolCol == false || $0.optBoolCol == false
        }
        assertQuery("((boolCol == %@) || (optBoolCol == %@))", values: [false, false], count: 1) {
            ($0.boolCol == false) || ($0.optBoolCol == false)
        }

        // List

        assertQuery("((boolCol == %@) || (%@ IN arrayBool))", values: [false, true], count: 1) {
            $0.boolCol == false || $0.arrayBool.contains(true)
        }
        assertQuery("((boolCol != %@) || (%@ IN arrayBool))", values: [true, true], count: 1) {
            $0.boolCol != true || $0.arrayBool.contains(true)
        }
        assertQuery("((boolCol == %@) || (%@ IN arrayOptBool))", values: [false, true], count: 1) {
            $0.boolCol == false || $0.arrayOptBool.contains(true)
        }
        assertQuery("((boolCol != %@) || (%@ IN arrayOptBool))", values: [true, true], count: 1) {
            $0.boolCol != true || $0.arrayOptBool.contains(true)
        }

        // Set

        assertQuery("((boolCol == %@) || (%@ IN setBool))", values: [false, true], count: 1) {
            $0.boolCol == false || $0.setBool.contains(true)
        }
        assertQuery("((boolCol != %@) || (%@ IN setBool))", values: [true, true], count: 1) {
            $0.boolCol != true || $0.setBool.contains(true)
        }
        assertQuery("((boolCol == %@) || (%@ IN setOptBool))", values: [false, true], count: 1) {
            $0.boolCol == false || $0.setOptBool.contains(true)
        }
        assertQuery("((boolCol != %@) || (%@ IN setOptBool))", values: [true, true], count: 1) {
            $0.boolCol != true || $0.setOptBool.contains(true)
        }

        // Map

        assertQuery("((boolCol == %@) || (%@ IN mapBool))", values: [false, true], count: 1) {
            $0.boolCol == false || $0.mapBool.contains(true)
        }
        assertQuery("((boolCol != %@) || (mapBool[%@] == %@))",
                    values: [true, "foo", true], count: 1) {
            ($0.boolCol != true) || ($0.mapBool["foo"] == true)
        }
        assertQuery("(((boolCol != %@) || (mapBool[%@] == %@)) || (mapBool[%@] == %@))",
                    values: [true, "foo", true, "bar", true], count: 1) {
            ($0.boolCol != true) ||
            ($0.mapBool["foo"] == true) ||
            ($0.mapBool["bar"] == true)
        }
        assertQuery("((boolCol == %@) || (%@ IN mapOptBool))", values: [false, true], count: 1) {
            $0.boolCol == false || $0.mapOptBool.contains(true)
        }
        assertQuery("((boolCol != %@) || (mapOptBool[%@] == %@))",
                    values: [true, "foo", true], count: 1) {
            ($0.boolCol != true) || ($0.mapOptBool["foo"] == true)
        }
        assertQuery("(((boolCol != %@) || (mapOptBool[%@] == %@)) || (mapOptBool[%@] == %@))",
                    values: [true, "foo", true, "bar", true], count: 1) {
            ($0.boolCol != true) ||
            ($0.mapOptBool["foo"] == true) ||
            ($0.mapOptBool["bar"] == true)
        }
        assertQuery("((boolCol == %@) || (%@ IN mapInt))", values: [false, 6], count: 1) {
            $0.boolCol == false || $0.mapInt.contains(6)
        }
        assertQuery("((boolCol != %@) || (mapInt[%@] == %@))",
                    values: [true, "foo", 6], count: 1) {
            ($0.boolCol != true) || ($0.mapInt["foo"] == 6)
        }
        assertQuery("(((boolCol != %@) || (mapInt[%@] == %@)) || (mapInt[%@] == %@))",
                    values: [true, "foo", 5, "bar", 6], count: 1) {
            ($0.boolCol != true) ||
            ($0.mapInt["foo"] == 5) ||
            ($0.mapInt["bar"] == 6)
        }
        assertQuery("((boolCol == %@) || (%@ IN mapOptInt))", values: [false, 6], count: 1) {
            $0.boolCol == false || $0.mapOptInt.contains(6)
        }
        assertQuery("((boolCol != %@) || (mapOptInt[%@] == %@))",
                    values: [true, "foo", 6], count: 1) {
            ($0.boolCol != true) || ($0.mapOptInt["foo"] == 6)
        }
        assertQuery("(((boolCol != %@) || (mapOptInt[%@] == %@)) || (mapOptInt[%@] == %@))",
                    values: [true, "foo", 5, "bar", 6], count: 1) {
            ($0.boolCol != true) ||
            ($0.mapOptInt["foo"] == 5) ||
            ($0.mapOptInt["bar"] == 6)
        }

        // Aggregates

        let sumarrayInt = 5 + 6
        assertQuery("((((((arrayInt.@min <= %@) || (arrayInt.@max >= %@)) || (arrayInt.@sum != %@)) || (arrayInt.@count == %@)) || (arrayInt.@avg > %@)) || (arrayInt.@avg < %@))",
                    values: [5, 7, sumarrayInt, 0, 6, 5], count: 1) {
            ($0.arrayInt.min <= 5) ||
            ($0.arrayInt.max >= 7) ||
            ($0.arrayInt.sum != sumarrayInt) ||
            ($0.arrayInt.count == 0) ||
            ($0.arrayInt.avg > 6) ||
            ($0.arrayInt.avg < 5)
        }
        let sumarrayOptInt = 5 + 6
        assertQuery("((((((arrayOptInt.@min <= %@) || (arrayOptInt.@max >= %@)) || (arrayOptInt.@sum != %@)) || (arrayOptInt.@count == %@)) || (arrayOptInt.@avg > %@)) || (arrayOptInt.@avg < %@))",
                    values: [5, 7, sumarrayOptInt, 0, 6, 5], count: 1) {
            ($0.arrayOptInt.min <= 5) ||
            ($0.arrayOptInt.max >= 7) ||
            ($0.arrayOptInt.sum != sumarrayOptInt) ||
            ($0.arrayOptInt.count == 0) ||
            ($0.arrayOptInt.avg > 6) ||
            ($0.arrayOptInt.avg < 5)
        }

        // Keypath Collection Aggregates

        let object = objects().first!
        createKeypathCollectionAggregatesObject(object)

        let sumdoubleCol = 123.456 + 234.567 + 345.678
        assertQuery("((((((arrayCol.@min.doubleCol < %@) || (arrayCol.@max.doubleCol > %@)) || (arrayCol.@sum.doubleCol != %@)) || (arrayCol.@min.doubleCol == %@)) || (arrayCol.@avg.doubleCol >= %@)) || (arrayCol.@avg.doubleCol <= %@))", values: [123.456, 345.678, sumdoubleCol, 0, 345.678, 123.456], count: 3) {
            $0.arrayCol.doubleCol.min < 123.456 ||
            $0.arrayCol.doubleCol.max > 345.678 ||
            $0.arrayCol.doubleCol.sum != sumdoubleCol ||
            $0.arrayCol.doubleCol.min == 0 ||
            $0.arrayCol.doubleCol.avg >= 345.678 ||
            $0.arrayCol.doubleCol.avg <= 123.456
        }

        let sumoptDoubleCol = 123.456 + 234.567 + 345.678
        assertQuery("((((((arrayCol.@min.optDoubleCol < %@) || (arrayCol.@max.optDoubleCol > %@)) || (arrayCol.@sum.optDoubleCol != %@)) || (arrayCol.@min.optDoubleCol == %@)) || (arrayCol.@avg.optDoubleCol >= %@)) || (arrayCol.@avg.optDoubleCol <= %@))", values: [123.456, 345.678, sumoptDoubleCol, 0, 345.678, 123.456], count: 3) {
            $0.arrayCol.optDoubleCol.min < 123.456 ||
            $0.arrayCol.optDoubleCol.max > 345.678 ||
            $0.arrayCol.optDoubleCol.sum != sumoptDoubleCol ||
            $0.arrayCol.optDoubleCol.min == 0 ||
            $0.arrayCol.optDoubleCol.avg >= 345.678 ||
            $0.arrayCol.optDoubleCol.avg <= 123.456
        }
    }

    func testCompoundMixed() {
        assertQuery("(((boolCol == %@) || (intCol == %@)) && ((boolCol != %@) || (intCol != %@)))",
                    values: [false, 6, false, 6], count: 0) {
            ($0.boolCol == false || $0.intCol == 6) &&
            ($0.boolCol != false || $0.intCol != 6)
        }
        assertQuery("((boolCol == %@) || (intCol == %@))", values: [false, 6], count: 1) {
            ($0.boolCol == false) || ($0.intCol == 6)
        }
        assertQuery("(((intCol == %@) || (int8Col == %@)) && ((intCol != %@) || (int8Col != %@)))",
                    values: [6, Int8(9), 6, Int8(9)], count: 0) {
            ($0.intCol == 6 || $0.int8Col == Int8(9)) &&
            ($0.intCol != 6 || $0.int8Col != Int8(9))
        }
        assertQuery("((intCol == %@) || (int8Col == %@))", values: [6, Int8(9)], count: 1) {
            ($0.intCol == 6) || ($0.int8Col == Int8(9))
        }
        assertQuery("(((int8Col == %@) || (int16Col == %@)) && ((int8Col != %@) || (int16Col != %@)))",
                    values: [Int8(9), Int16(17), Int8(9), Int16(17)], count: 0) {
            ($0.int8Col == Int8(9) || $0.int16Col == Int16(17)) &&
            ($0.int8Col != Int8(9) || $0.int16Col != Int16(17))
        }
        assertQuery("((int8Col == %@) || (int16Col == %@))", values: [Int8(9), Int16(17)], count: 1) {
            ($0.int8Col == Int8(9)) || ($0.int16Col == Int16(17))
        }
        assertQuery("(((int16Col == %@) || (int32Col == %@)) && ((int16Col != %@) || (int32Col != %@)))",
                    values: [Int16(17), Int32(33), Int16(17), Int32(33)], count: 0) {
            ($0.int16Col == Int16(17) || $0.int32Col == Int32(33)) &&
            ($0.int16Col != Int16(17) || $0.int32Col != Int32(33))
        }
        assertQuery("((int16Col == %@) || (int32Col == %@))", values: [Int16(17), Int32(33)], count: 1) {
            ($0.int16Col == Int16(17)) || ($0.int32Col == Int32(33))
        }
        assertQuery("(((int32Col == %@) || (int64Col == %@)) && ((int32Col != %@) || (int64Col != %@)))",
                    values: [Int32(33), Int64(65), Int32(33), Int64(65)], count: 0) {
            ($0.int32Col == Int32(33) || $0.int64Col == Int64(65)) &&
            ($0.int32Col != Int32(33) || $0.int64Col != Int64(65))
        }
        assertQuery("((int32Col == %@) || (int64Col == %@))", values: [Int32(33), Int64(65)], count: 1) {
            ($0.int32Col == Int32(33)) || ($0.int64Col == Int64(65))
        }
        assertQuery("(((int64Col == %@) || (floatCol == %@)) && ((int64Col != %@) || (floatCol != %@)))",
                    values: [Int64(65), Float(6.55444333), Int64(65), Float(6.55444333)], count: 0) {
            ($0.int64Col == Int64(65) || $0.floatCol == Float(6.55444333)) &&
            ($0.int64Col != Int64(65) || $0.floatCol != Float(6.55444333))
        }
        assertQuery("((int64Col == %@) || (floatCol == %@))", values: [Int64(65), Float(6.55444333)], count: 1) {
            ($0.int64Col == Int64(65)) || ($0.floatCol == Float(6.55444333))
        }
        assertQuery("(((floatCol == %@) || (doubleCol == %@)) && ((floatCol != %@) || (doubleCol != %@)))",
                    values: [Float(6.55444333), 234.567, Float(6.55444333), 234.567], count: 0) {
            ($0.floatCol == Float(6.55444333) || $0.doubleCol == 234.567) &&
            ($0.floatCol != Float(6.55444333) || $0.doubleCol != 234.567)
        }
        assertQuery("((floatCol == %@) || (doubleCol == %@))", values: [Float(6.55444333), 234.567], count: 1) {
            ($0.floatCol == Float(6.55444333)) || ($0.doubleCol == 234.567)
        }
        assertQuery("(((doubleCol == %@) || (stringCol == %@)) && ((doubleCol != %@) || (stringCol != %@)))",
                    values: [234.567, "Foó", 234.567, "Foó"], count: 0) {
            ($0.doubleCol == 234.567 || $0.stringCol == "Foó") &&
            ($0.doubleCol != 234.567 || $0.stringCol != "Foó")
        }
        assertQuery("((doubleCol == %@) || (stringCol == %@))", values: [234.567, "Foó"], count: 1) {
            ($0.doubleCol == 234.567) || ($0.stringCol == "Foó")
        }
        assertQuery("(NOT ((doubleCol == %@) || (stringCol CONTAINS %@)) && (stringCol == %@))",
                    values: [234.567, "Foó", "Foó"], count: 0) {
            !($0.doubleCol == 234.567 || $0.stringCol.contains("Foó")) &&
            ($0.stringCol == "Foó")
        }
        assertQuery("(((stringCol == %@) || (binaryCol == %@)) && ((stringCol != %@) || (binaryCol != %@)))",
                    values: ["Foó", Data(count: 128), "Foó", Data(count: 128)], count: 0) {
            ($0.stringCol == "Foó" || $0.binaryCol == Data(count: 128)) &&
            ($0.stringCol != "Foó" || $0.binaryCol != Data(count: 128))
        }
        assertQuery("((stringCol == %@) || (binaryCol == %@))", values: ["Foó", Data(count: 128)], count: 1) {
            ($0.stringCol == "Foó") || ($0.binaryCol == Data(count: 128))
        }
        assertQuery("(((binaryCol == %@) || (dateCol == %@)) && ((binaryCol != %@) || (dateCol != %@)))",
                    values: [Data(count: 128), Date(timeIntervalSince1970: 2000000), Data(count: 128), Date(timeIntervalSince1970: 2000000)], count: 0) {
            ($0.binaryCol == Data(count: 128) || $0.dateCol == Date(timeIntervalSince1970: 2000000)) &&
            ($0.binaryCol != Data(count: 128) || $0.dateCol != Date(timeIntervalSince1970: 2000000))
        }
        assertQuery("((binaryCol == %@) || (dateCol == %@))", values: [Data(count: 128), Date(timeIntervalSince1970: 2000000)], count: 1) {
            ($0.binaryCol == Data(count: 128)) || ($0.dateCol == Date(timeIntervalSince1970: 2000000))
        }
        assertQuery("(((dateCol == %@) || (decimalCol == %@)) && ((dateCol != %@) || (decimalCol != %@)))",
                    values: [Date(timeIntervalSince1970: 2000000), Decimal128(234.567), Date(timeIntervalSince1970: 2000000), Decimal128(234.567)], count: 0) {
            ($0.dateCol == Date(timeIntervalSince1970: 2000000) || $0.decimalCol == Decimal128(234.567)) &&
            ($0.dateCol != Date(timeIntervalSince1970: 2000000) || $0.decimalCol != Decimal128(234.567))
        }
        assertQuery("((dateCol == %@) || (decimalCol == %@))", values: [Date(timeIntervalSince1970: 2000000), Decimal128(234.567)], count: 1) {
            ($0.dateCol == Date(timeIntervalSince1970: 2000000)) || ($0.decimalCol == Decimal128(234.567))
        }
        assertQuery("(((decimalCol == %@) || (objectIdCol == %@)) && ((decimalCol != %@) || (objectIdCol != %@)))",
                    values: [Decimal128(234.567), ObjectId("61184062c1d8f096a3695045"), Decimal128(234.567), ObjectId("61184062c1d8f096a3695045")], count: 0) {
            ($0.decimalCol == Decimal128(234.567) || $0.objectIdCol == ObjectId("61184062c1d8f096a3695045")) &&
            ($0.decimalCol != Decimal128(234.567) || $0.objectIdCol != ObjectId("61184062c1d8f096a3695045"))
        }
        assertQuery("((decimalCol == %@) || (objectIdCol == %@))", values: [Decimal128(234.567), ObjectId("61184062c1d8f096a3695045")], count: 1) {
            ($0.decimalCol == Decimal128(234.567)) || ($0.objectIdCol == ObjectId("61184062c1d8f096a3695045"))
        }
        assertQuery("(((objectIdCol == %@) || (uuidCol == %@)) && ((objectIdCol != %@) || (uuidCol != %@)))",
                    values: [ObjectId("61184062c1d8f096a3695045"), UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!, ObjectId("61184062c1d8f096a3695045"), UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!], count: 0) {
            ($0.objectIdCol == ObjectId("61184062c1d8f096a3695045") || $0.uuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!) &&
            ($0.objectIdCol != ObjectId("61184062c1d8f096a3695045") || $0.uuidCol != UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)
        }
        assertQuery("((objectIdCol == %@) || (uuidCol == %@))", values: [ObjectId("61184062c1d8f096a3695045"), UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!], count: 1) {
            ($0.objectIdCol == ObjectId("61184062c1d8f096a3695045")) || ($0.uuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)
        }
        assertQuery("(((uuidCol == %@) || (intEnumCol == %@)) && ((uuidCol != %@) || (intEnumCol != %@)))",
                    values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!, ModernIntEnum.value2, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!, ModernIntEnum.value2], count: 0) {
            ($0.uuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")! || $0.intEnumCol == .value2) &&
            ($0.uuidCol != UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")! || $0.intEnumCol != .value2)
        }
        assertQuery("((uuidCol == %@) || (intEnumCol == %@))", values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!, ModernIntEnum.value2], count: 1) {
            ($0.uuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!) || ($0.intEnumCol == .value2)
        }
        assertQuery("(((intEnumCol == %@) || (stringEnumCol == %@)) && ((intEnumCol != %@) || (stringEnumCol != %@)))",
                    values: [ModernIntEnum.value2, ModernStringEnum.value2, ModernIntEnum.value2, ModernStringEnum.value2], count: 0) {
            ($0.intEnumCol == .value2 || $0.stringEnumCol == .value2) &&
            ($0.intEnumCol != .value2 || $0.stringEnumCol != .value2)
        }
        assertQuery("((intEnumCol == %@) || (stringEnumCol == %@))", values: [ModernIntEnum.value2, ModernStringEnum.value2], count: 1) {
            ($0.intEnumCol == .value2) || ($0.stringEnumCol == .value2)
        }
        assertQuery("(((stringEnumCol == %@) || (optBoolCol == %@)) && ((stringEnumCol != %@) || (optBoolCol != %@)))",
                    values: [ModernStringEnum.value2, false, ModernStringEnum.value2, false], count: 0) {
            ($0.stringEnumCol == .value2 || $0.optBoolCol == false) &&
            ($0.stringEnumCol != .value2 || $0.optBoolCol != false)
        }
        assertQuery("((stringEnumCol == %@) || (optBoolCol == %@))", values: [ModernStringEnum.value2, false], count: 1) {
            ($0.stringEnumCol == .value2) || ($0.optBoolCol == false)
        }
        assertQuery("(((optBoolCol == %@) || (optIntCol == %@)) && ((optBoolCol != %@) || (optIntCol != %@)))",
                    values: [false, 6, false, 6], count: 0) {
            ($0.optBoolCol == false || $0.optIntCol == 6) &&
            ($0.optBoolCol != false || $0.optIntCol != 6)
        }
        assertQuery("((optBoolCol == %@) || (optIntCol == %@))", values: [false, 6], count: 1) {
            ($0.optBoolCol == false) || ($0.optIntCol == 6)
        }
        assertQuery("(((optIntCol == %@) || (optInt8Col == %@)) && ((optIntCol != %@) || (optInt8Col != %@)))",
                    values: [6, Int8(9), 6, Int8(9)], count: 0) {
            ($0.optIntCol == 6 || $0.optInt8Col == Int8(9)) &&
            ($0.optIntCol != 6 || $0.optInt8Col != Int8(9))
        }
        assertQuery("((optIntCol == %@) || (optInt8Col == %@))", values: [6, Int8(9)], count: 1) {
            ($0.optIntCol == 6) || ($0.optInt8Col == Int8(9))
        }
        assertQuery("(((optInt8Col == %@) || (optInt16Col == %@)) && ((optInt8Col != %@) || (optInt16Col != %@)))",
                    values: [Int8(9), Int16(17), Int8(9), Int16(17)], count: 0) {
            ($0.optInt8Col == Int8(9) || $0.optInt16Col == Int16(17)) &&
            ($0.optInt8Col != Int8(9) || $0.optInt16Col != Int16(17))
        }
        assertQuery("((optInt8Col == %@) || (optInt16Col == %@))", values: [Int8(9), Int16(17)], count: 1) {
            ($0.optInt8Col == Int8(9)) || ($0.optInt16Col == Int16(17))
        }
        assertQuery("(((optInt16Col == %@) || (optInt32Col == %@)) && ((optInt16Col != %@) || (optInt32Col != %@)))",
                    values: [Int16(17), Int32(33), Int16(17), Int32(33)], count: 0) {
            ($0.optInt16Col == Int16(17) || $0.optInt32Col == Int32(33)) &&
            ($0.optInt16Col != Int16(17) || $0.optInt32Col != Int32(33))
        }
        assertQuery("((optInt16Col == %@) || (optInt32Col == %@))", values: [Int16(17), Int32(33)], count: 1) {
            ($0.optInt16Col == Int16(17)) || ($0.optInt32Col == Int32(33))
        }
        assertQuery("(((optInt32Col == %@) || (optInt64Col == %@)) && ((optInt32Col != %@) || (optInt64Col != %@)))",
                    values: [Int32(33), Int64(65), Int32(33), Int64(65)], count: 0) {
            ($0.optInt32Col == Int32(33) || $0.optInt64Col == Int64(65)) &&
            ($0.optInt32Col != Int32(33) || $0.optInt64Col != Int64(65))
        }
        assertQuery("((optInt32Col == %@) || (optInt64Col == %@))", values: [Int32(33), Int64(65)], count: 1) {
            ($0.optInt32Col == Int32(33)) || ($0.optInt64Col == Int64(65))
        }
        assertQuery("(((optInt64Col == %@) || (optFloatCol == %@)) && ((optInt64Col != %@) || (optFloatCol != %@)))",
                    values: [Int64(65), Float(6.55444333), Int64(65), Float(6.55444333)], count: 0) {
            ($0.optInt64Col == Int64(65) || $0.optFloatCol == Float(6.55444333)) &&
            ($0.optInt64Col != Int64(65) || $0.optFloatCol != Float(6.55444333))
        }
        assertQuery("((optInt64Col == %@) || (optFloatCol == %@))", values: [Int64(65), Float(6.55444333)], count: 1) {
            ($0.optInt64Col == Int64(65)) || ($0.optFloatCol == Float(6.55444333))
        }
        assertQuery("(((optFloatCol == %@) || (optDoubleCol == %@)) && ((optFloatCol != %@) || (optDoubleCol != %@)))",
                    values: [Float(6.55444333), 234.567, Float(6.55444333), 234.567], count: 0) {
            ($0.optFloatCol == Float(6.55444333) || $0.optDoubleCol == 234.567) &&
            ($0.optFloatCol != Float(6.55444333) || $0.optDoubleCol != 234.567)
        }
        assertQuery("((optFloatCol == %@) || (optDoubleCol == %@))", values: [Float(6.55444333), 234.567], count: 1) {
            ($0.optFloatCol == Float(6.55444333)) || ($0.optDoubleCol == 234.567)
        }
        assertQuery("(((optDoubleCol == %@) || (optStringCol == %@)) && ((optDoubleCol != %@) || (optStringCol != %@)))",
                    values: [234.567, "Foó", 234.567, "Foó"], count: 0) {
            ($0.optDoubleCol == 234.567 || $0.optStringCol == "Foó") &&
            ($0.optDoubleCol != 234.567 || $0.optStringCol != "Foó")
        }
        assertQuery("((optDoubleCol == %@) || (optStringCol == %@))", values: [234.567, "Foó"], count: 1) {
            ($0.optDoubleCol == 234.567) || ($0.optStringCol == "Foó")
        }
        assertQuery("(NOT ((optDoubleCol == %@) || (optStringCol CONTAINS %@)) && (optStringCol == %@))",
                    values: [234.567, "Foó", "Foó"], count: 0) {
            !($0.optDoubleCol == 234.567 || $0.optStringCol.contains("Foó")) &&
            ($0.optStringCol == "Foó")
        }
        assertQuery("(((optStringCol == %@) || (optBinaryCol == %@)) && ((optStringCol != %@) || (optBinaryCol != %@)))",
                    values: ["Foó", Data(count: 128), "Foó", Data(count: 128)], count: 0) {
            ($0.optStringCol == "Foó" || $0.optBinaryCol == Data(count: 128)) &&
            ($0.optStringCol != "Foó" || $0.optBinaryCol != Data(count: 128))
        }
        assertQuery("((optStringCol == %@) || (optBinaryCol == %@))", values: ["Foó", Data(count: 128)], count: 1) {
            ($0.optStringCol == "Foó") || ($0.optBinaryCol == Data(count: 128))
        }
        assertQuery("(((optBinaryCol == %@) || (optDateCol == %@)) && ((optBinaryCol != %@) || (optDateCol != %@)))",
                    values: [Data(count: 128), Date(timeIntervalSince1970: 2000000), Data(count: 128), Date(timeIntervalSince1970: 2000000)], count: 0) {
            ($0.optBinaryCol == Data(count: 128) || $0.optDateCol == Date(timeIntervalSince1970: 2000000)) &&
            ($0.optBinaryCol != Data(count: 128) || $0.optDateCol != Date(timeIntervalSince1970: 2000000))
        }
        assertQuery("((optBinaryCol == %@) || (optDateCol == %@))", values: [Data(count: 128), Date(timeIntervalSince1970: 2000000)], count: 1) {
            ($0.optBinaryCol == Data(count: 128)) || ($0.optDateCol == Date(timeIntervalSince1970: 2000000))
        }
        assertQuery("(((optDateCol == %@) || (optDecimalCol == %@)) && ((optDateCol != %@) || (optDecimalCol != %@)))",
                    values: [Date(timeIntervalSince1970: 2000000), Decimal128(234.567), Date(timeIntervalSince1970: 2000000), Decimal128(234.567)], count: 0) {
            ($0.optDateCol == Date(timeIntervalSince1970: 2000000) || $0.optDecimalCol == Decimal128(234.567)) &&
            ($0.optDateCol != Date(timeIntervalSince1970: 2000000) || $0.optDecimalCol != Decimal128(234.567))
        }
        assertQuery("((optDateCol == %@) || (optDecimalCol == %@))", values: [Date(timeIntervalSince1970: 2000000), Decimal128(234.567)], count: 1) {
            ($0.optDateCol == Date(timeIntervalSince1970: 2000000)) || ($0.optDecimalCol == Decimal128(234.567))
        }
        assertQuery("(((optDecimalCol == %@) || (optObjectIdCol == %@)) && ((optDecimalCol != %@) || (optObjectIdCol != %@)))",
                    values: [Decimal128(234.567), ObjectId("61184062c1d8f096a3695045"), Decimal128(234.567), ObjectId("61184062c1d8f096a3695045")], count: 0) {
            ($0.optDecimalCol == Decimal128(234.567) || $0.optObjectIdCol == ObjectId("61184062c1d8f096a3695045")) &&
            ($0.optDecimalCol != Decimal128(234.567) || $0.optObjectIdCol != ObjectId("61184062c1d8f096a3695045"))
        }
        assertQuery("((optDecimalCol == %@) || (optObjectIdCol == %@))", values: [Decimal128(234.567), ObjectId("61184062c1d8f096a3695045")], count: 1) {
            ($0.optDecimalCol == Decimal128(234.567)) || ($0.optObjectIdCol == ObjectId("61184062c1d8f096a3695045"))
        }
        assertQuery("(((optObjectIdCol == %@) || (optUuidCol == %@)) && ((optObjectIdCol != %@) || (optUuidCol != %@)))",
                    values: [ObjectId("61184062c1d8f096a3695045"), UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!, ObjectId("61184062c1d8f096a3695045"), UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!], count: 0) {
            ($0.optObjectIdCol == ObjectId("61184062c1d8f096a3695045") || $0.optUuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!) &&
            ($0.optObjectIdCol != ObjectId("61184062c1d8f096a3695045") || $0.optUuidCol != UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)
        }
        assertQuery("((optObjectIdCol == %@) || (optUuidCol == %@))", values: [ObjectId("61184062c1d8f096a3695045"), UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!], count: 1) {
            ($0.optObjectIdCol == ObjectId("61184062c1d8f096a3695045")) || ($0.optUuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)
        }
        assertQuery("(((optUuidCol == %@) || (optIntEnumCol == %@)) && ((optUuidCol != %@) || (optIntEnumCol != %@)))",
                    values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!, ModernIntEnum.value2, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!, ModernIntEnum.value2], count: 0) {
            ($0.optUuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")! || $0.optIntEnumCol == .value2) &&
            ($0.optUuidCol != UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")! || $0.optIntEnumCol != .value2)
        }
        assertQuery("((optUuidCol == %@) || (optIntEnumCol == %@))", values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!, ModernIntEnum.value2], count: 1) {
            ($0.optUuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!) || ($0.optIntEnumCol == .value2)
        }
        assertQuery("(((optIntEnumCol == %@) || (optStringEnumCol == %@)) && ((optIntEnumCol != %@) || (optStringEnumCol != %@)))",
                    values: [ModernIntEnum.value2, ModernStringEnum.value2, ModernIntEnum.value2, ModernStringEnum.value2], count: 0) {
            ($0.optIntEnumCol == .value2 || $0.optStringEnumCol == .value2) &&
            ($0.optIntEnumCol != .value2 || $0.optStringEnumCol != .value2)
        }
        assertQuery("((optIntEnumCol == %@) || (optStringEnumCol == %@))", values: [ModernIntEnum.value2, ModernStringEnum.value2], count: 1) {
            ($0.optIntEnumCol == .value2) || ($0.optStringEnumCol == .value2)
        }

        // Aggregates

        let sumarrayInt = 5 + 6
        assertQuery("(((((arrayInt.@min <= %@) || (arrayInt.@max >= %@)) && (arrayInt.@sum == %@)) && (arrayInt.@count != %@)) && ((arrayInt.@avg > %@) && (arrayInt.@avg < %@)))",
                    values: [5, 7, sumarrayInt, 0, 5, 7], count: 1) {
            (($0.arrayInt.min <= 5) || ($0.arrayInt.max >= 7)) &&
            ($0.arrayInt.sum == sumarrayInt) &&
            ($0.arrayInt.count != 0) &&
            ($0.arrayInt.avg > 5 && $0.arrayInt.avg < 7)
        }
        let sumarrayOptInt = 5 + 6
        assertQuery("(((((arrayOptInt.@min <= %@) || (arrayOptInt.@max >= %@)) && (arrayOptInt.@sum == %@)) && (arrayOptInt.@count != %@)) && ((arrayOptInt.@avg > %@) && (arrayOptInt.@avg < %@)))",
                    values: [5, 7, sumarrayOptInt, 0, 5, 7], count: 1) {
            (($0.arrayOptInt.min <= 5) || ($0.arrayOptInt.max >= 7)) &&
            ($0.arrayOptInt.sum == sumarrayOptInt) &&
            ($0.arrayOptInt.count != 0) &&
            ($0.arrayOptInt.avg > 5 && $0.arrayOptInt.avg < 7)
        }
        let summapInt = 5 + 6
        assertQuery("(((((mapInt.@min <= %@) || (mapInt.@max >= %@)) && (mapInt.@sum == %@)) && (mapInt.@count != %@)) && ((mapInt.@avg > %@) && (mapInt.@avg < %@)))",
                    values: [5, 7, summapInt, 0, 5, 7], count: 1) {
            (($0.mapInt.min <= 5) || ($0.mapInt.max >= 7)) &&
            ($0.mapInt.sum == summapInt) &&
            ($0.mapInt.count != 0) &&
            ($0.mapInt.avg > 5 && $0.mapInt.avg < 7)
        }
        let summapOptInt = 5 + 6
        assertQuery("(((((mapOptInt.@min <= %@) || (mapOptInt.@max >= %@)) && (mapOptInt.@sum == %@)) && (mapOptInt.@count != %@)) && ((mapOptInt.@avg > %@) && (mapOptInt.@avg < %@)))",
                    values: [5, 7, summapOptInt, 0, 5, 7], count: 1) {
            (($0.mapOptInt.min <= 5) || ($0.mapOptInt.max >= 7)) &&
            ($0.mapOptInt.sum == summapOptInt) &&
            ($0.mapOptInt.count != 0) &&
            ($0.mapOptInt.avg > 5 && $0.mapOptInt.avg < 7)
        }

        // Keypath Collection Aggregates

        let object = objects().first!
        createKeypathCollectionAggregatesObject(object)

        let sumdoubleCol = 123.456 + 234.567 + 345.678
        assertQuery("(((((arrayCol.@min.doubleCol <= %@) || (arrayCol.@max.doubleCol >= %@)) && (arrayCol.@sum.doubleCol == %@)) && (arrayCol.@sum.doubleCol != %@)) && ((arrayCol.@avg.doubleCol > %@) && (arrayCol.@avg.doubleCol < %@)))", values: [123.456, 345.678, sumdoubleCol, 0, 123.456, 345.678], count: 1) {
            ($0.arrayCol.doubleCol.min <= 123.456 || $0.arrayCol.doubleCol.max >= 345.678) &&
            $0.arrayCol.doubleCol.sum == sumdoubleCol &&
            $0.arrayCol.doubleCol.sum != 0 &&
            ($0.arrayCol.doubleCol.avg > 123.456 && $0.arrayCol.doubleCol.avg < 345.678)
        }

        let sumoptDoubleCol = 123.456 + 234.567 + 345.678
        assertQuery("(((((arrayCol.@min.optDoubleCol <= %@) || (arrayCol.@max.optDoubleCol >= %@)) && (arrayCol.@sum.optDoubleCol == %@)) && (arrayCol.@sum.optDoubleCol != %@)) && ((arrayCol.@avg.optDoubleCol > %@) && (arrayCol.@avg.optDoubleCol < %@)))", values: [123.456, 345.678, sumoptDoubleCol, 0, 123.456, 345.678], count: 1) {
            ($0.arrayCol.optDoubleCol.min <= 123.456 || $0.arrayCol.optDoubleCol.max >= 345.678) &&
            $0.arrayCol.optDoubleCol.sum == sumoptDoubleCol &&
            $0.arrayCol.optDoubleCol.sum != 0 &&
            ($0.arrayCol.optDoubleCol.avg > 123.456 && $0.arrayCol.optDoubleCol.avg < 345.678)
        }
    }

    func testAny() {
        assertQuery(ModernAllTypesObject.self, "(ANY arrayBool == %@)", true, count: 1) {
            $0.arrayBool == true
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayInt == %@)", 5, count: 1) {
            $0.arrayInt == 5
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayInt8 == %@)", Int8(8), count: 1) {
            $0.arrayInt8 == Int8(8)
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayInt16 == %@)", Int16(16), count: 1) {
            $0.arrayInt16 == Int16(16)
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayInt32 == %@)", Int32(32), count: 1) {
            $0.arrayInt32 == Int32(32)
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayInt64 == %@)", Int64(64), count: 1) {
            $0.arrayInt64 == Int64(64)
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayFloat == %@)", Float(5.55444333), count: 1) {
            $0.arrayFloat == Float(5.55444333)
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayDouble == %@)", 123.456, count: 1) {
            $0.arrayDouble == 123.456
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayString == %@)", "Foo", count: 1) {
            $0.arrayString == "Foo"
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayBinary == %@)", Data(count: 64), count: 1) {
            $0.arrayBinary == Data(count: 64)
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayDate == %@)", Date(timeIntervalSince1970: 1000000), count: 1) {
            $0.arrayDate == Date(timeIntervalSince1970: 1000000)
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayDecimal == %@)", Decimal128(123.456), count: 1) {
            $0.arrayDecimal == Decimal128(123.456)
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayObjectId == %@)", ObjectId("61184062c1d8f096a3695046"), count: 1) {
            $0.arrayObjectId == ObjectId("61184062c1d8f096a3695046")
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayUuid == %@)", UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, count: 1) {
            $0.arrayUuid == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayAny == %@)", AnyRealmValue.objectId(ObjectId("61184062c1d8f096a3695046")), count: 1) {
            $0.arrayAny == AnyRealmValue.objectId(ObjectId("61184062c1d8f096a3695046"))
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY listInt == %@)", EnumInt.value1, count: 1) {
            $0.listInt == .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY listInt8 == %@)", EnumInt8.value1, count: 1) {
            $0.listInt8 == .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY listInt16 == %@)", EnumInt16.value1, count: 1) {
            $0.listInt16 == .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY listInt32 == %@)", EnumInt32.value1, count: 1) {
            $0.listInt32 == .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY listInt64 == %@)", EnumInt64.value1, count: 1) {
            $0.listInt64 == .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY listFloat == %@)", EnumFloat.value1, count: 1) {
            $0.listFloat == .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY listDouble == %@)", EnumDouble.value1, count: 1) {
            $0.listDouble == .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY listString == %@)", EnumString.value1, count: 1) {
            $0.listString == .value1
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayOptBool == %@)", true, count: 1) {
            $0.arrayOptBool == true
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayOptInt == %@)", 5, count: 1) {
            $0.arrayOptInt == 5
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayOptInt8 == %@)", Int8(8), count: 1) {
            $0.arrayOptInt8 == Int8(8)
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayOptInt16 == %@)", Int16(16), count: 1) {
            $0.arrayOptInt16 == Int16(16)
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayOptInt32 == %@)", Int32(32), count: 1) {
            $0.arrayOptInt32 == Int32(32)
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayOptInt64 == %@)", Int64(64), count: 1) {
            $0.arrayOptInt64 == Int64(64)
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayOptFloat == %@)", Float(5.55444333), count: 1) {
            $0.arrayOptFloat == Float(5.55444333)
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayOptDouble == %@)", 123.456, count: 1) {
            $0.arrayOptDouble == 123.456
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayOptString == %@)", "Foo", count: 1) {
            $0.arrayOptString == "Foo"
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayOptBinary == %@)", Data(count: 64), count: 1) {
            $0.arrayOptBinary == Data(count: 64)
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayOptDate == %@)", Date(timeIntervalSince1970: 1000000), count: 1) {
            $0.arrayOptDate == Date(timeIntervalSince1970: 1000000)
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayOptDecimal == %@)", Decimal128(123.456), count: 1) {
            $0.arrayOptDecimal == Decimal128(123.456)
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayOptObjectId == %@)", ObjectId("61184062c1d8f096a3695046"), count: 1) {
            $0.arrayOptObjectId == ObjectId("61184062c1d8f096a3695046")
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayOptUuid == %@)", UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, count: 1) {
            $0.arrayOptUuid == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY listIntOpt == %@)", EnumInt.value1, count: 1) {
            $0.listIntOpt == .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY listInt8Opt == %@)", EnumInt8.value1, count: 1) {
            $0.listInt8Opt == .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY listInt16Opt == %@)", EnumInt16.value1, count: 1) {
            $0.listInt16Opt == .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY listInt32Opt == %@)", EnumInt32.value1, count: 1) {
            $0.listInt32Opt == .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY listInt64Opt == %@)", EnumInt64.value1, count: 1) {
            $0.listInt64Opt == .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY listFloatOpt == %@)", EnumFloat.value1, count: 1) {
            $0.listFloatOpt == .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY listDoubleOpt == %@)", EnumDouble.value1, count: 1) {
            $0.listDoubleOpt == .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY listStringOpt == %@)", EnumString.value1, count: 1) {
            $0.listStringOpt == .value1
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setBool == %@)", true, count: 1) {
            $0.setBool == true
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setInt == %@)", 5, count: 1) {
            $0.setInt == 5
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setInt8 == %@)", Int8(8), count: 1) {
            $0.setInt8 == Int8(8)
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setInt16 == %@)", Int16(16), count: 1) {
            $0.setInt16 == Int16(16)
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setInt32 == %@)", Int32(32), count: 1) {
            $0.setInt32 == Int32(32)
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setInt64 == %@)", Int64(64), count: 1) {
            $0.setInt64 == Int64(64)
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setFloat == %@)", Float(5.55444333), count: 1) {
            $0.setFloat == Float(5.55444333)
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setDouble == %@)", 123.456, count: 1) {
            $0.setDouble == 123.456
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setString == %@)", "Foo", count: 1) {
            $0.setString == "Foo"
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setBinary == %@)", Data(count: 64), count: 1) {
            $0.setBinary == Data(count: 64)
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setDate == %@)", Date(timeIntervalSince1970: 1000000), count: 1) {
            $0.setDate == Date(timeIntervalSince1970: 1000000)
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setDecimal == %@)", Decimal128(123.456), count: 1) {
            $0.setDecimal == Decimal128(123.456)
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setObjectId == %@)", ObjectId("61184062c1d8f096a3695046"), count: 1) {
            $0.setObjectId == ObjectId("61184062c1d8f096a3695046")
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setUuid == %@)", UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, count: 1) {
            $0.setUuid == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setAny == %@)", AnyRealmValue.objectId(ObjectId("61184062c1d8f096a3695046")), count: 1) {
            $0.setAny == AnyRealmValue.objectId(ObjectId("61184062c1d8f096a3695046"))
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY setInt == %@)", EnumInt.value1, count: 1) {
            $0.setInt == .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY setInt8 == %@)", EnumInt8.value1, count: 1) {
            $0.setInt8 == .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY setInt16 == %@)", EnumInt16.value1, count: 1) {
            $0.setInt16 == .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY setInt32 == %@)", EnumInt32.value1, count: 1) {
            $0.setInt32 == .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY setInt64 == %@)", EnumInt64.value1, count: 1) {
            $0.setInt64 == .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY setFloat == %@)", EnumFloat.value1, count: 1) {
            $0.setFloat == .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY setDouble == %@)", EnumDouble.value1, count: 1) {
            $0.setDouble == .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY setString == %@)", EnumString.value1, count: 1) {
            $0.setString == .value1
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setOptBool == %@)", true, count: 1) {
            $0.setOptBool == true
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setOptInt == %@)", 5, count: 1) {
            $0.setOptInt == 5
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setOptInt8 == %@)", Int8(8), count: 1) {
            $0.setOptInt8 == Int8(8)
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setOptInt16 == %@)", Int16(16), count: 1) {
            $0.setOptInt16 == Int16(16)
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setOptInt32 == %@)", Int32(32), count: 1) {
            $0.setOptInt32 == Int32(32)
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setOptInt64 == %@)", Int64(64), count: 1) {
            $0.setOptInt64 == Int64(64)
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setOptFloat == %@)", Float(5.55444333), count: 1) {
            $0.setOptFloat == Float(5.55444333)
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setOptDouble == %@)", 123.456, count: 1) {
            $0.setOptDouble == 123.456
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setOptString == %@)", "Foo", count: 1) {
            $0.setOptString == "Foo"
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setOptBinary == %@)", Data(count: 64), count: 1) {
            $0.setOptBinary == Data(count: 64)
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setOptDate == %@)", Date(timeIntervalSince1970: 1000000), count: 1) {
            $0.setOptDate == Date(timeIntervalSince1970: 1000000)
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setOptDecimal == %@)", Decimal128(123.456), count: 1) {
            $0.setOptDecimal == Decimal128(123.456)
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setOptObjectId == %@)", ObjectId("61184062c1d8f096a3695046"), count: 1) {
            $0.setOptObjectId == ObjectId("61184062c1d8f096a3695046")
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setOptUuid == %@)", UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, count: 1) {
            $0.setOptUuid == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY setIntOpt == %@)", EnumInt.value1, count: 1) {
            $0.setIntOpt == .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY setInt8Opt == %@)", EnumInt8.value1, count: 1) {
            $0.setInt8Opt == .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY setInt16Opt == %@)", EnumInt16.value1, count: 1) {
            $0.setInt16Opt == .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY setInt32Opt == %@)", EnumInt32.value1, count: 1) {
            $0.setInt32Opt == .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY setInt64Opt == %@)", EnumInt64.value1, count: 1) {
            $0.setInt64Opt == .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY setFloatOpt == %@)", EnumFloat.value1, count: 1) {
            $0.setFloatOpt == .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY setDoubleOpt == %@)", EnumDouble.value1, count: 1) {
            $0.setDoubleOpt == .value1
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY setStringOpt == %@)", EnumString.value1, count: 1) {
            $0.setStringOpt == .value1
        }

        assertQuery("(((ANY arrayCol.intCol != %@) && (ANY arrayCol.objectCol.intCol > %@)) && ((ANY setCol.intCol != %@) && (ANY setCol.objectCol.intCol > %@)))", values: [123, 456, 123, 456], count: 0) {
            (($0.arrayCol.intCol != 123) && ($0.arrayCol.objectCol.intCol > 456)) && (($0.setCol.intCol != 123) && ($0.setCol.objectCol.intCol > 456))
        }
    }

    func testSubquery() {
        // List

        // Count of results will be 0 because there are no `ModernAllTypesObject`s in the list.
        assertQuery("(SUBQUERY(arrayCol, $col1, ($col1.intCol != %@)).@count > %@)", values: [123, 0], count: 0) {
            ($0.arrayCol.intCol != 123).count > 0
        }

        assertQuery("((intCol == %@) && (SUBQUERY(arrayCol, $col1, ($col1.stringCol == %@)).@count == %@))", values: [5, "Bar", 0], count: 0) {
            $0.intCol == 5 &&
            ($0.arrayCol.stringCol == "Bar").count == 0
        }

        // Set

        // Will be 0 results because there are no `ModernAllTypesObject`s in the set.
        assertQuery("(SUBQUERY(arrayCol, $col1, ($col1.intCol != %@)).@count > %@)", values: [123, 0], count: 0) {
            ($0.arrayCol.intCol != 123).count > 0
        }

        assertQuery("((intCol == %@) && (SUBQUERY(setCol, $col1, ($col1.stringCol == %@)).@count == %@))", values: [5, "Bar", 0], count: 0) {
            $0.intCol == 5 &&
            ($0.setCol.stringCol == "Bar").count == 0
        }

        let object = objects().first!
        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["intCol": 5, "stringCol": "Foo"])
            object.arrayCol.append(modernObj)
            object.setCol.insert(modernObj)
        }

        // Results count should now be 1
        assertQuery("(SUBQUERY(arrayCol, $col1, ($col1.arrayInt.@count >= %@)).@count > %@)", values: [0, 0], count: 1) {
            ($0.arrayCol.arrayInt.count >= 0).count > 0
        }

        // Subquery in a subquery
        assertQuery("(SUBQUERY(arrayCol, $col1, (($col1.arrayInt.@count >= %@) && (SUBQUERY(arrayCol, $col2, ($col2.intCol != %@)).@count > %@))).@count > %@)", values: [0, 123, 0, 0], count: 0) {
            ($0.arrayCol.arrayInt.count >= 0 && ($0.arrayCol.intCol != 123).count > 0).count > 0
        }

        assertQuery("(SUBQUERY(arrayCol, $col1, ($col1.intCol != %@)).@count > %@)", values: [123, 0], count: 1) {
            ($0.arrayCol.intCol != 123).count > 0
        }

        assertQuery("(SUBQUERY(arrayCol, $col1, (($col1.intCol > %@) && ($col1.intCol <= %@))).@count > %@)", values: [0, 5, 0], count: 1) {
            ($0.arrayCol.intCol > 0 && $0.arrayCol.intCol <= 5 ).count > 0
        }

        assertQuery("((SUBQUERY(arrayCol, $col1, ($col1.intCol == %@)).@count == %@) && (SUBQUERY(arrayCol, $col2, ($col2.stringCol == %@)).@count == %@))", values: [5, 1, "Bar", 0], count: 1) {
            ($0.arrayCol.intCol == 5).count == 1 &&
            ($0.arrayCol.stringCol == "Bar").count == 0
        }

        // Set

        // Will be 0 results because there are no `ModernAllTypesObject`s in the set.
        assertQuery("(SUBQUERY(arrayCol, $col1, ($col1.intCol != %@)).@count > %@)", values: [123, 0], count: 1) {
            ($0.arrayCol.intCol != 123).count > 0
        }

        assertQuery("((intCol == %@) && (SUBQUERY(setCol, $col1, ($col1.stringCol == %@)).@count == %@))", values: [6, "Bar", 0], count: 1) {
            ($0.intCol == 6) &&
            ($0.setCol.stringCol == "Bar").count == 0
        }

        assertQuery("((intCol == %@) && (SUBQUERY(setCol, $col1, (($col1.intCol == %@) && ($col1.stringCol != %@))).@count == %@))", values: [6, 5, "Blah", 1], count: 1) {
            ($0.intCol == 6) &&
            (((($0.setCol.intCol == 5) && ($0.setCol.stringCol != "Blah"))).count == 1)
        }

        // Column comparison

        assertQuery("(SUBQUERY(arrayCol, $col1, ($col1.stringCol == stringCol)).@count == %@)", 0, count: 1) {
            ($0.arrayCol.stringCol == $0.stringCol).count == 0
        }

        assertThrows(assertQuery("", count: 1) {
            ($0.stringCol == $0.stringCol).count == 0
        }, reason: "Subqueries must contain a keypath starting with a collection.")
    }

    // MARK: - Collection Aggregations

    private func validateAverage<Root: Object, T: RealmCollection>(_ name: String, _ average: T.Element, _ min: T.Element, _ lhs: (Query<Root>) -> Query<T>)
            where T.Element: _Persistable, T.Element.PersistedType: _QueryNumeric, T.Element: QueryValue {
        assertQuery(Root.self, "(objectCol.\(name).@avg == %@)", average, count: 1) {
            lhs($0).avg == average
        }
        assertQuery(Root.self, "(objectCol.\(name).@avg == %@)", min, count: 0) {
            lhs($0).avg == min
        }
        assertQuery(Root.self, "(objectCol.\(name).@avg != %@)", average, count: 1) {
            lhs($0).avg != average
        }
        assertQuery(Root.self, "(objectCol.\(name).@avg != %@)", min, count: 2) {
            lhs($0).avg != min
        }
        assertQuery(Root.self, "(objectCol.\(name).@avg > %@)", average, count: 0) {
            lhs($0).avg > average
        }
        assertQuery(Root.self, "(objectCol.\(name).@avg > %@)", min, count: 1) {
            lhs($0).avg > min
        }
        assertQuery(Root.self, "(objectCol.\(name).@avg < %@)", average, count: 0 + 0) {
            lhs($0).avg < average
        }
        assertQuery(Root.self, "(objectCol.\(name).@avg >= %@)", average, count: 1) {
            lhs($0).avg >= average
        }
        assertQuery(Root.self, "(objectCol.\(name).@avg <= %@)", average, count: 1 + 0) {
            lhs($0).avg <= average
        }
    }

    private func validateAverage<Root: Object, T: RealmKeyedCollection>(_ name: String, _ average: T.Value, _ min: T.Value, _ lhs: (Query<Root>) -> Query<T>)
            where T.Value: _Persistable, T.Value.PersistedType: _QueryNumeric, T.Value: QueryValue {
        assertQuery(Root.self, "(objectCol.\(name).@avg == %@)", average, count: 1) {
            lhs($0).avg == average
        }
        assertQuery(Root.self, "(objectCol.\(name).@avg == %@)", min, count: 0) {
            lhs($0).avg == min
        }
        assertQuery(Root.self, "(objectCol.\(name).@avg != %@)", average, count: 1) {
            lhs($0).avg != average
        }
        assertQuery(Root.self, "(objectCol.\(name).@avg != %@)", min, count: 2) {
            lhs($0).avg != min
        }
        assertQuery(Root.self, "(objectCol.\(name).@avg > %@)", average, count: 0) {
            lhs($0).avg > average
        }
        assertQuery(Root.self, "(objectCol.\(name).@avg > %@)", min, count: 1) {
            lhs($0).avg > min
        }
        assertQuery(Root.self, "(objectCol.\(name).@avg < %@)", average, count: 0 + 0) {
            lhs($0).avg < average
        }
        assertQuery(Root.self, "(objectCol.\(name).@avg >= %@)", average, count: 1) {
            lhs($0).avg >= average
        }
        assertQuery(Root.self, "(objectCol.\(name).@avg <= %@)", average, count: 1 + 0) {
            lhs($0).avg <= average
        }
    }

    func testCollectionAggregatesAvg() {
        initLinkedCollectionAggregatesObject()

        validateAverage("arrayInt", Int.average(), 5,
                    \Query<ModernAllTypesObject>.objectCol.arrayInt)
        validateAverage("arrayInt8", Int8.average(), Int8(8),
                    \Query<ModernAllTypesObject>.objectCol.arrayInt8)
        validateAverage("arrayInt16", Int16.average(), Int16(16),
                    \Query<ModernAllTypesObject>.objectCol.arrayInt16)
        validateAverage("arrayInt32", Int32.average(), Int32(32),
                    \Query<ModernAllTypesObject>.objectCol.arrayInt32)
        validateAverage("arrayInt64", Int64.average(), Int64(64),
                    \Query<ModernAllTypesObject>.objectCol.arrayInt64)
        validateAverage("arrayFloat", Float.average(), Float(5.55444333),
                    \Query<ModernAllTypesObject>.objectCol.arrayFloat)
        validateAverage("arrayDouble", Double.average(), 123.456,
                    \Query<ModernAllTypesObject>.objectCol.arrayDouble)
        validateAverage("arrayDecimal", Decimal128.average(), Decimal128(123.456),
                    \Query<ModernAllTypesObject>.objectCol.arrayDecimal)
        validateAverage("listInt", EnumInt.average(), EnumInt.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt.rawValue)
        validateAverage("listInt8", EnumInt8.average(), EnumInt8.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt8.rawValue)
        validateAverage("listInt16", EnumInt16.average(), EnumInt16.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt16.rawValue)
        validateAverage("listInt32", EnumInt32.average(), EnumInt32.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt32.rawValue)
        validateAverage("listInt64", EnumInt64.average(), EnumInt64.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt64.rawValue)
        validateAverage("listFloat", EnumFloat.average(), EnumFloat.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listFloat.rawValue)
        validateAverage("listDouble", EnumDouble.average(), EnumDouble.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listDouble.rawValue)
        validateAverage("arrayOptInt", Int?.average(), 5,
                    \Query<ModernAllTypesObject>.objectCol.arrayOptInt)
        validateAverage("arrayOptInt8", Int8?.average(), Int8(8),
                    \Query<ModernAllTypesObject>.objectCol.arrayOptInt8)
        validateAverage("arrayOptInt16", Int16?.average(), Int16(16),
                    \Query<ModernAllTypesObject>.objectCol.arrayOptInt16)
        validateAverage("arrayOptInt32", Int32?.average(), Int32(32),
                    \Query<ModernAllTypesObject>.objectCol.arrayOptInt32)
        validateAverage("arrayOptInt64", Int64?.average(), Int64(64),
                    \Query<ModernAllTypesObject>.objectCol.arrayOptInt64)
        validateAverage("arrayOptFloat", Float?.average(), Float(5.55444333),
                    \Query<ModernAllTypesObject>.objectCol.arrayOptFloat)
        validateAverage("arrayOptDouble", Double?.average(), 123.456,
                    \Query<ModernAllTypesObject>.objectCol.arrayOptDouble)
        validateAverage("arrayOptDecimal", Decimal128?.average(), Decimal128(123.456),
                    \Query<ModernAllTypesObject>.objectCol.arrayOptDecimal)
        validateAverage("listIntOpt", EnumInt?.average(), EnumInt.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listIntOpt.rawValue)
        validateAverage("listInt8Opt", EnumInt8?.average(), EnumInt8.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt8Opt.rawValue)
        validateAverage("listInt16Opt", EnumInt16?.average(), EnumInt16.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt16Opt.rawValue)
        validateAverage("listInt32Opt", EnumInt32?.average(), EnumInt32.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt32Opt.rawValue)
        validateAverage("listInt64Opt", EnumInt64?.average(), EnumInt64.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt64Opt.rawValue)
        validateAverage("listFloatOpt", EnumFloat?.average(), EnumFloat.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listFloatOpt.rawValue)
        validateAverage("listDoubleOpt", EnumDouble?.average(), EnumDouble.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listDoubleOpt.rawValue)
        validateAverage("setInt", Int.average(), 5,
                    \Query<ModernAllTypesObject>.objectCol.setInt)
        validateAverage("setInt8", Int8.average(), Int8(8),
                    \Query<ModernAllTypesObject>.objectCol.setInt8)
        validateAverage("setInt16", Int16.average(), Int16(16),
                    \Query<ModernAllTypesObject>.objectCol.setInt16)
        validateAverage("setInt32", Int32.average(), Int32(32),
                    \Query<ModernAllTypesObject>.objectCol.setInt32)
        validateAverage("setInt64", Int64.average(), Int64(64),
                    \Query<ModernAllTypesObject>.objectCol.setInt64)
        validateAverage("setFloat", Float.average(), Float(5.55444333),
                    \Query<ModernAllTypesObject>.objectCol.setFloat)
        validateAverage("setDouble", Double.average(), 123.456,
                    \Query<ModernAllTypesObject>.objectCol.setDouble)
        validateAverage("setDecimal", Decimal128.average(), Decimal128(123.456),
                    \Query<ModernAllTypesObject>.objectCol.setDecimal)
        validateAverage("setInt", EnumInt.average(), EnumInt.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt.rawValue)
        validateAverage("setInt8", EnumInt8.average(), EnumInt8.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt8.rawValue)
        validateAverage("setInt16", EnumInt16.average(), EnumInt16.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt16.rawValue)
        validateAverage("setInt32", EnumInt32.average(), EnumInt32.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt32.rawValue)
        validateAverage("setInt64", EnumInt64.average(), EnumInt64.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt64.rawValue)
        validateAverage("setFloat", EnumFloat.average(), EnumFloat.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setFloat.rawValue)
        validateAverage("setDouble", EnumDouble.average(), EnumDouble.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setDouble.rawValue)
        validateAverage("setOptInt", Int?.average(), 5,
                    \Query<ModernAllTypesObject>.objectCol.setOptInt)
        validateAverage("setOptInt8", Int8?.average(), Int8(8),
                    \Query<ModernAllTypesObject>.objectCol.setOptInt8)
        validateAverage("setOptInt16", Int16?.average(), Int16(16),
                    \Query<ModernAllTypesObject>.objectCol.setOptInt16)
        validateAverage("setOptInt32", Int32?.average(), Int32(32),
                    \Query<ModernAllTypesObject>.objectCol.setOptInt32)
        validateAverage("setOptInt64", Int64?.average(), Int64(64),
                    \Query<ModernAllTypesObject>.objectCol.setOptInt64)
        validateAverage("setOptFloat", Float?.average(), Float(5.55444333),
                    \Query<ModernAllTypesObject>.objectCol.setOptFloat)
        validateAverage("setOptDouble", Double?.average(), 123.456,
                    \Query<ModernAllTypesObject>.objectCol.setOptDouble)
        validateAverage("setOptDecimal", Decimal128?.average(), Decimal128(123.456),
                    \Query<ModernAllTypesObject>.objectCol.setOptDecimal)
        validateAverage("setIntOpt", EnumInt?.average(), EnumInt.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setIntOpt.rawValue)
        validateAverage("setInt8Opt", EnumInt8?.average(), EnumInt8.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt8Opt.rawValue)
        validateAverage("setInt16Opt", EnumInt16?.average(), EnumInt16.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt16Opt.rawValue)
        validateAverage("setInt32Opt", EnumInt32?.average(), EnumInt32.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt32Opt.rawValue)
        validateAverage("setInt64Opt", EnumInt64?.average(), EnumInt64.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt64Opt.rawValue)
        validateAverage("setFloatOpt", EnumFloat?.average(), EnumFloat.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setFloatOpt.rawValue)
        validateAverage("setDoubleOpt", EnumDouble?.average(), EnumDouble.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setDoubleOpt.rawValue)
        validateAverage("mapInt", Int.average(), 5,
                    \Query<ModernAllTypesObject>.objectCol.mapInt)
        validateAverage("mapInt8", Int8.average(), Int8(8),
                    \Query<ModernAllTypesObject>.objectCol.mapInt8)
        validateAverage("mapInt16", Int16.average(), Int16(16),
                    \Query<ModernAllTypesObject>.objectCol.mapInt16)
        validateAverage("mapInt32", Int32.average(), Int32(32),
                    \Query<ModernAllTypesObject>.objectCol.mapInt32)
        validateAverage("mapInt64", Int64.average(), Int64(64),
                    \Query<ModernAllTypesObject>.objectCol.mapInt64)
        validateAverage("mapFloat", Float.average(), Float(5.55444333),
                    \Query<ModernAllTypesObject>.objectCol.mapFloat)
        validateAverage("mapDouble", Double.average(), 123.456,
                    \Query<ModernAllTypesObject>.objectCol.mapDouble)
        validateAverage("mapDecimal", Decimal128.average(), Decimal128(123.456),
                    \Query<ModernAllTypesObject>.objectCol.mapDecimal)
        validateAverage("mapInt", EnumInt.average(), EnumInt.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt.rawValue)
        validateAverage("mapInt8", EnumInt8.average(), EnumInt8.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt8.rawValue)
        validateAverage("mapInt16", EnumInt16.average(), EnumInt16.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt16.rawValue)
        validateAverage("mapInt32", EnumInt32.average(), EnumInt32.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt32.rawValue)
        validateAverage("mapInt64", EnumInt64.average(), EnumInt64.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt64.rawValue)
        validateAverage("mapFloat", EnumFloat.average(), EnumFloat.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapFloat.rawValue)
        validateAverage("mapDouble", EnumDouble.average(), EnumDouble.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapDouble.rawValue)
        validateAverage("mapOptInt", Int?.average(), 5,
                    \Query<ModernAllTypesObject>.objectCol.mapOptInt)
        validateAverage("mapOptInt8", Int8?.average(), Int8(8),
                    \Query<ModernAllTypesObject>.objectCol.mapOptInt8)
        validateAverage("mapOptInt16", Int16?.average(), Int16(16),
                    \Query<ModernAllTypesObject>.objectCol.mapOptInt16)
        validateAverage("mapOptInt32", Int32?.average(), Int32(32),
                    \Query<ModernAllTypesObject>.objectCol.mapOptInt32)
        validateAverage("mapOptInt64", Int64?.average(), Int64(64),
                    \Query<ModernAllTypesObject>.objectCol.mapOptInt64)
        validateAverage("mapOptFloat", Float?.average(), Float(5.55444333),
                    \Query<ModernAllTypesObject>.objectCol.mapOptFloat)
        validateAverage("mapOptDouble", Double?.average(), 123.456,
                    \Query<ModernAllTypesObject>.objectCol.mapOptDouble)
        validateAverage("mapOptDecimal", Decimal128?.average(), Decimal128(123.456),
                    \Query<ModernAllTypesObject>.objectCol.mapOptDecimal)
        validateAverage("mapIntOpt", EnumInt?.average(), EnumInt.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapIntOpt.rawValue)
        validateAverage("mapInt8Opt", EnumInt8?.average(), EnumInt8.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt8Opt.rawValue)
        validateAverage("mapInt16Opt", EnumInt16?.average(), EnumInt16.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt16Opt.rawValue)
        validateAverage("mapInt32Opt", EnumInt32?.average(), EnumInt32.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt32Opt.rawValue)
        validateAverage("mapInt64Opt", EnumInt64?.average(), EnumInt64.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt64Opt.rawValue)
        validateAverage("mapFloatOpt", EnumFloat?.average(), EnumFloat.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapFloatOpt.rawValue)
        validateAverage("mapDoubleOpt", EnumDouble?.average(), EnumDouble.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapDoubleOpt.rawValue)
    }

    private func validateSum<Root: Object, T: RealmCollection>(_ name: String, _ sum: T.Element, _ min: T.Element, _ lhs: (Query<Root>) -> Query<T>)
            where T.Element: _Persistable, T.Element.PersistedType: _QueryNumeric, T.Element: QueryValue {
        assertQuery(Root.self, "(objectCol.\(name).@sum == %@)", sum, count: 1) {
            lhs($0).sum == sum
        }
        assertQuery(Root.self, "(objectCol.\(name).@sum == %@)", min, count: 0) {
            lhs($0).sum == min
        }
        assertQuery(Root.self, "(objectCol.\(name).@sum != %@)", sum, count: 1) {
            lhs($0).sum != sum
        }
        assertQuery(Root.self, "(objectCol.\(name).@sum != %@)", min, count: 2) {
            lhs($0).sum != min
        }
        assertQuery(Root.self, "(objectCol.\(name).@sum > %@)", sum, count: 0) {
            lhs($0).sum > sum
        }
        assertQuery(Root.self, "(objectCol.\(name).@sum > %@)", min, count: 1) {
            lhs($0).sum > min
        }
        assertQuery(Root.self, "(objectCol.\(name).@sum < %@)", sum, count: 0 + 1) {
            lhs($0).sum < sum
        }
        assertQuery(Root.self, "(objectCol.\(name).@sum >= %@)", sum, count: 1) {
            lhs($0).sum >= sum
        }
        assertQuery(Root.self, "(objectCol.\(name).@sum <= %@)", sum, count: 1 + 1) {
            lhs($0).sum <= sum
        }
    }

    private func validateSum<Root: Object, T: RealmKeyedCollection>(_ name: String, _ sum: T.Value, _ min: T.Value, _ lhs: (Query<Root>) -> Query<T>)
            where T.Value: _Persistable, T.Value.PersistedType: _QueryNumeric, T.Value: QueryValue {
        assertQuery(Root.self, "(objectCol.\(name).@sum == %@)", sum, count: 1) {
            lhs($0).sum == sum
        }
        assertQuery(Root.self, "(objectCol.\(name).@sum == %@)", min, count: 0) {
            lhs($0).sum == min
        }
        assertQuery(Root.self, "(objectCol.\(name).@sum != %@)", sum, count: 1) {
            lhs($0).sum != sum
        }
        assertQuery(Root.self, "(objectCol.\(name).@sum != %@)", min, count: 2) {
            lhs($0).sum != min
        }
        assertQuery(Root.self, "(objectCol.\(name).@sum > %@)", sum, count: 0) {
            lhs($0).sum > sum
        }
        assertQuery(Root.self, "(objectCol.\(name).@sum > %@)", min, count: 1) {
            lhs($0).sum > min
        }
        assertQuery(Root.self, "(objectCol.\(name).@sum < %@)", sum, count: 0 + 1) {
            lhs($0).sum < sum
        }
        assertQuery(Root.self, "(objectCol.\(name).@sum >= %@)", sum, count: 1) {
            lhs($0).sum >= sum
        }
        assertQuery(Root.self, "(objectCol.\(name).@sum <= %@)", sum, count: 1 + 1) {
            lhs($0).sum <= sum
        }
    }

    func testCollectionAggregatesSum() {
        initLinkedCollectionAggregatesObject()

        validateSum("arrayInt", Int.sum(), 5,
                    \Query<ModernAllTypesObject>.objectCol.arrayInt)
        validateSum("arrayInt8", Int8.sum(), Int8(8),
                    \Query<ModernAllTypesObject>.objectCol.arrayInt8)
        validateSum("arrayInt16", Int16.sum(), Int16(16),
                    \Query<ModernAllTypesObject>.objectCol.arrayInt16)
        validateSum("arrayInt32", Int32.sum(), Int32(32),
                    \Query<ModernAllTypesObject>.objectCol.arrayInt32)
        validateSum("arrayInt64", Int64.sum(), Int64(64),
                    \Query<ModernAllTypesObject>.objectCol.arrayInt64)
        validateSum("arrayFloat", Float.sum(), Float(5.55444333),
                    \Query<ModernAllTypesObject>.objectCol.arrayFloat)
        validateSum("arrayDouble", Double.sum(), 123.456,
                    \Query<ModernAllTypesObject>.objectCol.arrayDouble)
        validateSum("arrayDecimal", Decimal128.sum(), Decimal128(123.456),
                    \Query<ModernAllTypesObject>.objectCol.arrayDecimal)
        validateSum("listInt", EnumInt.sum(), EnumInt.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt.rawValue)
        validateSum("listInt8", EnumInt8.sum(), EnumInt8.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt8.rawValue)
        validateSum("listInt16", EnumInt16.sum(), EnumInt16.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt16.rawValue)
        validateSum("listInt32", EnumInt32.sum(), EnumInt32.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt32.rawValue)
        validateSum("listInt64", EnumInt64.sum(), EnumInt64.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt64.rawValue)
        validateSum("listFloat", EnumFloat.sum(), EnumFloat.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listFloat.rawValue)
        validateSum("listDouble", EnumDouble.sum(), EnumDouble.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listDouble.rawValue)
        validateSum("arrayOptInt", Int?.sum(), 5,
                    \Query<ModernAllTypesObject>.objectCol.arrayOptInt)
        validateSum("arrayOptInt8", Int8?.sum(), Int8(8),
                    \Query<ModernAllTypesObject>.objectCol.arrayOptInt8)
        validateSum("arrayOptInt16", Int16?.sum(), Int16(16),
                    \Query<ModernAllTypesObject>.objectCol.arrayOptInt16)
        validateSum("arrayOptInt32", Int32?.sum(), Int32(32),
                    \Query<ModernAllTypesObject>.objectCol.arrayOptInt32)
        validateSum("arrayOptInt64", Int64?.sum(), Int64(64),
                    \Query<ModernAllTypesObject>.objectCol.arrayOptInt64)
        validateSum("arrayOptFloat", Float?.sum(), Float(5.55444333),
                    \Query<ModernAllTypesObject>.objectCol.arrayOptFloat)
        validateSum("arrayOptDouble", Double?.sum(), 123.456,
                    \Query<ModernAllTypesObject>.objectCol.arrayOptDouble)
        validateSum("arrayOptDecimal", Decimal128?.sum(), Decimal128(123.456),
                    \Query<ModernAllTypesObject>.objectCol.arrayOptDecimal)
        validateSum("listIntOpt", EnumInt?.sum(), EnumInt.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listIntOpt.rawValue)
        validateSum("listInt8Opt", EnumInt8?.sum(), EnumInt8.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt8Opt.rawValue)
        validateSum("listInt16Opt", EnumInt16?.sum(), EnumInt16.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt16Opt.rawValue)
        validateSum("listInt32Opt", EnumInt32?.sum(), EnumInt32.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt32Opt.rawValue)
        validateSum("listInt64Opt", EnumInt64?.sum(), EnumInt64.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt64Opt.rawValue)
        validateSum("listFloatOpt", EnumFloat?.sum(), EnumFloat.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listFloatOpt.rawValue)
        validateSum("listDoubleOpt", EnumDouble?.sum(), EnumDouble.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listDoubleOpt.rawValue)
        validateSum("setInt", Int.sum(), 5,
                    \Query<ModernAllTypesObject>.objectCol.setInt)
        validateSum("setInt8", Int8.sum(), Int8(8),
                    \Query<ModernAllTypesObject>.objectCol.setInt8)
        validateSum("setInt16", Int16.sum(), Int16(16),
                    \Query<ModernAllTypesObject>.objectCol.setInt16)
        validateSum("setInt32", Int32.sum(), Int32(32),
                    \Query<ModernAllTypesObject>.objectCol.setInt32)
        validateSum("setInt64", Int64.sum(), Int64(64),
                    \Query<ModernAllTypesObject>.objectCol.setInt64)
        validateSum("setFloat", Float.sum(), Float(5.55444333),
                    \Query<ModernAllTypesObject>.objectCol.setFloat)
        validateSum("setDouble", Double.sum(), 123.456,
                    \Query<ModernAllTypesObject>.objectCol.setDouble)
        validateSum("setDecimal", Decimal128.sum(), Decimal128(123.456),
                    \Query<ModernAllTypesObject>.objectCol.setDecimal)
        validateSum("setInt", EnumInt.sum(), EnumInt.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt.rawValue)
        validateSum("setInt8", EnumInt8.sum(), EnumInt8.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt8.rawValue)
        validateSum("setInt16", EnumInt16.sum(), EnumInt16.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt16.rawValue)
        validateSum("setInt32", EnumInt32.sum(), EnumInt32.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt32.rawValue)
        validateSum("setInt64", EnumInt64.sum(), EnumInt64.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt64.rawValue)
        validateSum("setFloat", EnumFloat.sum(), EnumFloat.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setFloat.rawValue)
        validateSum("setDouble", EnumDouble.sum(), EnumDouble.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setDouble.rawValue)
        validateSum("setOptInt", Int?.sum(), 5,
                    \Query<ModernAllTypesObject>.objectCol.setOptInt)
        validateSum("setOptInt8", Int8?.sum(), Int8(8),
                    \Query<ModernAllTypesObject>.objectCol.setOptInt8)
        validateSum("setOptInt16", Int16?.sum(), Int16(16),
                    \Query<ModernAllTypesObject>.objectCol.setOptInt16)
        validateSum("setOptInt32", Int32?.sum(), Int32(32),
                    \Query<ModernAllTypesObject>.objectCol.setOptInt32)
        validateSum("setOptInt64", Int64?.sum(), Int64(64),
                    \Query<ModernAllTypesObject>.objectCol.setOptInt64)
        validateSum("setOptFloat", Float?.sum(), Float(5.55444333),
                    \Query<ModernAllTypesObject>.objectCol.setOptFloat)
        validateSum("setOptDouble", Double?.sum(), 123.456,
                    \Query<ModernAllTypesObject>.objectCol.setOptDouble)
        validateSum("setOptDecimal", Decimal128?.sum(), Decimal128(123.456),
                    \Query<ModernAllTypesObject>.objectCol.setOptDecimal)
        validateSum("setIntOpt", EnumInt?.sum(), EnumInt.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setIntOpt.rawValue)
        validateSum("setInt8Opt", EnumInt8?.sum(), EnumInt8.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt8Opt.rawValue)
        validateSum("setInt16Opt", EnumInt16?.sum(), EnumInt16.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt16Opt.rawValue)
        validateSum("setInt32Opt", EnumInt32?.sum(), EnumInt32.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt32Opt.rawValue)
        validateSum("setInt64Opt", EnumInt64?.sum(), EnumInt64.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt64Opt.rawValue)
        validateSum("setFloatOpt", EnumFloat?.sum(), EnumFloat.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setFloatOpt.rawValue)
        validateSum("setDoubleOpt", EnumDouble?.sum(), EnumDouble.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setDoubleOpt.rawValue)
        validateSum("mapInt", Int.sum(), 5,
                    \Query<ModernAllTypesObject>.objectCol.mapInt)
        validateSum("mapInt8", Int8.sum(), Int8(8),
                    \Query<ModernAllTypesObject>.objectCol.mapInt8)
        validateSum("mapInt16", Int16.sum(), Int16(16),
                    \Query<ModernAllTypesObject>.objectCol.mapInt16)
        validateSum("mapInt32", Int32.sum(), Int32(32),
                    \Query<ModernAllTypesObject>.objectCol.mapInt32)
        validateSum("mapInt64", Int64.sum(), Int64(64),
                    \Query<ModernAllTypesObject>.objectCol.mapInt64)
        validateSum("mapFloat", Float.sum(), Float(5.55444333),
                    \Query<ModernAllTypesObject>.objectCol.mapFloat)
        validateSum("mapDouble", Double.sum(), 123.456,
                    \Query<ModernAllTypesObject>.objectCol.mapDouble)
        validateSum("mapDecimal", Decimal128.sum(), Decimal128(123.456),
                    \Query<ModernAllTypesObject>.objectCol.mapDecimal)
        validateSum("mapInt", EnumInt.sum(), EnumInt.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt.rawValue)
        validateSum("mapInt8", EnumInt8.sum(), EnumInt8.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt8.rawValue)
        validateSum("mapInt16", EnumInt16.sum(), EnumInt16.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt16.rawValue)
        validateSum("mapInt32", EnumInt32.sum(), EnumInt32.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt32.rawValue)
        validateSum("mapInt64", EnumInt64.sum(), EnumInt64.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt64.rawValue)
        validateSum("mapFloat", EnumFloat.sum(), EnumFloat.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapFloat.rawValue)
        validateSum("mapDouble", EnumDouble.sum(), EnumDouble.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapDouble.rawValue)
        validateSum("mapOptInt", Int?.sum(), 5,
                    \Query<ModernAllTypesObject>.objectCol.mapOptInt)
        validateSum("mapOptInt8", Int8?.sum(), Int8(8),
                    \Query<ModernAllTypesObject>.objectCol.mapOptInt8)
        validateSum("mapOptInt16", Int16?.sum(), Int16(16),
                    \Query<ModernAllTypesObject>.objectCol.mapOptInt16)
        validateSum("mapOptInt32", Int32?.sum(), Int32(32),
                    \Query<ModernAllTypesObject>.objectCol.mapOptInt32)
        validateSum("mapOptInt64", Int64?.sum(), Int64(64),
                    \Query<ModernAllTypesObject>.objectCol.mapOptInt64)
        validateSum("mapOptFloat", Float?.sum(), Float(5.55444333),
                    \Query<ModernAllTypesObject>.objectCol.mapOptFloat)
        validateSum("mapOptDouble", Double?.sum(), 123.456,
                    \Query<ModernAllTypesObject>.objectCol.mapOptDouble)
        validateSum("mapOptDecimal", Decimal128?.sum(), Decimal128(123.456),
                    \Query<ModernAllTypesObject>.objectCol.mapOptDecimal)
        validateSum("mapIntOpt", EnumInt?.sum(), EnumInt.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapIntOpt.rawValue)
        validateSum("mapInt8Opt", EnumInt8?.sum(), EnumInt8.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt8Opt.rawValue)
        validateSum("mapInt16Opt", EnumInt16?.sum(), EnumInt16.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt16Opt.rawValue)
        validateSum("mapInt32Opt", EnumInt32?.sum(), EnumInt32.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt32Opt.rawValue)
        validateSum("mapInt64Opt", EnumInt64?.sum(), EnumInt64.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt64Opt.rawValue)
        validateSum("mapFloatOpt", EnumFloat?.sum(), EnumFloat.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapFloatOpt.rawValue)
        validateSum("mapDoubleOpt", EnumDouble?.sum(), EnumDouble.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapDoubleOpt.rawValue)
    }


    private func validateMin<Root: Object, T: RealmCollection>(_ name: String, min: T.Element, max: T.Element, _ lhs: (Query<Root>) -> Query<T>)
            where T.Element: _Persistable, T.Element.PersistedType: _QueryNumeric, T.Element: QueryValue {
        assertQuery(Root.self, "(objectCol.\(name).@min == %@)", min, count: 1) {
            lhs($0).min == min
        }
        assertQuery(Root.self, "(objectCol.\(name).@min == %@)", max, count: 0) {
            lhs($0).min == max
        }
        assertQuery(Root.self, "(objectCol.\(name).@min != %@)", min, count: 1) {
            lhs($0).min != min
        }
        assertQuery(Root.self, "(objectCol.\(name).@min != %@)", max, count: 2) {
            lhs($0).min != max
        }
        assertQuery(Root.self, "(objectCol.\(name).@min > %@)", min, count: 0) {
            lhs($0).min > min
        }
        assertQuery(Root.self, "(objectCol.\(name).@min < %@)", min, count: 0) {
            lhs($0).min < min
        }
        assertQuery(Root.self, "(objectCol.\(name).@min >= %@)", min, count: 1) {
            lhs($0).min >= min
        }
        assertQuery(Root.self, "(objectCol.\(name).@min <= %@)", min, count: 1) {
            lhs($0).min <= min
        }
    }

    private func validateMin<Root: Object, T: RealmKeyedCollection>(_ name: String, min: T.Value, max: T.Value, _ lhs: (Query<Root>) -> Query<T>)
            where T.Value: _Persistable, T.Value.PersistedType: _QueryNumeric, T.Value: QueryValue {
        assertQuery(Root.self, "(objectCol.\(name).@min == %@)", min, count: 1) {
            lhs($0).min == min
        }
        assertQuery(Root.self, "(objectCol.\(name).@min == %@)", max, count: 0) {
            lhs($0).min == max
        }
        assertQuery(Root.self, "(objectCol.\(name).@min != %@)", min, count: 1) {
            lhs($0).min != min
        }
        assertQuery(Root.self, "(objectCol.\(name).@min != %@)", max, count: 2) {
            lhs($0).min != max
        }
        assertQuery(Root.self, "(objectCol.\(name).@min > %@)", min, count: 0) {
            lhs($0).min > min
        }
        assertQuery(Root.self, "(objectCol.\(name).@min < %@)", min, count: 0) {
            lhs($0).min < min
        }
        assertQuery(Root.self, "(objectCol.\(name).@min >= %@)", min, count: 1) {
            lhs($0).min >= min
        }
        assertQuery(Root.self, "(objectCol.\(name).@min <= %@)", min, count: 1) {
            lhs($0).min <= min
        }
    }

    func testCollectionAggregatesMin() {
        initLinkedCollectionAggregatesObject()

        validateMin("arrayInt", min: 5, max: 7,
                    \Query<ModernAllTypesObject>.objectCol.arrayInt)
        validateMin("arrayInt8", min: Int8(8), max: Int8(10),
                    \Query<ModernAllTypesObject>.objectCol.arrayInt8)
        validateMin("arrayInt16", min: Int16(16), max: Int16(18),
                    \Query<ModernAllTypesObject>.objectCol.arrayInt16)
        validateMin("arrayInt32", min: Int32(32), max: Int32(34),
                    \Query<ModernAllTypesObject>.objectCol.arrayInt32)
        validateMin("arrayInt64", min: Int64(64), max: Int64(66),
                    \Query<ModernAllTypesObject>.objectCol.arrayInt64)
        validateMin("arrayFloat", min: Float(5.55444333), max: Float(7.55444333),
                    \Query<ModernAllTypesObject>.objectCol.arrayFloat)
        validateMin("arrayDouble", min: 123.456, max: 345.678,
                    \Query<ModernAllTypesObject>.objectCol.arrayDouble)
        validateMin("arrayDecimal", min: Decimal128(123.456), max: Decimal128(345.678),
                    \Query<ModernAllTypesObject>.objectCol.arrayDecimal)
        validateMin("listInt", min: EnumInt.value1.rawValue, max: EnumInt.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt.rawValue)
        validateMin("listInt8", min: EnumInt8.value1.rawValue, max: EnumInt8.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt8.rawValue)
        validateMin("listInt16", min: EnumInt16.value1.rawValue, max: EnumInt16.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt16.rawValue)
        validateMin("listInt32", min: EnumInt32.value1.rawValue, max: EnumInt32.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt32.rawValue)
        validateMin("listInt64", min: EnumInt64.value1.rawValue, max: EnumInt64.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt64.rawValue)
        validateMin("listFloat", min: EnumFloat.value1.rawValue, max: EnumFloat.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listFloat.rawValue)
        validateMin("listDouble", min: EnumDouble.value1.rawValue, max: EnumDouble.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listDouble.rawValue)
        validateMin("arrayOptInt", min: 5, max: 7,
                    \Query<ModernAllTypesObject>.objectCol.arrayOptInt)
        validateMin("arrayOptInt8", min: Int8(8), max: Int8(10),
                    \Query<ModernAllTypesObject>.objectCol.arrayOptInt8)
        validateMin("arrayOptInt16", min: Int16(16), max: Int16(18),
                    \Query<ModernAllTypesObject>.objectCol.arrayOptInt16)
        validateMin("arrayOptInt32", min: Int32(32), max: Int32(34),
                    \Query<ModernAllTypesObject>.objectCol.arrayOptInt32)
        validateMin("arrayOptInt64", min: Int64(64), max: Int64(66),
                    \Query<ModernAllTypesObject>.objectCol.arrayOptInt64)
        validateMin("arrayOptFloat", min: Float(5.55444333), max: Float(7.55444333),
                    \Query<ModernAllTypesObject>.objectCol.arrayOptFloat)
        validateMin("arrayOptDouble", min: 123.456, max: 345.678,
                    \Query<ModernAllTypesObject>.objectCol.arrayOptDouble)
        validateMin("arrayOptDecimal", min: Decimal128(123.456), max: Decimal128(345.678),
                    \Query<ModernAllTypesObject>.objectCol.arrayOptDecimal)
        validateMin("listIntOpt", min: EnumInt.value1.rawValue, max: EnumInt.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listIntOpt.rawValue)
        validateMin("listInt8Opt", min: EnumInt8.value1.rawValue, max: EnumInt8.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt8Opt.rawValue)
        validateMin("listInt16Opt", min: EnumInt16.value1.rawValue, max: EnumInt16.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt16Opt.rawValue)
        validateMin("listInt32Opt", min: EnumInt32.value1.rawValue, max: EnumInt32.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt32Opt.rawValue)
        validateMin("listInt64Opt", min: EnumInt64.value1.rawValue, max: EnumInt64.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt64Opt.rawValue)
        validateMin("listFloatOpt", min: EnumFloat.value1.rawValue, max: EnumFloat.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listFloatOpt.rawValue)
        validateMin("listDoubleOpt", min: EnumDouble.value1.rawValue, max: EnumDouble.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listDoubleOpt.rawValue)
        validateMin("setInt", min: 5, max: 7,
                    \Query<ModernAllTypesObject>.objectCol.setInt)
        validateMin("setInt8", min: Int8(8), max: Int8(10),
                    \Query<ModernAllTypesObject>.objectCol.setInt8)
        validateMin("setInt16", min: Int16(16), max: Int16(18),
                    \Query<ModernAllTypesObject>.objectCol.setInt16)
        validateMin("setInt32", min: Int32(32), max: Int32(34),
                    \Query<ModernAllTypesObject>.objectCol.setInt32)
        validateMin("setInt64", min: Int64(64), max: Int64(66),
                    \Query<ModernAllTypesObject>.objectCol.setInt64)
        validateMin("setFloat", min: Float(5.55444333), max: Float(7.55444333),
                    \Query<ModernAllTypesObject>.objectCol.setFloat)
        validateMin("setDouble", min: 123.456, max: 345.678,
                    \Query<ModernAllTypesObject>.objectCol.setDouble)
        validateMin("setDecimal", min: Decimal128(123.456), max: Decimal128(345.678),
                    \Query<ModernAllTypesObject>.objectCol.setDecimal)
        validateMin("setInt", min: EnumInt.value1.rawValue, max: EnumInt.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt.rawValue)
        validateMin("setInt8", min: EnumInt8.value1.rawValue, max: EnumInt8.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt8.rawValue)
        validateMin("setInt16", min: EnumInt16.value1.rawValue, max: EnumInt16.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt16.rawValue)
        validateMin("setInt32", min: EnumInt32.value1.rawValue, max: EnumInt32.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt32.rawValue)
        validateMin("setInt64", min: EnumInt64.value1.rawValue, max: EnumInt64.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt64.rawValue)
        validateMin("setFloat", min: EnumFloat.value1.rawValue, max: EnumFloat.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setFloat.rawValue)
        validateMin("setDouble", min: EnumDouble.value1.rawValue, max: EnumDouble.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setDouble.rawValue)
        validateMin("setOptInt", min: 5, max: 7,
                    \Query<ModernAllTypesObject>.objectCol.setOptInt)
        validateMin("setOptInt8", min: Int8(8), max: Int8(10),
                    \Query<ModernAllTypesObject>.objectCol.setOptInt8)
        validateMin("setOptInt16", min: Int16(16), max: Int16(18),
                    \Query<ModernAllTypesObject>.objectCol.setOptInt16)
        validateMin("setOptInt32", min: Int32(32), max: Int32(34),
                    \Query<ModernAllTypesObject>.objectCol.setOptInt32)
        validateMin("setOptInt64", min: Int64(64), max: Int64(66),
                    \Query<ModernAllTypesObject>.objectCol.setOptInt64)
        validateMin("setOptFloat", min: Float(5.55444333), max: Float(7.55444333),
                    \Query<ModernAllTypesObject>.objectCol.setOptFloat)
        validateMin("setOptDouble", min: 123.456, max: 345.678,
                    \Query<ModernAllTypesObject>.objectCol.setOptDouble)
        validateMin("setOptDecimal", min: Decimal128(123.456), max: Decimal128(345.678),
                    \Query<ModernAllTypesObject>.objectCol.setOptDecimal)
        validateMin("setIntOpt", min: EnumInt.value1.rawValue, max: EnumInt.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setIntOpt.rawValue)
        validateMin("setInt8Opt", min: EnumInt8.value1.rawValue, max: EnumInt8.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt8Opt.rawValue)
        validateMin("setInt16Opt", min: EnumInt16.value1.rawValue, max: EnumInt16.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt16Opt.rawValue)
        validateMin("setInt32Opt", min: EnumInt32.value1.rawValue, max: EnumInt32.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt32Opt.rawValue)
        validateMin("setInt64Opt", min: EnumInt64.value1.rawValue, max: EnumInt64.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt64Opt.rawValue)
        validateMin("setFloatOpt", min: EnumFloat.value1.rawValue, max: EnumFloat.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setFloatOpt.rawValue)
        validateMin("setDoubleOpt", min: EnumDouble.value1.rawValue, max: EnumDouble.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setDoubleOpt.rawValue)
        validateMin("mapInt", min: 5, max: 7,
                    \Query<ModernAllTypesObject>.objectCol.mapInt)
        validateMin("mapInt8", min: Int8(8), max: Int8(10),
                    \Query<ModernAllTypesObject>.objectCol.mapInt8)
        validateMin("mapInt16", min: Int16(16), max: Int16(18),
                    \Query<ModernAllTypesObject>.objectCol.mapInt16)
        validateMin("mapInt32", min: Int32(32), max: Int32(34),
                    \Query<ModernAllTypesObject>.objectCol.mapInt32)
        validateMin("mapInt64", min: Int64(64), max: Int64(66),
                    \Query<ModernAllTypesObject>.objectCol.mapInt64)
        validateMin("mapFloat", min: Float(5.55444333), max: Float(7.55444333),
                    \Query<ModernAllTypesObject>.objectCol.mapFloat)
        validateMin("mapDouble", min: 123.456, max: 345.678,
                    \Query<ModernAllTypesObject>.objectCol.mapDouble)
        validateMin("mapDecimal", min: Decimal128(123.456), max: Decimal128(345.678),
                    \Query<ModernAllTypesObject>.objectCol.mapDecimal)
        validateMin("mapInt", min: EnumInt.value1.rawValue, max: EnumInt.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt.rawValue)
        validateMin("mapInt8", min: EnumInt8.value1.rawValue, max: EnumInt8.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt8.rawValue)
        validateMin("mapInt16", min: EnumInt16.value1.rawValue, max: EnumInt16.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt16.rawValue)
        validateMin("mapInt32", min: EnumInt32.value1.rawValue, max: EnumInt32.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt32.rawValue)
        validateMin("mapInt64", min: EnumInt64.value1.rawValue, max: EnumInt64.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt64.rawValue)
        validateMin("mapFloat", min: EnumFloat.value1.rawValue, max: EnumFloat.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapFloat.rawValue)
        validateMin("mapDouble", min: EnumDouble.value1.rawValue, max: EnumDouble.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapDouble.rawValue)
        validateMin("mapOptInt", min: 5, max: 7,
                    \Query<ModernAllTypesObject>.objectCol.mapOptInt)
        validateMin("mapOptInt8", min: Int8(8), max: Int8(10),
                    \Query<ModernAllTypesObject>.objectCol.mapOptInt8)
        validateMin("mapOptInt16", min: Int16(16), max: Int16(18),
                    \Query<ModernAllTypesObject>.objectCol.mapOptInt16)
        validateMin("mapOptInt32", min: Int32(32), max: Int32(34),
                    \Query<ModernAllTypesObject>.objectCol.mapOptInt32)
        validateMin("mapOptInt64", min: Int64(64), max: Int64(66),
                    \Query<ModernAllTypesObject>.objectCol.mapOptInt64)
        validateMin("mapOptFloat", min: Float(5.55444333), max: Float(7.55444333),
                    \Query<ModernAllTypesObject>.objectCol.mapOptFloat)
        validateMin("mapOptDouble", min: 123.456, max: 345.678,
                    \Query<ModernAllTypesObject>.objectCol.mapOptDouble)
        validateMin("mapOptDecimal", min: Decimal128(123.456), max: Decimal128(345.678),
                    \Query<ModernAllTypesObject>.objectCol.mapOptDecimal)
        validateMin("mapIntOpt", min: EnumInt.value1.rawValue, max: EnumInt.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapIntOpt.rawValue)
        validateMin("mapInt8Opt", min: EnumInt8.value1.rawValue, max: EnumInt8.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt8Opt.rawValue)
        validateMin("mapInt16Opt", min: EnumInt16.value1.rawValue, max: EnumInt16.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt16Opt.rawValue)
        validateMin("mapInt32Opt", min: EnumInt32.value1.rawValue, max: EnumInt32.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt32Opt.rawValue)
        validateMin("mapInt64Opt", min: EnumInt64.value1.rawValue, max: EnumInt64.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt64Opt.rawValue)
        validateMin("mapFloatOpt", min: EnumFloat.value1.rawValue, max: EnumFloat.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapFloatOpt.rawValue)
        validateMin("mapDoubleOpt", min: EnumDouble.value1.rawValue, max: EnumDouble.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapDoubleOpt.rawValue)
    }

    private func validateMax<Root: Object, T: RealmCollection>(_ name: String, min: T.Element, max: T.Element, _ lhs: (Query<Root>) -> Query<T>)
            where T.Element: _Persistable, T.Element.PersistedType: _QueryNumeric, T.Element: QueryValue {
        assertQuery(Root.self, "(objectCol.\(name).@max == %@)", max, count: 1) {
            lhs($0).max == max
        }
        assertQuery(Root.self, "(objectCol.\(name).@max == %@)", min, count: 0) {
            lhs($0).max == min
        }
        assertQuery(Root.self, "(objectCol.\(name).@max != %@)", max, count: 1) {
            lhs($0).max != max
        }
        assertQuery(Root.self, "(objectCol.\(name).@max != %@)", min, count: 2) {
            lhs($0).max != min
        }
        assertQuery(Root.self, "(objectCol.\(name).@max > %@)", max, count: 0) {
            lhs($0).max > max
        }
        assertQuery(Root.self, "(objectCol.\(name).@max < %@)", max, count: 0) {
            lhs($0).max < max
        }
        assertQuery(Root.self, "(objectCol.\(name).@max >= %@)", max, count: 1) {
            lhs($0).max >= max
        }
        assertQuery(Root.self, "(objectCol.\(name).@max <= %@)", max, count: 1) {
            lhs($0).max <= max
        }
    }

    private func validateMax<Root: Object, T: RealmKeyedCollection>(_ name: String, min: T.Value, max: T.Value, _ lhs: (Query<Root>) -> Query<T>)
            where T.Value: _Persistable, T.Value.PersistedType: _QueryNumeric, T.Value: QueryValue {
        assertQuery(Root.self, "(objectCol.\(name).@max == %@)", max, count: 1) {
            lhs($0).max == max
        }
        assertQuery(Root.self, "(objectCol.\(name).@max == %@)", min, count: 0) {
            lhs($0).max == min
        }
        assertQuery(Root.self, "(objectCol.\(name).@max != %@)", max, count: 1) {
            lhs($0).max != max
        }
        assertQuery(Root.self, "(objectCol.\(name).@max != %@)", min, count: 2) {
            lhs($0).max != min
        }
        assertQuery(Root.self, "(objectCol.\(name).@max > %@)", max, count: 0) {
            lhs($0).max > max
        }
        assertQuery(Root.self, "(objectCol.\(name).@max < %@)", max, count: 0) {
            lhs($0).max < max
        }
        assertQuery(Root.self, "(objectCol.\(name).@max >= %@)", max, count: 1) {
            lhs($0).max >= max
        }
        assertQuery(Root.self, "(objectCol.\(name).@max <= %@)", max, count: 1) {
            lhs($0).max <= max
        }
    }

    func testCollectionAggregatesMax() {
        initLinkedCollectionAggregatesObject()

        validateMax("arrayInt", min: 5, max: 7,
                    \Query<ModernAllTypesObject>.objectCol.arrayInt)
        validateMax("arrayInt8", min: Int8(8), max: Int8(10),
                    \Query<ModernAllTypesObject>.objectCol.arrayInt8)
        validateMax("arrayInt16", min: Int16(16), max: Int16(18),
                    \Query<ModernAllTypesObject>.objectCol.arrayInt16)
        validateMax("arrayInt32", min: Int32(32), max: Int32(34),
                    \Query<ModernAllTypesObject>.objectCol.arrayInt32)
        validateMax("arrayInt64", min: Int64(64), max: Int64(66),
                    \Query<ModernAllTypesObject>.objectCol.arrayInt64)
        validateMax("arrayFloat", min: Float(5.55444333), max: Float(7.55444333),
                    \Query<ModernAllTypesObject>.objectCol.arrayFloat)
        validateMax("arrayDouble", min: 123.456, max: 345.678,
                    \Query<ModernAllTypesObject>.objectCol.arrayDouble)
        validateMax("arrayDecimal", min: Decimal128(123.456), max: Decimal128(345.678),
                    \Query<ModernAllTypesObject>.objectCol.arrayDecimal)
        validateMax("listInt", min: EnumInt.value1.rawValue, max: EnumInt.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt.rawValue)
        validateMax("listInt8", min: EnumInt8.value1.rawValue, max: EnumInt8.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt8.rawValue)
        validateMax("listInt16", min: EnumInt16.value1.rawValue, max: EnumInt16.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt16.rawValue)
        validateMax("listInt32", min: EnumInt32.value1.rawValue, max: EnumInt32.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt32.rawValue)
        validateMax("listInt64", min: EnumInt64.value1.rawValue, max: EnumInt64.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt64.rawValue)
        validateMax("listFloat", min: EnumFloat.value1.rawValue, max: EnumFloat.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listFloat.rawValue)
        validateMax("listDouble", min: EnumDouble.value1.rawValue, max: EnumDouble.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listDouble.rawValue)
        validateMax("arrayOptInt", min: 5, max: 7,
                    \Query<ModernAllTypesObject>.objectCol.arrayOptInt)
        validateMax("arrayOptInt8", min: Int8(8), max: Int8(10),
                    \Query<ModernAllTypesObject>.objectCol.arrayOptInt8)
        validateMax("arrayOptInt16", min: Int16(16), max: Int16(18),
                    \Query<ModernAllTypesObject>.objectCol.arrayOptInt16)
        validateMax("arrayOptInt32", min: Int32(32), max: Int32(34),
                    \Query<ModernAllTypesObject>.objectCol.arrayOptInt32)
        validateMax("arrayOptInt64", min: Int64(64), max: Int64(66),
                    \Query<ModernAllTypesObject>.objectCol.arrayOptInt64)
        validateMax("arrayOptFloat", min: Float(5.55444333), max: Float(7.55444333),
                    \Query<ModernAllTypesObject>.objectCol.arrayOptFloat)
        validateMax("arrayOptDouble", min: 123.456, max: 345.678,
                    \Query<ModernAllTypesObject>.objectCol.arrayOptDouble)
        validateMax("arrayOptDecimal", min: Decimal128(123.456), max: Decimal128(345.678),
                    \Query<ModernAllTypesObject>.objectCol.arrayOptDecimal)
        validateMax("listIntOpt", min: EnumInt.value1.rawValue, max: EnumInt.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listIntOpt.rawValue)
        validateMax("listInt8Opt", min: EnumInt8.value1.rawValue, max: EnumInt8.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt8Opt.rawValue)
        validateMax("listInt16Opt", min: EnumInt16.value1.rawValue, max: EnumInt16.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt16Opt.rawValue)
        validateMax("listInt32Opt", min: EnumInt32.value1.rawValue, max: EnumInt32.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt32Opt.rawValue)
        validateMax("listInt64Opt", min: EnumInt64.value1.rawValue, max: EnumInt64.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt64Opt.rawValue)
        validateMax("listFloatOpt", min: EnumFloat.value1.rawValue, max: EnumFloat.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listFloatOpt.rawValue)
        validateMax("listDoubleOpt", min: EnumDouble.value1.rawValue, max: EnumDouble.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.listDoubleOpt.rawValue)
        validateMax("setInt", min: 5, max: 7,
                    \Query<ModernAllTypesObject>.objectCol.setInt)
        validateMax("setInt8", min: Int8(8), max: Int8(10),
                    \Query<ModernAllTypesObject>.objectCol.setInt8)
        validateMax("setInt16", min: Int16(16), max: Int16(18),
                    \Query<ModernAllTypesObject>.objectCol.setInt16)
        validateMax("setInt32", min: Int32(32), max: Int32(34),
                    \Query<ModernAllTypesObject>.objectCol.setInt32)
        validateMax("setInt64", min: Int64(64), max: Int64(66),
                    \Query<ModernAllTypesObject>.objectCol.setInt64)
        validateMax("setFloat", min: Float(5.55444333), max: Float(7.55444333),
                    \Query<ModernAllTypesObject>.objectCol.setFloat)
        validateMax("setDouble", min: 123.456, max: 345.678,
                    \Query<ModernAllTypesObject>.objectCol.setDouble)
        validateMax("setDecimal", min: Decimal128(123.456), max: Decimal128(345.678),
                    \Query<ModernAllTypesObject>.objectCol.setDecimal)
        validateMax("setInt", min: EnumInt.value1.rawValue, max: EnumInt.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt.rawValue)
        validateMax("setInt8", min: EnumInt8.value1.rawValue, max: EnumInt8.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt8.rawValue)
        validateMax("setInt16", min: EnumInt16.value1.rawValue, max: EnumInt16.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt16.rawValue)
        validateMax("setInt32", min: EnumInt32.value1.rawValue, max: EnumInt32.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt32.rawValue)
        validateMax("setInt64", min: EnumInt64.value1.rawValue, max: EnumInt64.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt64.rawValue)
        validateMax("setFloat", min: EnumFloat.value1.rawValue, max: EnumFloat.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setFloat.rawValue)
        validateMax("setDouble", min: EnumDouble.value1.rawValue, max: EnumDouble.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setDouble.rawValue)
        validateMax("setOptInt", min: 5, max: 7,
                    \Query<ModernAllTypesObject>.objectCol.setOptInt)
        validateMax("setOptInt8", min: Int8(8), max: Int8(10),
                    \Query<ModernAllTypesObject>.objectCol.setOptInt8)
        validateMax("setOptInt16", min: Int16(16), max: Int16(18),
                    \Query<ModernAllTypesObject>.objectCol.setOptInt16)
        validateMax("setOptInt32", min: Int32(32), max: Int32(34),
                    \Query<ModernAllTypesObject>.objectCol.setOptInt32)
        validateMax("setOptInt64", min: Int64(64), max: Int64(66),
                    \Query<ModernAllTypesObject>.objectCol.setOptInt64)
        validateMax("setOptFloat", min: Float(5.55444333), max: Float(7.55444333),
                    \Query<ModernAllTypesObject>.objectCol.setOptFloat)
        validateMax("setOptDouble", min: 123.456, max: 345.678,
                    \Query<ModernAllTypesObject>.objectCol.setOptDouble)
        validateMax("setOptDecimal", min: Decimal128(123.456), max: Decimal128(345.678),
                    \Query<ModernAllTypesObject>.objectCol.setOptDecimal)
        validateMax("setIntOpt", min: EnumInt.value1.rawValue, max: EnumInt.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setIntOpt.rawValue)
        validateMax("setInt8Opt", min: EnumInt8.value1.rawValue, max: EnumInt8.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt8Opt.rawValue)
        validateMax("setInt16Opt", min: EnumInt16.value1.rawValue, max: EnumInt16.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt16Opt.rawValue)
        validateMax("setInt32Opt", min: EnumInt32.value1.rawValue, max: EnumInt32.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt32Opt.rawValue)
        validateMax("setInt64Opt", min: EnumInt64.value1.rawValue, max: EnumInt64.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt64Opt.rawValue)
        validateMax("setFloatOpt", min: EnumFloat.value1.rawValue, max: EnumFloat.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setFloatOpt.rawValue)
        validateMax("setDoubleOpt", min: EnumDouble.value1.rawValue, max: EnumDouble.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.setDoubleOpt.rawValue)
        validateMax("mapInt", min: 5, max: 7,
                    \Query<ModernAllTypesObject>.objectCol.mapInt)
        validateMax("mapInt8", min: Int8(8), max: Int8(10),
                    \Query<ModernAllTypesObject>.objectCol.mapInt8)
        validateMax("mapInt16", min: Int16(16), max: Int16(18),
                    \Query<ModernAllTypesObject>.objectCol.mapInt16)
        validateMax("mapInt32", min: Int32(32), max: Int32(34),
                    \Query<ModernAllTypesObject>.objectCol.mapInt32)
        validateMax("mapInt64", min: Int64(64), max: Int64(66),
                    \Query<ModernAllTypesObject>.objectCol.mapInt64)
        validateMax("mapFloat", min: Float(5.55444333), max: Float(7.55444333),
                    \Query<ModernAllTypesObject>.objectCol.mapFloat)
        validateMax("mapDouble", min: 123.456, max: 345.678,
                    \Query<ModernAllTypesObject>.objectCol.mapDouble)
        validateMax("mapDecimal", min: Decimal128(123.456), max: Decimal128(345.678),
                    \Query<ModernAllTypesObject>.objectCol.mapDecimal)
        validateMax("mapInt", min: EnumInt.value1.rawValue, max: EnumInt.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt.rawValue)
        validateMax("mapInt8", min: EnumInt8.value1.rawValue, max: EnumInt8.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt8.rawValue)
        validateMax("mapInt16", min: EnumInt16.value1.rawValue, max: EnumInt16.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt16.rawValue)
        validateMax("mapInt32", min: EnumInt32.value1.rawValue, max: EnumInt32.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt32.rawValue)
        validateMax("mapInt64", min: EnumInt64.value1.rawValue, max: EnumInt64.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt64.rawValue)
        validateMax("mapFloat", min: EnumFloat.value1.rawValue, max: EnumFloat.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapFloat.rawValue)
        validateMax("mapDouble", min: EnumDouble.value1.rawValue, max: EnumDouble.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapDouble.rawValue)
        validateMax("mapOptInt", min: 5, max: 7,
                    \Query<ModernAllTypesObject>.objectCol.mapOptInt)
        validateMax("mapOptInt8", min: Int8(8), max: Int8(10),
                    \Query<ModernAllTypesObject>.objectCol.mapOptInt8)
        validateMax("mapOptInt16", min: Int16(16), max: Int16(18),
                    \Query<ModernAllTypesObject>.objectCol.mapOptInt16)
        validateMax("mapOptInt32", min: Int32(32), max: Int32(34),
                    \Query<ModernAllTypesObject>.objectCol.mapOptInt32)
        validateMax("mapOptInt64", min: Int64(64), max: Int64(66),
                    \Query<ModernAllTypesObject>.objectCol.mapOptInt64)
        validateMax("mapOptFloat", min: Float(5.55444333), max: Float(7.55444333),
                    \Query<ModernAllTypesObject>.objectCol.mapOptFloat)
        validateMax("mapOptDouble", min: 123.456, max: 345.678,
                    \Query<ModernAllTypesObject>.objectCol.mapOptDouble)
        validateMax("mapOptDecimal", min: Decimal128(123.456), max: Decimal128(345.678),
                    \Query<ModernAllTypesObject>.objectCol.mapOptDecimal)
        validateMax("mapIntOpt", min: EnumInt.value1.rawValue, max: EnumInt.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapIntOpt.rawValue)
        validateMax("mapInt8Opt", min: EnumInt8.value1.rawValue, max: EnumInt8.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt8Opt.rawValue)
        validateMax("mapInt16Opt", min: EnumInt16.value1.rawValue, max: EnumInt16.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt16Opt.rawValue)
        validateMax("mapInt32Opt", min: EnumInt32.value1.rawValue, max: EnumInt32.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt32Opt.rawValue)
        validateMax("mapInt64Opt", min: EnumInt64.value1.rawValue, max: EnumInt64.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt64Opt.rawValue)
        validateMax("mapFloatOpt", min: EnumFloat.value1.rawValue, max: EnumFloat.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapFloatOpt.rawValue)
        validateMax("mapDoubleOpt", min: EnumDouble.value1.rawValue, max: EnumDouble.value3.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.objectCol.mapDoubleOpt.rawValue)
    }


    // @Count

    private func validateCount<Root: Object, T: RealmCollection>(_ name: String, _ lhs: (Query<Root>) -> Query<T>) {
        assertQuery(Root.self, "(objectCol.\(name).@count == %@)", 3, count: 1) {
            lhs($0).count == 3
        }
        assertQuery(Root.self, "(objectCol.\(name).@count == %@)", 0, count: 1) {
            lhs($0).count == 0
        }
        assertQuery(Root.self, "(objectCol.\(name).@count != %@)", 3, count: 1) {
            lhs($0).count != 3
        }
        assertQuery(Root.self, "(objectCol.\(name).@count != %@)", 2, count: 2) {
            lhs($0).count != 2
        }
        assertQuery(Root.self, "(objectCol.\(name).@count < %@)", 3, count: 1) {
            lhs($0).count < 3
        }
        assertQuery(Root.self, "(objectCol.\(name).@count < %@)", 4, count: 2) {
            lhs($0).count < 4
        }
        assertQuery(Root.self, "(objectCol.\(name).@count > %@)", 2, count: 1) {
            lhs($0).count > 2
        }
        assertQuery(Root.self, "(objectCol.\(name).@count > %@)", 3, count: 0) {
            lhs($0).count > 3
        }
        assertQuery(Root.self, "(objectCol.\(name).@count <= %@)", 2, count: 1) {
            lhs($0).count <= 2
        }
        assertQuery(Root.self, "(objectCol.\(name).@count <= %@)", 3, count: 2) {
            lhs($0).count <= 3
        }
        assertQuery(Root.self, "(objectCol.\(name).@count >= %@)", 3, count: 1) {
            lhs($0).count >= 3
        }
        assertQuery(Root.self, "(objectCol.\(name).@count >= %@)", 4, count: 0) {
            lhs($0).count >= 4
        }
    }
    private func validateCount<Root: Object, T: RealmKeyedCollection>(_ name: String, _ lhs: (Query<Root>) -> Query<T>) {
        assertQuery(Root.self, "(objectCol.\(name).@count == %@)", 3, count: 1) {
            lhs($0).count == 3
        }
        assertQuery(Root.self, "(objectCol.\(name).@count == %@)", 0, count: 1) {
            lhs($0).count == 0
        }
        assertQuery(Root.self, "(objectCol.\(name).@count != %@)", 3, count: 1) {
            lhs($0).count != 3
        }
        assertQuery(Root.self, "(objectCol.\(name).@count != %@)", 2, count: 2) {
            lhs($0).count != 2
        }
        assertQuery(Root.self, "(objectCol.\(name).@count < %@)", 3, count: 1) {
            lhs($0).count < 3
        }
        assertQuery(Root.self, "(objectCol.\(name).@count < %@)", 4, count: 2) {
            lhs($0).count < 4
        }
        assertQuery(Root.self, "(objectCol.\(name).@count > %@)", 2, count: 1) {
            lhs($0).count > 2
        }
        assertQuery(Root.self, "(objectCol.\(name).@count > %@)", 3, count: 0) {
            lhs($0).count > 3
        }
        assertQuery(Root.self, "(objectCol.\(name).@count <= %@)", 2, count: 1) {
            lhs($0).count <= 2
        }
        assertQuery(Root.self, "(objectCol.\(name).@count <= %@)", 3, count: 2) {
            lhs($0).count <= 3
        }
        assertQuery(Root.self, "(objectCol.\(name).@count >= %@)", 3, count: 1) {
            lhs($0).count >= 3
        }
        assertQuery(Root.self, "(objectCol.\(name).@count >= %@)", 4, count: 0) {
            lhs($0).count >= 4
        }
    }

    func testCollectionAggregatesCount() {
        initLinkedCollectionAggregatesObject()

        validateCount("arrayInt", \Query<ModernAllTypesObject>.objectCol.arrayInt)
        validateCount("arrayInt8", \Query<ModernAllTypesObject>.objectCol.arrayInt8)
        validateCount("arrayInt16", \Query<ModernAllTypesObject>.objectCol.arrayInt16)
        validateCount("arrayInt32", \Query<ModernAllTypesObject>.objectCol.arrayInt32)
        validateCount("arrayInt64", \Query<ModernAllTypesObject>.objectCol.arrayInt64)
        validateCount("arrayFloat", \Query<ModernAllTypesObject>.objectCol.arrayFloat)
        validateCount("arrayDouble", \Query<ModernAllTypesObject>.objectCol.arrayDouble)
        validateCount("arrayString", \Query<ModernAllTypesObject>.objectCol.arrayString)
        validateCount("arrayBinary", \Query<ModernAllTypesObject>.objectCol.arrayBinary)
        validateCount("arrayDate", \Query<ModernAllTypesObject>.objectCol.arrayDate)
        validateCount("arrayDecimal", \Query<ModernAllTypesObject>.objectCol.arrayDecimal)
        validateCount("arrayObjectId", \Query<ModernAllTypesObject>.objectCol.arrayObjectId)
        validateCount("arrayUuid", \Query<ModernAllTypesObject>.objectCol.arrayUuid)
        validateCount("arrayAny", \Query<ModernAllTypesObject>.objectCol.arrayAny)
        validateCount("listInt", \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt)
        validateCount("listInt8", \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt8)
        validateCount("listInt16", \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt16)
        validateCount("listInt32", \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt32)
        validateCount("listInt64", \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt64)
        validateCount("listFloat", \Query<LinkToModernCollectionsOfEnums>.objectCol.listFloat)
        validateCount("listDouble", \Query<LinkToModernCollectionsOfEnums>.objectCol.listDouble)
        validateCount("listString", \Query<LinkToModernCollectionsOfEnums>.objectCol.listString)
        validateCount("arrayOptInt", \Query<ModernAllTypesObject>.objectCol.arrayOptInt)
        validateCount("arrayOptInt8", \Query<ModernAllTypesObject>.objectCol.arrayOptInt8)
        validateCount("arrayOptInt16", \Query<ModernAllTypesObject>.objectCol.arrayOptInt16)
        validateCount("arrayOptInt32", \Query<ModernAllTypesObject>.objectCol.arrayOptInt32)
        validateCount("arrayOptInt64", \Query<ModernAllTypesObject>.objectCol.arrayOptInt64)
        validateCount("arrayOptFloat", \Query<ModernAllTypesObject>.objectCol.arrayOptFloat)
        validateCount("arrayOptDouble", \Query<ModernAllTypesObject>.objectCol.arrayOptDouble)
        validateCount("arrayOptString", \Query<ModernAllTypesObject>.objectCol.arrayOptString)
        validateCount("arrayOptBinary", \Query<ModernAllTypesObject>.objectCol.arrayOptBinary)
        validateCount("arrayOptDate", \Query<ModernAllTypesObject>.objectCol.arrayOptDate)
        validateCount("arrayOptDecimal", \Query<ModernAllTypesObject>.objectCol.arrayOptDecimal)
        validateCount("arrayOptObjectId", \Query<ModernAllTypesObject>.objectCol.arrayOptObjectId)
        validateCount("arrayOptUuid", \Query<ModernAllTypesObject>.objectCol.arrayOptUuid)
        validateCount("listIntOpt", \Query<LinkToModernCollectionsOfEnums>.objectCol.listIntOpt)
        validateCount("listInt8Opt", \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt8Opt)
        validateCount("listInt16Opt", \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt16Opt)
        validateCount("listInt32Opt", \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt32Opt)
        validateCount("listInt64Opt", \Query<LinkToModernCollectionsOfEnums>.objectCol.listInt64Opt)
        validateCount("listFloatOpt", \Query<LinkToModernCollectionsOfEnums>.objectCol.listFloatOpt)
        validateCount("listDoubleOpt", \Query<LinkToModernCollectionsOfEnums>.objectCol.listDoubleOpt)
        validateCount("listStringOpt", \Query<LinkToModernCollectionsOfEnums>.objectCol.listStringOpt)
        validateCount("setInt", \Query<ModernAllTypesObject>.objectCol.setInt)
        validateCount("setInt8", \Query<ModernAllTypesObject>.objectCol.setInt8)
        validateCount("setInt16", \Query<ModernAllTypesObject>.objectCol.setInt16)
        validateCount("setInt32", \Query<ModernAllTypesObject>.objectCol.setInt32)
        validateCount("setInt64", \Query<ModernAllTypesObject>.objectCol.setInt64)
        validateCount("setFloat", \Query<ModernAllTypesObject>.objectCol.setFloat)
        validateCount("setDouble", \Query<ModernAllTypesObject>.objectCol.setDouble)
        validateCount("setString", \Query<ModernAllTypesObject>.objectCol.setString)
        validateCount("setBinary", \Query<ModernAllTypesObject>.objectCol.setBinary)
        validateCount("setDate", \Query<ModernAllTypesObject>.objectCol.setDate)
        validateCount("setDecimal", \Query<ModernAllTypesObject>.objectCol.setDecimal)
        validateCount("setObjectId", \Query<ModernAllTypesObject>.objectCol.setObjectId)
        validateCount("setUuid", \Query<ModernAllTypesObject>.objectCol.setUuid)
        validateCount("setAny", \Query<ModernAllTypesObject>.objectCol.setAny)
        validateCount("setInt", \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt)
        validateCount("setInt8", \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt8)
        validateCount("setInt16", \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt16)
        validateCount("setInt32", \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt32)
        validateCount("setInt64", \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt64)
        validateCount("setFloat", \Query<LinkToModernCollectionsOfEnums>.objectCol.setFloat)
        validateCount("setDouble", \Query<LinkToModernCollectionsOfEnums>.objectCol.setDouble)
        validateCount("setString", \Query<LinkToModernCollectionsOfEnums>.objectCol.setString)
        validateCount("setOptInt", \Query<ModernAllTypesObject>.objectCol.setOptInt)
        validateCount("setOptInt8", \Query<ModernAllTypesObject>.objectCol.setOptInt8)
        validateCount("setOptInt16", \Query<ModernAllTypesObject>.objectCol.setOptInt16)
        validateCount("setOptInt32", \Query<ModernAllTypesObject>.objectCol.setOptInt32)
        validateCount("setOptInt64", \Query<ModernAllTypesObject>.objectCol.setOptInt64)
        validateCount("setOptFloat", \Query<ModernAllTypesObject>.objectCol.setOptFloat)
        validateCount("setOptDouble", \Query<ModernAllTypesObject>.objectCol.setOptDouble)
        validateCount("setOptString", \Query<ModernAllTypesObject>.objectCol.setOptString)
        validateCount("setOptBinary", \Query<ModernAllTypesObject>.objectCol.setOptBinary)
        validateCount("setOptDate", \Query<ModernAllTypesObject>.objectCol.setOptDate)
        validateCount("setOptDecimal", \Query<ModernAllTypesObject>.objectCol.setOptDecimal)
        validateCount("setOptObjectId", \Query<ModernAllTypesObject>.objectCol.setOptObjectId)
        validateCount("setOptUuid", \Query<ModernAllTypesObject>.objectCol.setOptUuid)
        validateCount("setIntOpt", \Query<LinkToModernCollectionsOfEnums>.objectCol.setIntOpt)
        validateCount("setInt8Opt", \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt8Opt)
        validateCount("setInt16Opt", \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt16Opt)
        validateCount("setInt32Opt", \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt32Opt)
        validateCount("setInt64Opt", \Query<LinkToModernCollectionsOfEnums>.objectCol.setInt64Opt)
        validateCount("setFloatOpt", \Query<LinkToModernCollectionsOfEnums>.objectCol.setFloatOpt)
        validateCount("setDoubleOpt", \Query<LinkToModernCollectionsOfEnums>.objectCol.setDoubleOpt)
        validateCount("setStringOpt", \Query<LinkToModernCollectionsOfEnums>.objectCol.setStringOpt)
        validateCount("mapInt", \Query<ModernAllTypesObject>.objectCol.mapInt)
        validateCount("mapInt8", \Query<ModernAllTypesObject>.objectCol.mapInt8)
        validateCount("mapInt16", \Query<ModernAllTypesObject>.objectCol.mapInt16)
        validateCount("mapInt32", \Query<ModernAllTypesObject>.objectCol.mapInt32)
        validateCount("mapInt64", \Query<ModernAllTypesObject>.objectCol.mapInt64)
        validateCount("mapFloat", \Query<ModernAllTypesObject>.objectCol.mapFloat)
        validateCount("mapDouble", \Query<ModernAllTypesObject>.objectCol.mapDouble)
        validateCount("mapString", \Query<ModernAllTypesObject>.objectCol.mapString)
        validateCount("mapBinary", \Query<ModernAllTypesObject>.objectCol.mapBinary)
        validateCount("mapDate", \Query<ModernAllTypesObject>.objectCol.mapDate)
        validateCount("mapDecimal", \Query<ModernAllTypesObject>.objectCol.mapDecimal)
        validateCount("mapObjectId", \Query<ModernAllTypesObject>.objectCol.mapObjectId)
        validateCount("mapUuid", \Query<ModernAllTypesObject>.objectCol.mapUuid)
        validateCount("mapAny", \Query<ModernAllTypesObject>.objectCol.mapAny)
        validateCount("mapInt", \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt)
        validateCount("mapInt8", \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt8)
        validateCount("mapInt16", \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt16)
        validateCount("mapInt32", \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt32)
        validateCount("mapInt64", \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt64)
        validateCount("mapFloat", \Query<LinkToModernCollectionsOfEnums>.objectCol.mapFloat)
        validateCount("mapDouble", \Query<LinkToModernCollectionsOfEnums>.objectCol.mapDouble)
        validateCount("mapString", \Query<LinkToModernCollectionsOfEnums>.objectCol.mapString)
        validateCount("mapOptInt", \Query<ModernAllTypesObject>.objectCol.mapOptInt)
        validateCount("mapOptInt8", \Query<ModernAllTypesObject>.objectCol.mapOptInt8)
        validateCount("mapOptInt16", \Query<ModernAllTypesObject>.objectCol.mapOptInt16)
        validateCount("mapOptInt32", \Query<ModernAllTypesObject>.objectCol.mapOptInt32)
        validateCount("mapOptInt64", \Query<ModernAllTypesObject>.objectCol.mapOptInt64)
        validateCount("mapOptFloat", \Query<ModernAllTypesObject>.objectCol.mapOptFloat)
        validateCount("mapOptDouble", \Query<ModernAllTypesObject>.objectCol.mapOptDouble)
        validateCount("mapOptString", \Query<ModernAllTypesObject>.objectCol.mapOptString)
        validateCount("mapOptBinary", \Query<ModernAllTypesObject>.objectCol.mapOptBinary)
        validateCount("mapOptDate", \Query<ModernAllTypesObject>.objectCol.mapOptDate)
        validateCount("mapOptDecimal", \Query<ModernAllTypesObject>.objectCol.mapOptDecimal)
        validateCount("mapOptObjectId", \Query<ModernAllTypesObject>.objectCol.mapOptObjectId)
        validateCount("mapOptUuid", \Query<ModernAllTypesObject>.objectCol.mapOptUuid)
        validateCount("mapIntOpt", \Query<LinkToModernCollectionsOfEnums>.objectCol.mapIntOpt)
        validateCount("mapInt8Opt", \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt8Opt)
        validateCount("mapInt16Opt", \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt16Opt)
        validateCount("mapInt32Opt", \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt32Opt)
        validateCount("mapInt64Opt", \Query<LinkToModernCollectionsOfEnums>.objectCol.mapInt64Opt)
        validateCount("mapFloatOpt", \Query<LinkToModernCollectionsOfEnums>.objectCol.mapFloatOpt)
        validateCount("mapDoubleOpt", \Query<LinkToModernCollectionsOfEnums>.objectCol.mapDoubleOpt)
        validateCount("mapStringOpt", \Query<LinkToModernCollectionsOfEnums>.objectCol.mapStringOpt)
    }

    // MARK: - Keypath Collection Aggregations

    private func validateKeypathAverage<Root: Object, T>(_ name: String, _ average: T, _ min: T, _ lhs: (Query<Root>) -> Query<T>)
            where T: _Persistable & QueryValue, T.PersistedType: _QueryNumeric {
        // Note here that there are four total objects: the parent, and three children, all of the same type
        assertQuery(Root.self, "(arrayCol.@avg.\(name) == %@)", average, count: 1) {
            lhs($0).avg == average
        }
        assertQuery(Root.self, "(arrayCol.@avg.\(name) == %@)", min, count: 0) {
            lhs($0).avg == min
        }
        assertQuery(Root.self, "(arrayCol.@avg.\(name) != %@)", average, count: 3) {
            lhs($0).avg != average
        }
        assertQuery(Root.self, "(arrayCol.@avg.\(name) != %@)", min, count: 4) {
            lhs($0).avg != min
        }
        assertQuery(Root.self, "(arrayCol.@avg.\(name) > %@)", average, count: 0) {
            lhs($0).avg > average
        }
        assertQuery(Root.self, "(arrayCol.@avg.\(name) > %@)", min, count: 1) {
            lhs($0).avg > min
        }
        assertQuery(Root.self, "(arrayCol.@avg.\(name) < %@)", average, count: 0 + 0 * 3) {
            lhs($0).avg < average
        }
        assertQuery(Root.self, "(arrayCol.@avg.\(name) >= %@)", average, count: 1) {
            lhs($0).avg >= average
        }
        assertQuery(Root.self, "(arrayCol.@avg.\(name) <= %@)", average, count: 1 + 0 * 3) {
            lhs($0).avg <= average
        }
    }

    func testKeypathCollectionAggregatesAvg() {
        let object = objects().first!
        createKeypathCollectionAggregatesObject(object)

        validateKeypathAverage("intCol", Int.average(), 5,
                    \Query<ModernAllTypesObject>.arrayCol.intCol)
        validateKeypathAverage("int8Col", Int8.average(), Int8(8),
                    \Query<ModernAllTypesObject>.arrayCol.int8Col)
        validateKeypathAverage("int16Col", Int16.average(), Int16(16),
                    \Query<ModernAllTypesObject>.arrayCol.int16Col)
        validateKeypathAverage("int32Col", Int32.average(), Int32(32),
                    \Query<ModernAllTypesObject>.arrayCol.int32Col)
        validateKeypathAverage("int64Col", Int64.average(), Int64(64),
                    \Query<ModernAllTypesObject>.arrayCol.int64Col)
        validateKeypathAverage("floatCol", Float.average(), Float(5.55444333),
                    \Query<ModernAllTypesObject>.arrayCol.floatCol)
        validateKeypathAverage("doubleCol", Double.average(), 123.456,
                    \Query<ModernAllTypesObject>.arrayCol.doubleCol)
        validateKeypathAverage("decimalCol", Decimal128.average(), Decimal128(123.456),
                    \Query<ModernAllTypesObject>.arrayCol.decimalCol)
        validateKeypathAverage("intEnumCol", ModernIntEnum.average(), ModernIntEnum.value1.rawValue,
                    \Query<ModernAllTypesObject>.arrayCol.intEnumCol.rawValue)
        validateKeypathAverage("optIntCol", Int?.average(), 5,
                    \Query<ModernAllTypesObject>.arrayCol.optIntCol)
        validateKeypathAverage("optInt8Col", Int8?.average(), Int8(8),
                    \Query<ModernAllTypesObject>.arrayCol.optInt8Col)
        validateKeypathAverage("optInt16Col", Int16?.average(), Int16(16),
                    \Query<ModernAllTypesObject>.arrayCol.optInt16Col)
        validateKeypathAverage("optInt32Col", Int32?.average(), Int32(32),
                    \Query<ModernAllTypesObject>.arrayCol.optInt32Col)
        validateKeypathAverage("optInt64Col", Int64?.average(), Int64(64),
                    \Query<ModernAllTypesObject>.arrayCol.optInt64Col)
        validateKeypathAverage("optFloatCol", Float?.average(), Float(5.55444333),
                    \Query<ModernAllTypesObject>.arrayCol.optFloatCol)
        validateKeypathAverage("optDoubleCol", Double?.average(), 123.456,
                    \Query<ModernAllTypesObject>.arrayCol.optDoubleCol)
        validateKeypathAverage("optDecimalCol", Decimal128?.average(), Decimal128(123.456),
                    \Query<ModernAllTypesObject>.arrayCol.optDecimalCol)
        validateKeypathAverage("optIntEnumCol", ModernIntEnum.average(), ModernIntEnum.value1.rawValue,
                    \Query<ModernAllTypesObject>.arrayCol.optIntEnumCol.rawValue)
    }

    private func validateKeypathSum<Root: Object, T>(_ name: String, _ sum: T, _ min: T, _ lhs: (Query<Root>) -> Query<T>)
            where T: _Persistable & QueryValue, T.PersistedType: _QueryNumeric {
        // Note here that there are four total objects: the parent, and three children, all of the same type
        assertQuery(Root.self, "(arrayCol.@sum.\(name) == %@)", sum, count: 1) {
            lhs($0).sum == sum
        }
        assertQuery(Root.self, "(arrayCol.@sum.\(name) == %@)", min, count: 0) {
            lhs($0).sum == min
        }
        assertQuery(Root.self, "(arrayCol.@sum.\(name) != %@)", sum, count: 3) {
            lhs($0).sum != sum
        }
        assertQuery(Root.self, "(arrayCol.@sum.\(name) != %@)", min, count: 4) {
            lhs($0).sum != min
        }
        assertQuery(Root.self, "(arrayCol.@sum.\(name) > %@)", sum, count: 0) {
            lhs($0).sum > sum
        }
        assertQuery(Root.self, "(arrayCol.@sum.\(name) > %@)", min, count: 1) {
            lhs($0).sum > min
        }
        assertQuery(Root.self, "(arrayCol.@sum.\(name) < %@)", sum, count: 0 + 1 * 3) {
            lhs($0).sum < sum
        }
        assertQuery(Root.self, "(arrayCol.@sum.\(name) >= %@)", sum, count: 1) {
            lhs($0).sum >= sum
        }
        assertQuery(Root.self, "(arrayCol.@sum.\(name) <= %@)", sum, count: 1 + 1 * 3) {
            lhs($0).sum <= sum
        }
    }

    func testKeypathCollectionAggregatesSum() {
        let object = objects().first!
        createKeypathCollectionAggregatesObject(object)

        validateKeypathSum("intCol", Int.sum(), 5,
                    \Query<ModernAllTypesObject>.arrayCol.intCol)
        validateKeypathSum("int8Col", Int8.sum(), Int8(8),
                    \Query<ModernAllTypesObject>.arrayCol.int8Col)
        validateKeypathSum("int16Col", Int16.sum(), Int16(16),
                    \Query<ModernAllTypesObject>.arrayCol.int16Col)
        validateKeypathSum("int32Col", Int32.sum(), Int32(32),
                    \Query<ModernAllTypesObject>.arrayCol.int32Col)
        validateKeypathSum("int64Col", Int64.sum(), Int64(64),
                    \Query<ModernAllTypesObject>.arrayCol.int64Col)
        validateKeypathSum("floatCol", Float.sum(), Float(5.55444333),
                    \Query<ModernAllTypesObject>.arrayCol.floatCol)
        validateKeypathSum("doubleCol", Double.sum(), 123.456,
                    \Query<ModernAllTypesObject>.arrayCol.doubleCol)
        validateKeypathSum("decimalCol", Decimal128.sum(), Decimal128(123.456),
                    \Query<ModernAllTypesObject>.arrayCol.decimalCol)
        validateKeypathSum("intEnumCol", ModernIntEnum.sum(), ModernIntEnum.value1.rawValue,
                    \Query<ModernAllTypesObject>.arrayCol.intEnumCol.rawValue)
        validateKeypathSum("optIntCol", Int?.sum(), 5,
                    \Query<ModernAllTypesObject>.arrayCol.optIntCol)
        validateKeypathSum("optInt8Col", Int8?.sum(), Int8(8),
                    \Query<ModernAllTypesObject>.arrayCol.optInt8Col)
        validateKeypathSum("optInt16Col", Int16?.sum(), Int16(16),
                    \Query<ModernAllTypesObject>.arrayCol.optInt16Col)
        validateKeypathSum("optInt32Col", Int32?.sum(), Int32(32),
                    \Query<ModernAllTypesObject>.arrayCol.optInt32Col)
        validateKeypathSum("optInt64Col", Int64?.sum(), Int64(64),
                    \Query<ModernAllTypesObject>.arrayCol.optInt64Col)
        validateKeypathSum("optFloatCol", Float?.sum(), Float(5.55444333),
                    \Query<ModernAllTypesObject>.arrayCol.optFloatCol)
        validateKeypathSum("optDoubleCol", Double?.sum(), 123.456,
                    \Query<ModernAllTypesObject>.arrayCol.optDoubleCol)
        validateKeypathSum("optDecimalCol", Decimal128?.sum(), Decimal128(123.456),
                    \Query<ModernAllTypesObject>.arrayCol.optDecimalCol)
        validateKeypathSum("optIntEnumCol", ModernIntEnum.sum(), ModernIntEnum.value1.rawValue,
                    \Query<ModernAllTypesObject>.arrayCol.optIntEnumCol.rawValue)
    }


    private func validateKeypathMin<Root: Object, T>(_ name: String, min: T, max: T, _ lhs: (Query<Root>) -> Query<T>)
            where T: _Persistable & QueryValue, T.PersistedType: _QueryNumeric {
        assertQuery(Root.self, "(arrayCol.@min.\(name) == %@)", min, count: 1) {
            lhs($0).min == min
        }
        assertQuery(Root.self, "(arrayCol.@min.\(name) == %@)", max, count: 0) {
            lhs($0).min == max
        }
        assertQuery(Root.self, "(arrayCol.@min.\(name) != %@)", min, count: 3) {
            lhs($0).min != min
        }
        assertQuery(Root.self, "(arrayCol.@min.\(name) != %@)", max, count: 4) {
            lhs($0).min != max
        }
        assertQuery(Root.self, "(arrayCol.@min.\(name) > %@)", min, count: 0) {
            lhs($0).min > min
        }
        assertQuery(Root.self, "(arrayCol.@min.\(name) < %@)", min, count: 0) {
            lhs($0).min < min
        }
        assertQuery(Root.self, "(arrayCol.@min.\(name) >= %@)", min, count: 1) {
            lhs($0).min >= min
        }
        assertQuery(Root.self, "(arrayCol.@min.\(name) <= %@)", min, count: 1) {
            lhs($0).min <= min
        }
    }

    func testKeypathCollectionAggregatesMin() {
        let object = objects().first!
        createKeypathCollectionAggregatesObject(object)

        validateKeypathMin("intCol", min: 5, max: 7,
                    \Query<ModernAllTypesObject>.arrayCol.intCol)
        validateKeypathMin("int8Col", min: Int8(8), max: Int8(10),
                    \Query<ModernAllTypesObject>.arrayCol.int8Col)
        validateKeypathMin("int16Col", min: Int16(16), max: Int16(18),
                    \Query<ModernAllTypesObject>.arrayCol.int16Col)
        validateKeypathMin("int32Col", min: Int32(32), max: Int32(34),
                    \Query<ModernAllTypesObject>.arrayCol.int32Col)
        validateKeypathMin("int64Col", min: Int64(64), max: Int64(66),
                    \Query<ModernAllTypesObject>.arrayCol.int64Col)
        validateKeypathMin("floatCol", min: Float(5.55444333), max: Float(7.55444333),
                    \Query<ModernAllTypesObject>.arrayCol.floatCol)
        validateKeypathMin("doubleCol", min: 123.456, max: 345.678,
                    \Query<ModernAllTypesObject>.arrayCol.doubleCol)
        validateKeypathMin("dateCol", min: Date(timeIntervalSince1970: 1000000), max: Date(timeIntervalSince1970: 3000000),
                    \Query<ModernAllTypesObject>.arrayCol.dateCol)
        validateKeypathMin("decimalCol", min: Decimal128(123.456), max: Decimal128(345.678),
                    \Query<ModernAllTypesObject>.arrayCol.decimalCol)
        validateKeypathMin("intEnumCol", min: ModernIntEnum.value1.rawValue, max: ModernIntEnum.value3.rawValue,
                    \Query<ModernAllTypesObject>.arrayCol.intEnumCol.rawValue)
        validateKeypathMin("optIntCol", min: 5, max: 7,
                    \Query<ModernAllTypesObject>.arrayCol.optIntCol)
        validateKeypathMin("optInt8Col", min: Int8(8), max: Int8(10),
                    \Query<ModernAllTypesObject>.arrayCol.optInt8Col)
        validateKeypathMin("optInt16Col", min: Int16(16), max: Int16(18),
                    \Query<ModernAllTypesObject>.arrayCol.optInt16Col)
        validateKeypathMin("optInt32Col", min: Int32(32), max: Int32(34),
                    \Query<ModernAllTypesObject>.arrayCol.optInt32Col)
        validateKeypathMin("optInt64Col", min: Int64(64), max: Int64(66),
                    \Query<ModernAllTypesObject>.arrayCol.optInt64Col)
        validateKeypathMin("optFloatCol", min: Float(5.55444333), max: Float(7.55444333),
                    \Query<ModernAllTypesObject>.arrayCol.optFloatCol)
        validateKeypathMin("optDoubleCol", min: 123.456, max: 345.678,
                    \Query<ModernAllTypesObject>.arrayCol.optDoubleCol)
        validateKeypathMin("optDateCol", min: Date(timeIntervalSince1970: 1000000), max: Date(timeIntervalSince1970: 3000000),
                    \Query<ModernAllTypesObject>.arrayCol.optDateCol)
        validateKeypathMin("optDecimalCol", min: Decimal128(123.456), max: Decimal128(345.678),
                    \Query<ModernAllTypesObject>.arrayCol.optDecimalCol)
        validateKeypathMin("optIntEnumCol", min: ModernIntEnum.value1.rawValue, max: ModernIntEnum.value3.rawValue,
                    \Query<ModernAllTypesObject>.arrayCol.optIntEnumCol.rawValue)
    }

    private func validateKeypathMax<Root: Object, T>(_ name: String, min: T, max: T, _ lhs: (Query<Root>) -> Query<T>)
            where T: _Persistable & QueryValue, T.PersistedType: _QueryNumeric {
        assertQuery(Root.self, "(arrayCol.@max.\(name) == %@)", max, count: 1) {
            lhs($0).max == max
        }
        assertQuery(Root.self, "(arrayCol.@max.\(name) == %@)", min, count: 0) {
            lhs($0).max == min
        }
        assertQuery(Root.self, "(arrayCol.@max.\(name) != %@)", max, count: 3) {
            lhs($0).max != max
        }
        assertQuery(Root.self, "(arrayCol.@max.\(name) != %@)", min, count: 4) {
            lhs($0).max != min
        }
        assertQuery(Root.self, "(arrayCol.@max.\(name) > %@)", max, count: 0) {
            lhs($0).max > max
        }
        assertQuery(Root.self, "(arrayCol.@max.\(name) < %@)", max, count: 0) {
            lhs($0).max < max
        }
        assertQuery(Root.self, "(arrayCol.@max.\(name) >= %@)", max, count: 1) {
            lhs($0).max >= max
        }
        assertQuery(Root.self, "(arrayCol.@max.\(name) <= %@)", max, count: 1) {
            lhs($0).max <= max
        }
    }

    func testKeypathCollectionAggregatesMax() {
        let object = objects().first!
        createKeypathCollectionAggregatesObject(object)

        validateKeypathMax("intCol", min: 5, max: 7,
                    \Query<ModernAllTypesObject>.arrayCol.intCol)
        validateKeypathMax("int8Col", min: Int8(8), max: Int8(10),
                    \Query<ModernAllTypesObject>.arrayCol.int8Col)
        validateKeypathMax("int16Col", min: Int16(16), max: Int16(18),
                    \Query<ModernAllTypesObject>.arrayCol.int16Col)
        validateKeypathMax("int32Col", min: Int32(32), max: Int32(34),
                    \Query<ModernAllTypesObject>.arrayCol.int32Col)
        validateKeypathMax("int64Col", min: Int64(64), max: Int64(66),
                    \Query<ModernAllTypesObject>.arrayCol.int64Col)
        validateKeypathMax("floatCol", min: Float(5.55444333), max: Float(7.55444333),
                    \Query<ModernAllTypesObject>.arrayCol.floatCol)
        validateKeypathMax("doubleCol", min: 123.456, max: 345.678,
                    \Query<ModernAllTypesObject>.arrayCol.doubleCol)
        validateKeypathMax("dateCol", min: Date(timeIntervalSince1970: 1000000), max: Date(timeIntervalSince1970: 3000000),
                    \Query<ModernAllTypesObject>.arrayCol.dateCol)
        validateKeypathMax("decimalCol", min: Decimal128(123.456), max: Decimal128(345.678),
                    \Query<ModernAllTypesObject>.arrayCol.decimalCol)
        validateKeypathMax("intEnumCol", min: ModernIntEnum.value1.rawValue, max: ModernIntEnum.value3.rawValue,
                    \Query<ModernAllTypesObject>.arrayCol.intEnumCol.rawValue)
        validateKeypathMax("optIntCol", min: 5, max: 7,
                    \Query<ModernAllTypesObject>.arrayCol.optIntCol)
        validateKeypathMax("optInt8Col", min: Int8(8), max: Int8(10),
                    \Query<ModernAllTypesObject>.arrayCol.optInt8Col)
        validateKeypathMax("optInt16Col", min: Int16(16), max: Int16(18),
                    \Query<ModernAllTypesObject>.arrayCol.optInt16Col)
        validateKeypathMax("optInt32Col", min: Int32(32), max: Int32(34),
                    \Query<ModernAllTypesObject>.arrayCol.optInt32Col)
        validateKeypathMax("optInt64Col", min: Int64(64), max: Int64(66),
                    \Query<ModernAllTypesObject>.arrayCol.optInt64Col)
        validateKeypathMax("optFloatCol", min: Float(5.55444333), max: Float(7.55444333),
                    \Query<ModernAllTypesObject>.arrayCol.optFloatCol)
        validateKeypathMax("optDoubleCol", min: 123.456, max: 345.678,
                    \Query<ModernAllTypesObject>.arrayCol.optDoubleCol)
        validateKeypathMax("optDateCol", min: Date(timeIntervalSince1970: 1000000), max: Date(timeIntervalSince1970: 3000000),
                    \Query<ModernAllTypesObject>.arrayCol.optDateCol)
        validateKeypathMax("optDecimalCol", min: Decimal128(123.456), max: Decimal128(345.678),
                    \Query<ModernAllTypesObject>.arrayCol.optDecimalCol)
        validateKeypathMax("optIntEnumCol", min: ModernIntEnum.value1.rawValue, max: ModernIntEnum.value3.rawValue,
                    \Query<ModernAllTypesObject>.arrayCol.optIntEnumCol.rawValue)
    }

    func testAggregateNotSupported() {
        assertThrows(assertQuery("", count: 0) { $0.intCol.avg == 1 },
                     reason: "Aggregate operations can only be used on key paths that include an collection property")

        assertThrows(assertQuery("", count: 0) { $0.doubleCol.max != 1 },
                     reason: "Aggregate operations can only be used on key paths that include an collection property")

        assertThrows(assertQuery("", count: 0) { $0.dateCol.min > Date() },
                     reason: "Aggregate operations can only be used on key paths that include an collection property")

        assertThrows(assertQuery("", count: 0) { $0.decimalCol.sum < 1 },
                     reason: "Aggregate operations can only be used on key paths that include an collection property")
    }

    // MARK: Column comparison

    func testColumnComparison() {
        // Basic comparison

        assertQuery("(stringEnumCol == stringEnumCol)", count: 1) {
            $0.stringEnumCol == $0.stringEnumCol
        }

        assertQuery("(stringCol != stringCol)", count: 0) {
            $0.stringCol != $0.stringCol
        }

        assertQuery("(stringEnumCol != stringEnumCol)", count: 0) {
            $0.stringEnumCol != $0.stringEnumCol
        }

        assertThrows(assertQuery("", count: 1) {
            $0.arrayCol == $0.arrayCol
        }, reason: "Comparing two collection columns is not permitted.")

        assertThrows(assertQuery("", count: 1) {
            $0.arrayCol != $0.arrayCol
        }, reason: "Comparing two collection columns is not permitted.")

        assertQuery("(intCol > intCol)", count: 0) {
            $0.intCol > $0.intCol
        }

        assertQuery("(intEnumCol > intEnumCol)", count: 0) {
            $0.intEnumCol > $0.intEnumCol
        }

        assertQuery("(intCol >= intCol)", count: 1) {
            $0.intCol >= $0.intCol
        }

        assertQuery("(intEnumCol >= intEnumCol)", count: 1) {
            $0.intEnumCol >= $0.intEnumCol
        }

        assertQuery("(intCol < intCol)", count: 0) {
            $0.intCol < $0.intCol
        }

        assertQuery("(intEnumCol < intEnumCol)", count: 0) {
            $0.intEnumCol < $0.intEnumCol
        }

        assertQuery("(intCol <= intCol)", count: 1) {
            $0.intCol <= $0.intCol
        }

        assertQuery("(intEnumCol <= intEnumCol)", count: 1) {
            $0.intEnumCol <= $0.intEnumCol
        }

        assertQuery("(optStringCol == optStringCol)", count: 1) {
            $0.optStringCol == $0.optStringCol
        }

        assertQuery("(optStringCol != optStringCol)", count: 0) {
            $0.optStringCol != $0.optStringCol
        }

        assertQuery("(optIntCol > optIntCol)", count: 0) {
            $0.optIntCol > $0.optIntCol
        }

        assertQuery("(optIntCol >= optIntCol)", count: 1) {
            $0.optIntCol >= $0.optIntCol
        }

        assertQuery("(optIntCol < optIntCol)", count: 0) {
            $0.optIntCol < $0.optIntCol
        }

        assertQuery("(optIntCol <= optIntCol)", count: 1) {
            $0.optIntCol <= $0.optIntCol
        }

        // Basic comparison with one level depth

        assertQuery("(objectCol.stringCol == objectCol.stringCol)", count: 1) {
            $0.objectCol.stringCol == $0.objectCol.stringCol
        }

        assertQuery("(objectCol.stringCol != objectCol.stringCol)", count: 0) {
            $0.objectCol.stringCol != $0.objectCol.stringCol
        }

        assertQuery("(objectCol.intCol > objectCol.intCol)", count: 0) {
            $0.objectCol.intCol > $0.objectCol.intCol
        }

        assertQuery("(objectCol.intCol >= objectCol.intCol)", count: 1) {
            $0.objectCol.intCol >= $0.objectCol.intCol
        }

        assertQuery("(objectCol.intCol < objectCol.intCol)", count: 0) {
            $0.objectCol.intCol < $0.objectCol.intCol
        }

        assertQuery("(objectCol.intCol <= objectCol.intCol)", count: 1) {
            $0.objectCol.intCol <= $0.objectCol.intCol
        }

        assertQuery("(objectCol.optStringCol == objectCol.optStringCol)", count: 1) {
            $0.objectCol.optStringCol == $0.objectCol.optStringCol
        }

        assertQuery("(objectCol.optStringCol != objectCol.optStringCol)", count: 0) {
            $0.objectCol.optStringCol != $0.objectCol.optStringCol
        }

        assertQuery("(objectCol.optIntCol > objectCol.optIntCol)", count: 0) {
            $0.objectCol.optIntCol > $0.objectCol.optIntCol
        }

        assertQuery("(objectCol.optIntCol >= objectCol.optIntCol)", count: 1) {
            $0.objectCol.optIntCol >= $0.objectCol.optIntCol
        }

        assertQuery("(objectCol.optIntCol < objectCol.optIntCol)", count: 0) {
            $0.objectCol.optIntCol < $0.objectCol.optIntCol
        }

        assertQuery("(objectCol.optIntCol <= objectCol.optIntCol)", count: 1) {
            $0.objectCol.optIntCol <= $0.objectCol.optIntCol
        }

        // String comparison

        assertQuery("(stringCol CONTAINS[cd] stringCol)", count: 1) {
            $0.stringCol.contains($0.stringCol, options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery("(stringCol BEGINSWITH[cd] stringCol)", count: 1) {
            $0.stringCol.starts(with: $0.stringCol, options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery("(stringCol ENDSWITH[cd] stringCol)", count: 1) {
            $0.stringCol.ends(with: $0.stringCol, options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery("(stringCol LIKE[c] stringCol)", count: 1) {
            $0.stringCol.like($0.stringCol, caseInsensitive: true)
        }

        assertQuery("(stringCol ==[cd] stringCol)", count: 1) {
            $0.stringCol.equals($0.stringCol, options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery("(stringCol !=[cd] stringCol)", count: 0) {
            $0.stringCol.notEquals($0.stringCol, options: [.caseInsensitive, .diacriticInsensitive])
        }

        // String with optional col

        assertQuery("(stringCol CONTAINS[cd] optStringCol)", count: 1) {
            $0.stringCol.contains($0.optStringCol, options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery("(optStringCol CONTAINS[cd] optStringCol)", count: 1) {
            $0.optStringCol.contains($0.optStringCol, options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery("(optStringCol CONTAINS[cd] stringCol)", count: 1) {
            $0.optStringCol.contains($0.stringCol, options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery("(stringCol BEGINSWITH[cd] stringCol)", count: 1) {
            $0.stringCol.starts(with: $0.stringCol, options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery("(optStringCol BEGINSWITH[cd] optStringCol)", count: 1) {
            $0.optStringCol.starts(with: $0.optStringCol, options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery("(optStringCol BEGINSWITH[cd] stringCol)", count: 1) {
            $0.optStringCol.starts(with: $0.stringCol, options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery("(stringCol ENDSWITH[cd] stringCol)", count: 1) {
            $0.stringCol.ends(with: $0.stringCol, options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery("(optStringCol ENDSWITH[cd] optStringCol)", count: 1) {
            $0.optStringCol.ends(with: $0.optStringCol, options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery("(optStringCol ENDSWITH[cd] stringCol)", count: 1) {
            $0.optStringCol.ends(with: $0.stringCol, options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery("(stringCol LIKE[c] stringCol)", count: 1) {
            $0.stringCol.like($0.stringCol, caseInsensitive: true)
        }

        assertQuery("(optStringCol LIKE[c] optStringCol)", count: 1) {
            $0.optStringCol.like($0.optStringCol, caseInsensitive: true)
        }

        assertQuery("(optStringCol LIKE[c] stringCol)", count: 1) {
            $0.optStringCol.like($0.stringCol, caseInsensitive: true)
        }

        assertQuery("(stringCol ==[cd] stringCol)", count: 1) {
            $0.stringCol.equals($0.stringCol, options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery("(optStringCol ==[cd] optStringCol)", count: 1) {
            $0.optStringCol.equals($0.optStringCol, options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery("(optStringCol ==[cd] stringCol)", count: 1) {
            $0.optStringCol.equals($0.stringCol, options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery("(stringCol !=[cd] stringCol)", count: 0) {
            $0.stringCol.notEquals($0.stringCol, options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery("(optStringCol !=[cd] optStringCol)", count: 0) {
            $0.optStringCol.notEquals($0.optStringCol, options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery("(optStringCol !=[cd] stringCol)", count: 0) {
            $0.optStringCol.notEquals($0.stringCol, options: [.caseInsensitive, .diacriticInsensitive])
        }
    }
}

private protocol QueryValue {
    static func queryValues() -> [Self]
}

extension Bool: QueryValue {
    static func queryValues() -> [Bool] {
        return [true, true, false]
    }
}

extension Int: QueryValue {
    static func queryValues() -> [Int] {
        return [5, 6, 7]
    }
}
extension EnumInt: QueryValue {
    static func queryValues() -> [EnumInt] {
        return [.value1, .value2, .value3]
    }
}

extension Int8: QueryValue {
    static func queryValues() -> [Int8] {
        return [Int8(8), Int8(9), Int8(10)]
    }
}
extension EnumInt8: QueryValue {
    static func queryValues() -> [EnumInt8] {
        return [.value1, .value2, .value3]
    }
}

extension Int16: QueryValue {
    static func queryValues() -> [Int16] {
        return [Int16(16), Int16(17), Int16(18)]
    }
}
extension EnumInt16: QueryValue {
    static func queryValues() -> [EnumInt16] {
        return [.value1, .value2, .value3]
    }
}

extension Int32: QueryValue {
    static func queryValues() -> [Int32] {
        return [Int32(32), Int32(33), Int32(34)]
    }
}
extension EnumInt32: QueryValue {
    static func queryValues() -> [EnumInt32] {
        return [.value1, .value2, .value3]
    }
}

extension Int64: QueryValue {
    static func queryValues() -> [Int64] {
        return [Int64(64), Int64(65), Int64(66)]
    }
}
extension EnumInt64: QueryValue {
    static func queryValues() -> [EnumInt64] {
        return [.value1, .value2, .value3]
    }
}

extension Float: QueryValue {
    static func queryValues() -> [Float] {
        return [Float(5.55444333), Float(6.55444333), Float(7.55444333)]
    }
}
extension EnumFloat: QueryValue {
    static func queryValues() -> [EnumFloat] {
        return [.value1, .value2, .value3]
    }
}

extension Double: QueryValue {
    static func queryValues() -> [Double] {
        return [123.456, 234.567, 345.678]
    }
}
extension EnumDouble: QueryValue {
    static func queryValues() -> [EnumDouble] {
        return [.value1, .value2, .value3]
    }
}

extension String: QueryValue {
    static func queryValues() -> [String] {
        return ["Foo", "Foó", "foo"]
    }
}
extension EnumString: QueryValue {
    static func queryValues() -> [EnumString] {
        return [.value1, .value2, .value3]
    }
}

extension Data: QueryValue {
    static func queryValues() -> [Data] {
        return [Data(count: 64), Data(count: 128), Data(count: 256)]
    }
}

extension Date: QueryValue {
    static func queryValues() -> [Date] {
        return [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000), Date(timeIntervalSince1970: 3000000)]
    }
}

extension Decimal128: QueryValue {
    static func queryValues() -> [Decimal128] {
        return [Decimal128(123.456), Decimal128(234.567), Decimal128(345.678)]
    }
}

extension ObjectId: QueryValue {
    static func queryValues() -> [ObjectId] {
        return [ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045"), ObjectId("61184062c1d8f096a3695044")]
    }
}

extension UUID: QueryValue {
    static func queryValues() -> [UUID] {
        return [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d08e")!]
    }
}

extension ModernIntEnum: QueryValue {
    static func queryValues() -> [ModernIntEnum] {
        return [.value1, .value2, .value3]
    }
    fileprivate static func sum() -> Int {
        return Self.value1.rawValue + Self.value2.rawValue + Self.value3.rawValue
    }
    fileprivate static func average() -> Int {
        return Self.value2.rawValue
    }
}

extension AnyRealmValue: QueryValue {
    static func queryValues() -> [AnyRealmValue] {
        return [AnyRealmValue.objectId(ObjectId("61184062c1d8f096a3695046")), AnyRealmValue.string("Hello"), AnyRealmValue.int(123)]
    }
}

extension Optional: QueryValue where Wrapped: QueryValue {
    static func queryValues() -> [Self] {
        return Wrapped.queryValues().map(Self.init)
    }
}

private protocol AddableQueryValue {
    associatedtype SumType
    static func sum() -> SumType
    static func average() -> SumType
}

extension Int: AddableQueryValue {
    fileprivate typealias SumType = Int
    fileprivate static func sum() -> SumType {
        return 5 + 6 + 7
    }
    fileprivate static func average() -> SumType {
        return sum() / 3
    }
}
extension EnumInt: AddableQueryValue {
    fileprivate typealias SumType = Int
    fileprivate static func sum() -> SumType {
        return Self.value1.rawValue + Self.value2.rawValue + Self.value3.rawValue
    }
    fileprivate static func average() -> SumType {
        return sum() / 3
    }
}

extension Int8: AddableQueryValue {
    fileprivate typealias SumType = Int8
    fileprivate static func sum() -> SumType {
        return Int8(8) + Int8(9) + Int8(10)
    }
    fileprivate static func average() -> SumType {
        return sum() / 3
    }
}
extension EnumInt8: AddableQueryValue {
    fileprivate typealias SumType = Int8
    fileprivate static func sum() -> SumType {
        return Self.value1.rawValue + Self.value2.rawValue + Self.value3.rawValue
    }
    fileprivate static func average() -> SumType {
        return sum() / 3
    }
}

extension Int16: AddableQueryValue {
    fileprivate typealias SumType = Int16
    fileprivate static func sum() -> SumType {
        return Int16(16) + Int16(17) + Int16(18)
    }
    fileprivate static func average() -> SumType {
        return sum() / 3
    }
}
extension EnumInt16: AddableQueryValue {
    fileprivate typealias SumType = Int16
    fileprivate static func sum() -> SumType {
        return Self.value1.rawValue + Self.value2.rawValue + Self.value3.rawValue
    }
    fileprivate static func average() -> SumType {
        return sum() / 3
    }
}

extension Int32: AddableQueryValue {
    fileprivate typealias SumType = Int32
    fileprivate static func sum() -> SumType {
        return Int32(32) + Int32(33) + Int32(34)
    }
    fileprivate static func average() -> SumType {
        return sum() / 3
    }
}
extension EnumInt32: AddableQueryValue {
    fileprivate typealias SumType = Int32
    fileprivate static func sum() -> SumType {
        return Self.value1.rawValue + Self.value2.rawValue + Self.value3.rawValue
    }
    fileprivate static func average() -> SumType {
        return sum() / 3
    }
}

extension Int64: AddableQueryValue {
    fileprivate typealias SumType = Int64
    fileprivate static func sum() -> SumType {
        return Int64(64) + Int64(65) + Int64(66)
    }
    fileprivate static func average() -> SumType {
        return sum() / 3
    }
}
extension EnumInt64: AddableQueryValue {
    fileprivate typealias SumType = Int64
    fileprivate static func sum() -> SumType {
        return Self.value1.rawValue + Self.value2.rawValue + Self.value3.rawValue
    }
    fileprivate static func average() -> SumType {
        return sum() / 3
    }
}

extension Float: AddableQueryValue {
    fileprivate typealias SumType = Float
    fileprivate static func sum() -> SumType {
        return Float(5.55444333) + Float(6.55444333) + Float(7.55444333)
    }
    fileprivate static func average() -> SumType {
        return sum() / 3
    }
}
extension EnumFloat: AddableQueryValue {
    fileprivate typealias SumType = Float
    fileprivate static func sum() -> SumType {
        return Self.value1.rawValue + Self.value2.rawValue + Self.value3.rawValue
    }
    fileprivate static func average() -> SumType {
        return sum() / 3
    }
}

extension Double: AddableQueryValue {
    fileprivate typealias SumType = Double
    fileprivate static func sum() -> SumType {
        return 123.456 + 234.567 + 345.678
    }
    fileprivate static func average() -> SumType {
        return sum() / 3
    }
}
extension EnumDouble: AddableQueryValue {
    fileprivate typealias SumType = Double
    fileprivate static func sum() -> SumType {
        return Self.value1.rawValue + Self.value2.rawValue + Self.value3.rawValue
    }
    fileprivate static func average() -> SumType {
        return sum() / 3
    }
}

extension Decimal128: AddableQueryValue {
    fileprivate typealias SumType = Decimal128
    fileprivate static func sum() -> SumType {
        return Decimal128(123.456) + Decimal128(234.567) + Decimal128(345.678)
    }
    fileprivate static func average() -> SumType {
        return sum() / 3
    }
}

extension Optional: AddableQueryValue where Wrapped: AddableQueryValue {
    fileprivate typealias SumType = Optional<Wrapped.SumType>
    fileprivate static func sum() -> SumType {
        return .some(Wrapped.sum())
    }
    fileprivate static func average() -> SumType {
        return .some(Wrapped.average())
    }
}
