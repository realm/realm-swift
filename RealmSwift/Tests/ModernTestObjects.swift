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
    @Managed(primaryKey: true) var pk: ObjectId
    var ignored: Int = 1

    @Managed var boolCol: Bool
    @Managed var intCol: Int
    @Managed var int8Col: Int8 = 1
    @Managed var int16Col: Int16 = 2
    @Managed var int32Col: Int32 = 3
    @Managed var int64Col: Int64 = 4
    @Managed var floatCol: Float = 5
    @Managed var doubleCol: Double = 6
    @Managed var stringCol: String
    @Managed var binaryCol: Data
    @Managed var dateCol: Date
    @Managed var decimalCol: Decimal128
    @Managed var objectIdCol: ObjectId
    @Managed var objectCol: ModernAllTypesObject?
    @Managed var arrayCol: List<ModernAllTypesObject>
    @Managed var setCol: MutableSet<ModernAllTypesObject>
    @Managed var anyCol: AnyRealmValue
    @Managed var uuidCol: UUID

    @Managed var optIntCol: Int?
    @Managed var optInt8Col: Int8?
    @Managed var optInt16Col: Int16?
    @Managed var optInt32Col: Int32?
    @Managed var optInt64Col: Int64?
    @Managed var optFloatCol: Float?
    @Managed var optDoubleCol: Double?
    @Managed var optBoolCol: Bool?
    @Managed var optStringCol: String?
    @Managed var optBinaryCol: Data?
    @Managed var optDateCol: Date?
    @Managed var optDecimalCol: Decimal128?
    @Managed var optObjectIdCol: ObjectId?
    @Managed var optUuidCol: UUID?

    @Managed var arrayBool: List<Bool>
    @Managed var arrayInt: List<Int>
    @Managed var arrayInt8: List<Int8>
    @Managed var arrayInt16: List<Int16>
    @Managed var arrayInt32: List<Int32>
    @Managed var arrayInt64: List<Int64>
    @Managed var arrayFloat: List<Float>
    @Managed var arrayDouble: List<Double>
    @Managed var arrayString: List<String>
    @Managed var arrayBinary: List<Data>
    @Managed var arrayDate: List<Date>
    @Managed var arrayDecimal: List<Decimal128>
    @Managed var arrayObjectId: List<ObjectId>
    @Managed var arrayAny: List<AnyRealmValue>
    @Managed var arrayUuid: List<UUID>
    @Managed var arrayObject: List<ModernAllTypesObject>

    @Managed var arrayOptBool: List<Bool?>
    @Managed var arrayOptInt: List<Int?>
    @Managed var arrayOptInt8: List<Int8?>
    @Managed var arrayOptInt16: List<Int16?>
    @Managed var arrayOptInt32: List<Int32?>
    @Managed var arrayOptInt64: List<Int64?>
    @Managed var arrayOptFloat: List<Float?>
    @Managed var arrayOptDouble: List<Double?>
    @Managed var arrayOptString: List<String?>
    @Managed var arrayOptBinary: List<Data?>
    @Managed var arrayOptDate: List<Date?>
    @Managed var arrayOptDecimal: List<Decimal128?>
    @Managed var arrayOptObjectId: List<ObjectId?>
    @Managed var arrayOptUuid: List<UUID?>

    @Managed var setBool: MutableSet<Bool>
    @Managed var setInt: MutableSet<Int>
    @Managed var setInt8: MutableSet<Int8>
    @Managed var setInt16: MutableSet<Int16>
    @Managed var setInt32: MutableSet<Int32>
    @Managed var setInt64: MutableSet<Int64>
    @Managed var setFloat: MutableSet<Float>
    @Managed var setDouble: MutableSet<Double>
    @Managed var setString: MutableSet<String>
    @Managed var setBinary: MutableSet<Data>
    @Managed var setDate: MutableSet<Date>
    @Managed var setDecimal: MutableSet<Decimal128>
    @Managed var setObjectId: MutableSet<ObjectId>
    @Managed var setAny: MutableSet<AnyRealmValue>
    @Managed var setUuid: MutableSet<UUID>
    @Managed var setObject: MutableSet<ModernAllTypesObject>

    @Managed var setOptBool: MutableSet<Bool?>
    @Managed var setOptInt: MutableSet<Int?>
    @Managed var setOptInt8: MutableSet<Int8?>
    @Managed var setOptInt16: MutableSet<Int16?>
    @Managed var setOptInt32: MutableSet<Int32?>
    @Managed var setOptInt64: MutableSet<Int64?>
    @Managed var setOptFloat: MutableSet<Float?>
    @Managed var setOptDouble: MutableSet<Double?>
    @Managed var setOptString: MutableSet<String?>
    @Managed var setOptBinary: MutableSet<Data?>
    @Managed var setOptDate: MutableSet<Date?>
    @Managed var setOptDecimal: MutableSet<Decimal128?>
    @Managed var setOptObjectId: MutableSet<ObjectId?>
    @Managed var setOptUuid: MutableSet<UUID?>

    // enum
}

// @objc enum IntEnum: Int, RealmEnum, Codable {
//     case value1 = 1
//     case value2 = 3
// }

class ModernImplicitlyUnwrappedOptionalObject: Object {
    @Managed var optStringCol: String!
    @Managed var optBinaryCol: Data!
    @Managed var optDateCol: Date!
    @Managed var optDecimalCol: Decimal128!
    @Managed var optObjectIdCol: ObjectId!
    @Managed var optObjectCol: ModernImplicitlyUnwrappedOptionalObject!
    @Managed var optUuidCol: UUID!
}

