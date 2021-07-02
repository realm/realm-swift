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
import Foundation

class ModernKeyPathObject: Object {
    @Persisted var embeddedCol: ModernAllTypesEmbeddedObject?

    @Persisted var list: List<ModernAllTypesObject>
    @Persisted var listEmbedded: List<ModernAllTypesObject>

    @Persisted var set: MutableSet<ModernAllTypesObject>
    @Persisted var map: Map<String, ModernAllTypesObject?>
    @Persisted var mapEmbedded: Map<String, ModernAllTypesObject?>
}

class KeyPathTests: TestCase {

    private func produceString<Root: ObjectBase>(keyPath: PartialKeyPath<Root>) -> String {
        Object._name(for: keyPath)
    }

    func testModernObjectTopLevel() {
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.pk), "pk")

        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.boolCol), "boolCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.intCol), "intCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.int8Col), "int8Col")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.int16Col), "int16Col")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.int32Col), "int32Col")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.int64Col), "int64Col")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.floatCol), "floatCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.doubleCol), "doubleCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.stringCol), "stringCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.binaryCol), "binaryCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.dateCol), "dateCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.decimalCol), "decimalCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectIdCol), "objectIdCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol), "objectCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.arrayCol), "arrayCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.setCol), "setCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.anyCol), "anyCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.uuidCol), "uuidCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.intEnumCol), "intEnumCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.stringEnumCol), "stringEnumCol")

        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.optIntCol), "optIntCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.optInt8Col), "optInt8Col")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.optInt16Col), "optInt16Col")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.optInt32Col), "optInt32Col")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.optInt64Col), "optInt64Col")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.optFloatCol), "optFloatCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.optDoubleCol), "optDoubleCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.optStringCol), "optStringCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.optBinaryCol), "optBinaryCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.optDateCol), "optDateCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.optDecimalCol), "optDecimalCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.optObjectIdCol), "optObjectIdCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.optUuidCol), "optUuidCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.optIntEnumCol), "optIntEnumCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.optStringEnumCol), "optStringEnumCol")

        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.arrayBool), "arrayBool")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.arrayInt), "arrayInt")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.arrayInt8), "arrayInt8")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.arrayInt16), "arrayInt16")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.arrayInt32), "arrayInt32")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.arrayInt64), "arrayInt64")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.arrayFloat), "arrayFloat")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.arrayDouble), "arrayDouble")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.arrayString), "arrayString")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.arrayBinary), "arrayBinary")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.arrayDate), "arrayDate")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.arrayDecimal), "arrayDecimal")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.arrayObjectId), "arrayObjectId")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.arrayAny), "arrayAny")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.arrayUuid), "arrayUuid")

        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.arrayOptBool), "arrayOptBool")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.arrayOptInt), "arrayOptInt")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.arrayOptInt8), "arrayOptInt8")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.arrayOptInt16), "arrayOptInt16")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.arrayOptInt32), "arrayOptInt32")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.arrayOptInt64), "arrayOptInt64")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.arrayOptFloat), "arrayOptFloat")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.arrayOptDouble), "arrayOptDouble")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.arrayOptString), "arrayOptString")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.arrayOptBinary), "arrayOptBinary")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.arrayOptDate), "arrayOptDate")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.arrayOptDecimal), "arrayOptDecimal")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.arrayOptObjectId), "arrayOptObjectId")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.arrayOptUuid), "arrayOptUuid")

        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.setBool), "setBool")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.setInt), "setInt")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.setInt8), "setInt8")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.setInt16), "setInt16")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.setInt32), "setInt32")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.setInt64), "setInt64")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.setFloat), "setFloat")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.setDouble), "setDouble")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.setString), "setString")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.setBinary), "setBinary")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.setDate), "setDate")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.setDecimal), "setDecimal")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.setObjectId), "setObjectId")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.setAny), "setAny")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.setUuid), "setUuid")

        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.setOptBool), "setOptBool")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.setOptInt), "setOptInt")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.setOptInt8), "setOptInt8")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.setOptInt16), "setOptInt16")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.setOptInt32), "setOptInt32")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.setOptInt64), "setOptInt64")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.setOptFloat), "setOptFloat")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.setOptDouble), "setOptDouble")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.setOptString), "setOptString")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.setOptBinary), "setOptBinary")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.setOptDate), "setOptDate")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.setOptDecimal), "setOptDecimal")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.setOptObjectId), "setOptObjectId")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.setOptUuid), "setOptUuid")

        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.mapBool), "mapBool")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.mapInt), "mapInt")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.mapInt8), "mapInt8")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.mapInt16), "mapInt16")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.mapInt32), "mapInt32")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.mapInt64), "mapInt64")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.mapFloat), "mapFloat")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.mapDouble), "mapDouble")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.mapString), "mapString")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.mapBinary), "mapBinary")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.mapDate), "mapDate")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.mapDecimal), "mapDecimal")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.mapObjectId), "mapObjectId")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.mapAny), "mapAny")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.mapUuid), "mapUuid")

        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.mapOptBool), "mapOptBool")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.mapOptInt), "mapOptInt")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.mapOptInt8), "mapOptInt8")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.mapOptInt16), "mapOptInt16")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.mapOptInt32), "mapOptInt32")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.mapOptInt64), "mapOptInt64")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.mapOptFloat), "mapOptFloat")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.mapOptDouble), "mapOptDouble")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.mapOptString), "mapOptString")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.mapOptBinary), "mapOptBinary")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.mapOptDate), "mapOptDate")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.mapOptDecimal), "mapOptDecimal")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.mapOptObjectId), "mapOptObjectId")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.mapOptUuid), "mapOptUuid")

        XCTAssertEqual(produceString(keyPath: \ModernKeyPathObject.embeddedCol), "embeddedCol")

        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.linkingObjects), "linkingObjects")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.linkingObjects[0].boolCol), "linkingObjects.boolCol")

        XCTAssertEqual(produceString(keyPath: \ModernKeyPathObject.list), "list")
        XCTAssertEqual(produceString(keyPath: \ModernKeyPathObject.list[0].boolCol), "list.boolCol")
        XCTAssertEqual(produceString(keyPath: \ModernKeyPathObject.list[0].objectCol), "list.objectCol")
        XCTAssertEqual(produceString(keyPath: \ModernKeyPathObject.list[0].objectCol?.linkingObjects), "list.objectCol.linkingObjects")
        XCTAssertEqual(produceString(keyPath: \ModernKeyPathObject.list[0].objectCol?.linkingObjects[0].boolCol), "list.objectCol.linkingObjects.boolCol")

        XCTAssertEqual(produceString(keyPath: \ModernKeyPathObject.set), "set")
        XCTAssertEqual(produceString(keyPath: \ModernKeyPathObject.set[0].boolCol), "set.boolCol")
        XCTAssertEqual(produceString(keyPath: \ModernKeyPathObject.set[0].objectCol), "set.objectCol")
        XCTAssertEqual(produceString(keyPath: \ModernKeyPathObject.set[0].objectCol?.linkingObjects), "set.objectCol.linkingObjects")
        XCTAssertEqual(produceString(keyPath: \ModernKeyPathObject.set[0].objectCol?.linkingObjects[0].boolCol), "set.objectCol.linkingObjects.boolCol")

        XCTAssertEqual(produceString(keyPath: \ModernKeyPathObject.map), "map")
        XCTAssertEqual(produceString(keyPath: \ModernKeyPathObject.map[""]??.boolCol), "map.boolCol")
        XCTAssertEqual(produceString(keyPath: \ModernKeyPathObject.map[""]??.objectCol), "map.objectCol")
        XCTAssertEqual(produceString(keyPath: \ModernKeyPathObject.map[""]??.objectCol?.linkingObjects), "map.objectCol.linkingObjects")
        XCTAssertEqual(produceString(keyPath: \ModernKeyPathObject.map[""]??.objectCol?.linkingObjects[0].boolCol), "map.objectCol.linkingObjects.boolCol")

        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.linkingObjects), "objectCol.linkingObjects")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.linkingObjects[0].boolCol), "objectCol.linkingObjects.boolCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.linkingObjects[0].objectCol?.linkingObjects[0].boolCol),
                       "objectCol.linkingObjects.objectCol.linkingObjects.boolCol")

    }

    func testModernObjectNested() {
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.pk), "objectCol.pk")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.boolCol), "objectCol.boolCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.intCol), "objectCol.intCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.int8Col), "objectCol.int8Col")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.int16Col), "objectCol.int16Col")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.int32Col), "objectCol.int32Col")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.int64Col), "objectCol.int64Col")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.floatCol), "objectCol.floatCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.doubleCol), "objectCol.doubleCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.stringCol), "objectCol.stringCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.binaryCol), "objectCol.binaryCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.dateCol), "objectCol.dateCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.decimalCol), "objectCol.decimalCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.objectIdCol), "objectCol.objectIdCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.objectCol), "objectCol.objectCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.arrayCol), "objectCol.arrayCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.setCol), "objectCol.setCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.anyCol), "objectCol.anyCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.uuidCol), "objectCol.uuidCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.intEnumCol), "objectCol.intEnumCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.stringEnumCol), "objectCol.stringEnumCol")

        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.optIntCol), "objectCol.optIntCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.optInt8Col), "objectCol.optInt8Col")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.optInt16Col), "objectCol.optInt16Col")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.optInt32Col), "objectCol.optInt32Col")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.optInt64Col), "objectCol.optInt64Col")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.optFloatCol), "objectCol.optFloatCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.optDoubleCol), "objectCol.optDoubleCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.optStringCol), "objectCol.optStringCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.optBinaryCol), "objectCol.optBinaryCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.optDateCol), "objectCol.optDateCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.optDecimalCol), "objectCol.optDecimalCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.optObjectIdCol), "objectCol.optObjectIdCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.optUuidCol), "objectCol.optUuidCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.optIntEnumCol), "objectCol.optIntEnumCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.optStringEnumCol), "objectCol.optStringEnumCol")

        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.arrayBool), "objectCol.arrayBool")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.arrayInt), "objectCol.arrayInt")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.arrayInt8), "objectCol.arrayInt8")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.arrayInt16), "objectCol.arrayInt16")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.arrayInt32), "objectCol.arrayInt32")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.arrayInt64), "objectCol.arrayInt64")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.arrayFloat), "objectCol.arrayFloat")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.arrayDouble), "objectCol.arrayDouble")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.arrayString), "objectCol.arrayString")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.arrayBinary), "objectCol.arrayBinary")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.arrayDate), "objectCol.arrayDate")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.arrayDecimal), "objectCol.arrayDecimal")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.arrayObjectId), "objectCol.arrayObjectId")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.arrayAny), "objectCol.arrayAny")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.arrayUuid), "objectCol.arrayUuid")

        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.arrayOptBool), "objectCol.arrayOptBool")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.arrayOptInt), "objectCol.arrayOptInt")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.arrayOptInt8), "objectCol.arrayOptInt8")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.arrayOptInt16), "objectCol.arrayOptInt16")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.arrayOptInt32), "objectCol.arrayOptInt32")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.arrayOptInt64), "objectCol.arrayOptInt64")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.arrayOptFloat), "objectCol.arrayOptFloat")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.arrayOptDouble), "objectCol.arrayOptDouble")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.arrayOptString), "objectCol.arrayOptString")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.arrayOptBinary), "objectCol.arrayOptBinary")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.arrayOptDate), "objectCol.arrayOptDate")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.arrayOptDecimal), "objectCol.arrayOptDecimal")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.arrayOptObjectId), "objectCol.arrayOptObjectId")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.arrayOptUuid), "objectCol.arrayOptUuid")

        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.setBool), "objectCol.setBool")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.setInt), "objectCol.setInt")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.setInt8), "objectCol.setInt8")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.setInt16), "objectCol.setInt16")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.setInt32), "objectCol.setInt32")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.setInt64), "objectCol.setInt64")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.setFloat), "objectCol.setFloat")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.setDouble), "objectCol.setDouble")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.setString), "objectCol.setString")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.setBinary), "objectCol.setBinary")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.setDate), "objectCol.setDate")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.setDecimal), "objectCol.setDecimal")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.setObjectId), "objectCol.setObjectId")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.setAny), "objectCol.setAny")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.setUuid), "objectCol.setUuid")

        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.setOptBool), "objectCol.setOptBool")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.setOptInt), "objectCol.setOptInt")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.setOptInt8), "objectCol.setOptInt8")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.setOptInt16), "objectCol.setOptInt16")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.setOptInt32), "objectCol.setOptInt32")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.setOptInt64), "objectCol.setOptInt64")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.setOptFloat), "objectCol.setOptFloat")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.setOptDouble), "objectCol.setOptDouble")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.setOptString), "objectCol.setOptString")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.setOptBinary), "objectCol.setOptBinary")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.setOptDate), "objectCol.setOptDate")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.setOptDecimal), "objectCol.setOptDecimal")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.setOptObjectId), "objectCol.setOptObjectId")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.setOptUuid), "objectCol.setOptUuid")

        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.mapBool), "objectCol.mapBool")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.mapInt), "objectCol.mapInt")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.mapInt8), "objectCol.mapInt8")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.mapInt16), "objectCol.mapInt16")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.mapInt32), "objectCol.mapInt32")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.mapInt64), "objectCol.mapInt64")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.mapFloat), "objectCol.mapFloat")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.mapDouble), "objectCol.mapDouble")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.mapString), "objectCol.mapString")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.mapBinary), "objectCol.mapBinary")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.mapDate), "objectCol.mapDate")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.mapDecimal), "objectCol.mapDecimal")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.mapObjectId), "objectCol.mapObjectId")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.mapAny), "objectCol.mapAny")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.mapUuid), "objectCol.mapUuid")

        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.mapOptBool), "objectCol.mapOptBool")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.mapOptInt), "objectCol.mapOptInt")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.mapOptInt8), "objectCol.mapOptInt8")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.mapOptInt16), "objectCol.mapOptInt16")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.mapOptInt32), "objectCol.mapOptInt32")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.mapOptInt64), "objectCol.mapOptInt64")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.mapOptFloat), "objectCol.mapOptFloat")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.mapOptDouble), "objectCol.mapOptDouble")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.mapOptString), "objectCol.mapOptString")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.mapOptBinary), "objectCol.mapOptBinary")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.mapOptDate), "objectCol.mapOptDate")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.mapOptDecimal), "objectCol.mapOptDecimal")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.mapOptObjectId), "objectCol.mapOptObjectId")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.mapOptUuid), "objectCol.mapOptUuid")

        XCTAssertEqual(produceString(keyPath: \ModernAllTypesObject.objectCol?.linkingObjects), "objectCol.linkingObjects")
    }

    func testOldObjectSyntax() {
        XCTAssertEqual(produceString(keyPath: \SwiftOldSyntaxAllTypesObject.boolCol), "boolCol")
        XCTAssertEqual(produceString(keyPath: \SwiftOldSyntaxAllTypesObject.intCol), "intCol")
        XCTAssertEqual(produceString(keyPath: \SwiftOldSyntaxAllTypesObject.int8Col), "int8Col")
        XCTAssertEqual(produceString(keyPath: \SwiftOldSyntaxAllTypesObject.int16Col), "int16Col")
        XCTAssertEqual(produceString(keyPath: \SwiftOldSyntaxAllTypesObject.int32Col), "int32Col")
        XCTAssertEqual(produceString(keyPath: \SwiftOldSyntaxAllTypesObject.int64Col), "int64Col")
        XCTAssertEqual(produceString(keyPath: \SwiftOldSyntaxAllTypesObject.intEnumCol), "intEnumCol")
        XCTAssertEqual(produceString(keyPath: \SwiftOldSyntaxAllTypesObject.floatCol), "floatCol")
        XCTAssertEqual(produceString(keyPath: \SwiftOldSyntaxAllTypesObject.doubleCol), "doubleCol")
        XCTAssertEqual(produceString(keyPath: \SwiftOldSyntaxAllTypesObject.stringCol), "stringCol")
        XCTAssertEqual(produceString(keyPath: \SwiftOldSyntaxAllTypesObject.binaryCol), "binaryCol")
        XCTAssertEqual(produceString(keyPath: \SwiftOldSyntaxAllTypesObject.dateCol), "dateCol")
        XCTAssertEqual(produceString(keyPath: \SwiftOldSyntaxAllTypesObject.decimalCol), "decimalCol")
        XCTAssertEqual(produceString(keyPath: \SwiftOldSyntaxAllTypesObject.objectIdCol), "objectIdCol")
        XCTAssertEqual(produceString(keyPath: \SwiftOldSyntaxAllTypesObject.objectCol), "objectCol")
        XCTAssertEqual(produceString(keyPath: \SwiftOldSyntaxAllTypesObject.objectCol?.boolCol), "objectCol.boolCol")
        XCTAssertEqual(produceString(keyPath: \SwiftOldSyntaxAllTypesObject.uuidCol), "uuidCol")
        XCTAssertEqual(produceString(keyPath: \SwiftOldSyntaxAllTypesObject.anyCol), "anyCol")

        XCTAssertEqual(produceString(keyPath: \SwiftOldSyntaxAllTypesObject.arrayCol), "arrayCol")
        XCTAssertEqual(produceString(keyPath: \SwiftOldSyntaxAllTypesObject.setCol), "setCol")
        XCTAssertEqual(produceString(keyPath: \SwiftOldSyntaxAllTypesObject.mapCol), "mapCol")

        XCTAssertEqual(produceString(keyPath: \SwiftOldSyntaxAllTypesObject.arrayObjCol), "arrayObjCol")
        XCTAssertEqual(produceString(keyPath: \SwiftOldSyntaxAllTypesObject.setObjCol), "setObjCol")
        XCTAssertEqual(produceString(keyPath: \SwiftOldSyntaxAllTypesObject.mapObjCol), "mapObjCol")

        XCTAssertEqual(produceString(keyPath: \SwiftOldSyntaxAllTypesObject.arrayEmbeddedCol), "arrayEmbeddedCol")
        XCTAssertEqual(produceString(keyPath: \SwiftOldSyntaxAllTypesObject.mapEmbeddedCol), "mapEmbeddedCol")

        XCTAssertEqual(produceString(keyPath: \SwiftOldSyntaxAllTypesObject.embeddedCol), "embeddedCol")
        XCTAssertEqual(produceString(keyPath: \SwiftOldSyntaxAllTypesObject.embeddedCol?.boolCol), "embeddedCol.boolCol")

        XCTAssertEqual(produceString(keyPath: \SwiftOldSyntaxAllTypesObject.embeddedCol?.embeddedCol?.child), "embeddedCol.embeddedCol.child")
    }

