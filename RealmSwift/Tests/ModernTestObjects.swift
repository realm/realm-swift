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
import RealmSwift
import Realm

class ModernAllTypesObject: Object {
    @Persisted(primaryKey: true) var pk: ObjectId
    var ignored: Int = 1

    @Persisted var boolCol: Bool
    @Persisted var intCol: Int
    @Persisted var int8Col: Int8 = 1
    @Persisted var int16Col: Int16 = 2
    @Persisted var int32Col: Int32 = 3
    @Persisted var int64Col: Int64 = 4
    @Persisted var floatCol: Float = 5
    @Persisted var doubleCol: Double = 6
    @Persisted var stringCol: String
    @Persisted var binaryCol: Data
    @Persisted var dateCol: Date
    @Persisted var decimalCol: Decimal128
    @Persisted var objectIdCol: ObjectId
    @Persisted var objectCol: ModernAllTypesObject?
    @Persisted var arrayCol: List<ModernAllTypesObject>
    @Persisted var setCol: MutableSet<ModernAllTypesObject>
    @Persisted var mapCol: Map<String, ModernAllTypesObject?>
    @Persisted var anyCol: AnyRealmValue
    @Persisted var uuidCol: UUID
    @Persisted var intEnumCol: ModernIntEnum
    @Persisted var stringEnumCol: ModernStringEnum

    @Persisted var optIntCol: Int?
    @Persisted var optInt8Col: Int8?
    @Persisted var optInt16Col: Int16?
    @Persisted var optInt32Col: Int32?
    @Persisted var optInt64Col: Int64?
    @Persisted var optFloatCol: Float?
    @Persisted var optDoubleCol: Double?
    @Persisted var optBoolCol: Bool?
    @Persisted var optStringCol: String?
    @Persisted var optBinaryCol: Data?
    @Persisted var optDateCol: Date?
    @Persisted var optDecimalCol: Decimal128?
    @Persisted var optObjectIdCol: ObjectId?
    @Persisted var optUuidCol: UUID?
    @Persisted var optIntEnumCol: ModernIntEnum?
    @Persisted var optStringEnumCol: ModernStringEnum?

    @Persisted var arrayBool: List<Bool>
    @Persisted var arrayInt: List<Int>
    @Persisted var arrayInt8: List<Int8>
    @Persisted var arrayInt16: List<Int16>
    @Persisted var arrayInt32: List<Int32>
    @Persisted var arrayInt64: List<Int64>
    @Persisted var arrayFloat: List<Float>
    @Persisted var arrayDouble: List<Double>
    @Persisted var arrayString: List<String>
    @Persisted var arrayBinary: List<Data>
    @Persisted var arrayDate: List<Date>
    @Persisted var arrayDecimal: List<Decimal128>
    @Persisted var arrayObjectId: List<ObjectId>
    @Persisted var arrayAny: List<AnyRealmValue>
    @Persisted var arrayUuid: List<UUID>

    @Persisted var arrayOptBool: List<Bool?>
    @Persisted var arrayOptInt: List<Int?>
    @Persisted var arrayOptInt8: List<Int8?>
    @Persisted var arrayOptInt16: List<Int16?>
    @Persisted var arrayOptInt32: List<Int32?>
    @Persisted var arrayOptInt64: List<Int64?>
    @Persisted var arrayOptFloat: List<Float?>
    @Persisted var arrayOptDouble: List<Double?>
    @Persisted var arrayOptString: List<String?>
    @Persisted var arrayOptBinary: List<Data?>
    @Persisted var arrayOptDate: List<Date?>
    @Persisted var arrayOptDecimal: List<Decimal128?>
    @Persisted var arrayOptObjectId: List<ObjectId?>
    @Persisted var arrayOptUuid: List<UUID?>

    @Persisted var setBool: MutableSet<Bool>
    @Persisted var setInt: MutableSet<Int>
    @Persisted var setInt8: MutableSet<Int8>
    @Persisted var setInt16: MutableSet<Int16>
    @Persisted var setInt32: MutableSet<Int32>
    @Persisted var setInt64: MutableSet<Int64>
    @Persisted var setFloat: MutableSet<Float>
    @Persisted var setDouble: MutableSet<Double>
    @Persisted var setString: MutableSet<String>
    @Persisted var setBinary: MutableSet<Data>
    @Persisted var setDate: MutableSet<Date>
    @Persisted var setDecimal: MutableSet<Decimal128>
    @Persisted var setObjectId: MutableSet<ObjectId>
    @Persisted var setAny: MutableSet<AnyRealmValue>
    @Persisted var setUuid: MutableSet<UUID>

