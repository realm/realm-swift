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
// distributed under the License is distributed on an "(AS IS)" BASIS,
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
            let objCustomPersistableCollections = CustomPersistableCollections()
            let objAllCustomPersistableTypes = AllCustomPersistableTypes()
            let objModernAllTypesObject = ModernAllTypesObject()
            let objModernCollectionsOfEnums = ModernCollectionsOfEnums()

            objModernAllTypesObject.boolCol = false
            objModernAllTypesObject.intCol = 3
            objModernAllTypesObject.int8Col = Int8(9)
            objModernAllTypesObject.int16Col = Int16(17)
            objModernAllTypesObject.int32Col = Int32(33)
            objModernAllTypesObject.int64Col = Int64(65)
            objModernAllTypesObject.floatCol = Float(6.55444333)
            objModernAllTypesObject.doubleCol = 234.567
            objModernAllTypesObject.stringCol = "Foó"
            objModernAllTypesObject.binaryCol = Data(count: 128)
            objModernAllTypesObject.dateCol = Date(timeIntervalSince1970: 2000000)
            objModernAllTypesObject.decimalCol = Decimal128(234.567)
            objModernAllTypesObject.objectIdCol = ObjectId("61184062c1d8f096a3695045")
            objModernAllTypesObject.uuidCol = UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!
            objModernAllTypesObject.intEnumCol = .value2
            objModernAllTypesObject.stringEnumCol = .value2
            objAllCustomPersistableTypes.bool = BoolWrapper(persistedValue: false)
            objAllCustomPersistableTypes.int = IntWrapper(persistedValue: 3)
            objAllCustomPersistableTypes.int8 = Int8Wrapper(persistedValue: Int8(9))
            objAllCustomPersistableTypes.int16 = Int16Wrapper(persistedValue: Int16(17))
            objAllCustomPersistableTypes.int32 = Int32Wrapper(persistedValue: Int32(33))
            objAllCustomPersistableTypes.int64 = Int64Wrapper(persistedValue: Int64(65))
            objAllCustomPersistableTypes.float = FloatWrapper(persistedValue: Float(6.55444333))
            objAllCustomPersistableTypes.double = DoubleWrapper(persistedValue: 234.567)
            objAllCustomPersistableTypes.string = StringWrapper(persistedValue: "Foó")
            objAllCustomPersistableTypes.binary = DataWrapper(persistedValue: Data(count: 128))
            objAllCustomPersistableTypes.date = DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000))
            objAllCustomPersistableTypes.decimal = Decimal128Wrapper(persistedValue: Decimal128(234.567))
            objAllCustomPersistableTypes.objectId = ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045"))
            objAllCustomPersistableTypes.uuid = UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)
            objModernAllTypesObject.optBoolCol = false
            objModernAllTypesObject.optIntCol = 3
            objModernAllTypesObject.optInt8Col = Int8(9)
            objModernAllTypesObject.optInt16Col = Int16(17)
            objModernAllTypesObject.optInt32Col = Int32(33)
            objModernAllTypesObject.optInt64Col = Int64(65)
            objModernAllTypesObject.optFloatCol = Float(6.55444333)
            objModernAllTypesObject.optDoubleCol = 234.567
            objModernAllTypesObject.optStringCol = "Foó"
            objModernAllTypesObject.optBinaryCol = Data(count: 128)
            objModernAllTypesObject.optDateCol = Date(timeIntervalSince1970: 2000000)
            objModernAllTypesObject.optDecimalCol = Decimal128(234.567)
            objModernAllTypesObject.optObjectIdCol = ObjectId("61184062c1d8f096a3695045")
            objModernAllTypesObject.optUuidCol = UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!
            objModernAllTypesObject.optIntEnumCol = .value2
            objModernAllTypesObject.optStringEnumCol = .value2
            objAllCustomPersistableTypes.optBool = BoolWrapper(persistedValue: false)
            objAllCustomPersistableTypes.optInt = IntWrapper(persistedValue: 3)
            objAllCustomPersistableTypes.optInt8 = Int8Wrapper(persistedValue: Int8(9))
            objAllCustomPersistableTypes.optInt16 = Int16Wrapper(persistedValue: Int16(17))
            objAllCustomPersistableTypes.optInt32 = Int32Wrapper(persistedValue: Int32(33))
            objAllCustomPersistableTypes.optInt64 = Int64Wrapper(persistedValue: Int64(65))
            objAllCustomPersistableTypes.optFloat = FloatWrapper(persistedValue: Float(6.55444333))
            objAllCustomPersistableTypes.optDouble = DoubleWrapper(persistedValue: 234.567)
            objAllCustomPersistableTypes.optString = StringWrapper(persistedValue: "Foó")
            objAllCustomPersistableTypes.optBinary = DataWrapper(persistedValue: Data(count: 128))
            objAllCustomPersistableTypes.optDate = DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000))
            objAllCustomPersistableTypes.optDecimal = Decimal128Wrapper(persistedValue: Decimal128(234.567))
            objAllCustomPersistableTypes.optObjectId = ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045"))
            objAllCustomPersistableTypes.optUuid = UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)

            objModernAllTypesObject.arrayBool.append(objectsIn: [true, true])
            objModernAllTypesObject.arrayInt.append(objectsIn: [1, 3])
            objModernAllTypesObject.arrayInt8.append(objectsIn: [Int8(8), Int8(9)])
            objModernAllTypesObject.arrayInt16.append(objectsIn: [Int16(16), Int16(17)])
            objModernAllTypesObject.arrayInt32.append(objectsIn: [Int32(32), Int32(33)])
            objModernAllTypesObject.arrayInt64.append(objectsIn: [Int64(64), Int64(65)])
            objModernAllTypesObject.arrayFloat.append(objectsIn: [Float(5.55444333), Float(6.55444333)])
            objModernAllTypesObject.arrayDouble.append(objectsIn: [123.456, 234.567])
            objModernAllTypesObject.arrayString.append(objectsIn: ["Foo", "Foó"])
            objModernAllTypesObject.arrayBinary.append(objectsIn: [Data(count: 64), Data(count: 128)])
            objModernAllTypesObject.arrayDate.append(objectsIn: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)])
            objModernAllTypesObject.arrayDecimal.append(objectsIn: [Decimal128(123.456), Decimal128(234.567)])
            objModernAllTypesObject.arrayObjectId.append(objectsIn: [ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045")])
            objModernAllTypesObject.arrayUuid.append(objectsIn: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])
            objModernAllTypesObject.arrayAny.append(objectsIn: [AnyRealmValue.objectId(ObjectId("61184062c1d8f096a3695046")), AnyRealmValue.string("Hello")])
            objModernCollectionsOfEnums.listInt.append(objectsIn: [.value1, .value2])
            objModernCollectionsOfEnums.listInt8.append(objectsIn: [.value1, .value2])
            objModernCollectionsOfEnums.listInt16.append(objectsIn: [.value1, .value2])
            objModernCollectionsOfEnums.listInt32.append(objectsIn: [.value1, .value2])
            objModernCollectionsOfEnums.listInt64.append(objectsIn: [.value1, .value2])
            objModernCollectionsOfEnums.listFloat.append(objectsIn: [.value1, .value2])
            objModernCollectionsOfEnums.listDouble.append(objectsIn: [.value1, .value2])
            objModernCollectionsOfEnums.listString.append(objectsIn: [.value1, .value2])
            objCustomPersistableCollections.listBool.append(objectsIn: [BoolWrapper(persistedValue: true), BoolWrapper(persistedValue: true)])
            objCustomPersistableCollections.listInt.append(objectsIn: [IntWrapper(persistedValue: 1), IntWrapper(persistedValue: 3)])
            objCustomPersistableCollections.listInt8.append(objectsIn: [Int8Wrapper(persistedValue: Int8(8)), Int8Wrapper(persistedValue: Int8(9))])
            objCustomPersistableCollections.listInt16.append(objectsIn: [Int16Wrapper(persistedValue: Int16(16)), Int16Wrapper(persistedValue: Int16(17))])
            objCustomPersistableCollections.listInt32.append(objectsIn: [Int32Wrapper(persistedValue: Int32(32)), Int32Wrapper(persistedValue: Int32(33))])
            objCustomPersistableCollections.listInt64.append(objectsIn: [Int64Wrapper(persistedValue: Int64(64)), Int64Wrapper(persistedValue: Int64(65))])
            objCustomPersistableCollections.listFloat.append(objectsIn: [FloatWrapper(persistedValue: Float(5.55444333)), FloatWrapper(persistedValue: Float(6.55444333))])
            objCustomPersistableCollections.listDouble.append(objectsIn: [DoubleWrapper(persistedValue: 123.456), DoubleWrapper(persistedValue: 234.567)])
            objCustomPersistableCollections.listString.append(objectsIn: [StringWrapper(persistedValue: "Foo"), StringWrapper(persistedValue: "Foó")])
            objCustomPersistableCollections.listBinary.append(objectsIn: [DataWrapper(persistedValue: Data(count: 64)), DataWrapper(persistedValue: Data(count: 128))])
            objCustomPersistableCollections.listDate.append(objectsIn: [DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)), DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000))])
            objCustomPersistableCollections.listDecimal.append(objectsIn: [Decimal128Wrapper(persistedValue: Decimal128(123.456)), Decimal128Wrapper(persistedValue: Decimal128(234.567))])
            objCustomPersistableCollections.listObjectId.append(objectsIn: [ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695046")), ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045"))])
            objCustomPersistableCollections.listUuid.append(objectsIn: [UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!), UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)])
            objModernAllTypesObject.arrayOptBool.append(objectsIn: [true, true])
            objModernAllTypesObject.arrayOptInt.append(objectsIn: [1, 3])
            objModernAllTypesObject.arrayOptInt8.append(objectsIn: [Int8(8), Int8(9)])
            objModernAllTypesObject.arrayOptInt16.append(objectsIn: [Int16(16), Int16(17)])
            objModernAllTypesObject.arrayOptInt32.append(objectsIn: [Int32(32), Int32(33)])
            objModernAllTypesObject.arrayOptInt64.append(objectsIn: [Int64(64), Int64(65)])
            objModernAllTypesObject.arrayOptFloat.append(objectsIn: [Float(5.55444333), Float(6.55444333)])
            objModernAllTypesObject.arrayOptDouble.append(objectsIn: [123.456, 234.567])
            objModernAllTypesObject.arrayOptString.append(objectsIn: ["Foo", "Foó"])
            objModernAllTypesObject.arrayOptBinary.append(objectsIn: [Data(count: 64), Data(count: 128)])
            objModernAllTypesObject.arrayOptDate.append(objectsIn: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)])
            objModernAllTypesObject.arrayOptDecimal.append(objectsIn: [Decimal128(123.456), Decimal128(234.567)])
            objModernAllTypesObject.arrayOptObjectId.append(objectsIn: [ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045")])
            objModernAllTypesObject.arrayOptUuid.append(objectsIn: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])
            objModernCollectionsOfEnums.listIntOpt.append(objectsIn: [.value1, .value2])
            objModernCollectionsOfEnums.listInt8Opt.append(objectsIn: [.value1, .value2])
            objModernCollectionsOfEnums.listInt16Opt.append(objectsIn: [.value1, .value2])
            objModernCollectionsOfEnums.listInt32Opt.append(objectsIn: [.value1, .value2])
            objModernCollectionsOfEnums.listInt64Opt.append(objectsIn: [.value1, .value2])
            objModernCollectionsOfEnums.listFloatOpt.append(objectsIn: [.value1, .value2])
            objModernCollectionsOfEnums.listDoubleOpt.append(objectsIn: [.value1, .value2])
            objModernCollectionsOfEnums.listStringOpt.append(objectsIn: [.value1, .value2])
            objCustomPersistableCollections.listOptBool.append(objectsIn: [BoolWrapper(persistedValue: true), BoolWrapper(persistedValue: true)])
            objCustomPersistableCollections.listOptInt.append(objectsIn: [IntWrapper(persistedValue: 1), IntWrapper(persistedValue: 3)])
            objCustomPersistableCollections.listOptInt8.append(objectsIn: [Int8Wrapper(persistedValue: Int8(8)), Int8Wrapper(persistedValue: Int8(9))])
            objCustomPersistableCollections.listOptInt16.append(objectsIn: [Int16Wrapper(persistedValue: Int16(16)), Int16Wrapper(persistedValue: Int16(17))])
            objCustomPersistableCollections.listOptInt32.append(objectsIn: [Int32Wrapper(persistedValue: Int32(32)), Int32Wrapper(persistedValue: Int32(33))])
            objCustomPersistableCollections.listOptInt64.append(objectsIn: [Int64Wrapper(persistedValue: Int64(64)), Int64Wrapper(persistedValue: Int64(65))])
            objCustomPersistableCollections.listOptFloat.append(objectsIn: [FloatWrapper(persistedValue: Float(5.55444333)), FloatWrapper(persistedValue: Float(6.55444333))])
            objCustomPersistableCollections.listOptDouble.append(objectsIn: [DoubleWrapper(persistedValue: 123.456), DoubleWrapper(persistedValue: 234.567)])
            objCustomPersistableCollections.listOptString.append(objectsIn: [StringWrapper(persistedValue: "Foo"), StringWrapper(persistedValue: "Foó")])
            objCustomPersistableCollections.listOptBinary.append(objectsIn: [DataWrapper(persistedValue: Data(count: 64)), DataWrapper(persistedValue: Data(count: 128))])
            objCustomPersistableCollections.listOptDate.append(objectsIn: [DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)), DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000))])
            objCustomPersistableCollections.listOptDecimal.append(objectsIn: [Decimal128Wrapper(persistedValue: Decimal128(123.456)), Decimal128Wrapper(persistedValue: Decimal128(234.567))])
            objCustomPersistableCollections.listOptObjectId.append(objectsIn: [ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695046")), ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045"))])
            objCustomPersistableCollections.listOptUuid.append(objectsIn: [UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!), UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)])

            objModernAllTypesObject.setBool.insert(objectsIn: [true, true])
            objModernAllTypesObject.setInt.insert(objectsIn: [1, 3])
            objModernAllTypesObject.setInt8.insert(objectsIn: [Int8(8), Int8(9)])
            objModernAllTypesObject.setInt16.insert(objectsIn: [Int16(16), Int16(17)])
            objModernAllTypesObject.setInt32.insert(objectsIn: [Int32(32), Int32(33)])
            objModernAllTypesObject.setInt64.insert(objectsIn: [Int64(64), Int64(65)])
            objModernAllTypesObject.setFloat.insert(objectsIn: [Float(5.55444333), Float(6.55444333)])
            objModernAllTypesObject.setDouble.insert(objectsIn: [123.456, 234.567])
            objModernAllTypesObject.setString.insert(objectsIn: ["Foo", "Foó"])
            objModernAllTypesObject.setBinary.insert(objectsIn: [Data(count: 64), Data(count: 128)])
            objModernAllTypesObject.setDate.insert(objectsIn: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)])
            objModernAllTypesObject.setDecimal.insert(objectsIn: [Decimal128(123.456), Decimal128(234.567)])
            objModernAllTypesObject.setObjectId.insert(objectsIn: [ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045")])
            objModernAllTypesObject.setUuid.insert(objectsIn: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])
            objModernAllTypesObject.setAny.insert(objectsIn: [AnyRealmValue.objectId(ObjectId("61184062c1d8f096a3695046")), AnyRealmValue.string("Hello")])
            objModernCollectionsOfEnums.setInt.insert(objectsIn: [.value1, .value2])
            objModernCollectionsOfEnums.setInt8.insert(objectsIn: [.value1, .value2])
            objModernCollectionsOfEnums.setInt16.insert(objectsIn: [.value1, .value2])
            objModernCollectionsOfEnums.setInt32.insert(objectsIn: [.value1, .value2])
            objModernCollectionsOfEnums.setInt64.insert(objectsIn: [.value1, .value2])
            objModernCollectionsOfEnums.setFloat.insert(objectsIn: [.value1, .value2])
            objModernCollectionsOfEnums.setDouble.insert(objectsIn: [.value1, .value2])
            objModernCollectionsOfEnums.setString.insert(objectsIn: [.value1, .value2])
            objCustomPersistableCollections.setBool.insert(objectsIn: [BoolWrapper(persistedValue: true), BoolWrapper(persistedValue: true)])
            objCustomPersistableCollections.setInt.insert(objectsIn: [IntWrapper(persistedValue: 1), IntWrapper(persistedValue: 3)])
            objCustomPersistableCollections.setInt8.insert(objectsIn: [Int8Wrapper(persistedValue: Int8(8)), Int8Wrapper(persistedValue: Int8(9))])
            objCustomPersistableCollections.setInt16.insert(objectsIn: [Int16Wrapper(persistedValue: Int16(16)), Int16Wrapper(persistedValue: Int16(17))])
            objCustomPersistableCollections.setInt32.insert(objectsIn: [Int32Wrapper(persistedValue: Int32(32)), Int32Wrapper(persistedValue: Int32(33))])
            objCustomPersistableCollections.setInt64.insert(objectsIn: [Int64Wrapper(persistedValue: Int64(64)), Int64Wrapper(persistedValue: Int64(65))])
            objCustomPersistableCollections.setFloat.insert(objectsIn: [FloatWrapper(persistedValue: Float(5.55444333)), FloatWrapper(persistedValue: Float(6.55444333))])
            objCustomPersistableCollections.setDouble.insert(objectsIn: [DoubleWrapper(persistedValue: 123.456), DoubleWrapper(persistedValue: 234.567)])
            objCustomPersistableCollections.setString.insert(objectsIn: [StringWrapper(persistedValue: "Foo"), StringWrapper(persistedValue: "Foó")])
            objCustomPersistableCollections.setBinary.insert(objectsIn: [DataWrapper(persistedValue: Data(count: 64)), DataWrapper(persistedValue: Data(count: 128))])
            objCustomPersistableCollections.setDate.insert(objectsIn: [DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)), DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000))])
            objCustomPersistableCollections.setDecimal.insert(objectsIn: [Decimal128Wrapper(persistedValue: Decimal128(123.456)), Decimal128Wrapper(persistedValue: Decimal128(234.567))])
            objCustomPersistableCollections.setObjectId.insert(objectsIn: [ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695046")), ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045"))])
            objCustomPersistableCollections.setUuid.insert(objectsIn: [UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!), UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)])
            objModernAllTypesObject.setOptBool.insert(objectsIn: [true, true])
            objModernAllTypesObject.setOptInt.insert(objectsIn: [1, 3])
            objModernAllTypesObject.setOptInt8.insert(objectsIn: [Int8(8), Int8(9)])
            objModernAllTypesObject.setOptInt16.insert(objectsIn: [Int16(16), Int16(17)])
            objModernAllTypesObject.setOptInt32.insert(objectsIn: [Int32(32), Int32(33)])
            objModernAllTypesObject.setOptInt64.insert(objectsIn: [Int64(64), Int64(65)])
            objModernAllTypesObject.setOptFloat.insert(objectsIn: [Float(5.55444333), Float(6.55444333)])
            objModernAllTypesObject.setOptDouble.insert(objectsIn: [123.456, 234.567])
            objModernAllTypesObject.setOptString.insert(objectsIn: ["Foo", "Foó"])
            objModernAllTypesObject.setOptBinary.insert(objectsIn: [Data(count: 64), Data(count: 128)])
            objModernAllTypesObject.setOptDate.insert(objectsIn: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)])
            objModernAllTypesObject.setOptDecimal.insert(objectsIn: [Decimal128(123.456), Decimal128(234.567)])
            objModernAllTypesObject.setOptObjectId.insert(objectsIn: [ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045")])
            objModernAllTypesObject.setOptUuid.insert(objectsIn: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])
            objModernCollectionsOfEnums.setIntOpt.insert(objectsIn: [.value1, .value2])
            objModernCollectionsOfEnums.setInt8Opt.insert(objectsIn: [.value1, .value2])
            objModernCollectionsOfEnums.setInt16Opt.insert(objectsIn: [.value1, .value2])
            objModernCollectionsOfEnums.setInt32Opt.insert(objectsIn: [.value1, .value2])
            objModernCollectionsOfEnums.setInt64Opt.insert(objectsIn: [.value1, .value2])
            objModernCollectionsOfEnums.setFloatOpt.insert(objectsIn: [.value1, .value2])
            objModernCollectionsOfEnums.setDoubleOpt.insert(objectsIn: [.value1, .value2])
            objModernCollectionsOfEnums.setStringOpt.insert(objectsIn: [.value1, .value2])
            objCustomPersistableCollections.setOptBool.insert(objectsIn: [BoolWrapper(persistedValue: true), BoolWrapper(persistedValue: true)])
            objCustomPersistableCollections.setOptInt.insert(objectsIn: [IntWrapper(persistedValue: 1), IntWrapper(persistedValue: 3)])
            objCustomPersistableCollections.setOptInt8.insert(objectsIn: [Int8Wrapper(persistedValue: Int8(8)), Int8Wrapper(persistedValue: Int8(9))])
            objCustomPersistableCollections.setOptInt16.insert(objectsIn: [Int16Wrapper(persistedValue: Int16(16)), Int16Wrapper(persistedValue: Int16(17))])
            objCustomPersistableCollections.setOptInt32.insert(objectsIn: [Int32Wrapper(persistedValue: Int32(32)), Int32Wrapper(persistedValue: Int32(33))])
            objCustomPersistableCollections.setOptInt64.insert(objectsIn: [Int64Wrapper(persistedValue: Int64(64)), Int64Wrapper(persistedValue: Int64(65))])
            objCustomPersistableCollections.setOptFloat.insert(objectsIn: [FloatWrapper(persistedValue: Float(5.55444333)), FloatWrapper(persistedValue: Float(6.55444333))])
            objCustomPersistableCollections.setOptDouble.insert(objectsIn: [DoubleWrapper(persistedValue: 123.456), DoubleWrapper(persistedValue: 234.567)])
            objCustomPersistableCollections.setOptString.insert(objectsIn: [StringWrapper(persistedValue: "Foo"), StringWrapper(persistedValue: "Foó")])
            objCustomPersistableCollections.setOptBinary.insert(objectsIn: [DataWrapper(persistedValue: Data(count: 64)), DataWrapper(persistedValue: Data(count: 128))])
            objCustomPersistableCollections.setOptDate.insert(objectsIn: [DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)), DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000))])
            objCustomPersistableCollections.setOptDecimal.insert(objectsIn: [Decimal128Wrapper(persistedValue: Decimal128(123.456)), Decimal128Wrapper(persistedValue: Decimal128(234.567))])
            objCustomPersistableCollections.setOptObjectId.insert(objectsIn: [ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695046")), ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045"))])
            objCustomPersistableCollections.setOptUuid.insert(objectsIn: [UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!), UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)])

            objModernAllTypesObject.mapBool["foo"] = true
            objModernAllTypesObject.mapBool["bar"] = true
            objModernAllTypesObject.mapInt["foo"] = 1
            objModernAllTypesObject.mapInt["bar"] = 3
            objModernAllTypesObject.mapInt8["foo"] = Int8(8)
            objModernAllTypesObject.mapInt8["bar"] = Int8(9)
            objModernAllTypesObject.mapInt16["foo"] = Int16(16)
            objModernAllTypesObject.mapInt16["bar"] = Int16(17)
            objModernAllTypesObject.mapInt32["foo"] = Int32(32)
            objModernAllTypesObject.mapInt32["bar"] = Int32(33)
            objModernAllTypesObject.mapInt64["foo"] = Int64(64)
            objModernAllTypesObject.mapInt64["bar"] = Int64(65)
            objModernAllTypesObject.mapFloat["foo"] = Float(5.55444333)
            objModernAllTypesObject.mapFloat["bar"] = Float(6.55444333)
            objModernAllTypesObject.mapDouble["foo"] = 123.456
            objModernAllTypesObject.mapDouble["bar"] = 234.567
            objModernAllTypesObject.mapString["foo"] = "Foo"
            objModernAllTypesObject.mapString["bar"] = "Foó"
            objModernAllTypesObject.mapBinary["foo"] = Data(count: 64)
            objModernAllTypesObject.mapBinary["bar"] = Data(count: 128)
            objModernAllTypesObject.mapDate["foo"] = Date(timeIntervalSince1970: 1000000)
            objModernAllTypesObject.mapDate["bar"] = Date(timeIntervalSince1970: 2000000)
            objModernAllTypesObject.mapDecimal["foo"] = Decimal128(123.456)
            objModernAllTypesObject.mapDecimal["bar"] = Decimal128(234.567)
            objModernAllTypesObject.mapObjectId["foo"] = ObjectId("61184062c1d8f096a3695046")
            objModernAllTypesObject.mapObjectId["bar"] = ObjectId("61184062c1d8f096a3695045")
            objModernAllTypesObject.mapUuid["foo"] = UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!
            objModernAllTypesObject.mapUuid["bar"] = UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!
            objModernAllTypesObject.mapAny["foo"] = AnyRealmValue.objectId(ObjectId("61184062c1d8f096a3695046"))
            objModernAllTypesObject.mapAny["bar"] = AnyRealmValue.string("Hello")
            objModernCollectionsOfEnums.mapInt["foo"] = .value1
            objModernCollectionsOfEnums.mapInt["bar"] = .value2
            objModernCollectionsOfEnums.mapInt8["foo"] = .value1
            objModernCollectionsOfEnums.mapInt8["bar"] = .value2
            objModernCollectionsOfEnums.mapInt16["foo"] = .value1
            objModernCollectionsOfEnums.mapInt16["bar"] = .value2
            objModernCollectionsOfEnums.mapInt32["foo"] = .value1
            objModernCollectionsOfEnums.mapInt32["bar"] = .value2
            objModernCollectionsOfEnums.mapInt64["foo"] = .value1
            objModernCollectionsOfEnums.mapInt64["bar"] = .value2
            objModernCollectionsOfEnums.mapFloat["foo"] = .value1
            objModernCollectionsOfEnums.mapFloat["bar"] = .value2
            objModernCollectionsOfEnums.mapDouble["foo"] = .value1
            objModernCollectionsOfEnums.mapDouble["bar"] = .value2
            objModernCollectionsOfEnums.mapString["foo"] = .value1
            objModernCollectionsOfEnums.mapString["bar"] = .value2
            objCustomPersistableCollections.mapBool["foo"] = BoolWrapper(persistedValue: true)
            objCustomPersistableCollections.mapBool["bar"] = BoolWrapper(persistedValue: true)
            objCustomPersistableCollections.mapInt["foo"] = IntWrapper(persistedValue: 1)
            objCustomPersistableCollections.mapInt["bar"] = IntWrapper(persistedValue: 3)
            objCustomPersistableCollections.mapInt8["foo"] = Int8Wrapper(persistedValue: Int8(8))
            objCustomPersistableCollections.mapInt8["bar"] = Int8Wrapper(persistedValue: Int8(9))
            objCustomPersistableCollections.mapInt16["foo"] = Int16Wrapper(persistedValue: Int16(16))
            objCustomPersistableCollections.mapInt16["bar"] = Int16Wrapper(persistedValue: Int16(17))
            objCustomPersistableCollections.mapInt32["foo"] = Int32Wrapper(persistedValue: Int32(32))
            objCustomPersistableCollections.mapInt32["bar"] = Int32Wrapper(persistedValue: Int32(33))
            objCustomPersistableCollections.mapInt64["foo"] = Int64Wrapper(persistedValue: Int64(64))
            objCustomPersistableCollections.mapInt64["bar"] = Int64Wrapper(persistedValue: Int64(65))
            objCustomPersistableCollections.mapFloat["foo"] = FloatWrapper(persistedValue: Float(5.55444333))
            objCustomPersistableCollections.mapFloat["bar"] = FloatWrapper(persistedValue: Float(6.55444333))
            objCustomPersistableCollections.mapDouble["foo"] = DoubleWrapper(persistedValue: 123.456)
            objCustomPersistableCollections.mapDouble["bar"] = DoubleWrapper(persistedValue: 234.567)
            objCustomPersistableCollections.mapString["foo"] = StringWrapper(persistedValue: "Foo")
            objCustomPersistableCollections.mapString["bar"] = StringWrapper(persistedValue: "Foó")
            objCustomPersistableCollections.mapBinary["foo"] = DataWrapper(persistedValue: Data(count: 64))
            objCustomPersistableCollections.mapBinary["bar"] = DataWrapper(persistedValue: Data(count: 128))
            objCustomPersistableCollections.mapDate["foo"] = DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000))
            objCustomPersistableCollections.mapDate["bar"] = DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000))
            objCustomPersistableCollections.mapDecimal["foo"] = Decimal128Wrapper(persistedValue: Decimal128(123.456))
            objCustomPersistableCollections.mapDecimal["bar"] = Decimal128Wrapper(persistedValue: Decimal128(234.567))
            objCustomPersistableCollections.mapObjectId["foo"] = ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695046"))
            objCustomPersistableCollections.mapObjectId["bar"] = ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045"))
            objCustomPersistableCollections.mapUuid["foo"] = UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!)
            objCustomPersistableCollections.mapUuid["bar"] = UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)
            objModernAllTypesObject.mapOptBool["foo"] = true
            objModernAllTypesObject.mapOptBool["bar"] = true
            objModernAllTypesObject.mapOptInt["foo"] = 1
            objModernAllTypesObject.mapOptInt["bar"] = 3
            objModernAllTypesObject.mapOptInt8["foo"] = Int8(8)
            objModernAllTypesObject.mapOptInt8["bar"] = Int8(9)
            objModernAllTypesObject.mapOptInt16["foo"] = Int16(16)
            objModernAllTypesObject.mapOptInt16["bar"] = Int16(17)
            objModernAllTypesObject.mapOptInt32["foo"] = Int32(32)
            objModernAllTypesObject.mapOptInt32["bar"] = Int32(33)
            objModernAllTypesObject.mapOptInt64["foo"] = Int64(64)
            objModernAllTypesObject.mapOptInt64["bar"] = Int64(65)
            objModernAllTypesObject.mapOptFloat["foo"] = Float(5.55444333)
            objModernAllTypesObject.mapOptFloat["bar"] = Float(6.55444333)
            objModernAllTypesObject.mapOptDouble["foo"] = 123.456
            objModernAllTypesObject.mapOptDouble["bar"] = 234.567
            objModernAllTypesObject.mapOptString["foo"] = "Foo"
            objModernAllTypesObject.mapOptString["bar"] = "Foó"
            objModernAllTypesObject.mapOptBinary["foo"] = Data(count: 64)
            objModernAllTypesObject.mapOptBinary["bar"] = Data(count: 128)
            objModernAllTypesObject.mapOptDate["foo"] = Date(timeIntervalSince1970: 1000000)
            objModernAllTypesObject.mapOptDate["bar"] = Date(timeIntervalSince1970: 2000000)
            objModernAllTypesObject.mapOptDecimal["foo"] = Decimal128(123.456)
            objModernAllTypesObject.mapOptDecimal["bar"] = Decimal128(234.567)
            objModernAllTypesObject.mapOptObjectId["foo"] = ObjectId("61184062c1d8f096a3695046")
            objModernAllTypesObject.mapOptObjectId["bar"] = ObjectId("61184062c1d8f096a3695045")
            objModernAllTypesObject.mapOptUuid["foo"] = UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!
            objModernAllTypesObject.mapOptUuid["bar"] = UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!
            objModernCollectionsOfEnums.mapIntOpt["foo"] = .value1
            objModernCollectionsOfEnums.mapIntOpt["bar"] = .value2
            objModernCollectionsOfEnums.mapInt8Opt["foo"] = .value1
            objModernCollectionsOfEnums.mapInt8Opt["bar"] = .value2
            objModernCollectionsOfEnums.mapInt16Opt["foo"] = .value1
            objModernCollectionsOfEnums.mapInt16Opt["bar"] = .value2
            objModernCollectionsOfEnums.mapInt32Opt["foo"] = .value1
            objModernCollectionsOfEnums.mapInt32Opt["bar"] = .value2
            objModernCollectionsOfEnums.mapInt64Opt["foo"] = .value1
            objModernCollectionsOfEnums.mapInt64Opt["bar"] = .value2
            objModernCollectionsOfEnums.mapFloatOpt["foo"] = .value1
            objModernCollectionsOfEnums.mapFloatOpt["bar"] = .value2
            objModernCollectionsOfEnums.mapDoubleOpt["foo"] = .value1
            objModernCollectionsOfEnums.mapDoubleOpt["bar"] = .value2
            objModernCollectionsOfEnums.mapStringOpt["foo"] = .value1
            objModernCollectionsOfEnums.mapStringOpt["bar"] = .value2
            objCustomPersistableCollections.mapOptBool["foo"] = BoolWrapper(persistedValue: true)
            objCustomPersistableCollections.mapOptBool["bar"] = BoolWrapper(persistedValue: true)
            objCustomPersistableCollections.mapOptInt["foo"] = IntWrapper(persistedValue: 1)
            objCustomPersistableCollections.mapOptInt["bar"] = IntWrapper(persistedValue: 3)
            objCustomPersistableCollections.mapOptInt8["foo"] = Int8Wrapper(persistedValue: Int8(8))
            objCustomPersistableCollections.mapOptInt8["bar"] = Int8Wrapper(persistedValue: Int8(9))
            objCustomPersistableCollections.mapOptInt16["foo"] = Int16Wrapper(persistedValue: Int16(16))
            objCustomPersistableCollections.mapOptInt16["bar"] = Int16Wrapper(persistedValue: Int16(17))
            objCustomPersistableCollections.mapOptInt32["foo"] = Int32Wrapper(persistedValue: Int32(32))
            objCustomPersistableCollections.mapOptInt32["bar"] = Int32Wrapper(persistedValue: Int32(33))
            objCustomPersistableCollections.mapOptInt64["foo"] = Int64Wrapper(persistedValue: Int64(64))
            objCustomPersistableCollections.mapOptInt64["bar"] = Int64Wrapper(persistedValue: Int64(65))
            objCustomPersistableCollections.mapOptFloat["foo"] = FloatWrapper(persistedValue: Float(5.55444333))
            objCustomPersistableCollections.mapOptFloat["bar"] = FloatWrapper(persistedValue: Float(6.55444333))
            objCustomPersistableCollections.mapOptDouble["foo"] = DoubleWrapper(persistedValue: 123.456)
            objCustomPersistableCollections.mapOptDouble["bar"] = DoubleWrapper(persistedValue: 234.567)
            objCustomPersistableCollections.mapOptString["foo"] = StringWrapper(persistedValue: "Foo")
            objCustomPersistableCollections.mapOptString["bar"] = StringWrapper(persistedValue: "Foó")
            objCustomPersistableCollections.mapOptBinary["foo"] = DataWrapper(persistedValue: Data(count: 64))
            objCustomPersistableCollections.mapOptBinary["bar"] = DataWrapper(persistedValue: Data(count: 128))
            objCustomPersistableCollections.mapOptDate["foo"] = DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000))
            objCustomPersistableCollections.mapOptDate["bar"] = DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000))
            objCustomPersistableCollections.mapOptDecimal["foo"] = Decimal128Wrapper(persistedValue: Decimal128(123.456))
            objCustomPersistableCollections.mapOptDecimal["bar"] = Decimal128Wrapper(persistedValue: Decimal128(234.567))
            objCustomPersistableCollections.mapOptObjectId["foo"] = ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695046"))
            objCustomPersistableCollections.mapOptObjectId["bar"] = ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045"))
            objCustomPersistableCollections.mapOptUuid["foo"] = UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!)
            objCustomPersistableCollections.mapOptUuid["bar"] = UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)

            realm.add(objAllCustomPersistableTypes)
            realm.add(objModernCollectionsOfEnums)
            realm.add(objModernAllTypesObject)
            realm.add(objCustomPersistableCollections)
        }
    }

    override func tearDown() {
        realm = nil
    }

    private func createKeypathCollectionAggregatesObject() {
        realm.beginWrite()
        realm.deleteAll()

        let parentLinkToCustomPersistableCollections = realm.create(LinkToCustomPersistableCollections.self)
        let childrenCustomPersistableCollections = [CustomPersistableCollections(), CustomPersistableCollections(), CustomPersistableCollections()]
        parentLinkToCustomPersistableCollections.list.append(objectsIn: childrenCustomPersistableCollections)

        let parentLinkToAllCustomPersistableTypes = realm.create(LinkToAllCustomPersistableTypes.self)
        let childrenAllCustomPersistableTypes = [AllCustomPersistableTypes(), AllCustomPersistableTypes(), AllCustomPersistableTypes()]
        parentLinkToAllCustomPersistableTypes.list.append(objectsIn: childrenAllCustomPersistableTypes)

        let parentLinkToModernAllTypesObject = realm.create(LinkToModernAllTypesObject.self)
        let childrenModernAllTypesObject = [ModernAllTypesObject(), ModernAllTypesObject(), ModernAllTypesObject()]
        parentLinkToModernAllTypesObject.list.append(objectsIn: childrenModernAllTypesObject)

        let parentLinkToModernCollectionsOfEnums = realm.create(LinkToModernCollectionsOfEnums.self)
        let childrenModernCollectionsOfEnums = [ModernCollectionsOfEnums(), ModernCollectionsOfEnums(), ModernCollectionsOfEnums()]
        parentLinkToModernCollectionsOfEnums.list.append(objectsIn: childrenModernCollectionsOfEnums)


        initForKeypathCollectionAggregates(childrenModernAllTypesObject, \.intCol)
        initForKeypathCollectionAggregates(childrenModernAllTypesObject, \.int8Col)
        initForKeypathCollectionAggregates(childrenModernAllTypesObject, \.int16Col)
        initForKeypathCollectionAggregates(childrenModernAllTypesObject, \.int32Col)
        initForKeypathCollectionAggregates(childrenModernAllTypesObject, \.int64Col)
        initForKeypathCollectionAggregates(childrenModernAllTypesObject, \.floatCol)
        initForKeypathCollectionAggregates(childrenModernAllTypesObject, \.doubleCol)
        initForKeypathCollectionAggregates(childrenModernAllTypesObject, \.dateCol)
        initForKeypathCollectionAggregates(childrenModernAllTypesObject, \.decimalCol)
        initForKeypathCollectionAggregates(childrenModernAllTypesObject, \.intEnumCol)
        initForKeypathCollectionAggregates(childrenAllCustomPersistableTypes, \.int)
        initForKeypathCollectionAggregates(childrenAllCustomPersistableTypes, \.int8)
        initForKeypathCollectionAggregates(childrenAllCustomPersistableTypes, \.int16)
        initForKeypathCollectionAggregates(childrenAllCustomPersistableTypes, \.int32)
        initForKeypathCollectionAggregates(childrenAllCustomPersistableTypes, \.int64)
        initForKeypathCollectionAggregates(childrenAllCustomPersistableTypes, \.float)
        initForKeypathCollectionAggregates(childrenAllCustomPersistableTypes, \.double)
        initForKeypathCollectionAggregates(childrenAllCustomPersistableTypes, \.date)
        initForKeypathCollectionAggregates(childrenAllCustomPersistableTypes, \.decimal)
        initForKeypathCollectionAggregates(childrenModernAllTypesObject, \.optIntCol)
        initForKeypathCollectionAggregates(childrenModernAllTypesObject, \.optInt8Col)
        initForKeypathCollectionAggregates(childrenModernAllTypesObject, \.optInt16Col)
        initForKeypathCollectionAggregates(childrenModernAllTypesObject, \.optInt32Col)
        initForKeypathCollectionAggregates(childrenModernAllTypesObject, \.optInt64Col)
        initForKeypathCollectionAggregates(childrenModernAllTypesObject, \.optFloatCol)
        initForKeypathCollectionAggregates(childrenModernAllTypesObject, \.optDoubleCol)
        initForKeypathCollectionAggregates(childrenModernAllTypesObject, \.optDateCol)
        initForKeypathCollectionAggregates(childrenModernAllTypesObject, \.optDecimalCol)
        initForKeypathCollectionAggregates(childrenModernAllTypesObject, \.optIntEnumCol)
        initForKeypathCollectionAggregates(childrenAllCustomPersistableTypes, \.optInt)
        initForKeypathCollectionAggregates(childrenAllCustomPersistableTypes, \.optInt8)
        initForKeypathCollectionAggregates(childrenAllCustomPersistableTypes, \.optInt16)
        initForKeypathCollectionAggregates(childrenAllCustomPersistableTypes, \.optInt32)
        initForKeypathCollectionAggregates(childrenAllCustomPersistableTypes, \.optInt64)
        initForKeypathCollectionAggregates(childrenAllCustomPersistableTypes, \.optFloat)
        initForKeypathCollectionAggregates(childrenAllCustomPersistableTypes, \.optDouble)
        initForKeypathCollectionAggregates(childrenAllCustomPersistableTypes, \.optDate)
        initForKeypathCollectionAggregates(childrenAllCustomPersistableTypes, \.optDecimal)

        try! realm.commitWrite()
    }

    private func initForKeypathCollectionAggregates<O: Object, T: QueryValue>(
            _ objects: [O],
            _ keyPath: ReferenceWritableKeyPath<O, T>) {
        for (obj, value) in zip(objects, T.queryValues()) {
            obj[keyPath: keyPath] = value
        }
    }

    private func initLinkedCollectionAggregatesObject() {
        realm.beginWrite()
        realm.deleteAll()

        let parentLinkToModernCollectionsOfEnums = realm.create(LinkToModernCollectionsOfEnums.self)
        let objModernCollectionsOfEnums = ModernCollectionsOfEnums()
        parentLinkToModernCollectionsOfEnums["object"] = objModernCollectionsOfEnums
        let parentLinkToCustomPersistableCollections = realm.create(LinkToCustomPersistableCollections.self)
        let objCustomPersistableCollections = CustomPersistableCollections()
        parentLinkToCustomPersistableCollections["object"] = objCustomPersistableCollections
        let parentLinkToModernAllTypesObject = realm.create(LinkToModernAllTypesObject.self)
        let objModernAllTypesObject = ModernAllTypesObject()
        parentLinkToModernAllTypesObject["object"] = objModernAllTypesObject

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
        objCustomPersistableCollections["listBool"] = BoolWrapper.queryValues()
        objCustomPersistableCollections["listInt"] = IntWrapper.queryValues()
        objCustomPersistableCollections["listInt8"] = Int8Wrapper.queryValues()
        objCustomPersistableCollections["listInt16"] = Int16Wrapper.queryValues()
        objCustomPersistableCollections["listInt32"] = Int32Wrapper.queryValues()
        objCustomPersistableCollections["listInt64"] = Int64Wrapper.queryValues()
        objCustomPersistableCollections["listFloat"] = FloatWrapper.queryValues()
        objCustomPersistableCollections["listDouble"] = DoubleWrapper.queryValues()
        objCustomPersistableCollections["listString"] = StringWrapper.queryValues()
        objCustomPersistableCollections["listBinary"] = DataWrapper.queryValues()
        objCustomPersistableCollections["listDate"] = DateWrapper.queryValues()
        objCustomPersistableCollections["listDecimal"] = Decimal128Wrapper.queryValues()
        objCustomPersistableCollections["listObjectId"] = ObjectIdWrapper.queryValues()
        objCustomPersistableCollections["listUuid"] = UUIDWrapper.queryValues()
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
        objCustomPersistableCollections["listOptBool"] = BoolWrapper?.queryValues()
        objCustomPersistableCollections["listOptInt"] = IntWrapper?.queryValues()
        objCustomPersistableCollections["listOptInt8"] = Int8Wrapper?.queryValues()
        objCustomPersistableCollections["listOptInt16"] = Int16Wrapper?.queryValues()
        objCustomPersistableCollections["listOptInt32"] = Int32Wrapper?.queryValues()
        objCustomPersistableCollections["listOptInt64"] = Int64Wrapper?.queryValues()
        objCustomPersistableCollections["listOptFloat"] = FloatWrapper?.queryValues()
        objCustomPersistableCollections["listOptDouble"] = DoubleWrapper?.queryValues()
        objCustomPersistableCollections["listOptString"] = StringWrapper?.queryValues()
        objCustomPersistableCollections["listOptBinary"] = DataWrapper?.queryValues()
        objCustomPersistableCollections["listOptDate"] = DateWrapper?.queryValues()
        objCustomPersistableCollections["listOptDecimal"] = Decimal128Wrapper?.queryValues()
        objCustomPersistableCollections["listOptObjectId"] = ObjectIdWrapper?.queryValues()
        objCustomPersistableCollections["listOptUuid"] = UUIDWrapper?.queryValues()
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
        objCustomPersistableCollections["setBool"] = BoolWrapper.queryValues()
        objCustomPersistableCollections["setInt"] = IntWrapper.queryValues()
        objCustomPersistableCollections["setInt8"] = Int8Wrapper.queryValues()
        objCustomPersistableCollections["setInt16"] = Int16Wrapper.queryValues()
        objCustomPersistableCollections["setInt32"] = Int32Wrapper.queryValues()
        objCustomPersistableCollections["setInt64"] = Int64Wrapper.queryValues()
        objCustomPersistableCollections["setFloat"] = FloatWrapper.queryValues()
        objCustomPersistableCollections["setDouble"] = DoubleWrapper.queryValues()
        objCustomPersistableCollections["setString"] = StringWrapper.queryValues()
        objCustomPersistableCollections["setBinary"] = DataWrapper.queryValues()
        objCustomPersistableCollections["setDate"] = DateWrapper.queryValues()
        objCustomPersistableCollections["setDecimal"] = Decimal128Wrapper.queryValues()
        objCustomPersistableCollections["setObjectId"] = ObjectIdWrapper.queryValues()
        objCustomPersistableCollections["setUuid"] = UUIDWrapper.queryValues()
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
        objCustomPersistableCollections["setOptBool"] = BoolWrapper?.queryValues()
        objCustomPersistableCollections["setOptInt"] = IntWrapper?.queryValues()
        objCustomPersistableCollections["setOptInt8"] = Int8Wrapper?.queryValues()
        objCustomPersistableCollections["setOptInt16"] = Int16Wrapper?.queryValues()
        objCustomPersistableCollections["setOptInt32"] = Int32Wrapper?.queryValues()
        objCustomPersistableCollections["setOptInt64"] = Int64Wrapper?.queryValues()
        objCustomPersistableCollections["setOptFloat"] = FloatWrapper?.queryValues()
        objCustomPersistableCollections["setOptDouble"] = DoubleWrapper?.queryValues()
        objCustomPersistableCollections["setOptString"] = StringWrapper?.queryValues()
        objCustomPersistableCollections["setOptBinary"] = DataWrapper?.queryValues()
        objCustomPersistableCollections["setOptDate"] = DateWrapper?.queryValues()
        objCustomPersistableCollections["setOptDecimal"] = Decimal128Wrapper?.queryValues()
        objCustomPersistableCollections["setOptObjectId"] = ObjectIdWrapper?.queryValues()
        objCustomPersistableCollections["setOptUuid"] = UUIDWrapper?.queryValues()
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
        populateMap(objCustomPersistableCollections.mapBool)
        populateMap(objCustomPersistableCollections.mapInt)
        populateMap(objCustomPersistableCollections.mapInt8)
        populateMap(objCustomPersistableCollections.mapInt16)
        populateMap(objCustomPersistableCollections.mapInt32)
        populateMap(objCustomPersistableCollections.mapInt64)
        populateMap(objCustomPersistableCollections.mapFloat)
        populateMap(objCustomPersistableCollections.mapDouble)
        populateMap(objCustomPersistableCollections.mapString)
        populateMap(objCustomPersistableCollections.mapBinary)
        populateMap(objCustomPersistableCollections.mapDate)
        populateMap(objCustomPersistableCollections.mapDecimal)
        populateMap(objCustomPersistableCollections.mapObjectId)
        populateMap(objCustomPersistableCollections.mapUuid)
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
        populateMap(objCustomPersistableCollections.mapOptBool)
        populateMap(objCustomPersistableCollections.mapOptInt)
        populateMap(objCustomPersistableCollections.mapOptInt8)
        populateMap(objCustomPersistableCollections.mapOptInt16)
        populateMap(objCustomPersistableCollections.mapOptInt32)
        populateMap(objCustomPersistableCollections.mapOptInt64)
        populateMap(objCustomPersistableCollections.mapOptFloat)
        populateMap(objCustomPersistableCollections.mapOptDouble)
        populateMap(objCustomPersistableCollections.mapOptString)
        populateMap(objCustomPersistableCollections.mapOptBinary)
        populateMap(objCustomPersistableCollections.mapOptDate)
        populateMap(objCustomPersistableCollections.mapOptDecimal)
        populateMap(objCustomPersistableCollections.mapOptObjectId)
        populateMap(objCustomPersistableCollections.mapOptUuid)

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

    // MARK: - Basic Comparison

    func validateEquals<Root: Object, T: _Persistable>(
            _ name: String, _ lhs: (Query<Root>) -> Query<T>, _ value: T,
            equalCount: Int = 1, notEqualCount: Int = 0) {
        assertQuery(Root.self, "(\(name) == %@)", value, count: equalCount) {
            lhs($0) == value
        }
        assertQuery(Root.self, "(\(name) != %@)", value, count: notEqualCount) {
            lhs($0) != value
        }
    }
    func validateEqualsNil<Root: Object, T: _RealmSchemaDiscoverable & ExpressibleByNilLiteral>(
            _ name: String, _ lhs: (Query<Root>) -> Query<T>) {
        assertQuery(Root.self, "(\(name) == %@)", NSNull(), count: 0) {
            lhs($0) == nil
        }
        assertQuery(Root.self, "(\(name) != %@)", NSNull(), count: 1) {
            lhs($0) != nil
        }
    }

    func testEquals() {
        validateEquals("boolCol", \Query<ModernAllTypesObject>.boolCol, false)
        validateEquals("intCol", \Query<ModernAllTypesObject>.intCol, 3)
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
        validateEquals("bool", \Query<AllCustomPersistableTypes>.bool, BoolWrapper(persistedValue: false))
        validateEquals("int", \Query<AllCustomPersistableTypes>.int, IntWrapper(persistedValue: 3))
        validateEquals("int8", \Query<AllCustomPersistableTypes>.int8, Int8Wrapper(persistedValue: Int8(9)))
        validateEquals("int16", \Query<AllCustomPersistableTypes>.int16, Int16Wrapper(persistedValue: Int16(17)))
        validateEquals("int32", \Query<AllCustomPersistableTypes>.int32, Int32Wrapper(persistedValue: Int32(33)))
        validateEquals("int64", \Query<AllCustomPersistableTypes>.int64, Int64Wrapper(persistedValue: Int64(65)))
        validateEquals("float", \Query<AllCustomPersistableTypes>.float, FloatWrapper(persistedValue: Float(6.55444333)))
        validateEquals("double", \Query<AllCustomPersistableTypes>.double, DoubleWrapper(persistedValue: 234.567))
        validateEquals("string", \Query<AllCustomPersistableTypes>.string, StringWrapper(persistedValue: "Foó"))
        validateEquals("binary", \Query<AllCustomPersistableTypes>.binary, DataWrapper(persistedValue: Data(count: 128)))
        validateEquals("date", \Query<AllCustomPersistableTypes>.date, DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)))
        validateEquals("decimal", \Query<AllCustomPersistableTypes>.decimal, Decimal128Wrapper(persistedValue: Decimal128(234.567)))
        validateEquals("objectId", \Query<AllCustomPersistableTypes>.objectId, ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045")))
        validateEquals("uuid", \Query<AllCustomPersistableTypes>.uuid, UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!))
        validateEquals("optBoolCol", \Query<ModernAllTypesObject>.optBoolCol, false)
        validateEquals("optIntCol", \Query<ModernAllTypesObject>.optIntCol, 3)
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
        validateEquals("optBool", \Query<AllCustomPersistableTypes>.optBool, BoolWrapper(persistedValue: false))
        validateEquals("optInt", \Query<AllCustomPersistableTypes>.optInt, IntWrapper(persistedValue: 3))
        validateEquals("optInt8", \Query<AllCustomPersistableTypes>.optInt8, Int8Wrapper(persistedValue: Int8(9)))
        validateEquals("optInt16", \Query<AllCustomPersistableTypes>.optInt16, Int16Wrapper(persistedValue: Int16(17)))
        validateEquals("optInt32", \Query<AllCustomPersistableTypes>.optInt32, Int32Wrapper(persistedValue: Int32(33)))
        validateEquals("optInt64", \Query<AllCustomPersistableTypes>.optInt64, Int64Wrapper(persistedValue: Int64(65)))
        validateEquals("optFloat", \Query<AllCustomPersistableTypes>.optFloat, FloatWrapper(persistedValue: Float(6.55444333)))
        validateEquals("optDouble", \Query<AllCustomPersistableTypes>.optDouble, DoubleWrapper(persistedValue: 234.567))
        validateEquals("optString", \Query<AllCustomPersistableTypes>.optString, StringWrapper(persistedValue: "Foó"))
        validateEquals("optBinary", \Query<AllCustomPersistableTypes>.optBinary, DataWrapper(persistedValue: Data(count: 128)))
        validateEquals("optDate", \Query<AllCustomPersistableTypes>.optDate, DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)))
        validateEquals("optDecimal", \Query<AllCustomPersistableTypes>.optDecimal, Decimal128Wrapper(persistedValue: Decimal128(234.567)))
        validateEquals("optObjectId", \Query<AllCustomPersistableTypes>.optObjectId, ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045")))
        validateEquals("optUuid", \Query<AllCustomPersistableTypes>.optUuid, UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!))

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
        validateEqualsNil("optBool", \Query<AllCustomPersistableTypes>.optBool)
        validateEqualsNil("optInt", \Query<AllCustomPersistableTypes>.optInt)
        validateEqualsNil("optInt8", \Query<AllCustomPersistableTypes>.optInt8)
        validateEqualsNil("optInt16", \Query<AllCustomPersistableTypes>.optInt16)
        validateEqualsNil("optInt32", \Query<AllCustomPersistableTypes>.optInt32)
        validateEqualsNil("optInt64", \Query<AllCustomPersistableTypes>.optInt64)
        validateEqualsNil("optFloat", \Query<AllCustomPersistableTypes>.optFloat)
        validateEqualsNil("optDouble", \Query<AllCustomPersistableTypes>.optDouble)
        validateEqualsNil("optString", \Query<AllCustomPersistableTypes>.optString)
        validateEqualsNil("optBinary", \Query<AllCustomPersistableTypes>.optBinary)
        validateEqualsNil("optDate", \Query<AllCustomPersistableTypes>.optDate)
        validateEqualsNil("optDecimal", \Query<AllCustomPersistableTypes>.optDecimal)
        validateEqualsNil("optObjectId", \Query<AllCustomPersistableTypes>.optObjectId)
        validateEqualsNil("optUuid", \Query<AllCustomPersistableTypes>.optUuid)
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

    private func createLinksToMappedEmbeddedObject() {
        try! realm.write {
            let obj = realm.objects(AllCustomPersistableTypes.self).first!
            obj.object = EmbeddedObjectWrapper(value: 2)
            _ = realm.create(LinkToAllCustomPersistableTypes.self, value: [obj, [obj], [obj], ["1": obj]])
        }
    }

    func testEqualMappedToEmbeddedObject() {
        createLinksToMappedEmbeddedObject()

        assertQuery(AllCustomPersistableTypes.self, "(object.value == %@)", 2, count: 1) {
            $0.object.persistableValue.value == 2
        }
        assertQuery(AllCustomPersistableTypes.self, "(object == %@)", EmbeddedObjectWrapper(value: 2), count: 1) {
            $0.object == EmbeddedObjectWrapper(value: 2)
        }
        assertQuery(AllCustomPersistableTypes.self, "(object.value == %@)", 3, count: 0) {
            $0.object.persistableValue.value == 3
        }
        assertQuery(AllCustomPersistableTypes.self, "(object == %@)", EmbeddedObjectWrapper(value: 3), count: 0) {
            $0.object == EmbeddedObjectWrapper(value: 3)
        }

        assertQuery(LinkToAllCustomPersistableTypes.self, "(object.object.value == %@)", 2, count: 1) {
            $0.object.object.persistableValue.value == 2
        }
        assertQuery(LinkToAllCustomPersistableTypes.self, "(object.object == %@)", EmbeddedObjectWrapper(value: 2), count: 1) {
            $0.object.object == EmbeddedObjectWrapper(value: 2)
        }
        assertQuery(LinkToAllCustomPersistableTypes.self, "(object.object.value == %@)", 3, count: 0) {
            $0.object.object.persistableValue.value == 3
        }
        assertQuery(LinkToAllCustomPersistableTypes.self, "(object.object == %@)", EmbeddedObjectWrapper(value: 3), count: 0) {
            $0.object.object == EmbeddedObjectWrapper(value: 3)
        }

        assertQuery(LinkToAllCustomPersistableTypes.self, "(ANY list.object.value == %@)", 2, count: 1) {
            $0.list.object.persistableValue.value == 2
        }
        assertQuery(LinkToAllCustomPersistableTypes.self, "(ANY list.object == %@)", EmbeddedObjectWrapper(value: 2), count: 1) {
            $0.list.object == EmbeddedObjectWrapper(value: 2)
        }
        assertQuery(LinkToAllCustomPersistableTypes.self, "(ANY list.object.value == %@)", 3, count: 0) {
            $0.list.object.persistableValue.value == 3
        }
        assertQuery(LinkToAllCustomPersistableTypes.self, "(ANY list.object == %@)", EmbeddedObjectWrapper(value: 3), count: 0) {
            $0.list.object == EmbeddedObjectWrapper(value: 3)
        }

        assertQuery(LinkToAllCustomPersistableTypes.self, "(ANY set.object.value == %@)", 2, count: 1) {
            $0.set.object.persistableValue.value == 2
        }
        assertQuery(LinkToAllCustomPersistableTypes.self, "(ANY set.object == %@)", EmbeddedObjectWrapper(value: 2), count: 1) {
            $0.set.object == EmbeddedObjectWrapper(value: 2)
        }
        assertQuery(LinkToAllCustomPersistableTypes.self, "(ANY set.object.value == %@)", 3, count: 0) {
            $0.set.object.persistableValue.value == 3
        }
        assertQuery(LinkToAllCustomPersistableTypes.self, "(ANY set.object == %@)", EmbeddedObjectWrapper(value: 3), count: 0) {
            $0.set.object == EmbeddedObjectWrapper(value: 3)
        }

        assertQuery(LinkToAllCustomPersistableTypes.self, "(ANY map.@allValues.object.value == %@)", 2, count: 1) {
            $0.map.values.object.persistableValue.value == 2
        }
        assertQuery(LinkToAllCustomPersistableTypes.self, "(ANY map.@allValues.object == %@)", EmbeddedObjectWrapper(value: 2), count: 1) {
            $0.map.values.object == EmbeddedObjectWrapper(value: 2)
        }
        assertQuery(LinkToAllCustomPersistableTypes.self, "(ANY map.@allValues.object.value == %@)", 3, count: 0) {
            $0.map.values.object.persistableValue.value == 3
        }
        assertQuery(LinkToAllCustomPersistableTypes.self, "(ANY map.@allValues.object == %@)", EmbeddedObjectWrapper(value: 3), count: 0) {
            $0.map.values.object == EmbeddedObjectWrapper(value: 3)
        }
    }

    func testMemberwiseEquality() {
        realm.beginWrite()
        let obj1 = AddressSwiftWrapper(persistedValue: AddressSwift(value: ["a", "b"]))
        let obj2 = AddressSwiftWrapper(persistedValue: AddressSwift(value: ["a", "c"]))
        let obj3 = AddressSwiftWrapper(persistedValue: AddressSwift(value: ["b", "b"]))
        let linkObj1 = realm.create(LinkToAddressSwiftWrapper.self, value: [obj1, obj1])
        let linkObj2 = realm.create(LinkToAddressSwiftWrapper.self, value: [obj2, obj2])
        _ = realm.create(LinkToAddressSwiftWrapper.self, value: [obj3, obj3])

        // Test basic equality
        assertQuery(LinkToAddressSwiftWrapper.self, "(object == %@)", obj1, count: 1) {
            $0.object == obj1
        }
        assertQuery(LinkToAddressSwiftWrapper.self, "(object != %@)", obj1, count: 2) {
            $0.object != obj1
        }
        assertQuery(LinkToAddressSwiftWrapper.self, "(optObject == %@)", obj1, count: 1) {
            $0.optObject == obj1
        }
        assertQuery(LinkToAddressSwiftWrapper.self, "(optObject != %@)", obj1, count: 2) {
            $0.optObject != obj1
        }

        // Verify that the expanded comparison nested groups correctly. If it doesn't
        // start/end a subgroup, it'd end up as ((x or y) and z) instead of (x or (y and z)).
        assertQuery(LinkToAddressSwiftWrapper.self, "((object.city != %@) || (object == %@))", values: ["c", obj1], count: 3) {
            $0.object.persistableValue.city != "c" || $0.object == obj1
        }
        // Check for ((x and y) or Z) rather than (x and (y or z))
        assertQuery(LinkToAddressSwiftWrapper.self, "((object == %@) || (object.city != %@))", values: [obj1, "c"], count: 3) {
             $0.object == obj1 || $0.object.persistableValue.city != "c"
        }

        // Basic equality in collections
        linkObj1.list.append(obj1)
        linkObj1.map["foo"] = obj1
        linkObj1.optMap["foo"] = obj1

        assertQuery(LinkToAddressSwiftWrapper.self, "(ANY list == %@)", obj1, count: 1) {
            $0.list == obj1
        }
        assertQuery(LinkToAddressSwiftWrapper.self, "(ANY list != %@)", obj1, count: 0) {
            $0.list != obj1
        }
        assertQuery(LinkToAddressSwiftWrapper.self, "(ANY map.@allValues == %@)", obj1, count: 1) {
            $0.map.values == obj1
        }
        assertQuery(LinkToAddressSwiftWrapper.self, "(ANY map.@allValues != %@)", obj1, count: 0) {
            $0.map.values != obj1
        }
        assertQuery(LinkToAddressSwiftWrapper.self, "(ANY optMap.@allValues != %@)", obj1, count: 0) {
            $0.optMap.values != obj1
        }
        assertQuery(LinkToAddressSwiftWrapper.self, "(ANY optMap.@allValues == %@)", obj1, count: 1) {
            $0.optMap.values == obj1
        }

        // Verify that collections use a subquery. If they didn't, this object would
        // now match as it has objects which match each property separately
        linkObj2.list.append(obj2)
        linkObj2.list.append(obj3)

        assertQuery(LinkToAddressSwiftWrapper.self, "(ANY list == %@)", obj1, count: 1) {
            $0.list == obj1
        }
        assertQuery(LinkToAddressSwiftWrapper.self, "(ANY list != %@)", obj1, count: 1) {
            $0.list != obj1
        }

        realm.cancelWrite()
    }

    func testInvalidMemberwiseEquality() {
        assertThrows(assertQuery(LinkToWrapperForTypeWithObjectLink.self, "", count: 0) {
            $0.link == WrapperForTypeWithObjectLink()
        }, reason: "Unsupported property 'TypeWithObjectLink.value' for memberwise equality query: object links are not implemented.")
        assertThrows(assertQuery(LinkToWrapperForTypeWithCollection.self, "", count: 0) {
            $0.link == WrapperForTypeWithCollection()
        }, reason: "Unsupported property 'TypeWithCollection.list' for memberwise equality query: equality on collections is not implemented.")
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

    func testNotEqualMappedToEmbeddedObject() {
        createLinksToMappedEmbeddedObject()

        assertQuery(AllCustomPersistableTypes.self, "(object.value != %@)", 2, count: 0) {
            $0.object.persistableValue.value != 2
        }
        assertQuery(AllCustomPersistableTypes.self, "(object != %@)", EmbeddedObjectWrapper(value: 2), count: 0) {
            $0.object != EmbeddedObjectWrapper(value: 2)
        }
        assertQuery(AllCustomPersistableTypes.self, "(object.value != %@)", 3, count: 1) {
            $0.object.persistableValue.value != 3
        }
        assertQuery(AllCustomPersistableTypes.self, "(object != %@)", EmbeddedObjectWrapper(value: 3), count: 1) {
            $0.object != EmbeddedObjectWrapper(value: 3)
        }


        assertQuery(LinkToAllCustomPersistableTypes.self, "(object.object.value != %@)", 2, count: 0) {
            $0.object.object.persistableValue.value != 2
        }
        assertQuery(LinkToAllCustomPersistableTypes.self, "(object.object != %@)", EmbeddedObjectWrapper(value: 2), count: 0) {
            $0.object.object != EmbeddedObjectWrapper(value: 2)
        }
        assertQuery(LinkToAllCustomPersistableTypes.self, "(object.object.value != %@)", 3, count: 1) {
            $0.object.object.persistableValue.value != 3
        }
        assertQuery(LinkToAllCustomPersistableTypes.self, "(object.object != %@)", EmbeddedObjectWrapper(value: 3), count: 1) {
            $0.object.object != EmbeddedObjectWrapper(value: 3)
        }

        assertQuery(LinkToAllCustomPersistableTypes.self, "(ANY list.object.value != %@)", 2, count: 0) {
            $0.list.object.persistableValue.value != 2
        }
        assertQuery(LinkToAllCustomPersistableTypes.self, "(ANY list.object != %@)", EmbeddedObjectWrapper(value: 2), count: 0) {
            $0.list.object != EmbeddedObjectWrapper(value: 2)
        }
        assertQuery(LinkToAllCustomPersistableTypes.self, "(ANY list.object.value != %@)", 3, count: 1) {
            $0.list.object.persistableValue.value != 3
        }
        assertQuery(LinkToAllCustomPersistableTypes.self, "(ANY list.object != %@)", EmbeddedObjectWrapper(value: 3), count: 1) {
            $0.list.object != EmbeddedObjectWrapper(value: 3)
        }

        assertQuery(LinkToAllCustomPersistableTypes.self, "(ANY set.object.value != %@)", 2, count: 0) {
            $0.set.object.persistableValue.value != 2
        }
        assertQuery(LinkToAllCustomPersistableTypes.self, "(ANY set.object != %@)", EmbeddedObjectWrapper(value: 2), count: 0) {
            $0.set.object != EmbeddedObjectWrapper(value: 2)
        }
        assertQuery(LinkToAllCustomPersistableTypes.self, "(ANY set.object.value != %@)", 3, count: 1) {
            $0.set.object.persistableValue.value != 3
        }
        assertQuery(LinkToAllCustomPersistableTypes.self, "(ANY set.object != %@)", EmbeddedObjectWrapper(value: 3), count: 1) {
            $0.set.object != EmbeddedObjectWrapper(value: 3)
        }

        assertQuery(LinkToAllCustomPersistableTypes.self, "(ANY map.@allValues.object.value != %@)", 2, count: 0) {
            $0.map.values.object.persistableValue.value != 2
        }
        assertQuery(LinkToAllCustomPersistableTypes.self, "(ANY map.@allValues.object != %@)", EmbeddedObjectWrapper(value: 2), count: 0) {
            $0.map.values.object != EmbeddedObjectWrapper(value: 2)
        }
        assertQuery(LinkToAllCustomPersistableTypes.self, "(ANY map.@allValues.object.value != %@)", 3, count: 1) {
            $0.map.values.object.persistableValue.value != 3
        }
        assertQuery(LinkToAllCustomPersistableTypes.self, "(ANY map.@allValues.object != %@)", EmbeddedObjectWrapper(value: 3), count: 1) {
            $0.map.values.object != EmbeddedObjectWrapper(value: 3)
        }
    }

    func validateNumericComparisons<Root: Object, T: _Persistable>(
            _ name: String, _ lhs: (Query<Root>) -> Query<T>,
            _ value: T, count: Int = 1, ltCount: Int = 0, gtCount: Int = 0) where T.PersistedType: _QueryNumeric {
        assertQuery(Root.self, "(\(name) > %@)", value, count: gtCount) {
            lhs($0) > value
        }
        assertQuery(Root.self, "(\(name) >= %@)", value, count: count) {
            lhs($0) >= value
        }
        assertQuery(Root.self, "(\(name) < %@)", value, count: ltCount) {
            lhs($0) < value
        }
        assertQuery(Root.self, "(\(name) <= %@)", value, count: count) {
            lhs($0) <= value
        }
    }

    func testNumericComparisons() {
        validateNumericComparisons("intCol", \Query<ModernAllTypesObject>.intCol, 3)
        validateNumericComparisons("int8Col", \Query<ModernAllTypesObject>.int8Col, Int8(9))
        validateNumericComparisons("int16Col", \Query<ModernAllTypesObject>.int16Col, Int16(17))
        validateNumericComparisons("int32Col", \Query<ModernAllTypesObject>.int32Col, Int32(33))
        validateNumericComparisons("int64Col", \Query<ModernAllTypesObject>.int64Col, Int64(65))
        validateNumericComparisons("floatCol", \Query<ModernAllTypesObject>.floatCol, Float(6.55444333))
        validateNumericComparisons("doubleCol", \Query<ModernAllTypesObject>.doubleCol, 234.567)
        validateNumericComparisons("dateCol", \Query<ModernAllTypesObject>.dateCol, Date(timeIntervalSince1970: 2000000))
        validateNumericComparisons("decimalCol", \Query<ModernAllTypesObject>.decimalCol, Decimal128(234.567))
        validateNumericComparisons("intEnumCol", \Query<ModernAllTypesObject>.intEnumCol, .value2)
        validateNumericComparisons("int", \Query<AllCustomPersistableTypes>.int, IntWrapper(persistedValue: 3))
        validateNumericComparisons("int8", \Query<AllCustomPersistableTypes>.int8, Int8Wrapper(persistedValue: Int8(9)))
        validateNumericComparisons("int16", \Query<AllCustomPersistableTypes>.int16, Int16Wrapper(persistedValue: Int16(17)))
        validateNumericComparisons("int32", \Query<AllCustomPersistableTypes>.int32, Int32Wrapper(persistedValue: Int32(33)))
        validateNumericComparisons("int64", \Query<AllCustomPersistableTypes>.int64, Int64Wrapper(persistedValue: Int64(65)))
        validateNumericComparisons("float", \Query<AllCustomPersistableTypes>.float, FloatWrapper(persistedValue: Float(6.55444333)))
        validateNumericComparisons("double", \Query<AllCustomPersistableTypes>.double, DoubleWrapper(persistedValue: 234.567))
        validateNumericComparisons("date", \Query<AllCustomPersistableTypes>.date, DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)))
        validateNumericComparisons("decimal", \Query<AllCustomPersistableTypes>.decimal, Decimal128Wrapper(persistedValue: Decimal128(234.567)))
        validateNumericComparisons("optIntCol", \Query<ModernAllTypesObject>.optIntCol, 3)
        validateNumericComparisons("optInt8Col", \Query<ModernAllTypesObject>.optInt8Col, Int8(9))
        validateNumericComparisons("optInt16Col", \Query<ModernAllTypesObject>.optInt16Col, Int16(17))
        validateNumericComparisons("optInt32Col", \Query<ModernAllTypesObject>.optInt32Col, Int32(33))
        validateNumericComparisons("optInt64Col", \Query<ModernAllTypesObject>.optInt64Col, Int64(65))
        validateNumericComparisons("optFloatCol", \Query<ModernAllTypesObject>.optFloatCol, Float(6.55444333))
        validateNumericComparisons("optDoubleCol", \Query<ModernAllTypesObject>.optDoubleCol, 234.567)
        validateNumericComparisons("optDateCol", \Query<ModernAllTypesObject>.optDateCol, Date(timeIntervalSince1970: 2000000))
        validateNumericComparisons("optDecimalCol", \Query<ModernAllTypesObject>.optDecimalCol, Decimal128(234.567))
        validateNumericComparisons("optIntEnumCol", \Query<ModernAllTypesObject>.optIntEnumCol, .value2)
        validateNumericComparisons("optInt", \Query<AllCustomPersistableTypes>.optInt, IntWrapper(persistedValue: 3))
        validateNumericComparisons("optInt8", \Query<AllCustomPersistableTypes>.optInt8, Int8Wrapper(persistedValue: Int8(9)))
        validateNumericComparisons("optInt16", \Query<AllCustomPersistableTypes>.optInt16, Int16Wrapper(persistedValue: Int16(17)))
        validateNumericComparisons("optInt32", \Query<AllCustomPersistableTypes>.optInt32, Int32Wrapper(persistedValue: Int32(33)))
        validateNumericComparisons("optInt64", \Query<AllCustomPersistableTypes>.optInt64, Int64Wrapper(persistedValue: Int64(65)))
        validateNumericComparisons("optFloat", \Query<AllCustomPersistableTypes>.optFloat, FloatWrapper(persistedValue: Float(6.55444333)))
        validateNumericComparisons("optDouble", \Query<AllCustomPersistableTypes>.optDouble, DoubleWrapper(persistedValue: 234.567))
        validateNumericComparisons("optDate", \Query<AllCustomPersistableTypes>.optDate, DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)))
        validateNumericComparisons("optDecimal", \Query<AllCustomPersistableTypes>.optDecimal, Decimal128Wrapper(persistedValue: Decimal128(234.567)))

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
        validateNumericComparisons("optInt", \Query<AllCustomPersistableTypes>.optInt, nil, count: 0)
        validateNumericComparisons("optInt8", \Query<AllCustomPersistableTypes>.optInt8, nil, count: 0)
        validateNumericComparisons("optInt16", \Query<AllCustomPersistableTypes>.optInt16, nil, count: 0)
        validateNumericComparisons("optInt32", \Query<AllCustomPersistableTypes>.optInt32, nil, count: 0)
        validateNumericComparisons("optInt64", \Query<AllCustomPersistableTypes>.optInt64, nil, count: 0)
        validateNumericComparisons("optFloat", \Query<AllCustomPersistableTypes>.optFloat, nil, count: 0)
        validateNumericComparisons("optDouble", \Query<AllCustomPersistableTypes>.optDouble, nil, count: 0)
        validateNumericComparisons("optDate", \Query<AllCustomPersistableTypes>.optDate, nil, count: 0)
        validateNumericComparisons("optDecimal", \Query<AllCustomPersistableTypes>.optDecimal, nil, count: 0)
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

    private func validateNumericContains<Root: Object, T: _RealmSchemaDiscoverable & QueryValue & Comparable>(
            _ name: String, _ lhs: (Query<Root>) -> Query<T>) {
        let values = T.queryValues()
        assertQuery(Root.self, "((\(name) >= %@) && (\(name) < %@))", values: [values[0], values[2]], count: 1) {
            lhs($0).contains(values[0]..<values[2])
        }
        assertQuery(Root.self, "((\(name) >= %@) && (\(name) < %@))", values: [values[0], values[1]], count: 0) {
            lhs($0).contains(values[0]..<values[1])
        }
        assertQuery(Root.self, "(\(name) BETWEEN {%@, %@})", values: [values[0], values[2]], count: 1) {
            lhs($0).contains(values[0]...values[2])
        }
        assertQuery(Root.self, "(\(name) BETWEEN {%@, %@})", values: [values[0], values[1]], count: 1) {
            lhs($0).contains(values[0]...values[1])
        }
    }
    private func validateNumericContains<Root: Object, T: _RealmSchemaDiscoverable & OptionalProtocol>(
            _ name: String, _ lhs: (Query<Root>) -> Query<T>) where T.Wrapped: Comparable & QueryValue {
        let values = T.Wrapped.queryValues()
        assertQuery(Root.self, "((\(name) >= %@) && (\(name) < %@))", values: [values[0], values[2]], count: 1) {
            lhs($0).contains(values[0]..<values[2])
        }
        assertQuery(Root.self, "((\(name) >= %@) && (\(name) < %@))", values: [values[0], values[1]], count: 0) {
            lhs($0).contains(values[0]..<values[1])
        }
        assertQuery(Root.self, "(\(name) BETWEEN {%@, %@})", values: [values[0], values[2]], count: 1) {
            lhs($0).contains(values[0]...values[2])
        }
        assertQuery(Root.self, "(\(name) BETWEEN {%@, %@})", values: [values[0], values[1]], count: 1) {
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
        validateNumericContains("intEnumCol", \Query<ModernAllTypesObject>.intEnumCol.rawValue)
        validateNumericContains("int", \Query<AllCustomPersistableTypes>.int.persistableValue)
        validateNumericContains("int8", \Query<AllCustomPersistableTypes>.int8.persistableValue)
        validateNumericContains("int16", \Query<AllCustomPersistableTypes>.int16.persistableValue)
        validateNumericContains("int32", \Query<AllCustomPersistableTypes>.int32.persistableValue)
        validateNumericContains("int64", \Query<AllCustomPersistableTypes>.int64.persistableValue)
        validateNumericContains("float", \Query<AllCustomPersistableTypes>.float.persistableValue)
        validateNumericContains("double", \Query<AllCustomPersistableTypes>.double.persistableValue)
        validateNumericContains("date", \Query<AllCustomPersistableTypes>.date.persistableValue)
        validateNumericContains("decimal", \Query<AllCustomPersistableTypes>.decimal.persistableValue)
        validateNumericContains("optIntCol", \Query<ModernAllTypesObject>.optIntCol)
        validateNumericContains("optInt8Col", \Query<ModernAllTypesObject>.optInt8Col)
        validateNumericContains("optInt16Col", \Query<ModernAllTypesObject>.optInt16Col)
        validateNumericContains("optInt32Col", \Query<ModernAllTypesObject>.optInt32Col)
        validateNumericContains("optInt64Col", \Query<ModernAllTypesObject>.optInt64Col)
        validateNumericContains("optFloatCol", \Query<ModernAllTypesObject>.optFloatCol)
        validateNumericContains("optDoubleCol", \Query<ModernAllTypesObject>.optDoubleCol)
        validateNumericContains("optDateCol", \Query<ModernAllTypesObject>.optDateCol)
        validateNumericContains("optDecimalCol", \Query<ModernAllTypesObject>.optDecimalCol)
        validateNumericContains("optIntEnumCol", \Query<ModernAllTypesObject>.optIntEnumCol.rawValue)
        validateNumericContains("optInt", \Query<AllCustomPersistableTypes>.optInt.persistableValue)
        validateNumericContains("optInt8", \Query<AllCustomPersistableTypes>.optInt8.persistableValue)
        validateNumericContains("optInt16", \Query<AllCustomPersistableTypes>.optInt16.persistableValue)
        validateNumericContains("optInt32", \Query<AllCustomPersistableTypes>.optInt32.persistableValue)
        validateNumericContains("optInt64", \Query<AllCustomPersistableTypes>.optInt64.persistableValue)
        validateNumericContains("optFloat", \Query<AllCustomPersistableTypes>.optFloat.persistableValue)
        validateNumericContains("optDouble", \Query<AllCustomPersistableTypes>.optDouble.persistableValue)
        validateNumericContains("optDate", \Query<AllCustomPersistableTypes>.optDate.persistableValue)
        validateNumericContains("optDecimal", \Query<AllCustomPersistableTypes>.optDecimal.persistableValue)
    }

    // MARK: - Strings

    let stringModifiers: [(String, StringOptions)] = [
        ("", []),
        ("[c]", [.caseInsensitive]),
        ("[d]", [.diacriticInsensitive]),
        ("[cd]", [.caseInsensitive, .diacriticInsensitive]),
    ]

    private func validateStringOperations<Root: Object, T: _Persistable>(
            _ name: String, _ lhs: (Query<Root>) -> Query<T>,
            _ values: (T, T, T), count: (Bool, StringOptions) -> Int)
            where T.PersistedType: _QueryString {
        let (full, prefix, suffix) = values
        for (modifier, options) in stringModifiers {
            let matchingCount = count(true, options)
            let notMatchingCount = count(false, options)
            assertQuery(Root.self, "(\(name) ==\(modifier) %@)", full, count: matchingCount) {
                lhs($0).equals(full, options: [options])
            }
            assertQuery(Root.self, "(NOT \(name) ==\(modifier) %@)", full, count: 1 - matchingCount) {
                !lhs($0).equals(full, options: [options])
            }
            assertQuery(Root.self, "(\(name) !=\(modifier) %@)", full, count: notMatchingCount) {
                lhs($0).notEquals(full, options: [options])
            }
            assertQuery(Root.self, "(NOT \(name) !=\(modifier) %@)", full, count: 1 - notMatchingCount) {
                !lhs($0).notEquals(full, options: [options])
            }

            assertQuery(Root.self, "(\(name) CONTAINS\(modifier) %@)", full, count: matchingCount) {
                lhs($0).contains(full, options: [options])
            }
            assertQuery(Root.self, "(NOT \(name) CONTAINS\(modifier) %@)", full, count: 1 - matchingCount) {
                !lhs($0).contains(full, options: [options])
            }

            assertQuery(Root.self, "(\(name) BEGINSWITH\(modifier) %@)", prefix, count: matchingCount) {
                lhs($0).starts(with: prefix, options: [options])
            }
            assertQuery(Root.self, "(NOT \(name) BEGINSWITH\(modifier) %@)", prefix, count: 1 - matchingCount) {
                !lhs($0).starts(with: prefix, options: [options])
            }

            assertQuery(Root.self, "(\(name) ENDSWITH\(modifier) %@)", suffix, count: matchingCount) {
                lhs($0).ends(with: suffix, options: [options])
            }
            assertQuery(Root.self, "(NOT \(name) ENDSWITH\(modifier) %@)", suffix, count: 1 - matchingCount) {
                !lhs($0).ends(with: suffix, options: [options])
            }
        }
    }

    func testStringOperations() {
        validateStringOperations("stringCol", \Query<ModernAllTypesObject>.stringCol,
                                 ("Foó", "Fo", "oó"),
                                 count: { (equals, _) in equals ? 1 : 0 })
        validateStringOperations("stringEnumCol", \Query<ModernAllTypesObject>.stringEnumCol.rawValue,
                                 ("Foó", "Fo", "oó"),
                                 count: { (equals, _) in equals ? 0 : 1 })
        validateStringOperations("string", \Query<AllCustomPersistableTypes>.string,
                                 (StringWrapper(persistedValue: "Foó"), StringWrapper(persistedValue: "Fo"), StringWrapper(persistedValue: "oó")),
                                 count: { (equals, _) in equals ? 1 : 0 })
        validateStringOperations("optStringCol", \Query<ModernAllTypesObject>.optStringCol,
                                 (String?.some("Foó"), String?.some("Fo"), String?.some("oó")),
                                 count: { (equals, _) in equals ? 1 : 0 })
        validateStringOperations("optStringEnumCol", \Query<ModernAllTypesObject>.optStringEnumCol.rawValue,
                                 (String?.some("Foó"), String?.some("Fo"), String?.some("oó")),
                                 count: { (equals, _) in equals ? 0 : 1 })
        validateStringOperations("optString", \Query<AllCustomPersistableTypes>.optString,
                                 (StringWrapper(persistedValue: "Foó"), StringWrapper(persistedValue: "Fo"), StringWrapper(persistedValue: "oó")),
                                 count: { (equals, _) in equals ? 1 : 0 })
    }

    private func validateStringLike<Root: Object, T: _Persistable>(
            _ name: String, _ lhs: (Query<Root>) -> Query<T>, _ strings: [(T, Int, Int)], canMatch: Bool) where T.PersistedType: _QueryString {
        for (str, sensitiveCount, insensitiveCount) in strings {
            assertQuery(Root.self, "(\(name) LIKE %@)", str, count: canMatch ? sensitiveCount : 0) {
                lhs($0).like(str)
            }
            assertQuery(Root.self, "(\(name) LIKE[c] %@)", str, count: canMatch ? insensitiveCount : 0) {
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
        validateStringLike("stringCol", \Query<ModernAllTypesObject>.stringCol,
                           likeStrings.map { ($0.0, $0.1, $0.2) }, canMatch: true)
        validateStringLike("stringEnumCol", \Query<ModernAllTypesObject>.stringEnumCol.rawValue,
                           likeStrings.map { ($0.0, $0.1, $0.2) }, canMatch: false)
        validateStringLike("string", \Query<AllCustomPersistableTypes>.string,
                           likeStrings.map { (StringWrapper(persistedValue: $0.0), $0.1, $0.2) }, canMatch: true)
        validateStringLike("optStringCol", \Query<ModernAllTypesObject>.optStringCol,
                           likeStrings.map { (String?.some($0.0), $0.1, $0.2) }, canMatch: true)
        validateStringLike("optStringEnumCol", \Query<ModernAllTypesObject>.optStringEnumCol.rawValue,
                           likeStrings.map { (String?.some($0.0), $0.1, $0.2) }, canMatch: false)
        validateStringLike("optString", \Query<AllCustomPersistableTypes>.optString,
                           likeStrings.map { (StringWrapper(persistedValue: $0.0), $0.1, $0.2) }, canMatch: true)
    }

    // MARK: - Data

    func validateData<Root: Object, T: _Persistable>(_ name: String, _ lhs: (Query<Root>) -> Query<T>,
                                                     zeroData: T, oneData: T) where T.PersistedType: _QueryBinary {
        assertQuery(Root.self, "(\(name) BEGINSWITH %@)", zeroData, count: 1) {
            lhs($0).starts(with: zeroData)
        }

        assertQuery(Root.self, "(NOT \(name) BEGINSWITH %@)", zeroData, count: 0) {
            !lhs($0).starts(with: zeroData)
        }

        assertQuery(Root.self, "(\(name) ENDSWITH %@)", zeroData, count: 1) {
            lhs($0).ends(with: zeroData)
        }

        assertQuery(Root.self, "(NOT \(name) ENDSWITH %@)", zeroData, count: 0) {
            !lhs($0).ends(with: zeroData)
        }

        assertQuery(Root.self, "(\(name) CONTAINS %@)", zeroData, count: 1) {
            lhs($0).contains(zeroData)
        }

        assertQuery(Root.self, "(NOT \(name) CONTAINS %@)", zeroData, count: 0) {
            !lhs($0).contains(zeroData)
        }

        assertQuery(Root.self, "(\(name) == %@)", zeroData, count: 0) {
            lhs($0).equals(zeroData)
        }

        assertQuery(Root.self, "(NOT \(name) == %@)", zeroData, count: 1) {
            !lhs($0).equals(zeroData)
        }

        assertQuery(Root.self, "(\(name) != %@)", zeroData, count: 1) {
            lhs($0).notEquals(zeroData)
        }

        assertQuery(Root.self, "(NOT \(name) != %@)", zeroData, count: 0) {
            !lhs($0).notEquals(zeroData)
        }

        assertQuery(Root.self, "(\(name) BEGINSWITH %@)", oneData, count: 0) {
            lhs($0).starts(with: oneData)
        }

        assertQuery(Root.self, "(\(name) ENDSWITH %@)", oneData, count: 0) {
            lhs($0).ends(with: oneData)
        }

        assertQuery(Root.self, "(\(name) CONTAINS %@)", oneData, count: 0) {
            lhs($0).contains(oneData)
        }

        assertQuery(Root.self, "(NOT \(name) CONTAINS %@)", oneData, count: 1) {
            !lhs($0).contains(oneData)
        }

        assertQuery(Root.self, "(\(name) CONTAINS %@)", oneData, count: 0) {
            lhs($0).contains(oneData)
        }

        assertQuery(Root.self, "(NOT \(name) CONTAINS %@)", oneData, count: 1) {
            !lhs($0).contains(oneData)
        }

        assertQuery(Root.self, "(\(name) == %@)", oneData, count: 0) {
            lhs($0).equals(oneData)
        }

        assertQuery(Root.self, "(NOT \(name) == %@)", oneData, count: 1) {
            !lhs($0).equals(oneData)
        }

        assertQuery(Root.self, "(\(name) != %@)", oneData, count: 1) {
            lhs($0).notEquals(oneData)
        }

        assertQuery(Root.self, "(NOT \(name) != %@)", oneData, count: 0) {
            !lhs($0).notEquals(oneData)
        }
    }

    func testBinarySearchQueries() {
        validateData("binaryCol", \Query<ModernAllTypesObject>.binaryCol,
                     zeroData: Data(count: 28), oneData: Data(repeating: 1, count: 28))
        validateData("binary", \Query<AllCustomPersistableTypes>.binary,
                     zeroData: DataWrapper(persistedValue: Data(count: 28)), oneData: DataWrapper(persistedValue: Data(repeating: 1, count: 28)))
        validateData("optBinaryCol", \Query<ModernAllTypesObject>.optBinaryCol,
                     zeroData: Data?.some(Data(count: 28)), oneData: Data?.some(Data(repeating: 1, count: 28)))
        validateData("optBinary", \Query<AllCustomPersistableTypes>.optBinary,
                     zeroData: DataWrapper(persistedValue: Data(count: 28)), oneData: DataWrapper(persistedValue: Data(repeating: 1, count: 28)))
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
        validateCollectionContains("listBool", \Query<CustomPersistableCollections>.listBool)
        validateCollectionContains("listInt", \Query<CustomPersistableCollections>.listInt)
        validateCollectionContains("listInt8", \Query<CustomPersistableCollections>.listInt8)
        validateCollectionContains("listInt16", \Query<CustomPersistableCollections>.listInt16)
        validateCollectionContains("listInt32", \Query<CustomPersistableCollections>.listInt32)
        validateCollectionContains("listInt64", \Query<CustomPersistableCollections>.listInt64)
        validateCollectionContains("listFloat", \Query<CustomPersistableCollections>.listFloat)
        validateCollectionContains("listDouble", \Query<CustomPersistableCollections>.listDouble)
        validateCollectionContains("listString", \Query<CustomPersistableCollections>.listString)
        validateCollectionContains("listBinary", \Query<CustomPersistableCollections>.listBinary)
        validateCollectionContains("listDate", \Query<CustomPersistableCollections>.listDate)
        validateCollectionContains("listDecimal", \Query<CustomPersistableCollections>.listDecimal)
        validateCollectionContains("listObjectId", \Query<CustomPersistableCollections>.listObjectId)
        validateCollectionContains("listUuid", \Query<CustomPersistableCollections>.listUuid)
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
        validateCollectionContains("listOptBool", \Query<CustomPersistableCollections>.listOptBool)
        validateCollectionContains("listOptInt", \Query<CustomPersistableCollections>.listOptInt)
        validateCollectionContains("listOptInt8", \Query<CustomPersistableCollections>.listOptInt8)
        validateCollectionContains("listOptInt16", \Query<CustomPersistableCollections>.listOptInt16)
        validateCollectionContains("listOptInt32", \Query<CustomPersistableCollections>.listOptInt32)
        validateCollectionContains("listOptInt64", \Query<CustomPersistableCollections>.listOptInt64)
        validateCollectionContains("listOptFloat", \Query<CustomPersistableCollections>.listOptFloat)
        validateCollectionContains("listOptDouble", \Query<CustomPersistableCollections>.listOptDouble)
        validateCollectionContains("listOptString", \Query<CustomPersistableCollections>.listOptString)
        validateCollectionContains("listOptBinary", \Query<CustomPersistableCollections>.listOptBinary)
        validateCollectionContains("listOptDate", \Query<CustomPersistableCollections>.listOptDate)
        validateCollectionContains("listOptDecimal", \Query<CustomPersistableCollections>.listOptDecimal)
        validateCollectionContains("listOptObjectId", \Query<CustomPersistableCollections>.listOptObjectId)
        validateCollectionContains("listOptUuid", \Query<CustomPersistableCollections>.listOptUuid)
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
        validateCollectionContains("setBool", \Query<CustomPersistableCollections>.setBool)
        validateCollectionContains("setInt", \Query<CustomPersistableCollections>.setInt)
        validateCollectionContains("setInt8", \Query<CustomPersistableCollections>.setInt8)
        validateCollectionContains("setInt16", \Query<CustomPersistableCollections>.setInt16)
        validateCollectionContains("setInt32", \Query<CustomPersistableCollections>.setInt32)
        validateCollectionContains("setInt64", \Query<CustomPersistableCollections>.setInt64)
        validateCollectionContains("setFloat", \Query<CustomPersistableCollections>.setFloat)
        validateCollectionContains("setDouble", \Query<CustomPersistableCollections>.setDouble)
        validateCollectionContains("setString", \Query<CustomPersistableCollections>.setString)
        validateCollectionContains("setBinary", \Query<CustomPersistableCollections>.setBinary)
        validateCollectionContains("setDate", \Query<CustomPersistableCollections>.setDate)
        validateCollectionContains("setDecimal", \Query<CustomPersistableCollections>.setDecimal)
        validateCollectionContains("setObjectId", \Query<CustomPersistableCollections>.setObjectId)
        validateCollectionContains("setUuid", \Query<CustomPersistableCollections>.setUuid)
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
        validateCollectionContains("setOptBool", \Query<CustomPersistableCollections>.setOptBool)
        validateCollectionContains("setOptInt", \Query<CustomPersistableCollections>.setOptInt)
        validateCollectionContains("setOptInt8", \Query<CustomPersistableCollections>.setOptInt8)
        validateCollectionContains("setOptInt16", \Query<CustomPersistableCollections>.setOptInt16)
        validateCollectionContains("setOptInt32", \Query<CustomPersistableCollections>.setOptInt32)
        validateCollectionContains("setOptInt64", \Query<CustomPersistableCollections>.setOptInt64)
        validateCollectionContains("setOptFloat", \Query<CustomPersistableCollections>.setOptFloat)
        validateCollectionContains("setOptDouble", \Query<CustomPersistableCollections>.setOptDouble)
        validateCollectionContains("setOptString", \Query<CustomPersistableCollections>.setOptString)
        validateCollectionContains("setOptBinary", \Query<CustomPersistableCollections>.setOptBinary)
        validateCollectionContains("setOptDate", \Query<CustomPersistableCollections>.setOptDate)
        validateCollectionContains("setOptDecimal", \Query<CustomPersistableCollections>.setOptDecimal)
        validateCollectionContains("setOptObjectId", \Query<CustomPersistableCollections>.setOptObjectId)
        validateCollectionContains("setOptUuid", \Query<CustomPersistableCollections>.setOptUuid)
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
        validateCollectionContains("mapBool", \Query<CustomPersistableCollections>.mapBool)
        validateCollectionContains("mapInt", \Query<CustomPersistableCollections>.mapInt)
        validateCollectionContains("mapInt8", \Query<CustomPersistableCollections>.mapInt8)
        validateCollectionContains("mapInt16", \Query<CustomPersistableCollections>.mapInt16)
        validateCollectionContains("mapInt32", \Query<CustomPersistableCollections>.mapInt32)
        validateCollectionContains("mapInt64", \Query<CustomPersistableCollections>.mapInt64)
        validateCollectionContains("mapFloat", \Query<CustomPersistableCollections>.mapFloat)
        validateCollectionContains("mapDouble", \Query<CustomPersistableCollections>.mapDouble)
        validateCollectionContains("mapString", \Query<CustomPersistableCollections>.mapString)
        validateCollectionContains("mapBinary", \Query<CustomPersistableCollections>.mapBinary)
        validateCollectionContains("mapDate", \Query<CustomPersistableCollections>.mapDate)
        validateCollectionContains("mapDecimal", \Query<CustomPersistableCollections>.mapDecimal)
        validateCollectionContains("mapObjectId", \Query<CustomPersistableCollections>.mapObjectId)
        validateCollectionContains("mapUuid", \Query<CustomPersistableCollections>.mapUuid)
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
        validateCollectionContains("mapOptBool", \Query<CustomPersistableCollections>.mapOptBool)
        validateCollectionContains("mapOptInt", \Query<CustomPersistableCollections>.mapOptInt)
        validateCollectionContains("mapOptInt8", \Query<CustomPersistableCollections>.mapOptInt8)
        validateCollectionContains("mapOptInt16", \Query<CustomPersistableCollections>.mapOptInt16)
        validateCollectionContains("mapOptInt32", \Query<CustomPersistableCollections>.mapOptInt32)
        validateCollectionContains("mapOptInt64", \Query<CustomPersistableCollections>.mapOptInt64)
        validateCollectionContains("mapOptFloat", \Query<CustomPersistableCollections>.mapOptFloat)
        validateCollectionContains("mapOptDouble", \Query<CustomPersistableCollections>.mapOptDouble)
        validateCollectionContains("mapOptString", \Query<CustomPersistableCollections>.mapOptString)
        validateCollectionContains("mapOptBinary", \Query<CustomPersistableCollections>.mapOptBinary)
        validateCollectionContains("mapOptDate", \Query<CustomPersistableCollections>.mapOptDate)
        validateCollectionContains("mapOptDecimal", \Query<CustomPersistableCollections>.mapOptDecimal)
        validateCollectionContains("mapOptObjectId", \Query<CustomPersistableCollections>.mapOptObjectId)
        validateCollectionContains("mapOptUuid", \Query<CustomPersistableCollections>.mapOptUuid)

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
        validateCollectionContainsNil("listOptBool", \Query<CustomPersistableCollections>.listOptBool)
        validateCollectionContainsNil("listOptInt", \Query<CustomPersistableCollections>.listOptInt)
        validateCollectionContainsNil("listOptInt8", \Query<CustomPersistableCollections>.listOptInt8)
        validateCollectionContainsNil("listOptInt16", \Query<CustomPersistableCollections>.listOptInt16)
        validateCollectionContainsNil("listOptInt32", \Query<CustomPersistableCollections>.listOptInt32)
        validateCollectionContainsNil("listOptInt64", \Query<CustomPersistableCollections>.listOptInt64)
        validateCollectionContainsNil("listOptFloat", \Query<CustomPersistableCollections>.listOptFloat)
        validateCollectionContainsNil("listOptDouble", \Query<CustomPersistableCollections>.listOptDouble)
        validateCollectionContainsNil("listOptString", \Query<CustomPersistableCollections>.listOptString)
        validateCollectionContainsNil("listOptBinary", \Query<CustomPersistableCollections>.listOptBinary)
        validateCollectionContainsNil("listOptDate", \Query<CustomPersistableCollections>.listOptDate)
        validateCollectionContainsNil("listOptDecimal", \Query<CustomPersistableCollections>.listOptDecimal)
        validateCollectionContainsNil("listOptObjectId", \Query<CustomPersistableCollections>.listOptObjectId)
        validateCollectionContainsNil("listOptUuid", \Query<CustomPersistableCollections>.listOptUuid)
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
        validateCollectionContainsNil("setOptBool", \Query<CustomPersistableCollections>.setOptBool)
        validateCollectionContainsNil("setOptInt", \Query<CustomPersistableCollections>.setOptInt)
        validateCollectionContainsNil("setOptInt8", \Query<CustomPersistableCollections>.setOptInt8)
        validateCollectionContainsNil("setOptInt16", \Query<CustomPersistableCollections>.setOptInt16)
        validateCollectionContainsNil("setOptInt32", \Query<CustomPersistableCollections>.setOptInt32)
        validateCollectionContainsNil("setOptInt64", \Query<CustomPersistableCollections>.setOptInt64)
        validateCollectionContainsNil("setOptFloat", \Query<CustomPersistableCollections>.setOptFloat)
        validateCollectionContainsNil("setOptDouble", \Query<CustomPersistableCollections>.setOptDouble)
        validateCollectionContainsNil("setOptString", \Query<CustomPersistableCollections>.setOptString)
        validateCollectionContainsNil("setOptBinary", \Query<CustomPersistableCollections>.setOptBinary)
        validateCollectionContainsNil("setOptDate", \Query<CustomPersistableCollections>.setOptDate)
        validateCollectionContainsNil("setOptDecimal", \Query<CustomPersistableCollections>.setOptDecimal)
        validateCollectionContainsNil("setOptObjectId", \Query<CustomPersistableCollections>.setOptObjectId)
        validateCollectionContainsNil("setOptUuid", \Query<CustomPersistableCollections>.setOptUuid)
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
        validateCollectionContainsNil("mapOptBool", \Query<CustomPersistableCollections>.mapOptBool)
        validateCollectionContainsNil("mapOptInt", \Query<CustomPersistableCollections>.mapOptInt)
        validateCollectionContainsNil("mapOptInt8", \Query<CustomPersistableCollections>.mapOptInt8)
        validateCollectionContainsNil("mapOptInt16", \Query<CustomPersistableCollections>.mapOptInt16)
        validateCollectionContainsNil("mapOptInt32", \Query<CustomPersistableCollections>.mapOptInt32)
        validateCollectionContainsNil("mapOptInt64", \Query<CustomPersistableCollections>.mapOptInt64)
        validateCollectionContainsNil("mapOptFloat", \Query<CustomPersistableCollections>.mapOptFloat)
        validateCollectionContainsNil("mapOptDouble", \Query<CustomPersistableCollections>.mapOptDouble)
        validateCollectionContainsNil("mapOptString", \Query<CustomPersistableCollections>.mapOptString)
        validateCollectionContainsNil("mapOptBinary", \Query<CustomPersistableCollections>.mapOptBinary)
        validateCollectionContainsNil("mapOptDate", \Query<CustomPersistableCollections>.mapOptDate)
        validateCollectionContainsNil("mapOptDecimal", \Query<CustomPersistableCollections>.mapOptDecimal)
        validateCollectionContainsNil("mapOptObjectId", \Query<CustomPersistableCollections>.mapOptObjectId)
        validateCollectionContainsNil("mapOptUuid", \Query<CustomPersistableCollections>.mapOptUuid)
    }

    func testListContainsObject() {
        let obj = objects().first!
        let colObj = collectionObject()
        let result = realm.objects(ModernCollectionObject.self).where {
            $0.list.contains(obj)
        }
        XCTAssertEqual(result.count, 0)
        try! realm.write {
            colObj.list.append(obj)
        }
        XCTAssertEqual(result.count, 1)
    }

    func testCollectionContainsRange() {
        assertQuery(ModernAllTypesObject.self, "((arrayInt.@min >= %@) && (arrayInt.@max <= %@))",
                    values: [1, 3], count: 1) {
            $0.arrayInt.contains(1...3)
        }
        assertQuery(ModernAllTypesObject.self, "((arrayInt.@min >= %@) && (arrayInt.@max < %@))",
                    values: [1, 3], count: 0) {
            $0.arrayInt.contains(1..<3)
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
        assertQuery(CustomPersistableCollections.self, "((listInt.@min >= %@) && (listInt.@max <= %@))",
                    values: [IntWrapper(persistedValue: 1).persistableValue, IntWrapper(persistedValue: 3).persistableValue], count: 1) {
            $0.listInt.persistableValue.contains(IntWrapper(persistedValue: 1).persistableValue...IntWrapper(persistedValue: 3).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((listInt.@min >= %@) && (listInt.@max < %@))",
                    values: [IntWrapper(persistedValue: 1).persistableValue, IntWrapper(persistedValue: 3).persistableValue], count: 0) {
            $0.listInt.persistableValue.contains(IntWrapper(persistedValue: 1).persistableValue..<IntWrapper(persistedValue: 3).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((listInt8.@min >= %@) && (listInt8.@max <= %@))",
                    values: [Int8Wrapper(persistedValue: Int8(8)).persistableValue, Int8Wrapper(persistedValue: Int8(9)).persistableValue], count: 1) {
            $0.listInt8.persistableValue.contains(Int8Wrapper(persistedValue: Int8(8)).persistableValue...Int8Wrapper(persistedValue: Int8(9)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((listInt8.@min >= %@) && (listInt8.@max < %@))",
                    values: [Int8Wrapper(persistedValue: Int8(8)).persistableValue, Int8Wrapper(persistedValue: Int8(9)).persistableValue], count: 0) {
            $0.listInt8.persistableValue.contains(Int8Wrapper(persistedValue: Int8(8)).persistableValue..<Int8Wrapper(persistedValue: Int8(9)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((listInt16.@min >= %@) && (listInt16.@max <= %@))",
                    values: [Int16Wrapper(persistedValue: Int16(16)).persistableValue, Int16Wrapper(persistedValue: Int16(17)).persistableValue], count: 1) {
            $0.listInt16.persistableValue.contains(Int16Wrapper(persistedValue: Int16(16)).persistableValue...Int16Wrapper(persistedValue: Int16(17)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((listInt16.@min >= %@) && (listInt16.@max < %@))",
                    values: [Int16Wrapper(persistedValue: Int16(16)).persistableValue, Int16Wrapper(persistedValue: Int16(17)).persistableValue], count: 0) {
            $0.listInt16.persistableValue.contains(Int16Wrapper(persistedValue: Int16(16)).persistableValue..<Int16Wrapper(persistedValue: Int16(17)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((listInt32.@min >= %@) && (listInt32.@max <= %@))",
                    values: [Int32Wrapper(persistedValue: Int32(32)).persistableValue, Int32Wrapper(persistedValue: Int32(33)).persistableValue], count: 1) {
            $0.listInt32.persistableValue.contains(Int32Wrapper(persistedValue: Int32(32)).persistableValue...Int32Wrapper(persistedValue: Int32(33)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((listInt32.@min >= %@) && (listInt32.@max < %@))",
                    values: [Int32Wrapper(persistedValue: Int32(32)).persistableValue, Int32Wrapper(persistedValue: Int32(33)).persistableValue], count: 0) {
            $0.listInt32.persistableValue.contains(Int32Wrapper(persistedValue: Int32(32)).persistableValue..<Int32Wrapper(persistedValue: Int32(33)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((listInt64.@min >= %@) && (listInt64.@max <= %@))",
                    values: [Int64Wrapper(persistedValue: Int64(64)).persistableValue, Int64Wrapper(persistedValue: Int64(65)).persistableValue], count: 1) {
            $0.listInt64.persistableValue.contains(Int64Wrapper(persistedValue: Int64(64)).persistableValue...Int64Wrapper(persistedValue: Int64(65)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((listInt64.@min >= %@) && (listInt64.@max < %@))",
                    values: [Int64Wrapper(persistedValue: Int64(64)).persistableValue, Int64Wrapper(persistedValue: Int64(65)).persistableValue], count: 0) {
            $0.listInt64.persistableValue.contains(Int64Wrapper(persistedValue: Int64(64)).persistableValue..<Int64Wrapper(persistedValue: Int64(65)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((listFloat.@min >= %@) && (listFloat.@max <= %@))",
                    values: [FloatWrapper(persistedValue: Float(5.55444333)).persistableValue, FloatWrapper(persistedValue: Float(6.55444333)).persistableValue], count: 1) {
            $0.listFloat.persistableValue.contains(FloatWrapper(persistedValue: Float(5.55444333)).persistableValue...FloatWrapper(persistedValue: Float(6.55444333)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((listFloat.@min >= %@) && (listFloat.@max < %@))",
                    values: [FloatWrapper(persistedValue: Float(5.55444333)).persistableValue, FloatWrapper(persistedValue: Float(6.55444333)).persistableValue], count: 0) {
            $0.listFloat.persistableValue.contains(FloatWrapper(persistedValue: Float(5.55444333)).persistableValue..<FloatWrapper(persistedValue: Float(6.55444333)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((listDouble.@min >= %@) && (listDouble.@max <= %@))",
                    values: [DoubleWrapper(persistedValue: 123.456).persistableValue, DoubleWrapper(persistedValue: 234.567).persistableValue], count: 1) {
            $0.listDouble.persistableValue.contains(DoubleWrapper(persistedValue: 123.456).persistableValue...DoubleWrapper(persistedValue: 234.567).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((listDouble.@min >= %@) && (listDouble.@max < %@))",
                    values: [DoubleWrapper(persistedValue: 123.456).persistableValue, DoubleWrapper(persistedValue: 234.567).persistableValue], count: 0) {
            $0.listDouble.persistableValue.contains(DoubleWrapper(persistedValue: 123.456).persistableValue..<DoubleWrapper(persistedValue: 234.567).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((listDate.@min >= %@) && (listDate.@max <= %@))",
                    values: [DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)).persistableValue, DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)).persistableValue], count: 1) {
            $0.listDate.persistableValue.contains(DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)).persistableValue...DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((listDate.@min >= %@) && (listDate.@max < %@))",
                    values: [DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)).persistableValue, DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)).persistableValue], count: 0) {
            $0.listDate.persistableValue.contains(DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)).persistableValue..<DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((listDecimal.@min >= %@) && (listDecimal.@max <= %@))",
                    values: [Decimal128Wrapper(persistedValue: Decimal128(123.456)).persistableValue, Decimal128Wrapper(persistedValue: Decimal128(234.567)).persistableValue], count: 1) {
            $0.listDecimal.persistableValue.contains(Decimal128Wrapper(persistedValue: Decimal128(123.456)).persistableValue...Decimal128Wrapper(persistedValue: Decimal128(234.567)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((listDecimal.@min >= %@) && (listDecimal.@max < %@))",
                    values: [Decimal128Wrapper(persistedValue: Decimal128(123.456)).persistableValue, Decimal128Wrapper(persistedValue: Decimal128(234.567)).persistableValue], count: 0) {
            $0.listDecimal.persistableValue.contains(Decimal128Wrapper(persistedValue: Decimal128(123.456)).persistableValue..<Decimal128Wrapper(persistedValue: Decimal128(234.567)).persistableValue)
        }
        assertQuery(ModernAllTypesObject.self, "((arrayOptInt.@min >= %@) && (arrayOptInt.@max <= %@))",
                    values: [1, 3], count: 1) {
            $0.arrayOptInt.contains(1...3)
        }
        assertQuery(ModernAllTypesObject.self, "((arrayOptInt.@min >= %@) && (arrayOptInt.@max < %@))",
                    values: [1, 3], count: 0) {
            $0.arrayOptInt.contains(1..<3)
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
        assertQuery(CustomPersistableCollections.self, "((listOptInt.@min >= %@) && (listOptInt.@max <= %@))",
                    values: [IntWrapper(persistedValue: 1).persistableValue, IntWrapper(persistedValue: 3).persistableValue], count: 1) {
            $0.listOptInt.persistableValue.contains(IntWrapper(persistedValue: 1).persistableValue...IntWrapper(persistedValue: 3).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((listOptInt.@min >= %@) && (listOptInt.@max < %@))",
                    values: [IntWrapper(persistedValue: 1).persistableValue, IntWrapper(persistedValue: 3).persistableValue], count: 0) {
            $0.listOptInt.persistableValue.contains(IntWrapper(persistedValue: 1).persistableValue..<IntWrapper(persistedValue: 3).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((listOptInt8.@min >= %@) && (listOptInt8.@max <= %@))",
                    values: [Int8Wrapper(persistedValue: Int8(8)).persistableValue, Int8Wrapper(persistedValue: Int8(9)).persistableValue], count: 1) {
            $0.listOptInt8.persistableValue.contains(Int8Wrapper(persistedValue: Int8(8)).persistableValue...Int8Wrapper(persistedValue: Int8(9)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((listOptInt8.@min >= %@) && (listOptInt8.@max < %@))",
                    values: [Int8Wrapper(persistedValue: Int8(8)).persistableValue, Int8Wrapper(persistedValue: Int8(9)).persistableValue], count: 0) {
            $0.listOptInt8.persistableValue.contains(Int8Wrapper(persistedValue: Int8(8)).persistableValue..<Int8Wrapper(persistedValue: Int8(9)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((listOptInt16.@min >= %@) && (listOptInt16.@max <= %@))",
                    values: [Int16Wrapper(persistedValue: Int16(16)).persistableValue, Int16Wrapper(persistedValue: Int16(17)).persistableValue], count: 1) {
            $0.listOptInt16.persistableValue.contains(Int16Wrapper(persistedValue: Int16(16)).persistableValue...Int16Wrapper(persistedValue: Int16(17)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((listOptInt16.@min >= %@) && (listOptInt16.@max < %@))",
                    values: [Int16Wrapper(persistedValue: Int16(16)).persistableValue, Int16Wrapper(persistedValue: Int16(17)).persistableValue], count: 0) {
            $0.listOptInt16.persistableValue.contains(Int16Wrapper(persistedValue: Int16(16)).persistableValue..<Int16Wrapper(persistedValue: Int16(17)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((listOptInt32.@min >= %@) && (listOptInt32.@max <= %@))",
                    values: [Int32Wrapper(persistedValue: Int32(32)).persistableValue, Int32Wrapper(persistedValue: Int32(33)).persistableValue], count: 1) {
            $0.listOptInt32.persistableValue.contains(Int32Wrapper(persistedValue: Int32(32)).persistableValue...Int32Wrapper(persistedValue: Int32(33)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((listOptInt32.@min >= %@) && (listOptInt32.@max < %@))",
                    values: [Int32Wrapper(persistedValue: Int32(32)).persistableValue, Int32Wrapper(persistedValue: Int32(33)).persistableValue], count: 0) {
            $0.listOptInt32.persistableValue.contains(Int32Wrapper(persistedValue: Int32(32)).persistableValue..<Int32Wrapper(persistedValue: Int32(33)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((listOptInt64.@min >= %@) && (listOptInt64.@max <= %@))",
                    values: [Int64Wrapper(persistedValue: Int64(64)).persistableValue, Int64Wrapper(persistedValue: Int64(65)).persistableValue], count: 1) {
            $0.listOptInt64.persistableValue.contains(Int64Wrapper(persistedValue: Int64(64)).persistableValue...Int64Wrapper(persistedValue: Int64(65)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((listOptInt64.@min >= %@) && (listOptInt64.@max < %@))",
                    values: [Int64Wrapper(persistedValue: Int64(64)).persistableValue, Int64Wrapper(persistedValue: Int64(65)).persistableValue], count: 0) {
            $0.listOptInt64.persistableValue.contains(Int64Wrapper(persistedValue: Int64(64)).persistableValue..<Int64Wrapper(persistedValue: Int64(65)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((listOptFloat.@min >= %@) && (listOptFloat.@max <= %@))",
                    values: [FloatWrapper(persistedValue: Float(5.55444333)).persistableValue, FloatWrapper(persistedValue: Float(6.55444333)).persistableValue], count: 1) {
            $0.listOptFloat.persistableValue.contains(FloatWrapper(persistedValue: Float(5.55444333)).persistableValue...FloatWrapper(persistedValue: Float(6.55444333)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((listOptFloat.@min >= %@) && (listOptFloat.@max < %@))",
                    values: [FloatWrapper(persistedValue: Float(5.55444333)).persistableValue, FloatWrapper(persistedValue: Float(6.55444333)).persistableValue], count: 0) {
            $0.listOptFloat.persistableValue.contains(FloatWrapper(persistedValue: Float(5.55444333)).persistableValue..<FloatWrapper(persistedValue: Float(6.55444333)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((listOptDouble.@min >= %@) && (listOptDouble.@max <= %@))",
                    values: [DoubleWrapper(persistedValue: 123.456).persistableValue, DoubleWrapper(persistedValue: 234.567).persistableValue], count: 1) {
            $0.listOptDouble.persistableValue.contains(DoubleWrapper(persistedValue: 123.456).persistableValue...DoubleWrapper(persistedValue: 234.567).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((listOptDouble.@min >= %@) && (listOptDouble.@max < %@))",
                    values: [DoubleWrapper(persistedValue: 123.456).persistableValue, DoubleWrapper(persistedValue: 234.567).persistableValue], count: 0) {
            $0.listOptDouble.persistableValue.contains(DoubleWrapper(persistedValue: 123.456).persistableValue..<DoubleWrapper(persistedValue: 234.567).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((listOptDate.@min >= %@) && (listOptDate.@max <= %@))",
                    values: [DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)).persistableValue, DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)).persistableValue], count: 1) {
            $0.listOptDate.persistableValue.contains(DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)).persistableValue...DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((listOptDate.@min >= %@) && (listOptDate.@max < %@))",
                    values: [DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)).persistableValue, DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)).persistableValue], count: 0) {
            $0.listOptDate.persistableValue.contains(DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)).persistableValue..<DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((listOptDecimal.@min >= %@) && (listOptDecimal.@max <= %@))",
                    values: [Decimal128Wrapper(persistedValue: Decimal128(123.456)).persistableValue, Decimal128Wrapper(persistedValue: Decimal128(234.567)).persistableValue], count: 1) {
            $0.listOptDecimal.persistableValue.contains(Decimal128Wrapper(persistedValue: Decimal128(123.456)).persistableValue...Decimal128Wrapper(persistedValue: Decimal128(234.567)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((listOptDecimal.@min >= %@) && (listOptDecimal.@max < %@))",
                    values: [Decimal128Wrapper(persistedValue: Decimal128(123.456)).persistableValue, Decimal128Wrapper(persistedValue: Decimal128(234.567)).persistableValue], count: 0) {
            $0.listOptDecimal.persistableValue.contains(Decimal128Wrapper(persistedValue: Decimal128(123.456)).persistableValue..<Decimal128Wrapper(persistedValue: Decimal128(234.567)).persistableValue)
        }
        assertQuery(ModernAllTypesObject.self, "((setInt.@min >= %@) && (setInt.@max <= %@))",
                    values: [1, 3], count: 1) {
            $0.setInt.contains(1...3)
        }
        assertQuery(ModernAllTypesObject.self, "((setInt.@min >= %@) && (setInt.@max < %@))",
                    values: [1, 3], count: 0) {
            $0.setInt.contains(1..<3)
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
        assertQuery(CustomPersistableCollections.self, "((setInt.@min >= %@) && (setInt.@max <= %@))",
                    values: [IntWrapper(persistedValue: 1).persistableValue, IntWrapper(persistedValue: 3).persistableValue], count: 1) {
            $0.setInt.persistableValue.contains(IntWrapper(persistedValue: 1).persistableValue...IntWrapper(persistedValue: 3).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((setInt.@min >= %@) && (setInt.@max < %@))",
                    values: [IntWrapper(persistedValue: 1).persistableValue, IntWrapper(persistedValue: 3).persistableValue], count: 0) {
            $0.setInt.persistableValue.contains(IntWrapper(persistedValue: 1).persistableValue..<IntWrapper(persistedValue: 3).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((setInt8.@min >= %@) && (setInt8.@max <= %@))",
                    values: [Int8Wrapper(persistedValue: Int8(8)).persistableValue, Int8Wrapper(persistedValue: Int8(9)).persistableValue], count: 1) {
            $0.setInt8.persistableValue.contains(Int8Wrapper(persistedValue: Int8(8)).persistableValue...Int8Wrapper(persistedValue: Int8(9)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((setInt8.@min >= %@) && (setInt8.@max < %@))",
                    values: [Int8Wrapper(persistedValue: Int8(8)).persistableValue, Int8Wrapper(persistedValue: Int8(9)).persistableValue], count: 0) {
            $0.setInt8.persistableValue.contains(Int8Wrapper(persistedValue: Int8(8)).persistableValue..<Int8Wrapper(persistedValue: Int8(9)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((setInt16.@min >= %@) && (setInt16.@max <= %@))",
                    values: [Int16Wrapper(persistedValue: Int16(16)).persistableValue, Int16Wrapper(persistedValue: Int16(17)).persistableValue], count: 1) {
            $0.setInt16.persistableValue.contains(Int16Wrapper(persistedValue: Int16(16)).persistableValue...Int16Wrapper(persistedValue: Int16(17)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((setInt16.@min >= %@) && (setInt16.@max < %@))",
                    values: [Int16Wrapper(persistedValue: Int16(16)).persistableValue, Int16Wrapper(persistedValue: Int16(17)).persistableValue], count: 0) {
            $0.setInt16.persistableValue.contains(Int16Wrapper(persistedValue: Int16(16)).persistableValue..<Int16Wrapper(persistedValue: Int16(17)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((setInt32.@min >= %@) && (setInt32.@max <= %@))",
                    values: [Int32Wrapper(persistedValue: Int32(32)).persistableValue, Int32Wrapper(persistedValue: Int32(33)).persistableValue], count: 1) {
            $0.setInt32.persistableValue.contains(Int32Wrapper(persistedValue: Int32(32)).persistableValue...Int32Wrapper(persistedValue: Int32(33)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((setInt32.@min >= %@) && (setInt32.@max < %@))",
                    values: [Int32Wrapper(persistedValue: Int32(32)).persistableValue, Int32Wrapper(persistedValue: Int32(33)).persistableValue], count: 0) {
            $0.setInt32.persistableValue.contains(Int32Wrapper(persistedValue: Int32(32)).persistableValue..<Int32Wrapper(persistedValue: Int32(33)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((setInt64.@min >= %@) && (setInt64.@max <= %@))",
                    values: [Int64Wrapper(persistedValue: Int64(64)).persistableValue, Int64Wrapper(persistedValue: Int64(65)).persistableValue], count: 1) {
            $0.setInt64.persistableValue.contains(Int64Wrapper(persistedValue: Int64(64)).persistableValue...Int64Wrapper(persistedValue: Int64(65)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((setInt64.@min >= %@) && (setInt64.@max < %@))",
                    values: [Int64Wrapper(persistedValue: Int64(64)).persistableValue, Int64Wrapper(persistedValue: Int64(65)).persistableValue], count: 0) {
            $0.setInt64.persistableValue.contains(Int64Wrapper(persistedValue: Int64(64)).persistableValue..<Int64Wrapper(persistedValue: Int64(65)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((setFloat.@min >= %@) && (setFloat.@max <= %@))",
                    values: [FloatWrapper(persistedValue: Float(5.55444333)).persistableValue, FloatWrapper(persistedValue: Float(6.55444333)).persistableValue], count: 1) {
            $0.setFloat.persistableValue.contains(FloatWrapper(persistedValue: Float(5.55444333)).persistableValue...FloatWrapper(persistedValue: Float(6.55444333)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((setFloat.@min >= %@) && (setFloat.@max < %@))",
                    values: [FloatWrapper(persistedValue: Float(5.55444333)).persistableValue, FloatWrapper(persistedValue: Float(6.55444333)).persistableValue], count: 0) {
            $0.setFloat.persistableValue.contains(FloatWrapper(persistedValue: Float(5.55444333)).persistableValue..<FloatWrapper(persistedValue: Float(6.55444333)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((setDouble.@min >= %@) && (setDouble.@max <= %@))",
                    values: [DoubleWrapper(persistedValue: 123.456).persistableValue, DoubleWrapper(persistedValue: 234.567).persistableValue], count: 1) {
            $0.setDouble.persistableValue.contains(DoubleWrapper(persistedValue: 123.456).persistableValue...DoubleWrapper(persistedValue: 234.567).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((setDouble.@min >= %@) && (setDouble.@max < %@))",
                    values: [DoubleWrapper(persistedValue: 123.456).persistableValue, DoubleWrapper(persistedValue: 234.567).persistableValue], count: 0) {
            $0.setDouble.persistableValue.contains(DoubleWrapper(persistedValue: 123.456).persistableValue..<DoubleWrapper(persistedValue: 234.567).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((setDate.@min >= %@) && (setDate.@max <= %@))",
                    values: [DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)).persistableValue, DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)).persistableValue], count: 1) {
            $0.setDate.persistableValue.contains(DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)).persistableValue...DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((setDate.@min >= %@) && (setDate.@max < %@))",
                    values: [DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)).persistableValue, DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)).persistableValue], count: 0) {
            $0.setDate.persistableValue.contains(DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)).persistableValue..<DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((setDecimal.@min >= %@) && (setDecimal.@max <= %@))",
                    values: [Decimal128Wrapper(persistedValue: Decimal128(123.456)).persistableValue, Decimal128Wrapper(persistedValue: Decimal128(234.567)).persistableValue], count: 1) {
            $0.setDecimal.persistableValue.contains(Decimal128Wrapper(persistedValue: Decimal128(123.456)).persistableValue...Decimal128Wrapper(persistedValue: Decimal128(234.567)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((setDecimal.@min >= %@) && (setDecimal.@max < %@))",
                    values: [Decimal128Wrapper(persistedValue: Decimal128(123.456)).persistableValue, Decimal128Wrapper(persistedValue: Decimal128(234.567)).persistableValue], count: 0) {
            $0.setDecimal.persistableValue.contains(Decimal128Wrapper(persistedValue: Decimal128(123.456)).persistableValue..<Decimal128Wrapper(persistedValue: Decimal128(234.567)).persistableValue)
        }
        assertQuery(ModernAllTypesObject.self, "((setOptInt.@min >= %@) && (setOptInt.@max <= %@))",
                    values: [1, 3], count: 1) {
            $0.setOptInt.contains(1...3)
        }
        assertQuery(ModernAllTypesObject.self, "((setOptInt.@min >= %@) && (setOptInt.@max < %@))",
                    values: [1, 3], count: 0) {
            $0.setOptInt.contains(1..<3)
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
        assertQuery(CustomPersistableCollections.self, "((setOptInt.@min >= %@) && (setOptInt.@max <= %@))",
                    values: [IntWrapper(persistedValue: 1).persistableValue, IntWrapper(persistedValue: 3).persistableValue], count: 1) {
            $0.setOptInt.persistableValue.contains(IntWrapper(persistedValue: 1).persistableValue...IntWrapper(persistedValue: 3).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((setOptInt.@min >= %@) && (setOptInt.@max < %@))",
                    values: [IntWrapper(persistedValue: 1).persistableValue, IntWrapper(persistedValue: 3).persistableValue], count: 0) {
            $0.setOptInt.persistableValue.contains(IntWrapper(persistedValue: 1).persistableValue..<IntWrapper(persistedValue: 3).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((setOptInt8.@min >= %@) && (setOptInt8.@max <= %@))",
                    values: [Int8Wrapper(persistedValue: Int8(8)).persistableValue, Int8Wrapper(persistedValue: Int8(9)).persistableValue], count: 1) {
            $0.setOptInt8.persistableValue.contains(Int8Wrapper(persistedValue: Int8(8)).persistableValue...Int8Wrapper(persistedValue: Int8(9)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((setOptInt8.@min >= %@) && (setOptInt8.@max < %@))",
                    values: [Int8Wrapper(persistedValue: Int8(8)).persistableValue, Int8Wrapper(persistedValue: Int8(9)).persistableValue], count: 0) {
            $0.setOptInt8.persistableValue.contains(Int8Wrapper(persistedValue: Int8(8)).persistableValue..<Int8Wrapper(persistedValue: Int8(9)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((setOptInt16.@min >= %@) && (setOptInt16.@max <= %@))",
                    values: [Int16Wrapper(persistedValue: Int16(16)).persistableValue, Int16Wrapper(persistedValue: Int16(17)).persistableValue], count: 1) {
            $0.setOptInt16.persistableValue.contains(Int16Wrapper(persistedValue: Int16(16)).persistableValue...Int16Wrapper(persistedValue: Int16(17)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((setOptInt16.@min >= %@) && (setOptInt16.@max < %@))",
                    values: [Int16Wrapper(persistedValue: Int16(16)).persistableValue, Int16Wrapper(persistedValue: Int16(17)).persistableValue], count: 0) {
            $0.setOptInt16.persistableValue.contains(Int16Wrapper(persistedValue: Int16(16)).persistableValue..<Int16Wrapper(persistedValue: Int16(17)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((setOptInt32.@min >= %@) && (setOptInt32.@max <= %@))",
                    values: [Int32Wrapper(persistedValue: Int32(32)).persistableValue, Int32Wrapper(persistedValue: Int32(33)).persistableValue], count: 1) {
            $0.setOptInt32.persistableValue.contains(Int32Wrapper(persistedValue: Int32(32)).persistableValue...Int32Wrapper(persistedValue: Int32(33)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((setOptInt32.@min >= %@) && (setOptInt32.@max < %@))",
                    values: [Int32Wrapper(persistedValue: Int32(32)).persistableValue, Int32Wrapper(persistedValue: Int32(33)).persistableValue], count: 0) {
            $0.setOptInt32.persistableValue.contains(Int32Wrapper(persistedValue: Int32(32)).persistableValue..<Int32Wrapper(persistedValue: Int32(33)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((setOptInt64.@min >= %@) && (setOptInt64.@max <= %@))",
                    values: [Int64Wrapper(persistedValue: Int64(64)).persistableValue, Int64Wrapper(persistedValue: Int64(65)).persistableValue], count: 1) {
            $0.setOptInt64.persistableValue.contains(Int64Wrapper(persistedValue: Int64(64)).persistableValue...Int64Wrapper(persistedValue: Int64(65)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((setOptInt64.@min >= %@) && (setOptInt64.@max < %@))",
                    values: [Int64Wrapper(persistedValue: Int64(64)).persistableValue, Int64Wrapper(persistedValue: Int64(65)).persistableValue], count: 0) {
            $0.setOptInt64.persistableValue.contains(Int64Wrapper(persistedValue: Int64(64)).persistableValue..<Int64Wrapper(persistedValue: Int64(65)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((setOptFloat.@min >= %@) && (setOptFloat.@max <= %@))",
                    values: [FloatWrapper(persistedValue: Float(5.55444333)).persistableValue, FloatWrapper(persistedValue: Float(6.55444333)).persistableValue], count: 1) {
            $0.setOptFloat.persistableValue.contains(FloatWrapper(persistedValue: Float(5.55444333)).persistableValue...FloatWrapper(persistedValue: Float(6.55444333)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((setOptFloat.@min >= %@) && (setOptFloat.@max < %@))",
                    values: [FloatWrapper(persistedValue: Float(5.55444333)).persistableValue, FloatWrapper(persistedValue: Float(6.55444333)).persistableValue], count: 0) {
            $0.setOptFloat.persistableValue.contains(FloatWrapper(persistedValue: Float(5.55444333)).persistableValue..<FloatWrapper(persistedValue: Float(6.55444333)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((setOptDouble.@min >= %@) && (setOptDouble.@max <= %@))",
                    values: [DoubleWrapper(persistedValue: 123.456).persistableValue, DoubleWrapper(persistedValue: 234.567).persistableValue], count: 1) {
            $0.setOptDouble.persistableValue.contains(DoubleWrapper(persistedValue: 123.456).persistableValue...DoubleWrapper(persistedValue: 234.567).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((setOptDouble.@min >= %@) && (setOptDouble.@max < %@))",
                    values: [DoubleWrapper(persistedValue: 123.456).persistableValue, DoubleWrapper(persistedValue: 234.567).persistableValue], count: 0) {
            $0.setOptDouble.persistableValue.contains(DoubleWrapper(persistedValue: 123.456).persistableValue..<DoubleWrapper(persistedValue: 234.567).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((setOptDate.@min >= %@) && (setOptDate.@max <= %@))",
                    values: [DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)).persistableValue, DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)).persistableValue], count: 1) {
            $0.setOptDate.persistableValue.contains(DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)).persistableValue...DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((setOptDate.@min >= %@) && (setOptDate.@max < %@))",
                    values: [DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)).persistableValue, DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)).persistableValue], count: 0) {
            $0.setOptDate.persistableValue.contains(DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)).persistableValue..<DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((setOptDecimal.@min >= %@) && (setOptDecimal.@max <= %@))",
                    values: [Decimal128Wrapper(persistedValue: Decimal128(123.456)).persistableValue, Decimal128Wrapper(persistedValue: Decimal128(234.567)).persistableValue], count: 1) {
            $0.setOptDecimal.persistableValue.contains(Decimal128Wrapper(persistedValue: Decimal128(123.456)).persistableValue...Decimal128Wrapper(persistedValue: Decimal128(234.567)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((setOptDecimal.@min >= %@) && (setOptDecimal.@max < %@))",
                    values: [Decimal128Wrapper(persistedValue: Decimal128(123.456)).persistableValue, Decimal128Wrapper(persistedValue: Decimal128(234.567)).persistableValue], count: 0) {
            $0.setOptDecimal.persistableValue.contains(Decimal128Wrapper(persistedValue: Decimal128(123.456)).persistableValue..<Decimal128Wrapper(persistedValue: Decimal128(234.567)).persistableValue)
        }
        assertQuery(ModernAllTypesObject.self, "((mapInt.@min >= %@) && (mapInt.@max <= %@))",
                    values: [1, 3], count: 1) {
            $0.mapInt.contains(1...3)
        }
        assertQuery(ModernAllTypesObject.self, "((mapInt.@min >= %@) && (mapInt.@max < %@))",
                    values: [1, 3], count: 0) {
            $0.mapInt.contains(1..<3)
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
        assertQuery(CustomPersistableCollections.self, "((mapInt.@min >= %@) && (mapInt.@max <= %@))",
                    values: [IntWrapper(persistedValue: 1).persistableValue, IntWrapper(persistedValue: 3).persistableValue], count: 1) {
            $0.mapInt.persistableValue.contains(IntWrapper(persistedValue: 1).persistableValue...IntWrapper(persistedValue: 3).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((mapInt.@min >= %@) && (mapInt.@max < %@))",
                    values: [IntWrapper(persistedValue: 1).persistableValue, IntWrapper(persistedValue: 3).persistableValue], count: 0) {
            $0.mapInt.persistableValue.contains(IntWrapper(persistedValue: 1).persistableValue..<IntWrapper(persistedValue: 3).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((mapInt8.@min >= %@) && (mapInt8.@max <= %@))",
                    values: [Int8Wrapper(persistedValue: Int8(8)).persistableValue, Int8Wrapper(persistedValue: Int8(9)).persistableValue], count: 1) {
            $0.mapInt8.persistableValue.contains(Int8Wrapper(persistedValue: Int8(8)).persistableValue...Int8Wrapper(persistedValue: Int8(9)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((mapInt8.@min >= %@) && (mapInt8.@max < %@))",
                    values: [Int8Wrapper(persistedValue: Int8(8)).persistableValue, Int8Wrapper(persistedValue: Int8(9)).persistableValue], count: 0) {
            $0.mapInt8.persistableValue.contains(Int8Wrapper(persistedValue: Int8(8)).persistableValue..<Int8Wrapper(persistedValue: Int8(9)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((mapInt16.@min >= %@) && (mapInt16.@max <= %@))",
                    values: [Int16Wrapper(persistedValue: Int16(16)).persistableValue, Int16Wrapper(persistedValue: Int16(17)).persistableValue], count: 1) {
            $0.mapInt16.persistableValue.contains(Int16Wrapper(persistedValue: Int16(16)).persistableValue...Int16Wrapper(persistedValue: Int16(17)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((mapInt16.@min >= %@) && (mapInt16.@max < %@))",
                    values: [Int16Wrapper(persistedValue: Int16(16)).persistableValue, Int16Wrapper(persistedValue: Int16(17)).persistableValue], count: 0) {
            $0.mapInt16.persistableValue.contains(Int16Wrapper(persistedValue: Int16(16)).persistableValue..<Int16Wrapper(persistedValue: Int16(17)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((mapInt32.@min >= %@) && (mapInt32.@max <= %@))",
                    values: [Int32Wrapper(persistedValue: Int32(32)).persistableValue, Int32Wrapper(persistedValue: Int32(33)).persistableValue], count: 1) {
            $0.mapInt32.persistableValue.contains(Int32Wrapper(persistedValue: Int32(32)).persistableValue...Int32Wrapper(persistedValue: Int32(33)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((mapInt32.@min >= %@) && (mapInt32.@max < %@))",
                    values: [Int32Wrapper(persistedValue: Int32(32)).persistableValue, Int32Wrapper(persistedValue: Int32(33)).persistableValue], count: 0) {
            $0.mapInt32.persistableValue.contains(Int32Wrapper(persistedValue: Int32(32)).persistableValue..<Int32Wrapper(persistedValue: Int32(33)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((mapInt64.@min >= %@) && (mapInt64.@max <= %@))",
                    values: [Int64Wrapper(persistedValue: Int64(64)).persistableValue, Int64Wrapper(persistedValue: Int64(65)).persistableValue], count: 1) {
            $0.mapInt64.persistableValue.contains(Int64Wrapper(persistedValue: Int64(64)).persistableValue...Int64Wrapper(persistedValue: Int64(65)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((mapInt64.@min >= %@) && (mapInt64.@max < %@))",
                    values: [Int64Wrapper(persistedValue: Int64(64)).persistableValue, Int64Wrapper(persistedValue: Int64(65)).persistableValue], count: 0) {
            $0.mapInt64.persistableValue.contains(Int64Wrapper(persistedValue: Int64(64)).persistableValue..<Int64Wrapper(persistedValue: Int64(65)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((mapFloat.@min >= %@) && (mapFloat.@max <= %@))",
                    values: [FloatWrapper(persistedValue: Float(5.55444333)).persistableValue, FloatWrapper(persistedValue: Float(6.55444333)).persistableValue], count: 1) {
            $0.mapFloat.persistableValue.contains(FloatWrapper(persistedValue: Float(5.55444333)).persistableValue...FloatWrapper(persistedValue: Float(6.55444333)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((mapFloat.@min >= %@) && (mapFloat.@max < %@))",
                    values: [FloatWrapper(persistedValue: Float(5.55444333)).persistableValue, FloatWrapper(persistedValue: Float(6.55444333)).persistableValue], count: 0) {
            $0.mapFloat.persistableValue.contains(FloatWrapper(persistedValue: Float(5.55444333)).persistableValue..<FloatWrapper(persistedValue: Float(6.55444333)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((mapDouble.@min >= %@) && (mapDouble.@max <= %@))",
                    values: [DoubleWrapper(persistedValue: 123.456).persistableValue, DoubleWrapper(persistedValue: 234.567).persistableValue], count: 1) {
            $0.mapDouble.persistableValue.contains(DoubleWrapper(persistedValue: 123.456).persistableValue...DoubleWrapper(persistedValue: 234.567).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((mapDouble.@min >= %@) && (mapDouble.@max < %@))",
                    values: [DoubleWrapper(persistedValue: 123.456).persistableValue, DoubleWrapper(persistedValue: 234.567).persistableValue], count: 0) {
            $0.mapDouble.persistableValue.contains(DoubleWrapper(persistedValue: 123.456).persistableValue..<DoubleWrapper(persistedValue: 234.567).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((mapDate.@min >= %@) && (mapDate.@max <= %@))",
                    values: [DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)).persistableValue, DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)).persistableValue], count: 1) {
            $0.mapDate.persistableValue.contains(DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)).persistableValue...DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((mapDate.@min >= %@) && (mapDate.@max < %@))",
                    values: [DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)).persistableValue, DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)).persistableValue], count: 0) {
            $0.mapDate.persistableValue.contains(DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)).persistableValue..<DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((mapDecimal.@min >= %@) && (mapDecimal.@max <= %@))",
                    values: [Decimal128Wrapper(persistedValue: Decimal128(123.456)).persistableValue, Decimal128Wrapper(persistedValue: Decimal128(234.567)).persistableValue], count: 1) {
            $0.mapDecimal.persistableValue.contains(Decimal128Wrapper(persistedValue: Decimal128(123.456)).persistableValue...Decimal128Wrapper(persistedValue: Decimal128(234.567)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((mapDecimal.@min >= %@) && (mapDecimal.@max < %@))",
                    values: [Decimal128Wrapper(persistedValue: Decimal128(123.456)).persistableValue, Decimal128Wrapper(persistedValue: Decimal128(234.567)).persistableValue], count: 0) {
            $0.mapDecimal.persistableValue.contains(Decimal128Wrapper(persistedValue: Decimal128(123.456)).persistableValue..<Decimal128Wrapper(persistedValue: Decimal128(234.567)).persistableValue)
        }
        assertQuery(ModernAllTypesObject.self, "((mapOptInt.@min >= %@) && (mapOptInt.@max <= %@))",
                    values: [1, 3], count: 1) {
            $0.mapOptInt.contains(1...3)
        }
        assertQuery(ModernAllTypesObject.self, "((mapOptInt.@min >= %@) && (mapOptInt.@max < %@))",
                    values: [1, 3], count: 0) {
            $0.mapOptInt.contains(1..<3)
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
        assertQuery(CustomPersistableCollections.self, "((mapOptInt.@min >= %@) && (mapOptInt.@max <= %@))",
                    values: [IntWrapper(persistedValue: 1).persistableValue, IntWrapper(persistedValue: 3).persistableValue], count: 1) {
            $0.mapOptInt.persistableValue.contains(IntWrapper(persistedValue: 1).persistableValue...IntWrapper(persistedValue: 3).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((mapOptInt.@min >= %@) && (mapOptInt.@max < %@))",
                    values: [IntWrapper(persistedValue: 1).persistableValue, IntWrapper(persistedValue: 3).persistableValue], count: 0) {
            $0.mapOptInt.persistableValue.contains(IntWrapper(persistedValue: 1).persistableValue..<IntWrapper(persistedValue: 3).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((mapOptInt8.@min >= %@) && (mapOptInt8.@max <= %@))",
                    values: [Int8Wrapper(persistedValue: Int8(8)).persistableValue, Int8Wrapper(persistedValue: Int8(9)).persistableValue], count: 1) {
            $0.mapOptInt8.persistableValue.contains(Int8Wrapper(persistedValue: Int8(8)).persistableValue...Int8Wrapper(persistedValue: Int8(9)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((mapOptInt8.@min >= %@) && (mapOptInt8.@max < %@))",
                    values: [Int8Wrapper(persistedValue: Int8(8)).persistableValue, Int8Wrapper(persistedValue: Int8(9)).persistableValue], count: 0) {
            $0.mapOptInt8.persistableValue.contains(Int8Wrapper(persistedValue: Int8(8)).persistableValue..<Int8Wrapper(persistedValue: Int8(9)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((mapOptInt16.@min >= %@) && (mapOptInt16.@max <= %@))",
                    values: [Int16Wrapper(persistedValue: Int16(16)).persistableValue, Int16Wrapper(persistedValue: Int16(17)).persistableValue], count: 1) {
            $0.mapOptInt16.persistableValue.contains(Int16Wrapper(persistedValue: Int16(16)).persistableValue...Int16Wrapper(persistedValue: Int16(17)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((mapOptInt16.@min >= %@) && (mapOptInt16.@max < %@))",
                    values: [Int16Wrapper(persistedValue: Int16(16)).persistableValue, Int16Wrapper(persistedValue: Int16(17)).persistableValue], count: 0) {
            $0.mapOptInt16.persistableValue.contains(Int16Wrapper(persistedValue: Int16(16)).persistableValue..<Int16Wrapper(persistedValue: Int16(17)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((mapOptInt32.@min >= %@) && (mapOptInt32.@max <= %@))",
                    values: [Int32Wrapper(persistedValue: Int32(32)).persistableValue, Int32Wrapper(persistedValue: Int32(33)).persistableValue], count: 1) {
            $0.mapOptInt32.persistableValue.contains(Int32Wrapper(persistedValue: Int32(32)).persistableValue...Int32Wrapper(persistedValue: Int32(33)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((mapOptInt32.@min >= %@) && (mapOptInt32.@max < %@))",
                    values: [Int32Wrapper(persistedValue: Int32(32)).persistableValue, Int32Wrapper(persistedValue: Int32(33)).persistableValue], count: 0) {
            $0.mapOptInt32.persistableValue.contains(Int32Wrapper(persistedValue: Int32(32)).persistableValue..<Int32Wrapper(persistedValue: Int32(33)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((mapOptInt64.@min >= %@) && (mapOptInt64.@max <= %@))",
                    values: [Int64Wrapper(persistedValue: Int64(64)).persistableValue, Int64Wrapper(persistedValue: Int64(65)).persistableValue], count: 1) {
            $0.mapOptInt64.persistableValue.contains(Int64Wrapper(persistedValue: Int64(64)).persistableValue...Int64Wrapper(persistedValue: Int64(65)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((mapOptInt64.@min >= %@) && (mapOptInt64.@max < %@))",
                    values: [Int64Wrapper(persistedValue: Int64(64)).persistableValue, Int64Wrapper(persistedValue: Int64(65)).persistableValue], count: 0) {
            $0.mapOptInt64.persistableValue.contains(Int64Wrapper(persistedValue: Int64(64)).persistableValue..<Int64Wrapper(persistedValue: Int64(65)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((mapOptFloat.@min >= %@) && (mapOptFloat.@max <= %@))",
                    values: [FloatWrapper(persistedValue: Float(5.55444333)).persistableValue, FloatWrapper(persistedValue: Float(6.55444333)).persistableValue], count: 1) {
            $0.mapOptFloat.persistableValue.contains(FloatWrapper(persistedValue: Float(5.55444333)).persistableValue...FloatWrapper(persistedValue: Float(6.55444333)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((mapOptFloat.@min >= %@) && (mapOptFloat.@max < %@))",
                    values: [FloatWrapper(persistedValue: Float(5.55444333)).persistableValue, FloatWrapper(persistedValue: Float(6.55444333)).persistableValue], count: 0) {
            $0.mapOptFloat.persistableValue.contains(FloatWrapper(persistedValue: Float(5.55444333)).persistableValue..<FloatWrapper(persistedValue: Float(6.55444333)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((mapOptDouble.@min >= %@) && (mapOptDouble.@max <= %@))",
                    values: [DoubleWrapper(persistedValue: 123.456).persistableValue, DoubleWrapper(persistedValue: 234.567).persistableValue], count: 1) {
            $0.mapOptDouble.persistableValue.contains(DoubleWrapper(persistedValue: 123.456).persistableValue...DoubleWrapper(persistedValue: 234.567).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((mapOptDouble.@min >= %@) && (mapOptDouble.@max < %@))",
                    values: [DoubleWrapper(persistedValue: 123.456).persistableValue, DoubleWrapper(persistedValue: 234.567).persistableValue], count: 0) {
            $0.mapOptDouble.persistableValue.contains(DoubleWrapper(persistedValue: 123.456).persistableValue..<DoubleWrapper(persistedValue: 234.567).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((mapOptDate.@min >= %@) && (mapOptDate.@max <= %@))",
                    values: [DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)).persistableValue, DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)).persistableValue], count: 1) {
            $0.mapOptDate.persistableValue.contains(DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)).persistableValue...DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((mapOptDate.@min >= %@) && (mapOptDate.@max < %@))",
                    values: [DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)).persistableValue, DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)).persistableValue], count: 0) {
            $0.mapOptDate.persistableValue.contains(DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)).persistableValue..<DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((mapOptDecimal.@min >= %@) && (mapOptDecimal.@max <= %@))",
                    values: [Decimal128Wrapper(persistedValue: Decimal128(123.456)).persistableValue, Decimal128Wrapper(persistedValue: Decimal128(234.567)).persistableValue], count: 1) {
            $0.mapOptDecimal.persistableValue.contains(Decimal128Wrapper(persistedValue: Decimal128(123.456)).persistableValue...Decimal128Wrapper(persistedValue: Decimal128(234.567)).persistableValue)
        }
        assertQuery(CustomPersistableCollections.self, "((mapOptDecimal.@min >= %@) && (mapOptDecimal.@max < %@))",
                    values: [Decimal128Wrapper(persistedValue: Decimal128(123.456)).persistableValue, Decimal128Wrapper(persistedValue: Decimal128(234.567)).persistableValue], count: 0) {
            $0.mapOptDecimal.persistableValue.contains(Decimal128Wrapper(persistedValue: Decimal128(123.456)).persistableValue..<Decimal128Wrapper(persistedValue: Decimal128(234.567)).persistableValue)
        }
    }

    func testListContainsAnyInObject() {
        assertQuery(ModernAllTypesObject.self, "(ANY arrayBool IN %@)",
                    values: [NSArray(array: [true, true])], count: 1) {
            $0.arrayBool.containsAny(in: [true, true])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayInt IN %@)",
                    values: [NSArray(array: [1, 3])], count: 1) {
            $0.arrayInt.containsAny(in: [1, 3])
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
        assertQuery(CustomPersistableCollections.self, "(ANY listBool IN %@)",
                    values: [NSArray(array: [BoolWrapper(persistedValue: true), BoolWrapper(persistedValue: true)])], count: 1) {
            $0.listBool.containsAny(in: [BoolWrapper(persistedValue: true), BoolWrapper(persistedValue: true)])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listInt IN %@)",
                    values: [NSArray(array: [IntWrapper(persistedValue: 1), IntWrapper(persistedValue: 3)])], count: 1) {
            $0.listInt.containsAny(in: [IntWrapper(persistedValue: 1), IntWrapper(persistedValue: 3)])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listInt8 IN %@)",
                    values: [NSArray(array: [Int8Wrapper(persistedValue: Int8(8)), Int8Wrapper(persistedValue: Int8(9))])], count: 1) {
            $0.listInt8.containsAny(in: [Int8Wrapper(persistedValue: Int8(8)), Int8Wrapper(persistedValue: Int8(9))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listInt16 IN %@)",
                    values: [NSArray(array: [Int16Wrapper(persistedValue: Int16(16)), Int16Wrapper(persistedValue: Int16(17))])], count: 1) {
            $0.listInt16.containsAny(in: [Int16Wrapper(persistedValue: Int16(16)), Int16Wrapper(persistedValue: Int16(17))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listInt32 IN %@)",
                    values: [NSArray(array: [Int32Wrapper(persistedValue: Int32(32)), Int32Wrapper(persistedValue: Int32(33))])], count: 1) {
            $0.listInt32.containsAny(in: [Int32Wrapper(persistedValue: Int32(32)), Int32Wrapper(persistedValue: Int32(33))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listInt64 IN %@)",
                    values: [NSArray(array: [Int64Wrapper(persistedValue: Int64(64)), Int64Wrapper(persistedValue: Int64(65))])], count: 1) {
            $0.listInt64.containsAny(in: [Int64Wrapper(persistedValue: Int64(64)), Int64Wrapper(persistedValue: Int64(65))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listFloat IN %@)",
                    values: [NSArray(array: [FloatWrapper(persistedValue: Float(5.55444333)), FloatWrapper(persistedValue: Float(6.55444333))])], count: 1) {
            $0.listFloat.containsAny(in: [FloatWrapper(persistedValue: Float(5.55444333)), FloatWrapper(persistedValue: Float(6.55444333))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listDouble IN %@)",
                    values: [NSArray(array: [DoubleWrapper(persistedValue: 123.456), DoubleWrapper(persistedValue: 234.567)])], count: 1) {
            $0.listDouble.containsAny(in: [DoubleWrapper(persistedValue: 123.456), DoubleWrapper(persistedValue: 234.567)])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listString IN %@)",
                    values: [NSArray(array: [StringWrapper(persistedValue: "Foo"), StringWrapper(persistedValue: "Foó")])], count: 1) {
            $0.listString.containsAny(in: [StringWrapper(persistedValue: "Foo"), StringWrapper(persistedValue: "Foó")])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listBinary IN %@)",
                    values: [NSArray(array: [DataWrapper(persistedValue: Data(count: 64)), DataWrapper(persistedValue: Data(count: 128))])], count: 1) {
            $0.listBinary.containsAny(in: [DataWrapper(persistedValue: Data(count: 64)), DataWrapper(persistedValue: Data(count: 128))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listDate IN %@)",
                    values: [NSArray(array: [DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)), DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000))])], count: 1) {
            $0.listDate.containsAny(in: [DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)), DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listDecimal IN %@)",
                    values: [NSArray(array: [Decimal128Wrapper(persistedValue: Decimal128(123.456)), Decimal128Wrapper(persistedValue: Decimal128(234.567))])], count: 1) {
            $0.listDecimal.containsAny(in: [Decimal128Wrapper(persistedValue: Decimal128(123.456)), Decimal128Wrapper(persistedValue: Decimal128(234.567))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listObjectId IN %@)",
                    values: [NSArray(array: [ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695046")), ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045"))])], count: 1) {
            $0.listObjectId.containsAny(in: [ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695046")), ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045"))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listUuid IN %@)",
                    values: [NSArray(array: [UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!), UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)])], count: 1) {
            $0.listUuid.containsAny(in: [UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!), UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayOptBool IN %@)",
                    values: [NSArray(array: [true, true])], count: 1) {
            $0.arrayOptBool.containsAny(in: [true, true])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayOptInt IN %@)",
                    values: [NSArray(array: [1, 3])], count: 1) {
            $0.arrayOptInt.containsAny(in: [1, 3])
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
        assertQuery(CustomPersistableCollections.self, "(ANY listOptBool IN %@)",
                    values: [NSArray(array: [BoolWrapper(persistedValue: true), BoolWrapper(persistedValue: true)])], count: 1) {
            $0.listOptBool.containsAny(in: [BoolWrapper(persistedValue: true), BoolWrapper(persistedValue: true)])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listOptInt IN %@)",
                    values: [NSArray(array: [IntWrapper(persistedValue: 1), IntWrapper(persistedValue: 3)])], count: 1) {
            $0.listOptInt.containsAny(in: [IntWrapper(persistedValue: 1), IntWrapper(persistedValue: 3)])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listOptInt8 IN %@)",
                    values: [NSArray(array: [Int8Wrapper(persistedValue: Int8(8)), Int8Wrapper(persistedValue: Int8(9))])], count: 1) {
            $0.listOptInt8.containsAny(in: [Int8Wrapper(persistedValue: Int8(8)), Int8Wrapper(persistedValue: Int8(9))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listOptInt16 IN %@)",
                    values: [NSArray(array: [Int16Wrapper(persistedValue: Int16(16)), Int16Wrapper(persistedValue: Int16(17))])], count: 1) {
            $0.listOptInt16.containsAny(in: [Int16Wrapper(persistedValue: Int16(16)), Int16Wrapper(persistedValue: Int16(17))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listOptInt32 IN %@)",
                    values: [NSArray(array: [Int32Wrapper(persistedValue: Int32(32)), Int32Wrapper(persistedValue: Int32(33))])], count: 1) {
            $0.listOptInt32.containsAny(in: [Int32Wrapper(persistedValue: Int32(32)), Int32Wrapper(persistedValue: Int32(33))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listOptInt64 IN %@)",
                    values: [NSArray(array: [Int64Wrapper(persistedValue: Int64(64)), Int64Wrapper(persistedValue: Int64(65))])], count: 1) {
            $0.listOptInt64.containsAny(in: [Int64Wrapper(persistedValue: Int64(64)), Int64Wrapper(persistedValue: Int64(65))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listOptFloat IN %@)",
                    values: [NSArray(array: [FloatWrapper(persistedValue: Float(5.55444333)), FloatWrapper(persistedValue: Float(6.55444333))])], count: 1) {
            $0.listOptFloat.containsAny(in: [FloatWrapper(persistedValue: Float(5.55444333)), FloatWrapper(persistedValue: Float(6.55444333))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listOptDouble IN %@)",
                    values: [NSArray(array: [DoubleWrapper(persistedValue: 123.456), DoubleWrapper(persistedValue: 234.567)])], count: 1) {
            $0.listOptDouble.containsAny(in: [DoubleWrapper(persistedValue: 123.456), DoubleWrapper(persistedValue: 234.567)])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listOptString IN %@)",
                    values: [NSArray(array: [StringWrapper(persistedValue: "Foo"), StringWrapper(persistedValue: "Foó")])], count: 1) {
            $0.listOptString.containsAny(in: [StringWrapper(persistedValue: "Foo"), StringWrapper(persistedValue: "Foó")])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listOptBinary IN %@)",
                    values: [NSArray(array: [DataWrapper(persistedValue: Data(count: 64)), DataWrapper(persistedValue: Data(count: 128))])], count: 1) {
            $0.listOptBinary.containsAny(in: [DataWrapper(persistedValue: Data(count: 64)), DataWrapper(persistedValue: Data(count: 128))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listOptDate IN %@)",
                    values: [NSArray(array: [DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)), DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000))])], count: 1) {
            $0.listOptDate.containsAny(in: [DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)), DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listOptDecimal IN %@)",
                    values: [NSArray(array: [Decimal128Wrapper(persistedValue: Decimal128(123.456)), Decimal128Wrapper(persistedValue: Decimal128(234.567))])], count: 1) {
            $0.listOptDecimal.containsAny(in: [Decimal128Wrapper(persistedValue: Decimal128(123.456)), Decimal128Wrapper(persistedValue: Decimal128(234.567))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listOptObjectId IN %@)",
                    values: [NSArray(array: [ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695046")), ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045"))])], count: 1) {
            $0.listOptObjectId.containsAny(in: [ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695046")), ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045"))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listOptUuid IN %@)",
                    values: [NSArray(array: [UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!), UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)])], count: 1) {
            $0.listOptUuid.containsAny(in: [UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!), UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)])
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
        try! realm.write {
            let objCustomPersistableCollections = realm.objects(CustomPersistableCollections.self).first!
            _ = realm.create(LinkToCustomPersistableCollections.self, value: [
                "list": [objCustomPersistableCollections],
                "set": [objCustomPersistableCollections],
                "map": ["foo": objCustomPersistableCollections]
            ])
            let objAllCustomPersistableTypes = realm.objects(AllCustomPersistableTypes.self).first!
            _ = realm.create(LinkToAllCustomPersistableTypes.self, value: [
                "list": [objAllCustomPersistableTypes],
                "set": [objAllCustomPersistableTypes],
                "map": ["foo": objAllCustomPersistableTypes]
            ])
            let objModernAllTypesObject = realm.objects(ModernAllTypesObject.self).first!
            _ = realm.create(LinkToModernAllTypesObject.self, value: [
                "list": [objModernAllTypesObject],
                "set": [objModernAllTypesObject],
                "map": ["foo": objModernAllTypesObject]
            ])
            let objModernCollectionsOfEnums = realm.objects(ModernCollectionsOfEnums.self).first!
            _ = realm.create(LinkToModernCollectionsOfEnums.self, value: [
                "list": [objModernCollectionsOfEnums],
                "set": [objModernCollectionsOfEnums],
                "map": ["foo": objModernCollectionsOfEnums]
            ])
        }

        func test<Root: LinkToTestObject>(
                _ type: Root.Type, _ predicate: String, _ value: Any,
                _ q1: ((Query<Root.Child>) -> Query<Bool>), _ q2: ((Query<Root.Child?>) -> Query<Bool>)) {
            assertPredicate(predicate, [value], q1)
            assertPredicate(predicate, [value], q2)
            let obj = realm.objects(Root.self).first!
            XCTAssertEqual(obj.list.where(q1).count, 1)
            XCTAssertEqual(obj.set.where(q1).count, 1)
            XCTAssertEqual(obj.map.where(q2).count, 1)
        }

        // swiftlint:disable opening_brace
        test(LinkToModernAllTypesObject.self, "(boolCol == %@)",
             false,
             { $0.boolCol == false },
             { $0.boolCol == false })
        test(LinkToModernAllTypesObject.self, "(intCol == %@)",
             3,
             { $0.intCol == 3 },
             { $0.intCol == 3 })
        test(LinkToModernAllTypesObject.self, "(int8Col == %@)",
             Int8(9),
             { $0.int8Col == Int8(9) },
             { $0.int8Col == Int8(9) })
        test(LinkToModernAllTypesObject.self, "(int16Col == %@)",
             Int16(17),
             { $0.int16Col == Int16(17) },
             { $0.int16Col == Int16(17) })
        test(LinkToModernAllTypesObject.self, "(int32Col == %@)",
             Int32(33),
             { $0.int32Col == Int32(33) },
             { $0.int32Col == Int32(33) })
        test(LinkToModernAllTypesObject.self, "(int64Col == %@)",
             Int64(65),
             { $0.int64Col == Int64(65) },
             { $0.int64Col == Int64(65) })
        test(LinkToModernAllTypesObject.self, "(floatCol == %@)",
             Float(6.55444333),
             { $0.floatCol == Float(6.55444333) },
             { $0.floatCol == Float(6.55444333) })
        test(LinkToModernAllTypesObject.self, "(doubleCol == %@)",
             234.567,
             { $0.doubleCol == 234.567 },
             { $0.doubleCol == 234.567 })
        test(LinkToModernAllTypesObject.self, "(stringCol == %@)",
             "Foó",
             { $0.stringCol == "Foó" },
             { $0.stringCol == "Foó" })
        test(LinkToModernAllTypesObject.self, "(binaryCol == %@)",
             Data(count: 128),
             { $0.binaryCol == Data(count: 128) },
             { $0.binaryCol == Data(count: 128) })
        test(LinkToModernAllTypesObject.self, "(dateCol == %@)",
             Date(timeIntervalSince1970: 2000000),
             { $0.dateCol == Date(timeIntervalSince1970: 2000000) },
             { $0.dateCol == Date(timeIntervalSince1970: 2000000) })
        test(LinkToModernAllTypesObject.self, "(decimalCol == %@)",
             Decimal128(234.567),
             { $0.decimalCol == Decimal128(234.567) },
             { $0.decimalCol == Decimal128(234.567) })
        test(LinkToModernAllTypesObject.self, "(objectIdCol == %@)",
             ObjectId("61184062c1d8f096a3695045"),
             { $0.objectIdCol == ObjectId("61184062c1d8f096a3695045") },
             { $0.objectIdCol == ObjectId("61184062c1d8f096a3695045") })
        test(LinkToModernAllTypesObject.self, "(uuidCol == %@)",
             UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!,
             { $0.uuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")! },
             { $0.uuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")! })
        test(LinkToModernAllTypesObject.self, "(intEnumCol == %@)",
             ModernIntEnum.value2,
             { $0.intEnumCol == .value2 },
             { $0.intEnumCol == .value2 })
        test(LinkToModernAllTypesObject.self, "(stringEnumCol == %@)",
             ModernStringEnum.value2,
             { $0.stringEnumCol == .value2 },
             { $0.stringEnumCol == .value2 })
        test(LinkToAllCustomPersistableTypes.self, "(bool == %@)",
             BoolWrapper(persistedValue: false),
             { $0.bool == BoolWrapper(persistedValue: false) },
             { $0.bool == BoolWrapper(persistedValue: false) })
        test(LinkToAllCustomPersistableTypes.self, "(int == %@)",
             IntWrapper(persistedValue: 3),
             { $0.int == IntWrapper(persistedValue: 3) },
             { $0.int == IntWrapper(persistedValue: 3) })
        test(LinkToAllCustomPersistableTypes.self, "(int8 == %@)",
             Int8Wrapper(persistedValue: Int8(9)),
             { $0.int8 == Int8Wrapper(persistedValue: Int8(9)) },
             { $0.int8 == Int8Wrapper(persistedValue: Int8(9)) })
        test(LinkToAllCustomPersistableTypes.self, "(int16 == %@)",
             Int16Wrapper(persistedValue: Int16(17)),
             { $0.int16 == Int16Wrapper(persistedValue: Int16(17)) },
             { $0.int16 == Int16Wrapper(persistedValue: Int16(17)) })
        test(LinkToAllCustomPersistableTypes.self, "(int32 == %@)",
             Int32Wrapper(persistedValue: Int32(33)),
             { $0.int32 == Int32Wrapper(persistedValue: Int32(33)) },
             { $0.int32 == Int32Wrapper(persistedValue: Int32(33)) })
        test(LinkToAllCustomPersistableTypes.self, "(int64 == %@)",
             Int64Wrapper(persistedValue: Int64(65)),
             { $0.int64 == Int64Wrapper(persistedValue: Int64(65)) },
             { $0.int64 == Int64Wrapper(persistedValue: Int64(65)) })
        test(LinkToAllCustomPersistableTypes.self, "(float == %@)",
             FloatWrapper(persistedValue: Float(6.55444333)),
             { $0.float == FloatWrapper(persistedValue: Float(6.55444333)) },
             { $0.float == FloatWrapper(persistedValue: Float(6.55444333)) })
        test(LinkToAllCustomPersistableTypes.self, "(double == %@)",
             DoubleWrapper(persistedValue: 234.567),
             { $0.double == DoubleWrapper(persistedValue: 234.567) },
             { $0.double == DoubleWrapper(persistedValue: 234.567) })
        test(LinkToAllCustomPersistableTypes.self, "(string == %@)",
             StringWrapper(persistedValue: "Foó"),
             { $0.string == StringWrapper(persistedValue: "Foó") },
             { $0.string == StringWrapper(persistedValue: "Foó") })
        test(LinkToAllCustomPersistableTypes.self, "(binary == %@)",
             DataWrapper(persistedValue: Data(count: 128)),
             { $0.binary == DataWrapper(persistedValue: Data(count: 128)) },
             { $0.binary == DataWrapper(persistedValue: Data(count: 128)) })
        test(LinkToAllCustomPersistableTypes.self, "(date == %@)",
             DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)),
             { $0.date == DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)) },
             { $0.date == DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)) })
        test(LinkToAllCustomPersistableTypes.self, "(decimal == %@)",
             Decimal128Wrapper(persistedValue: Decimal128(234.567)),
             { $0.decimal == Decimal128Wrapper(persistedValue: Decimal128(234.567)) },
             { $0.decimal == Decimal128Wrapper(persistedValue: Decimal128(234.567)) })
        test(LinkToAllCustomPersistableTypes.self, "(objectId == %@)",
             ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045")),
             { $0.objectId == ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045")) },
             { $0.objectId == ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045")) })
        test(LinkToAllCustomPersistableTypes.self, "(uuid == %@)",
             UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!),
             { $0.uuid == UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!) },
             { $0.uuid == UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!) })
        test(LinkToModernAllTypesObject.self, "(optBoolCol == %@)",
             false,
             { $0.optBoolCol == false },
             { $0.optBoolCol == false })
        test(LinkToModernAllTypesObject.self, "(optIntCol == %@)",
             3,
             { $0.optIntCol == 3 },
             { $0.optIntCol == 3 })
        test(LinkToModernAllTypesObject.self, "(optInt8Col == %@)",
             Int8(9),
             { $0.optInt8Col == Int8(9) },
             { $0.optInt8Col == Int8(9) })
        test(LinkToModernAllTypesObject.self, "(optInt16Col == %@)",
             Int16(17),
             { $0.optInt16Col == Int16(17) },
             { $0.optInt16Col == Int16(17) })
        test(LinkToModernAllTypesObject.self, "(optInt32Col == %@)",
             Int32(33),
             { $0.optInt32Col == Int32(33) },
             { $0.optInt32Col == Int32(33) })
        test(LinkToModernAllTypesObject.self, "(optInt64Col == %@)",
             Int64(65),
             { $0.optInt64Col == Int64(65) },
             { $0.optInt64Col == Int64(65) })
        test(LinkToModernAllTypesObject.self, "(optFloatCol == %@)",
             Float(6.55444333),
             { $0.optFloatCol == Float(6.55444333) },
             { $0.optFloatCol == Float(6.55444333) })
        test(LinkToModernAllTypesObject.self, "(optDoubleCol == %@)",
             234.567,
             { $0.optDoubleCol == 234.567 },
             { $0.optDoubleCol == 234.567 })
        test(LinkToModernAllTypesObject.self, "(optStringCol == %@)",
             "Foó",
             { $0.optStringCol == "Foó" },
             { $0.optStringCol == "Foó" })
        test(LinkToModernAllTypesObject.self, "(optBinaryCol == %@)",
             Data(count: 128),
             { $0.optBinaryCol == Data(count: 128) },
             { $0.optBinaryCol == Data(count: 128) })
        test(LinkToModernAllTypesObject.self, "(optDateCol == %@)",
             Date(timeIntervalSince1970: 2000000),
             { $0.optDateCol == Date(timeIntervalSince1970: 2000000) },
             { $0.optDateCol == Date(timeIntervalSince1970: 2000000) })
        test(LinkToModernAllTypesObject.self, "(optDecimalCol == %@)",
             Decimal128(234.567),
             { $0.optDecimalCol == Decimal128(234.567) },
             { $0.optDecimalCol == Decimal128(234.567) })
        test(LinkToModernAllTypesObject.self, "(optObjectIdCol == %@)",
             ObjectId("61184062c1d8f096a3695045"),
             { $0.optObjectIdCol == ObjectId("61184062c1d8f096a3695045") },
             { $0.optObjectIdCol == ObjectId("61184062c1d8f096a3695045") })
        test(LinkToModernAllTypesObject.self, "(optUuidCol == %@)",
             UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!,
             { $0.optUuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")! },
             { $0.optUuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")! })
        test(LinkToModernAllTypesObject.self, "(optIntEnumCol == %@)",
             ModernIntEnum.value2,
             { $0.optIntEnumCol == .value2 },
             { $0.optIntEnumCol == .value2 })
        test(LinkToModernAllTypesObject.self, "(optStringEnumCol == %@)",
             ModernStringEnum.value2,
             { $0.optStringEnumCol == .value2 },
             { $0.optStringEnumCol == .value2 })
        test(LinkToAllCustomPersistableTypes.self, "(optBool == %@)",
             BoolWrapper(persistedValue: false),
             { $0.optBool == BoolWrapper(persistedValue: false) },
             { $0.optBool == BoolWrapper(persistedValue: false) })
        test(LinkToAllCustomPersistableTypes.self, "(optInt == %@)",
             IntWrapper(persistedValue: 3),
             { $0.optInt == IntWrapper(persistedValue: 3) },
             { $0.optInt == IntWrapper(persistedValue: 3) })
        test(LinkToAllCustomPersistableTypes.self, "(optInt8 == %@)",
             Int8Wrapper(persistedValue: Int8(9)),
             { $0.optInt8 == Int8Wrapper(persistedValue: Int8(9)) },
             { $0.optInt8 == Int8Wrapper(persistedValue: Int8(9)) })
        test(LinkToAllCustomPersistableTypes.self, "(optInt16 == %@)",
             Int16Wrapper(persistedValue: Int16(17)),
             { $0.optInt16 == Int16Wrapper(persistedValue: Int16(17)) },
             { $0.optInt16 == Int16Wrapper(persistedValue: Int16(17)) })
        test(LinkToAllCustomPersistableTypes.self, "(optInt32 == %@)",
             Int32Wrapper(persistedValue: Int32(33)),
             { $0.optInt32 == Int32Wrapper(persistedValue: Int32(33)) },
             { $0.optInt32 == Int32Wrapper(persistedValue: Int32(33)) })
        test(LinkToAllCustomPersistableTypes.self, "(optInt64 == %@)",
             Int64Wrapper(persistedValue: Int64(65)),
             { $0.optInt64 == Int64Wrapper(persistedValue: Int64(65)) },
             { $0.optInt64 == Int64Wrapper(persistedValue: Int64(65)) })
        test(LinkToAllCustomPersistableTypes.self, "(optFloat == %@)",
             FloatWrapper(persistedValue: Float(6.55444333)),
             { $0.optFloat == FloatWrapper(persistedValue: Float(6.55444333)) },
             { $0.optFloat == FloatWrapper(persistedValue: Float(6.55444333)) })
        test(LinkToAllCustomPersistableTypes.self, "(optDouble == %@)",
             DoubleWrapper(persistedValue: 234.567),
             { $0.optDouble == DoubleWrapper(persistedValue: 234.567) },
             { $0.optDouble == DoubleWrapper(persistedValue: 234.567) })
        test(LinkToAllCustomPersistableTypes.self, "(optString == %@)",
             StringWrapper(persistedValue: "Foó"),
             { $0.optString == StringWrapper(persistedValue: "Foó") },
             { $0.optString == StringWrapper(persistedValue: "Foó") })
        test(LinkToAllCustomPersistableTypes.self, "(optBinary == %@)",
             DataWrapper(persistedValue: Data(count: 128)),
             { $0.optBinary == DataWrapper(persistedValue: Data(count: 128)) },
             { $0.optBinary == DataWrapper(persistedValue: Data(count: 128)) })
        test(LinkToAllCustomPersistableTypes.self, "(optDate == %@)",
             DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)),
             { $0.optDate == DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)) },
             { $0.optDate == DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)) })
        test(LinkToAllCustomPersistableTypes.self, "(optDecimal == %@)",
             Decimal128Wrapper(persistedValue: Decimal128(234.567)),
             { $0.optDecimal == Decimal128Wrapper(persistedValue: Decimal128(234.567)) },
             { $0.optDecimal == Decimal128Wrapper(persistedValue: Decimal128(234.567)) })
        test(LinkToAllCustomPersistableTypes.self, "(optObjectId == %@)",
             ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045")),
             { $0.optObjectId == ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045")) },
             { $0.optObjectId == ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045")) })
        test(LinkToAllCustomPersistableTypes.self, "(optUuid == %@)",
             UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!),
             { $0.optUuid == UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!) },
             { $0.optUuid == UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!) })
        // swiftlint:enable opening_brace
    }

    func testSetContainsObject() {
        let obj = objects().first!
        let colObj = collectionObject()
        let result = realm.objects(ModernCollectionObject.self).where {
            $0.set.contains(obj)
        }
        XCTAssertEqual(result.count, 0)
        try! realm.write {
            colObj.set.insert(obj)
        }
        XCTAssertEqual(result.count, 1)
    }

    func testSetContainsAnyInObject() {
        assertQuery(ModernAllTypesObject.self, "(ANY setBool IN %@)",
                    values: [NSArray(array: [true, true])], count: 1) {
            $0.setBool.containsAny(in: [true, true])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setInt IN %@)",
                    values: [NSArray(array: [1, 3])], count: 1) {
            $0.setInt.containsAny(in: [1, 3])
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
        assertQuery(CustomPersistableCollections.self, "(ANY setBool IN %@)",
                    values: [NSArray(array: [BoolWrapper(persistedValue: true), BoolWrapper(persistedValue: true)])], count: 1) {
            $0.setBool.containsAny(in: [BoolWrapper(persistedValue: true), BoolWrapper(persistedValue: true)])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setInt IN %@)",
                    values: [NSArray(array: [IntWrapper(persistedValue: 1), IntWrapper(persistedValue: 3)])], count: 1) {
            $0.setInt.containsAny(in: [IntWrapper(persistedValue: 1), IntWrapper(persistedValue: 3)])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setInt8 IN %@)",
                    values: [NSArray(array: [Int8Wrapper(persistedValue: Int8(8)), Int8Wrapper(persistedValue: Int8(9))])], count: 1) {
            $0.setInt8.containsAny(in: [Int8Wrapper(persistedValue: Int8(8)), Int8Wrapper(persistedValue: Int8(9))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setInt16 IN %@)",
                    values: [NSArray(array: [Int16Wrapper(persistedValue: Int16(16)), Int16Wrapper(persistedValue: Int16(17))])], count: 1) {
            $0.setInt16.containsAny(in: [Int16Wrapper(persistedValue: Int16(16)), Int16Wrapper(persistedValue: Int16(17))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setInt32 IN %@)",
                    values: [NSArray(array: [Int32Wrapper(persistedValue: Int32(32)), Int32Wrapper(persistedValue: Int32(33))])], count: 1) {
            $0.setInt32.containsAny(in: [Int32Wrapper(persistedValue: Int32(32)), Int32Wrapper(persistedValue: Int32(33))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setInt64 IN %@)",
                    values: [NSArray(array: [Int64Wrapper(persistedValue: Int64(64)), Int64Wrapper(persistedValue: Int64(65))])], count: 1) {
            $0.setInt64.containsAny(in: [Int64Wrapper(persistedValue: Int64(64)), Int64Wrapper(persistedValue: Int64(65))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setFloat IN %@)",
                    values: [NSArray(array: [FloatWrapper(persistedValue: Float(5.55444333)), FloatWrapper(persistedValue: Float(6.55444333))])], count: 1) {
            $0.setFloat.containsAny(in: [FloatWrapper(persistedValue: Float(5.55444333)), FloatWrapper(persistedValue: Float(6.55444333))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setDouble IN %@)",
                    values: [NSArray(array: [DoubleWrapper(persistedValue: 123.456), DoubleWrapper(persistedValue: 234.567)])], count: 1) {
            $0.setDouble.containsAny(in: [DoubleWrapper(persistedValue: 123.456), DoubleWrapper(persistedValue: 234.567)])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setString IN %@)",
                    values: [NSArray(array: [StringWrapper(persistedValue: "Foo"), StringWrapper(persistedValue: "Foó")])], count: 1) {
            $0.setString.containsAny(in: [StringWrapper(persistedValue: "Foo"), StringWrapper(persistedValue: "Foó")])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setBinary IN %@)",
                    values: [NSArray(array: [DataWrapper(persistedValue: Data(count: 64)), DataWrapper(persistedValue: Data(count: 128))])], count: 1) {
            $0.setBinary.containsAny(in: [DataWrapper(persistedValue: Data(count: 64)), DataWrapper(persistedValue: Data(count: 128))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setDate IN %@)",
                    values: [NSArray(array: [DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)), DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000))])], count: 1) {
            $0.setDate.containsAny(in: [DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)), DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setDecimal IN %@)",
                    values: [NSArray(array: [Decimal128Wrapper(persistedValue: Decimal128(123.456)), Decimal128Wrapper(persistedValue: Decimal128(234.567))])], count: 1) {
            $0.setDecimal.containsAny(in: [Decimal128Wrapper(persistedValue: Decimal128(123.456)), Decimal128Wrapper(persistedValue: Decimal128(234.567))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setObjectId IN %@)",
                    values: [NSArray(array: [ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695046")), ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045"))])], count: 1) {
            $0.setObjectId.containsAny(in: [ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695046")), ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045"))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setUuid IN %@)",
                    values: [NSArray(array: [UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!), UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)])], count: 1) {
            $0.setUuid.containsAny(in: [UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!), UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setOptBool IN %@)",
                    values: [NSArray(array: [true, true])], count: 1) {
            $0.setOptBool.containsAny(in: [true, true])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setOptInt IN %@)",
                    values: [NSArray(array: [1, 3])], count: 1) {
            $0.setOptInt.containsAny(in: [1, 3])
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
        assertQuery(CustomPersistableCollections.self, "(ANY setOptBool IN %@)",
                    values: [NSArray(array: [BoolWrapper(persistedValue: true), BoolWrapper(persistedValue: true)])], count: 1) {
            $0.setOptBool.containsAny(in: [BoolWrapper(persistedValue: true), BoolWrapper(persistedValue: true)])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setOptInt IN %@)",
                    values: [NSArray(array: [IntWrapper(persistedValue: 1), IntWrapper(persistedValue: 3)])], count: 1) {
            $0.setOptInt.containsAny(in: [IntWrapper(persistedValue: 1), IntWrapper(persistedValue: 3)])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setOptInt8 IN %@)",
                    values: [NSArray(array: [Int8Wrapper(persistedValue: Int8(8)), Int8Wrapper(persistedValue: Int8(9))])], count: 1) {
            $0.setOptInt8.containsAny(in: [Int8Wrapper(persistedValue: Int8(8)), Int8Wrapper(persistedValue: Int8(9))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setOptInt16 IN %@)",
                    values: [NSArray(array: [Int16Wrapper(persistedValue: Int16(16)), Int16Wrapper(persistedValue: Int16(17))])], count: 1) {
            $0.setOptInt16.containsAny(in: [Int16Wrapper(persistedValue: Int16(16)), Int16Wrapper(persistedValue: Int16(17))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setOptInt32 IN %@)",
                    values: [NSArray(array: [Int32Wrapper(persistedValue: Int32(32)), Int32Wrapper(persistedValue: Int32(33))])], count: 1) {
            $0.setOptInt32.containsAny(in: [Int32Wrapper(persistedValue: Int32(32)), Int32Wrapper(persistedValue: Int32(33))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setOptInt64 IN %@)",
                    values: [NSArray(array: [Int64Wrapper(persistedValue: Int64(64)), Int64Wrapper(persistedValue: Int64(65))])], count: 1) {
            $0.setOptInt64.containsAny(in: [Int64Wrapper(persistedValue: Int64(64)), Int64Wrapper(persistedValue: Int64(65))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setOptFloat IN %@)",
                    values: [NSArray(array: [FloatWrapper(persistedValue: Float(5.55444333)), FloatWrapper(persistedValue: Float(6.55444333))])], count: 1) {
            $0.setOptFloat.containsAny(in: [FloatWrapper(persistedValue: Float(5.55444333)), FloatWrapper(persistedValue: Float(6.55444333))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setOptDouble IN %@)",
                    values: [NSArray(array: [DoubleWrapper(persistedValue: 123.456), DoubleWrapper(persistedValue: 234.567)])], count: 1) {
            $0.setOptDouble.containsAny(in: [DoubleWrapper(persistedValue: 123.456), DoubleWrapper(persistedValue: 234.567)])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setOptString IN %@)",
                    values: [NSArray(array: [StringWrapper(persistedValue: "Foo"), StringWrapper(persistedValue: "Foó")])], count: 1) {
            $0.setOptString.containsAny(in: [StringWrapper(persistedValue: "Foo"), StringWrapper(persistedValue: "Foó")])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setOptBinary IN %@)",
                    values: [NSArray(array: [DataWrapper(persistedValue: Data(count: 64)), DataWrapper(persistedValue: Data(count: 128))])], count: 1) {
            $0.setOptBinary.containsAny(in: [DataWrapper(persistedValue: Data(count: 64)), DataWrapper(persistedValue: Data(count: 128))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setOptDate IN %@)",
                    values: [NSArray(array: [DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)), DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000))])], count: 1) {
            $0.setOptDate.containsAny(in: [DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)), DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setOptDecimal IN %@)",
                    values: [NSArray(array: [Decimal128Wrapper(persistedValue: Decimal128(123.456)), Decimal128Wrapper(persistedValue: Decimal128(234.567))])], count: 1) {
            $0.setOptDecimal.containsAny(in: [Decimal128Wrapper(persistedValue: Decimal128(123.456)), Decimal128Wrapper(persistedValue: Decimal128(234.567))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setOptObjectId IN %@)",
                    values: [NSArray(array: [ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695046")), ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045"))])], count: 1) {
            $0.setOptObjectId.containsAny(in: [ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695046")), ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045"))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setOptUuid IN %@)",
                    values: [NSArray(array: [UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!), UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)])], count: 1) {
            $0.setOptUuid.containsAny(in: [UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!), UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)])
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
        assertQuery(Root.self, "(ANY \(name).@allKeys == %@)", "foo", count: 1) {
            lhs($0).keys == "foo"
        }

        assertQuery(Root.self, "(ANY \(name).@allKeys != %@)", "foo", count: 1) {
            lhs($0).keys != "foo"
        }

        assertQuery(Root.self, "(ANY \(name).@allKeys CONTAINS[cd] %@)", "foo", count: 1) {
            lhs($0).keys.contains("foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(Root.self, "(ANY \(name).@allKeys CONTAINS %@)", "foo", count: 1) {
            lhs($0).keys.contains("foo")
        }

        assertQuery(Root.self, "(ANY \(name).@allKeys BEGINSWITH[cd] %@)", "foo", count: 1) {
            lhs($0).keys.starts(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(Root.self, "(ANY \(name).@allKeys BEGINSWITH %@)", "foo", count: 1) {
            lhs($0).keys.starts(with: "foo")
        }

        assertQuery(Root.self, "(ANY \(name).@allKeys ENDSWITH[cd] %@)", "foo", count: 1) {
            lhs($0).keys.ends(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(Root.self, "(ANY \(name).@allKeys ENDSWITH %@)", "foo", count: 1) {
            lhs($0).keys.ends(with: "foo")
        }

        assertQuery(Root.self, "(ANY \(name).@allKeys LIKE[c] %@)", "foo", count: 1) {
            lhs($0).keys.like("foo", caseInsensitive: true)
        }

        assertQuery(Root.self, "(ANY \(name).@allKeys LIKE %@)", "foo", count: 1) {
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
        validateAllKeys("mapBool", \Query<CustomPersistableCollections>.mapBool)
        validateAllKeys("mapInt", \Query<CustomPersistableCollections>.mapInt)
        validateAllKeys("mapInt8", \Query<CustomPersistableCollections>.mapInt8)
        validateAllKeys("mapInt16", \Query<CustomPersistableCollections>.mapInt16)
        validateAllKeys("mapInt32", \Query<CustomPersistableCollections>.mapInt32)
        validateAllKeys("mapInt64", \Query<CustomPersistableCollections>.mapInt64)
        validateAllKeys("mapFloat", \Query<CustomPersistableCollections>.mapFloat)
        validateAllKeys("mapDouble", \Query<CustomPersistableCollections>.mapDouble)
        validateAllKeys("mapString", \Query<CustomPersistableCollections>.mapString)
        validateAllKeys("mapBinary", \Query<CustomPersistableCollections>.mapBinary)
        validateAllKeys("mapDate", \Query<CustomPersistableCollections>.mapDate)
        validateAllKeys("mapDecimal", \Query<CustomPersistableCollections>.mapDecimal)
        validateAllKeys("mapObjectId", \Query<CustomPersistableCollections>.mapObjectId)
        validateAllKeys("mapUuid", \Query<CustomPersistableCollections>.mapUuid)
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
        validateAllKeys("mapOptBool", \Query<CustomPersistableCollections>.mapOptBool)
        validateAllKeys("mapOptInt", \Query<CustomPersistableCollections>.mapOptInt)
        validateAllKeys("mapOptInt8", \Query<CustomPersistableCollections>.mapOptInt8)
        validateAllKeys("mapOptInt16", \Query<CustomPersistableCollections>.mapOptInt16)
        validateAllKeys("mapOptInt32", \Query<CustomPersistableCollections>.mapOptInt32)
        validateAllKeys("mapOptInt64", \Query<CustomPersistableCollections>.mapOptInt64)
        validateAllKeys("mapOptFloat", \Query<CustomPersistableCollections>.mapOptFloat)
        validateAllKeys("mapOptDouble", \Query<CustomPersistableCollections>.mapOptDouble)
        validateAllKeys("mapOptString", \Query<CustomPersistableCollections>.mapOptString)
        validateAllKeys("mapOptBinary", \Query<CustomPersistableCollections>.mapOptBinary)
        validateAllKeys("mapOptDate", \Query<CustomPersistableCollections>.mapOptDate)
        validateAllKeys("mapOptDecimal", \Query<CustomPersistableCollections>.mapOptDecimal)
        validateAllKeys("mapOptObjectId", \Query<CustomPersistableCollections>.mapOptObjectId)
        validateAllKeys("mapOptUuid", \Query<CustomPersistableCollections>.mapOptUuid)
    }

    // swiftlint:disable unused_closure_parameter
    func testMapAllValues() {
        validateEquals("ANY mapBool.@allValues", \Query<ModernAllTypesObject>.mapBool.values, true)

        validateEquals("ANY mapInt.@allValues", \Query<ModernAllTypesObject>.mapInt.values, 1, notEqualCount: 1)
        validateNumericComparisons("ANY mapInt.@allValues", \Query<ModernAllTypesObject>.mapInt.values, 3, ltCount: 1)

        validateEquals("ANY mapInt8.@allValues", \Query<ModernAllTypesObject>.mapInt8.values, Int8(8), notEqualCount: 1)
        validateNumericComparisons("ANY mapInt8.@allValues", \Query<ModernAllTypesObject>.mapInt8.values, Int8(9), ltCount: 1)

        validateEquals("ANY mapInt16.@allValues", \Query<ModernAllTypesObject>.mapInt16.values, Int16(16), notEqualCount: 1)
        validateNumericComparisons("ANY mapInt16.@allValues", \Query<ModernAllTypesObject>.mapInt16.values, Int16(17), ltCount: 1)

        validateEquals("ANY mapInt32.@allValues", \Query<ModernAllTypesObject>.mapInt32.values, Int32(32), notEqualCount: 1)
        validateNumericComparisons("ANY mapInt32.@allValues", \Query<ModernAllTypesObject>.mapInt32.values, Int32(33), ltCount: 1)

        validateEquals("ANY mapInt64.@allValues", \Query<ModernAllTypesObject>.mapInt64.values, Int64(64), notEqualCount: 1)
        validateNumericComparisons("ANY mapInt64.@allValues", \Query<ModernAllTypesObject>.mapInt64.values, Int64(65), ltCount: 1)

        validateEquals("ANY mapFloat.@allValues", \Query<ModernAllTypesObject>.mapFloat.values, Float(5.55444333), notEqualCount: 1)
        validateNumericComparisons("ANY mapFloat.@allValues", \Query<ModernAllTypesObject>.mapFloat.values, Float(6.55444333), ltCount: 1)

        validateEquals("ANY mapDouble.@allValues", \Query<ModernAllTypesObject>.mapDouble.values, 123.456, notEqualCount: 1)
        validateNumericComparisons("ANY mapDouble.@allValues", \Query<ModernAllTypesObject>.mapDouble.values, 234.567, ltCount: 1)

        validateEquals("ANY mapString.@allValues", \Query<ModernAllTypesObject>.mapString.values, "Foo", notEqualCount: 1)
        validateStringOperations("ANY mapString.@allValues", \Query<ModernAllTypesObject>.mapString.values,
                                 ("Foo", "Foo", "Foo")) { equals, options in
            // Non-enum maps have the keys Foo and Foó, so !=[d] doesn't match any
            if options.contains(.diacriticInsensitive) {
                return equals ? 1 : 0
            }
            return 1
        }

        assertQuery(ModernAllTypesObject.self, "(ANY mapString.@allValues LIKE[c] %@)", "Foo", count: 1) {
            $0.mapString.values.like("Foo", caseInsensitive: true)
        }
        assertQuery(ModernAllTypesObject.self, "(ANY mapString.@allValues LIKE %@)", "Foo", count: 1) {
            $0.mapString.values.like("Foo")
        }

        validateEquals("ANY mapBinary.@allValues", \Query<ModernAllTypesObject>.mapBinary.values, Data(count: 64), notEqualCount: 1)

        validateEquals("ANY mapDate.@allValues", \Query<ModernAllTypesObject>.mapDate.values, Date(timeIntervalSince1970: 1000000), notEqualCount: 1)
        validateNumericComparisons("ANY mapDate.@allValues", \Query<ModernAllTypesObject>.mapDate.values, Date(timeIntervalSince1970: 2000000), ltCount: 1)

        validateEquals("ANY mapDecimal.@allValues", \Query<ModernAllTypesObject>.mapDecimal.values, Decimal128(123.456), notEqualCount: 1)
        validateNumericComparisons("ANY mapDecimal.@allValues", \Query<ModernAllTypesObject>.mapDecimal.values, Decimal128(234.567), ltCount: 1)

        validateEquals("ANY mapObjectId.@allValues", \Query<ModernAllTypesObject>.mapObjectId.values, ObjectId("61184062c1d8f096a3695046"), notEqualCount: 1)

        validateEquals("ANY mapUuid.@allValues", \Query<ModernAllTypesObject>.mapUuid.values, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, notEqualCount: 1)

        validateEquals("ANY mapAny.@allValues", \Query<ModernAllTypesObject>.mapAny.values, AnyRealmValue.objectId(ObjectId("61184062c1d8f096a3695046")), notEqualCount: 1)

        validateEquals("ANY mapInt.@allValues", \Query<ModernCollectionsOfEnums>.mapInt.values, EnumInt.value1, notEqualCount: 1)
        validateNumericComparisons("ANY mapInt.@allValues", \Query<ModernCollectionsOfEnums>.mapInt.values, .value2, ltCount: 1)

        validateEquals("ANY mapInt8.@allValues", \Query<ModernCollectionsOfEnums>.mapInt8.values, EnumInt8.value1, notEqualCount: 1)
        validateNumericComparisons("ANY mapInt8.@allValues", \Query<ModernCollectionsOfEnums>.mapInt8.values, .value2, ltCount: 1)

        validateEquals("ANY mapInt16.@allValues", \Query<ModernCollectionsOfEnums>.mapInt16.values, EnumInt16.value1, notEqualCount: 1)
        validateNumericComparisons("ANY mapInt16.@allValues", \Query<ModernCollectionsOfEnums>.mapInt16.values, .value2, ltCount: 1)

        validateEquals("ANY mapInt32.@allValues", \Query<ModernCollectionsOfEnums>.mapInt32.values, EnumInt32.value1, notEqualCount: 1)
        validateNumericComparisons("ANY mapInt32.@allValues", \Query<ModernCollectionsOfEnums>.mapInt32.values, .value2, ltCount: 1)

        validateEquals("ANY mapInt64.@allValues", \Query<ModernCollectionsOfEnums>.mapInt64.values, EnumInt64.value1, notEqualCount: 1)
        validateNumericComparisons("ANY mapInt64.@allValues", \Query<ModernCollectionsOfEnums>.mapInt64.values, .value2, ltCount: 1)

        validateEquals("ANY mapFloat.@allValues", \Query<ModernCollectionsOfEnums>.mapFloat.values, EnumFloat.value1, notEqualCount: 1)
        validateNumericComparisons("ANY mapFloat.@allValues", \Query<ModernCollectionsOfEnums>.mapFloat.values, .value2, ltCount: 1)

        validateEquals("ANY mapDouble.@allValues", \Query<ModernCollectionsOfEnums>.mapDouble.values, EnumDouble.value1, notEqualCount: 1)
        validateNumericComparisons("ANY mapDouble.@allValues", \Query<ModernCollectionsOfEnums>.mapDouble.values, .value2, ltCount: 1)

        validateEquals("ANY mapString.@allValues", \Query<ModernCollectionsOfEnums>.mapString.values, EnumString.value1, notEqualCount: 1)
        validateStringOperations("ANY mapString.@allValues", \Query<ModernCollectionsOfEnums>.mapString.values,
                                 (.value1, .value1, .value1)) { equals, options in
            return 1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(ANY mapString.@allValues LIKE[c] %@)", EnumString.value1, count: 1) {
            $0.mapString.values.like(.value1, caseInsensitive: true)
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY mapString.@allValues LIKE %@)", EnumString.value1, count: 1) {
            $0.mapString.values.like(.value1)
        }

        validateEquals("ANY mapBool.@allValues", \Query<CustomPersistableCollections>.mapBool.values, BoolWrapper(persistedValue: true))

        validateEquals("ANY mapInt.@allValues", \Query<CustomPersistableCollections>.mapInt.values, IntWrapper(persistedValue: 1), notEqualCount: 1)
        validateNumericComparisons("ANY mapInt.@allValues", \Query<CustomPersistableCollections>.mapInt.values, IntWrapper(persistedValue: 3), ltCount: 1)

        validateEquals("ANY mapInt8.@allValues", \Query<CustomPersistableCollections>.mapInt8.values, Int8Wrapper(persistedValue: Int8(8)), notEqualCount: 1)
        validateNumericComparisons("ANY mapInt8.@allValues", \Query<CustomPersistableCollections>.mapInt8.values, Int8Wrapper(persistedValue: Int8(9)), ltCount: 1)

        validateEquals("ANY mapInt16.@allValues", \Query<CustomPersistableCollections>.mapInt16.values, Int16Wrapper(persistedValue: Int16(16)), notEqualCount: 1)
        validateNumericComparisons("ANY mapInt16.@allValues", \Query<CustomPersistableCollections>.mapInt16.values, Int16Wrapper(persistedValue: Int16(17)), ltCount: 1)

        validateEquals("ANY mapInt32.@allValues", \Query<CustomPersistableCollections>.mapInt32.values, Int32Wrapper(persistedValue: Int32(32)), notEqualCount: 1)
        validateNumericComparisons("ANY mapInt32.@allValues", \Query<CustomPersistableCollections>.mapInt32.values, Int32Wrapper(persistedValue: Int32(33)), ltCount: 1)

        validateEquals("ANY mapInt64.@allValues", \Query<CustomPersistableCollections>.mapInt64.values, Int64Wrapper(persistedValue: Int64(64)), notEqualCount: 1)
        validateNumericComparisons("ANY mapInt64.@allValues", \Query<CustomPersistableCollections>.mapInt64.values, Int64Wrapper(persistedValue: Int64(65)), ltCount: 1)

        validateEquals("ANY mapFloat.@allValues", \Query<CustomPersistableCollections>.mapFloat.values, FloatWrapper(persistedValue: Float(5.55444333)), notEqualCount: 1)
        validateNumericComparisons("ANY mapFloat.@allValues", \Query<CustomPersistableCollections>.mapFloat.values, FloatWrapper(persistedValue: Float(6.55444333)), ltCount: 1)

        validateEquals("ANY mapDouble.@allValues", \Query<CustomPersistableCollections>.mapDouble.values, DoubleWrapper(persistedValue: 123.456), notEqualCount: 1)
        validateNumericComparisons("ANY mapDouble.@allValues", \Query<CustomPersistableCollections>.mapDouble.values, DoubleWrapper(persistedValue: 234.567), ltCount: 1)

        validateEquals("ANY mapString.@allValues", \Query<CustomPersistableCollections>.mapString.values, StringWrapper(persistedValue: "Foo"), notEqualCount: 1)
        validateStringOperations("ANY mapString.@allValues", \Query<CustomPersistableCollections>.mapString.values,
                                 (StringWrapper(persistedValue: "Foo"), StringWrapper(persistedValue: "Foo"), StringWrapper(persistedValue: "Foo"))) { equals, options in
            // Non-enum maps have the keys Foo and Foó, so !=[d] doesn't match any
            if options.contains(.diacriticInsensitive) {
                return equals ? 1 : 0
            }
            return 1
        }

        assertQuery(CustomPersistableCollections.self, "(ANY mapString.@allValues LIKE[c] %@)", StringWrapper(persistedValue: "Foo"), count: 1) {
            $0.mapString.values.like(StringWrapper(persistedValue: "Foo"), caseInsensitive: true)
        }
        assertQuery(CustomPersistableCollections.self, "(ANY mapString.@allValues LIKE %@)", StringWrapper(persistedValue: "Foo"), count: 1) {
            $0.mapString.values.like(StringWrapper(persistedValue: "Foo"))
        }

        validateEquals("ANY mapBinary.@allValues", \Query<CustomPersistableCollections>.mapBinary.values, DataWrapper(persistedValue: Data(count: 64)), notEqualCount: 1)

        validateEquals("ANY mapDate.@allValues", \Query<CustomPersistableCollections>.mapDate.values, DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)), notEqualCount: 1)
        validateNumericComparisons("ANY mapDate.@allValues", \Query<CustomPersistableCollections>.mapDate.values, DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)), ltCount: 1)

        validateEquals("ANY mapDecimal.@allValues", \Query<CustomPersistableCollections>.mapDecimal.values, Decimal128Wrapper(persistedValue: Decimal128(123.456)), notEqualCount: 1)
        validateNumericComparisons("ANY mapDecimal.@allValues", \Query<CustomPersistableCollections>.mapDecimal.values, Decimal128Wrapper(persistedValue: Decimal128(234.567)), ltCount: 1)

        validateEquals("ANY mapObjectId.@allValues", \Query<CustomPersistableCollections>.mapObjectId.values, ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695046")), notEqualCount: 1)

        validateEquals("ANY mapUuid.@allValues", \Query<CustomPersistableCollections>.mapUuid.values, UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!), notEqualCount: 1)

        validateEquals("ANY mapOptBool.@allValues", \Query<ModernAllTypesObject>.mapOptBool.values, true)

        validateEquals("ANY mapOptInt.@allValues", \Query<ModernAllTypesObject>.mapOptInt.values, 1, notEqualCount: 1)
        validateNumericComparisons("ANY mapOptInt.@allValues", \Query<ModernAllTypesObject>.mapOptInt.values, 3, ltCount: 1)

        validateEquals("ANY mapOptInt8.@allValues", \Query<ModernAllTypesObject>.mapOptInt8.values, Int8(8), notEqualCount: 1)
        validateNumericComparisons("ANY mapOptInt8.@allValues", \Query<ModernAllTypesObject>.mapOptInt8.values, Int8(9), ltCount: 1)

        validateEquals("ANY mapOptInt16.@allValues", \Query<ModernAllTypesObject>.mapOptInt16.values, Int16(16), notEqualCount: 1)
        validateNumericComparisons("ANY mapOptInt16.@allValues", \Query<ModernAllTypesObject>.mapOptInt16.values, Int16(17), ltCount: 1)

        validateEquals("ANY mapOptInt32.@allValues", \Query<ModernAllTypesObject>.mapOptInt32.values, Int32(32), notEqualCount: 1)
        validateNumericComparisons("ANY mapOptInt32.@allValues", \Query<ModernAllTypesObject>.mapOptInt32.values, Int32(33), ltCount: 1)

        validateEquals("ANY mapOptInt64.@allValues", \Query<ModernAllTypesObject>.mapOptInt64.values, Int64(64), notEqualCount: 1)
        validateNumericComparisons("ANY mapOptInt64.@allValues", \Query<ModernAllTypesObject>.mapOptInt64.values, Int64(65), ltCount: 1)

        validateEquals("ANY mapOptFloat.@allValues", \Query<ModernAllTypesObject>.mapOptFloat.values, Float(5.55444333), notEqualCount: 1)
        validateNumericComparisons("ANY mapOptFloat.@allValues", \Query<ModernAllTypesObject>.mapOptFloat.values, Float(6.55444333), ltCount: 1)

        validateEquals("ANY mapOptDouble.@allValues", \Query<ModernAllTypesObject>.mapOptDouble.values, 123.456, notEqualCount: 1)
        validateNumericComparisons("ANY mapOptDouble.@allValues", \Query<ModernAllTypesObject>.mapOptDouble.values, 234.567, ltCount: 1)

        validateEquals("ANY mapOptString.@allValues", \Query<ModernAllTypesObject>.mapOptString.values, "Foo", notEqualCount: 1)
        validateStringOperations("ANY mapOptString.@allValues", \Query<ModernAllTypesObject>.mapOptString.values,
                                 ("Foo", "Foo", "Foo")) { equals, options in
            // Non-enum maps have the keys Foo and Foó, so !=[d] doesn't match any
            if options.contains(.diacriticInsensitive) {
                return equals ? 1 : 0
            }
            return 1
        }

        assertQuery(ModernAllTypesObject.self, "(ANY mapOptString.@allValues LIKE[c] %@)", "Foo", count: 1) {
            $0.mapOptString.values.like("Foo", caseInsensitive: true)
        }
        assertQuery(ModernAllTypesObject.self, "(ANY mapOptString.@allValues LIKE %@)", "Foo", count: 1) {
            $0.mapOptString.values.like("Foo")
        }

        validateEquals("ANY mapOptBinary.@allValues", \Query<ModernAllTypesObject>.mapOptBinary.values, Data(count: 64), notEqualCount: 1)

        validateEquals("ANY mapOptDate.@allValues", \Query<ModernAllTypesObject>.mapOptDate.values, Date(timeIntervalSince1970: 1000000), notEqualCount: 1)
        validateNumericComparisons("ANY mapOptDate.@allValues", \Query<ModernAllTypesObject>.mapOptDate.values, Date(timeIntervalSince1970: 2000000), ltCount: 1)

        validateEquals("ANY mapOptDecimal.@allValues", \Query<ModernAllTypesObject>.mapOptDecimal.values, Decimal128(123.456), notEqualCount: 1)
        validateNumericComparisons("ANY mapOptDecimal.@allValues", \Query<ModernAllTypesObject>.mapOptDecimal.values, Decimal128(234.567), ltCount: 1)

        validateEquals("ANY mapOptObjectId.@allValues", \Query<ModernAllTypesObject>.mapOptObjectId.values, ObjectId("61184062c1d8f096a3695046"), notEqualCount: 1)

        validateEquals("ANY mapOptUuid.@allValues", \Query<ModernAllTypesObject>.mapOptUuid.values, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, notEqualCount: 1)

        validateEquals("ANY mapIntOpt.@allValues", \Query<ModernCollectionsOfEnums>.mapIntOpt.values, EnumInt.value1, notEqualCount: 1)
        validateNumericComparisons("ANY mapIntOpt.@allValues", \Query<ModernCollectionsOfEnums>.mapIntOpt.values, .value2, ltCount: 1)

        validateEquals("ANY mapInt8Opt.@allValues", \Query<ModernCollectionsOfEnums>.mapInt8Opt.values, EnumInt8.value1, notEqualCount: 1)
        validateNumericComparisons("ANY mapInt8Opt.@allValues", \Query<ModernCollectionsOfEnums>.mapInt8Opt.values, .value2, ltCount: 1)

        validateEquals("ANY mapInt16Opt.@allValues", \Query<ModernCollectionsOfEnums>.mapInt16Opt.values, EnumInt16.value1, notEqualCount: 1)
        validateNumericComparisons("ANY mapInt16Opt.@allValues", \Query<ModernCollectionsOfEnums>.mapInt16Opt.values, .value2, ltCount: 1)

        validateEquals("ANY mapInt32Opt.@allValues", \Query<ModernCollectionsOfEnums>.mapInt32Opt.values, EnumInt32.value1, notEqualCount: 1)
        validateNumericComparisons("ANY mapInt32Opt.@allValues", \Query<ModernCollectionsOfEnums>.mapInt32Opt.values, .value2, ltCount: 1)

        validateEquals("ANY mapInt64Opt.@allValues", \Query<ModernCollectionsOfEnums>.mapInt64Opt.values, EnumInt64.value1, notEqualCount: 1)
        validateNumericComparisons("ANY mapInt64Opt.@allValues", \Query<ModernCollectionsOfEnums>.mapInt64Opt.values, .value2, ltCount: 1)

        validateEquals("ANY mapFloatOpt.@allValues", \Query<ModernCollectionsOfEnums>.mapFloatOpt.values, EnumFloat.value1, notEqualCount: 1)
        validateNumericComparisons("ANY mapFloatOpt.@allValues", \Query<ModernCollectionsOfEnums>.mapFloatOpt.values, .value2, ltCount: 1)

        validateEquals("ANY mapDoubleOpt.@allValues", \Query<ModernCollectionsOfEnums>.mapDoubleOpt.values, EnumDouble.value1, notEqualCount: 1)
        validateNumericComparisons("ANY mapDoubleOpt.@allValues", \Query<ModernCollectionsOfEnums>.mapDoubleOpt.values, .value2, ltCount: 1)

        validateEquals("ANY mapStringOpt.@allValues", \Query<ModernCollectionsOfEnums>.mapStringOpt.values, EnumString.value1, notEqualCount: 1)
        validateStringOperations("ANY mapStringOpt.@allValues", \Query<ModernCollectionsOfEnums>.mapStringOpt.values,
                                 (.value1, .value1, .value1)) { equals, options in
            return 1
        }

        assertQuery(ModernCollectionsOfEnums.self, "(ANY mapStringOpt.@allValues LIKE[c] %@)", EnumString.value1, count: 1) {
            $0.mapStringOpt.values.like(.value1, caseInsensitive: true)
        }
        assertQuery(ModernCollectionsOfEnums.self, "(ANY mapStringOpt.@allValues LIKE %@)", EnumString.value1, count: 1) {
            $0.mapStringOpt.values.like(.value1)
        }

        validateEquals("ANY mapOptBool.@allValues", \Query<CustomPersistableCollections>.mapOptBool.values, BoolWrapper(persistedValue: true))

        validateEquals("ANY mapOptInt.@allValues", \Query<CustomPersistableCollections>.mapOptInt.values, IntWrapper(persistedValue: 1), notEqualCount: 1)
        validateNumericComparisons("ANY mapOptInt.@allValues", \Query<CustomPersistableCollections>.mapOptInt.values, IntWrapper(persistedValue: 3), ltCount: 1)

        validateEquals("ANY mapOptInt8.@allValues", \Query<CustomPersistableCollections>.mapOptInt8.values, Int8Wrapper(persistedValue: Int8(8)), notEqualCount: 1)
        validateNumericComparisons("ANY mapOptInt8.@allValues", \Query<CustomPersistableCollections>.mapOptInt8.values, Int8Wrapper(persistedValue: Int8(9)), ltCount: 1)

        validateEquals("ANY mapOptInt16.@allValues", \Query<CustomPersistableCollections>.mapOptInt16.values, Int16Wrapper(persistedValue: Int16(16)), notEqualCount: 1)
        validateNumericComparisons("ANY mapOptInt16.@allValues", \Query<CustomPersistableCollections>.mapOptInt16.values, Int16Wrapper(persistedValue: Int16(17)), ltCount: 1)

        validateEquals("ANY mapOptInt32.@allValues", \Query<CustomPersistableCollections>.mapOptInt32.values, Int32Wrapper(persistedValue: Int32(32)), notEqualCount: 1)
        validateNumericComparisons("ANY mapOptInt32.@allValues", \Query<CustomPersistableCollections>.mapOptInt32.values, Int32Wrapper(persistedValue: Int32(33)), ltCount: 1)

        validateEquals("ANY mapOptInt64.@allValues", \Query<CustomPersistableCollections>.mapOptInt64.values, Int64Wrapper(persistedValue: Int64(64)), notEqualCount: 1)
        validateNumericComparisons("ANY mapOptInt64.@allValues", \Query<CustomPersistableCollections>.mapOptInt64.values, Int64Wrapper(persistedValue: Int64(65)), ltCount: 1)

        validateEquals("ANY mapOptFloat.@allValues", \Query<CustomPersistableCollections>.mapOptFloat.values, FloatWrapper(persistedValue: Float(5.55444333)), notEqualCount: 1)
        validateNumericComparisons("ANY mapOptFloat.@allValues", \Query<CustomPersistableCollections>.mapOptFloat.values, FloatWrapper(persistedValue: Float(6.55444333)), ltCount: 1)

        validateEquals("ANY mapOptDouble.@allValues", \Query<CustomPersistableCollections>.mapOptDouble.values, DoubleWrapper(persistedValue: 123.456), notEqualCount: 1)
        validateNumericComparisons("ANY mapOptDouble.@allValues", \Query<CustomPersistableCollections>.mapOptDouble.values, DoubleWrapper(persistedValue: 234.567), ltCount: 1)

        validateEquals("ANY mapOptString.@allValues", \Query<CustomPersistableCollections>.mapOptString.values, StringWrapper(persistedValue: "Foo"), notEqualCount: 1)
        validateStringOperations("ANY mapOptString.@allValues", \Query<CustomPersistableCollections>.mapOptString.values,
                                 (StringWrapper(persistedValue: "Foo"), StringWrapper(persistedValue: "Foo"), StringWrapper(persistedValue: "Foo"))) { equals, options in
            // Non-enum maps have the keys Foo and Foó, so !=[d] doesn't match any
            if options.contains(.diacriticInsensitive) {
                return equals ? 1 : 0
            }
            return 1
        }

        assertQuery(CustomPersistableCollections.self, "(ANY mapOptString.@allValues LIKE[c] %@)", StringWrapper(persistedValue: "Foo"), count: 1) {
            $0.mapOptString.values.like(StringWrapper(persistedValue: "Foo"), caseInsensitive: true)
        }
        assertQuery(CustomPersistableCollections.self, "(ANY mapOptString.@allValues LIKE %@)", StringWrapper(persistedValue: "Foo"), count: 1) {
            $0.mapOptString.values.like(StringWrapper(persistedValue: "Foo"))
        }

        validateEquals("ANY mapOptBinary.@allValues", \Query<CustomPersistableCollections>.mapOptBinary.values, DataWrapper(persistedValue: Data(count: 64)), notEqualCount: 1)

        validateEquals("ANY mapOptDate.@allValues", \Query<CustomPersistableCollections>.mapOptDate.values, DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)), notEqualCount: 1)
        validateNumericComparisons("ANY mapOptDate.@allValues", \Query<CustomPersistableCollections>.mapOptDate.values, DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)), ltCount: 1)

        validateEquals("ANY mapOptDecimal.@allValues", \Query<CustomPersistableCollections>.mapOptDecimal.values, Decimal128Wrapper(persistedValue: Decimal128(123.456)), notEqualCount: 1)
        validateNumericComparisons("ANY mapOptDecimal.@allValues", \Query<CustomPersistableCollections>.mapOptDecimal.values, Decimal128Wrapper(persistedValue: Decimal128(234.567)), ltCount: 1)

        validateEquals("ANY mapOptObjectId.@allValues", \Query<CustomPersistableCollections>.mapOptObjectId.values, ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695046")), notEqualCount: 1)

        validateEquals("ANY mapOptUuid.@allValues", \Query<CustomPersistableCollections>.mapOptUuid.values, UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!), notEqualCount: 1)

    }
    // swiftlint:enable unused_closure_parameter

    func testMapContainsObject() {
        let obj = objects().first!
        let colObj = collectionObject()
        let result = realm.objects(ModernCollectionObject.self).where {
            $0.map.contains(obj)
        }
        XCTAssertEqual(result.count, 0)
        try! realm.write {
            colObj.map["foo"] = obj
        }
        XCTAssertEqual(result.count, 1)
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
            where T.Value.PersistedType: _QueryNumeric, T.Key == String {
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
            where T.Value.PersistedType: _QueryString, T.Key == String {
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

        validateMapSubscriptEquality("mapInt", \Query<ModernAllTypesObject>.mapInt, value: 1)
        validateMapSubscriptNumericComparisons("mapInt", \Query<ModernAllTypesObject>.mapInt, value: 1)

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

        validateMapSubscriptEquality("mapBool", \Query<CustomPersistableCollections>.mapBool, value: BoolWrapper(persistedValue: true))

        validateMapSubscriptEquality("mapInt", \Query<CustomPersistableCollections>.mapInt, value: IntWrapper(persistedValue: 1))
        validateMapSubscriptNumericComparisons("mapInt", \Query<CustomPersistableCollections>.mapInt, value: IntWrapper(persistedValue: 1))

        validateMapSubscriptEquality("mapInt8", \Query<CustomPersistableCollections>.mapInt8, value: Int8Wrapper(persistedValue: Int8(8)))
        validateMapSubscriptNumericComparisons("mapInt8", \Query<CustomPersistableCollections>.mapInt8, value: Int8Wrapper(persistedValue: Int8(8)))

        validateMapSubscriptEquality("mapInt16", \Query<CustomPersistableCollections>.mapInt16, value: Int16Wrapper(persistedValue: Int16(16)))
        validateMapSubscriptNumericComparisons("mapInt16", \Query<CustomPersistableCollections>.mapInt16, value: Int16Wrapper(persistedValue: Int16(16)))

        validateMapSubscriptEquality("mapInt32", \Query<CustomPersistableCollections>.mapInt32, value: Int32Wrapper(persistedValue: Int32(32)))
        validateMapSubscriptNumericComparisons("mapInt32", \Query<CustomPersistableCollections>.mapInt32, value: Int32Wrapper(persistedValue: Int32(32)))

        validateMapSubscriptEquality("mapInt64", \Query<CustomPersistableCollections>.mapInt64, value: Int64Wrapper(persistedValue: Int64(64)))
        validateMapSubscriptNumericComparisons("mapInt64", \Query<CustomPersistableCollections>.mapInt64, value: Int64Wrapper(persistedValue: Int64(64)))

        validateMapSubscriptEquality("mapFloat", \Query<CustomPersistableCollections>.mapFloat, value: FloatWrapper(persistedValue: Float(5.55444333)))
        validateMapSubscriptNumericComparisons("mapFloat", \Query<CustomPersistableCollections>.mapFloat, value: FloatWrapper(persistedValue: Float(5.55444333)))

        validateMapSubscriptEquality("mapDouble", \Query<CustomPersistableCollections>.mapDouble, value: DoubleWrapper(persistedValue: 123.456))
        validateMapSubscriptNumericComparisons("mapDouble", \Query<CustomPersistableCollections>.mapDouble, value: DoubleWrapper(persistedValue: 123.456))

        validateMapSubscriptEquality("mapString", \Query<CustomPersistableCollections>.mapString, value: StringWrapper(persistedValue: "Foo"))
        validateMapSubscriptStringComparisons("mapString", \Query<CustomPersistableCollections>.mapString, value: StringWrapper(persistedValue: "Foo"))

        validateMapSubscriptEquality("mapBinary", \Query<CustomPersistableCollections>.mapBinary, value: DataWrapper(persistedValue: Data(count: 64)))

        validateMapSubscriptEquality("mapDate", \Query<CustomPersistableCollections>.mapDate, value: DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)))
        validateMapSubscriptNumericComparisons("mapDate", \Query<CustomPersistableCollections>.mapDate, value: DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)))

        validateMapSubscriptEquality("mapDecimal", \Query<CustomPersistableCollections>.mapDecimal, value: Decimal128Wrapper(persistedValue: Decimal128(123.456)))
        validateMapSubscriptNumericComparisons("mapDecimal", \Query<CustomPersistableCollections>.mapDecimal, value: Decimal128Wrapper(persistedValue: Decimal128(123.456)))

        validateMapSubscriptEquality("mapObjectId", \Query<CustomPersistableCollections>.mapObjectId, value: ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695046")))

        validateMapSubscriptEquality("mapUuid", \Query<CustomPersistableCollections>.mapUuid, value: UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!))

        validateMapSubscriptEquality("mapOptBool", \Query<ModernAllTypesObject>.mapOptBool, value: true)

        validateMapSubscriptEquality("mapOptInt", \Query<ModernAllTypesObject>.mapOptInt, value: 1)
        validateMapSubscriptNumericComparisons("mapOptInt", \Query<ModernAllTypesObject>.mapOptInt, value: 1)

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

        validateMapSubscriptEquality("mapOptBool", \Query<CustomPersistableCollections>.mapOptBool, value: BoolWrapper(persistedValue: true))

        validateMapSubscriptEquality("mapOptInt", \Query<CustomPersistableCollections>.mapOptInt, value: IntWrapper(persistedValue: 1))
        validateMapSubscriptNumericComparisons("mapOptInt", \Query<CustomPersistableCollections>.mapOptInt, value: IntWrapper(persistedValue: 1))

        validateMapSubscriptEquality("mapOptInt8", \Query<CustomPersistableCollections>.mapOptInt8, value: Int8Wrapper(persistedValue: Int8(8)))
        validateMapSubscriptNumericComparisons("mapOptInt8", \Query<CustomPersistableCollections>.mapOptInt8, value: Int8Wrapper(persistedValue: Int8(8)))

        validateMapSubscriptEquality("mapOptInt16", \Query<CustomPersistableCollections>.mapOptInt16, value: Int16Wrapper(persistedValue: Int16(16)))
        validateMapSubscriptNumericComparisons("mapOptInt16", \Query<CustomPersistableCollections>.mapOptInt16, value: Int16Wrapper(persistedValue: Int16(16)))

        validateMapSubscriptEquality("mapOptInt32", \Query<CustomPersistableCollections>.mapOptInt32, value: Int32Wrapper(persistedValue: Int32(32)))
        validateMapSubscriptNumericComparisons("mapOptInt32", \Query<CustomPersistableCollections>.mapOptInt32, value: Int32Wrapper(persistedValue: Int32(32)))

        validateMapSubscriptEquality("mapOptInt64", \Query<CustomPersistableCollections>.mapOptInt64, value: Int64Wrapper(persistedValue: Int64(64)))
        validateMapSubscriptNumericComparisons("mapOptInt64", \Query<CustomPersistableCollections>.mapOptInt64, value: Int64Wrapper(persistedValue: Int64(64)))

        validateMapSubscriptEquality("mapOptFloat", \Query<CustomPersistableCollections>.mapOptFloat, value: FloatWrapper(persistedValue: Float(5.55444333)))
        validateMapSubscriptNumericComparisons("mapOptFloat", \Query<CustomPersistableCollections>.mapOptFloat, value: FloatWrapper(persistedValue: Float(5.55444333)))

        validateMapSubscriptEquality("mapOptDouble", \Query<CustomPersistableCollections>.mapOptDouble, value: DoubleWrapper(persistedValue: 123.456))
        validateMapSubscriptNumericComparisons("mapOptDouble", \Query<CustomPersistableCollections>.mapOptDouble, value: DoubleWrapper(persistedValue: 123.456))

        validateMapSubscriptEquality("mapOptString", \Query<CustomPersistableCollections>.mapOptString, value: StringWrapper(persistedValue: "Foo"))
        validateMapSubscriptStringComparisons("mapOptString", \Query<CustomPersistableCollections>.mapOptString, value: StringWrapper(persistedValue: "Foo"))

        validateMapSubscriptEquality("mapOptBinary", \Query<CustomPersistableCollections>.mapOptBinary, value: DataWrapper(persistedValue: Data(count: 64)))

        validateMapSubscriptEquality("mapOptDate", \Query<CustomPersistableCollections>.mapOptDate, value: DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)))
        validateMapSubscriptNumericComparisons("mapOptDate", \Query<CustomPersistableCollections>.mapOptDate, value: DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)))

        validateMapSubscriptEquality("mapOptDecimal", \Query<CustomPersistableCollections>.mapOptDecimal, value: Decimal128Wrapper(persistedValue: Decimal128(123.456)))
        validateMapSubscriptNumericComparisons("mapOptDecimal", \Query<CustomPersistableCollections>.mapOptDecimal, value: Decimal128Wrapper(persistedValue: Decimal128(123.456)))

        validateMapSubscriptEquality("mapOptObjectId", \Query<CustomPersistableCollections>.mapOptObjectId, value: ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695046")))

        validateMapSubscriptEquality("mapOptUuid", \Query<CustomPersistableCollections>.mapOptUuid, value: UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!))

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
                    values: [NSArray(array: [1, 3])], count: 1) {
            $0.mapInt.containsAny(in: [1, 3])
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
        assertQuery(CustomPersistableCollections.self, "(ANY mapBool IN %@)",
                    values: [NSArray(array: [BoolWrapper(persistedValue: true), BoolWrapper(persistedValue: true)])], count: 1) {
            $0.mapBool.containsAny(in: [BoolWrapper(persistedValue: true), BoolWrapper(persistedValue: true)])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY mapInt IN %@)",
                    values: [NSArray(array: [IntWrapper(persistedValue: 1), IntWrapper(persistedValue: 3)])], count: 1) {
            $0.mapInt.containsAny(in: [IntWrapper(persistedValue: 1), IntWrapper(persistedValue: 3)])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY mapInt8 IN %@)",
                    values: [NSArray(array: [Int8Wrapper(persistedValue: Int8(8)), Int8Wrapper(persistedValue: Int8(9))])], count: 1) {
            $0.mapInt8.containsAny(in: [Int8Wrapper(persistedValue: Int8(8)), Int8Wrapper(persistedValue: Int8(9))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY mapInt16 IN %@)",
                    values: [NSArray(array: [Int16Wrapper(persistedValue: Int16(16)), Int16Wrapper(persistedValue: Int16(17))])], count: 1) {
            $0.mapInt16.containsAny(in: [Int16Wrapper(persistedValue: Int16(16)), Int16Wrapper(persistedValue: Int16(17))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY mapInt32 IN %@)",
                    values: [NSArray(array: [Int32Wrapper(persistedValue: Int32(32)), Int32Wrapper(persistedValue: Int32(33))])], count: 1) {
            $0.mapInt32.containsAny(in: [Int32Wrapper(persistedValue: Int32(32)), Int32Wrapper(persistedValue: Int32(33))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY mapInt64 IN %@)",
                    values: [NSArray(array: [Int64Wrapper(persistedValue: Int64(64)), Int64Wrapper(persistedValue: Int64(65))])], count: 1) {
            $0.mapInt64.containsAny(in: [Int64Wrapper(persistedValue: Int64(64)), Int64Wrapper(persistedValue: Int64(65))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY mapFloat IN %@)",
                    values: [NSArray(array: [FloatWrapper(persistedValue: Float(5.55444333)), FloatWrapper(persistedValue: Float(6.55444333))])], count: 1) {
            $0.mapFloat.containsAny(in: [FloatWrapper(persistedValue: Float(5.55444333)), FloatWrapper(persistedValue: Float(6.55444333))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY mapDouble IN %@)",
                    values: [NSArray(array: [DoubleWrapper(persistedValue: 123.456), DoubleWrapper(persistedValue: 234.567)])], count: 1) {
            $0.mapDouble.containsAny(in: [DoubleWrapper(persistedValue: 123.456), DoubleWrapper(persistedValue: 234.567)])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY mapString IN %@)",
                    values: [NSArray(array: [StringWrapper(persistedValue: "Foo"), StringWrapper(persistedValue: "Foó")])], count: 1) {
            $0.mapString.containsAny(in: [StringWrapper(persistedValue: "Foo"), StringWrapper(persistedValue: "Foó")])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY mapBinary IN %@)",
                    values: [NSArray(array: [DataWrapper(persistedValue: Data(count: 64)), DataWrapper(persistedValue: Data(count: 128))])], count: 1) {
            $0.mapBinary.containsAny(in: [DataWrapper(persistedValue: Data(count: 64)), DataWrapper(persistedValue: Data(count: 128))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY mapDate IN %@)",
                    values: [NSArray(array: [DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)), DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000))])], count: 1) {
            $0.mapDate.containsAny(in: [DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)), DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY mapDecimal IN %@)",
                    values: [NSArray(array: [Decimal128Wrapper(persistedValue: Decimal128(123.456)), Decimal128Wrapper(persistedValue: Decimal128(234.567))])], count: 1) {
            $0.mapDecimal.containsAny(in: [Decimal128Wrapper(persistedValue: Decimal128(123.456)), Decimal128Wrapper(persistedValue: Decimal128(234.567))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY mapObjectId IN %@)",
                    values: [NSArray(array: [ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695046")), ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045"))])], count: 1) {
            $0.mapObjectId.containsAny(in: [ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695046")), ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045"))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY mapUuid IN %@)",
                    values: [NSArray(array: [UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!), UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)])], count: 1) {
            $0.mapUuid.containsAny(in: [UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!), UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY mapOptBool IN %@)",
                    values: [NSArray(array: [true, true])], count: 1) {
            $0.mapOptBool.containsAny(in: [true, true])
        }
        assertQuery(ModernAllTypesObject.self, "(ANY mapOptInt IN %@)",
                    values: [NSArray(array: [1, 3])], count: 1) {
            $0.mapOptInt.containsAny(in: [1, 3])
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
        assertQuery(CustomPersistableCollections.self, "(ANY mapOptBool IN %@)",
                    values: [NSArray(array: [BoolWrapper(persistedValue: true), BoolWrapper(persistedValue: true)])], count: 1) {
            $0.mapOptBool.containsAny(in: [BoolWrapper(persistedValue: true), BoolWrapper(persistedValue: true)])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY mapOptInt IN %@)",
                    values: [NSArray(array: [IntWrapper(persistedValue: 1), IntWrapper(persistedValue: 3)])], count: 1) {
            $0.mapOptInt.containsAny(in: [IntWrapper(persistedValue: 1), IntWrapper(persistedValue: 3)])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY mapOptInt8 IN %@)",
                    values: [NSArray(array: [Int8Wrapper(persistedValue: Int8(8)), Int8Wrapper(persistedValue: Int8(9))])], count: 1) {
            $0.mapOptInt8.containsAny(in: [Int8Wrapper(persistedValue: Int8(8)), Int8Wrapper(persistedValue: Int8(9))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY mapOptInt16 IN %@)",
                    values: [NSArray(array: [Int16Wrapper(persistedValue: Int16(16)), Int16Wrapper(persistedValue: Int16(17))])], count: 1) {
            $0.mapOptInt16.containsAny(in: [Int16Wrapper(persistedValue: Int16(16)), Int16Wrapper(persistedValue: Int16(17))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY mapOptInt32 IN %@)",
                    values: [NSArray(array: [Int32Wrapper(persistedValue: Int32(32)), Int32Wrapper(persistedValue: Int32(33))])], count: 1) {
            $0.mapOptInt32.containsAny(in: [Int32Wrapper(persistedValue: Int32(32)), Int32Wrapper(persistedValue: Int32(33))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY mapOptInt64 IN %@)",
                    values: [NSArray(array: [Int64Wrapper(persistedValue: Int64(64)), Int64Wrapper(persistedValue: Int64(65))])], count: 1) {
            $0.mapOptInt64.containsAny(in: [Int64Wrapper(persistedValue: Int64(64)), Int64Wrapper(persistedValue: Int64(65))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY mapOptFloat IN %@)",
                    values: [NSArray(array: [FloatWrapper(persistedValue: Float(5.55444333)), FloatWrapper(persistedValue: Float(6.55444333))])], count: 1) {
            $0.mapOptFloat.containsAny(in: [FloatWrapper(persistedValue: Float(5.55444333)), FloatWrapper(persistedValue: Float(6.55444333))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY mapOptDouble IN %@)",
                    values: [NSArray(array: [DoubleWrapper(persistedValue: 123.456), DoubleWrapper(persistedValue: 234.567)])], count: 1) {
            $0.mapOptDouble.containsAny(in: [DoubleWrapper(persistedValue: 123.456), DoubleWrapper(persistedValue: 234.567)])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY mapOptString IN %@)",
                    values: [NSArray(array: [StringWrapper(persistedValue: "Foo"), StringWrapper(persistedValue: "Foó")])], count: 1) {
            $0.mapOptString.containsAny(in: [StringWrapper(persistedValue: "Foo"), StringWrapper(persistedValue: "Foó")])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY mapOptBinary IN %@)",
                    values: [NSArray(array: [DataWrapper(persistedValue: Data(count: 64)), DataWrapper(persistedValue: Data(count: 128))])], count: 1) {
            $0.mapOptBinary.containsAny(in: [DataWrapper(persistedValue: Data(count: 64)), DataWrapper(persistedValue: Data(count: 128))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY mapOptDate IN %@)",
                    values: [NSArray(array: [DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)), DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000))])], count: 1) {
            $0.mapOptDate.containsAny(in: [DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)), DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY mapOptDecimal IN %@)",
                    values: [NSArray(array: [Decimal128Wrapper(persistedValue: Decimal128(123.456)), Decimal128Wrapper(persistedValue: Decimal128(234.567))])], count: 1) {
            $0.mapOptDecimal.containsAny(in: [Decimal128Wrapper(persistedValue: Decimal128(123.456)), Decimal128Wrapper(persistedValue: Decimal128(234.567))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY mapOptObjectId IN %@)",
                    values: [NSArray(array: [ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695046")), ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045"))])], count: 1) {
            $0.mapOptObjectId.containsAny(in: [ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695046")), ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045"))])
        }
        assertQuery(CustomPersistableCollections.self, "(ANY mapOptUuid IN %@)",
                    values: [NSArray(array: [UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!), UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)])], count: 1) {
            $0.mapOptUuid.containsAny(in: [UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!), UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)])
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

        let sumarrayInt = 1 + 3
        assertQuery("((((((arrayInt.@min <= %@) && (arrayInt.@max >= %@)) && (arrayInt.@sum == %@)) && (arrayInt.@count != %@)) && (arrayInt.@avg > %@)) && (arrayInt.@avg < %@))",
                    values: [1, 3, sumarrayInt, 0, 1, 3], count: 1) {
            ($0.arrayInt.min <= 1) &&
            ($0.arrayInt.max >= 3) &&
            ($0.arrayInt.sum == sumarrayInt) &&
            ($0.arrayInt.count != 0) &&
            ($0.arrayInt.avg > 1) &&
            ($0.arrayInt.avg < 3)
        }
        let sumarrayOptInt = 1 + 3
        assertQuery("((((((arrayOptInt.@min <= %@) && (arrayOptInt.@max >= %@)) && (arrayOptInt.@sum == %@)) && (arrayOptInt.@count != %@)) && (arrayOptInt.@avg > %@)) && (arrayOptInt.@avg < %@))",
                    values: [1, 3, sumarrayOptInt, 0, 1, 3], count: 1) {
            ($0.arrayOptInt.min <= 1) &&
            ($0.arrayOptInt.max >= 3) &&
            ($0.arrayOptInt.sum == sumarrayOptInt) &&
            ($0.arrayOptInt.count != 0) &&
            ($0.arrayOptInt.avg > 1) &&
            ($0.arrayOptInt.avg < 3)
        }
        let summapInt = 1 + 3
        assertQuery("((((((mapInt.@min <= %@) && (mapInt.@max >= %@)) && (mapInt.@sum == %@)) && (mapInt.@count != %@)) && (mapInt.@avg > %@)) && (mapInt.@avg < %@))",
                    values: [1, 3, summapInt, 0, 1, 3], count: 1) {
            ($0.mapInt.min <= 1) &&
            ($0.mapInt.max >= 3) &&
            ($0.mapInt.sum == summapInt) &&
            ($0.mapInt.count != 0) &&
            ($0.mapInt.avg > 1) &&
            ($0.mapInt.avg < 3)
        }
        let summapOptInt = 1 + 3
        assertQuery("((((((mapOptInt.@min <= %@) && (mapOptInt.@max >= %@)) && (mapOptInt.@sum == %@)) && (mapOptInt.@count != %@)) && (mapOptInt.@avg > %@)) && (mapOptInt.@avg < %@))",
                    values: [1, 3, summapOptInt, 0, 1, 3], count: 1) {
            ($0.mapOptInt.min <= 1) &&
            ($0.mapOptInt.max >= 3) &&
            ($0.mapOptInt.sum == summapOptInt) &&
            ($0.mapOptInt.count != 0) &&
            ($0.mapOptInt.avg > 1) &&
            ($0.mapOptInt.avg < 3)
        }

        // Keypath Collection Aggregates

        createKeypathCollectionAggregatesObject()

        let sumdoubleCol = 123.456 + 234.567 + 345.678
        assertQuery(LinkToModernAllTypesObject.self, "((((((list.@min.doubleCol <= %@) && (list.@max.doubleCol >= %@)) && (list.@sum.doubleCol == %@)) && (list.@min.doubleCol != %@)) && (list.@avg.doubleCol > %@)) && (list.@avg.doubleCol < %@))",
                    values: [123.456, 345.678, sumdoubleCol, 234.567, 123.456, 345.678], count: 1) {
            $0.list.doubleCol.min <= 123.456 &&
            $0.list.doubleCol.max >= 345.678 &&
            $0.list.doubleCol.sum == sumdoubleCol &&
            $0.list.doubleCol.min != 234.567 &&
            $0.list.doubleCol.avg > 123.456 &&
            $0.list.doubleCol.avg < 345.678
        }

        let sumoptDoubleCol = 123.456 + 234.567 + 345.678
        assertQuery(LinkToModernAllTypesObject.self, "((((((list.@min.optDoubleCol <= %@) && (list.@max.optDoubleCol >= %@)) && (list.@sum.optDoubleCol == %@)) && (list.@min.optDoubleCol != %@)) && (list.@avg.optDoubleCol > %@)) && (list.@avg.optDoubleCol < %@))",
                    values: [123.456, 345.678, sumoptDoubleCol, 234.567, 123.456, 345.678], count: 1) {
            $0.list.optDoubleCol.min <= 123.456 &&
            $0.list.optDoubleCol.max >= 345.678 &&
            $0.list.optDoubleCol.sum == sumoptDoubleCol &&
            $0.list.optDoubleCol.min != 234.567 &&
            $0.list.optDoubleCol.avg > 123.456 &&
            $0.list.optDoubleCol.avg < 345.678
        }
    }

    func testCompoundOr() {
        assertQuery(ModernAllTypesObject.self, "((boolCol == %@) || (intCol == %@))", values: [false, 3], count: 1) {
            $0.boolCol == false || $0.intCol == 3
        }
        assertQuery(ModernAllTypesObject.self, "((boolCol == %@) || (intCol == %@))", values: [false, 3], count: 1) {
            ($0.boolCol == false) || ($0.intCol == 3)
        }
        assertQuery(ModernAllTypesObject.self, "((intCol == %@) || (int8Col == %@))", values: [3, Int8(9)], count: 1) {
            $0.intCol == 3 || $0.int8Col == Int8(9)
        }
        assertQuery(ModernAllTypesObject.self, "((intCol == %@) || (int8Col == %@))", values: [3, Int8(9)], count: 1) {
            ($0.intCol == 3) || ($0.int8Col == Int8(9))
        }
        assertQuery(ModernAllTypesObject.self, "((int8Col == %@) || (int16Col == %@))", values: [Int8(9), Int16(17)], count: 1) {
            $0.int8Col == Int8(9) || $0.int16Col == Int16(17)
        }
        assertQuery(ModernAllTypesObject.self, "((int8Col == %@) || (int16Col == %@))", values: [Int8(9), Int16(17)], count: 1) {
            ($0.int8Col == Int8(9)) || ($0.int16Col == Int16(17))
        }
        assertQuery(ModernAllTypesObject.self, "((int16Col == %@) || (int32Col == %@))", values: [Int16(17), Int32(33)], count: 1) {
            $0.int16Col == Int16(17) || $0.int32Col == Int32(33)
        }
        assertQuery(ModernAllTypesObject.self, "((int16Col == %@) || (int32Col == %@))", values: [Int16(17), Int32(33)], count: 1) {
            ($0.int16Col == Int16(17)) || ($0.int32Col == Int32(33))
        }
        assertQuery(ModernAllTypesObject.self, "((int32Col == %@) || (int64Col == %@))", values: [Int32(33), Int64(65)], count: 1) {
            $0.int32Col == Int32(33) || $0.int64Col == Int64(65)
        }
        assertQuery(ModernAllTypesObject.self, "((int32Col == %@) || (int64Col == %@))", values: [Int32(33), Int64(65)], count: 1) {
            ($0.int32Col == Int32(33)) || ($0.int64Col == Int64(65))
        }
        assertQuery(ModernAllTypesObject.self, "((int64Col == %@) || (floatCol == %@))", values: [Int64(65), Float(6.55444333)], count: 1) {
            $0.int64Col == Int64(65) || $0.floatCol == Float(6.55444333)
        }
        assertQuery(ModernAllTypesObject.self, "((int64Col == %@) || (floatCol == %@))", values: [Int64(65), Float(6.55444333)], count: 1) {
            ($0.int64Col == Int64(65)) || ($0.floatCol == Float(6.55444333))
        }
        assertQuery(ModernAllTypesObject.self, "((floatCol == %@) || (doubleCol == %@))", values: [Float(6.55444333), 234.567], count: 1) {
            $0.floatCol == Float(6.55444333) || $0.doubleCol == 234.567
        }
        assertQuery(ModernAllTypesObject.self, "((floatCol == %@) || (doubleCol == %@))", values: [Float(6.55444333), 234.567], count: 1) {
            ($0.floatCol == Float(6.55444333)) || ($0.doubleCol == 234.567)
        }
        assertQuery(ModernAllTypesObject.self, "((doubleCol == %@) || (stringCol == %@))", values: [234.567, "Foó"], count: 1) {
            $0.doubleCol == 234.567 || $0.stringCol == "Foó"
        }
        assertQuery(ModernAllTypesObject.self, "((doubleCol == %@) || (stringCol == %@))", values: [234.567, "Foó"], count: 1) {
            ($0.doubleCol == 234.567) || ($0.stringCol == "Foó")
        }
        assertQuery(ModernAllTypesObject.self, "((stringCol == %@) || (binaryCol == %@))", values: ["Foó", Data(count: 128)], count: 1) {
            $0.stringCol == "Foó" || $0.binaryCol == Data(count: 128)
        }
        assertQuery(ModernAllTypesObject.self, "((stringCol == %@) || (binaryCol == %@))", values: ["Foó", Data(count: 128)], count: 1) {
            ($0.stringCol == "Foó") || ($0.binaryCol == Data(count: 128))
        }
        assertQuery(ModernAllTypesObject.self, "((binaryCol == %@) || (dateCol == %@))", values: [Data(count: 128), Date(timeIntervalSince1970: 2000000)], count: 1) {
            $0.binaryCol == Data(count: 128) || $0.dateCol == Date(timeIntervalSince1970: 2000000)
        }
        assertQuery(ModernAllTypesObject.self, "((binaryCol == %@) || (dateCol == %@))", values: [Data(count: 128), Date(timeIntervalSince1970: 2000000)], count: 1) {
            ($0.binaryCol == Data(count: 128)) || ($0.dateCol == Date(timeIntervalSince1970: 2000000))
        }
        assertQuery(ModernAllTypesObject.self, "((dateCol == %@) || (decimalCol == %@))", values: [Date(timeIntervalSince1970: 2000000), Decimal128(234.567)], count: 1) {
            $0.dateCol == Date(timeIntervalSince1970: 2000000) || $0.decimalCol == Decimal128(234.567)
        }
        assertQuery(ModernAllTypesObject.self, "((dateCol == %@) || (decimalCol == %@))", values: [Date(timeIntervalSince1970: 2000000), Decimal128(234.567)], count: 1) {
            ($0.dateCol == Date(timeIntervalSince1970: 2000000)) || ($0.decimalCol == Decimal128(234.567))
        }
        assertQuery(ModernAllTypesObject.self, "((decimalCol == %@) || (objectIdCol == %@))", values: [Decimal128(234.567), ObjectId("61184062c1d8f096a3695045")], count: 1) {
            $0.decimalCol == Decimal128(234.567) || $0.objectIdCol == ObjectId("61184062c1d8f096a3695045")
        }
        assertQuery(ModernAllTypesObject.self, "((decimalCol == %@) || (objectIdCol == %@))", values: [Decimal128(234.567), ObjectId("61184062c1d8f096a3695045")], count: 1) {
            ($0.decimalCol == Decimal128(234.567)) || ($0.objectIdCol == ObjectId("61184062c1d8f096a3695045"))
        }
        assertQuery(ModernAllTypesObject.self, "((objectIdCol == %@) || (uuidCol == %@))", values: [ObjectId("61184062c1d8f096a3695045"), UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!], count: 1) {
            $0.objectIdCol == ObjectId("61184062c1d8f096a3695045") || $0.uuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!
        }
        assertQuery(ModernAllTypesObject.self, "((objectIdCol == %@) || (uuidCol == %@))", values: [ObjectId("61184062c1d8f096a3695045"), UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!], count: 1) {
            ($0.objectIdCol == ObjectId("61184062c1d8f096a3695045")) || ($0.uuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)
        }
        assertQuery(ModernAllTypesObject.self, "((uuidCol == %@) || (intEnumCol == %@))", values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!, ModernIntEnum.value2], count: 1) {
            $0.uuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")! || $0.intEnumCol == .value2
        }
        assertQuery(ModernAllTypesObject.self, "((uuidCol == %@) || (intEnumCol == %@))", values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!, ModernIntEnum.value2], count: 1) {
            ($0.uuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!) || ($0.intEnumCol == .value2)
        }
        assertQuery(ModernAllTypesObject.self, "((intEnumCol == %@) || (stringEnumCol == %@))", values: [ModernIntEnum.value2, ModernStringEnum.value2], count: 1) {
            $0.intEnumCol == .value2 || $0.stringEnumCol == .value2
        }
        assertQuery(ModernAllTypesObject.self, "((intEnumCol == %@) || (stringEnumCol == %@))", values: [ModernIntEnum.value2, ModernStringEnum.value2], count: 1) {
            ($0.intEnumCol == .value2) || ($0.stringEnumCol == .value2)
        }
        assertQuery(AllCustomPersistableTypes.self, "((bool == %@) || (int == %@))", values: [BoolWrapper(persistedValue: false), IntWrapper(persistedValue: 3)], count: 1) {
            $0.bool == BoolWrapper(persistedValue: false) || $0.int == IntWrapper(persistedValue: 3)
        }
        assertQuery(AllCustomPersistableTypes.self, "((bool == %@) || (int == %@))", values: [BoolWrapper(persistedValue: false), IntWrapper(persistedValue: 3)], count: 1) {
            ($0.bool == BoolWrapper(persistedValue: false)) || ($0.int == IntWrapper(persistedValue: 3))
        }
        assertQuery(AllCustomPersistableTypes.self, "((int == %@) || (int8 == %@))", values: [IntWrapper(persistedValue: 3), Int8Wrapper(persistedValue: Int8(9))], count: 1) {
            $0.int == IntWrapper(persistedValue: 3) || $0.int8 == Int8Wrapper(persistedValue: Int8(9))
        }
        assertQuery(AllCustomPersistableTypes.self, "((int == %@) || (int8 == %@))", values: [IntWrapper(persistedValue: 3), Int8Wrapper(persistedValue: Int8(9))], count: 1) {
            ($0.int == IntWrapper(persistedValue: 3)) || ($0.int8 == Int8Wrapper(persistedValue: Int8(9)))
        }
        assertQuery(AllCustomPersistableTypes.self, "((int8 == %@) || (int16 == %@))", values: [Int8Wrapper(persistedValue: Int8(9)), Int16Wrapper(persistedValue: Int16(17))], count: 1) {
            $0.int8 == Int8Wrapper(persistedValue: Int8(9)) || $0.int16 == Int16Wrapper(persistedValue: Int16(17))
        }
        assertQuery(AllCustomPersistableTypes.self, "((int8 == %@) || (int16 == %@))", values: [Int8Wrapper(persistedValue: Int8(9)), Int16Wrapper(persistedValue: Int16(17))], count: 1) {
            ($0.int8 == Int8Wrapper(persistedValue: Int8(9))) || ($0.int16 == Int16Wrapper(persistedValue: Int16(17)))
        }
        assertQuery(AllCustomPersistableTypes.self, "((int16 == %@) || (int32 == %@))", values: [Int16Wrapper(persistedValue: Int16(17)), Int32Wrapper(persistedValue: Int32(33))], count: 1) {
            $0.int16 == Int16Wrapper(persistedValue: Int16(17)) || $0.int32 == Int32Wrapper(persistedValue: Int32(33))
        }
        assertQuery(AllCustomPersistableTypes.self, "((int16 == %@) || (int32 == %@))", values: [Int16Wrapper(persistedValue: Int16(17)), Int32Wrapper(persistedValue: Int32(33))], count: 1) {
            ($0.int16 == Int16Wrapper(persistedValue: Int16(17))) || ($0.int32 == Int32Wrapper(persistedValue: Int32(33)))
        }
        assertQuery(AllCustomPersistableTypes.self, "((int32 == %@) || (int64 == %@))", values: [Int32Wrapper(persistedValue: Int32(33)), Int64Wrapper(persistedValue: Int64(65))], count: 1) {
            $0.int32 == Int32Wrapper(persistedValue: Int32(33)) || $0.int64 == Int64Wrapper(persistedValue: Int64(65))
        }
        assertQuery(AllCustomPersistableTypes.self, "((int32 == %@) || (int64 == %@))", values: [Int32Wrapper(persistedValue: Int32(33)), Int64Wrapper(persistedValue: Int64(65))], count: 1) {
            ($0.int32 == Int32Wrapper(persistedValue: Int32(33))) || ($0.int64 == Int64Wrapper(persistedValue: Int64(65)))
        }
        assertQuery(AllCustomPersistableTypes.self, "((int64 == %@) || (float == %@))", values: [Int64Wrapper(persistedValue: Int64(65)), FloatWrapper(persistedValue: Float(6.55444333))], count: 1) {
            $0.int64 == Int64Wrapper(persistedValue: Int64(65)) || $0.float == FloatWrapper(persistedValue: Float(6.55444333))
        }
        assertQuery(AllCustomPersistableTypes.self, "((int64 == %@) || (float == %@))", values: [Int64Wrapper(persistedValue: Int64(65)), FloatWrapper(persistedValue: Float(6.55444333))], count: 1) {
            ($0.int64 == Int64Wrapper(persistedValue: Int64(65))) || ($0.float == FloatWrapper(persistedValue: Float(6.55444333)))
        }
        assertQuery(AllCustomPersistableTypes.self, "((float == %@) || (double == %@))", values: [FloatWrapper(persistedValue: Float(6.55444333)), DoubleWrapper(persistedValue: 234.567)], count: 1) {
            $0.float == FloatWrapper(persistedValue: Float(6.55444333)) || $0.double == DoubleWrapper(persistedValue: 234.567)
        }
        assertQuery(AllCustomPersistableTypes.self, "((float == %@) || (double == %@))", values: [FloatWrapper(persistedValue: Float(6.55444333)), DoubleWrapper(persistedValue: 234.567)], count: 1) {
            ($0.float == FloatWrapper(persistedValue: Float(6.55444333))) || ($0.double == DoubleWrapper(persistedValue: 234.567))
        }
        assertQuery(AllCustomPersistableTypes.self, "((double == %@) || (string == %@))", values: [DoubleWrapper(persistedValue: 234.567), StringWrapper(persistedValue: "Foó")], count: 1) {
            $0.double == DoubleWrapper(persistedValue: 234.567) || $0.string == StringWrapper(persistedValue: "Foó")
        }
        assertQuery(AllCustomPersistableTypes.self, "((double == %@) || (string == %@))", values: [DoubleWrapper(persistedValue: 234.567), StringWrapper(persistedValue: "Foó")], count: 1) {
            ($0.double == DoubleWrapper(persistedValue: 234.567)) || ($0.string == StringWrapper(persistedValue: "Foó"))
        }
        assertQuery(AllCustomPersistableTypes.self, "((string == %@) || (binary == %@))", values: [StringWrapper(persistedValue: "Foó"), DataWrapper(persistedValue: Data(count: 128))], count: 1) {
            $0.string == StringWrapper(persistedValue: "Foó") || $0.binary == DataWrapper(persistedValue: Data(count: 128))
        }
        assertQuery(AllCustomPersistableTypes.self, "((string == %@) || (binary == %@))", values: [StringWrapper(persistedValue: "Foó"), DataWrapper(persistedValue: Data(count: 128))], count: 1) {
            ($0.string == StringWrapper(persistedValue: "Foó")) || ($0.binary == DataWrapper(persistedValue: Data(count: 128)))
        }
        assertQuery(AllCustomPersistableTypes.self, "((binary == %@) || (date == %@))", values: [DataWrapper(persistedValue: Data(count: 128)), DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000))], count: 1) {
            $0.binary == DataWrapper(persistedValue: Data(count: 128)) || $0.date == DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000))
        }
        assertQuery(AllCustomPersistableTypes.self, "((binary == %@) || (date == %@))", values: [DataWrapper(persistedValue: Data(count: 128)), DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000))], count: 1) {
            ($0.binary == DataWrapper(persistedValue: Data(count: 128))) || ($0.date == DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)))
        }
        assertQuery(AllCustomPersistableTypes.self, "((date == %@) || (decimal == %@))", values: [DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)), Decimal128Wrapper(persistedValue: Decimal128(234.567))], count: 1) {
            $0.date == DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)) || $0.decimal == Decimal128Wrapper(persistedValue: Decimal128(234.567))
        }
        assertQuery(AllCustomPersistableTypes.self, "((date == %@) || (decimal == %@))", values: [DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)), Decimal128Wrapper(persistedValue: Decimal128(234.567))], count: 1) {
            ($0.date == DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000))) || ($0.decimal == Decimal128Wrapper(persistedValue: Decimal128(234.567)))
        }
        assertQuery(AllCustomPersistableTypes.self, "((decimal == %@) || (objectId == %@))", values: [Decimal128Wrapper(persistedValue: Decimal128(234.567)), ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045"))], count: 1) {
            $0.decimal == Decimal128Wrapper(persistedValue: Decimal128(234.567)) || $0.objectId == ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045"))
        }
        assertQuery(AllCustomPersistableTypes.self, "((decimal == %@) || (objectId == %@))", values: [Decimal128Wrapper(persistedValue: Decimal128(234.567)), ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045"))], count: 1) {
            ($0.decimal == Decimal128Wrapper(persistedValue: Decimal128(234.567))) || ($0.objectId == ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045")))
        }
        assertQuery(AllCustomPersistableTypes.self, "((objectId == %@) || (uuid == %@))", values: [ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045")), UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)], count: 1) {
            $0.objectId == ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045")) || $0.uuid == UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)
        }
        assertQuery(AllCustomPersistableTypes.self, "((objectId == %@) || (uuid == %@))", values: [ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045")), UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)], count: 1) {
            ($0.objectId == ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045"))) || ($0.uuid == UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!))
        }
        assertQuery(ModernAllTypesObject.self, "((optBoolCol == %@) || (optIntCol == %@))", values: [false, 3], count: 1) {
            $0.optBoolCol == false || $0.optIntCol == 3
        }
        assertQuery(ModernAllTypesObject.self, "((optBoolCol == %@) || (optIntCol == %@))", values: [false, 3], count: 1) {
            ($0.optBoolCol == false) || ($0.optIntCol == 3)
        }
        assertQuery(ModernAllTypesObject.self, "((optIntCol == %@) || (optInt8Col == %@))", values: [3, Int8(9)], count: 1) {
            $0.optIntCol == 3 || $0.optInt8Col == Int8(9)
        }
        assertQuery(ModernAllTypesObject.self, "((optIntCol == %@) || (optInt8Col == %@))", values: [3, Int8(9)], count: 1) {
            ($0.optIntCol == 3) || ($0.optInt8Col == Int8(9))
        }
        assertQuery(ModernAllTypesObject.self, "((optInt8Col == %@) || (optInt16Col == %@))", values: [Int8(9), Int16(17)], count: 1) {
            $0.optInt8Col == Int8(9) || $0.optInt16Col == Int16(17)
        }
        assertQuery(ModernAllTypesObject.self, "((optInt8Col == %@) || (optInt16Col == %@))", values: [Int8(9), Int16(17)], count: 1) {
            ($0.optInt8Col == Int8(9)) || ($0.optInt16Col == Int16(17))
        }
        assertQuery(ModernAllTypesObject.self, "((optInt16Col == %@) || (optInt32Col == %@))", values: [Int16(17), Int32(33)], count: 1) {
            $0.optInt16Col == Int16(17) || $0.optInt32Col == Int32(33)
        }
        assertQuery(ModernAllTypesObject.self, "((optInt16Col == %@) || (optInt32Col == %@))", values: [Int16(17), Int32(33)], count: 1) {
            ($0.optInt16Col == Int16(17)) || ($0.optInt32Col == Int32(33))
        }
        assertQuery(ModernAllTypesObject.self, "((optInt32Col == %@) || (optInt64Col == %@))", values: [Int32(33), Int64(65)], count: 1) {
            $0.optInt32Col == Int32(33) || $0.optInt64Col == Int64(65)
        }
        assertQuery(ModernAllTypesObject.self, "((optInt32Col == %@) || (optInt64Col == %@))", values: [Int32(33), Int64(65)], count: 1) {
            ($0.optInt32Col == Int32(33)) || ($0.optInt64Col == Int64(65))
        }
        assertQuery(ModernAllTypesObject.self, "((optInt64Col == %@) || (optFloatCol == %@))", values: [Int64(65), Float(6.55444333)], count: 1) {
            $0.optInt64Col == Int64(65) || $0.optFloatCol == Float(6.55444333)
        }
        assertQuery(ModernAllTypesObject.self, "((optInt64Col == %@) || (optFloatCol == %@))", values: [Int64(65), Float(6.55444333)], count: 1) {
            ($0.optInt64Col == Int64(65)) || ($0.optFloatCol == Float(6.55444333))
        }
        assertQuery(ModernAllTypesObject.self, "((optFloatCol == %@) || (optDoubleCol == %@))", values: [Float(6.55444333), 234.567], count: 1) {
            $0.optFloatCol == Float(6.55444333) || $0.optDoubleCol == 234.567
        }
        assertQuery(ModernAllTypesObject.self, "((optFloatCol == %@) || (optDoubleCol == %@))", values: [Float(6.55444333), 234.567], count: 1) {
            ($0.optFloatCol == Float(6.55444333)) || ($0.optDoubleCol == 234.567)
        }
        assertQuery(ModernAllTypesObject.self, "((optDoubleCol == %@) || (optStringCol == %@))", values: [234.567, "Foó"], count: 1) {
            $0.optDoubleCol == 234.567 || $0.optStringCol == "Foó"
        }
        assertQuery(ModernAllTypesObject.self, "((optDoubleCol == %@) || (optStringCol == %@))", values: [234.567, "Foó"], count: 1) {
            ($0.optDoubleCol == 234.567) || ($0.optStringCol == "Foó")
        }
        assertQuery(ModernAllTypesObject.self, "((optStringCol == %@) || (optBinaryCol == %@))", values: ["Foó", Data(count: 128)], count: 1) {
            $0.optStringCol == "Foó" || $0.optBinaryCol == Data(count: 128)
        }
        assertQuery(ModernAllTypesObject.self, "((optStringCol == %@) || (optBinaryCol == %@))", values: ["Foó", Data(count: 128)], count: 1) {
            ($0.optStringCol == "Foó") || ($0.optBinaryCol == Data(count: 128))
        }
        assertQuery(ModernAllTypesObject.self, "((optBinaryCol == %@) || (optDateCol == %@))", values: [Data(count: 128), Date(timeIntervalSince1970: 2000000)], count: 1) {
            $0.optBinaryCol == Data(count: 128) || $0.optDateCol == Date(timeIntervalSince1970: 2000000)
        }
        assertQuery(ModernAllTypesObject.self, "((optBinaryCol == %@) || (optDateCol == %@))", values: [Data(count: 128), Date(timeIntervalSince1970: 2000000)], count: 1) {
            ($0.optBinaryCol == Data(count: 128)) || ($0.optDateCol == Date(timeIntervalSince1970: 2000000))
        }
        assertQuery(ModernAllTypesObject.self, "((optDateCol == %@) || (optDecimalCol == %@))", values: [Date(timeIntervalSince1970: 2000000), Decimal128(234.567)], count: 1) {
            $0.optDateCol == Date(timeIntervalSince1970: 2000000) || $0.optDecimalCol == Decimal128(234.567)
        }
        assertQuery(ModernAllTypesObject.self, "((optDateCol == %@) || (optDecimalCol == %@))", values: [Date(timeIntervalSince1970: 2000000), Decimal128(234.567)], count: 1) {
            ($0.optDateCol == Date(timeIntervalSince1970: 2000000)) || ($0.optDecimalCol == Decimal128(234.567))
        }
        assertQuery(ModernAllTypesObject.self, "((optDecimalCol == %@) || (optObjectIdCol == %@))", values: [Decimal128(234.567), ObjectId("61184062c1d8f096a3695045")], count: 1) {
            $0.optDecimalCol == Decimal128(234.567) || $0.optObjectIdCol == ObjectId("61184062c1d8f096a3695045")
        }
        assertQuery(ModernAllTypesObject.self, "((optDecimalCol == %@) || (optObjectIdCol == %@))", values: [Decimal128(234.567), ObjectId("61184062c1d8f096a3695045")], count: 1) {
            ($0.optDecimalCol == Decimal128(234.567)) || ($0.optObjectIdCol == ObjectId("61184062c1d8f096a3695045"))
        }
        assertQuery(ModernAllTypesObject.self, "((optObjectIdCol == %@) || (optUuidCol == %@))", values: [ObjectId("61184062c1d8f096a3695045"), UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!], count: 1) {
            $0.optObjectIdCol == ObjectId("61184062c1d8f096a3695045") || $0.optUuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!
        }
        assertQuery(ModernAllTypesObject.self, "((optObjectIdCol == %@) || (optUuidCol == %@))", values: [ObjectId("61184062c1d8f096a3695045"), UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!], count: 1) {
            ($0.optObjectIdCol == ObjectId("61184062c1d8f096a3695045")) || ($0.optUuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)
        }
        assertQuery(ModernAllTypesObject.self, "((optUuidCol == %@) || (optIntEnumCol == %@))", values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!, ModernIntEnum.value2], count: 1) {
            $0.optUuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")! || $0.optIntEnumCol == .value2
        }
        assertQuery(ModernAllTypesObject.self, "((optUuidCol == %@) || (optIntEnumCol == %@))", values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!, ModernIntEnum.value2], count: 1) {
            ($0.optUuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!) || ($0.optIntEnumCol == .value2)
        }
        assertQuery(ModernAllTypesObject.self, "((optIntEnumCol == %@) || (optStringEnumCol == %@))", values: [ModernIntEnum.value2, ModernStringEnum.value2], count: 1) {
            $0.optIntEnumCol == .value2 || $0.optStringEnumCol == .value2
        }
        assertQuery(ModernAllTypesObject.self, "((optIntEnumCol == %@) || (optStringEnumCol == %@))", values: [ModernIntEnum.value2, ModernStringEnum.value2], count: 1) {
            ($0.optIntEnumCol == .value2) || ($0.optStringEnumCol == .value2)
        }
        assertQuery(AllCustomPersistableTypes.self, "((optBool == %@) || (optInt == %@))", values: [BoolWrapper(persistedValue: false), IntWrapper(persistedValue: 3)], count: 1) {
            $0.optBool == BoolWrapper(persistedValue: false) || $0.optInt == IntWrapper(persistedValue: 3)
        }
        assertQuery(AllCustomPersistableTypes.self, "((optBool == %@) || (optInt == %@))", values: [BoolWrapper(persistedValue: false), IntWrapper(persistedValue: 3)], count: 1) {
            ($0.optBool == BoolWrapper(persistedValue: false)) || ($0.optInt == IntWrapper(persistedValue: 3))
        }
        assertQuery(AllCustomPersistableTypes.self, "((optInt == %@) || (optInt8 == %@))", values: [IntWrapper(persistedValue: 3), Int8Wrapper(persistedValue: Int8(9))], count: 1) {
            $0.optInt == IntWrapper(persistedValue: 3) || $0.optInt8 == Int8Wrapper(persistedValue: Int8(9))
        }
        assertQuery(AllCustomPersistableTypes.self, "((optInt == %@) || (optInt8 == %@))", values: [IntWrapper(persistedValue: 3), Int8Wrapper(persistedValue: Int8(9))], count: 1) {
            ($0.optInt == IntWrapper(persistedValue: 3)) || ($0.optInt8 == Int8Wrapper(persistedValue: Int8(9)))
        }
        assertQuery(AllCustomPersistableTypes.self, "((optInt8 == %@) || (optInt16 == %@))", values: [Int8Wrapper(persistedValue: Int8(9)), Int16Wrapper(persistedValue: Int16(17))], count: 1) {
            $0.optInt8 == Int8Wrapper(persistedValue: Int8(9)) || $0.optInt16 == Int16Wrapper(persistedValue: Int16(17))
        }
        assertQuery(AllCustomPersistableTypes.self, "((optInt8 == %@) || (optInt16 == %@))", values: [Int8Wrapper(persistedValue: Int8(9)), Int16Wrapper(persistedValue: Int16(17))], count: 1) {
            ($0.optInt8 == Int8Wrapper(persistedValue: Int8(9))) || ($0.optInt16 == Int16Wrapper(persistedValue: Int16(17)))
        }
        assertQuery(AllCustomPersistableTypes.self, "((optInt16 == %@) || (optInt32 == %@))", values: [Int16Wrapper(persistedValue: Int16(17)), Int32Wrapper(persistedValue: Int32(33))], count: 1) {
            $0.optInt16 == Int16Wrapper(persistedValue: Int16(17)) || $0.optInt32 == Int32Wrapper(persistedValue: Int32(33))
        }
        assertQuery(AllCustomPersistableTypes.self, "((optInt16 == %@) || (optInt32 == %@))", values: [Int16Wrapper(persistedValue: Int16(17)), Int32Wrapper(persistedValue: Int32(33))], count: 1) {
            ($0.optInt16 == Int16Wrapper(persistedValue: Int16(17))) || ($0.optInt32 == Int32Wrapper(persistedValue: Int32(33)))
        }
        assertQuery(AllCustomPersistableTypes.self, "((optInt32 == %@) || (optInt64 == %@))", values: [Int32Wrapper(persistedValue: Int32(33)), Int64Wrapper(persistedValue: Int64(65))], count: 1) {
            $0.optInt32 == Int32Wrapper(persistedValue: Int32(33)) || $0.optInt64 == Int64Wrapper(persistedValue: Int64(65))
        }
        assertQuery(AllCustomPersistableTypes.self, "((optInt32 == %@) || (optInt64 == %@))", values: [Int32Wrapper(persistedValue: Int32(33)), Int64Wrapper(persistedValue: Int64(65))], count: 1) {
            ($0.optInt32 == Int32Wrapper(persistedValue: Int32(33))) || ($0.optInt64 == Int64Wrapper(persistedValue: Int64(65)))
        }
        assertQuery(AllCustomPersistableTypes.self, "((optInt64 == %@) || (optFloat == %@))", values: [Int64Wrapper(persistedValue: Int64(65)), FloatWrapper(persistedValue: Float(6.55444333))], count: 1) {
            $0.optInt64 == Int64Wrapper(persistedValue: Int64(65)) || $0.optFloat == FloatWrapper(persistedValue: Float(6.55444333))
        }
        assertQuery(AllCustomPersistableTypes.self, "((optInt64 == %@) || (optFloat == %@))", values: [Int64Wrapper(persistedValue: Int64(65)), FloatWrapper(persistedValue: Float(6.55444333))], count: 1) {
            ($0.optInt64 == Int64Wrapper(persistedValue: Int64(65))) || ($0.optFloat == FloatWrapper(persistedValue: Float(6.55444333)))
        }
        assertQuery(AllCustomPersistableTypes.self, "((optFloat == %@) || (optDouble == %@))", values: [FloatWrapper(persistedValue: Float(6.55444333)), DoubleWrapper(persistedValue: 234.567)], count: 1) {
            $0.optFloat == FloatWrapper(persistedValue: Float(6.55444333)) || $0.optDouble == DoubleWrapper(persistedValue: 234.567)
        }
        assertQuery(AllCustomPersistableTypes.self, "((optFloat == %@) || (optDouble == %@))", values: [FloatWrapper(persistedValue: Float(6.55444333)), DoubleWrapper(persistedValue: 234.567)], count: 1) {
            ($0.optFloat == FloatWrapper(persistedValue: Float(6.55444333))) || ($0.optDouble == DoubleWrapper(persistedValue: 234.567))
        }
        assertQuery(AllCustomPersistableTypes.self, "((optDouble == %@) || (optString == %@))", values: [DoubleWrapper(persistedValue: 234.567), StringWrapper(persistedValue: "Foó")], count: 1) {
            $0.optDouble == DoubleWrapper(persistedValue: 234.567) || $0.optString == StringWrapper(persistedValue: "Foó")
        }
        assertQuery(AllCustomPersistableTypes.self, "((optDouble == %@) || (optString == %@))", values: [DoubleWrapper(persistedValue: 234.567), StringWrapper(persistedValue: "Foó")], count: 1) {
            ($0.optDouble == DoubleWrapper(persistedValue: 234.567)) || ($0.optString == StringWrapper(persistedValue: "Foó"))
        }
        assertQuery(AllCustomPersistableTypes.self, "((optString == %@) || (optBinary == %@))", values: [StringWrapper(persistedValue: "Foó"), DataWrapper(persistedValue: Data(count: 128))], count: 1) {
            $0.optString == StringWrapper(persistedValue: "Foó") || $0.optBinary == DataWrapper(persistedValue: Data(count: 128))
        }
        assertQuery(AllCustomPersistableTypes.self, "((optString == %@) || (optBinary == %@))", values: [StringWrapper(persistedValue: "Foó"), DataWrapper(persistedValue: Data(count: 128))], count: 1) {
            ($0.optString == StringWrapper(persistedValue: "Foó")) || ($0.optBinary == DataWrapper(persistedValue: Data(count: 128)))
        }
        assertQuery(AllCustomPersistableTypes.self, "((optBinary == %@) || (optDate == %@))", values: [DataWrapper(persistedValue: Data(count: 128)), DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000))], count: 1) {
            $0.optBinary == DataWrapper(persistedValue: Data(count: 128)) || $0.optDate == DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000))
        }
        assertQuery(AllCustomPersistableTypes.self, "((optBinary == %@) || (optDate == %@))", values: [DataWrapper(persistedValue: Data(count: 128)), DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000))], count: 1) {
            ($0.optBinary == DataWrapper(persistedValue: Data(count: 128))) || ($0.optDate == DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)))
        }
        assertQuery(AllCustomPersistableTypes.self, "((optDate == %@) || (optDecimal == %@))", values: [DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)), Decimal128Wrapper(persistedValue: Decimal128(234.567))], count: 1) {
            $0.optDate == DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)) || $0.optDecimal == Decimal128Wrapper(persistedValue: Decimal128(234.567))
        }
        assertQuery(AllCustomPersistableTypes.self, "((optDate == %@) || (optDecimal == %@))", values: [DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)), Decimal128Wrapper(persistedValue: Decimal128(234.567))], count: 1) {
            ($0.optDate == DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000))) || ($0.optDecimal == Decimal128Wrapper(persistedValue: Decimal128(234.567)))
        }
        assertQuery(AllCustomPersistableTypes.self, "((optDecimal == %@) || (optObjectId == %@))", values: [Decimal128Wrapper(persistedValue: Decimal128(234.567)), ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045"))], count: 1) {
            $0.optDecimal == Decimal128Wrapper(persistedValue: Decimal128(234.567)) || $0.optObjectId == ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045"))
        }
        assertQuery(AllCustomPersistableTypes.self, "((optDecimal == %@) || (optObjectId == %@))", values: [Decimal128Wrapper(persistedValue: Decimal128(234.567)), ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045"))], count: 1) {
            ($0.optDecimal == Decimal128Wrapper(persistedValue: Decimal128(234.567))) || ($0.optObjectId == ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045")))
        }
        assertQuery(AllCustomPersistableTypes.self, "((optObjectId == %@) || (optUuid == %@))", values: [ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045")), UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)], count: 1) {
            $0.optObjectId == ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045")) || $0.optUuid == UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)
        }
        assertQuery(AllCustomPersistableTypes.self, "((optObjectId == %@) || (optUuid == %@))", values: [ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045")), UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)], count: 1) {
            ($0.optObjectId == ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045"))) || ($0.optUuid == UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!))
        }

        // List / Set

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
        assertQuery("((boolCol == %@) || (%@ IN mapInt))", values: [false, 3], count: 1) {
            $0.boolCol == false || $0.mapInt.contains(3)
        }
        assertQuery("((boolCol != %@) || (mapInt[%@] == %@))",
                    values: [true, "foo", 3], count: 1) {
            ($0.boolCol != true) || ($0.mapInt["foo"] == 3)
        }
        assertQuery("(((boolCol != %@) || (mapInt[%@] == %@)) || (mapInt[%@] == %@))",
                    values: [true, "foo", 1, "bar", 3], count: 1) {
            ($0.boolCol != true) ||
            ($0.mapInt["foo"] == 1) ||
            ($0.mapInt["bar"] == 3)
        }
        assertQuery("((boolCol == %@) || (%@ IN mapOptInt))", values: [false, 3], count: 1) {
            $0.boolCol == false || $0.mapOptInt.contains(3)
        }
        assertQuery("((boolCol != %@) || (mapOptInt[%@] == %@))",
                    values: [true, "foo", 3], count: 1) {
            ($0.boolCol != true) || ($0.mapOptInt["foo"] == 3)
        }
        assertQuery("(((boolCol != %@) || (mapOptInt[%@] == %@)) || (mapOptInt[%@] == %@))",
                    values: [true, "foo", 1, "bar", 3], count: 1) {
            ($0.boolCol != true) ||
            ($0.mapOptInt["foo"] == 1) ||
            ($0.mapOptInt["bar"] == 3)
        }

        // Aggregates

        let sumarrayInt = 1 + 3
        assertQuery("((((((arrayInt.@min <= %@) || (arrayInt.@max >= %@)) || (arrayInt.@sum != %@)) || (arrayInt.@count == %@)) || (arrayInt.@avg > %@)) || (arrayInt.@avg < %@))",
                    values: [1, 5, sumarrayInt, 0, 3, 1], count: 1) {
            ($0.arrayInt.min <= 1) ||
            ($0.arrayInt.max >= 5) ||
            ($0.arrayInt.sum != sumarrayInt) ||
            ($0.arrayInt.count == 0) ||
            ($0.arrayInt.avg > 3) ||
            ($0.arrayInt.avg < 1)
        }
        let sumarrayOptInt = 1 + 3
        assertQuery("((((((arrayOptInt.@min <= %@) || (arrayOptInt.@max >= %@)) || (arrayOptInt.@sum != %@)) || (arrayOptInt.@count == %@)) || (arrayOptInt.@avg > %@)) || (arrayOptInt.@avg < %@))",
                    values: [1, 5, sumarrayOptInt, 0, 3, 1], count: 1) {
            ($0.arrayOptInt.min <= 1) ||
            ($0.arrayOptInt.max >= 5) ||
            ($0.arrayOptInt.sum != sumarrayOptInt) ||
            ($0.arrayOptInt.count == 0) ||
            ($0.arrayOptInt.avg > 3) ||
            ($0.arrayOptInt.avg < 1)
        }

        // Keypath Collection Aggregates

        createKeypathCollectionAggregatesObject()

        let sumdoubleCol = 123.456 + 234.567 + 345.678
        assertQuery(LinkToModernAllTypesObject.self, "((((((list.@min.doubleCol < %@) || (list.@max.doubleCol > %@)) || (list.@sum.doubleCol != %@)) || (list.@min.doubleCol == %@)) || (list.@avg.doubleCol >= %@)) || (list.@avg.doubleCol <= %@))",
                    values: [123.456, 345.678, sumdoubleCol, 0, 345.678, 123.456], count: 0) {
            $0.list.doubleCol.min < 123.456 ||
            $0.list.doubleCol.max > 345.678 ||
            $0.list.doubleCol.sum != sumdoubleCol ||
            $0.list.doubleCol.min == 0 ||
            $0.list.doubleCol.avg >= 345.678 ||
            $0.list.doubleCol.avg <= 123.456
        }

        let sumoptDoubleCol = 123.456 + 234.567 + 345.678
        assertQuery(LinkToModernAllTypesObject.self, "((((((list.@min.optDoubleCol < %@) || (list.@max.optDoubleCol > %@)) || (list.@sum.optDoubleCol != %@)) || (list.@min.optDoubleCol == %@)) || (list.@avg.optDoubleCol >= %@)) || (list.@avg.optDoubleCol <= %@))",
                    values: [123.456, 345.678, sumoptDoubleCol, 0, 345.678, 123.456], count: 0) {
            $0.list.optDoubleCol.min < 123.456 ||
            $0.list.optDoubleCol.max > 345.678 ||
            $0.list.optDoubleCol.sum != sumoptDoubleCol ||
            $0.list.optDoubleCol.min == 0 ||
            $0.list.optDoubleCol.avg >= 345.678 ||
            $0.list.optDoubleCol.avg <= 123.456
        }
    }

    func validateCompoundMixed<Root: Object, T: _Persistable, U: _Persistable>(
            _ name1: String, _ lhs1: (Query<Root>) -> Query<T>, _ value1: T,
            _ name2: String, _ lhs2: (Query<Root>) -> Query<U>, _ value2: U) {
        assertQuery(Root.self, "(((\(name1) == %@) || (\(name2) == %@)) && ((\(name1) != %@) || (\(name2) != %@)))",
                    values: [value1, value2, value1, value2], count: 0) {
            (lhs1($0) == value1 || lhs2($0) == value2) && (lhs1($0) != value1 || lhs2($0) != value2)
        }
        assertQuery(Root.self, "((\(name1) == %@) || (\(name2) == %@))", values: [value1, value2], count: 1) {
            (lhs1($0) == value1) || (lhs2($0) == value2)
        }
    }

    func validateCompoundString<Root: Object, T: _Persistable, U: _Persistable>(
            _ name1: String, _ lhs1: (Query<Root>) -> Query<T>, _ value1: T,
            _ name2: String, _ lhs2: (Query<Root>) -> Query<U>, _ value2: U) where U.PersistedType: _QueryBinary {
        assertQuery(Root.self, "(NOT ((\(name1) == %@) || (\(name2) CONTAINS %@)) && (\(name2) == %@))",
                    values: [value1, value2, value2], count: 0) {
            !(lhs1($0) == value1 || lhs2($0).contains(value2)) && (lhs2($0) == value2)
        }
    }

    func testCompoundMixed() {
        validateCompoundMixed("boolCol", \Query<ModernAllTypesObject>.boolCol, false,
                              "intCol", \Query<ModernAllTypesObject>.intCol, 3)
        validateCompoundMixed("intCol", \Query<ModernAllTypesObject>.intCol, 3,
                              "int8Col", \Query<ModernAllTypesObject>.int8Col, Int8(9))
        validateCompoundMixed("int8Col", \Query<ModernAllTypesObject>.int8Col, Int8(9),
                              "int16Col", \Query<ModernAllTypesObject>.int16Col, Int16(17))
        validateCompoundMixed("int16Col", \Query<ModernAllTypesObject>.int16Col, Int16(17),
                              "int32Col", \Query<ModernAllTypesObject>.int32Col, Int32(33))
        validateCompoundMixed("int32Col", \Query<ModernAllTypesObject>.int32Col, Int32(33),
                              "int64Col", \Query<ModernAllTypesObject>.int64Col, Int64(65))
        validateCompoundMixed("int64Col", \Query<ModernAllTypesObject>.int64Col, Int64(65),
                              "floatCol", \Query<ModernAllTypesObject>.floatCol, Float(6.55444333))
        validateCompoundMixed("floatCol", \Query<ModernAllTypesObject>.floatCol, Float(6.55444333),
                              "doubleCol", \Query<ModernAllTypesObject>.doubleCol, 234.567)
        validateCompoundMixed("doubleCol", \Query<ModernAllTypesObject>.doubleCol, 234.567,
                              "stringCol", \Query<ModernAllTypesObject>.stringCol, "Foó")
        validateCompoundString("doubleCol", \Query<ModernAllTypesObject>.doubleCol, 234.567,
                               "stringCol", \Query<ModernAllTypesObject>.stringCol, "Foó")
        validateCompoundMixed("stringCol", \Query<ModernAllTypesObject>.stringCol, "Foó",
                              "binaryCol", \Query<ModernAllTypesObject>.binaryCol, Data(count: 128))
        validateCompoundMixed("binaryCol", \Query<ModernAllTypesObject>.binaryCol, Data(count: 128),
                              "dateCol", \Query<ModernAllTypesObject>.dateCol, Date(timeIntervalSince1970: 2000000))
        validateCompoundMixed("dateCol", \Query<ModernAllTypesObject>.dateCol, Date(timeIntervalSince1970: 2000000),
                              "decimalCol", \Query<ModernAllTypesObject>.decimalCol, Decimal128(234.567))
        validateCompoundMixed("decimalCol", \Query<ModernAllTypesObject>.decimalCol, Decimal128(234.567),
                              "objectIdCol", \Query<ModernAllTypesObject>.objectIdCol, ObjectId("61184062c1d8f096a3695045"))
        validateCompoundMixed("objectIdCol", \Query<ModernAllTypesObject>.objectIdCol, ObjectId("61184062c1d8f096a3695045"),
                              "uuidCol", \Query<ModernAllTypesObject>.uuidCol, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)
        validateCompoundMixed("uuidCol", \Query<ModernAllTypesObject>.uuidCol, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!,
                              "intEnumCol", \Query<ModernAllTypesObject>.intEnumCol, .value2)
        validateCompoundMixed("intEnumCol", \Query<ModernAllTypesObject>.intEnumCol, .value2,
                              "stringEnumCol", \Query<ModernAllTypesObject>.stringEnumCol, .value2)
        validateCompoundMixed("bool", \Query<AllCustomPersistableTypes>.bool, BoolWrapper(persistedValue: false),
                              "int", \Query<AllCustomPersistableTypes>.int, IntWrapper(persistedValue: 3))
        validateCompoundMixed("int", \Query<AllCustomPersistableTypes>.int, IntWrapper(persistedValue: 3),
                              "int8", \Query<AllCustomPersistableTypes>.int8, Int8Wrapper(persistedValue: Int8(9)))
        validateCompoundMixed("int8", \Query<AllCustomPersistableTypes>.int8, Int8Wrapper(persistedValue: Int8(9)),
                              "int16", \Query<AllCustomPersistableTypes>.int16, Int16Wrapper(persistedValue: Int16(17)))
        validateCompoundMixed("int16", \Query<AllCustomPersistableTypes>.int16, Int16Wrapper(persistedValue: Int16(17)),
                              "int32", \Query<AllCustomPersistableTypes>.int32, Int32Wrapper(persistedValue: Int32(33)))
        validateCompoundMixed("int32", \Query<AllCustomPersistableTypes>.int32, Int32Wrapper(persistedValue: Int32(33)),
                              "int64", \Query<AllCustomPersistableTypes>.int64, Int64Wrapper(persistedValue: Int64(65)))
        validateCompoundMixed("int64", \Query<AllCustomPersistableTypes>.int64, Int64Wrapper(persistedValue: Int64(65)),
                              "float", \Query<AllCustomPersistableTypes>.float, FloatWrapper(persistedValue: Float(6.55444333)))
        validateCompoundMixed("float", \Query<AllCustomPersistableTypes>.float, FloatWrapper(persistedValue: Float(6.55444333)),
                              "double", \Query<AllCustomPersistableTypes>.double, DoubleWrapper(persistedValue: 234.567))
        validateCompoundMixed("double", \Query<AllCustomPersistableTypes>.double, DoubleWrapper(persistedValue: 234.567),
                              "string", \Query<AllCustomPersistableTypes>.string, StringWrapper(persistedValue: "Foó"))
        validateCompoundString("double", \Query<AllCustomPersistableTypes>.double, DoubleWrapper(persistedValue: 234.567),
                               "string", \Query<AllCustomPersistableTypes>.string, StringWrapper(persistedValue: "Foó"))
        validateCompoundMixed("string", \Query<AllCustomPersistableTypes>.string, StringWrapper(persistedValue: "Foó"),
                              "binary", \Query<AllCustomPersistableTypes>.binary, DataWrapper(persistedValue: Data(count: 128)))
        validateCompoundMixed("binary", \Query<AllCustomPersistableTypes>.binary, DataWrapper(persistedValue: Data(count: 128)),
                              "date", \Query<AllCustomPersistableTypes>.date, DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)))
        validateCompoundMixed("date", \Query<AllCustomPersistableTypes>.date, DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)),
                              "decimal", \Query<AllCustomPersistableTypes>.decimal, Decimal128Wrapper(persistedValue: Decimal128(234.567)))
        validateCompoundMixed("decimal", \Query<AllCustomPersistableTypes>.decimal, Decimal128Wrapper(persistedValue: Decimal128(234.567)),
                              "objectId", \Query<AllCustomPersistableTypes>.objectId, ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045")))
        validateCompoundMixed("objectId", \Query<AllCustomPersistableTypes>.objectId, ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045")),
                              "uuid", \Query<AllCustomPersistableTypes>.uuid, UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!))
        validateCompoundMixed("optBoolCol", \Query<ModernAllTypesObject>.optBoolCol, false,
                              "optIntCol", \Query<ModernAllTypesObject>.optIntCol, 3)
        validateCompoundMixed("optIntCol", \Query<ModernAllTypesObject>.optIntCol, 3,
                              "optInt8Col", \Query<ModernAllTypesObject>.optInt8Col, Int8(9))
        validateCompoundMixed("optInt8Col", \Query<ModernAllTypesObject>.optInt8Col, Int8(9),
                              "optInt16Col", \Query<ModernAllTypesObject>.optInt16Col, Int16(17))
        validateCompoundMixed("optInt16Col", \Query<ModernAllTypesObject>.optInt16Col, Int16(17),
                              "optInt32Col", \Query<ModernAllTypesObject>.optInt32Col, Int32(33))
        validateCompoundMixed("optInt32Col", \Query<ModernAllTypesObject>.optInt32Col, Int32(33),
                              "optInt64Col", \Query<ModernAllTypesObject>.optInt64Col, Int64(65))
        validateCompoundMixed("optInt64Col", \Query<ModernAllTypesObject>.optInt64Col, Int64(65),
                              "optFloatCol", \Query<ModernAllTypesObject>.optFloatCol, Float(6.55444333))
        validateCompoundMixed("optFloatCol", \Query<ModernAllTypesObject>.optFloatCol, Float(6.55444333),
                              "optDoubleCol", \Query<ModernAllTypesObject>.optDoubleCol, 234.567)
        validateCompoundMixed("optDoubleCol", \Query<ModernAllTypesObject>.optDoubleCol, 234.567,
                              "optStringCol", \Query<ModernAllTypesObject>.optStringCol, "Foó")
        validateCompoundString("optDoubleCol", \Query<ModernAllTypesObject>.optDoubleCol, 234.567,
                               "optStringCol", \Query<ModernAllTypesObject>.optStringCol, "Foó")
        validateCompoundMixed("optStringCol", \Query<ModernAllTypesObject>.optStringCol, "Foó",
                              "optBinaryCol", \Query<ModernAllTypesObject>.optBinaryCol, Data(count: 128))
        validateCompoundMixed("optBinaryCol", \Query<ModernAllTypesObject>.optBinaryCol, Data(count: 128),
                              "optDateCol", \Query<ModernAllTypesObject>.optDateCol, Date(timeIntervalSince1970: 2000000))
        validateCompoundMixed("optDateCol", \Query<ModernAllTypesObject>.optDateCol, Date(timeIntervalSince1970: 2000000),
                              "optDecimalCol", \Query<ModernAllTypesObject>.optDecimalCol, Decimal128(234.567))
        validateCompoundMixed("optDecimalCol", \Query<ModernAllTypesObject>.optDecimalCol, Decimal128(234.567),
                              "optObjectIdCol", \Query<ModernAllTypesObject>.optObjectIdCol, ObjectId("61184062c1d8f096a3695045"))
        validateCompoundMixed("optObjectIdCol", \Query<ModernAllTypesObject>.optObjectIdCol, ObjectId("61184062c1d8f096a3695045"),
                              "optUuidCol", \Query<ModernAllTypesObject>.optUuidCol, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)
        validateCompoundMixed("optUuidCol", \Query<ModernAllTypesObject>.optUuidCol, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!,
                              "optIntEnumCol", \Query<ModernAllTypesObject>.optIntEnumCol, .value2)
        validateCompoundMixed("optIntEnumCol", \Query<ModernAllTypesObject>.optIntEnumCol, .value2,
                              "optStringEnumCol", \Query<ModernAllTypesObject>.optStringEnumCol, .value2)
        validateCompoundMixed("optBool", \Query<AllCustomPersistableTypes>.optBool, BoolWrapper(persistedValue: false),
                              "optInt", \Query<AllCustomPersistableTypes>.optInt, IntWrapper(persistedValue: 3))
        validateCompoundMixed("optInt", \Query<AllCustomPersistableTypes>.optInt, IntWrapper(persistedValue: 3),
                              "optInt8", \Query<AllCustomPersistableTypes>.optInt8, Int8Wrapper(persistedValue: Int8(9)))
        validateCompoundMixed("optInt8", \Query<AllCustomPersistableTypes>.optInt8, Int8Wrapper(persistedValue: Int8(9)),
                              "optInt16", \Query<AllCustomPersistableTypes>.optInt16, Int16Wrapper(persistedValue: Int16(17)))
        validateCompoundMixed("optInt16", \Query<AllCustomPersistableTypes>.optInt16, Int16Wrapper(persistedValue: Int16(17)),
                              "optInt32", \Query<AllCustomPersistableTypes>.optInt32, Int32Wrapper(persistedValue: Int32(33)))
        validateCompoundMixed("optInt32", \Query<AllCustomPersistableTypes>.optInt32, Int32Wrapper(persistedValue: Int32(33)),
                              "optInt64", \Query<AllCustomPersistableTypes>.optInt64, Int64Wrapper(persistedValue: Int64(65)))
        validateCompoundMixed("optInt64", \Query<AllCustomPersistableTypes>.optInt64, Int64Wrapper(persistedValue: Int64(65)),
                              "optFloat", \Query<AllCustomPersistableTypes>.optFloat, FloatWrapper(persistedValue: Float(6.55444333)))
        validateCompoundMixed("optFloat", \Query<AllCustomPersistableTypes>.optFloat, FloatWrapper(persistedValue: Float(6.55444333)),
                              "optDouble", \Query<AllCustomPersistableTypes>.optDouble, DoubleWrapper(persistedValue: 234.567))
        validateCompoundMixed("optDouble", \Query<AllCustomPersistableTypes>.optDouble, DoubleWrapper(persistedValue: 234.567),
                              "optString", \Query<AllCustomPersistableTypes>.optString, StringWrapper(persistedValue: "Foó"))
        validateCompoundString("optDouble", \Query<AllCustomPersistableTypes>.optDouble, DoubleWrapper(persistedValue: 234.567),
                               "optString", \Query<AllCustomPersistableTypes>.optString, StringWrapper(persistedValue: "Foó"))
        validateCompoundMixed("optString", \Query<AllCustomPersistableTypes>.optString, StringWrapper(persistedValue: "Foó"),
                              "optBinary", \Query<AllCustomPersistableTypes>.optBinary, DataWrapper(persistedValue: Data(count: 128)))
        validateCompoundMixed("optBinary", \Query<AllCustomPersistableTypes>.optBinary, DataWrapper(persistedValue: Data(count: 128)),
                              "optDate", \Query<AllCustomPersistableTypes>.optDate, DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)))
        validateCompoundMixed("optDate", \Query<AllCustomPersistableTypes>.optDate, DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000)),
                              "optDecimal", \Query<AllCustomPersistableTypes>.optDecimal, Decimal128Wrapper(persistedValue: Decimal128(234.567)))
        validateCompoundMixed("optDecimal", \Query<AllCustomPersistableTypes>.optDecimal, Decimal128Wrapper(persistedValue: Decimal128(234.567)),
                              "optObjectId", \Query<AllCustomPersistableTypes>.optObjectId, ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045")))
        validateCompoundMixed("optObjectId", \Query<AllCustomPersistableTypes>.optObjectId, ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045")),
                              "optUuid", \Query<AllCustomPersistableTypes>.optUuid, UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!))

        // Aggregates

        let sumarrayInt = 1 + 3
        assertQuery("(((((arrayInt.@min <= %@) || (arrayInt.@max >= %@)) && (arrayInt.@sum == %@)) && (arrayInt.@count != %@)) && ((arrayInt.@avg > %@) && (arrayInt.@avg < %@)))",
                    values: [1, 5, sumarrayInt, 0, 1, 5], count: 1) {
            (($0.arrayInt.min <= 1) || ($0.arrayInt.max >= 5)) &&
            ($0.arrayInt.sum == sumarrayInt) &&
            ($0.arrayInt.count != 0) &&
            ($0.arrayInt.avg > 1 && $0.arrayInt.avg < 5)
        }
        let sumarrayOptInt = 1 + 3
        assertQuery("(((((arrayOptInt.@min <= %@) || (arrayOptInt.@max >= %@)) && (arrayOptInt.@sum == %@)) && (arrayOptInt.@count != %@)) && ((arrayOptInt.@avg > %@) && (arrayOptInt.@avg < %@)))",
                    values: [1, 5, sumarrayOptInt, 0, 1, 5], count: 1) {
            (($0.arrayOptInt.min <= 1) || ($0.arrayOptInt.max >= 5)) &&
            ($0.arrayOptInt.sum == sumarrayOptInt) &&
            ($0.arrayOptInt.count != 0) &&
            ($0.arrayOptInt.avg > 1 && $0.arrayOptInt.avg < 5)
        }
        let summapInt = 1 + 3
        assertQuery("(((((mapInt.@min <= %@) || (mapInt.@max >= %@)) && (mapInt.@sum == %@)) && (mapInt.@count != %@)) && ((mapInt.@avg > %@) && (mapInt.@avg < %@)))",
                    values: [1, 5, summapInt, 0, 1, 5], count: 1) {
            (($0.mapInt.min <= 1) || ($0.mapInt.max >= 5)) &&
            ($0.mapInt.sum == summapInt) &&
            ($0.mapInt.count != 0) &&
            ($0.mapInt.avg > 1 && $0.mapInt.avg < 5)
        }
        let summapOptInt = 1 + 3
        assertQuery("(((((mapOptInt.@min <= %@) || (mapOptInt.@max >= %@)) && (mapOptInt.@sum == %@)) && (mapOptInt.@count != %@)) && ((mapOptInt.@avg > %@) && (mapOptInt.@avg < %@)))",
                    values: [1, 5, summapOptInt, 0, 1, 5], count: 1) {
            (($0.mapOptInt.min <= 1) || ($0.mapOptInt.max >= 5)) &&
            ($0.mapOptInt.sum == summapOptInt) &&
            ($0.mapOptInt.count != 0) &&
            ($0.mapOptInt.avg > 1 && $0.mapOptInt.avg < 5)
        }

        // Keypath Collection Aggregates

        createKeypathCollectionAggregatesObject()

        let sumdoubleCol = 123.456 + 234.567 + 345.678
        assertQuery(LinkToModernAllTypesObject.self, "(((((list.@min.doubleCol <= %@) || (list.@max.doubleCol >= %@)) && (list.@sum.doubleCol == %@)) && (list.@sum.doubleCol != %@)) && ((list.@avg.doubleCol > %@) && (list.@avg.doubleCol < %@)))", values: [123.456, 345.678, sumdoubleCol, 0, 123.456, 345.678], count: 1) {
            ($0.list.doubleCol.min <= 123.456 || $0.list.doubleCol.max >= 345.678) &&
            $0.list.doubleCol.sum == sumdoubleCol &&
            $0.list.doubleCol.sum != 0 &&
            ($0.list.doubleCol.avg > 123.456 && $0.list.doubleCol.avg < 345.678)
        }

        let sumoptDoubleCol = 123.456 + 234.567 + 345.678
        assertQuery(LinkToModernAllTypesObject.self, "(((((list.@min.optDoubleCol <= %@) || (list.@max.optDoubleCol >= %@)) && (list.@sum.optDoubleCol == %@)) && (list.@sum.optDoubleCol != %@)) && ((list.@avg.optDoubleCol > %@) && (list.@avg.optDoubleCol < %@)))", values: [123.456, 345.678, sumoptDoubleCol, 0, 123.456, 345.678], count: 1) {
            ($0.list.optDoubleCol.min <= 123.456 || $0.list.optDoubleCol.max >= 345.678) &&
            $0.list.optDoubleCol.sum == sumoptDoubleCol &&
            $0.list.optDoubleCol.sum != 0 &&
            ($0.list.optDoubleCol.avg > 123.456 && $0.list.optDoubleCol.avg < 345.678)
        }
    }

    func testAny() {
        assertQuery(ModernAllTypesObject.self, "(ANY arrayBool == %@)", true, count: 1) {
            $0.arrayBool == true
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayInt == %@)", 1, count: 1) {
            $0.arrayInt == 1
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
        assertQuery(CustomPersistableCollections.self, "(ANY listBool == %@)", BoolWrapper(persistedValue: true), count: 1) {
            $0.listBool == BoolWrapper(persistedValue: true)
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listInt == %@)", IntWrapper(persistedValue: 1), count: 1) {
            $0.listInt == IntWrapper(persistedValue: 1)
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listInt8 == %@)", Int8Wrapper(persistedValue: Int8(8)), count: 1) {
            $0.listInt8 == Int8Wrapper(persistedValue: Int8(8))
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listInt16 == %@)", Int16Wrapper(persistedValue: Int16(16)), count: 1) {
            $0.listInt16 == Int16Wrapper(persistedValue: Int16(16))
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listInt32 == %@)", Int32Wrapper(persistedValue: Int32(32)), count: 1) {
            $0.listInt32 == Int32Wrapper(persistedValue: Int32(32))
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listInt64 == %@)", Int64Wrapper(persistedValue: Int64(64)), count: 1) {
            $0.listInt64 == Int64Wrapper(persistedValue: Int64(64))
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listFloat == %@)", FloatWrapper(persistedValue: Float(5.55444333)), count: 1) {
            $0.listFloat == FloatWrapper(persistedValue: Float(5.55444333))
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listDouble == %@)", DoubleWrapper(persistedValue: 123.456), count: 1) {
            $0.listDouble == DoubleWrapper(persistedValue: 123.456)
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listString == %@)", StringWrapper(persistedValue: "Foo"), count: 1) {
            $0.listString == StringWrapper(persistedValue: "Foo")
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listBinary == %@)", DataWrapper(persistedValue: Data(count: 64)), count: 1) {
            $0.listBinary == DataWrapper(persistedValue: Data(count: 64))
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listDate == %@)", DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)), count: 1) {
            $0.listDate == DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000))
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listDecimal == %@)", Decimal128Wrapper(persistedValue: Decimal128(123.456)), count: 1) {
            $0.listDecimal == Decimal128Wrapper(persistedValue: Decimal128(123.456))
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listObjectId == %@)", ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695046")), count: 1) {
            $0.listObjectId == ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695046"))
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listUuid == %@)", UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!), count: 1) {
            $0.listUuid == UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!)
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayOptBool == %@)", true, count: 1) {
            $0.arrayOptBool == true
        }
        assertQuery(ModernAllTypesObject.self, "(ANY arrayOptInt == %@)", 1, count: 1) {
            $0.arrayOptInt == 1
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
        assertQuery(CustomPersistableCollections.self, "(ANY listOptBool == %@)", BoolWrapper(persistedValue: true), count: 1) {
            $0.listOptBool == BoolWrapper(persistedValue: true)
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listOptInt == %@)", IntWrapper(persistedValue: 1), count: 1) {
            $0.listOptInt == IntWrapper(persistedValue: 1)
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listOptInt8 == %@)", Int8Wrapper(persistedValue: Int8(8)), count: 1) {
            $0.listOptInt8 == Int8Wrapper(persistedValue: Int8(8))
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listOptInt16 == %@)", Int16Wrapper(persistedValue: Int16(16)), count: 1) {
            $0.listOptInt16 == Int16Wrapper(persistedValue: Int16(16))
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listOptInt32 == %@)", Int32Wrapper(persistedValue: Int32(32)), count: 1) {
            $0.listOptInt32 == Int32Wrapper(persistedValue: Int32(32))
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listOptInt64 == %@)", Int64Wrapper(persistedValue: Int64(64)), count: 1) {
            $0.listOptInt64 == Int64Wrapper(persistedValue: Int64(64))
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listOptFloat == %@)", FloatWrapper(persistedValue: Float(5.55444333)), count: 1) {
            $0.listOptFloat == FloatWrapper(persistedValue: Float(5.55444333))
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listOptDouble == %@)", DoubleWrapper(persistedValue: 123.456), count: 1) {
            $0.listOptDouble == DoubleWrapper(persistedValue: 123.456)
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listOptString == %@)", StringWrapper(persistedValue: "Foo"), count: 1) {
            $0.listOptString == StringWrapper(persistedValue: "Foo")
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listOptBinary == %@)", DataWrapper(persistedValue: Data(count: 64)), count: 1) {
            $0.listOptBinary == DataWrapper(persistedValue: Data(count: 64))
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listOptDate == %@)", DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)), count: 1) {
            $0.listOptDate == DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000))
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listOptDecimal == %@)", Decimal128Wrapper(persistedValue: Decimal128(123.456)), count: 1) {
            $0.listOptDecimal == Decimal128Wrapper(persistedValue: Decimal128(123.456))
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listOptObjectId == %@)", ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695046")), count: 1) {
            $0.listOptObjectId == ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695046"))
        }
        assertQuery(CustomPersistableCollections.self, "(ANY listOptUuid == %@)", UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!), count: 1) {
            $0.listOptUuid == UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!)
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setBool == %@)", true, count: 1) {
            $0.setBool == true
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setInt == %@)", 1, count: 1) {
            $0.setInt == 1
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
        assertQuery(CustomPersistableCollections.self, "(ANY setBool == %@)", BoolWrapper(persistedValue: true), count: 1) {
            $0.setBool == BoolWrapper(persistedValue: true)
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setInt == %@)", IntWrapper(persistedValue: 1), count: 1) {
            $0.setInt == IntWrapper(persistedValue: 1)
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setInt8 == %@)", Int8Wrapper(persistedValue: Int8(8)), count: 1) {
            $0.setInt8 == Int8Wrapper(persistedValue: Int8(8))
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setInt16 == %@)", Int16Wrapper(persistedValue: Int16(16)), count: 1) {
            $0.setInt16 == Int16Wrapper(persistedValue: Int16(16))
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setInt32 == %@)", Int32Wrapper(persistedValue: Int32(32)), count: 1) {
            $0.setInt32 == Int32Wrapper(persistedValue: Int32(32))
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setInt64 == %@)", Int64Wrapper(persistedValue: Int64(64)), count: 1) {
            $0.setInt64 == Int64Wrapper(persistedValue: Int64(64))
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setFloat == %@)", FloatWrapper(persistedValue: Float(5.55444333)), count: 1) {
            $0.setFloat == FloatWrapper(persistedValue: Float(5.55444333))
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setDouble == %@)", DoubleWrapper(persistedValue: 123.456), count: 1) {
            $0.setDouble == DoubleWrapper(persistedValue: 123.456)
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setString == %@)", StringWrapper(persistedValue: "Foo"), count: 1) {
            $0.setString == StringWrapper(persistedValue: "Foo")
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setBinary == %@)", DataWrapper(persistedValue: Data(count: 64)), count: 1) {
            $0.setBinary == DataWrapper(persistedValue: Data(count: 64))
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setDate == %@)", DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)), count: 1) {
            $0.setDate == DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000))
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setDecimal == %@)", Decimal128Wrapper(persistedValue: Decimal128(123.456)), count: 1) {
            $0.setDecimal == Decimal128Wrapper(persistedValue: Decimal128(123.456))
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setObjectId == %@)", ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695046")), count: 1) {
            $0.setObjectId == ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695046"))
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setUuid == %@)", UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!), count: 1) {
            $0.setUuid == UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!)
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setOptBool == %@)", true, count: 1) {
            $0.setOptBool == true
        }
        assertQuery(ModernAllTypesObject.self, "(ANY setOptInt == %@)", 1, count: 1) {
            $0.setOptInt == 1
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
        assertQuery(CustomPersistableCollections.self, "(ANY setOptBool == %@)", BoolWrapper(persistedValue: true), count: 1) {
            $0.setOptBool == BoolWrapper(persistedValue: true)
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setOptInt == %@)", IntWrapper(persistedValue: 1), count: 1) {
            $0.setOptInt == IntWrapper(persistedValue: 1)
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setOptInt8 == %@)", Int8Wrapper(persistedValue: Int8(8)), count: 1) {
            $0.setOptInt8 == Int8Wrapper(persistedValue: Int8(8))
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setOptInt16 == %@)", Int16Wrapper(persistedValue: Int16(16)), count: 1) {
            $0.setOptInt16 == Int16Wrapper(persistedValue: Int16(16))
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setOptInt32 == %@)", Int32Wrapper(persistedValue: Int32(32)), count: 1) {
            $0.setOptInt32 == Int32Wrapper(persistedValue: Int32(32))
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setOptInt64 == %@)", Int64Wrapper(persistedValue: Int64(64)), count: 1) {
            $0.setOptInt64 == Int64Wrapper(persistedValue: Int64(64))
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setOptFloat == %@)", FloatWrapper(persistedValue: Float(5.55444333)), count: 1) {
            $0.setOptFloat == FloatWrapper(persistedValue: Float(5.55444333))
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setOptDouble == %@)", DoubleWrapper(persistedValue: 123.456), count: 1) {
            $0.setOptDouble == DoubleWrapper(persistedValue: 123.456)
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setOptString == %@)", StringWrapper(persistedValue: "Foo"), count: 1) {
            $0.setOptString == StringWrapper(persistedValue: "Foo")
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setOptBinary == %@)", DataWrapper(persistedValue: Data(count: 64)), count: 1) {
            $0.setOptBinary == DataWrapper(persistedValue: Data(count: 64))
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setOptDate == %@)", DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)), count: 1) {
            $0.setOptDate == DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000))
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setOptDecimal == %@)", Decimal128Wrapper(persistedValue: Decimal128(123.456)), count: 1) {
            $0.setOptDecimal == Decimal128Wrapper(persistedValue: Decimal128(123.456))
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setOptObjectId == %@)", ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695046")), count: 1) {
            $0.setOptObjectId == ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695046"))
        }
        assertQuery(CustomPersistableCollections.self, "(ANY setOptUuid == %@)", UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!), count: 1) {
            $0.setOptUuid == UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!)
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

        assertQuery("((intCol == %@) && (SUBQUERY(setCol, $col1, ($col1.stringCol == %@)).@count == %@))", values: [3, "Bar", 0], count: 1) {
            ($0.intCol == 3) &&
            ($0.setCol.stringCol == "Bar").count == 0
        }

        assertQuery("((intCol == %@) && (SUBQUERY(setCol, $col1, (($col1.intCol == %@) && ($col1.stringCol != %@))).@count == %@))", values: [3, 5, "Blah", 1], count: 1) {
            ($0.intCol == 3) &&
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
            where T.Element.PersistedType: _QueryNumeric, T.Element: QueryValue {
        assertQuery(Root.self, "(object.\(name).@avg == %@)", average, count: 1) {
            lhs($0).avg == average
        }
        assertQuery(Root.self, "(object.\(name).@avg == %@)", min, count: 0) {
            lhs($0).avg == min
        }
        assertQuery(Root.self, "(object.\(name).@avg != %@)", average, count: 0) {
            lhs($0).avg != average
        }
        assertQuery(Root.self, "(object.\(name).@avg != %@)", min, count: 1) {
            lhs($0).avg != min
        }
        assertQuery(Root.self, "(object.\(name).@avg > %@)", average, count: 0) {
            lhs($0).avg > average
        }
        assertQuery(Root.self, "(object.\(name).@avg > %@)", min, count: 1) {
            lhs($0).avg > min
        }
        assertQuery(Root.self, "(object.\(name).@avg < %@)", average, count: 0) {
            lhs($0).avg < average
        }
        assertQuery(Root.self, "(object.\(name).@avg >= %@)", average, count: 1) {
            lhs($0).avg >= average
        }
        assertQuery(Root.self, "(object.\(name).@avg <= %@)", average, count: 1) {
            lhs($0).avg <= average
        }
    }

    private func validateAverage<Root: Object, T: RealmKeyedCollection>(_ name: String, _ average: T.Value, _ min: T.Value, _ lhs: (Query<Root>) -> Query<T>)
            where T.Value.PersistedType: _QueryNumeric, T.Value: QueryValue {
        assertQuery(Root.self, "(object.\(name).@avg == %@)", average, count: 1) {
            lhs($0).avg == average
        }
        assertQuery(Root.self, "(object.\(name).@avg == %@)", min, count: 0) {
            lhs($0).avg == min
        }
        assertQuery(Root.self, "(object.\(name).@avg != %@)", average, count: 0) {
            lhs($0).avg != average
        }
        assertQuery(Root.self, "(object.\(name).@avg != %@)", min, count: 1) {
            lhs($0).avg != min
        }
        assertQuery(Root.self, "(object.\(name).@avg > %@)", average, count: 0) {
            lhs($0).avg > average
        }
        assertQuery(Root.self, "(object.\(name).@avg > %@)", min, count: 1) {
            lhs($0).avg > min
        }
        assertQuery(Root.self, "(object.\(name).@avg < %@)", average, count: 0) {
            lhs($0).avg < average
        }
        assertQuery(Root.self, "(object.\(name).@avg >= %@)", average, count: 1) {
            lhs($0).avg >= average
        }
        assertQuery(Root.self, "(object.\(name).@avg <= %@)", average, count: 1) {
            lhs($0).avg <= average
        }
    }

    func testCollectionAggregatesAvg() {
        initLinkedCollectionAggregatesObject()

        validateAverage("arrayInt", Int.average(), 1,
                    \Query<LinkToModernAllTypesObject>.object.arrayInt)
        validateAverage("arrayInt8", Int8.average(), Int8(8),
                    \Query<LinkToModernAllTypesObject>.object.arrayInt8)
        validateAverage("arrayInt16", Int16.average(), Int16(16),
                    \Query<LinkToModernAllTypesObject>.object.arrayInt16)
        validateAverage("arrayInt32", Int32.average(), Int32(32),
                    \Query<LinkToModernAllTypesObject>.object.arrayInt32)
        validateAverage("arrayInt64", Int64.average(), Int64(64),
                    \Query<LinkToModernAllTypesObject>.object.arrayInt64)
        validateAverage("arrayFloat", Float.average(), Float(5.55444333),
                    \Query<LinkToModernAllTypesObject>.object.arrayFloat)
        validateAverage("arrayDouble", Double.average(), 123.456,
                    \Query<LinkToModernAllTypesObject>.object.arrayDouble)
        validateAverage("arrayDecimal", Decimal128.average(), Decimal128(123.456),
                    \Query<LinkToModernAllTypesObject>.object.arrayDecimal)
        validateAverage("listInt", EnumInt.average(), EnumInt.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.listInt.rawValue)
        validateAverage("listInt8", EnumInt8.average(), EnumInt8.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.listInt8.rawValue)
        validateAverage("listInt16", EnumInt16.average(), EnumInt16.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.listInt16.rawValue)
        validateAverage("listInt32", EnumInt32.average(), EnumInt32.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.listInt32.rawValue)
        validateAverage("listInt64", EnumInt64.average(), EnumInt64.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.listInt64.rawValue)
        validateAverage("listDouble", EnumDouble.average(), EnumDouble.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.listDouble.rawValue)
        validateAverage("listInt", IntWrapper.average(), IntWrapper(persistedValue: 1),
                    \Query<LinkToCustomPersistableCollections>.object.listInt)
        validateAverage("listInt8", Int8Wrapper.average(), Int8Wrapper(persistedValue: Int8(8)),
                    \Query<LinkToCustomPersistableCollections>.object.listInt8)
        validateAverage("listInt16", Int16Wrapper.average(), Int16Wrapper(persistedValue: Int16(16)),
                    \Query<LinkToCustomPersistableCollections>.object.listInt16)
        validateAverage("listInt32", Int32Wrapper.average(), Int32Wrapper(persistedValue: Int32(32)),
                    \Query<LinkToCustomPersistableCollections>.object.listInt32)
        validateAverage("listInt64", Int64Wrapper.average(), Int64Wrapper(persistedValue: Int64(64)),
                    \Query<LinkToCustomPersistableCollections>.object.listInt64)
        validateAverage("listFloat", FloatWrapper.average(), FloatWrapper(persistedValue: Float(5.55444333)),
                    \Query<LinkToCustomPersistableCollections>.object.listFloat)
        validateAverage("listDouble", DoubleWrapper.average(), DoubleWrapper(persistedValue: 123.456),
                    \Query<LinkToCustomPersistableCollections>.object.listDouble)
        validateAverage("listDecimal", Decimal128Wrapper.average(), Decimal128Wrapper(persistedValue: Decimal128(123.456)),
                    \Query<LinkToCustomPersistableCollections>.object.listDecimal)
        validateAverage("arrayOptInt", Int?.average(), 1,
                    \Query<LinkToModernAllTypesObject>.object.arrayOptInt)
        validateAverage("arrayOptInt8", Int8?.average(), Int8(8),
                    \Query<LinkToModernAllTypesObject>.object.arrayOptInt8)
        validateAverage("arrayOptInt16", Int16?.average(), Int16(16),
                    \Query<LinkToModernAllTypesObject>.object.arrayOptInt16)
        validateAverage("arrayOptInt32", Int32?.average(), Int32(32),
                    \Query<LinkToModernAllTypesObject>.object.arrayOptInt32)
        validateAverage("arrayOptInt64", Int64?.average(), Int64(64),
                    \Query<LinkToModernAllTypesObject>.object.arrayOptInt64)
        validateAverage("arrayOptFloat", Float?.average(), Float(5.55444333),
                    \Query<LinkToModernAllTypesObject>.object.arrayOptFloat)
        validateAverage("arrayOptDouble", Double?.average(), 123.456,
                    \Query<LinkToModernAllTypesObject>.object.arrayOptDouble)
        validateAverage("arrayOptDecimal", Decimal128?.average(), Decimal128(123.456),
                    \Query<LinkToModernAllTypesObject>.object.arrayOptDecimal)
        validateAverage("listIntOpt", EnumInt?.average(), EnumInt.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.listIntOpt.rawValue)
        validateAverage("listInt8Opt", EnumInt8?.average(), EnumInt8.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.listInt8Opt.rawValue)
        validateAverage("listInt16Opt", EnumInt16?.average(), EnumInt16.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.listInt16Opt.rawValue)
        validateAverage("listInt32Opt", EnumInt32?.average(), EnumInt32.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.listInt32Opt.rawValue)
        validateAverage("listInt64Opt", EnumInt64?.average(), EnumInt64.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.listInt64Opt.rawValue)
        validateAverage("listDoubleOpt", EnumDouble?.average(), EnumDouble.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.listDoubleOpt.rawValue)
        validateAverage("listOptInt", IntWrapper?.average(), IntWrapper(persistedValue: 1),
                    \Query<LinkToCustomPersistableCollections>.object.listOptInt)
        validateAverage("listOptInt8", Int8Wrapper?.average(), Int8Wrapper(persistedValue: Int8(8)),
                    \Query<LinkToCustomPersistableCollections>.object.listOptInt8)
        validateAverage("listOptInt16", Int16Wrapper?.average(), Int16Wrapper(persistedValue: Int16(16)),
                    \Query<LinkToCustomPersistableCollections>.object.listOptInt16)
        validateAverage("listOptInt32", Int32Wrapper?.average(), Int32Wrapper(persistedValue: Int32(32)),
                    \Query<LinkToCustomPersistableCollections>.object.listOptInt32)
        validateAverage("listOptInt64", Int64Wrapper?.average(), Int64Wrapper(persistedValue: Int64(64)),
                    \Query<LinkToCustomPersistableCollections>.object.listOptInt64)
        validateAverage("listOptFloat", FloatWrapper?.average(), FloatWrapper(persistedValue: Float(5.55444333)),
                    \Query<LinkToCustomPersistableCollections>.object.listOptFloat)
        validateAverage("listOptDouble", DoubleWrapper?.average(), DoubleWrapper(persistedValue: 123.456),
                    \Query<LinkToCustomPersistableCollections>.object.listOptDouble)
        validateAverage("listOptDecimal", Decimal128Wrapper?.average(), Decimal128Wrapper(persistedValue: Decimal128(123.456)),
                    \Query<LinkToCustomPersistableCollections>.object.listOptDecimal)
        validateAverage("setInt", Int.average(), 1,
                    \Query<LinkToModernAllTypesObject>.object.setInt)
        validateAverage("setInt8", Int8.average(), Int8(8),
                    \Query<LinkToModernAllTypesObject>.object.setInt8)
        validateAverage("setInt16", Int16.average(), Int16(16),
                    \Query<LinkToModernAllTypesObject>.object.setInt16)
        validateAverage("setInt32", Int32.average(), Int32(32),
                    \Query<LinkToModernAllTypesObject>.object.setInt32)
        validateAverage("setInt64", Int64.average(), Int64(64),
                    \Query<LinkToModernAllTypesObject>.object.setInt64)
        validateAverage("setFloat", Float.average(), Float(5.55444333),
                    \Query<LinkToModernAllTypesObject>.object.setFloat)
        validateAverage("setDouble", Double.average(), 123.456,
                    \Query<LinkToModernAllTypesObject>.object.setDouble)
        validateAverage("setDecimal", Decimal128.average(), Decimal128(123.456),
                    \Query<LinkToModernAllTypesObject>.object.setDecimal)
        validateAverage("setInt", EnumInt.average(), EnumInt.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.setInt.rawValue)
        validateAverage("setInt8", EnumInt8.average(), EnumInt8.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.setInt8.rawValue)
        validateAverage("setInt16", EnumInt16.average(), EnumInt16.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.setInt16.rawValue)
        validateAverage("setInt32", EnumInt32.average(), EnumInt32.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.setInt32.rawValue)
        validateAverage("setInt64", EnumInt64.average(), EnumInt64.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.setInt64.rawValue)
        validateAverage("setDouble", EnumDouble.average(), EnumDouble.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.setDouble.rawValue)
        validateAverage("setInt", IntWrapper.average(), IntWrapper(persistedValue: 1),
                    \Query<LinkToCustomPersistableCollections>.object.setInt)
        validateAverage("setInt8", Int8Wrapper.average(), Int8Wrapper(persistedValue: Int8(8)),
                    \Query<LinkToCustomPersistableCollections>.object.setInt8)
        validateAverage("setInt16", Int16Wrapper.average(), Int16Wrapper(persistedValue: Int16(16)),
                    \Query<LinkToCustomPersistableCollections>.object.setInt16)
        validateAverage("setInt32", Int32Wrapper.average(), Int32Wrapper(persistedValue: Int32(32)),
                    \Query<LinkToCustomPersistableCollections>.object.setInt32)
        validateAverage("setInt64", Int64Wrapper.average(), Int64Wrapper(persistedValue: Int64(64)),
                    \Query<LinkToCustomPersistableCollections>.object.setInt64)
        validateAverage("setFloat", FloatWrapper.average(), FloatWrapper(persistedValue: Float(5.55444333)),
                    \Query<LinkToCustomPersistableCollections>.object.setFloat)
        validateAverage("setDouble", DoubleWrapper.average(), DoubleWrapper(persistedValue: 123.456),
                    \Query<LinkToCustomPersistableCollections>.object.setDouble)
        validateAverage("setDecimal", Decimal128Wrapper.average(), Decimal128Wrapper(persistedValue: Decimal128(123.456)),
                    \Query<LinkToCustomPersistableCollections>.object.setDecimal)
        validateAverage("setOptInt", Int?.average(), 1,
                    \Query<LinkToModernAllTypesObject>.object.setOptInt)
        validateAverage("setOptInt8", Int8?.average(), Int8(8),
                    \Query<LinkToModernAllTypesObject>.object.setOptInt8)
        validateAverage("setOptInt16", Int16?.average(), Int16(16),
                    \Query<LinkToModernAllTypesObject>.object.setOptInt16)
        validateAverage("setOptInt32", Int32?.average(), Int32(32),
                    \Query<LinkToModernAllTypesObject>.object.setOptInt32)
        validateAverage("setOptInt64", Int64?.average(), Int64(64),
                    \Query<LinkToModernAllTypesObject>.object.setOptInt64)
        validateAverage("setOptFloat", Float?.average(), Float(5.55444333),
                    \Query<LinkToModernAllTypesObject>.object.setOptFloat)
        validateAverage("setOptDouble", Double?.average(), 123.456,
                    \Query<LinkToModernAllTypesObject>.object.setOptDouble)
        validateAverage("setOptDecimal", Decimal128?.average(), Decimal128(123.456),
                    \Query<LinkToModernAllTypesObject>.object.setOptDecimal)
        validateAverage("setIntOpt", EnumInt?.average(), EnumInt.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.setIntOpt.rawValue)
        validateAverage("setInt8Opt", EnumInt8?.average(), EnumInt8.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.setInt8Opt.rawValue)
        validateAverage("setInt16Opt", EnumInt16?.average(), EnumInt16.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.setInt16Opt.rawValue)
        validateAverage("setInt32Opt", EnumInt32?.average(), EnumInt32.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.setInt32Opt.rawValue)
        validateAverage("setInt64Opt", EnumInt64?.average(), EnumInt64.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.setInt64Opt.rawValue)
        validateAverage("setDoubleOpt", EnumDouble?.average(), EnumDouble.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.setDoubleOpt.rawValue)
        validateAverage("setOptInt", IntWrapper?.average(), IntWrapper(persistedValue: 1),
                    \Query<LinkToCustomPersistableCollections>.object.setOptInt)
        validateAverage("setOptInt8", Int8Wrapper?.average(), Int8Wrapper(persistedValue: Int8(8)),
                    \Query<LinkToCustomPersistableCollections>.object.setOptInt8)
        validateAverage("setOptInt16", Int16Wrapper?.average(), Int16Wrapper(persistedValue: Int16(16)),
                    \Query<LinkToCustomPersistableCollections>.object.setOptInt16)
        validateAverage("setOptInt32", Int32Wrapper?.average(), Int32Wrapper(persistedValue: Int32(32)),
                    \Query<LinkToCustomPersistableCollections>.object.setOptInt32)
        validateAverage("setOptInt64", Int64Wrapper?.average(), Int64Wrapper(persistedValue: Int64(64)),
                    \Query<LinkToCustomPersistableCollections>.object.setOptInt64)
        validateAverage("setOptFloat", FloatWrapper?.average(), FloatWrapper(persistedValue: Float(5.55444333)),
                    \Query<LinkToCustomPersistableCollections>.object.setOptFloat)
        validateAverage("setOptDouble", DoubleWrapper?.average(), DoubleWrapper(persistedValue: 123.456),
                    \Query<LinkToCustomPersistableCollections>.object.setOptDouble)
        validateAverage("setOptDecimal", Decimal128Wrapper?.average(), Decimal128Wrapper(persistedValue: Decimal128(123.456)),
                    \Query<LinkToCustomPersistableCollections>.object.setOptDecimal)
        validateAverage("mapInt", Int.average(), 1,
                    \Query<LinkToModernAllTypesObject>.object.mapInt)
        validateAverage("mapInt8", Int8.average(), Int8(8),
                    \Query<LinkToModernAllTypesObject>.object.mapInt8)
        validateAverage("mapInt16", Int16.average(), Int16(16),
                    \Query<LinkToModernAllTypesObject>.object.mapInt16)
        validateAverage("mapInt32", Int32.average(), Int32(32),
                    \Query<LinkToModernAllTypesObject>.object.mapInt32)
        validateAverage("mapInt64", Int64.average(), Int64(64),
                    \Query<LinkToModernAllTypesObject>.object.mapInt64)
        validateAverage("mapFloat", Float.average(), Float(5.55444333),
                    \Query<LinkToModernAllTypesObject>.object.mapFloat)
        validateAverage("mapDouble", Double.average(), 123.456,
                    \Query<LinkToModernAllTypesObject>.object.mapDouble)
        validateAverage("mapDecimal", Decimal128.average(), Decimal128(123.456),
                    \Query<LinkToModernAllTypesObject>.object.mapDecimal)
        validateAverage("mapInt", EnumInt.average(), EnumInt.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapInt.rawValue)
        validateAverage("mapInt8", EnumInt8.average(), EnumInt8.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapInt8.rawValue)
        validateAverage("mapInt16", EnumInt16.average(), EnumInt16.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapInt16.rawValue)
        validateAverage("mapInt32", EnumInt32.average(), EnumInt32.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapInt32.rawValue)
        validateAverage("mapInt64", EnumInt64.average(), EnumInt64.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapInt64.rawValue)
        validateAverage("mapDouble", EnumDouble.average(), EnumDouble.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapDouble.rawValue)
        validateAverage("mapInt", IntWrapper.average(), IntWrapper(persistedValue: 1),
                    \Query<LinkToCustomPersistableCollections>.object.mapInt)
        validateAverage("mapInt8", Int8Wrapper.average(), Int8Wrapper(persistedValue: Int8(8)),
                    \Query<LinkToCustomPersistableCollections>.object.mapInt8)
        validateAverage("mapInt16", Int16Wrapper.average(), Int16Wrapper(persistedValue: Int16(16)),
                    \Query<LinkToCustomPersistableCollections>.object.mapInt16)
        validateAverage("mapInt32", Int32Wrapper.average(), Int32Wrapper(persistedValue: Int32(32)),
                    \Query<LinkToCustomPersistableCollections>.object.mapInt32)
        validateAverage("mapInt64", Int64Wrapper.average(), Int64Wrapper(persistedValue: Int64(64)),
                    \Query<LinkToCustomPersistableCollections>.object.mapInt64)
        validateAverage("mapFloat", FloatWrapper.average(), FloatWrapper(persistedValue: Float(5.55444333)),
                    \Query<LinkToCustomPersistableCollections>.object.mapFloat)
        validateAverage("mapDouble", DoubleWrapper.average(), DoubleWrapper(persistedValue: 123.456),
                    \Query<LinkToCustomPersistableCollections>.object.mapDouble)
        validateAverage("mapDecimal", Decimal128Wrapper.average(), Decimal128Wrapper(persistedValue: Decimal128(123.456)),
                    \Query<LinkToCustomPersistableCollections>.object.mapDecimal)
        validateAverage("mapOptInt", Int?.average(), 1,
                    \Query<LinkToModernAllTypesObject>.object.mapOptInt)
        validateAverage("mapOptInt8", Int8?.average(), Int8(8),
                    \Query<LinkToModernAllTypesObject>.object.mapOptInt8)
        validateAverage("mapOptInt16", Int16?.average(), Int16(16),
                    \Query<LinkToModernAllTypesObject>.object.mapOptInt16)
        validateAverage("mapOptInt32", Int32?.average(), Int32(32),
                    \Query<LinkToModernAllTypesObject>.object.mapOptInt32)
        validateAverage("mapOptInt64", Int64?.average(), Int64(64),
                    \Query<LinkToModernAllTypesObject>.object.mapOptInt64)
        validateAverage("mapOptFloat", Float?.average(), Float(5.55444333),
                    \Query<LinkToModernAllTypesObject>.object.mapOptFloat)
        validateAverage("mapOptDouble", Double?.average(), 123.456,
                    \Query<LinkToModernAllTypesObject>.object.mapOptDouble)
        validateAverage("mapOptDecimal", Decimal128?.average(), Decimal128(123.456),
                    \Query<LinkToModernAllTypesObject>.object.mapOptDecimal)
        validateAverage("mapIntOpt", EnumInt?.average(), EnumInt.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapIntOpt.rawValue)
        validateAverage("mapInt8Opt", EnumInt8?.average(), EnumInt8.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapInt8Opt.rawValue)
        validateAverage("mapInt16Opt", EnumInt16?.average(), EnumInt16.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapInt16Opt.rawValue)
        validateAverage("mapInt32Opt", EnumInt32?.average(), EnumInt32.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapInt32Opt.rawValue)
        validateAverage("mapInt64Opt", EnumInt64?.average(), EnumInt64.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapInt64Opt.rawValue)
        validateAverage("mapDoubleOpt", EnumDouble?.average(), EnumDouble.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapDoubleOpt.rawValue)
        validateAverage("mapOptInt", IntWrapper?.average(), IntWrapper(persistedValue: 1),
                    \Query<LinkToCustomPersistableCollections>.object.mapOptInt)
        validateAverage("mapOptInt8", Int8Wrapper?.average(), Int8Wrapper(persistedValue: Int8(8)),
                    \Query<LinkToCustomPersistableCollections>.object.mapOptInt8)
        validateAverage("mapOptInt16", Int16Wrapper?.average(), Int16Wrapper(persistedValue: Int16(16)),
                    \Query<LinkToCustomPersistableCollections>.object.mapOptInt16)
        validateAverage("mapOptInt32", Int32Wrapper?.average(), Int32Wrapper(persistedValue: Int32(32)),
                    \Query<LinkToCustomPersistableCollections>.object.mapOptInt32)
        validateAverage("mapOptInt64", Int64Wrapper?.average(), Int64Wrapper(persistedValue: Int64(64)),
                    \Query<LinkToCustomPersistableCollections>.object.mapOptInt64)
        validateAverage("mapOptFloat", FloatWrapper?.average(), FloatWrapper(persistedValue: Float(5.55444333)),
                    \Query<LinkToCustomPersistableCollections>.object.mapOptFloat)
        validateAverage("mapOptDouble", DoubleWrapper?.average(), DoubleWrapper(persistedValue: 123.456),
                    \Query<LinkToCustomPersistableCollections>.object.mapOptDouble)
        validateAverage("mapOptDecimal", Decimal128Wrapper?.average(), Decimal128Wrapper(persistedValue: Decimal128(123.456)),
                    \Query<LinkToCustomPersistableCollections>.object.mapOptDecimal)
    }

    private func validateSum<Root: Object, T: RealmCollection>(_ name: String, _ sum: T.Element, _ min: T.Element, _ lhs: (Query<Root>) -> Query<T>)
            where T.Element.PersistedType: _QueryNumeric, T.Element: QueryValue {
        assertQuery(Root.self, "(object.\(name).@sum == %@)", sum, count: 1) {
            lhs($0).sum == sum
        }
        assertQuery(Root.self, "(object.\(name).@sum == %@)", min, count: 0) {
            lhs($0).sum == min
        }
        assertQuery(Root.self, "(object.\(name).@sum != %@)", sum, count: 0) {
            lhs($0).sum != sum
        }
        assertQuery(Root.self, "(object.\(name).@sum != %@)", min, count: 1) {
            lhs($0).sum != min
        }
        assertQuery(Root.self, "(object.\(name).@sum > %@)", sum, count: 0) {
            lhs($0).sum > sum
        }
        assertQuery(Root.self, "(object.\(name).@sum > %@)", min, count: 1) {
            lhs($0).sum > min
        }
        assertQuery(Root.self, "(object.\(name).@sum < %@)", sum, count: 0) {
            lhs($0).sum < sum
        }
        assertQuery(Root.self, "(object.\(name).@sum >= %@)", sum, count: 1) {
            lhs($0).sum >= sum
        }
        assertQuery(Root.self, "(object.\(name).@sum <= %@)", sum, count: 1) {
            lhs($0).sum <= sum
        }
    }

    private func validateSum<Root: Object, T: RealmKeyedCollection>(_ name: String, _ sum: T.Value, _ min: T.Value, _ lhs: (Query<Root>) -> Query<T>)
            where T.Value.PersistedType: _QueryNumeric, T.Value: QueryValue {
        assertQuery(Root.self, "(object.\(name).@sum == %@)", sum, count: 1) {
            lhs($0).sum == sum
        }
        assertQuery(Root.self, "(object.\(name).@sum == %@)", min, count: 0) {
            lhs($0).sum == min
        }
        assertQuery(Root.self, "(object.\(name).@sum != %@)", sum, count: 0) {
            lhs($0).sum != sum
        }
        assertQuery(Root.self, "(object.\(name).@sum != %@)", min, count: 1) {
            lhs($0).sum != min
        }
        assertQuery(Root.self, "(object.\(name).@sum > %@)", sum, count: 0) {
            lhs($0).sum > sum
        }
        assertQuery(Root.self, "(object.\(name).@sum > %@)", min, count: 1) {
            lhs($0).sum > min
        }
        assertQuery(Root.self, "(object.\(name).@sum < %@)", sum, count: 0) {
            lhs($0).sum < sum
        }
        assertQuery(Root.self, "(object.\(name).@sum >= %@)", sum, count: 1) {
            lhs($0).sum >= sum
        }
        assertQuery(Root.self, "(object.\(name).@sum <= %@)", sum, count: 1) {
            lhs($0).sum <= sum
        }
    }

    func testCollectionAggregatesSum() {
        initLinkedCollectionAggregatesObject()

        validateSum("arrayInt", Int.sum(), 1,
                    \Query<LinkToModernAllTypesObject>.object.arrayInt)
        validateSum("arrayInt8", Int8.sum(), Int8(8),
                    \Query<LinkToModernAllTypesObject>.object.arrayInt8)
        validateSum("arrayInt16", Int16.sum(), Int16(16),
                    \Query<LinkToModernAllTypesObject>.object.arrayInt16)
        validateSum("arrayInt32", Int32.sum(), Int32(32),
                    \Query<LinkToModernAllTypesObject>.object.arrayInt32)
        validateSum("arrayInt64", Int64.sum(), Int64(64),
                    \Query<LinkToModernAllTypesObject>.object.arrayInt64)
        validateSum("arrayFloat", Float.sum(), Float(5.55444333),
                    \Query<LinkToModernAllTypesObject>.object.arrayFloat)
        validateSum("arrayDouble", Double.sum(), 123.456,
                    \Query<LinkToModernAllTypesObject>.object.arrayDouble)
        validateSum("arrayDecimal", Decimal128.sum(), Decimal128(123.456),
                    \Query<LinkToModernAllTypesObject>.object.arrayDecimal)
        validateSum("listInt", EnumInt.sum(), EnumInt.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.listInt.rawValue)
        validateSum("listInt8", EnumInt8.sum(), EnumInt8.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.listInt8.rawValue)
        validateSum("listInt16", EnumInt16.sum(), EnumInt16.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.listInt16.rawValue)
        validateSum("listInt32", EnumInt32.sum(), EnumInt32.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.listInt32.rawValue)
        validateSum("listInt64", EnumInt64.sum(), EnumInt64.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.listInt64.rawValue)
        validateSum("listDouble", EnumDouble.sum(), EnumDouble.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.listDouble.rawValue)
        validateSum("listInt", IntWrapper.sum(), IntWrapper(persistedValue: 1),
                    \Query<LinkToCustomPersistableCollections>.object.listInt)
        validateSum("listInt8", Int8Wrapper.sum(), Int8Wrapper(persistedValue: Int8(8)),
                    \Query<LinkToCustomPersistableCollections>.object.listInt8)
        validateSum("listInt16", Int16Wrapper.sum(), Int16Wrapper(persistedValue: Int16(16)),
                    \Query<LinkToCustomPersistableCollections>.object.listInt16)
        validateSum("listInt32", Int32Wrapper.sum(), Int32Wrapper(persistedValue: Int32(32)),
                    \Query<LinkToCustomPersistableCollections>.object.listInt32)
        validateSum("listInt64", Int64Wrapper.sum(), Int64Wrapper(persistedValue: Int64(64)),
                    \Query<LinkToCustomPersistableCollections>.object.listInt64)
        validateSum("listFloat", FloatWrapper.sum(), FloatWrapper(persistedValue: Float(5.55444333)),
                    \Query<LinkToCustomPersistableCollections>.object.listFloat)
        validateSum("listDouble", DoubleWrapper.sum(), DoubleWrapper(persistedValue: 123.456),
                    \Query<LinkToCustomPersistableCollections>.object.listDouble)
        validateSum("listDecimal", Decimal128Wrapper.sum(), Decimal128Wrapper(persistedValue: Decimal128(123.456)),
                    \Query<LinkToCustomPersistableCollections>.object.listDecimal)
        validateSum("arrayOptInt", Int?.sum(), 1,
                    \Query<LinkToModernAllTypesObject>.object.arrayOptInt)
        validateSum("arrayOptInt8", Int8?.sum(), Int8(8),
                    \Query<LinkToModernAllTypesObject>.object.arrayOptInt8)
        validateSum("arrayOptInt16", Int16?.sum(), Int16(16),
                    \Query<LinkToModernAllTypesObject>.object.arrayOptInt16)
        validateSum("arrayOptInt32", Int32?.sum(), Int32(32),
                    \Query<LinkToModernAllTypesObject>.object.arrayOptInt32)
        validateSum("arrayOptInt64", Int64?.sum(), Int64(64),
                    \Query<LinkToModernAllTypesObject>.object.arrayOptInt64)
        validateSum("arrayOptFloat", Float?.sum(), Float(5.55444333),
                    \Query<LinkToModernAllTypesObject>.object.arrayOptFloat)
        validateSum("arrayOptDouble", Double?.sum(), 123.456,
                    \Query<LinkToModernAllTypesObject>.object.arrayOptDouble)
        validateSum("arrayOptDecimal", Decimal128?.sum(), Decimal128(123.456),
                    \Query<LinkToModernAllTypesObject>.object.arrayOptDecimal)
        validateSum("listIntOpt", EnumInt?.sum(), EnumInt.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.listIntOpt.rawValue)
        validateSum("listInt8Opt", EnumInt8?.sum(), EnumInt8.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.listInt8Opt.rawValue)
        validateSum("listInt16Opt", EnumInt16?.sum(), EnumInt16.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.listInt16Opt.rawValue)
        validateSum("listInt32Opt", EnumInt32?.sum(), EnumInt32.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.listInt32Opt.rawValue)
        validateSum("listInt64Opt", EnumInt64?.sum(), EnumInt64.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.listInt64Opt.rawValue)
        validateSum("listDoubleOpt", EnumDouble?.sum(), EnumDouble.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.listDoubleOpt.rawValue)
        validateSum("listOptInt", IntWrapper?.sum(), IntWrapper(persistedValue: 1),
                    \Query<LinkToCustomPersistableCollections>.object.listOptInt)
        validateSum("listOptInt8", Int8Wrapper?.sum(), Int8Wrapper(persistedValue: Int8(8)),
                    \Query<LinkToCustomPersistableCollections>.object.listOptInt8)
        validateSum("listOptInt16", Int16Wrapper?.sum(), Int16Wrapper(persistedValue: Int16(16)),
                    \Query<LinkToCustomPersistableCollections>.object.listOptInt16)
        validateSum("listOptInt32", Int32Wrapper?.sum(), Int32Wrapper(persistedValue: Int32(32)),
                    \Query<LinkToCustomPersistableCollections>.object.listOptInt32)
        validateSum("listOptInt64", Int64Wrapper?.sum(), Int64Wrapper(persistedValue: Int64(64)),
                    \Query<LinkToCustomPersistableCollections>.object.listOptInt64)
        validateSum("listOptFloat", FloatWrapper?.sum(), FloatWrapper(persistedValue: Float(5.55444333)),
                    \Query<LinkToCustomPersistableCollections>.object.listOptFloat)
        validateSum("listOptDouble", DoubleWrapper?.sum(), DoubleWrapper(persistedValue: 123.456),
                    \Query<LinkToCustomPersistableCollections>.object.listOptDouble)
        validateSum("listOptDecimal", Decimal128Wrapper?.sum(), Decimal128Wrapper(persistedValue: Decimal128(123.456)),
                    \Query<LinkToCustomPersistableCollections>.object.listOptDecimal)
        validateSum("setInt", Int.sum(), 1,
                    \Query<LinkToModernAllTypesObject>.object.setInt)
        validateSum("setInt8", Int8.sum(), Int8(8),
                    \Query<LinkToModernAllTypesObject>.object.setInt8)
        validateSum("setInt16", Int16.sum(), Int16(16),
                    \Query<LinkToModernAllTypesObject>.object.setInt16)
        validateSum("setInt32", Int32.sum(), Int32(32),
                    \Query<LinkToModernAllTypesObject>.object.setInt32)
        validateSum("setInt64", Int64.sum(), Int64(64),
                    \Query<LinkToModernAllTypesObject>.object.setInt64)
        validateSum("setFloat", Float.sum(), Float(5.55444333),
                    \Query<LinkToModernAllTypesObject>.object.setFloat)
        validateSum("setDouble", Double.sum(), 123.456,
                    \Query<LinkToModernAllTypesObject>.object.setDouble)
        validateSum("setDecimal", Decimal128.sum(), Decimal128(123.456),
                    \Query<LinkToModernAllTypesObject>.object.setDecimal)
        validateSum("setInt", EnumInt.sum(), EnumInt.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.setInt.rawValue)
        validateSum("setInt8", EnumInt8.sum(), EnumInt8.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.setInt8.rawValue)
        validateSum("setInt16", EnumInt16.sum(), EnumInt16.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.setInt16.rawValue)
        validateSum("setInt32", EnumInt32.sum(), EnumInt32.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.setInt32.rawValue)
        validateSum("setInt64", EnumInt64.sum(), EnumInt64.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.setInt64.rawValue)
        validateSum("setDouble", EnumDouble.sum(), EnumDouble.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.setDouble.rawValue)
        validateSum("setInt", IntWrapper.sum(), IntWrapper(persistedValue: 1),
                    \Query<LinkToCustomPersistableCollections>.object.setInt)
        validateSum("setInt8", Int8Wrapper.sum(), Int8Wrapper(persistedValue: Int8(8)),
                    \Query<LinkToCustomPersistableCollections>.object.setInt8)
        validateSum("setInt16", Int16Wrapper.sum(), Int16Wrapper(persistedValue: Int16(16)),
                    \Query<LinkToCustomPersistableCollections>.object.setInt16)
        validateSum("setInt32", Int32Wrapper.sum(), Int32Wrapper(persistedValue: Int32(32)),
                    \Query<LinkToCustomPersistableCollections>.object.setInt32)
        validateSum("setInt64", Int64Wrapper.sum(), Int64Wrapper(persistedValue: Int64(64)),
                    \Query<LinkToCustomPersistableCollections>.object.setInt64)
        validateSum("setFloat", FloatWrapper.sum(), FloatWrapper(persistedValue: Float(5.55444333)),
                    \Query<LinkToCustomPersistableCollections>.object.setFloat)
        validateSum("setDouble", DoubleWrapper.sum(), DoubleWrapper(persistedValue: 123.456),
                    \Query<LinkToCustomPersistableCollections>.object.setDouble)
        validateSum("setDecimal", Decimal128Wrapper.sum(), Decimal128Wrapper(persistedValue: Decimal128(123.456)),
                    \Query<LinkToCustomPersistableCollections>.object.setDecimal)
        validateSum("setOptInt", Int?.sum(), 1,
                    \Query<LinkToModernAllTypesObject>.object.setOptInt)
        validateSum("setOptInt8", Int8?.sum(), Int8(8),
                    \Query<LinkToModernAllTypesObject>.object.setOptInt8)
        validateSum("setOptInt16", Int16?.sum(), Int16(16),
                    \Query<LinkToModernAllTypesObject>.object.setOptInt16)
        validateSum("setOptInt32", Int32?.sum(), Int32(32),
                    \Query<LinkToModernAllTypesObject>.object.setOptInt32)
        validateSum("setOptInt64", Int64?.sum(), Int64(64),
                    \Query<LinkToModernAllTypesObject>.object.setOptInt64)
        validateSum("setOptFloat", Float?.sum(), Float(5.55444333),
                    \Query<LinkToModernAllTypesObject>.object.setOptFloat)
        validateSum("setOptDouble", Double?.sum(), 123.456,
                    \Query<LinkToModernAllTypesObject>.object.setOptDouble)
        validateSum("setOptDecimal", Decimal128?.sum(), Decimal128(123.456),
                    \Query<LinkToModernAllTypesObject>.object.setOptDecimal)
        validateSum("setIntOpt", EnumInt?.sum(), EnumInt.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.setIntOpt.rawValue)
        validateSum("setInt8Opt", EnumInt8?.sum(), EnumInt8.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.setInt8Opt.rawValue)
        validateSum("setInt16Opt", EnumInt16?.sum(), EnumInt16.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.setInt16Opt.rawValue)
        validateSum("setInt32Opt", EnumInt32?.sum(), EnumInt32.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.setInt32Opt.rawValue)
        validateSum("setInt64Opt", EnumInt64?.sum(), EnumInt64.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.setInt64Opt.rawValue)
        validateSum("setDoubleOpt", EnumDouble?.sum(), EnumDouble.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.setDoubleOpt.rawValue)
        validateSum("setOptInt", IntWrapper?.sum(), IntWrapper(persistedValue: 1),
                    \Query<LinkToCustomPersistableCollections>.object.setOptInt)
        validateSum("setOptInt8", Int8Wrapper?.sum(), Int8Wrapper(persistedValue: Int8(8)),
                    \Query<LinkToCustomPersistableCollections>.object.setOptInt8)
        validateSum("setOptInt16", Int16Wrapper?.sum(), Int16Wrapper(persistedValue: Int16(16)),
                    \Query<LinkToCustomPersistableCollections>.object.setOptInt16)
        validateSum("setOptInt32", Int32Wrapper?.sum(), Int32Wrapper(persistedValue: Int32(32)),
                    \Query<LinkToCustomPersistableCollections>.object.setOptInt32)
        validateSum("setOptInt64", Int64Wrapper?.sum(), Int64Wrapper(persistedValue: Int64(64)),
                    \Query<LinkToCustomPersistableCollections>.object.setOptInt64)
        validateSum("setOptFloat", FloatWrapper?.sum(), FloatWrapper(persistedValue: Float(5.55444333)),
                    \Query<LinkToCustomPersistableCollections>.object.setOptFloat)
        validateSum("setOptDouble", DoubleWrapper?.sum(), DoubleWrapper(persistedValue: 123.456),
                    \Query<LinkToCustomPersistableCollections>.object.setOptDouble)
        validateSum("setOptDecimal", Decimal128Wrapper?.sum(), Decimal128Wrapper(persistedValue: Decimal128(123.456)),
                    \Query<LinkToCustomPersistableCollections>.object.setOptDecimal)
        validateSum("mapInt", Int.sum(), 1,
                    \Query<LinkToModernAllTypesObject>.object.mapInt)
        validateSum("mapInt8", Int8.sum(), Int8(8),
                    \Query<LinkToModernAllTypesObject>.object.mapInt8)
        validateSum("mapInt16", Int16.sum(), Int16(16),
                    \Query<LinkToModernAllTypesObject>.object.mapInt16)
        validateSum("mapInt32", Int32.sum(), Int32(32),
                    \Query<LinkToModernAllTypesObject>.object.mapInt32)
        validateSum("mapInt64", Int64.sum(), Int64(64),
                    \Query<LinkToModernAllTypesObject>.object.mapInt64)
        validateSum("mapFloat", Float.sum(), Float(5.55444333),
                    \Query<LinkToModernAllTypesObject>.object.mapFloat)
        validateSum("mapDouble", Double.sum(), 123.456,
                    \Query<LinkToModernAllTypesObject>.object.mapDouble)
        validateSum("mapDecimal", Decimal128.sum(), Decimal128(123.456),
                    \Query<LinkToModernAllTypesObject>.object.mapDecimal)
        validateSum("mapInt", EnumInt.sum(), EnumInt.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapInt.rawValue)
        validateSum("mapInt8", EnumInt8.sum(), EnumInt8.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapInt8.rawValue)
        validateSum("mapInt16", EnumInt16.sum(), EnumInt16.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapInt16.rawValue)
        validateSum("mapInt32", EnumInt32.sum(), EnumInt32.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapInt32.rawValue)
        validateSum("mapInt64", EnumInt64.sum(), EnumInt64.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapInt64.rawValue)
        validateSum("mapDouble", EnumDouble.sum(), EnumDouble.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapDouble.rawValue)
        validateSum("mapInt", IntWrapper.sum(), IntWrapper(persistedValue: 1),
                    \Query<LinkToCustomPersistableCollections>.object.mapInt)
        validateSum("mapInt8", Int8Wrapper.sum(), Int8Wrapper(persistedValue: Int8(8)),
                    \Query<LinkToCustomPersistableCollections>.object.mapInt8)
        validateSum("mapInt16", Int16Wrapper.sum(), Int16Wrapper(persistedValue: Int16(16)),
                    \Query<LinkToCustomPersistableCollections>.object.mapInt16)
        validateSum("mapInt32", Int32Wrapper.sum(), Int32Wrapper(persistedValue: Int32(32)),
                    \Query<LinkToCustomPersistableCollections>.object.mapInt32)
        validateSum("mapInt64", Int64Wrapper.sum(), Int64Wrapper(persistedValue: Int64(64)),
                    \Query<LinkToCustomPersistableCollections>.object.mapInt64)
        validateSum("mapFloat", FloatWrapper.sum(), FloatWrapper(persistedValue: Float(5.55444333)),
                    \Query<LinkToCustomPersistableCollections>.object.mapFloat)
        validateSum("mapDouble", DoubleWrapper.sum(), DoubleWrapper(persistedValue: 123.456),
                    \Query<LinkToCustomPersistableCollections>.object.mapDouble)
        validateSum("mapDecimal", Decimal128Wrapper.sum(), Decimal128Wrapper(persistedValue: Decimal128(123.456)),
                    \Query<LinkToCustomPersistableCollections>.object.mapDecimal)
        validateSum("mapOptInt", Int?.sum(), 1,
                    \Query<LinkToModernAllTypesObject>.object.mapOptInt)
        validateSum("mapOptInt8", Int8?.sum(), Int8(8),
                    \Query<LinkToModernAllTypesObject>.object.mapOptInt8)
        validateSum("mapOptInt16", Int16?.sum(), Int16(16),
                    \Query<LinkToModernAllTypesObject>.object.mapOptInt16)
        validateSum("mapOptInt32", Int32?.sum(), Int32(32),
                    \Query<LinkToModernAllTypesObject>.object.mapOptInt32)
        validateSum("mapOptInt64", Int64?.sum(), Int64(64),
                    \Query<LinkToModernAllTypesObject>.object.mapOptInt64)
        validateSum("mapOptFloat", Float?.sum(), Float(5.55444333),
                    \Query<LinkToModernAllTypesObject>.object.mapOptFloat)
        validateSum("mapOptDouble", Double?.sum(), 123.456,
                    \Query<LinkToModernAllTypesObject>.object.mapOptDouble)
        validateSum("mapOptDecimal", Decimal128?.sum(), Decimal128(123.456),
                    \Query<LinkToModernAllTypesObject>.object.mapOptDecimal)
        validateSum("mapIntOpt", EnumInt?.sum(), EnumInt.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapIntOpt.rawValue)
        validateSum("mapInt8Opt", EnumInt8?.sum(), EnumInt8.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapInt8Opt.rawValue)
        validateSum("mapInt16Opt", EnumInt16?.sum(), EnumInt16.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapInt16Opt.rawValue)
        validateSum("mapInt32Opt", EnumInt32?.sum(), EnumInt32.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapInt32Opt.rawValue)
        validateSum("mapInt64Opt", EnumInt64?.sum(), EnumInt64.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapInt64Opt.rawValue)
        validateSum("mapDoubleOpt", EnumDouble?.sum(), EnumDouble.value1.rawValue,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapDoubleOpt.rawValue)
        validateSum("mapOptInt", IntWrapper?.sum(), IntWrapper(persistedValue: 1),
                    \Query<LinkToCustomPersistableCollections>.object.mapOptInt)
        validateSum("mapOptInt8", Int8Wrapper?.sum(), Int8Wrapper(persistedValue: Int8(8)),
                    \Query<LinkToCustomPersistableCollections>.object.mapOptInt8)
        validateSum("mapOptInt16", Int16Wrapper?.sum(), Int16Wrapper(persistedValue: Int16(16)),
                    \Query<LinkToCustomPersistableCollections>.object.mapOptInt16)
        validateSum("mapOptInt32", Int32Wrapper?.sum(), Int32Wrapper(persistedValue: Int32(32)),
                    \Query<LinkToCustomPersistableCollections>.object.mapOptInt32)
        validateSum("mapOptInt64", Int64Wrapper?.sum(), Int64Wrapper(persistedValue: Int64(64)),
                    \Query<LinkToCustomPersistableCollections>.object.mapOptInt64)
        validateSum("mapOptFloat", FloatWrapper?.sum(), FloatWrapper(persistedValue: Float(5.55444333)),
                    \Query<LinkToCustomPersistableCollections>.object.mapOptFloat)
        validateSum("mapOptDouble", DoubleWrapper?.sum(), DoubleWrapper(persistedValue: 123.456),
                    \Query<LinkToCustomPersistableCollections>.object.mapOptDouble)
        validateSum("mapOptDecimal", Decimal128Wrapper?.sum(), Decimal128Wrapper(persistedValue: Decimal128(123.456)),
                    \Query<LinkToCustomPersistableCollections>.object.mapOptDecimal)
    }


    private func validateMin<Root: Object, T: RealmCollection>(_ name: String, min: T.Element, max: T.Element, _ lhs: (Query<Root>) -> Query<T>)
            where T.Element.PersistedType: _QueryNumeric, T.Element: QueryValue {
        assertQuery(Root.self, "(object.\(name).@min == %@)", min, count: 1) {
            lhs($0).min == min
        }
        assertQuery(Root.self, "(object.\(name).@min == %@)", max, count: 0) {
            lhs($0).min == max
        }
        assertQuery(Root.self, "(object.\(name).@min != %@)", min, count: 0) {
            lhs($0).min != min
        }
        assertQuery(Root.self, "(object.\(name).@min != %@)", max, count: 1) {
            lhs($0).min != max
        }
        assertQuery(Root.self, "(object.\(name).@min > %@)", min, count: 0) {
            lhs($0).min > min
        }
        assertQuery(Root.self, "(object.\(name).@min < %@)", min, count: 0) {
            lhs($0).min < min
        }
        assertQuery(Root.self, "(object.\(name).@min >= %@)", min, count: 1) {
            lhs($0).min >= min
        }
        assertQuery(Root.self, "(object.\(name).@min <= %@)", min, count: 1) {
            lhs($0).min <= min
        }
    }

    private func validateMin<Root: Object, T: RealmKeyedCollection>(_ name: String, min: T.Value, max: T.Value, _ lhs: (Query<Root>) -> Query<T>)
            where T.Value.PersistedType: _QueryNumeric, T.Value: QueryValue {
        assertQuery(Root.self, "(object.\(name).@min == %@)", min, count: 1) {
            lhs($0).min == min
        }
        assertQuery(Root.self, "(object.\(name).@min == %@)", max, count: 0) {
            lhs($0).min == max
        }
        assertQuery(Root.self, "(object.\(name).@min != %@)", min, count: 0) {
            lhs($0).min != min
        }
        assertQuery(Root.self, "(object.\(name).@min != %@)", max, count: 1) {
            lhs($0).min != max
        }
        assertQuery(Root.self, "(object.\(name).@min > %@)", min, count: 0) {
            lhs($0).min > min
        }
        assertQuery(Root.self, "(object.\(name).@min < %@)", min, count: 0) {
            lhs($0).min < min
        }
        assertQuery(Root.self, "(object.\(name).@min >= %@)", min, count: 1) {
            lhs($0).min >= min
        }
        assertQuery(Root.self, "(object.\(name).@min <= %@)", min, count: 1) {
            lhs($0).min <= min
        }
    }

    func testCollectionAggregatesMin() {
        initLinkedCollectionAggregatesObject()

        validateMin("arrayInt", min: 1, max: 5,
                    \Query<LinkToModernAllTypesObject>.object.arrayInt)
        validateMin("arrayInt8", min: Int8(8), max: Int8(10),
                    \Query<LinkToModernAllTypesObject>.object.arrayInt8)
        validateMin("arrayInt16", min: Int16(16), max: Int16(18),
                    \Query<LinkToModernAllTypesObject>.object.arrayInt16)
        validateMin("arrayInt32", min: Int32(32), max: Int32(34),
                    \Query<LinkToModernAllTypesObject>.object.arrayInt32)
        validateMin("arrayInt64", min: Int64(64), max: Int64(66),
                    \Query<LinkToModernAllTypesObject>.object.arrayInt64)
        validateMin("arrayFloat", min: Float(5.55444333), max: Float(7.55444333),
                    \Query<LinkToModernAllTypesObject>.object.arrayFloat)
        validateMin("arrayDouble", min: 123.456, max: 345.678,
                    \Query<LinkToModernAllTypesObject>.object.arrayDouble)
        validateMin("arrayDecimal", min: Decimal128(123.456), max: Decimal128(345.678),
                    \Query<LinkToModernAllTypesObject>.object.arrayDecimal)
        validateMin("listInt", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.listInt)
        validateMin("listInt8", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.listInt8)
        validateMin("listInt16", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.listInt16)
        validateMin("listInt32", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.listInt32)
        validateMin("listInt64", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.listInt64)
        validateMin("listDouble", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.listDouble)
        validateMin("listInt", min: IntWrapper(persistedValue: 1), max: IntWrapper(persistedValue: 5),
                    \Query<LinkToCustomPersistableCollections>.object.listInt)
        validateMin("listInt8", min: Int8Wrapper(persistedValue: Int8(8)), max: Int8Wrapper(persistedValue: Int8(10)),
                    \Query<LinkToCustomPersistableCollections>.object.listInt8)
        validateMin("listInt16", min: Int16Wrapper(persistedValue: Int16(16)), max: Int16Wrapper(persistedValue: Int16(18)),
                    \Query<LinkToCustomPersistableCollections>.object.listInt16)
        validateMin("listInt32", min: Int32Wrapper(persistedValue: Int32(32)), max: Int32Wrapper(persistedValue: Int32(34)),
                    \Query<LinkToCustomPersistableCollections>.object.listInt32)
        validateMin("listInt64", min: Int64Wrapper(persistedValue: Int64(64)), max: Int64Wrapper(persistedValue: Int64(66)),
                    \Query<LinkToCustomPersistableCollections>.object.listInt64)
        validateMin("listFloat", min: FloatWrapper(persistedValue: Float(5.55444333)), max: FloatWrapper(persistedValue: Float(7.55444333)),
                    \Query<LinkToCustomPersistableCollections>.object.listFloat)
        validateMin("listDouble", min: DoubleWrapper(persistedValue: 123.456), max: DoubleWrapper(persistedValue: 345.678),
                    \Query<LinkToCustomPersistableCollections>.object.listDouble)
        validateMin("listDecimal", min: Decimal128Wrapper(persistedValue: Decimal128(123.456)), max: Decimal128Wrapper(persistedValue: Decimal128(345.678)),
                    \Query<LinkToCustomPersistableCollections>.object.listDecimal)
        validateMin("arrayOptInt", min: 1, max: 5,
                    \Query<LinkToModernAllTypesObject>.object.arrayOptInt)
        validateMin("arrayOptInt8", min: Int8(8), max: Int8(10),
                    \Query<LinkToModernAllTypesObject>.object.arrayOptInt8)
        validateMin("arrayOptInt16", min: Int16(16), max: Int16(18),
                    \Query<LinkToModernAllTypesObject>.object.arrayOptInt16)
        validateMin("arrayOptInt32", min: Int32(32), max: Int32(34),
                    \Query<LinkToModernAllTypesObject>.object.arrayOptInt32)
        validateMin("arrayOptInt64", min: Int64(64), max: Int64(66),
                    \Query<LinkToModernAllTypesObject>.object.arrayOptInt64)
        validateMin("arrayOptFloat", min: Float(5.55444333), max: Float(7.55444333),
                    \Query<LinkToModernAllTypesObject>.object.arrayOptFloat)
        validateMin("arrayOptDouble", min: 123.456, max: 345.678,
                    \Query<LinkToModernAllTypesObject>.object.arrayOptDouble)
        validateMin("arrayOptDecimal", min: Decimal128(123.456), max: Decimal128(345.678),
                    \Query<LinkToModernAllTypesObject>.object.arrayOptDecimal)
        validateMin("listIntOpt", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.listIntOpt)
        validateMin("listInt8Opt", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.listInt8Opt)
        validateMin("listInt16Opt", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.listInt16Opt)
        validateMin("listInt32Opt", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.listInt32Opt)
        validateMin("listInt64Opt", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.listInt64Opt)
        validateMin("listDoubleOpt", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.listDoubleOpt)
        validateMin("listOptInt", min: IntWrapper(persistedValue: 1), max: IntWrapper(persistedValue: 5),
                    \Query<LinkToCustomPersistableCollections>.object.listOptInt)
        validateMin("listOptInt8", min: Int8Wrapper(persistedValue: Int8(8)), max: Int8Wrapper(persistedValue: Int8(10)),
                    \Query<LinkToCustomPersistableCollections>.object.listOptInt8)
        validateMin("listOptInt16", min: Int16Wrapper(persistedValue: Int16(16)), max: Int16Wrapper(persistedValue: Int16(18)),
                    \Query<LinkToCustomPersistableCollections>.object.listOptInt16)
        validateMin("listOptInt32", min: Int32Wrapper(persistedValue: Int32(32)), max: Int32Wrapper(persistedValue: Int32(34)),
                    \Query<LinkToCustomPersistableCollections>.object.listOptInt32)
        validateMin("listOptInt64", min: Int64Wrapper(persistedValue: Int64(64)), max: Int64Wrapper(persistedValue: Int64(66)),
                    \Query<LinkToCustomPersistableCollections>.object.listOptInt64)
        validateMin("listOptFloat", min: FloatWrapper(persistedValue: Float(5.55444333)), max: FloatWrapper(persistedValue: Float(7.55444333)),
                    \Query<LinkToCustomPersistableCollections>.object.listOptFloat)
        validateMin("listOptDouble", min: DoubleWrapper(persistedValue: 123.456), max: DoubleWrapper(persistedValue: 345.678),
                    \Query<LinkToCustomPersistableCollections>.object.listOptDouble)
        validateMin("listOptDecimal", min: Decimal128Wrapper(persistedValue: Decimal128(123.456)), max: Decimal128Wrapper(persistedValue: Decimal128(345.678)),
                    \Query<LinkToCustomPersistableCollections>.object.listOptDecimal)
        validateMin("setInt", min: 1, max: 5,
                    \Query<LinkToModernAllTypesObject>.object.setInt)
        validateMin("setInt8", min: Int8(8), max: Int8(10),
                    \Query<LinkToModernAllTypesObject>.object.setInt8)
        validateMin("setInt16", min: Int16(16), max: Int16(18),
                    \Query<LinkToModernAllTypesObject>.object.setInt16)
        validateMin("setInt32", min: Int32(32), max: Int32(34),
                    \Query<LinkToModernAllTypesObject>.object.setInt32)
        validateMin("setInt64", min: Int64(64), max: Int64(66),
                    \Query<LinkToModernAllTypesObject>.object.setInt64)
        validateMin("setFloat", min: Float(5.55444333), max: Float(7.55444333),
                    \Query<LinkToModernAllTypesObject>.object.setFloat)
        validateMin("setDouble", min: 123.456, max: 345.678,
                    \Query<LinkToModernAllTypesObject>.object.setDouble)
        validateMin("setDecimal", min: Decimal128(123.456), max: Decimal128(345.678),
                    \Query<LinkToModernAllTypesObject>.object.setDecimal)
        validateMin("setInt", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.setInt)
        validateMin("setInt8", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.setInt8)
        validateMin("setInt16", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.setInt16)
        validateMin("setInt32", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.setInt32)
        validateMin("setInt64", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.setInt64)
        validateMin("setDouble", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.setDouble)
        validateMin("setInt", min: IntWrapper(persistedValue: 1), max: IntWrapper(persistedValue: 5),
                    \Query<LinkToCustomPersistableCollections>.object.setInt)
        validateMin("setInt8", min: Int8Wrapper(persistedValue: Int8(8)), max: Int8Wrapper(persistedValue: Int8(10)),
                    \Query<LinkToCustomPersistableCollections>.object.setInt8)
        validateMin("setInt16", min: Int16Wrapper(persistedValue: Int16(16)), max: Int16Wrapper(persistedValue: Int16(18)),
                    \Query<LinkToCustomPersistableCollections>.object.setInt16)
        validateMin("setInt32", min: Int32Wrapper(persistedValue: Int32(32)), max: Int32Wrapper(persistedValue: Int32(34)),
                    \Query<LinkToCustomPersistableCollections>.object.setInt32)
        validateMin("setInt64", min: Int64Wrapper(persistedValue: Int64(64)), max: Int64Wrapper(persistedValue: Int64(66)),
                    \Query<LinkToCustomPersistableCollections>.object.setInt64)
        validateMin("setFloat", min: FloatWrapper(persistedValue: Float(5.55444333)), max: FloatWrapper(persistedValue: Float(7.55444333)),
                    \Query<LinkToCustomPersistableCollections>.object.setFloat)
        validateMin("setDouble", min: DoubleWrapper(persistedValue: 123.456), max: DoubleWrapper(persistedValue: 345.678),
                    \Query<LinkToCustomPersistableCollections>.object.setDouble)
        validateMin("setDecimal", min: Decimal128Wrapper(persistedValue: Decimal128(123.456)), max: Decimal128Wrapper(persistedValue: Decimal128(345.678)),
                    \Query<LinkToCustomPersistableCollections>.object.setDecimal)
        validateMin("setOptInt", min: 1, max: 5,
                    \Query<LinkToModernAllTypesObject>.object.setOptInt)
        validateMin("setOptInt8", min: Int8(8), max: Int8(10),
                    \Query<LinkToModernAllTypesObject>.object.setOptInt8)
        validateMin("setOptInt16", min: Int16(16), max: Int16(18),
                    \Query<LinkToModernAllTypesObject>.object.setOptInt16)
        validateMin("setOptInt32", min: Int32(32), max: Int32(34),
                    \Query<LinkToModernAllTypesObject>.object.setOptInt32)
        validateMin("setOptInt64", min: Int64(64), max: Int64(66),
                    \Query<LinkToModernAllTypesObject>.object.setOptInt64)
        validateMin("setOptFloat", min: Float(5.55444333), max: Float(7.55444333),
                    \Query<LinkToModernAllTypesObject>.object.setOptFloat)
        validateMin("setOptDouble", min: 123.456, max: 345.678,
                    \Query<LinkToModernAllTypesObject>.object.setOptDouble)
        validateMin("setOptDecimal", min: Decimal128(123.456), max: Decimal128(345.678),
                    \Query<LinkToModernAllTypesObject>.object.setOptDecimal)
        validateMin("setIntOpt", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.setIntOpt)
        validateMin("setInt8Opt", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.setInt8Opt)
        validateMin("setInt16Opt", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.setInt16Opt)
        validateMin("setInt32Opt", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.setInt32Opt)
        validateMin("setInt64Opt", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.setInt64Opt)
        validateMin("setDoubleOpt", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.setDoubleOpt)
        validateMin("setOptInt", min: IntWrapper(persistedValue: 1), max: IntWrapper(persistedValue: 5),
                    \Query<LinkToCustomPersistableCollections>.object.setOptInt)
        validateMin("setOptInt8", min: Int8Wrapper(persistedValue: Int8(8)), max: Int8Wrapper(persistedValue: Int8(10)),
                    \Query<LinkToCustomPersistableCollections>.object.setOptInt8)
        validateMin("setOptInt16", min: Int16Wrapper(persistedValue: Int16(16)), max: Int16Wrapper(persistedValue: Int16(18)),
                    \Query<LinkToCustomPersistableCollections>.object.setOptInt16)
        validateMin("setOptInt32", min: Int32Wrapper(persistedValue: Int32(32)), max: Int32Wrapper(persistedValue: Int32(34)),
                    \Query<LinkToCustomPersistableCollections>.object.setOptInt32)
        validateMin("setOptInt64", min: Int64Wrapper(persistedValue: Int64(64)), max: Int64Wrapper(persistedValue: Int64(66)),
                    \Query<LinkToCustomPersistableCollections>.object.setOptInt64)
        validateMin("setOptFloat", min: FloatWrapper(persistedValue: Float(5.55444333)), max: FloatWrapper(persistedValue: Float(7.55444333)),
                    \Query<LinkToCustomPersistableCollections>.object.setOptFloat)
        validateMin("setOptDouble", min: DoubleWrapper(persistedValue: 123.456), max: DoubleWrapper(persistedValue: 345.678),
                    \Query<LinkToCustomPersistableCollections>.object.setOptDouble)
        validateMin("setOptDecimal", min: Decimal128Wrapper(persistedValue: Decimal128(123.456)), max: Decimal128Wrapper(persistedValue: Decimal128(345.678)),
                    \Query<LinkToCustomPersistableCollections>.object.setOptDecimal)
        validateMin("mapInt", min: 1, max: 5,
                    \Query<LinkToModernAllTypesObject>.object.mapInt)
        validateMin("mapInt8", min: Int8(8), max: Int8(10),
                    \Query<LinkToModernAllTypesObject>.object.mapInt8)
        validateMin("mapInt16", min: Int16(16), max: Int16(18),
                    \Query<LinkToModernAllTypesObject>.object.mapInt16)
        validateMin("mapInt32", min: Int32(32), max: Int32(34),
                    \Query<LinkToModernAllTypesObject>.object.mapInt32)
        validateMin("mapInt64", min: Int64(64), max: Int64(66),
                    \Query<LinkToModernAllTypesObject>.object.mapInt64)
        validateMin("mapFloat", min: Float(5.55444333), max: Float(7.55444333),
                    \Query<LinkToModernAllTypesObject>.object.mapFloat)
        validateMin("mapDouble", min: 123.456, max: 345.678,
                    \Query<LinkToModernAllTypesObject>.object.mapDouble)
        validateMin("mapDecimal", min: Decimal128(123.456), max: Decimal128(345.678),
                    \Query<LinkToModernAllTypesObject>.object.mapDecimal)
        validateMin("mapInt", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapInt)
        validateMin("mapInt8", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapInt8)
        validateMin("mapInt16", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapInt16)
        validateMin("mapInt32", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapInt32)
        validateMin("mapInt64", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapInt64)
        validateMin("mapDouble", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapDouble)
        validateMin("mapInt", min: IntWrapper(persistedValue: 1), max: IntWrapper(persistedValue: 5),
                    \Query<LinkToCustomPersistableCollections>.object.mapInt)
        validateMin("mapInt8", min: Int8Wrapper(persistedValue: Int8(8)), max: Int8Wrapper(persistedValue: Int8(10)),
                    \Query<LinkToCustomPersistableCollections>.object.mapInt8)
        validateMin("mapInt16", min: Int16Wrapper(persistedValue: Int16(16)), max: Int16Wrapper(persistedValue: Int16(18)),
                    \Query<LinkToCustomPersistableCollections>.object.mapInt16)
        validateMin("mapInt32", min: Int32Wrapper(persistedValue: Int32(32)), max: Int32Wrapper(persistedValue: Int32(34)),
                    \Query<LinkToCustomPersistableCollections>.object.mapInt32)
        validateMin("mapInt64", min: Int64Wrapper(persistedValue: Int64(64)), max: Int64Wrapper(persistedValue: Int64(66)),
                    \Query<LinkToCustomPersistableCollections>.object.mapInt64)
        validateMin("mapFloat", min: FloatWrapper(persistedValue: Float(5.55444333)), max: FloatWrapper(persistedValue: Float(7.55444333)),
                    \Query<LinkToCustomPersistableCollections>.object.mapFloat)
        validateMin("mapDouble", min: DoubleWrapper(persistedValue: 123.456), max: DoubleWrapper(persistedValue: 345.678),
                    \Query<LinkToCustomPersistableCollections>.object.mapDouble)
        validateMin("mapDecimal", min: Decimal128Wrapper(persistedValue: Decimal128(123.456)), max: Decimal128Wrapper(persistedValue: Decimal128(345.678)),
                    \Query<LinkToCustomPersistableCollections>.object.mapDecimal)
        validateMin("mapOptInt", min: 1, max: 5,
                    \Query<LinkToModernAllTypesObject>.object.mapOptInt)
        validateMin("mapOptInt8", min: Int8(8), max: Int8(10),
                    \Query<LinkToModernAllTypesObject>.object.mapOptInt8)
        validateMin("mapOptInt16", min: Int16(16), max: Int16(18),
                    \Query<LinkToModernAllTypesObject>.object.mapOptInt16)
        validateMin("mapOptInt32", min: Int32(32), max: Int32(34),
                    \Query<LinkToModernAllTypesObject>.object.mapOptInt32)
        validateMin("mapOptInt64", min: Int64(64), max: Int64(66),
                    \Query<LinkToModernAllTypesObject>.object.mapOptInt64)
        validateMin("mapOptFloat", min: Float(5.55444333), max: Float(7.55444333),
                    \Query<LinkToModernAllTypesObject>.object.mapOptFloat)
        validateMin("mapOptDouble", min: 123.456, max: 345.678,
                    \Query<LinkToModernAllTypesObject>.object.mapOptDouble)
        validateMin("mapOptDecimal", min: Decimal128(123.456), max: Decimal128(345.678),
                    \Query<LinkToModernAllTypesObject>.object.mapOptDecimal)
        validateMin("mapIntOpt", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapIntOpt)
        validateMin("mapInt8Opt", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapInt8Opt)
        validateMin("mapInt16Opt", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapInt16Opt)
        validateMin("mapInt32Opt", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapInt32Opt)
        validateMin("mapInt64Opt", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapInt64Opt)
        validateMin("mapDoubleOpt", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapDoubleOpt)
        validateMin("mapOptInt", min: IntWrapper(persistedValue: 1), max: IntWrapper(persistedValue: 5),
                    \Query<LinkToCustomPersistableCollections>.object.mapOptInt)
        validateMin("mapOptInt8", min: Int8Wrapper(persistedValue: Int8(8)), max: Int8Wrapper(persistedValue: Int8(10)),
                    \Query<LinkToCustomPersistableCollections>.object.mapOptInt8)
        validateMin("mapOptInt16", min: Int16Wrapper(persistedValue: Int16(16)), max: Int16Wrapper(persistedValue: Int16(18)),
                    \Query<LinkToCustomPersistableCollections>.object.mapOptInt16)
        validateMin("mapOptInt32", min: Int32Wrapper(persistedValue: Int32(32)), max: Int32Wrapper(persistedValue: Int32(34)),
                    \Query<LinkToCustomPersistableCollections>.object.mapOptInt32)
        validateMin("mapOptInt64", min: Int64Wrapper(persistedValue: Int64(64)), max: Int64Wrapper(persistedValue: Int64(66)),
                    \Query<LinkToCustomPersistableCollections>.object.mapOptInt64)
        validateMin("mapOptFloat", min: FloatWrapper(persistedValue: Float(5.55444333)), max: FloatWrapper(persistedValue: Float(7.55444333)),
                    \Query<LinkToCustomPersistableCollections>.object.mapOptFloat)
        validateMin("mapOptDouble", min: DoubleWrapper(persistedValue: 123.456), max: DoubleWrapper(persistedValue: 345.678),
                    \Query<LinkToCustomPersistableCollections>.object.mapOptDouble)
        validateMin("mapOptDecimal", min: Decimal128Wrapper(persistedValue: Decimal128(123.456)), max: Decimal128Wrapper(persistedValue: Decimal128(345.678)),
                    \Query<LinkToCustomPersistableCollections>.object.mapOptDecimal)
    }

    private func validateMax<Root: Object, T: RealmCollection>(_ name: String, min: T.Element, max: T.Element, _ lhs: (Query<Root>) -> Query<T>)
            where T.Element.PersistedType: _QueryNumeric, T.Element: QueryValue {
        assertQuery(Root.self, "(object.\(name).@max == %@)", max, count: 1) {
            lhs($0).max == max
        }
        assertQuery(Root.self, "(object.\(name).@max == %@)", min, count: 0) {
            lhs($0).max == min
        }
        assertQuery(Root.self, "(object.\(name).@max != %@)", max, count: 0) {
            lhs($0).max != max
        }
        assertQuery(Root.self, "(object.\(name).@max != %@)", min, count: 1) {
            lhs($0).max != min
        }
        assertQuery(Root.self, "(object.\(name).@max > %@)", max, count: 0) {
            lhs($0).max > max
        }
        assertQuery(Root.self, "(object.\(name).@max < %@)", max, count: 0) {
            lhs($0).max < max
        }
        assertQuery(Root.self, "(object.\(name).@max >= %@)", max, count: 1) {
            lhs($0).max >= max
        }
        assertQuery(Root.self, "(object.\(name).@max <= %@)", max, count: 1) {
            lhs($0).max <= max
        }
    }

    private func validateMax<Root: Object, T: RealmKeyedCollection>(_ name: String, min: T.Value, max: T.Value, _ lhs: (Query<Root>) -> Query<T>)
            where T.Value.PersistedType: _QueryNumeric, T.Value: QueryValue {
        assertQuery(Root.self, "(object.\(name).@max == %@)", max, count: 1) {
            lhs($0).max == max
        }
        assertQuery(Root.self, "(object.\(name).@max == %@)", min, count: 0) {
            lhs($0).max == min
        }
        assertQuery(Root.self, "(object.\(name).@max != %@)", max, count: 0) {
            lhs($0).max != max
        }
        assertQuery(Root.self, "(object.\(name).@max != %@)", min, count: 1) {
            lhs($0).max != min
        }
        assertQuery(Root.self, "(object.\(name).@max > %@)", max, count: 0) {
            lhs($0).max > max
        }
        assertQuery(Root.self, "(object.\(name).@max < %@)", max, count: 0) {
            lhs($0).max < max
        }
        assertQuery(Root.self, "(object.\(name).@max >= %@)", max, count: 1) {
            lhs($0).max >= max
        }
        assertQuery(Root.self, "(object.\(name).@max <= %@)", max, count: 1) {
            lhs($0).max <= max
        }
    }

    func testCollectionAggregatesMax() {
        initLinkedCollectionAggregatesObject()

        validateMax("arrayInt", min: 1, max: 5,
                    \Query<LinkToModernAllTypesObject>.object.arrayInt)
        validateMax("arrayInt8", min: Int8(8), max: Int8(10),
                    \Query<LinkToModernAllTypesObject>.object.arrayInt8)
        validateMax("arrayInt16", min: Int16(16), max: Int16(18),
                    \Query<LinkToModernAllTypesObject>.object.arrayInt16)
        validateMax("arrayInt32", min: Int32(32), max: Int32(34),
                    \Query<LinkToModernAllTypesObject>.object.arrayInt32)
        validateMax("arrayInt64", min: Int64(64), max: Int64(66),
                    \Query<LinkToModernAllTypesObject>.object.arrayInt64)
        validateMax("arrayFloat", min: Float(5.55444333), max: Float(7.55444333),
                    \Query<LinkToModernAllTypesObject>.object.arrayFloat)
        validateMax("arrayDouble", min: 123.456, max: 345.678,
                    \Query<LinkToModernAllTypesObject>.object.arrayDouble)
        validateMax("arrayDecimal", min: Decimal128(123.456), max: Decimal128(345.678),
                    \Query<LinkToModernAllTypesObject>.object.arrayDecimal)
        validateMax("listInt", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.listInt)
        validateMax("listInt8", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.listInt8)
        validateMax("listInt16", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.listInt16)
        validateMax("listInt32", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.listInt32)
        validateMax("listInt64", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.listInt64)
        validateMax("listDouble", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.listDouble)
        validateMax("listInt", min: IntWrapper(persistedValue: 1), max: IntWrapper(persistedValue: 5),
                    \Query<LinkToCustomPersistableCollections>.object.listInt)
        validateMax("listInt8", min: Int8Wrapper(persistedValue: Int8(8)), max: Int8Wrapper(persistedValue: Int8(10)),
                    \Query<LinkToCustomPersistableCollections>.object.listInt8)
        validateMax("listInt16", min: Int16Wrapper(persistedValue: Int16(16)), max: Int16Wrapper(persistedValue: Int16(18)),
                    \Query<LinkToCustomPersistableCollections>.object.listInt16)
        validateMax("listInt32", min: Int32Wrapper(persistedValue: Int32(32)), max: Int32Wrapper(persistedValue: Int32(34)),
                    \Query<LinkToCustomPersistableCollections>.object.listInt32)
        validateMax("listInt64", min: Int64Wrapper(persistedValue: Int64(64)), max: Int64Wrapper(persistedValue: Int64(66)),
                    \Query<LinkToCustomPersistableCollections>.object.listInt64)
        validateMax("listFloat", min: FloatWrapper(persistedValue: Float(5.55444333)), max: FloatWrapper(persistedValue: Float(7.55444333)),
                    \Query<LinkToCustomPersistableCollections>.object.listFloat)
        validateMax("listDouble", min: DoubleWrapper(persistedValue: 123.456), max: DoubleWrapper(persistedValue: 345.678),
                    \Query<LinkToCustomPersistableCollections>.object.listDouble)
        validateMax("listDecimal", min: Decimal128Wrapper(persistedValue: Decimal128(123.456)), max: Decimal128Wrapper(persistedValue: Decimal128(345.678)),
                    \Query<LinkToCustomPersistableCollections>.object.listDecimal)
        validateMax("arrayOptInt", min: 1, max: 5,
                    \Query<LinkToModernAllTypesObject>.object.arrayOptInt)
        validateMax("arrayOptInt8", min: Int8(8), max: Int8(10),
                    \Query<LinkToModernAllTypesObject>.object.arrayOptInt8)
        validateMax("arrayOptInt16", min: Int16(16), max: Int16(18),
                    \Query<LinkToModernAllTypesObject>.object.arrayOptInt16)
        validateMax("arrayOptInt32", min: Int32(32), max: Int32(34),
                    \Query<LinkToModernAllTypesObject>.object.arrayOptInt32)
        validateMax("arrayOptInt64", min: Int64(64), max: Int64(66),
                    \Query<LinkToModernAllTypesObject>.object.arrayOptInt64)
        validateMax("arrayOptFloat", min: Float(5.55444333), max: Float(7.55444333),
                    \Query<LinkToModernAllTypesObject>.object.arrayOptFloat)
        validateMax("arrayOptDouble", min: 123.456, max: 345.678,
                    \Query<LinkToModernAllTypesObject>.object.arrayOptDouble)
        validateMax("arrayOptDecimal", min: Decimal128(123.456), max: Decimal128(345.678),
                    \Query<LinkToModernAllTypesObject>.object.arrayOptDecimal)
        validateMax("listIntOpt", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.listIntOpt)
        validateMax("listInt8Opt", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.listInt8Opt)
        validateMax("listInt16Opt", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.listInt16Opt)
        validateMax("listInt32Opt", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.listInt32Opt)
        validateMax("listInt64Opt", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.listInt64Opt)
        validateMax("listDoubleOpt", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.listDoubleOpt)
        validateMax("listOptInt", min: IntWrapper(persistedValue: 1), max: IntWrapper(persistedValue: 5),
                    \Query<LinkToCustomPersistableCollections>.object.listOptInt)
        validateMax("listOptInt8", min: Int8Wrapper(persistedValue: Int8(8)), max: Int8Wrapper(persistedValue: Int8(10)),
                    \Query<LinkToCustomPersistableCollections>.object.listOptInt8)
        validateMax("listOptInt16", min: Int16Wrapper(persistedValue: Int16(16)), max: Int16Wrapper(persistedValue: Int16(18)),
                    \Query<LinkToCustomPersistableCollections>.object.listOptInt16)
        validateMax("listOptInt32", min: Int32Wrapper(persistedValue: Int32(32)), max: Int32Wrapper(persistedValue: Int32(34)),
                    \Query<LinkToCustomPersistableCollections>.object.listOptInt32)
        validateMax("listOptInt64", min: Int64Wrapper(persistedValue: Int64(64)), max: Int64Wrapper(persistedValue: Int64(66)),
                    \Query<LinkToCustomPersistableCollections>.object.listOptInt64)
        validateMax("listOptFloat", min: FloatWrapper(persistedValue: Float(5.55444333)), max: FloatWrapper(persistedValue: Float(7.55444333)),
                    \Query<LinkToCustomPersistableCollections>.object.listOptFloat)
        validateMax("listOptDouble", min: DoubleWrapper(persistedValue: 123.456), max: DoubleWrapper(persistedValue: 345.678),
                    \Query<LinkToCustomPersistableCollections>.object.listOptDouble)
        validateMax("listOptDecimal", min: Decimal128Wrapper(persistedValue: Decimal128(123.456)), max: Decimal128Wrapper(persistedValue: Decimal128(345.678)),
                    \Query<LinkToCustomPersistableCollections>.object.listOptDecimal)
        validateMax("setInt", min: 1, max: 5,
                    \Query<LinkToModernAllTypesObject>.object.setInt)
        validateMax("setInt8", min: Int8(8), max: Int8(10),
                    \Query<LinkToModernAllTypesObject>.object.setInt8)
        validateMax("setInt16", min: Int16(16), max: Int16(18),
                    \Query<LinkToModernAllTypesObject>.object.setInt16)
        validateMax("setInt32", min: Int32(32), max: Int32(34),
                    \Query<LinkToModernAllTypesObject>.object.setInt32)
        validateMax("setInt64", min: Int64(64), max: Int64(66),
                    \Query<LinkToModernAllTypesObject>.object.setInt64)
        validateMax("setFloat", min: Float(5.55444333), max: Float(7.55444333),
                    \Query<LinkToModernAllTypesObject>.object.setFloat)
        validateMax("setDouble", min: 123.456, max: 345.678,
                    \Query<LinkToModernAllTypesObject>.object.setDouble)
        validateMax("setDecimal", min: Decimal128(123.456), max: Decimal128(345.678),
                    \Query<LinkToModernAllTypesObject>.object.setDecimal)
        validateMax("setInt", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.setInt)
        validateMax("setInt8", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.setInt8)
        validateMax("setInt16", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.setInt16)
        validateMax("setInt32", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.setInt32)
        validateMax("setInt64", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.setInt64)
        validateMax("setDouble", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.setDouble)
        validateMax("setInt", min: IntWrapper(persistedValue: 1), max: IntWrapper(persistedValue: 5),
                    \Query<LinkToCustomPersistableCollections>.object.setInt)
        validateMax("setInt8", min: Int8Wrapper(persistedValue: Int8(8)), max: Int8Wrapper(persistedValue: Int8(10)),
                    \Query<LinkToCustomPersistableCollections>.object.setInt8)
        validateMax("setInt16", min: Int16Wrapper(persistedValue: Int16(16)), max: Int16Wrapper(persistedValue: Int16(18)),
                    \Query<LinkToCustomPersistableCollections>.object.setInt16)
        validateMax("setInt32", min: Int32Wrapper(persistedValue: Int32(32)), max: Int32Wrapper(persistedValue: Int32(34)),
                    \Query<LinkToCustomPersistableCollections>.object.setInt32)
        validateMax("setInt64", min: Int64Wrapper(persistedValue: Int64(64)), max: Int64Wrapper(persistedValue: Int64(66)),
                    \Query<LinkToCustomPersistableCollections>.object.setInt64)
        validateMax("setFloat", min: FloatWrapper(persistedValue: Float(5.55444333)), max: FloatWrapper(persistedValue: Float(7.55444333)),
                    \Query<LinkToCustomPersistableCollections>.object.setFloat)
        validateMax("setDouble", min: DoubleWrapper(persistedValue: 123.456), max: DoubleWrapper(persistedValue: 345.678),
                    \Query<LinkToCustomPersistableCollections>.object.setDouble)
        validateMax("setDecimal", min: Decimal128Wrapper(persistedValue: Decimal128(123.456)), max: Decimal128Wrapper(persistedValue: Decimal128(345.678)),
                    \Query<LinkToCustomPersistableCollections>.object.setDecimal)
        validateMax("setOptInt", min: 1, max: 5,
                    \Query<LinkToModernAllTypesObject>.object.setOptInt)
        validateMax("setOptInt8", min: Int8(8), max: Int8(10),
                    \Query<LinkToModernAllTypesObject>.object.setOptInt8)
        validateMax("setOptInt16", min: Int16(16), max: Int16(18),
                    \Query<LinkToModernAllTypesObject>.object.setOptInt16)
        validateMax("setOptInt32", min: Int32(32), max: Int32(34),
                    \Query<LinkToModernAllTypesObject>.object.setOptInt32)
        validateMax("setOptInt64", min: Int64(64), max: Int64(66),
                    \Query<LinkToModernAllTypesObject>.object.setOptInt64)
        validateMax("setOptFloat", min: Float(5.55444333), max: Float(7.55444333),
                    \Query<LinkToModernAllTypesObject>.object.setOptFloat)
        validateMax("setOptDouble", min: 123.456, max: 345.678,
                    \Query<LinkToModernAllTypesObject>.object.setOptDouble)
        validateMax("setOptDecimal", min: Decimal128(123.456), max: Decimal128(345.678),
                    \Query<LinkToModernAllTypesObject>.object.setOptDecimal)
        validateMax("setIntOpt", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.setIntOpt)
        validateMax("setInt8Opt", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.setInt8Opt)
        validateMax("setInt16Opt", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.setInt16Opt)
        validateMax("setInt32Opt", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.setInt32Opt)
        validateMax("setInt64Opt", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.setInt64Opt)
        validateMax("setDoubleOpt", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.setDoubleOpt)
        validateMax("setOptInt", min: IntWrapper(persistedValue: 1), max: IntWrapper(persistedValue: 5),
                    \Query<LinkToCustomPersistableCollections>.object.setOptInt)
        validateMax("setOptInt8", min: Int8Wrapper(persistedValue: Int8(8)), max: Int8Wrapper(persistedValue: Int8(10)),
                    \Query<LinkToCustomPersistableCollections>.object.setOptInt8)
        validateMax("setOptInt16", min: Int16Wrapper(persistedValue: Int16(16)), max: Int16Wrapper(persistedValue: Int16(18)),
                    \Query<LinkToCustomPersistableCollections>.object.setOptInt16)
        validateMax("setOptInt32", min: Int32Wrapper(persistedValue: Int32(32)), max: Int32Wrapper(persistedValue: Int32(34)),
                    \Query<LinkToCustomPersistableCollections>.object.setOptInt32)
        validateMax("setOptInt64", min: Int64Wrapper(persistedValue: Int64(64)), max: Int64Wrapper(persistedValue: Int64(66)),
                    \Query<LinkToCustomPersistableCollections>.object.setOptInt64)
        validateMax("setOptFloat", min: FloatWrapper(persistedValue: Float(5.55444333)), max: FloatWrapper(persistedValue: Float(7.55444333)),
                    \Query<LinkToCustomPersistableCollections>.object.setOptFloat)
        validateMax("setOptDouble", min: DoubleWrapper(persistedValue: 123.456), max: DoubleWrapper(persistedValue: 345.678),
                    \Query<LinkToCustomPersistableCollections>.object.setOptDouble)
        validateMax("setOptDecimal", min: Decimal128Wrapper(persistedValue: Decimal128(123.456)), max: Decimal128Wrapper(persistedValue: Decimal128(345.678)),
                    \Query<LinkToCustomPersistableCollections>.object.setOptDecimal)
        validateMax("mapInt", min: 1, max: 5,
                    \Query<LinkToModernAllTypesObject>.object.mapInt)
        validateMax("mapInt8", min: Int8(8), max: Int8(10),
                    \Query<LinkToModernAllTypesObject>.object.mapInt8)
        validateMax("mapInt16", min: Int16(16), max: Int16(18),
                    \Query<LinkToModernAllTypesObject>.object.mapInt16)
        validateMax("mapInt32", min: Int32(32), max: Int32(34),
                    \Query<LinkToModernAllTypesObject>.object.mapInt32)
        validateMax("mapInt64", min: Int64(64), max: Int64(66),
                    \Query<LinkToModernAllTypesObject>.object.mapInt64)
        validateMax("mapFloat", min: Float(5.55444333), max: Float(7.55444333),
                    \Query<LinkToModernAllTypesObject>.object.mapFloat)
        validateMax("mapDouble", min: 123.456, max: 345.678,
                    \Query<LinkToModernAllTypesObject>.object.mapDouble)
        validateMax("mapDecimal", min: Decimal128(123.456), max: Decimal128(345.678),
                    \Query<LinkToModernAllTypesObject>.object.mapDecimal)
        validateMax("mapInt", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapInt)
        validateMax("mapInt8", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapInt8)
        validateMax("mapInt16", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapInt16)
        validateMax("mapInt32", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapInt32)
        validateMax("mapInt64", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapInt64)
        validateMax("mapDouble", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapDouble)
        validateMax("mapInt", min: IntWrapper(persistedValue: 1), max: IntWrapper(persistedValue: 5),
                    \Query<LinkToCustomPersistableCollections>.object.mapInt)
        validateMax("mapInt8", min: Int8Wrapper(persistedValue: Int8(8)), max: Int8Wrapper(persistedValue: Int8(10)),
                    \Query<LinkToCustomPersistableCollections>.object.mapInt8)
        validateMax("mapInt16", min: Int16Wrapper(persistedValue: Int16(16)), max: Int16Wrapper(persistedValue: Int16(18)),
                    \Query<LinkToCustomPersistableCollections>.object.mapInt16)
        validateMax("mapInt32", min: Int32Wrapper(persistedValue: Int32(32)), max: Int32Wrapper(persistedValue: Int32(34)),
                    \Query<LinkToCustomPersistableCollections>.object.mapInt32)
        validateMax("mapInt64", min: Int64Wrapper(persistedValue: Int64(64)), max: Int64Wrapper(persistedValue: Int64(66)),
                    \Query<LinkToCustomPersistableCollections>.object.mapInt64)
        validateMax("mapFloat", min: FloatWrapper(persistedValue: Float(5.55444333)), max: FloatWrapper(persistedValue: Float(7.55444333)),
                    \Query<LinkToCustomPersistableCollections>.object.mapFloat)
        validateMax("mapDouble", min: DoubleWrapper(persistedValue: 123.456), max: DoubleWrapper(persistedValue: 345.678),
                    \Query<LinkToCustomPersistableCollections>.object.mapDouble)
        validateMax("mapDecimal", min: Decimal128Wrapper(persistedValue: Decimal128(123.456)), max: Decimal128Wrapper(persistedValue: Decimal128(345.678)),
                    \Query<LinkToCustomPersistableCollections>.object.mapDecimal)
        validateMax("mapOptInt", min: 1, max: 5,
                    \Query<LinkToModernAllTypesObject>.object.mapOptInt)
        validateMax("mapOptInt8", min: Int8(8), max: Int8(10),
                    \Query<LinkToModernAllTypesObject>.object.mapOptInt8)
        validateMax("mapOptInt16", min: Int16(16), max: Int16(18),
                    \Query<LinkToModernAllTypesObject>.object.mapOptInt16)
        validateMax("mapOptInt32", min: Int32(32), max: Int32(34),
                    \Query<LinkToModernAllTypesObject>.object.mapOptInt32)
        validateMax("mapOptInt64", min: Int64(64), max: Int64(66),
                    \Query<LinkToModernAllTypesObject>.object.mapOptInt64)
        validateMax("mapOptFloat", min: Float(5.55444333), max: Float(7.55444333),
                    \Query<LinkToModernAllTypesObject>.object.mapOptFloat)
        validateMax("mapOptDouble", min: 123.456, max: 345.678,
                    \Query<LinkToModernAllTypesObject>.object.mapOptDouble)
        validateMax("mapOptDecimal", min: Decimal128(123.456), max: Decimal128(345.678),
                    \Query<LinkToModernAllTypesObject>.object.mapOptDecimal)
        validateMax("mapIntOpt", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapIntOpt)
        validateMax("mapInt8Opt", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapInt8Opt)
        validateMax("mapInt16Opt", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapInt16Opt)
        validateMax("mapInt32Opt", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapInt32Opt)
        validateMax("mapInt64Opt", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapInt64Opt)
        validateMax("mapDoubleOpt", min: .value1, max: .value3,
                    \Query<LinkToModernCollectionsOfEnums>.object.mapDoubleOpt)
        validateMax("mapOptInt", min: IntWrapper(persistedValue: 1), max: IntWrapper(persistedValue: 5),
                    \Query<LinkToCustomPersistableCollections>.object.mapOptInt)
        validateMax("mapOptInt8", min: Int8Wrapper(persistedValue: Int8(8)), max: Int8Wrapper(persistedValue: Int8(10)),
                    \Query<LinkToCustomPersistableCollections>.object.mapOptInt8)
        validateMax("mapOptInt16", min: Int16Wrapper(persistedValue: Int16(16)), max: Int16Wrapper(persistedValue: Int16(18)),
                    \Query<LinkToCustomPersistableCollections>.object.mapOptInt16)
        validateMax("mapOptInt32", min: Int32Wrapper(persistedValue: Int32(32)), max: Int32Wrapper(persistedValue: Int32(34)),
                    \Query<LinkToCustomPersistableCollections>.object.mapOptInt32)
        validateMax("mapOptInt64", min: Int64Wrapper(persistedValue: Int64(64)), max: Int64Wrapper(persistedValue: Int64(66)),
                    \Query<LinkToCustomPersistableCollections>.object.mapOptInt64)
        validateMax("mapOptFloat", min: FloatWrapper(persistedValue: Float(5.55444333)), max: FloatWrapper(persistedValue: Float(7.55444333)),
                    \Query<LinkToCustomPersistableCollections>.object.mapOptFloat)
        validateMax("mapOptDouble", min: DoubleWrapper(persistedValue: 123.456), max: DoubleWrapper(persistedValue: 345.678),
                    \Query<LinkToCustomPersistableCollections>.object.mapOptDouble)
        validateMax("mapOptDecimal", min: Decimal128Wrapper(persistedValue: Decimal128(123.456)), max: Decimal128Wrapper(persistedValue: Decimal128(345.678)),
                    \Query<LinkToCustomPersistableCollections>.object.mapOptDecimal)
    }


    // @Count

    private func validateCount<Root: Object, T: RealmCollection>(_ name: String, _ lhs: (Query<Root>) -> Query<T>) {
        assertQuery(Root.self, "(object.\(name).@count == %@)", 3, count: 1) {
            lhs($0).count == 3
        }
        assertQuery(Root.self, "(object.\(name).@count == %@)", 0, count: 0) {
            lhs($0).count == 0
        }
        assertQuery(Root.self, "(object.\(name).@count != %@)", 3, count: 0) {
            lhs($0).count != 3
        }
        assertQuery(Root.self, "(object.\(name).@count != %@)", 2, count: 1) {
            lhs($0).count != 2
        }
        assertQuery(Root.self, "(object.\(name).@count < %@)", 3, count: 0) {
            lhs($0).count < 3
        }
        assertQuery(Root.self, "(object.\(name).@count < %@)", 4, count: 1) {
            lhs($0).count < 4
        }
        assertQuery(Root.self, "(object.\(name).@count > %@)", 2, count: 1) {
            lhs($0).count > 2
        }
        assertQuery(Root.self, "(object.\(name).@count > %@)", 3, count: 0) {
            lhs($0).count > 3
        }
        assertQuery(Root.self, "(object.\(name).@count <= %@)", 2, count: 0) {
            lhs($0).count <= 2
        }
        assertQuery(Root.self, "(object.\(name).@count <= %@)", 3, count: 1) {
            lhs($0).count <= 3
        }
        assertQuery(Root.self, "(object.\(name).@count >= %@)", 3, count: 1) {
            lhs($0).count >= 3
        }
        assertQuery(Root.self, "(object.\(name).@count >= %@)", 4, count: 0) {
            lhs($0).count >= 4
        }
    }
    private func validateCount<Root: Object, T: RealmKeyedCollection>(_ name: String, _ lhs: (Query<Root>) -> Query<T>) {
        assertQuery(Root.self, "(object.\(name).@count == %@)", 3, count: 1) {
            lhs($0).count == 3
        }
        assertQuery(Root.self, "(object.\(name).@count == %@)", 0, count: 0) {
            lhs($0).count == 0
        }
        assertQuery(Root.self, "(object.\(name).@count != %@)", 3, count: 0) {
            lhs($0).count != 3
        }
        assertQuery(Root.self, "(object.\(name).@count != %@)", 2, count: 1) {
            lhs($0).count != 2
        }
        assertQuery(Root.self, "(object.\(name).@count < %@)", 3, count: 0) {
            lhs($0).count < 3
        }
        assertQuery(Root.self, "(object.\(name).@count < %@)", 4, count: 1) {
            lhs($0).count < 4
        }
        assertQuery(Root.self, "(object.\(name).@count > %@)", 2, count: 1) {
            lhs($0).count > 2
        }
        assertQuery(Root.self, "(object.\(name).@count > %@)", 3, count: 0) {
            lhs($0).count > 3
        }
        assertQuery(Root.self, "(object.\(name).@count <= %@)", 2, count: 0) {
            lhs($0).count <= 2
        }
        assertQuery(Root.self, "(object.\(name).@count <= %@)", 3, count: 1) {
            lhs($0).count <= 3
        }
        assertQuery(Root.self, "(object.\(name).@count >= %@)", 3, count: 1) {
            lhs($0).count >= 3
        }
        assertQuery(Root.self, "(object.\(name).@count >= %@)", 4, count: 0) {
            lhs($0).count >= 4
        }
    }

    func testCollectionAggregatesCount() {
        initLinkedCollectionAggregatesObject()

        validateCount("arrayInt", \Query<LinkToModernAllTypesObject>.object.arrayInt)
        validateCount("arrayInt8", \Query<LinkToModernAllTypesObject>.object.arrayInt8)
        validateCount("arrayInt16", \Query<LinkToModernAllTypesObject>.object.arrayInt16)
        validateCount("arrayInt32", \Query<LinkToModernAllTypesObject>.object.arrayInt32)
        validateCount("arrayInt64", \Query<LinkToModernAllTypesObject>.object.arrayInt64)
        validateCount("arrayFloat", \Query<LinkToModernAllTypesObject>.object.arrayFloat)
        validateCount("arrayDouble", \Query<LinkToModernAllTypesObject>.object.arrayDouble)
        validateCount("arrayString", \Query<LinkToModernAllTypesObject>.object.arrayString)
        validateCount("arrayBinary", \Query<LinkToModernAllTypesObject>.object.arrayBinary)
        validateCount("arrayDate", \Query<LinkToModernAllTypesObject>.object.arrayDate)
        validateCount("arrayDecimal", \Query<LinkToModernAllTypesObject>.object.arrayDecimal)
        validateCount("arrayObjectId", \Query<LinkToModernAllTypesObject>.object.arrayObjectId)
        validateCount("arrayUuid", \Query<LinkToModernAllTypesObject>.object.arrayUuid)
        validateCount("arrayAny", \Query<LinkToModernAllTypesObject>.object.arrayAny)
        validateCount("listInt", \Query<LinkToModernCollectionsOfEnums>.object.listInt)
        validateCount("listInt8", \Query<LinkToModernCollectionsOfEnums>.object.listInt8)
        validateCount("listInt16", \Query<LinkToModernCollectionsOfEnums>.object.listInt16)
        validateCount("listInt32", \Query<LinkToModernCollectionsOfEnums>.object.listInt32)
        validateCount("listInt64", \Query<LinkToModernCollectionsOfEnums>.object.listInt64)
        validateCount("listFloat", \Query<LinkToModernCollectionsOfEnums>.object.listFloat)
        validateCount("listDouble", \Query<LinkToModernCollectionsOfEnums>.object.listDouble)
        validateCount("listString", \Query<LinkToModernCollectionsOfEnums>.object.listString)
        validateCount("listInt", \Query<LinkToCustomPersistableCollections>.object.listInt)
        validateCount("listInt8", \Query<LinkToCustomPersistableCollections>.object.listInt8)
        validateCount("listInt16", \Query<LinkToCustomPersistableCollections>.object.listInt16)
        validateCount("listInt32", \Query<LinkToCustomPersistableCollections>.object.listInt32)
        validateCount("listInt64", \Query<LinkToCustomPersistableCollections>.object.listInt64)
        validateCount("listFloat", \Query<LinkToCustomPersistableCollections>.object.listFloat)
        validateCount("listDouble", \Query<LinkToCustomPersistableCollections>.object.listDouble)
        validateCount("listString", \Query<LinkToCustomPersistableCollections>.object.listString)
        validateCount("listBinary", \Query<LinkToCustomPersistableCollections>.object.listBinary)
        validateCount("listDate", \Query<LinkToCustomPersistableCollections>.object.listDate)
        validateCount("listDecimal", \Query<LinkToCustomPersistableCollections>.object.listDecimal)
        validateCount("listObjectId", \Query<LinkToCustomPersistableCollections>.object.listObjectId)
        validateCount("listUuid", \Query<LinkToCustomPersistableCollections>.object.listUuid)
        validateCount("arrayOptInt", \Query<LinkToModernAllTypesObject>.object.arrayOptInt)
        validateCount("arrayOptInt8", \Query<LinkToModernAllTypesObject>.object.arrayOptInt8)
        validateCount("arrayOptInt16", \Query<LinkToModernAllTypesObject>.object.arrayOptInt16)
        validateCount("arrayOptInt32", \Query<LinkToModernAllTypesObject>.object.arrayOptInt32)
        validateCount("arrayOptInt64", \Query<LinkToModernAllTypesObject>.object.arrayOptInt64)
        validateCount("arrayOptFloat", \Query<LinkToModernAllTypesObject>.object.arrayOptFloat)
        validateCount("arrayOptDouble", \Query<LinkToModernAllTypesObject>.object.arrayOptDouble)
        validateCount("arrayOptString", \Query<LinkToModernAllTypesObject>.object.arrayOptString)
        validateCount("arrayOptBinary", \Query<LinkToModernAllTypesObject>.object.arrayOptBinary)
        validateCount("arrayOptDate", \Query<LinkToModernAllTypesObject>.object.arrayOptDate)
        validateCount("arrayOptDecimal", \Query<LinkToModernAllTypesObject>.object.arrayOptDecimal)
        validateCount("arrayOptObjectId", \Query<LinkToModernAllTypesObject>.object.arrayOptObjectId)
        validateCount("arrayOptUuid", \Query<LinkToModernAllTypesObject>.object.arrayOptUuid)
        validateCount("listIntOpt", \Query<LinkToModernCollectionsOfEnums>.object.listIntOpt)
        validateCount("listInt8Opt", \Query<LinkToModernCollectionsOfEnums>.object.listInt8Opt)
        validateCount("listInt16Opt", \Query<LinkToModernCollectionsOfEnums>.object.listInt16Opt)
        validateCount("listInt32Opt", \Query<LinkToModernCollectionsOfEnums>.object.listInt32Opt)
        validateCount("listInt64Opt", \Query<LinkToModernCollectionsOfEnums>.object.listInt64Opt)
        validateCount("listFloatOpt", \Query<LinkToModernCollectionsOfEnums>.object.listFloatOpt)
        validateCount("listDoubleOpt", \Query<LinkToModernCollectionsOfEnums>.object.listDoubleOpt)
        validateCount("listStringOpt", \Query<LinkToModernCollectionsOfEnums>.object.listStringOpt)
        validateCount("listOptInt", \Query<LinkToCustomPersistableCollections>.object.listOptInt)
        validateCount("listOptInt8", \Query<LinkToCustomPersistableCollections>.object.listOptInt8)
        validateCount("listOptInt16", \Query<LinkToCustomPersistableCollections>.object.listOptInt16)
        validateCount("listOptInt32", \Query<LinkToCustomPersistableCollections>.object.listOptInt32)
        validateCount("listOptInt64", \Query<LinkToCustomPersistableCollections>.object.listOptInt64)
        validateCount("listOptFloat", \Query<LinkToCustomPersistableCollections>.object.listOptFloat)
        validateCount("listOptDouble", \Query<LinkToCustomPersistableCollections>.object.listOptDouble)
        validateCount("listOptString", \Query<LinkToCustomPersistableCollections>.object.listOptString)
        validateCount("listOptBinary", \Query<LinkToCustomPersistableCollections>.object.listOptBinary)
        validateCount("listOptDate", \Query<LinkToCustomPersistableCollections>.object.listOptDate)
        validateCount("listOptDecimal", \Query<LinkToCustomPersistableCollections>.object.listOptDecimal)
        validateCount("listOptObjectId", \Query<LinkToCustomPersistableCollections>.object.listOptObjectId)
        validateCount("listOptUuid", \Query<LinkToCustomPersistableCollections>.object.listOptUuid)
        validateCount("setInt", \Query<LinkToModernAllTypesObject>.object.setInt)
        validateCount("setInt8", \Query<LinkToModernAllTypesObject>.object.setInt8)
        validateCount("setInt16", \Query<LinkToModernAllTypesObject>.object.setInt16)
        validateCount("setInt32", \Query<LinkToModernAllTypesObject>.object.setInt32)
        validateCount("setInt64", \Query<LinkToModernAllTypesObject>.object.setInt64)
        validateCount("setFloat", \Query<LinkToModernAllTypesObject>.object.setFloat)
        validateCount("setDouble", \Query<LinkToModernAllTypesObject>.object.setDouble)
        validateCount("setString", \Query<LinkToModernAllTypesObject>.object.setString)
        validateCount("setBinary", \Query<LinkToModernAllTypesObject>.object.setBinary)
        validateCount("setDate", \Query<LinkToModernAllTypesObject>.object.setDate)
        validateCount("setDecimal", \Query<LinkToModernAllTypesObject>.object.setDecimal)
        validateCount("setObjectId", \Query<LinkToModernAllTypesObject>.object.setObjectId)
        validateCount("setUuid", \Query<LinkToModernAllTypesObject>.object.setUuid)
        validateCount("setAny", \Query<LinkToModernAllTypesObject>.object.setAny)
        validateCount("setInt", \Query<LinkToModernCollectionsOfEnums>.object.setInt)
        validateCount("setInt8", \Query<LinkToModernCollectionsOfEnums>.object.setInt8)
        validateCount("setInt16", \Query<LinkToModernCollectionsOfEnums>.object.setInt16)
        validateCount("setInt32", \Query<LinkToModernCollectionsOfEnums>.object.setInt32)
        validateCount("setInt64", \Query<LinkToModernCollectionsOfEnums>.object.setInt64)
        validateCount("setFloat", \Query<LinkToModernCollectionsOfEnums>.object.setFloat)
        validateCount("setDouble", \Query<LinkToModernCollectionsOfEnums>.object.setDouble)
        validateCount("setString", \Query<LinkToModernCollectionsOfEnums>.object.setString)
        validateCount("setInt", \Query<LinkToCustomPersistableCollections>.object.setInt)
        validateCount("setInt8", \Query<LinkToCustomPersistableCollections>.object.setInt8)
        validateCount("setInt16", \Query<LinkToCustomPersistableCollections>.object.setInt16)
        validateCount("setInt32", \Query<LinkToCustomPersistableCollections>.object.setInt32)
        validateCount("setInt64", \Query<LinkToCustomPersistableCollections>.object.setInt64)
        validateCount("setFloat", \Query<LinkToCustomPersistableCollections>.object.setFloat)
        validateCount("setDouble", \Query<LinkToCustomPersistableCollections>.object.setDouble)
        validateCount("setString", \Query<LinkToCustomPersistableCollections>.object.setString)
        validateCount("setBinary", \Query<LinkToCustomPersistableCollections>.object.setBinary)
        validateCount("setDate", \Query<LinkToCustomPersistableCollections>.object.setDate)
        validateCount("setDecimal", \Query<LinkToCustomPersistableCollections>.object.setDecimal)
        validateCount("setObjectId", \Query<LinkToCustomPersistableCollections>.object.setObjectId)
        validateCount("setUuid", \Query<LinkToCustomPersistableCollections>.object.setUuid)
        validateCount("setOptInt", \Query<LinkToModernAllTypesObject>.object.setOptInt)
        validateCount("setOptInt8", \Query<LinkToModernAllTypesObject>.object.setOptInt8)
        validateCount("setOptInt16", \Query<LinkToModernAllTypesObject>.object.setOptInt16)
        validateCount("setOptInt32", \Query<LinkToModernAllTypesObject>.object.setOptInt32)
        validateCount("setOptInt64", \Query<LinkToModernAllTypesObject>.object.setOptInt64)
        validateCount("setOptFloat", \Query<LinkToModernAllTypesObject>.object.setOptFloat)
        validateCount("setOptDouble", \Query<LinkToModernAllTypesObject>.object.setOptDouble)
        validateCount("setOptString", \Query<LinkToModernAllTypesObject>.object.setOptString)
        validateCount("setOptBinary", \Query<LinkToModernAllTypesObject>.object.setOptBinary)
        validateCount("setOptDate", \Query<LinkToModernAllTypesObject>.object.setOptDate)
        validateCount("setOptDecimal", \Query<LinkToModernAllTypesObject>.object.setOptDecimal)
        validateCount("setOptObjectId", \Query<LinkToModernAllTypesObject>.object.setOptObjectId)
        validateCount("setOptUuid", \Query<LinkToModernAllTypesObject>.object.setOptUuid)
        validateCount("setIntOpt", \Query<LinkToModernCollectionsOfEnums>.object.setIntOpt)
        validateCount("setInt8Opt", \Query<LinkToModernCollectionsOfEnums>.object.setInt8Opt)
        validateCount("setInt16Opt", \Query<LinkToModernCollectionsOfEnums>.object.setInt16Opt)
        validateCount("setInt32Opt", \Query<LinkToModernCollectionsOfEnums>.object.setInt32Opt)
        validateCount("setInt64Opt", \Query<LinkToModernCollectionsOfEnums>.object.setInt64Opt)
        validateCount("setFloatOpt", \Query<LinkToModernCollectionsOfEnums>.object.setFloatOpt)
        validateCount("setDoubleOpt", \Query<LinkToModernCollectionsOfEnums>.object.setDoubleOpt)
        validateCount("setStringOpt", \Query<LinkToModernCollectionsOfEnums>.object.setStringOpt)
        validateCount("setOptInt", \Query<LinkToCustomPersistableCollections>.object.setOptInt)
        validateCount("setOptInt8", \Query<LinkToCustomPersistableCollections>.object.setOptInt8)
        validateCount("setOptInt16", \Query<LinkToCustomPersistableCollections>.object.setOptInt16)
        validateCount("setOptInt32", \Query<LinkToCustomPersistableCollections>.object.setOptInt32)
        validateCount("setOptInt64", \Query<LinkToCustomPersistableCollections>.object.setOptInt64)
        validateCount("setOptFloat", \Query<LinkToCustomPersistableCollections>.object.setOptFloat)
        validateCount("setOptDouble", \Query<LinkToCustomPersistableCollections>.object.setOptDouble)
        validateCount("setOptString", \Query<LinkToCustomPersistableCollections>.object.setOptString)
        validateCount("setOptBinary", \Query<LinkToCustomPersistableCollections>.object.setOptBinary)
        validateCount("setOptDate", \Query<LinkToCustomPersistableCollections>.object.setOptDate)
        validateCount("setOptDecimal", \Query<LinkToCustomPersistableCollections>.object.setOptDecimal)
        validateCount("setOptObjectId", \Query<LinkToCustomPersistableCollections>.object.setOptObjectId)
        validateCount("setOptUuid", \Query<LinkToCustomPersistableCollections>.object.setOptUuid)
        validateCount("mapInt", \Query<LinkToModernAllTypesObject>.object.mapInt)
        validateCount("mapInt8", \Query<LinkToModernAllTypesObject>.object.mapInt8)
        validateCount("mapInt16", \Query<LinkToModernAllTypesObject>.object.mapInt16)
        validateCount("mapInt32", \Query<LinkToModernAllTypesObject>.object.mapInt32)
        validateCount("mapInt64", \Query<LinkToModernAllTypesObject>.object.mapInt64)
        validateCount("mapFloat", \Query<LinkToModernAllTypesObject>.object.mapFloat)
        validateCount("mapDouble", \Query<LinkToModernAllTypesObject>.object.mapDouble)
        validateCount("mapString", \Query<LinkToModernAllTypesObject>.object.mapString)
        validateCount("mapBinary", \Query<LinkToModernAllTypesObject>.object.mapBinary)
        validateCount("mapDate", \Query<LinkToModernAllTypesObject>.object.mapDate)
        validateCount("mapDecimal", \Query<LinkToModernAllTypesObject>.object.mapDecimal)
        validateCount("mapObjectId", \Query<LinkToModernAllTypesObject>.object.mapObjectId)
        validateCount("mapUuid", \Query<LinkToModernAllTypesObject>.object.mapUuid)
        validateCount("mapAny", \Query<LinkToModernAllTypesObject>.object.mapAny)
        validateCount("mapInt", \Query<LinkToModernCollectionsOfEnums>.object.mapInt)
        validateCount("mapInt8", \Query<LinkToModernCollectionsOfEnums>.object.mapInt8)
        validateCount("mapInt16", \Query<LinkToModernCollectionsOfEnums>.object.mapInt16)
        validateCount("mapInt32", \Query<LinkToModernCollectionsOfEnums>.object.mapInt32)
        validateCount("mapInt64", \Query<LinkToModernCollectionsOfEnums>.object.mapInt64)
        validateCount("mapFloat", \Query<LinkToModernCollectionsOfEnums>.object.mapFloat)
        validateCount("mapDouble", \Query<LinkToModernCollectionsOfEnums>.object.mapDouble)
        validateCount("mapString", \Query<LinkToModernCollectionsOfEnums>.object.mapString)
        validateCount("mapInt", \Query<LinkToCustomPersistableCollections>.object.mapInt)
        validateCount("mapInt8", \Query<LinkToCustomPersistableCollections>.object.mapInt8)
        validateCount("mapInt16", \Query<LinkToCustomPersistableCollections>.object.mapInt16)
        validateCount("mapInt32", \Query<LinkToCustomPersistableCollections>.object.mapInt32)
        validateCount("mapInt64", \Query<LinkToCustomPersistableCollections>.object.mapInt64)
        validateCount("mapFloat", \Query<LinkToCustomPersistableCollections>.object.mapFloat)
        validateCount("mapDouble", \Query<LinkToCustomPersistableCollections>.object.mapDouble)
        validateCount("mapString", \Query<LinkToCustomPersistableCollections>.object.mapString)
        validateCount("mapBinary", \Query<LinkToCustomPersistableCollections>.object.mapBinary)
        validateCount("mapDate", \Query<LinkToCustomPersistableCollections>.object.mapDate)
        validateCount("mapDecimal", \Query<LinkToCustomPersistableCollections>.object.mapDecimal)
        validateCount("mapObjectId", \Query<LinkToCustomPersistableCollections>.object.mapObjectId)
        validateCount("mapUuid", \Query<LinkToCustomPersistableCollections>.object.mapUuid)
        validateCount("mapOptInt", \Query<LinkToModernAllTypesObject>.object.mapOptInt)
        validateCount("mapOptInt8", \Query<LinkToModernAllTypesObject>.object.mapOptInt8)
        validateCount("mapOptInt16", \Query<LinkToModernAllTypesObject>.object.mapOptInt16)
        validateCount("mapOptInt32", \Query<LinkToModernAllTypesObject>.object.mapOptInt32)
        validateCount("mapOptInt64", \Query<LinkToModernAllTypesObject>.object.mapOptInt64)
        validateCount("mapOptFloat", \Query<LinkToModernAllTypesObject>.object.mapOptFloat)
        validateCount("mapOptDouble", \Query<LinkToModernAllTypesObject>.object.mapOptDouble)
        validateCount("mapOptString", \Query<LinkToModernAllTypesObject>.object.mapOptString)
        validateCount("mapOptBinary", \Query<LinkToModernAllTypesObject>.object.mapOptBinary)
        validateCount("mapOptDate", \Query<LinkToModernAllTypesObject>.object.mapOptDate)
        validateCount("mapOptDecimal", \Query<LinkToModernAllTypesObject>.object.mapOptDecimal)
        validateCount("mapOptObjectId", \Query<LinkToModernAllTypesObject>.object.mapOptObjectId)
        validateCount("mapOptUuid", \Query<LinkToModernAllTypesObject>.object.mapOptUuid)
        validateCount("mapIntOpt", \Query<LinkToModernCollectionsOfEnums>.object.mapIntOpt)
        validateCount("mapInt8Opt", \Query<LinkToModernCollectionsOfEnums>.object.mapInt8Opt)
        validateCount("mapInt16Opt", \Query<LinkToModernCollectionsOfEnums>.object.mapInt16Opt)
        validateCount("mapInt32Opt", \Query<LinkToModernCollectionsOfEnums>.object.mapInt32Opt)
        validateCount("mapInt64Opt", \Query<LinkToModernCollectionsOfEnums>.object.mapInt64Opt)
        validateCount("mapFloatOpt", \Query<LinkToModernCollectionsOfEnums>.object.mapFloatOpt)
        validateCount("mapDoubleOpt", \Query<LinkToModernCollectionsOfEnums>.object.mapDoubleOpt)
        validateCount("mapStringOpt", \Query<LinkToModernCollectionsOfEnums>.object.mapStringOpt)
        validateCount("mapOptInt", \Query<LinkToCustomPersistableCollections>.object.mapOptInt)
        validateCount("mapOptInt8", \Query<LinkToCustomPersistableCollections>.object.mapOptInt8)
        validateCount("mapOptInt16", \Query<LinkToCustomPersistableCollections>.object.mapOptInt16)
        validateCount("mapOptInt32", \Query<LinkToCustomPersistableCollections>.object.mapOptInt32)
        validateCount("mapOptInt64", \Query<LinkToCustomPersistableCollections>.object.mapOptInt64)
        validateCount("mapOptFloat", \Query<LinkToCustomPersistableCollections>.object.mapOptFloat)
        validateCount("mapOptDouble", \Query<LinkToCustomPersistableCollections>.object.mapOptDouble)
        validateCount("mapOptString", \Query<LinkToCustomPersistableCollections>.object.mapOptString)
        validateCount("mapOptBinary", \Query<LinkToCustomPersistableCollections>.object.mapOptBinary)
        validateCount("mapOptDate", \Query<LinkToCustomPersistableCollections>.object.mapOptDate)
        validateCount("mapOptDecimal", \Query<LinkToCustomPersistableCollections>.object.mapOptDecimal)
        validateCount("mapOptObjectId", \Query<LinkToCustomPersistableCollections>.object.mapOptObjectId)
        validateCount("mapOptUuid", \Query<LinkToCustomPersistableCollections>.object.mapOptUuid)
    }

    // MARK: - Keypath Collection Aggregations

    private func validateKeypathAverage<Root: Object, T>(_ name: String, _ average: T, _ min: T, _ lhs: (Query<Root>) -> Query<T>)
            where T: _Persistable & QueryValue, T.PersistedType: _QueryNumeric {
        assertQuery(Root.self, "(list.@avg.\(name) == %@)", average, count: 1) {
            lhs($0).avg == average
        }
        assertQuery(Root.self, "(list.@avg.\(name) == %@)", min, count: 0) {
            lhs($0).avg == min
        }
        assertQuery(Root.self, "(list.@avg.\(name) != %@)", average, count: 0) {
            lhs($0).avg != average
        }
        assertQuery(Root.self, "(list.@avg.\(name) != %@)", min, count: 1) {
            lhs($0).avg != min
        }
        assertQuery(Root.self, "(list.@avg.\(name) > %@)", average, count: 0) {
            lhs($0).avg > average
        }
        assertQuery(Root.self, "(list.@avg.\(name) > %@)", min, count: 1) {
            lhs($0).avg > min
        }
        assertQuery(Root.self, "(list.@avg.\(name) < %@)", average, count: 0) {
            lhs($0).avg < average
        }
        assertQuery(Root.self, "(list.@avg.\(name) >= %@)", average, count: 1) {
            lhs($0).avg >= average
        }
        assertQuery(Root.self, "(list.@avg.\(name) <= %@)", average, count: 1) {
            lhs($0).avg <= average
        }
    }

    func testKeypathCollectionAggregatesAvg() {
        createKeypathCollectionAggregatesObject()

        validateKeypathAverage("intCol", Int.average(), 1,
                    \Query<LinkToModernAllTypesObject>.list.intCol)
        validateKeypathAverage("int8Col", Int8.average(), Int8(8),
                    \Query<LinkToModernAllTypesObject>.list.int8Col)
        validateKeypathAverage("int16Col", Int16.average(), Int16(16),
                    \Query<LinkToModernAllTypesObject>.list.int16Col)
        validateKeypathAverage("int32Col", Int32.average(), Int32(32),
                    \Query<LinkToModernAllTypesObject>.list.int32Col)
        validateKeypathAverage("int64Col", Int64.average(), Int64(64),
                    \Query<LinkToModernAllTypesObject>.list.int64Col)
        validateKeypathAverage("floatCol", Float.average(), Float(5.55444333),
                    \Query<LinkToModernAllTypesObject>.list.floatCol)
        validateKeypathAverage("doubleCol", Double.average(), 123.456,
                    \Query<LinkToModernAllTypesObject>.list.doubleCol)
        validateKeypathAverage("decimalCol", Decimal128.average(), Decimal128(123.456),
                    \Query<LinkToModernAllTypesObject>.list.decimalCol)
        validateKeypathAverage("intEnumCol", ModernIntEnum.average(), ModernIntEnum.value1.rawValue,
                    \Query<LinkToModernAllTypesObject>.list.intEnumCol.rawValue)
        validateKeypathAverage("int", IntWrapper.average(), IntWrapper(persistedValue: 1),
                    \Query<LinkToAllCustomPersistableTypes>.list.int)
        validateKeypathAverage("int8", Int8Wrapper.average(), Int8Wrapper(persistedValue: Int8(8)),
                    \Query<LinkToAllCustomPersistableTypes>.list.int8)
        validateKeypathAverage("int16", Int16Wrapper.average(), Int16Wrapper(persistedValue: Int16(16)),
                    \Query<LinkToAllCustomPersistableTypes>.list.int16)
        validateKeypathAverage("int32", Int32Wrapper.average(), Int32Wrapper(persistedValue: Int32(32)),
                    \Query<LinkToAllCustomPersistableTypes>.list.int32)
        validateKeypathAverage("int64", Int64Wrapper.average(), Int64Wrapper(persistedValue: Int64(64)),
                    \Query<LinkToAllCustomPersistableTypes>.list.int64)
        validateKeypathAverage("float", FloatWrapper.average(), FloatWrapper(persistedValue: Float(5.55444333)),
                    \Query<LinkToAllCustomPersistableTypes>.list.float)
        validateKeypathAverage("double", DoubleWrapper.average(), DoubleWrapper(persistedValue: 123.456),
                    \Query<LinkToAllCustomPersistableTypes>.list.double)
        validateKeypathAverage("decimal", Decimal128Wrapper.average(), Decimal128Wrapper(persistedValue: Decimal128(123.456)),
                    \Query<LinkToAllCustomPersistableTypes>.list.decimal)
        validateKeypathAverage("optIntCol", Int?.average(), 1,
                    \Query<LinkToModernAllTypesObject>.list.optIntCol)
        validateKeypathAverage("optInt8Col", Int8?.average(), Int8(8),
                    \Query<LinkToModernAllTypesObject>.list.optInt8Col)
        validateKeypathAverage("optInt16Col", Int16?.average(), Int16(16),
                    \Query<LinkToModernAllTypesObject>.list.optInt16Col)
        validateKeypathAverage("optInt32Col", Int32?.average(), Int32(32),
                    \Query<LinkToModernAllTypesObject>.list.optInt32Col)
        validateKeypathAverage("optInt64Col", Int64?.average(), Int64(64),
                    \Query<LinkToModernAllTypesObject>.list.optInt64Col)
        validateKeypathAverage("optFloatCol", Float?.average(), Float(5.55444333),
                    \Query<LinkToModernAllTypesObject>.list.optFloatCol)
        validateKeypathAverage("optDoubleCol", Double?.average(), 123.456,
                    \Query<LinkToModernAllTypesObject>.list.optDoubleCol)
        validateKeypathAverage("optDecimalCol", Decimal128?.average(), Decimal128(123.456),
                    \Query<LinkToModernAllTypesObject>.list.optDecimalCol)
        validateKeypathAverage("optIntEnumCol", ModernIntEnum.average(), ModernIntEnum.value1.rawValue,
                    \Query<LinkToModernAllTypesObject>.list.optIntEnumCol.rawValue)
        validateKeypathAverage("optInt", IntWrapper?.average(), IntWrapper(persistedValue: 1),
                    \Query<LinkToAllCustomPersistableTypes>.list.optInt)
        validateKeypathAverage("optInt8", Int8Wrapper?.average(), Int8Wrapper(persistedValue: Int8(8)),
                    \Query<LinkToAllCustomPersistableTypes>.list.optInt8)
        validateKeypathAverage("optInt16", Int16Wrapper?.average(), Int16Wrapper(persistedValue: Int16(16)),
                    \Query<LinkToAllCustomPersistableTypes>.list.optInt16)
        validateKeypathAverage("optInt32", Int32Wrapper?.average(), Int32Wrapper(persistedValue: Int32(32)),
                    \Query<LinkToAllCustomPersistableTypes>.list.optInt32)
        validateKeypathAverage("optInt64", Int64Wrapper?.average(), Int64Wrapper(persistedValue: Int64(64)),
                    \Query<LinkToAllCustomPersistableTypes>.list.optInt64)
        validateKeypathAverage("optFloat", FloatWrapper?.average(), FloatWrapper(persistedValue: Float(5.55444333)),
                    \Query<LinkToAllCustomPersistableTypes>.list.optFloat)
        validateKeypathAverage("optDouble", DoubleWrapper?.average(), DoubleWrapper(persistedValue: 123.456),
                    \Query<LinkToAllCustomPersistableTypes>.list.optDouble)
        validateKeypathAverage("optDecimal", Decimal128Wrapper?.average(), Decimal128Wrapper(persistedValue: Decimal128(123.456)),
                    \Query<LinkToAllCustomPersistableTypes>.list.optDecimal)
    }

    private func validateKeypathSum<Root: Object, T>(_ name: String, _ sum: T, _ min: T, _ lhs: (Query<Root>) -> Query<T>)
            where T: _Persistable & QueryValue, T.PersistedType: _QueryNumeric {
        assertQuery(Root.self, "(list.@sum.\(name) == %@)", sum, count: 1) {
            lhs($0).sum == sum
        }
        assertQuery(Root.self, "(list.@sum.\(name) == %@)", min, count: 0) {
            lhs($0).sum == min
        }
        assertQuery(Root.self, "(list.@sum.\(name) != %@)", sum, count: 0) {
            lhs($0).sum != sum
        }
        assertQuery(Root.self, "(list.@sum.\(name) != %@)", min, count: 1) {
            lhs($0).sum != min
        }
        assertQuery(Root.self, "(list.@sum.\(name) > %@)", sum, count: 0) {
            lhs($0).sum > sum
        }
        assertQuery(Root.self, "(list.@sum.\(name) > %@)", min, count: 1) {
            lhs($0).sum > min
        }
        assertQuery(Root.self, "(list.@sum.\(name) < %@)", sum, count: 0) {
            lhs($0).sum < sum
        }
        assertQuery(Root.self, "(list.@sum.\(name) >= %@)", sum, count: 1) {
            lhs($0).sum >= sum
        }
        assertQuery(Root.self, "(list.@sum.\(name) <= %@)", sum, count: 1) {
            lhs($0).sum <= sum
        }
    }

    func testKeypathCollectionAggregatesSum() {
        createKeypathCollectionAggregatesObject()

        validateKeypathSum("intCol", Int.sum(), 1,
                    \Query<LinkToModernAllTypesObject>.list.intCol)
        validateKeypathSum("int8Col", Int8.sum(), Int8(8),
                    \Query<LinkToModernAllTypesObject>.list.int8Col)
        validateKeypathSum("int16Col", Int16.sum(), Int16(16),
                    \Query<LinkToModernAllTypesObject>.list.int16Col)
        validateKeypathSum("int32Col", Int32.sum(), Int32(32),
                    \Query<LinkToModernAllTypesObject>.list.int32Col)
        validateKeypathSum("int64Col", Int64.sum(), Int64(64),
                    \Query<LinkToModernAllTypesObject>.list.int64Col)
        validateKeypathSum("floatCol", Float.sum(), Float(5.55444333),
                    \Query<LinkToModernAllTypesObject>.list.floatCol)
        validateKeypathSum("doubleCol", Double.sum(), 123.456,
                    \Query<LinkToModernAllTypesObject>.list.doubleCol)
        validateKeypathSum("decimalCol", Decimal128.sum(), Decimal128(123.456),
                    \Query<LinkToModernAllTypesObject>.list.decimalCol)
        validateKeypathSum("intEnumCol", ModernIntEnum.sum(), ModernIntEnum.value1.rawValue,
                    \Query<LinkToModernAllTypesObject>.list.intEnumCol.rawValue)
        validateKeypathSum("int", IntWrapper.sum(), IntWrapper(persistedValue: 1),
                    \Query<LinkToAllCustomPersistableTypes>.list.int)
        validateKeypathSum("int8", Int8Wrapper.sum(), Int8Wrapper(persistedValue: Int8(8)),
                    \Query<LinkToAllCustomPersistableTypes>.list.int8)
        validateKeypathSum("int16", Int16Wrapper.sum(), Int16Wrapper(persistedValue: Int16(16)),
                    \Query<LinkToAllCustomPersistableTypes>.list.int16)
        validateKeypathSum("int32", Int32Wrapper.sum(), Int32Wrapper(persistedValue: Int32(32)),
                    \Query<LinkToAllCustomPersistableTypes>.list.int32)
        validateKeypathSum("int64", Int64Wrapper.sum(), Int64Wrapper(persistedValue: Int64(64)),
                    \Query<LinkToAllCustomPersistableTypes>.list.int64)
        validateKeypathSum("float", FloatWrapper.sum(), FloatWrapper(persistedValue: Float(5.55444333)),
                    \Query<LinkToAllCustomPersistableTypes>.list.float)
        validateKeypathSum("double", DoubleWrapper.sum(), DoubleWrapper(persistedValue: 123.456),
                    \Query<LinkToAllCustomPersistableTypes>.list.double)
        validateKeypathSum("decimal", Decimal128Wrapper.sum(), Decimal128Wrapper(persistedValue: Decimal128(123.456)),
                    \Query<LinkToAllCustomPersistableTypes>.list.decimal)
        validateKeypathSum("optIntCol", Int?.sum(), 1,
                    \Query<LinkToModernAllTypesObject>.list.optIntCol)
        validateKeypathSum("optInt8Col", Int8?.sum(), Int8(8),
                    \Query<LinkToModernAllTypesObject>.list.optInt8Col)
        validateKeypathSum("optInt16Col", Int16?.sum(), Int16(16),
                    \Query<LinkToModernAllTypesObject>.list.optInt16Col)
        validateKeypathSum("optInt32Col", Int32?.sum(), Int32(32),
                    \Query<LinkToModernAllTypesObject>.list.optInt32Col)
        validateKeypathSum("optInt64Col", Int64?.sum(), Int64(64),
                    \Query<LinkToModernAllTypesObject>.list.optInt64Col)
        validateKeypathSum("optFloatCol", Float?.sum(), Float(5.55444333),
                    \Query<LinkToModernAllTypesObject>.list.optFloatCol)
        validateKeypathSum("optDoubleCol", Double?.sum(), 123.456,
                    \Query<LinkToModernAllTypesObject>.list.optDoubleCol)
        validateKeypathSum("optDecimalCol", Decimal128?.sum(), Decimal128(123.456),
                    \Query<LinkToModernAllTypesObject>.list.optDecimalCol)
        validateKeypathSum("optIntEnumCol", ModernIntEnum.sum(), ModernIntEnum.value1.rawValue,
                    \Query<LinkToModernAllTypesObject>.list.optIntEnumCol.rawValue)
        validateKeypathSum("optInt", IntWrapper?.sum(), IntWrapper(persistedValue: 1),
                    \Query<LinkToAllCustomPersistableTypes>.list.optInt)
        validateKeypathSum("optInt8", Int8Wrapper?.sum(), Int8Wrapper(persistedValue: Int8(8)),
                    \Query<LinkToAllCustomPersistableTypes>.list.optInt8)
        validateKeypathSum("optInt16", Int16Wrapper?.sum(), Int16Wrapper(persistedValue: Int16(16)),
                    \Query<LinkToAllCustomPersistableTypes>.list.optInt16)
        validateKeypathSum("optInt32", Int32Wrapper?.sum(), Int32Wrapper(persistedValue: Int32(32)),
                    \Query<LinkToAllCustomPersistableTypes>.list.optInt32)
        validateKeypathSum("optInt64", Int64Wrapper?.sum(), Int64Wrapper(persistedValue: Int64(64)),
                    \Query<LinkToAllCustomPersistableTypes>.list.optInt64)
        validateKeypathSum("optFloat", FloatWrapper?.sum(), FloatWrapper(persistedValue: Float(5.55444333)),
                    \Query<LinkToAllCustomPersistableTypes>.list.optFloat)
        validateKeypathSum("optDouble", DoubleWrapper?.sum(), DoubleWrapper(persistedValue: 123.456),
                    \Query<LinkToAllCustomPersistableTypes>.list.optDouble)
        validateKeypathSum("optDecimal", Decimal128Wrapper?.sum(), Decimal128Wrapper(persistedValue: Decimal128(123.456)),
                    \Query<LinkToAllCustomPersistableTypes>.list.optDecimal)
    }


    private func validateKeypathMin<Root: Object, T>(_ name: String, min: T, max: T, _ lhs: (Query<Root>) -> Query<T>)
            where T: _Persistable & QueryValue, T.PersistedType: _QueryNumeric {
        assertQuery(Root.self, "(list.@min.\(name) == %@)", min, count: 1) {
            lhs($0).min == min
        }
        assertQuery(Root.self, "(list.@min.\(name) == %@)", max, count: 0) {
            lhs($0).min == max
        }
        assertQuery(Root.self, "(list.@min.\(name) != %@)", min, count: 0) {
            lhs($0).min != min
        }
        assertQuery(Root.self, "(list.@min.\(name) != %@)", max, count: 1) {
            lhs($0).min != max
        }
        assertQuery(Root.self, "(list.@min.\(name) > %@)", min, count: 0) {
            lhs($0).min > min
        }
        assertQuery(Root.self, "(list.@min.\(name) < %@)", min, count: 0) {
            lhs($0).min < min
        }
        assertQuery(Root.self, "(list.@min.\(name) >= %@)", min, count: 1) {
            lhs($0).min >= min
        }
        assertQuery(Root.self, "(list.@min.\(name) <= %@)", min, count: 1) {
            lhs($0).min <= min
        }
    }

    func testKeypathCollectionAggregatesMin() {
        createKeypathCollectionAggregatesObject()

        validateKeypathMin("intCol", min: 1, max: 5,
                    \Query<LinkToModernAllTypesObject>.list.intCol)
        validateKeypathMin("int8Col", min: Int8(8), max: Int8(10),
                    \Query<LinkToModernAllTypesObject>.list.int8Col)
        validateKeypathMin("int16Col", min: Int16(16), max: Int16(18),
                    \Query<LinkToModernAllTypesObject>.list.int16Col)
        validateKeypathMin("int32Col", min: Int32(32), max: Int32(34),
                    \Query<LinkToModernAllTypesObject>.list.int32Col)
        validateKeypathMin("int64Col", min: Int64(64), max: Int64(66),
                    \Query<LinkToModernAllTypesObject>.list.int64Col)
        validateKeypathMin("floatCol", min: Float(5.55444333), max: Float(7.55444333),
                    \Query<LinkToModernAllTypesObject>.list.floatCol)
        validateKeypathMin("doubleCol", min: 123.456, max: 345.678,
                    \Query<LinkToModernAllTypesObject>.list.doubleCol)
        validateKeypathMin("dateCol", min: Date(timeIntervalSince1970: 1000000), max: Date(timeIntervalSince1970: 3000000),
                    \Query<LinkToModernAllTypesObject>.list.dateCol)
        validateKeypathMin("decimalCol", min: Decimal128(123.456), max: Decimal128(345.678),
                    \Query<LinkToModernAllTypesObject>.list.decimalCol)
        validateKeypathMin("intEnumCol", min: ModernIntEnum.value1.rawValue, max: ModernIntEnum.value3.rawValue,
                    \Query<LinkToModernAllTypesObject>.list.intEnumCol.rawValue)
        validateKeypathMin("int", min: IntWrapper(persistedValue: 1), max: IntWrapper(persistedValue: 5),
                    \Query<LinkToAllCustomPersistableTypes>.list.int)
        validateKeypathMin("int8", min: Int8Wrapper(persistedValue: Int8(8)), max: Int8Wrapper(persistedValue: Int8(10)),
                    \Query<LinkToAllCustomPersistableTypes>.list.int8)
        validateKeypathMin("int16", min: Int16Wrapper(persistedValue: Int16(16)), max: Int16Wrapper(persistedValue: Int16(18)),
                    \Query<LinkToAllCustomPersistableTypes>.list.int16)
        validateKeypathMin("int32", min: Int32Wrapper(persistedValue: Int32(32)), max: Int32Wrapper(persistedValue: Int32(34)),
                    \Query<LinkToAllCustomPersistableTypes>.list.int32)
        validateKeypathMin("int64", min: Int64Wrapper(persistedValue: Int64(64)), max: Int64Wrapper(persistedValue: Int64(66)),
                    \Query<LinkToAllCustomPersistableTypes>.list.int64)
        validateKeypathMin("float", min: FloatWrapper(persistedValue: Float(5.55444333)), max: FloatWrapper(persistedValue: Float(7.55444333)),
                    \Query<LinkToAllCustomPersistableTypes>.list.float)
        validateKeypathMin("double", min: DoubleWrapper(persistedValue: 123.456), max: DoubleWrapper(persistedValue: 345.678),
                    \Query<LinkToAllCustomPersistableTypes>.list.double)
        validateKeypathMin("date", min: DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)), max: DateWrapper(persistedValue: Date(timeIntervalSince1970: 3000000)),
                    \Query<LinkToAllCustomPersistableTypes>.list.date)
        validateKeypathMin("decimal", min: Decimal128Wrapper(persistedValue: Decimal128(123.456)), max: Decimal128Wrapper(persistedValue: Decimal128(345.678)),
                    \Query<LinkToAllCustomPersistableTypes>.list.decimal)
        validateKeypathMin("optIntCol", min: 1, max: 5,
                    \Query<LinkToModernAllTypesObject>.list.optIntCol)
        validateKeypathMin("optInt8Col", min: Int8(8), max: Int8(10),
                    \Query<LinkToModernAllTypesObject>.list.optInt8Col)
        validateKeypathMin("optInt16Col", min: Int16(16), max: Int16(18),
                    \Query<LinkToModernAllTypesObject>.list.optInt16Col)
        validateKeypathMin("optInt32Col", min: Int32(32), max: Int32(34),
                    \Query<LinkToModernAllTypesObject>.list.optInt32Col)
        validateKeypathMin("optInt64Col", min: Int64(64), max: Int64(66),
                    \Query<LinkToModernAllTypesObject>.list.optInt64Col)
        validateKeypathMin("optFloatCol", min: Float(5.55444333), max: Float(7.55444333),
                    \Query<LinkToModernAllTypesObject>.list.optFloatCol)
        validateKeypathMin("optDoubleCol", min: 123.456, max: 345.678,
                    \Query<LinkToModernAllTypesObject>.list.optDoubleCol)
        validateKeypathMin("optDateCol", min: Date(timeIntervalSince1970: 1000000), max: Date(timeIntervalSince1970: 3000000),
                    \Query<LinkToModernAllTypesObject>.list.optDateCol)
        validateKeypathMin("optDecimalCol", min: Decimal128(123.456), max: Decimal128(345.678),
                    \Query<LinkToModernAllTypesObject>.list.optDecimalCol)
        validateKeypathMin("optIntEnumCol", min: ModernIntEnum.value1.rawValue, max: ModernIntEnum.value3.rawValue,
                    \Query<LinkToModernAllTypesObject>.list.optIntEnumCol.rawValue)
        validateKeypathMin("optInt", min: IntWrapper(persistedValue: 1), max: IntWrapper(persistedValue: 5),
                    \Query<LinkToAllCustomPersistableTypes>.list.optInt)
        validateKeypathMin("optInt8", min: Int8Wrapper(persistedValue: Int8(8)), max: Int8Wrapper(persistedValue: Int8(10)),
                    \Query<LinkToAllCustomPersistableTypes>.list.optInt8)
        validateKeypathMin("optInt16", min: Int16Wrapper(persistedValue: Int16(16)), max: Int16Wrapper(persistedValue: Int16(18)),
                    \Query<LinkToAllCustomPersistableTypes>.list.optInt16)
        validateKeypathMin("optInt32", min: Int32Wrapper(persistedValue: Int32(32)), max: Int32Wrapper(persistedValue: Int32(34)),
                    \Query<LinkToAllCustomPersistableTypes>.list.optInt32)
        validateKeypathMin("optInt64", min: Int64Wrapper(persistedValue: Int64(64)), max: Int64Wrapper(persistedValue: Int64(66)),
                    \Query<LinkToAllCustomPersistableTypes>.list.optInt64)
        validateKeypathMin("optFloat", min: FloatWrapper(persistedValue: Float(5.55444333)), max: FloatWrapper(persistedValue: Float(7.55444333)),
                    \Query<LinkToAllCustomPersistableTypes>.list.optFloat)
        validateKeypathMin("optDouble", min: DoubleWrapper(persistedValue: 123.456), max: DoubleWrapper(persistedValue: 345.678),
                    \Query<LinkToAllCustomPersistableTypes>.list.optDouble)
        validateKeypathMin("optDate", min: DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)), max: DateWrapper(persistedValue: Date(timeIntervalSince1970: 3000000)),
                    \Query<LinkToAllCustomPersistableTypes>.list.optDate)
        validateKeypathMin("optDecimal", min: Decimal128Wrapper(persistedValue: Decimal128(123.456)), max: Decimal128Wrapper(persistedValue: Decimal128(345.678)),
                    \Query<LinkToAllCustomPersistableTypes>.list.optDecimal)
    }

    private func validateKeypathMax<Root: Object, T>(_ name: String, min: T, max: T, _ lhs: (Query<Root>) -> Query<T>)
            where T: _Persistable & QueryValue, T.PersistedType: _QueryNumeric {
        assertQuery(Root.self, "(list.@max.\(name) == %@)", max, count: 1) {
            lhs($0).max == max
        }
        assertQuery(Root.self, "(list.@max.\(name) == %@)", min, count: 0) {
            lhs($0).max == min
        }
        assertQuery(Root.self, "(list.@max.\(name) != %@)", max, count: 0) {
            lhs($0).max != max
        }
        assertQuery(Root.self, "(list.@max.\(name) != %@)", min, count: 1) {
            lhs($0).max != min
        }
        assertQuery(Root.self, "(list.@max.\(name) > %@)", max, count: 0) {
            lhs($0).max > max
        }
        assertQuery(Root.self, "(list.@max.\(name) < %@)", max, count: 0) {
            lhs($0).max < max
        }
        assertQuery(Root.self, "(list.@max.\(name) >= %@)", max, count: 1) {
            lhs($0).max >= max
        }
        assertQuery(Root.self, "(list.@max.\(name) <= %@)", max, count: 1) {
            lhs($0).max <= max
        }
    }

    func testKeypathCollectionAggregatesMax() {
        createKeypathCollectionAggregatesObject()

        validateKeypathMax("intCol", min: 1, max: 5,
                    \Query<LinkToModernAllTypesObject>.list.intCol)
        validateKeypathMax("int8Col", min: Int8(8), max: Int8(10),
                    \Query<LinkToModernAllTypesObject>.list.int8Col)
        validateKeypathMax("int16Col", min: Int16(16), max: Int16(18),
                    \Query<LinkToModernAllTypesObject>.list.int16Col)
        validateKeypathMax("int32Col", min: Int32(32), max: Int32(34),
                    \Query<LinkToModernAllTypesObject>.list.int32Col)
        validateKeypathMax("int64Col", min: Int64(64), max: Int64(66),
                    \Query<LinkToModernAllTypesObject>.list.int64Col)
        validateKeypathMax("floatCol", min: Float(5.55444333), max: Float(7.55444333),
                    \Query<LinkToModernAllTypesObject>.list.floatCol)
        validateKeypathMax("doubleCol", min: 123.456, max: 345.678,
                    \Query<LinkToModernAllTypesObject>.list.doubleCol)
        validateKeypathMax("dateCol", min: Date(timeIntervalSince1970: 1000000), max: Date(timeIntervalSince1970: 3000000),
                    \Query<LinkToModernAllTypesObject>.list.dateCol)
        validateKeypathMax("decimalCol", min: Decimal128(123.456), max: Decimal128(345.678),
                    \Query<LinkToModernAllTypesObject>.list.decimalCol)
        validateKeypathMax("intEnumCol", min: ModernIntEnum.value1.rawValue, max: ModernIntEnum.value3.rawValue,
                    \Query<LinkToModernAllTypesObject>.list.intEnumCol.rawValue)
        validateKeypathMax("int", min: IntWrapper(persistedValue: 1), max: IntWrapper(persistedValue: 5),
                    \Query<LinkToAllCustomPersistableTypes>.list.int)
        validateKeypathMax("int8", min: Int8Wrapper(persistedValue: Int8(8)), max: Int8Wrapper(persistedValue: Int8(10)),
                    \Query<LinkToAllCustomPersistableTypes>.list.int8)
        validateKeypathMax("int16", min: Int16Wrapper(persistedValue: Int16(16)), max: Int16Wrapper(persistedValue: Int16(18)),
                    \Query<LinkToAllCustomPersistableTypes>.list.int16)
        validateKeypathMax("int32", min: Int32Wrapper(persistedValue: Int32(32)), max: Int32Wrapper(persistedValue: Int32(34)),
                    \Query<LinkToAllCustomPersistableTypes>.list.int32)
        validateKeypathMax("int64", min: Int64Wrapper(persistedValue: Int64(64)), max: Int64Wrapper(persistedValue: Int64(66)),
                    \Query<LinkToAllCustomPersistableTypes>.list.int64)
        validateKeypathMax("float", min: FloatWrapper(persistedValue: Float(5.55444333)), max: FloatWrapper(persistedValue: Float(7.55444333)),
                    \Query<LinkToAllCustomPersistableTypes>.list.float)
        validateKeypathMax("double", min: DoubleWrapper(persistedValue: 123.456), max: DoubleWrapper(persistedValue: 345.678),
                    \Query<LinkToAllCustomPersistableTypes>.list.double)
        validateKeypathMax("date", min: DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)), max: DateWrapper(persistedValue: Date(timeIntervalSince1970: 3000000)),
                    \Query<LinkToAllCustomPersistableTypes>.list.date)
        validateKeypathMax("decimal", min: Decimal128Wrapper(persistedValue: Decimal128(123.456)), max: Decimal128Wrapper(persistedValue: Decimal128(345.678)),
                    \Query<LinkToAllCustomPersistableTypes>.list.decimal)
        validateKeypathMax("optIntCol", min: 1, max: 5,
                    \Query<LinkToModernAllTypesObject>.list.optIntCol)
        validateKeypathMax("optInt8Col", min: Int8(8), max: Int8(10),
                    \Query<LinkToModernAllTypesObject>.list.optInt8Col)
        validateKeypathMax("optInt16Col", min: Int16(16), max: Int16(18),
                    \Query<LinkToModernAllTypesObject>.list.optInt16Col)
        validateKeypathMax("optInt32Col", min: Int32(32), max: Int32(34),
                    \Query<LinkToModernAllTypesObject>.list.optInt32Col)
        validateKeypathMax("optInt64Col", min: Int64(64), max: Int64(66),
                    \Query<LinkToModernAllTypesObject>.list.optInt64Col)
        validateKeypathMax("optFloatCol", min: Float(5.55444333), max: Float(7.55444333),
                    \Query<LinkToModernAllTypesObject>.list.optFloatCol)
        validateKeypathMax("optDoubleCol", min: 123.456, max: 345.678,
                    \Query<LinkToModernAllTypesObject>.list.optDoubleCol)
        validateKeypathMax("optDateCol", min: Date(timeIntervalSince1970: 1000000), max: Date(timeIntervalSince1970: 3000000),
                    \Query<LinkToModernAllTypesObject>.list.optDateCol)
        validateKeypathMax("optDecimalCol", min: Decimal128(123.456), max: Decimal128(345.678),
                    \Query<LinkToModernAllTypesObject>.list.optDecimalCol)
        validateKeypathMax("optIntEnumCol", min: ModernIntEnum.value1.rawValue, max: ModernIntEnum.value3.rawValue,
                    \Query<LinkToModernAllTypesObject>.list.optIntEnumCol.rawValue)
        validateKeypathMax("optInt", min: IntWrapper(persistedValue: 1), max: IntWrapper(persistedValue: 5),
                    \Query<LinkToAllCustomPersistableTypes>.list.optInt)
        validateKeypathMax("optInt8", min: Int8Wrapper(persistedValue: Int8(8)), max: Int8Wrapper(persistedValue: Int8(10)),
                    \Query<LinkToAllCustomPersistableTypes>.list.optInt8)
        validateKeypathMax("optInt16", min: Int16Wrapper(persistedValue: Int16(16)), max: Int16Wrapper(persistedValue: Int16(18)),
                    \Query<LinkToAllCustomPersistableTypes>.list.optInt16)
        validateKeypathMax("optInt32", min: Int32Wrapper(persistedValue: Int32(32)), max: Int32Wrapper(persistedValue: Int32(34)),
                    \Query<LinkToAllCustomPersistableTypes>.list.optInt32)
        validateKeypathMax("optInt64", min: Int64Wrapper(persistedValue: Int64(64)), max: Int64Wrapper(persistedValue: Int64(66)),
                    \Query<LinkToAllCustomPersistableTypes>.list.optInt64)
        validateKeypathMax("optFloat", min: FloatWrapper(persistedValue: Float(5.55444333)), max: FloatWrapper(persistedValue: Float(7.55444333)),
                    \Query<LinkToAllCustomPersistableTypes>.list.optFloat)
        validateKeypathMax("optDouble", min: DoubleWrapper(persistedValue: 123.456), max: DoubleWrapper(persistedValue: 345.678),
                    \Query<LinkToAllCustomPersistableTypes>.list.optDouble)
        validateKeypathMax("optDate", min: DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)), max: DateWrapper(persistedValue: Date(timeIntervalSince1970: 3000000)),
                    \Query<LinkToAllCustomPersistableTypes>.list.optDate)
        validateKeypathMax("optDecimal", min: Decimal128Wrapper(persistedValue: Decimal128(123.456)), max: Decimal128Wrapper(persistedValue: Decimal128(345.678)),
                    \Query<LinkToAllCustomPersistableTypes>.list.optDecimal)
    }

    func testAggregateNotSupported() {
        assertThrows(assertQuery("", count: 0) { $0.intCol.avg == 1 },
                     reason: "Invalid keypath 'intCol.@avg': Property 'ModernAllTypesObject.intCol' is not a link or collection and can only appear at the end of a keypath.")

        assertThrows(assertQuery("", count: 0) { $0.doubleCol.max != 1 },
                     reason: "Invalid keypath 'doubleCol.@max': Property 'ModernAllTypesObject.doubleCol' is not a link or collection and can only appear at the end of a keypath.")

        assertThrows(assertQuery("", count: 0) { $0.dateCol.min > Date() },
                     reason: "Invalid keypath 'dateCol.@min': Property 'ModernAllTypesObject.dateCol' is not a link or collection and can only appear at the end of a keypath.")

        assertThrows(assertQuery("", count: 0) { $0.decimalCol.sum < 1 },
                     reason: "Invalid keypath 'decimalCol.@sum': Property 'ModernAllTypesObject.decimalCol' is not a link or collection and can only appear at the end of a keypath.")
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

    // MARK: - ContainsIn

    func testContainsIn() {

        assertQuery(ModernAllTypesObject.self, "(boolCol IN %@)",
                    values: [NSArray(array: [true, false])], count: 1) {
            $0.boolCol.in([true, false])
        }
        assertQuery(ModernAllTypesObject.self, "(NOT boolCol IN %@)",
                    values: [NSArray(array: [false])], count: 0) {
            !$0.boolCol.in([false])
        }

        assertQuery(ModernAllTypesObject.self, "(intCol IN %@)",
                    values: [NSArray(array: [1, 3])], count: 1) {
            $0.intCol.in([1, 3])
        }
        assertQuery(ModernAllTypesObject.self, "(NOT intCol IN %@)",
                    values: [NSArray(array: [3])], count: 0) {
            !$0.intCol.in([3])
        }

        assertQuery(ModernAllTypesObject.self, "(int8Col IN %@)",
                    values: [NSArray(array: [Int8(8), Int8(9)])], count: 1) {
            $0.int8Col.in([Int8(8), Int8(9)])
        }
        assertQuery(ModernAllTypesObject.self, "(NOT int8Col IN %@)",
                    values: [NSArray(array: [Int8(9)])], count: 0) {
            !$0.int8Col.in([Int8(9)])
        }

        assertQuery(ModernAllTypesObject.self, "(int16Col IN %@)",
                    values: [NSArray(array: [Int16(16), Int16(17)])], count: 1) {
            $0.int16Col.in([Int16(16), Int16(17)])
        }
        assertQuery(ModernAllTypesObject.self, "(NOT int16Col IN %@)",
                    values: [NSArray(array: [Int16(17)])], count: 0) {
            !$0.int16Col.in([Int16(17)])
        }

        assertQuery(ModernAllTypesObject.self, "(int32Col IN %@)",
                    values: [NSArray(array: [Int32(32), Int32(33)])], count: 1) {
            $0.int32Col.in([Int32(32), Int32(33)])
        }
        assertQuery(ModernAllTypesObject.self, "(NOT int32Col IN %@)",
                    values: [NSArray(array: [Int32(33)])], count: 0) {
            !$0.int32Col.in([Int32(33)])
        }

        assertQuery(ModernAllTypesObject.self, "(int64Col IN %@)",
                    values: [NSArray(array: [Int64(64), Int64(65)])], count: 1) {
            $0.int64Col.in([Int64(64), Int64(65)])
        }
        assertQuery(ModernAllTypesObject.self, "(NOT int64Col IN %@)",
                    values: [NSArray(array: [Int64(65)])], count: 0) {
            !$0.int64Col.in([Int64(65)])
        }

        assertQuery(ModernAllTypesObject.self, "(floatCol IN %@)",
                    values: [NSArray(array: [Float(5.55444333), Float(6.55444333)])], count: 1) {
            $0.floatCol.in([Float(5.55444333), Float(6.55444333)])
        }
        assertQuery(ModernAllTypesObject.self, "(NOT floatCol IN %@)",
                    values: [NSArray(array: [Float(6.55444333)])], count: 0) {
            !$0.floatCol.in([Float(6.55444333)])
        }

        assertQuery(ModernAllTypesObject.self, "(doubleCol IN %@)",
                    values: [NSArray(array: [123.456, 234.567])], count: 1) {
            $0.doubleCol.in([123.456, 234.567])
        }
        assertQuery(ModernAllTypesObject.self, "(NOT doubleCol IN %@)",
                    values: [NSArray(array: [234.567])], count: 0) {
            !$0.doubleCol.in([234.567])
        }

        assertQuery(ModernAllTypesObject.self, "(stringCol IN %@)",
                    values: [NSArray(array: ["Foo", "Foó"])], count: 1) {
            $0.stringCol.in(["Foo", "Foó"])
        }
        assertQuery(ModernAllTypesObject.self, "(NOT stringCol IN %@)",
                    values: [NSArray(array: ["Foó"])], count: 0) {
            !$0.stringCol.in(["Foó"])
        }

        assertQuery(ModernAllTypesObject.self, "(binaryCol IN %@)",
                    values: [NSArray(array: [Data(count: 64), Data(count: 128)])], count: 1) {
            $0.binaryCol.in([Data(count: 64), Data(count: 128)])
        }
        assertQuery(ModernAllTypesObject.self, "(NOT binaryCol IN %@)",
                    values: [NSArray(array: [Data(count: 128)])], count: 0) {
            !$0.binaryCol.in([Data(count: 128)])
        }

        assertQuery(ModernAllTypesObject.self, "(dateCol IN %@)",
                    values: [NSArray(array: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)])], count: 1) {
            $0.dateCol.in([Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)])
        }
        assertQuery(ModernAllTypesObject.self, "(NOT dateCol IN %@)",
                    values: [NSArray(array: [Date(timeIntervalSince1970: 2000000)])], count: 0) {
            !$0.dateCol.in([Date(timeIntervalSince1970: 2000000)])
        }

        assertQuery(ModernAllTypesObject.self, "(decimalCol IN %@)",
                    values: [NSArray(array: [Decimal128(123.456), Decimal128(234.567)])], count: 1) {
            $0.decimalCol.in([Decimal128(123.456), Decimal128(234.567)])
        }
        assertQuery(ModernAllTypesObject.self, "(NOT decimalCol IN %@)",
                    values: [NSArray(array: [Decimal128(234.567)])], count: 0) {
            !$0.decimalCol.in([Decimal128(234.567)])
        }

        assertQuery(ModernAllTypesObject.self, "(objectIdCol IN %@)",
                    values: [NSArray(array: [ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045")])], count: 1) {
            $0.objectIdCol.in([ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045")])
        }
        assertQuery(ModernAllTypesObject.self, "(NOT objectIdCol IN %@)",
                    values: [NSArray(array: [ObjectId("61184062c1d8f096a3695045")])], count: 0) {
            !$0.objectIdCol.in([ObjectId("61184062c1d8f096a3695045")])
        }

        assertQuery(ModernAllTypesObject.self, "(uuidCol IN %@)",
                    values: [NSArray(array: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])], count: 1) {
            $0.uuidCol.in([UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])
        }
        assertQuery(ModernAllTypesObject.self, "(NOT uuidCol IN %@)",
                    values: [NSArray(array: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])], count: 0) {
            !$0.uuidCol.in([UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])
        }

        assertQuery(ModernAllTypesObject.self, "(intEnumCol IN %@)",
                    values: [NSArray(array: [ModernIntEnum.value1, ModernIntEnum.value2])], count: 1) {
            $0.intEnumCol.in([ModernIntEnum.value1, ModernIntEnum.value2])
        }
        assertQuery(ModernAllTypesObject.self, "(NOT intEnumCol IN %@)",
                    values: [NSArray(array: [ModernIntEnum.value2])], count: 0) {
            !$0.intEnumCol.in([ModernIntEnum.value2])
        }

        assertQuery(ModernAllTypesObject.self, "(stringEnumCol IN %@)",
                    values: [NSArray(array: [ModernStringEnum.value1, ModernStringEnum.value2])], count: 1) {
            $0.stringEnumCol.in([ModernStringEnum.value1, ModernStringEnum.value2])
        }
        assertQuery(ModernAllTypesObject.self, "(NOT stringEnumCol IN %@)",
                    values: [NSArray(array: [ModernStringEnum.value2])], count: 0) {
            !$0.stringEnumCol.in([ModernStringEnum.value2])
        }

        assertQuery(AllCustomPersistableTypes.self, "(bool IN %@)",
                    values: [NSArray(array: [BoolWrapper(persistedValue: true), BoolWrapper(persistedValue: false)])], count: 1) {
            $0.bool.in([BoolWrapper(persistedValue: true), BoolWrapper(persistedValue: false)])
        }
        assertQuery(AllCustomPersistableTypes.self, "(NOT bool IN %@)",
                    values: [NSArray(array: [BoolWrapper(persistedValue: false)])], count: 0) {
            !$0.bool.in([BoolWrapper(persistedValue: false)])
        }

        assertQuery(AllCustomPersistableTypes.self, "(int IN %@)",
                    values: [NSArray(array: [IntWrapper(persistedValue: 1), IntWrapper(persistedValue: 3)])], count: 1) {
            $0.int.in([IntWrapper(persistedValue: 1), IntWrapper(persistedValue: 3)])
        }
        assertQuery(AllCustomPersistableTypes.self, "(NOT int IN %@)",
                    values: [NSArray(array: [IntWrapper(persistedValue: 3)])], count: 0) {
            !$0.int.in([IntWrapper(persistedValue: 3)])
        }

        assertQuery(AllCustomPersistableTypes.self, "(int8 IN %@)",
                    values: [NSArray(array: [Int8Wrapper(persistedValue: Int8(8)), Int8Wrapper(persistedValue: Int8(9))])], count: 1) {
            $0.int8.in([Int8Wrapper(persistedValue: Int8(8)), Int8Wrapper(persistedValue: Int8(9))])
        }
        assertQuery(AllCustomPersistableTypes.self, "(NOT int8 IN %@)",
                    values: [NSArray(array: [Int8Wrapper(persistedValue: Int8(9))])], count: 0) {
            !$0.int8.in([Int8Wrapper(persistedValue: Int8(9))])
        }

        assertQuery(AllCustomPersistableTypes.self, "(int16 IN %@)",
                    values: [NSArray(array: [Int16Wrapper(persistedValue: Int16(16)), Int16Wrapper(persistedValue: Int16(17))])], count: 1) {
            $0.int16.in([Int16Wrapper(persistedValue: Int16(16)), Int16Wrapper(persistedValue: Int16(17))])
        }
        assertQuery(AllCustomPersistableTypes.self, "(NOT int16 IN %@)",
                    values: [NSArray(array: [Int16Wrapper(persistedValue: Int16(17))])], count: 0) {
            !$0.int16.in([Int16Wrapper(persistedValue: Int16(17))])
        }

        assertQuery(AllCustomPersistableTypes.self, "(int32 IN %@)",
                    values: [NSArray(array: [Int32Wrapper(persistedValue: Int32(32)), Int32Wrapper(persistedValue: Int32(33))])], count: 1) {
            $0.int32.in([Int32Wrapper(persistedValue: Int32(32)), Int32Wrapper(persistedValue: Int32(33))])
        }
        assertQuery(AllCustomPersistableTypes.self, "(NOT int32 IN %@)",
                    values: [NSArray(array: [Int32Wrapper(persistedValue: Int32(33))])], count: 0) {
            !$0.int32.in([Int32Wrapper(persistedValue: Int32(33))])
        }

        assertQuery(AllCustomPersistableTypes.self, "(int64 IN %@)",
                    values: [NSArray(array: [Int64Wrapper(persistedValue: Int64(64)), Int64Wrapper(persistedValue: Int64(65))])], count: 1) {
            $0.int64.in([Int64Wrapper(persistedValue: Int64(64)), Int64Wrapper(persistedValue: Int64(65))])
        }
        assertQuery(AllCustomPersistableTypes.self, "(NOT int64 IN %@)",
                    values: [NSArray(array: [Int64Wrapper(persistedValue: Int64(65))])], count: 0) {
            !$0.int64.in([Int64Wrapper(persistedValue: Int64(65))])
        }

        assertQuery(AllCustomPersistableTypes.self, "(float IN %@)",
                    values: [NSArray(array: [FloatWrapper(persistedValue: Float(5.55444333)), FloatWrapper(persistedValue: Float(6.55444333))])], count: 1) {
            $0.float.in([FloatWrapper(persistedValue: Float(5.55444333)), FloatWrapper(persistedValue: Float(6.55444333))])
        }
        assertQuery(AllCustomPersistableTypes.self, "(NOT float IN %@)",
                    values: [NSArray(array: [FloatWrapper(persistedValue: Float(6.55444333))])], count: 0) {
            !$0.float.in([FloatWrapper(persistedValue: Float(6.55444333))])
        }

        assertQuery(AllCustomPersistableTypes.self, "(double IN %@)",
                    values: [NSArray(array: [DoubleWrapper(persistedValue: 123.456), DoubleWrapper(persistedValue: 234.567)])], count: 1) {
            $0.double.in([DoubleWrapper(persistedValue: 123.456), DoubleWrapper(persistedValue: 234.567)])
        }
        assertQuery(AllCustomPersistableTypes.self, "(NOT double IN %@)",
                    values: [NSArray(array: [DoubleWrapper(persistedValue: 234.567)])], count: 0) {
            !$0.double.in([DoubleWrapper(persistedValue: 234.567)])
        }

        assertQuery(AllCustomPersistableTypes.self, "(string IN %@)",
                    values: [NSArray(array: [StringWrapper(persistedValue: "Foo"), StringWrapper(persistedValue: "Foó")])], count: 1) {
            $0.string.in([StringWrapper(persistedValue: "Foo"), StringWrapper(persistedValue: "Foó")])
        }
        assertQuery(AllCustomPersistableTypes.self, "(NOT string IN %@)",
                    values: [NSArray(array: [StringWrapper(persistedValue: "Foó")])], count: 0) {
            !$0.string.in([StringWrapper(persistedValue: "Foó")])
        }

        assertQuery(AllCustomPersistableTypes.self, "(binary IN %@)",
                    values: [NSArray(array: [DataWrapper(persistedValue: Data(count: 64)), DataWrapper(persistedValue: Data(count: 128))])], count: 1) {
            $0.binary.in([DataWrapper(persistedValue: Data(count: 64)), DataWrapper(persistedValue: Data(count: 128))])
        }
        assertQuery(AllCustomPersistableTypes.self, "(NOT binary IN %@)",
                    values: [NSArray(array: [DataWrapper(persistedValue: Data(count: 128))])], count: 0) {
            !$0.binary.in([DataWrapper(persistedValue: Data(count: 128))])
        }

        assertQuery(AllCustomPersistableTypes.self, "(date IN %@)",
                    values: [NSArray(array: [DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)), DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000))])], count: 1) {
            $0.date.in([DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)), DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000))])
        }
        assertQuery(AllCustomPersistableTypes.self, "(NOT date IN %@)",
                    values: [NSArray(array: [DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000))])], count: 0) {
            !$0.date.in([DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000))])
        }

        assertQuery(AllCustomPersistableTypes.self, "(decimal IN %@)",
                    values: [NSArray(array: [Decimal128Wrapper(persistedValue: Decimal128(123.456)), Decimal128Wrapper(persistedValue: Decimal128(234.567))])], count: 1) {
            $0.decimal.in([Decimal128Wrapper(persistedValue: Decimal128(123.456)), Decimal128Wrapper(persistedValue: Decimal128(234.567))])
        }
        assertQuery(AllCustomPersistableTypes.self, "(NOT decimal IN %@)",
                    values: [NSArray(array: [Decimal128Wrapper(persistedValue: Decimal128(234.567))])], count: 0) {
            !$0.decimal.in([Decimal128Wrapper(persistedValue: Decimal128(234.567))])
        }

        assertQuery(AllCustomPersistableTypes.self, "(objectId IN %@)",
                    values: [NSArray(array: [ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695046")), ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045"))])], count: 1) {
            $0.objectId.in([ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695046")), ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045"))])
        }
        assertQuery(AllCustomPersistableTypes.self, "(NOT objectId IN %@)",
                    values: [NSArray(array: [ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045"))])], count: 0) {
            !$0.objectId.in([ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045"))])
        }

        assertQuery(AllCustomPersistableTypes.self, "(uuid IN %@)",
                    values: [NSArray(array: [UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!), UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)])], count: 1) {
            $0.uuid.in([UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!), UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)])
        }
        assertQuery(AllCustomPersistableTypes.self, "(NOT uuid IN %@)",
                    values: [NSArray(array: [UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)])], count: 0) {
            !$0.uuid.in([UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)])
        }

        assertQuery(ModernAllTypesObject.self, "(optBoolCol IN %@)",
                    values: [NSArray(array: [true, false])], count: 1) {
            $0.optBoolCol.in([true, false])
        }
        assertQuery(ModernAllTypesObject.self, "(NOT optBoolCol IN %@)",
                    values: [NSArray(array: [false])], count: 0) {
            !$0.optBoolCol.in([false])
        }

        assertQuery(ModernAllTypesObject.self, "(optIntCol IN %@)",
                    values: [NSArray(array: [1, 3])], count: 1) {
            $0.optIntCol.in([1, 3])
        }
        assertQuery(ModernAllTypesObject.self, "(NOT optIntCol IN %@)",
                    values: [NSArray(array: [3])], count: 0) {
            !$0.optIntCol.in([3])
        }

        assertQuery(ModernAllTypesObject.self, "(optInt8Col IN %@)",
                    values: [NSArray(array: [Int8(8), Int8(9)])], count: 1) {
            $0.optInt8Col.in([Int8(8), Int8(9)])
        }
        assertQuery(ModernAllTypesObject.self, "(NOT optInt8Col IN %@)",
                    values: [NSArray(array: [Int8(9)])], count: 0) {
            !$0.optInt8Col.in([Int8(9)])
        }

        assertQuery(ModernAllTypesObject.self, "(optInt16Col IN %@)",
                    values: [NSArray(array: [Int16(16), Int16(17)])], count: 1) {
            $0.optInt16Col.in([Int16(16), Int16(17)])
        }
        assertQuery(ModernAllTypesObject.self, "(NOT optInt16Col IN %@)",
                    values: [NSArray(array: [Int16(17)])], count: 0) {
            !$0.optInt16Col.in([Int16(17)])
        }

        assertQuery(ModernAllTypesObject.self, "(optInt32Col IN %@)",
                    values: [NSArray(array: [Int32(32), Int32(33)])], count: 1) {
            $0.optInt32Col.in([Int32(32), Int32(33)])
        }
        assertQuery(ModernAllTypesObject.self, "(NOT optInt32Col IN %@)",
                    values: [NSArray(array: [Int32(33)])], count: 0) {
            !$0.optInt32Col.in([Int32(33)])
        }

        assertQuery(ModernAllTypesObject.self, "(optInt64Col IN %@)",
                    values: [NSArray(array: [Int64(64), Int64(65)])], count: 1) {
            $0.optInt64Col.in([Int64(64), Int64(65)])
        }
        assertQuery(ModernAllTypesObject.self, "(NOT optInt64Col IN %@)",
                    values: [NSArray(array: [Int64(65)])], count: 0) {
            !$0.optInt64Col.in([Int64(65)])
        }

        assertQuery(ModernAllTypesObject.self, "(optFloatCol IN %@)",
                    values: [NSArray(array: [Float(5.55444333), Float(6.55444333)])], count: 1) {
            $0.optFloatCol.in([Float(5.55444333), Float(6.55444333)])
        }
        assertQuery(ModernAllTypesObject.self, "(NOT optFloatCol IN %@)",
                    values: [NSArray(array: [Float(6.55444333)])], count: 0) {
            !$0.optFloatCol.in([Float(6.55444333)])
        }

        assertQuery(ModernAllTypesObject.self, "(optDoubleCol IN %@)",
                    values: [NSArray(array: [123.456, 234.567])], count: 1) {
            $0.optDoubleCol.in([123.456, 234.567])
        }
        assertQuery(ModernAllTypesObject.self, "(NOT optDoubleCol IN %@)",
                    values: [NSArray(array: [234.567])], count: 0) {
            !$0.optDoubleCol.in([234.567])
        }

        assertQuery(ModernAllTypesObject.self, "(optStringCol IN %@)",
                    values: [NSArray(array: ["Foo", "Foó"])], count: 1) {
            $0.optStringCol.in(["Foo", "Foó"])
        }
        assertQuery(ModernAllTypesObject.self, "(NOT optStringCol IN %@)",
                    values: [NSArray(array: ["Foó"])], count: 0) {
            !$0.optStringCol.in(["Foó"])
        }

        assertQuery(ModernAllTypesObject.self, "(optBinaryCol IN %@)",
                    values: [NSArray(array: [Data(count: 64), Data(count: 128)])], count: 1) {
            $0.optBinaryCol.in([Data(count: 64), Data(count: 128)])
        }
        assertQuery(ModernAllTypesObject.self, "(NOT optBinaryCol IN %@)",
                    values: [NSArray(array: [Data(count: 128)])], count: 0) {
            !$0.optBinaryCol.in([Data(count: 128)])
        }

        assertQuery(ModernAllTypesObject.self, "(optDateCol IN %@)",
                    values: [NSArray(array: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)])], count: 1) {
            $0.optDateCol.in([Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)])
        }
        assertQuery(ModernAllTypesObject.self, "(NOT optDateCol IN %@)",
                    values: [NSArray(array: [Date(timeIntervalSince1970: 2000000)])], count: 0) {
            !$0.optDateCol.in([Date(timeIntervalSince1970: 2000000)])
        }

        assertQuery(ModernAllTypesObject.self, "(optDecimalCol IN %@)",
                    values: [NSArray(array: [Decimal128(123.456), Decimal128(234.567)])], count: 1) {
            $0.optDecimalCol.in([Decimal128(123.456), Decimal128(234.567)])
        }
        assertQuery(ModernAllTypesObject.self, "(NOT optDecimalCol IN %@)",
                    values: [NSArray(array: [Decimal128(234.567)])], count: 0) {
            !$0.optDecimalCol.in([Decimal128(234.567)])
        }

        assertQuery(ModernAllTypesObject.self, "(optObjectIdCol IN %@)",
                    values: [NSArray(array: [ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045")])], count: 1) {
            $0.optObjectIdCol.in([ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045")])
        }
        assertQuery(ModernAllTypesObject.self, "(NOT optObjectIdCol IN %@)",
                    values: [NSArray(array: [ObjectId("61184062c1d8f096a3695045")])], count: 0) {
            !$0.optObjectIdCol.in([ObjectId("61184062c1d8f096a3695045")])
        }

        assertQuery(ModernAllTypesObject.self, "(optUuidCol IN %@)",
                    values: [NSArray(array: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])], count: 1) {
            $0.optUuidCol.in([UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])
        }
        assertQuery(ModernAllTypesObject.self, "(NOT optUuidCol IN %@)",
                    values: [NSArray(array: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])], count: 0) {
            !$0.optUuidCol.in([UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])
        }

        assertQuery(ModernAllTypesObject.self, "(optIntEnumCol IN %@)",
                    values: [NSArray(array: [ModernIntEnum.value1, ModernIntEnum.value2])], count: 1) {
            $0.optIntEnumCol.in([ModernIntEnum.value1, ModernIntEnum.value2])
        }
        assertQuery(ModernAllTypesObject.self, "(NOT optIntEnumCol IN %@)",
                    values: [NSArray(array: [ModernIntEnum.value2])], count: 0) {
            !$0.optIntEnumCol.in([ModernIntEnum.value2])
        }

        assertQuery(ModernAllTypesObject.self, "(optStringEnumCol IN %@)",
                    values: [NSArray(array: [ModernStringEnum.value1, ModernStringEnum.value2])], count: 1) {
            $0.optStringEnumCol.in([ModernStringEnum.value1, ModernStringEnum.value2])
        }
        assertQuery(ModernAllTypesObject.self, "(NOT optStringEnumCol IN %@)",
                    values: [NSArray(array: [ModernStringEnum.value2])], count: 0) {
            !$0.optStringEnumCol.in([ModernStringEnum.value2])
        }

        assertQuery(AllCustomPersistableTypes.self, "(optBool IN %@)",
                    values: [NSArray(array: [BoolWrapper(persistedValue: true), BoolWrapper(persistedValue: false)])], count: 1) {
            $0.optBool.in([BoolWrapper(persistedValue: true), BoolWrapper(persistedValue: false)])
        }
        assertQuery(AllCustomPersistableTypes.self, "(NOT optBool IN %@)",
                    values: [NSArray(array: [BoolWrapper(persistedValue: false)])], count: 0) {
            !$0.optBool.in([BoolWrapper(persistedValue: false)])
        }

        assertQuery(AllCustomPersistableTypes.self, "(optInt IN %@)",
                    values: [NSArray(array: [IntWrapper(persistedValue: 1), IntWrapper(persistedValue: 3)])], count: 1) {
            $0.optInt.in([IntWrapper(persistedValue: 1), IntWrapper(persistedValue: 3)])
        }
        assertQuery(AllCustomPersistableTypes.self, "(NOT optInt IN %@)",
                    values: [NSArray(array: [IntWrapper(persistedValue: 3)])], count: 0) {
            !$0.optInt.in([IntWrapper(persistedValue: 3)])
        }

        assertQuery(AllCustomPersistableTypes.self, "(optInt8 IN %@)",
                    values: [NSArray(array: [Int8Wrapper(persistedValue: Int8(8)), Int8Wrapper(persistedValue: Int8(9))])], count: 1) {
            $0.optInt8.in([Int8Wrapper(persistedValue: Int8(8)), Int8Wrapper(persistedValue: Int8(9))])
        }
        assertQuery(AllCustomPersistableTypes.self, "(NOT optInt8 IN %@)",
                    values: [NSArray(array: [Int8Wrapper(persistedValue: Int8(9))])], count: 0) {
            !$0.optInt8.in([Int8Wrapper(persistedValue: Int8(9))])
        }

        assertQuery(AllCustomPersistableTypes.self, "(optInt16 IN %@)",
                    values: [NSArray(array: [Int16Wrapper(persistedValue: Int16(16)), Int16Wrapper(persistedValue: Int16(17))])], count: 1) {
            $0.optInt16.in([Int16Wrapper(persistedValue: Int16(16)), Int16Wrapper(persistedValue: Int16(17))])
        }
        assertQuery(AllCustomPersistableTypes.self, "(NOT optInt16 IN %@)",
                    values: [NSArray(array: [Int16Wrapper(persistedValue: Int16(17))])], count: 0) {
            !$0.optInt16.in([Int16Wrapper(persistedValue: Int16(17))])
        }

        assertQuery(AllCustomPersistableTypes.self, "(optInt32 IN %@)",
                    values: [NSArray(array: [Int32Wrapper(persistedValue: Int32(32)), Int32Wrapper(persistedValue: Int32(33))])], count: 1) {
            $0.optInt32.in([Int32Wrapper(persistedValue: Int32(32)), Int32Wrapper(persistedValue: Int32(33))])
        }
        assertQuery(AllCustomPersistableTypes.self, "(NOT optInt32 IN %@)",
                    values: [NSArray(array: [Int32Wrapper(persistedValue: Int32(33))])], count: 0) {
            !$0.optInt32.in([Int32Wrapper(persistedValue: Int32(33))])
        }

        assertQuery(AllCustomPersistableTypes.self, "(optInt64 IN %@)",
                    values: [NSArray(array: [Int64Wrapper(persistedValue: Int64(64)), Int64Wrapper(persistedValue: Int64(65))])], count: 1) {
            $0.optInt64.in([Int64Wrapper(persistedValue: Int64(64)), Int64Wrapper(persistedValue: Int64(65))])
        }
        assertQuery(AllCustomPersistableTypes.self, "(NOT optInt64 IN %@)",
                    values: [NSArray(array: [Int64Wrapper(persistedValue: Int64(65))])], count: 0) {
            !$0.optInt64.in([Int64Wrapper(persistedValue: Int64(65))])
        }

        assertQuery(AllCustomPersistableTypes.self, "(optFloat IN %@)",
                    values: [NSArray(array: [FloatWrapper(persistedValue: Float(5.55444333)), FloatWrapper(persistedValue: Float(6.55444333))])], count: 1) {
            $0.optFloat.in([FloatWrapper(persistedValue: Float(5.55444333)), FloatWrapper(persistedValue: Float(6.55444333))])
        }
        assertQuery(AllCustomPersistableTypes.self, "(NOT optFloat IN %@)",
                    values: [NSArray(array: [FloatWrapper(persistedValue: Float(6.55444333))])], count: 0) {
            !$0.optFloat.in([FloatWrapper(persistedValue: Float(6.55444333))])
        }

        assertQuery(AllCustomPersistableTypes.self, "(optDouble IN %@)",
                    values: [NSArray(array: [DoubleWrapper(persistedValue: 123.456), DoubleWrapper(persistedValue: 234.567)])], count: 1) {
            $0.optDouble.in([DoubleWrapper(persistedValue: 123.456), DoubleWrapper(persistedValue: 234.567)])
        }
        assertQuery(AllCustomPersistableTypes.self, "(NOT optDouble IN %@)",
                    values: [NSArray(array: [DoubleWrapper(persistedValue: 234.567)])], count: 0) {
            !$0.optDouble.in([DoubleWrapper(persistedValue: 234.567)])
        }

        assertQuery(AllCustomPersistableTypes.self, "(optString IN %@)",
                    values: [NSArray(array: [StringWrapper(persistedValue: "Foo"), StringWrapper(persistedValue: "Foó")])], count: 1) {
            $0.optString.in([StringWrapper(persistedValue: "Foo"), StringWrapper(persistedValue: "Foó")])
        }
        assertQuery(AllCustomPersistableTypes.self, "(NOT optString IN %@)",
                    values: [NSArray(array: [StringWrapper(persistedValue: "Foó")])], count: 0) {
            !$0.optString.in([StringWrapper(persistedValue: "Foó")])
        }

        assertQuery(AllCustomPersistableTypes.self, "(optBinary IN %@)",
                    values: [NSArray(array: [DataWrapper(persistedValue: Data(count: 64)), DataWrapper(persistedValue: Data(count: 128))])], count: 1) {
            $0.optBinary.in([DataWrapper(persistedValue: Data(count: 64)), DataWrapper(persistedValue: Data(count: 128))])
        }
        assertQuery(AllCustomPersistableTypes.self, "(NOT optBinary IN %@)",
                    values: [NSArray(array: [DataWrapper(persistedValue: Data(count: 128))])], count: 0) {
            !$0.optBinary.in([DataWrapper(persistedValue: Data(count: 128))])
        }

        assertQuery(AllCustomPersistableTypes.self, "(optDate IN %@)",
                    values: [NSArray(array: [DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)), DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000))])], count: 1) {
            $0.optDate.in([DateWrapper(persistedValue: Date(timeIntervalSince1970: 1000000)), DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000))])
        }
        assertQuery(AllCustomPersistableTypes.self, "(NOT optDate IN %@)",
                    values: [NSArray(array: [DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000))])], count: 0) {
            !$0.optDate.in([DateWrapper(persistedValue: Date(timeIntervalSince1970: 2000000))])
        }

        assertQuery(AllCustomPersistableTypes.self, "(optDecimal IN %@)",
                    values: [NSArray(array: [Decimal128Wrapper(persistedValue: Decimal128(123.456)), Decimal128Wrapper(persistedValue: Decimal128(234.567))])], count: 1) {
            $0.optDecimal.in([Decimal128Wrapper(persistedValue: Decimal128(123.456)), Decimal128Wrapper(persistedValue: Decimal128(234.567))])
        }
        assertQuery(AllCustomPersistableTypes.self, "(NOT optDecimal IN %@)",
                    values: [NSArray(array: [Decimal128Wrapper(persistedValue: Decimal128(234.567))])], count: 0) {
            !$0.optDecimal.in([Decimal128Wrapper(persistedValue: Decimal128(234.567))])
        }

        assertQuery(AllCustomPersistableTypes.self, "(optObjectId IN %@)",
                    values: [NSArray(array: [ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695046")), ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045"))])], count: 1) {
            $0.optObjectId.in([ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695046")), ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045"))])
        }
        assertQuery(AllCustomPersistableTypes.self, "(NOT optObjectId IN %@)",
                    values: [NSArray(array: [ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045"))])], count: 0) {
            !$0.optObjectId.in([ObjectIdWrapper(persistedValue: ObjectId("61184062c1d8f096a3695045"))])
        }

        assertQuery(AllCustomPersistableTypes.self, "(optUuid IN %@)",
                    values: [NSArray(array: [UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!), UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)])], count: 1) {
            $0.optUuid.in([UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!), UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)])
        }
        assertQuery(AllCustomPersistableTypes.self, "(NOT optUuid IN %@)",
                    values: [NSArray(array: [UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)])], count: 0) {
            !$0.optUuid.in([UUIDWrapper(persistedValue: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)])
        }
    }
}

private protocol LinkToTestObject: Object {
    associatedtype Child: Object
    var object: Child? { get }
    var list: List<Child> { get }
    var set: MutableSet<Child> { get }
    var map: Map<String, Child?> { get }
}
extension LinkToCustomPersistableCollections: LinkToTestObject {}
extension LinkToAllCustomPersistableTypes: LinkToTestObject {}
extension LinkToModernAllTypesObject: LinkToTestObject {}
extension LinkToModernCollectionsOfEnums: LinkToTestObject {}

private protocol QueryValue {
    static func queryValues() -> [Self]
}

extension Bool: QueryValue {
    static func queryValues() -> [Bool] {
        return [true, true, false]
    }
}
extension BoolWrapper: QueryValue {
    static func queryValues() -> [BoolWrapper] {
        return Bool.queryValues().map(BoolWrapper.init)
    }
}

extension Int: QueryValue {
    static func queryValues() -> [Int] {
        return [1, 3, 5]
    }
}
extension IntWrapper: QueryValue {
    static func queryValues() -> [IntWrapper] {
        return Int.queryValues().map(IntWrapper.init)
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
extension Int8Wrapper: QueryValue {
    static func queryValues() -> [Int8Wrapper] {
        return Int8.queryValues().map(Int8Wrapper.init)
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
extension Int16Wrapper: QueryValue {
    static func queryValues() -> [Int16Wrapper] {
        return Int16.queryValues().map(Int16Wrapper.init)
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
extension Int32Wrapper: QueryValue {
    static func queryValues() -> [Int32Wrapper] {
        return Int32.queryValues().map(Int32Wrapper.init)
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
extension Int64Wrapper: QueryValue {
    static func queryValues() -> [Int64Wrapper] {
        return Int64.queryValues().map(Int64Wrapper.init)
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
extension FloatWrapper: QueryValue {
    static func queryValues() -> [FloatWrapper] {
        return Float.queryValues().map(FloatWrapper.init)
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
extension DoubleWrapper: QueryValue {
    static func queryValues() -> [DoubleWrapper] {
        return Double.queryValues().map(DoubleWrapper.init)
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
extension StringWrapper: QueryValue {
    static func queryValues() -> [StringWrapper] {
        return String.queryValues().map(StringWrapper.init)
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
extension DataWrapper: QueryValue {
    static func queryValues() -> [DataWrapper] {
        return Data.queryValues().map(DataWrapper.init)
    }
}

extension Date: QueryValue {
    static func queryValues() -> [Date] {
        return [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000), Date(timeIntervalSince1970: 3000000)]
    }
}
extension DateWrapper: QueryValue {
    static func queryValues() -> [DateWrapper] {
        return Date.queryValues().map(DateWrapper.init)
    }
}

extension Decimal128: QueryValue {
    static func queryValues() -> [Decimal128] {
        return [Decimal128(123.456), Decimal128(234.567), Decimal128(345.678)]
    }
}
extension Decimal128Wrapper: QueryValue {
    static func queryValues() -> [Decimal128Wrapper] {
        return Decimal128.queryValues().map(Decimal128Wrapper.init)
    }
}

extension ObjectId: QueryValue {
    static func queryValues() -> [ObjectId] {
        return [ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045"), ObjectId("61184062c1d8f096a3695044")]
    }
}
extension ObjectIdWrapper: QueryValue {
    static func queryValues() -> [ObjectIdWrapper] {
        return ObjectId.queryValues().map(ObjectIdWrapper.init)
    }
}

extension UUID: QueryValue {
    static func queryValues() -> [UUID] {
        return [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d08e")!]
    }
}
extension UUIDWrapper: QueryValue {
    static func queryValues() -> [UUIDWrapper] {
        return UUID.queryValues().map(UUIDWrapper.init)
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
        return 1 + 3 + 5
    }
    fileprivate static func average() -> SumType {
        return sum() / 3
    }
}
extension IntWrapper: AddableQueryValue {
    fileprivate typealias SumType = IntWrapper
    fileprivate static func sum() -> SumType {
        return IntWrapper(persistedValue: Int.sum())
    }
    fileprivate static func average() -> SumType {
        return IntWrapper(persistedValue: Int.average())
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
extension Int8Wrapper: AddableQueryValue {
    fileprivate typealias SumType = Int8Wrapper
    fileprivate static func sum() -> SumType {
        return Int8Wrapper(persistedValue: Int8.sum())
    }
    fileprivate static func average() -> SumType {
        return Int8Wrapper(persistedValue: Int8.average())
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
extension Int16Wrapper: AddableQueryValue {
    fileprivate typealias SumType = Int16Wrapper
    fileprivate static func sum() -> SumType {
        return Int16Wrapper(persistedValue: Int16.sum())
    }
    fileprivate static func average() -> SumType {
        return Int16Wrapper(persistedValue: Int16.average())
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
extension Int32Wrapper: AddableQueryValue {
    fileprivate typealias SumType = Int32Wrapper
    fileprivate static func sum() -> SumType {
        return Int32Wrapper(persistedValue: Int32.sum())
    }
    fileprivate static func average() -> SumType {
        return Int32Wrapper(persistedValue: Int32.average())
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
extension Int64Wrapper: AddableQueryValue {
    fileprivate typealias SumType = Int64Wrapper
    fileprivate static func sum() -> SumType {
        return Int64Wrapper(persistedValue: Int64.sum())
    }
    fileprivate static func average() -> SumType {
        return Int64Wrapper(persistedValue: Int64.average())
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
extension FloatWrapper: AddableQueryValue {
    fileprivate typealias SumType = FloatWrapper
    fileprivate static func sum() -> SumType {
        return FloatWrapper(persistedValue: Float.sum())
    }
    fileprivate static func average() -> SumType {
        return FloatWrapper(persistedValue: Float.average())
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
extension DoubleWrapper: AddableQueryValue {
    fileprivate typealias SumType = DoubleWrapper
    fileprivate static func sum() -> SumType {
        return DoubleWrapper(persistedValue: Double.sum())
    }
    fileprivate static func average() -> SumType {
        return DoubleWrapper(persistedValue: Double.average())
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
extension Decimal128Wrapper: AddableQueryValue {
    fileprivate typealias SumType = Decimal128Wrapper
    fileprivate static func sum() -> SumType {
        return Decimal128Wrapper(persistedValue: Decimal128.sum())
    }
    fileprivate static func average() -> SumType {
        return Decimal128Wrapper(persistedValue: Decimal128.average())
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