//    func testOldSyntaxEmbeddedObject() {
//        XCTAssertEqual(produceEmbeddedString(keyPath: \SwiftOldSyntaxAllTypesEmbeddedObject.boolCol), "boolCol")
//        XCTAssertEqual(produceEmbeddedString(keyPath: \SwiftOldSyntaxAllTypesEmbeddedObject.intCol), "intCol")
//        XCTAssertEqual(produceEmbeddedString(keyPath: \SwiftOldSyntaxAllTypesEmbeddedObject.int8Col), "int8Col")
//        XCTAssertEqual(produceEmbeddedString(keyPath: \SwiftOldSyntaxAllTypesEmbeddedObject.int16Col), "int16Col")
//        XCTAssertEqual(produceEmbeddedString(keyPath: \SwiftOldSyntaxAllTypesEmbeddedObject.int32Col), "int32Col")
//        XCTAssertEqual(produceEmbeddedString(keyPath: \SwiftOldSyntaxAllTypesEmbeddedObject.int64Col), "int64Col")
//        XCTAssertEqual(produceEmbeddedString(keyPath: \SwiftOldSyntaxAllTypesEmbeddedObject.intEnumCol), "intEnumCol")
//        XCTAssertEqual(produceEmbeddedString(keyPath: \SwiftOldSyntaxAllTypesEmbeddedObject.floatCol), "floatCol")
//        XCTAssertEqual(produceEmbeddedString(keyPath: \SwiftOldSyntaxAllTypesEmbeddedObject.doubleCol), "doubleCol")
//        XCTAssertEqual(produceEmbeddedString(keyPath: \SwiftOldSyntaxAllTypesEmbeddedObject.stringCol), "stringCol")
//        XCTAssertEqual(produceEmbeddedString(keyPath: \SwiftOldSyntaxAllTypesEmbeddedObject.binaryCol), "binaryCol")
//        XCTAssertEqual(produceEmbeddedString(keyPath: \SwiftOldSyntaxAllTypesEmbeddedObject.dateCol), "dateCol")
//        XCTAssertEqual(produceEmbeddedString(keyPath: \SwiftOldSyntaxAllTypesEmbeddedObject.decimalCol), "decimalCol")
//        XCTAssertEqual(produceEmbeddedString(keyPath: \SwiftOldSyntaxAllTypesEmbeddedObject.objectIdCol), "objectIdCol")
//        XCTAssertEqual(produceEmbeddedString(keyPath: \SwiftOldSyntaxAllTypesEmbeddedObject.uuidCol), "uuidCol")
//        XCTAssertEqual(produceEmbeddedString(keyPath: \SwiftOldSyntaxAllTypesEmbeddedObject.anyCol), "anyCol")
//
//        XCTAssertEqual(produceEmbeddedString(keyPath: \SwiftOldSyntaxAllTypesEmbeddedObject.arrayCol), "arrayCol")
//        XCTAssertEqual(produceEmbeddedString(keyPath: \SwiftOldSyntaxAllTypesEmbeddedObject.setCol), "setCol")
//        XCTAssertEqual(produceEmbeddedString(keyPath: \SwiftOldSyntaxAllTypesEmbeddedObject.mapCol), "mapCol")
//
//        XCTAssertEqual(produceEmbeddedString(keyPath: \SwiftOldSyntaxAllTypesEmbeddedObject.arrayEmbeddedCol), "arrayEmbeddedCol")
//        XCTAssertEqual(produceEmbeddedString(keyPath: \SwiftOldSyntaxAllTypesEmbeddedObject.mapEmbeddedCol), "mapEmbeddedCol")
//
//        XCTAssertEqual(produceEmbeddedString(keyPath: \SwiftOldSyntaxAllTypesEmbeddedObject.embeddedCol), "embeddedCol")
//        XCTAssertEqual(produceEmbeddedString(keyPath: \SwiftOldSyntaxAllTypesEmbeddedObject.embeddedCol?.child), "embeddedCol.child")
//
//        XCTAssertEqual(produceEmbeddedString(keyPath: \SwiftOldSyntaxAllTypesEmbeddedObject.embeddedCol?.child?.children), "embeddedCol.child.children")
//    }

    func testEmbeddedObject() {
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesEmbeddedObject.boolCol), "boolCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesEmbeddedObject.intCol), "intCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesEmbeddedObject.int8Col), "int8Col")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesEmbeddedObject.int16Col), "int16Col")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesEmbeddedObject.int32Col), "int32Col")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesEmbeddedObject.int64Col), "int64Col")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesEmbeddedObject.intEnumCol), "intEnumCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesEmbeddedObject.floatCol), "floatCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesEmbeddedObject.doubleCol), "doubleCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesEmbeddedObject.stringCol), "stringCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesEmbeddedObject.binaryCol), "binaryCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesEmbeddedObject.dateCol), "dateCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesEmbeddedObject.decimalCol), "decimalCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesEmbeddedObject.objectIdCol), "objectIdCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesEmbeddedObject.uuidCol), "uuidCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesEmbeddedObject.anyCol), "anyCol")

        XCTAssertEqual(produceString(keyPath: \ModernAllTypesEmbeddedObject.arrayCol), "arrayCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesEmbeddedObject.setCol), "setCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesEmbeddedObject.mapCol), "mapCol")

        XCTAssertEqual(produceString(keyPath: \ModernAllTypesEmbeddedObject.arrayEmbeddedCol), "arrayEmbeddedCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesEmbeddedObject.mapEmbeddedCol), "mapEmbeddedCol")

        XCTAssertEqual(produceString(keyPath: \ModernAllTypesEmbeddedObject.embeddedCol), "embeddedCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesEmbeddedObject.embeddedCol?.child), "embeddedCol.child")

        XCTAssertEqual(produceString(keyPath: \ModernAllTypesEmbeddedObject.embeddedCol?.child?.value), "embeddedCol.child.value")

        XCTAssertEqual(produceString(keyPath: \ModernAllTypesEmbeddedObject.arrayEmbeddedCol[0].value), "arrayEmbeddedCol.value")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesEmbeddedObject.arrayEmbeddedCol[0].child?.value), "arrayEmbeddedCol.child.value")

        XCTAssertEqual(produceString(keyPath: \ModernAllTypesEmbeddedObject.mapEmbeddedCol), "mapEmbeddedCol")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesEmbeddedObject.mapEmbeddedCol[""]??.value), "mapEmbeddedCol.value")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesEmbeddedObject.mapEmbeddedCol[""]??.child), "mapEmbeddedCol.child")
        XCTAssertEqual(produceString(keyPath: \ModernAllTypesEmbeddedObject.mapEmbeddedCol[""]??.child?.value), "mapEmbeddedCol.child.value")
    }
}