    @Persisted var setOptBool: MutableSet<Bool?>
    @Persisted var setOptInt: MutableSet<Int?>
    @Persisted var setOptInt8: MutableSet<Int8?>
    @Persisted var setOptInt16: MutableSet<Int16?>
    @Persisted var setOptInt32: MutableSet<Int32?>
    @Persisted var setOptInt64: MutableSet<Int64?>
    @Persisted var setOptFloat: MutableSet<Float?>
    @Persisted var setOptDouble: MutableSet<Double?>
    @Persisted var setOptString: MutableSet<String?>
    @Persisted var setOptBinary: MutableSet<Data?>
    @Persisted var setOptDate: MutableSet<Date?>
    @Persisted var setOptDecimal: MutableSet<Decimal128?>
    @Persisted var setOptObjectId: MutableSet<ObjectId?>
    @Persisted var setOptUuid: MutableSet<UUID?>

    @Persisted var mapBool: Map<String, Bool>
    @Persisted var mapInt: Map<String, Int>
    @Persisted var mapInt8: Map<String, Int8>
    @Persisted var mapInt16: Map<String, Int16>
    @Persisted var mapInt32: Map<String, Int32>
    @Persisted var mapInt64: Map<String, Int64>
    @Persisted var mapFloat: Map<String, Float>
    @Persisted var mapDouble: Map<String, Double>
    @Persisted var mapString: Map<String, String>
    @Persisted var mapBinary: Map<String, Data>
    @Persisted var mapDate: Map<String, Date>
    @Persisted var mapDecimal: Map<String, Decimal128>
    @Persisted var mapObjectId: Map<String, ObjectId>
    @Persisted var mapAny: Map<String, AnyRealmValue>
    @Persisted var mapUuid: Map<String, UUID>

    @Persisted var mapOptBool: Map<String, Bool?>
    @Persisted var mapOptInt: Map<String, Int?>
    @Persisted var mapOptInt8: Map<String, Int8?>
    @Persisted var mapOptInt16: Map<String, Int16?>
    @Persisted var mapOptInt32: Map<String, Int32?>
    @Persisted var mapOptInt64: Map<String, Int64?>
    @Persisted var mapOptFloat: Map<String, Float?>
    @Persisted var mapOptDouble: Map<String, Double?>
    @Persisted var mapOptString: Map<String, String?>
    @Persisted var mapOptBinary: Map<String, Data?>
    @Persisted var mapOptDate: Map<String, Date?>
    @Persisted var mapOptDecimal: Map<String, Decimal128?>
    @Persisted var mapOptObjectId: Map<String, ObjectId?>
    @Persisted var mapOptUuid: Map<String, UUID?>

    @Persisted(originProperty: "objectCol")
    var linkingObjects: LinkingObjects<ModernAllTypesObject>
}

class LinkToModernAllTypesObject: Object {
    @Persisted var object: ModernAllTypesObject?
    @Persisted var list: List<ModernAllTypesObject>
    @Persisted var set: MutableSet<ModernAllTypesObject>
    @Persisted var map: Map<String, ModernAllTypesObject?>
}

enum ModernIntEnum: Int, Codable, PersistableEnum {
    case value1 = 1
    case value2 = 3
    case value3 = 5
}
enum ModernStringEnum: String, Codable, PersistableEnum {
    case value1 = "a"
    case value2 = "c"
    case value3 = "e"
}

class ModernImplicitlyUnwrappedOptionalObject: Object {
    @Persisted var optStringCol: String!
    @Persisted var optBinaryCol: Data!
    @Persisted var optDateCol: Date!
    @Persisted var optDecimalCol: Decimal128!
    @Persisted var optObjectIdCol: ObjectId!
    @Persisted var optObjectCol: ModernImplicitlyUnwrappedOptionalObject!
    @Persisted var optUuidCol: UUID!
}

class ModernLinkToPrimaryStringObject: Object {
    @Persisted var pk = ""
    @Persisted var object: ModernPrimaryStringObject?
    @Persisted var objects: List<ModernPrimaryStringObject>

    override class func primaryKey() -> String? {
        return "pk"
    }
}

class ModernUTF8Object: Object {
    // swiftlint:disable:next identifier_name
    @Persisted var 柱колоéнǢкƱаم👍 = "值значен™👍☞⎠‱௹♣︎☐▼❒∑⨌⧭иеمرحبا"
}

protocol ModernPrimaryKeyObject: Object {
    associatedtype PrimaryKey: Equatable
    var pk: PrimaryKey { get set }
}

class ModernPrimaryStringObject: Object, ModernPrimaryKeyObject {
    @Persisted(primaryKey: true) var pk: String
}

