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

class KeyPathTests: TestCase {

    func testModernObjectTopLevel() {
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.pk), "pk")

        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.boolCol), "boolCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.intCol), "intCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.int8Col), "int8Col")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.int16Col), "int16Col")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.int32Col), "int32Col")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.int64Col), "int64Col")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.floatCol), "floatCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.doubleCol), "doubleCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.stringCol), "stringCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.binaryCol), "binaryCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.dateCol), "dateCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.decimalCol), "decimalCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectIdCol), "objectIdCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol), "objectCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.arrayCol), "arrayCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.setCol), "setCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.anyCol), "anyCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.uuidCol), "uuidCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.intEnumCol), "intEnumCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.stringEnumCol), "stringEnumCol")

        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.optIntCol), "optIntCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.optInt8Col), "optInt8Col")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.optInt16Col), "optInt16Col")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.optInt32Col), "optInt32Col")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.optInt64Col), "optInt64Col")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.optFloatCol), "optFloatCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.optDoubleCol), "optDoubleCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.optStringCol), "optStringCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.optBinaryCol), "optBinaryCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.optDateCol), "optDateCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.optDecimalCol), "optDecimalCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.optObjectIdCol), "optObjectIdCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.optUuidCol), "optUuidCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.optIntEnumCol), "optIntEnumCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.optStringEnumCol), "optStringEnumCol")

        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.arrayBool), "arrayBool")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.arrayInt), "arrayInt")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.arrayInt8), "arrayInt8")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.arrayInt16), "arrayInt16")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.arrayInt32), "arrayInt32")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.arrayInt64), "arrayInt64")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.arrayFloat), "arrayFloat")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.arrayDouble), "arrayDouble")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.arrayString), "arrayString")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.arrayBinary), "arrayBinary")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.arrayDate), "arrayDate")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.arrayDecimal), "arrayDecimal")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.arrayObjectId), "arrayObjectId")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.arrayAny), "arrayAny")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.arrayUuid), "arrayUuid")

        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.arrayOptBool), "arrayOptBool")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.arrayOptInt), "arrayOptInt")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.arrayOptInt8), "arrayOptInt8")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.arrayOptInt16), "arrayOptInt16")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.arrayOptInt32), "arrayOptInt32")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.arrayOptInt64), "arrayOptInt64")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.arrayOptFloat), "arrayOptFloat")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.arrayOptDouble), "arrayOptDouble")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.arrayOptString), "arrayOptString")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.arrayOptBinary), "arrayOptBinary")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.arrayOptDate), "arrayOptDate")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.arrayOptDecimal), "arrayOptDecimal")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.arrayOptObjectId), "arrayOptObjectId")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.arrayOptUuid), "arrayOptUuid")

        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.setBool), "setBool")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.setInt), "setInt")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.setInt8), "setInt8")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.setInt16), "setInt16")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.setInt32), "setInt32")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.setInt64), "setInt64")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.setFloat), "setFloat")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.setDouble), "setDouble")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.setString), "setString")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.setBinary), "setBinary")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.setDate), "setDate")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.setDecimal), "setDecimal")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.setObjectId), "setObjectId")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.setAny), "setAny")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.setUuid), "setUuid")

        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.setOptBool), "setOptBool")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.setOptInt), "setOptInt")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.setOptInt8), "setOptInt8")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.setOptInt16), "setOptInt16")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.setOptInt32), "setOptInt32")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.setOptInt64), "setOptInt64")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.setOptFloat), "setOptFloat")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.setOptDouble), "setOptDouble")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.setOptString), "setOptString")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.setOptBinary), "setOptBinary")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.setOptDate), "setOptDate")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.setOptDecimal), "setOptDecimal")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.setOptObjectId), "setOptObjectId")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.setOptUuid), "setOptUuid")

        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.mapBool), "mapBool")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.mapInt), "mapInt")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.mapInt8), "mapInt8")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.mapInt16), "mapInt16")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.mapInt32), "mapInt32")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.mapInt64), "mapInt64")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.mapFloat), "mapFloat")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.mapDouble), "mapDouble")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.mapString), "mapString")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.mapBinary), "mapBinary")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.mapDate), "mapDate")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.mapDecimal), "mapDecimal")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.mapObjectId), "mapObjectId")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.mapAny), "mapAny")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.mapUuid), "mapUuid")

        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.mapOptBool), "mapOptBool")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.mapOptInt), "mapOptInt")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.mapOptInt8), "mapOptInt8")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.mapOptInt16), "mapOptInt16")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.mapOptInt32), "mapOptInt32")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.mapOptInt64), "mapOptInt64")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.mapOptFloat), "mapOptFloat")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.mapOptDouble), "mapOptDouble")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.mapOptString), "mapOptString")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.mapOptBinary), "mapOptBinary")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.mapOptDate), "mapOptDate")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.mapOptDecimal), "mapOptDecimal")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.mapOptObjectId), "mapOptObjectId")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.mapOptUuid), "mapOptUuid")

        XCTAssertEqual(ObjectBase._name(for: \ModernKeyPathObject.embeddedCol), "embeddedCol")

        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.linkingObjects), "linkingObjects")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.linkingObjects[0].boolCol), "linkingObjects.boolCol")

        XCTAssertEqual(ObjectBase._name(for: \ModernKeyPathObject.list), "list")
        XCTAssertEqual(ObjectBase._name(for: \ModernKeyPathObject.list[0].boolCol), "list.boolCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernKeyPathObject.list[0].objectCol), "list.objectCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernKeyPathObject.list[0].objectCol?.linkingObjects), "list.objectCol.linkingObjects")
        XCTAssertEqual(ObjectBase._name(for: \ModernKeyPathObject.list[0].objectCol?.linkingObjects[0].boolCol), "list.objectCol.linkingObjects.boolCol")

        XCTAssertEqual(ObjectBase._name(for: \ModernKeyPathObject.set), "set")
        XCTAssertEqual(ObjectBase._name(for: \ModernKeyPathObject.set[0].boolCol), "set.boolCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernKeyPathObject.set[0].objectCol), "set.objectCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernKeyPathObject.set[0].objectCol?.linkingObjects), "set.objectCol.linkingObjects")
        XCTAssertEqual(ObjectBase._name(for: \ModernKeyPathObject.set[0].objectCol?.linkingObjects[0].boolCol), "set.objectCol.linkingObjects.boolCol")

        XCTAssertEqual(ObjectBase._name(for: \ModernKeyPathObject.map), "map")
        XCTAssertEqual(ObjectBase._name(for: \ModernKeyPathObject.map[""]??.boolCol), "map.boolCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernKeyPathObject.map[""]??.objectCol), "map.objectCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernKeyPathObject.map[""]??.objectCol?.linkingObjects), "map.objectCol.linkingObjects")
        XCTAssertEqual(ObjectBase._name(for: \ModernKeyPathObject.map[""]??.objectCol?.linkingObjects[0].boolCol), "map.objectCol.linkingObjects.boolCol")
    }

    func testModernObjectNested() {
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.pk), "objectCol.pk")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.boolCol), "objectCol.boolCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.intCol), "objectCol.intCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.int8Col), "objectCol.int8Col")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.int16Col), "objectCol.int16Col")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.int32Col), "objectCol.int32Col")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.int64Col), "objectCol.int64Col")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.floatCol), "objectCol.floatCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.doubleCol), "objectCol.doubleCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.stringCol), "objectCol.stringCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.binaryCol), "objectCol.binaryCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.dateCol), "objectCol.dateCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.decimalCol), "objectCol.decimalCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.objectIdCol), "objectCol.objectIdCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.objectCol), "objectCol.objectCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.arrayCol), "objectCol.arrayCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.setCol), "objectCol.setCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.anyCol), "objectCol.anyCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.uuidCol), "objectCol.uuidCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.intEnumCol), "objectCol.intEnumCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.stringEnumCol), "objectCol.stringEnumCol")

        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.optIntCol), "objectCol.optIntCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.optInt8Col), "objectCol.optInt8Col")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.optInt16Col), "objectCol.optInt16Col")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.optInt32Col), "objectCol.optInt32Col")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.optInt64Col), "objectCol.optInt64Col")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.optFloatCol), "objectCol.optFloatCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.optDoubleCol), "objectCol.optDoubleCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.optStringCol), "objectCol.optStringCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.optBinaryCol), "objectCol.optBinaryCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.optDateCol), "objectCol.optDateCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.optDecimalCol), "objectCol.optDecimalCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.optObjectIdCol), "objectCol.optObjectIdCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.optUuidCol), "objectCol.optUuidCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.optIntEnumCol), "objectCol.optIntEnumCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.optStringEnumCol), "objectCol.optStringEnumCol")

        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.arrayBool), "objectCol.arrayBool")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.arrayInt), "objectCol.arrayInt")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.arrayInt8), "objectCol.arrayInt8")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.arrayInt16), "objectCol.arrayInt16")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.arrayInt32), "objectCol.arrayInt32")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.arrayInt64), "objectCol.arrayInt64")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.arrayFloat), "objectCol.arrayFloat")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.arrayDouble), "objectCol.arrayDouble")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.arrayString), "objectCol.arrayString")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.arrayBinary), "objectCol.arrayBinary")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.arrayDate), "objectCol.arrayDate")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.arrayDecimal), "objectCol.arrayDecimal")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.arrayObjectId), "objectCol.arrayObjectId")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.arrayAny), "objectCol.arrayAny")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.arrayUuid), "objectCol.arrayUuid")

        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.arrayOptBool), "objectCol.arrayOptBool")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.arrayOptInt), "objectCol.arrayOptInt")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.arrayOptInt8), "objectCol.arrayOptInt8")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.arrayOptInt16), "objectCol.arrayOptInt16")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.arrayOptInt32), "objectCol.arrayOptInt32")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.arrayOptInt64), "objectCol.arrayOptInt64")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.arrayOptFloat), "objectCol.arrayOptFloat")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.arrayOptDouble), "objectCol.arrayOptDouble")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.arrayOptString), "objectCol.arrayOptString")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.arrayOptBinary), "objectCol.arrayOptBinary")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.arrayOptDate), "objectCol.arrayOptDate")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.arrayOptDecimal), "objectCol.arrayOptDecimal")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.arrayOptObjectId), "objectCol.arrayOptObjectId")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.arrayOptUuid), "objectCol.arrayOptUuid")

        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.setBool), "objectCol.setBool")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.setInt), "objectCol.setInt")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.setInt8), "objectCol.setInt8")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.setInt16), "objectCol.setInt16")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.setInt32), "objectCol.setInt32")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.setInt64), "objectCol.setInt64")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.setFloat), "objectCol.setFloat")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.setDouble), "objectCol.setDouble")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.setString), "objectCol.setString")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.setBinary), "objectCol.setBinary")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.setDate), "objectCol.setDate")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.setDecimal), "objectCol.setDecimal")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.setObjectId), "objectCol.setObjectId")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.setAny), "objectCol.setAny")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.setUuid), "objectCol.setUuid")

        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.setOptBool), "objectCol.setOptBool")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.setOptInt), "objectCol.setOptInt")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.setOptInt8), "objectCol.setOptInt8")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.setOptInt16), "objectCol.setOptInt16")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.setOptInt32), "objectCol.setOptInt32")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.setOptInt64), "objectCol.setOptInt64")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.setOptFloat), "objectCol.setOptFloat")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.setOptDouble), "objectCol.setOptDouble")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.setOptString), "objectCol.setOptString")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.setOptBinary), "objectCol.setOptBinary")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.setOptDate), "objectCol.setOptDate")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.setOptDecimal), "objectCol.setOptDecimal")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.setOptObjectId), "objectCol.setOptObjectId")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.setOptUuid), "objectCol.setOptUuid")

        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.mapBool), "objectCol.mapBool")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.mapInt), "objectCol.mapInt")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.mapInt8), "objectCol.mapInt8")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.mapInt16), "objectCol.mapInt16")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.mapInt32), "objectCol.mapInt32")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.mapInt64), "objectCol.mapInt64")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.mapFloat), "objectCol.mapFloat")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.mapDouble), "objectCol.mapDouble")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.mapString), "objectCol.mapString")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.mapBinary), "objectCol.mapBinary")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.mapDate), "objectCol.mapDate")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.mapDecimal), "objectCol.mapDecimal")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.mapObjectId), "objectCol.mapObjectId")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.mapAny), "objectCol.mapAny")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.mapUuid), "objectCol.mapUuid")

        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.mapOptBool), "objectCol.mapOptBool")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.mapOptInt), "objectCol.mapOptInt")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.mapOptInt8), "objectCol.mapOptInt8")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.mapOptInt16), "objectCol.mapOptInt16")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.mapOptInt32), "objectCol.mapOptInt32")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.mapOptInt64), "objectCol.mapOptInt64")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.mapOptFloat), "objectCol.mapOptFloat")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.mapOptDouble), "objectCol.mapOptDouble")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.mapOptString), "objectCol.mapOptString")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.mapOptBinary), "objectCol.mapOptBinary")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.mapOptDate), "objectCol.mapOptDate")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.mapOptDecimal), "objectCol.mapOptDecimal")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.mapOptObjectId), "objectCol.mapOptObjectId")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.mapOptUuid), "objectCol.mapOptUuid")

        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.linkingObjects), "objectCol.linkingObjects")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.linkingObjects[0].boolCol), "objectCol.linkingObjects.boolCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesObject.objectCol?.linkingObjects[0].objectCol?.linkingObjects[0].boolCol),
                       "objectCol.linkingObjects.objectCol.linkingObjects.boolCol")
    }

    func testOldObjectSyntax() {
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesObject.boolCol), "boolCol")
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesObject.intCol), "intCol")
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesObject.int8Col), "int8Col")
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesObject.int16Col), "int16Col")
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesObject.int32Col), "int32Col")
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesObject.int64Col), "int64Col")
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesObject.intEnumCol), "intEnumCol")
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesObject.floatCol), "floatCol")
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesObject.doubleCol), "doubleCol")
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesObject.stringCol), "stringCol")
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesObject.binaryCol), "binaryCol")
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesObject.dateCol), "dateCol")
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesObject.decimalCol), "decimalCol")
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesObject.objectIdCol), "objectIdCol")
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesObject.objectCol), "objectCol")
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesObject.objectCol?.boolCol), "objectCol.boolCol")
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesObject.uuidCol), "uuidCol")
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesObject.embeddedCol), "embeddedCol")
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesObject.embeddedCol?.boolCol), "embeddedCol.boolCol")

        // Nested objects will work fine once they can utilize _kvcKeyPathString.
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesObject.embeddedCol?.embeddedCol?.child), "embeddedCol.embeddedCol.child")

        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesObject.anyCol), "anyCol")

        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesObject.arrayCol), "arrayCol")
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesObject.setCol), "setCol")
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesObject.mapCol), "mapCol")

        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesObject.arrayObjCol), "arrayObjCol")
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesObject.setObjCol), "setObjCol")
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesObject.mapObjCol), "mapObjCol")

        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesObject.arrayEmbeddedCol), "arrayEmbeddedCol")
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesObject.mapEmbeddedCol), "mapEmbeddedCol")

        XCTAssertEqual(ObjectBase._name(for: \SwiftDogObject.owners), "owners")

        // Allowing old property syntax objects to do nested key path strings involves an invasive change to `unmanagedGetter` in RLMAccessor.
        // We would need to prevent the getter function from returning `nil` and instead return a block that appends the property name to the
        // tracing array in the object. This would break a ton of other stuff and instead it is recommened that a user use @Persisted
    }

    func testOldSyntaxEmbeddedObject() {
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesEmbeddedObject.boolCol), "boolCol")
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesEmbeddedObject.intCol), "intCol")
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesEmbeddedObject.int8Col), "int8Col")
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesEmbeddedObject.int16Col), "int16Col")
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesEmbeddedObject.int32Col), "int32Col")
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesEmbeddedObject.int64Col), "int64Col")
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesEmbeddedObject.intEnumCol), "intEnumCol")
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesEmbeddedObject.floatCol), "floatCol")
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesEmbeddedObject.doubleCol), "doubleCol")
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesEmbeddedObject.stringCol), "stringCol")
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesEmbeddedObject.binaryCol), "binaryCol")
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesEmbeddedObject.dateCol), "dateCol")
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesEmbeddedObject.decimalCol), "decimalCol")
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesEmbeddedObject.objectIdCol), "objectIdCol")
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesEmbeddedObject.uuidCol), "uuidCol")
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesEmbeddedObject.anyCol), "anyCol")

        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesEmbeddedObject.arrayCol), "arrayCol")
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesEmbeddedObject.setCol), "setCol")
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesEmbeddedObject.mapCol), "mapCol")

        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesEmbeddedObject.arrayEmbeddedCol), "arrayEmbeddedCol")
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesEmbeddedObject.mapEmbeddedCol), "mapEmbeddedCol")

        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesEmbeddedObject.embeddedCol), "embeddedCol")
        XCTAssertEqual(ObjectBase._name(for: \SwiftOldSyntaxAllTypesEmbeddedObject.embeddedCol?.child), "embeddedCol.child")
    }

    func testEmbeddedObject() {
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesEmbeddedObject.boolCol), "boolCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesEmbeddedObject.intCol), "intCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesEmbeddedObject.int8Col), "int8Col")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesEmbeddedObject.int16Col), "int16Col")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesEmbeddedObject.int32Col), "int32Col")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesEmbeddedObject.int64Col), "int64Col")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesEmbeddedObject.intEnumCol), "intEnumCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesEmbeddedObject.floatCol), "floatCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesEmbeddedObject.doubleCol), "doubleCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesEmbeddedObject.stringCol), "stringCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesEmbeddedObject.binaryCol), "binaryCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesEmbeddedObject.dateCol), "dateCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesEmbeddedObject.decimalCol), "decimalCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesEmbeddedObject.objectIdCol), "objectIdCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesEmbeddedObject.uuidCol), "uuidCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesEmbeddedObject.anyCol), "anyCol")

        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesEmbeddedObject.arrayCol), "arrayCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesEmbeddedObject.setCol), "setCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesEmbeddedObject.mapCol), "mapCol")

        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesEmbeddedObject.arrayEmbeddedCol), "arrayEmbeddedCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesEmbeddedObject.mapEmbeddedCol), "mapEmbeddedCol")

        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesEmbeddedObject.embeddedCol), "embeddedCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesEmbeddedObject.embeddedCol?.child), "embeddedCol.child")

        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesEmbeddedObject.embeddedCol?.child?.value), "embeddedCol.child.value")

        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesEmbeddedObject.arrayEmbeddedCol[0].value), "arrayEmbeddedCol.value")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesEmbeddedObject.arrayEmbeddedCol[0].child?.value), "arrayEmbeddedCol.child.value")

        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesEmbeddedObject.mapEmbeddedCol), "mapEmbeddedCol")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesEmbeddedObject.mapEmbeddedCol[""]??.value), "mapEmbeddedCol.value")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesEmbeddedObject.mapEmbeddedCol[""]??.child), "mapEmbeddedCol.child")
        XCTAssertEqual(ObjectBase._name(for: \ModernAllTypesEmbeddedObject.mapEmbeddedCol[""]??.child?.value), "mapEmbeddedCol.child.value")
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

class ModernKeyPathObject: Object {
    @Persisted var embeddedCol: ModernAllTypesEmbeddedObject?
    @Persisted var list: List<ModernAllTypesObject>
    @Persisted var listEmbedded: List<ModernAllTypesObject>
    @Persisted var set: MutableSet<ModernAllTypesObject>
    @Persisted var map: Map<String, ModernAllTypesObject?>
    @Persisted var mapEmbedded: Map<String, ModernAllTypesObject?>
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