class SwiftOldSyntaxAllTypesObject: Object {
    @objc dynamic var boolCol = false
    @objc dynamic var intCol = 123
    @objc dynamic var int8Col: Int8 = 123
    @objc dynamic var int16Col: Int16 = 123
    @objc dynamic var int32Col: Int32 = 123
    @objc dynamic var int64Col: Int64 = 123
    @objc dynamic var intEnumCol = IntEnum.value1
    @objc dynamic var floatCol = 1.23 as Float
    @objc dynamic var doubleCol = 12.3
    @objc dynamic var stringCol = "a"
    @objc dynamic var binaryCol = "a".data(using: String.Encoding.utf8)!
    @objc dynamic var dateCol = Date(timeIntervalSince1970: 1)
    @objc dynamic var decimalCol = Decimal128("123e4")
    @objc dynamic var objectIdCol = ObjectId("1234567890ab1234567890ab")
    @objc dynamic var objectCol: SwiftBoolObject? = SwiftBoolObject()
    @objc dynamic var uuidCol: UUID = UUID(uuidString: "137decc8-b300-4954-a233-f89909f4fd89")!
    @objc dynamic var embeddedCol: SwiftOldSyntaxAllTypesEmbeddedObject? = SwiftOldSyntaxAllTypesEmbeddedObject()