class ModernPrimaryOptionalStringObject: Object, ModernPrimaryKeyObject {
    @Persisted(primaryKey: true) var pk: String?
}

class ModernPrimaryIntObject: Object, ModernPrimaryKeyObject {
    @Persisted(primaryKey: true) var pk: Int
}

class ModernPrimaryOptionalIntObject: Object, ModernPrimaryKeyObject {
    @Persisted(primaryKey: true) var pk: Int?
}

class ModernPrimaryInt8Object: Object, ModernPrimaryKeyObject {
    @Persisted(primaryKey: true) var pk: Int8
}

class ModernPrimaryOptionalInt8Object: Object, ModernPrimaryKeyObject {
    @Persisted(primaryKey: true) var pk: Int8?
}

class ModernPrimaryInt16Object: Object, ModernPrimaryKeyObject {
    @Persisted(primaryKey: true) var pk: Int16
}

class ModernPrimaryOptionalInt16Object: Object, ModernPrimaryKeyObject {
    @Persisted(primaryKey: true) var pk: Int16?
}

class ModernPrimaryInt32Object: Object, ModernPrimaryKeyObject {
    @Persisted(primaryKey: true) var pk: Int32
}

class ModernPrimaryOptionalInt32Object: Object, ModernPrimaryKeyObject {
    @Persisted(primaryKey: true) var pk: Int32?
}

class ModernPrimaryInt64Object: Object, ModernPrimaryKeyObject {
    @Persisted(primaryKey: true) var pk: Int64
}

class ModernPrimaryOptionalInt64Object: Object, ModernPrimaryKeyObject {
    @Persisted(primaryKey: true) var pk: Int64?
}

class ModernPrimaryUUIDObject: Object, ModernPrimaryKeyObject {
    @Persisted(primaryKey: true) var pk: UUID
}

class ModernPrimaryOptionalUUIDObject: Object, ModernPrimaryKeyObject {
    @Persisted(primaryKey: true) var pk: UUID?
}

class ModernPrimaryObjectIdObject: Object, ModernPrimaryKeyObject {
    @Persisted(primaryKey: true) var pk: ObjectId
}

class ModernPrimaryOptionalObjectIdObject: Object, ModernPrimaryKeyObject {
    @Persisted(primaryKey: true) var pk: ObjectId?
}

class ModernPrimaryIntEnumObject: Object, ModernPrimaryKeyObject {
    @Persisted(primaryKey: true) var pk: ModernIntEnum
}

class ModernPrimaryOptionalIntEnumObject: Object, ModernPrimaryKeyObject {
    @Persisted(primaryKey: true) var pk: ModernIntEnum?
}

class ModernIndexedIntEnumObject: Object {
    @Persisted(indexed: true) var value: ModernIntEnum
}

class ModernIndexedOptionalIntEnumObject: Object {
    @Persisted(indexed: true) var value: ModernIntEnum?
}

class ModernCustomInitializerObject: Object {
    @Persisted var stringCol: String

    init(stringVal: String) {
        stringCol = stringVal
        super.init()
    }

    required override init() {
        stringCol = ""
        super.init()
    }
}

class ModernConvenienceInitializerObject: Object {
    @Persisted var stringCol = ""

    convenience init(stringCol: String) {
        self.init()
        self.stringCol = stringCol
    }
}

@objc(ModernObjcRenamedObject)
class ModernObjcRenamedObject: Object {
    @Persisted var stringCol = ""
}

@objc(ModernObjcRenamedObjectWithTotallyDifferentName)
class ModernObjcArbitrarilyRenamedObject: Object {
    @Persisted var boolCol = false
}

class ModernIntAndStringObject: Object {
    @Persisted var intCol: Int
    @Persisted var optIntCol: Int?
    @Persisted var stringCol: String
    @Persisted var optStringCol: String?
}

class ModernCollectionObject: Object {
    @Persisted var list: List<ModernAllTypesObject>
    @Persisted var set: MutableSet<ModernAllTypesObject>
    @Persisted var map: Map<String, ModernAllTypesObject?>
}

class ModernCircleObject: Object {
    @Persisted var obj: ModernCircleObject?
    @Persisted var array: List<ModernCircleObject>
}

class ModernEmbeddedParentObject: Object {
    @Persisted var object: ModernEmbeddedTreeObject1?
    @Persisted var array: List<ModernEmbeddedTreeObject1>
}

class ModernEmbeddedPrimaryParentObject: Object {
    @Persisted(primaryKey: true) var pk: Int = 0
    @Persisted var object: ModernEmbeddedTreeObject1?
    @Persisted var array: List<ModernEmbeddedTreeObject1>
}

