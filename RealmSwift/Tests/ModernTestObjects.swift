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
    @Persisted var arrayObject: List<ModernAllTypesObject>

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
    @Persisted var setObject: MutableSet<ModernAllTypesObject>

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

    @Persisted(originProperty: "object") var parent1: LinkingObjects<ModernEmbeddedParentObject>
    @Persisted(originProperty: "array") var parent2: LinkingObjects<ModernEmbeddedParentObject>
}

class ModernEmbeddedTreeObject2: EmbeddedObject, ModernEmbeddedTreeObject {
    @Persisted var value = 0
    @Persisted var child: ModernEmbeddedTreeObject3?
    @Persisted var children: List<ModernEmbeddedTreeObject3>

    @Persisted(originProperty: "child") var parent3: LinkingObjects<ModernEmbeddedTreeObject1>
    @Persisted(originProperty: "children") var parent4: LinkingObjects<ModernEmbeddedTreeObject1>
}

class ModernEmbeddedTreeObject3: EmbeddedObject, ModernEmbeddedTreeObject {
    @Persisted var value = 0

    @Persisted(originProperty: "child") var parent3: LinkingObjects<ModernEmbeddedTreeObject2>
    @Persisted(originProperty: "children") var parent4: LinkingObjects<ModernEmbeddedTreeObject2>
}