    let anyCol = RealmProperty<AnyRealmValue>()

    let arrayCol = List<Int>()
    let setCol = MutableSet<Int>()
    let mapCol = Map<String, Int>()

    let arrayObjCol = List<SwiftObject>()
    let setObjCol = MutableSet<SwiftObject>()
    let mapObjCol = Map<String, SwiftObject?>()

    let arrayEmbeddedCol = List<EmbeddedTreeObject1>()
    let mapEmbeddedCol = Map<String, EmbeddedTreeObject1?>()
}

class SwiftOldSyntaxAllTypesEmbeddedObject: EmbeddedObject {
    @objc dynamic var boolCol = false
    @objc dynamic var intCol = 123
    @objc dynamic var int8Col: Int8 = 123
    @objc dynamic var int16Col: Int16 = 123
    @objc dynamic var int32Col: Int32 = 123
    @objc dynamic var int64Col: Int64 = 123
    @objc dynamic var intEnumCol = IntEnum.value1
    @objc dynamic var floatCol = 1.23 as Float
    @objc dynamic var doubleCol = 12.3
    @objc dynamic var stringCol = "a"
    @objc dynamic var binaryCol = "a".data(using: String.Encoding.utf8)!
    @objc dynamic var dateCol = Date(timeIntervalSince1970: 1)
    @objc dynamic var decimalCol = Decimal128("123e4")
    @objc dynamic var objectIdCol = ObjectId("1234567890ab1234567890ab")
    @objc dynamic var uuidCol: UUID = UUID(uuidString: "137decc8-b300-4954-a233-f89909f4fd89")!