protocol ModernEmbeddedTreeObject: EmbeddedObject {
    var value: Int { get set }
}

class ModernEmbeddedTreeObject1: EmbeddedObject, ModernEmbeddedTreeObject {
    @Persisted var value = 0
    @Persisted var child: ModernEmbeddedTreeObject2?
    @Persisted var children: List<ModernEmbeddedTreeObject2>

    @Persisted(originProperty: "object")
    var parent1: LinkingObjects<ModernEmbeddedParentObject>
    @Persisted(originProperty: "array")
    var parent2: LinkingObjects<ModernEmbeddedParentObject>
}

class ModernEmbeddedTreeObject2: EmbeddedObject, ModernEmbeddedTreeObject {
    @Persisted var value = 0
    @Persisted var child: ModernEmbeddedTreeObject3?
    @Persisted var children: List<ModernEmbeddedTreeObject3>

    @Persisted(originProperty: "child")
    var parent3: LinkingObjects<ModernEmbeddedTreeObject1>
    @Persisted(originProperty: "children")
    var parent4: LinkingObjects<ModernEmbeddedTreeObject1>
}

class ModernEmbeddedTreeObject3: EmbeddedObject, ModernEmbeddedTreeObject {
    @Persisted var value = 0

    @Persisted(originProperty: "child")
    var parent3: LinkingObjects<ModernEmbeddedTreeObject2>
    @Persisted(originProperty: "children")
    var parent4: LinkingObjects<ModernEmbeddedTreeObject2>
}

class ModernEmbeddedObject: EmbeddedObject {
    @Persisted var value = 0
}

class SetterObservers: Object {
    @Persisted var value: Int {
        willSet {
            willSetCallback?()
        }
        didSet {
            didSetCallback?()
        }
    }

    var willSetCallback: (() -> Void)?
    var didSetCallback: (() -> Void)?
}

class ObjectWithArcMethodCategoryNames: Object {
    // @objc properties with these names would crash with asan (and unreliably
    // without it) because they would not have the correct behavior for the
    // inferred ARC method family.
    @Persisted var newValue: String
    @Persisted var allocValue: String
    @Persisted var copyValue: String
    @Persisted var mutableCopyValue: String
    @Persisted var initValue: String
}

class ModernAllIndexableTypesObject: Object {
    @Persisted(indexed: true) var boolCol: Bool
    @Persisted(indexed: true) var intCol: Int
    @Persisted(indexed: true) var int8Col: Int8 = 1
    @Persisted(indexed: true) var int16Col: Int16 = 2
    @Persisted(indexed: true) var int32Col: Int32 = 3
    @Persisted(indexed: true) var int64Col: Int64 = 4
    @Persisted(indexed: true) var stringCol: String
    @Persisted(indexed: true) var dateCol: Date
    @Persisted(indexed: true) var uuidCol: UUID
    @Persisted(indexed: true) var objectIdCol: ObjectId
    @Persisted(indexed: true) var intEnumCol: ModernIntEnum
    @Persisted(indexed: true) var stringEnumCol: ModernStringEnum

    @Persisted(indexed: true) var optIntCol: Int?
    @Persisted(indexed: true) var optInt8Col: Int8?
    @Persisted(indexed: true) var optInt16Col: Int16?
    @Persisted(indexed: true) var optInt32Col: Int32?
    @Persisted(indexed: true) var optInt64Col: Int64?
    @Persisted(indexed: true) var optBoolCol: Bool?
    @Persisted(indexed: true) var optStringCol: String?
    @Persisted(indexed: true) var optDateCol: Date?
    @Persisted(indexed: true) var optUuidCol: UUID?
    @Persisted(indexed: true) var optObjectIdCol: ObjectId?
    @Persisted(indexed: true) var optIntEnumCol: ModernIntEnum?
    @Persisted(indexed: true) var optStringEnumCol: ModernStringEnum?
}

class ModernAllIndexableButNotIndexedObject: Object {
    @Persisted(indexed: false) var boolCol: Bool
    @Persisted(indexed: false) var intCol: Int
    @Persisted(indexed: false) var int8Col: Int8 = 1
    @Persisted(indexed: false) var int16Col: Int16 = 2
    @Persisted(indexed: false) var int32Col: Int32 = 3
    @Persisted(indexed: false) var int64Col: Int64 = 4
    @Persisted(indexed: false) var stringCol: String
    @Persisted(indexed: false) var dateCol: Date
    @Persisted(indexed: false) var uuidCol: UUID
    @Persisted(indexed: false) var objectIdCol: ObjectId
    @Persisted(indexed: false) var intEnumCol: ModernIntEnum
    @Persisted(indexed: false) var stringEnumCol: ModernStringEnum