class ModernLinkToPrimaryStringObject: Object {
    @Managed var pk = ""
    @Managed var object: ModernPrimaryStringObject?
    @Managed var objects: List<ModernPrimaryStringObject>

    override class func primaryKey() -> String? {
        return "pk"
    }
}

class ModernUTF8Object: Object {
    // swiftlint:disable:next identifier_name
    @Managed var 柱колоéнǢкƱаم👍 = "值значен™👍☞⎠‱௹♣︎☐▼❒∑⨌⧭иеمرحبا"
}

protocol ModernPrimaryKeyObject: Object {
    associatedtype PrimaryKey: Equatable
    var pk: PrimaryKey { get set }
}

class ModernPrimaryStringObject: Object, ModernPrimaryKeyObject {
    @Managed(primaryKey: true) var pk: String
}

class ModernPrimaryOptionalStringObject: Object, ModernPrimaryKeyObject {
    @Managed(primaryKey: true) var pk: String?
}

class ModernPrimaryIntObject: Object, ModernPrimaryKeyObject {
    @Managed(primaryKey: true) var pk: Int
}

class ModernPrimaryOptionalIntObject: Object, ModernPrimaryKeyObject {
    @Managed(primaryKey: true) var pk: Int?
}

class ModernPrimaryInt8Object: Object, ModernPrimaryKeyObject {
    @Managed(primaryKey: true) var pk: Int8
}

class ModernPrimaryOptionalInt8Object: Object, ModernPrimaryKeyObject {
    @Managed(primaryKey: true) var pk: Int8?
}

class ModernPrimaryInt16Object: Object, ModernPrimaryKeyObject {
    @Managed(primaryKey: true) var pk: Int16
}

class ModernPrimaryOptionalInt16Object: Object, ModernPrimaryKeyObject {
    @Managed(primaryKey: true) var pk: Int16?
}

class ModernPrimaryInt32Object: Object, ModernPrimaryKeyObject {
    @Managed(primaryKey: true) var pk: Int32
}

class ModernPrimaryOptionalInt32Object: Object, ModernPrimaryKeyObject {
    @Managed(primaryKey: true) var pk: Int32?
}

class ModernPrimaryInt64Object: Object, ModernPrimaryKeyObject {
    @Managed(primaryKey: true) var pk: Int64
}

class ModernPrimaryOptionalInt64Object: Object, ModernPrimaryKeyObject {
    @Managed(primaryKey: true) var pk: Int64?
}

class ModernPrimaryUUIDObject: Object, ModernPrimaryKeyObject {
    @Managed(primaryKey: true) var pk: UUID
}

class ModernPrimaryOptionalUUIDObject: Object, ModernPrimaryKeyObject {
    @Managed(primaryKey: true) var pk: UUID?
}

class ModernPrimaryObjectIdObject: Object, ModernPrimaryKeyObject {
    @Managed(primaryKey: true) var pk: ObjectId
}

class ModernPrimaryOptionalObjectIdObject: Object, ModernPrimaryKeyObject {
    @Managed(primaryKey: true) var pk: ObjectId?
}

class ModernCustomInitializerObject: Object {
    @Managed var stringCol: String

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
    @Managed var stringCol = ""

    convenience init(stringCol: String) {
        self.init()
        self.stringCol = stringCol
    }
}

@objc(ModernObjcRenamedObject)
class ModernObjcRenamedObject: Object {
    @Managed var stringCol = ""
}

@objc(ModernObjcRenamedObjectWithTotallyDifferentName)
class ModernObjcArbitrarilyRenamedObject: Object {
    @Managed var boolCol = false
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
    @Managed var obj: ModernCircleObject?
    @Managed var array: List<ModernCircleObject>
}

class ModernEmbeddedParentObject: Object {
    @Managed var object: ModernEmbeddedTreeObject1?
    @Managed var array: List<ModernEmbeddedTreeObject1>
}

class ModernEmbeddedPrimaryParentObject: Object {
    @Managed(primaryKey: true) var pk: Int = 0
    @Managed var object: ModernEmbeddedTreeObject1?
    @Managed var array: List<ModernEmbeddedTreeObject1>
}

protocol ModernEmbeddedTreeObject: EmbeddedObject {
    var value: Int { get set }
}

class ModernEmbeddedTreeObject1: EmbeddedObject, ModernEmbeddedTreeObject {
    @Managed var value = 0
    @Managed var child: ModernEmbeddedTreeObject2?
    @Managed var children: List<ModernEmbeddedTreeObject2>

    @Managed(originProperty: "object") var parent1: LinkingObjects<ModernEmbeddedParentObject>
    @Managed(originProperty: "array") var parent2: LinkingObjects<ModernEmbeddedParentObject>
}

class ModernEmbeddedTreeObject2: EmbeddedObject, ModernEmbeddedTreeObject {
    @Managed var value = 0
    @Managed var child: ModernEmbeddedTreeObject3?
    @Managed var children: List<ModernEmbeddedTreeObject3>

    @Managed(originProperty: "child") var parent3: LinkingObjects<ModernEmbeddedTreeObject1>
    @Managed(originProperty: "children") var parent4: LinkingObjects<ModernEmbeddedTreeObject1>
}

class ModernEmbeddedTreeObject3: EmbeddedObject, ModernEmbeddedTreeObject {
    @Managed var value = 0

    @Managed(originProperty: "child") var parent3: LinkingObjects<ModernEmbeddedTreeObject2>
    @Managed(originProperty: "children") var parent4: LinkingObjects<ModernEmbeddedTreeObject2>
}