    let anyCol = RealmProperty<AnyRealmValue>()
    @objc dynamic var embeddedCol: EmbeddedTreeObject1?

    let arrayCol = List<Int>()
    let setCol = MutableSet<Int>()
    let mapCol = Map<String, Int>()

    let arrayEmbeddedCol = List<EmbeddedTreeObject3>()
    let mapEmbeddedCol = Map<String, EmbeddedTreeObject1?>()
}

class ModernKeyPathStringParentObject: Object {
    @Persisted var embeddedCol: ModernAllTypesEmbeddedObject?
}

class ModernAllTypesEmbeddedObject: EmbeddedObject {
    @Persisted var boolCol = false
    @Persisted var intCol = 123
    @Persisted var int8Col: Int8 = 123
    @Persisted var int16Col: Int16 = 123
    @Persisted var int32Col: Int32 = 123
    @Persisted var int64Col: Int64 = 123
    @Persisted var intEnumCol: ModernIntEnum
    @Persisted var floatCol = 1.23 as Float
    @Persisted var doubleCol = 12.3
    @Persisted var stringCol = "a"
    @Persisted var binaryCol = "a".data(using: String.Encoding.utf8)!
    @Persisted var dateCol = Date(timeIntervalSince1970: 1)
    @Persisted var decimalCol = Decimal128("123e4")
    @Persisted var objectIdCol = ObjectId("1234567890ab1234567890ab")
    @Persisted var uuidCol: UUID = UUID(uuidString: "137decc8-b300-4954-a233-f89909f4fd89")!

    @Persisted var anyCol: AnyRealmValue
    @Persisted var embeddedCol: ModernEmbeddedTreeObject2?

    @Persisted var arrayCol: List<Int>
    @Persisted var setCol: MutableSet<Int>
    @Persisted var mapCol: Map<String, Int>

    @Persisted var arrayEmbeddedCol: List<ModernEmbeddedTreeObject2>
    @Persisted var mapEmbeddedCol: Map<String, ModernEmbeddedTreeObject2?>
}