    @Persisted(indexed: false) var optIntCol: Int?
    @Persisted(indexed: false) var optInt8Col: Int8?
    @Persisted(indexed: false) var optInt16Col: Int16?
    @Persisted(indexed: false) var optInt32Col: Int32?
    @Persisted(indexed: false) var optInt64Col: Int64?
    @Persisted(indexed: false) var optBoolCol: Bool?
    @Persisted(indexed: false) var optStringCol: String?
    @Persisted(indexed: false) var optDateCol: Date?
    @Persisted(indexed: false) var optUuidCol: UUID?
    @Persisted(indexed: false) var optObjectIdCol: ObjectId?
    @Persisted(indexed: false) var optIntEnumCol: ModernIntEnum?
    @Persisted(indexed: false) var optStringEnumCol: ModernStringEnum?
}

class ModernCollectionsOfEnums: Object {
    @Persisted var listInt: List<EnumInt>
    @Persisted var listInt8: List<EnumInt8>
    @Persisted var listInt16: List<EnumInt16>
    @Persisted var listInt32: List<EnumInt32>
    @Persisted var listInt64: List<EnumInt64>
    @Persisted var listFloat: List<EnumFloat>
    @Persisted var listDouble: List<EnumDouble>
    @Persisted var listString: List<EnumString>

    @Persisted var listIntOpt: List<EnumInt?>
    @Persisted var listInt8Opt: List<EnumInt8?>
    @Persisted var listInt16Opt: List<EnumInt16?>
    @Persisted var listInt32Opt: List<EnumInt32?>
    @Persisted var listInt64Opt: List<EnumInt64?>
    @Persisted var listFloatOpt: List<EnumFloat?>
    @Persisted var listDoubleOpt: List<EnumDouble?>
    @Persisted var listStringOpt: List<EnumString?>

    @Persisted var setInt: MutableSet<EnumInt>
    @Persisted var setInt8: MutableSet<EnumInt8>
    @Persisted var setInt16: MutableSet<EnumInt16>
    @Persisted var setInt32: MutableSet<EnumInt32>
    @Persisted var setInt64: MutableSet<EnumInt64>
    @Persisted var setFloat: MutableSet<EnumFloat>
    @Persisted var setDouble: MutableSet<EnumDouble>
    @Persisted var setString: MutableSet<EnumString>

    @Persisted var setIntOpt: MutableSet<EnumInt?>
    @Persisted var setInt8Opt: MutableSet<EnumInt8?>
    @Persisted var setInt16Opt: MutableSet<EnumInt16?>
    @Persisted var setInt32Opt: MutableSet<EnumInt32?>
    @Persisted var setInt64Opt: MutableSet<EnumInt64?>
    @Persisted var setFloatOpt: MutableSet<EnumFloat?>
    @Persisted var setDoubleOpt: MutableSet<EnumDouble?>
    @Persisted var setStringOpt: MutableSet<EnumString?>

    @Persisted var mapInt: Map<String, EnumInt>
    @Persisted var mapInt8: Map<String, EnumInt8>
    @Persisted var mapInt16: Map<String, EnumInt16>
    @Persisted var mapInt32: Map<String, EnumInt32>
    @Persisted var mapInt64: Map<String, EnumInt64>
    @Persisted var mapFloat: Map<String, EnumFloat>
    @Persisted var mapDouble: Map<String, EnumDouble>
    @Persisted var mapString: Map<String, EnumString>

    @Persisted var mapIntOpt: Map<String, EnumInt?>
    @Persisted var mapInt8Opt: Map<String, EnumInt8?>
    @Persisted var mapInt16Opt: Map<String, EnumInt16?>
    @Persisted var mapInt32Opt: Map<String, EnumInt32?>
    @Persisted var mapInt64Opt: Map<String, EnumInt64?>
    @Persisted var mapFloatOpt: Map<String, EnumFloat?>
    @Persisted var mapDoubleOpt: Map<String, EnumDouble?>
    @Persisted var mapStringOpt: Map<String, EnumString?>
}

class LinkToModernCollectionsOfEnums: Object {
    @Persisted var object: ModernCollectionsOfEnums?
    @Persisted var list: List<ModernCollectionsOfEnums>
    @Persisted var set: MutableSet<ModernCollectionsOfEnums>
    @Persisted var map: Map<String, ModernCollectionsOfEnums?>
}

class ModernListAnyRealmValueObject: Object {
    @Persisted var value: List<AnyRealmValue>
}
