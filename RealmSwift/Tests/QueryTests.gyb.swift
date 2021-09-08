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
%{
    # How to use:
    #
    # $ wget https://github.com/apple/swift/raw/main/utils/gyb
    # $ wget https://github.com/apple/swift/raw/main/utils/gyb.py
    # $ chmod +x gyb
    #
    # ./YOUR_GYB_LOCATION/gyb --line-directive '' -o QueryTests.swift QueryTests.gyb.swift
}%
%{
    import sys
    reload(sys)
    sys.setdefaultencoding('utf-8')

    class Property:
        def __init__(self, colName, values, type, category, enumName=None):
            self.colName = colName
            self.values = values
            self.type = type
            self.category = category
            self.enumName = enumName

        def foundationValue(self, index):
          if self.category == 'any':
            return self.values[index][1]
          else:
            return self.values[index]

        def value(self, index):
          if self.category == 'any':
            return 'AnyRealmValue' + self.values[index][0] + '(' + str(self.values[index][1]) + ')'
          else:
            return self.values[index]


    properties = [
        Property('boolCol', ['true', 'false'], 'Bool', 'bool'),
        Property('intCol', [5, 6, 7], 'Int', 'numeric'),
        Property('int8Col', ['Int8(8)', 'Int8(9)', 'Int8(10)'], 'Int8', 'numeric'),
        Property('int16Col', ['Int16(16)', 'Int16(17)', 'Int16(18)'], 'Int16', 'numeric'),
        Property('int32Col', ['Int32(32)', 'Int32(33)', 'Int32(34)'], 'Int32', 'numeric'),
        Property('int64Col', ['Int64(64)', 'Int64(65)', 'Int64(66)'], 'Int64', 'numeric'),
        Property('floatCol', ['Float(5.55444333)', 'Float(6.55444333)', 'Float(7.55444333)'], 'Float', 'numeric'),
        Property('doubleCol', [5.55444333, 6.55444333, 7.55444333], 'Double', 'numeric'),
        Property('stringCol', ['"Foo"', '"Foó"', '"foo"'], 'String', 'string'),
        Property('binaryCol', ['Data(count: 64)', 'Data(count: 128)'], 'Data', 'binary'),
        Property('dateCol', ['Date(timeIntervalSince1970: 1000000)', 'Date(timeIntervalSince1970: 2000000)', 'Date(timeIntervalSince1970: 3000000)'], 'Date', 'numeric'),
        Property('decimalCol', ['Decimal128(123.456)', 'Decimal128(234.456)', 'Decimal128(345.456)'], 'Decimal128', 'numeric'),
        Property('objectIdCol', ['ObjectId("61184062c1d8f096a3695046")', 'ObjectId("61184062c1d8f096a3695045")'], 'ObjectId', 'objectId'),
        Property('intEnumCol', ['.value1', '.value2'], 'Int', 'numeric', 'ModernIntEnum.value2.rawValue'),
        Property('stringEnumCol', ['.value1', '.value2'], 'String', 'string', 'ModernStringEnum.value2.rawValue'),
        Property('uuidCol', ['UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!', 'UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!'], 'UUID', 'uuid')
    ]

    optProperties = [
        Property('optBoolCol', ['true', 'false'], 'Bool?', 'bool'),
        Property('optIntCol', [5, 6, 7], 'Int?', 'numeric'),
        Property('optInt8Col', ['Int8(8)', 'Int8(9)', 'Int8(10)'], 'Int8?', 'numeric'),
        Property('optInt16Col', ['Int16(16)', 'Int16(17)', 'Int16(18)'], 'Int16?', 'numeric'),
        Property('optInt32Col', ['Int32(32)', 'Int32(33)', 'Int32(34)'], 'Int32?', 'numeric'),
        Property('optInt64Col', ['Int64(64)', 'Int64(65)', 'Int64(66)'], 'Int64?', 'numeric'),
        Property('optFloatCol', ['Float(5.55444333)', 'Float(6.55444333)', 'Float(7.55444333)'], 'Float?', 'numeric'),
        Property('optDoubleCol', [5.55444333, 6.55444333, 7.55444333], 'Double?', 'numeric'),
        Property('optStringCol', ['"Foo"', '"Foó"', '"foo"'], 'String?', 'string'),
        Property('optBinaryCol', ['Data(count: 64)', 'Data(count: 128)'], 'Data?', 'binary'),
        Property('optDateCol', ['Date(timeIntervalSince1970: 1000000)', 'Date(timeIntervalSince1970: 2000000)', 'Date(timeIntervalSince1970: 3000000)'], 'Date?', 'numeric'),
        Property('optDecimalCol', ['Decimal128(123.456)', 'Decimal128(234.456)', 'Decimal128(345.456)'], 'Decimal128?', 'numeric'),
        Property('optObjectIdCol', ['ObjectId("61184062c1d8f096a3695046")', 'ObjectId("61184062c1d8f096a3695045")'], 'ObjectId?', 'objectId'),
        Property('optIntEnumCol', ['.value1', '.value2'], 'Int?', 'numeric', 'ModernIntEnum.value2.rawValue'),
        Property('optStringEnumCol', ['.value1', '.value2'], 'String?', 'string', 'ModernStringEnum.value2.rawValue'),
        Property('optUuidCol', ['UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!', 'UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!'], 'UUID?', 'uuid')
    ]

    listProperties = [
        Property('arrayBool', ['true', 'true', 'false'], 'Bool', 'bool'),
        Property('arrayInt', [1, 2, 3], 'Int', 'numeric'),
        Property('arrayInt8', ['Int8(8)', 'Int8(9)', 'Int8(10)'], 'Int8', 'numeric'),
        Property('arrayInt16', ['Int16(16)', 'Int16(17)', 'Int16(18)'], 'Int16', 'numeric'),
        Property('arrayInt32', ['Int32(32)', 'Int32(33)', 'Int32(34)'], 'Int32', 'numeric'),
        Property('arrayInt64', ['Int64(64)', 'Int64(65)', 'Int64(66)'], 'Int64', 'numeric'),
        Property('arrayFloat', ['Float(5.55444333)', 'Float(6.55444333)', 'Float(7.55444333)'], 'Float', 'numeric'),
        Property('arrayDouble', [123.456, 234.456, 345.567], 'Double', 'numeric'),
        Property('arrayString', ['"Foo"', '"Bar"', '"Baz"'], 'String', 'string'),
        Property('arrayBinary', ['Data(count: 64)', 'Data(count: 128)', 'Data(count: 256)'], 'Data', 'binary'),
        Property('arrayDate', ['Date(timeIntervalSince1970: 1000000)', 'Date(timeIntervalSince1970: 2000000)', 'Date(timeIntervalSince1970: 3000000)'], 'Date', 'numeric'),
        Property('arrayDecimal', ['Decimal128(123.456)', 'Decimal128(456.789)', 'Decimal128(963.852)'], 'Decimal128', 'numeric'),
        Property('arrayObjectId', ['ObjectId("61184062c1d8f096a3695046")', 'ObjectId("61184062c1d8f096a3695045")', 'ObjectId("61184062c1d8f096a3695044")'], 'ObjectId', 'objectId'),
        Property('arrayUuid', ['UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!', 'UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!', 'UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d08e")!'], 'UUID', 'uuid'),
        Property('arrayAny', [['.objectId', 'ObjectId("61184062c1d8f096a3695046")'], ['.string', '"Hello"'], ['.int', 123]], 'AnyRealmValue', 'any'),
    ]

    optListProperties = [
        Property('arrayOptBool', ['true', 'true', 'false'], 'Bool?', 'bool'),
        Property('arrayOptInt', [1, 2, 3], 'Int?', 'numeric'),
        Property('arrayOptInt8', ['Int8(8)', 'Int8(9)', 'Int8(10)'], 'Int8?', 'numeric'),
        Property('arrayOptInt16', ['Int16(16)', 'Int16(17)', 'Int16(18)'], 'Int16?', 'numeric'),
        Property('arrayOptInt32', ['Int32(32)', 'Int32(33)', 'Int32(34)'], 'Int32?', 'numeric'),
        Property('arrayOptInt64', ['Int64(64)', 'Int64(65)', 'Int64(66)'], 'Int64?', 'numeric'),
        Property('arrayOptFloat', ['Float(5.55444333)', 'Float(6.55444333)', 'Float(7.55444333)'], 'Float?', 'numeric'),
        Property('arrayOptDouble', [123.456, 234.456, 345.567], 'Double?', 'numeric'),
        Property('arrayOptString', ['"Foo"', '"Bar"', '"Baz"'], 'String?', 'string'),
        Property('arrayOptBinary', ['Data(count: 64)', 'Data(count: 128)', 'Data(count: 256)'], 'Data?', 'binary'),
        Property('arrayOptDate', ['Date(timeIntervalSince1970: 1000000)', 'Date(timeIntervalSince1970: 2000000)', 'Date(timeIntervalSince1970: 3000000)'], 'Date?', 'numeric'),
        Property('arrayOptDecimal', ['Decimal128(123.456)', 'Decimal128(456.789)', 'Decimal128(963.852)'], 'Decimal128?', 'numeric'),
        Property('arrayOptUuid', ['UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!', 'UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!', 'UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d08e")!'], 'UUID?', 'uuid'),
        Property('arrayOptObjectId', ['ObjectId("61184062c1d8f096a3695046")', 'ObjectId("61184062c1d8f096a3695045")', 'ObjectId("61184062c1d8f096a3695044")'], 'ObjectId?', 'objectId'),
    ]

    setProperties = [
        Property('setBool', ['true', 'true', 'false'], 'Bool', 'bool'),
        Property('setInt', [1, 2, 3], 'Int', 'numeric'),
        Property('setInt8', ['Int8(8)', 'Int8(9)', 'Int8(10)'], 'Int8', 'numeric'),
        Property('setInt16', ['Int16(16)', 'Int16(17)', 'Int16(18)'], 'Int16', 'numeric'),
        Property('setInt32', ['Int32(32)', 'Int32(33)', 'Int32(34)'], 'Int32', 'numeric'),
        Property('setInt64', ['Int64(64)', 'Int64(65)', 'Int64(66)'], 'Int64', 'numeric'),
        Property('setFloat', ['Float(5.55444333)', 'Float(6.55444333)', 'Float(7.55444333)'], 'Float', 'numeric'),
        Property('setDouble', [123.456, 234.456, 345.567], 'Double', 'numeric'),
        Property('setString', ['"Foo"', '"Bar"', '"Baz"'], 'String', 'string'),
        Property('setBinary', ['Data(count: 64)', 'Data(count: 128)', 'Data(count: 256)'], 'Data', 'binary'),
        Property('setDate', ['Date(timeIntervalSince1970: 1000000)', 'Date(timeIntervalSince1970: 2000000)', 'Date(timeIntervalSince1970: 3000000)'], 'Date', 'numeric'),
        Property('setDecimal', ['Decimal128(123.456)', 'Decimal128(456.789)', 'Decimal128(963.852)'], 'Decimal128', 'numeric'),
        Property('setObjectId', ['ObjectId("61184062c1d8f096a3695046")', 'ObjectId("61184062c1d8f096a3695045")', 'ObjectId("61184062c1d8f096a3695044")'], 'ObjectId', 'objectId'),
        Property('setUuid', ['UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!', 'UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!', 'UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d08e")!'], 'UUID', 'uuid'),
        Property('setAny', [['.objectId', 'ObjectId("61184062c1d8f096a3695046")'], ['.string', '"Hello"'], ['.int', 123]], 'AnyRealmValue', 'any'),
    ]

    optSetProperties = [
        Property('setOptBool', ['true', 'true', 'false'], 'Bool?', 'bool'),
        Property('setOptInt', [1, 2, 3], 'Int?', 'numeric'),
        Property('setOptInt8', ['Int8(8)', 'Int8(9)', 'Int8(10)'], 'Int8?', 'numeric'),
        Property('setOptInt16', ['Int16(16)', 'Int16(17)', 'Int16(18)'], 'Int16?', 'numeric'),
        Property('setOptInt32', ['Int32(32)', 'Int32(33)', 'Int32(34)'], 'Int32?', 'numeric'),
        Property('setOptInt64', ['Int64(64)', 'Int64(65)', 'Int64(66)'], 'Int64?', 'numeric'),
        Property('setOptFloat', ['Float(5.55444333)', 'Float(6.55444333)', 'Float(7.55444333)'], 'Float?', 'numeric'),
        Property('setOptDouble', [123.456, 234.456, 345.567], 'Double?', 'numeric'),
        Property('setOptString', ['"Foo"', '"Bar"', '"Baz"'], 'String?', 'string'),
        Property('setOptBinary', ['Data(count: 64)', 'Data(count: 128)', 'Data(count: 256)'], 'Data?', 'binary'),
        Property('setOptDate', ['Date(timeIntervalSince1970: 1000000)', 'Date(timeIntervalSince1970: 2000000)', 'Date(timeIntervalSince1970: 3000000)'], 'Date?', 'numeric'),
        Property('setOptDecimal', ['Decimal128(123.456)', 'Decimal128(456.789)', 'Decimal128(963.852)'], 'Decimal128?', 'numeric'),
        Property('setOptUuid', ['UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!', 'UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!', 'UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d08e")!'], 'UUID?', 'uuid'),
        Property('setOptObjectId', ['ObjectId("61184062c1d8f096a3695046")', 'ObjectId("61184062c1d8f096a3695045")', 'ObjectId("61184062c1d8f096a3695044")'], 'ObjectId?', 'objectId'),
    ]

    mapProperties = [
        Property('mapBool', ['true', 'true', 'false'], 'Bool', 'bool'),
        Property('mapInt', [1, 2, 3], 'Int', 'numeric'),
        Property('mapInt8', ['Int8(8)', 'Int8(9)', 'Int8(10)'], 'Int8', 'numeric'),
        Property('mapInt16', ['Int16(16)', 'Int16(17)', 'Int16(18)'], 'Int16', 'numeric'),
        Property('mapInt32', ['Int32(32)', 'Int32(33)', 'Int32(34)'], 'Int32', 'numeric'),
        Property('mapInt64', ['Int64(64)', 'Int64(65)', 'Int64(66)'], 'Int64', 'numeric'),
        Property('mapFloat', ['Float(5.55444333)', 'Float(6.55444333)', 'Float(7.55444333)'], 'Float', 'numeric'),
        Property('mapDouble', [123.456, 234.456, 345.567], 'Double', 'numeric'),
        Property('mapString', ['"Foo"', '"Bar"', '"Baz"'], 'String', 'string'),
        Property('mapBinary', ['Data(count: 64)', 'Data(count: 128)', 'Data(count: 256)'], 'Data', 'binary'),
        Property('mapDate', ['Date(timeIntervalSince1970: 1000000)', 'Date(timeIntervalSince1970: 2000000)', 'Date(timeIntervalSince1970: 3000000)'], 'Date', 'numeric'),
        Property('mapDecimal', ['Decimal128(123.456)', 'Decimal128(456.789)', 'Decimal128(963.852)'], 'Decimal128', 'numeric'),
        Property('mapObjectId', ['ObjectId("61184062c1d8f096a3695046")', 'ObjectId("61184062c1d8f096a3695045")', 'ObjectId("61184062c1d8f096a3695044")'], 'ObjectId', 'objectId'),
        Property('mapUuid', ['UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!', 'UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!', 'UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d08e")!'], 'UUID', 'uuid'),
        Property('mapAny', [['.objectId', 'ObjectId("61184062c1d8f096a3695046")'], ['.string', '"Hello"'], ['.int', 123]], 'AnyRealmValue', 'any'),
    ]

    optMapProperties = [
        Property('mapOptBool', ['true', 'true', 'false'], 'Bool?', 'bool'),
        Property('mapOptInt', [1, 2, 3], 'Int?', 'numeric'),
        Property('mapOptInt8', ['Int8(8)', 'Int8(9)', 'Int8(10)'], 'Int8?', 'numeric'),
        Property('mapOptInt16', ['Int16(16)', 'Int16(17)', 'Int16(18)'], 'Int16?', 'numeric'),
        Property('mapOptInt32', ['Int32(32)', 'Int32(33)', 'Int32(34)'], 'Int32?', 'numeric'),
        Property('mapOptInt64', ['Int64(64)', 'Int64(65)', 'Int64(66)'], 'Int64?', 'numeric'),
        Property('mapOptFloat', ['Float(5.55444333)', 'Float(6.55444333)', 'Float(7.55444333)'], 'Float?', 'numeric'),
        Property('mapOptDouble', [123.456, 234.456, 345.567], 'Double?', 'numeric'),
        Property('mapOptString', ['"Foo"', '"Bar"', '"Baz"'], 'String?', 'string'),
        Property('mapOptBinary', ['Data(count: 64)', 'Data(count: 128)', 'Data(count: 256)'], 'Data?', 'binary'),
        Property('mapOptDate', ['Date(timeIntervalSince1970: 1000000)', 'Date(timeIntervalSince1970: 2000000)', 'Date(timeIntervalSince1970: 3000000)'], 'Date?', 'numeric'),
        Property('mapOptDecimal', ['Decimal128(123.456)', 'Decimal128(456.789)', 'Decimal128(963.852)'], 'Decimal128?', 'numeric'),
        Property('mapOptUuid', ['UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!', 'UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!', 'UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d08e")!'], 'UUID?', 'uuid'),
        Property('mapOptObjectId', ['ObjectId("61184062c1d8f096a3695046")', 'ObjectId("61184062c1d8f096a3695045")', 'ObjectId("61184062c1d8f096a3695044")'], 'ObjectId?', 'objectId'),
    ]

    anyRealmValues = [
        ('.none', 'NSNull()', 'null'),
        ('.int(123)', '123', 'numeric'),
        ('.bool(true)', 'true', 'bool'),
        ('.float(123.456)', 'Float(123.456)', 'numeric'),
        ('.double(123.456)', '123.456', 'numeric'),
        ('.string("FooBar")', '"FooBar"', 'string'),
        ('.data(Data(count: 64))', 'Data(count: 64)', 'binary'),
        ('.date(Date(timeIntervalSince1970: 1000000))', 'Date(timeIntervalSince1970: 1000000)', 'numeric'),
        ('.object(circleObject)', 'circleObject', 'object'),
        ('.objectId(ObjectId("61184062c1d8f096a3695046"))', 'ObjectId("61184062c1d8f096a3695046")', 'objectId'),
        ('.decimal128(123.456)', 'Decimal128(123.456)', 'numeric'),
        ('.uuid(UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!)', 'UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!', 'uuid'),
    ]
}%
/// This file is generated from a template. Do not edit directly.
class QueryTests: TestCase {

    private func objects() -> Results<ModernAllTypesObject> {
        realmWithTestPath().objects(ModernAllTypesObject.self)
    }

    private func collectionObject() -> ModernCollectionObject {
        let realm = realmWithTestPath()
        if let object = realm.objects(ModernCollectionObject.self).first {
            return object
        } else {
            let object = ModernCollectionObject()
            try! realm.write {
                realm.add(object)
            }
            return object
        }
    }

    private func setAnyRealmValueCol(with value: AnyRealmValue, object: ModernAllTypesObject) {
        let realm = realmWithTestPath()
        try! realm.write {
            object.anyCol = value
        }
    }

    private var circleObject: ModernCircleObject {
        let realm = realmWithTestPath()
        if let object = realm.objects(ModernCircleObject.self).first {
            return object
        } else {
            let object = ModernCircleObject()
            try! realm.write {
                realm.add(object)
            }
            return object
        }
    }

    override func setUp() {
        let realm = realmWithTestPath()
        try! realm.write {
            let object = ModernAllTypesObject()

            % for property in properties + optProperties:
            object.${property.colName} = ${property.value(1)}
            % end

            % for property in listProperties + optListProperties:
            object.${property.colName}.append(objectsIn: [${property.value(0)}, ${property.value(1)}])
            % end

            % for property in setProperties + optSetProperties:
            object.${property.colName}.insert(objectsIn: [${property.value(0)}, ${property.value(1)}])
            % end

            % for property in mapProperties + optMapProperties:
            object.${property.colName}["foo"] = ${property.value(0)}
            object.${property.colName}["bar"] = ${property.value(1)}
            % end

            realm.add(object)
        }
    }

    private func assertQuery(predicate: String,
                             values: [AnyHashable],
                             expectedCount: Int,
                             _ query: ((Query<ModernAllTypesObject>) -> Query<ModernAllTypesObject>)) {
        let results = objects().query(query)
        XCTAssertEqual(results.count, expectedCount)

        let constructedPredicate = query(Query<ModernAllTypesObject>())._constructPredicate()
        XCTAssertEqual(constructedPredicate.0,
                       predicate)

        for (e1, e2) in zip(constructedPredicate.1, values) {
            if let e1 = e1 as? Object, let e2 = e2 as? Object {
                assertEqual(e1, e2)
            } else {
                XCTAssertEqual(e1 as! AnyHashable, e2)
            }
        }
    }

    private func assertCollectionObjectQuery(predicate: String,
                                             values: [AnyHashable],
                                             expectedCount: Int,
                                             _ query: ((Query<ModernCollectionObject>) -> Query<ModernCollectionObject>)) {
        let results = realmWithTestPath().objects(ModernCollectionObject.self).query(query)
        XCTAssertEqual(results.count, expectedCount)

        let constructedPredicate = query(Query<ModernCollectionObject>())._constructPredicate()
        XCTAssertEqual(constructedPredicate.0,
                       predicate)

        for (e1, e2) in zip(constructedPredicate.1, values) {
            if let e1 = e1 as? Object, let e2 = e2 as? Object {
                assertEqual(e1, e2)
            } else {
                XCTAssertEqual(e1 as! AnyHashable, e2)
            }
        }
    }

    // MARK: - Basic Comparison

    func testEquals() {
        % for property in properties:

        // ${property.colName}
        % if property.enumName != None:
        assertQuery(predicate: "${property.colName} == %@", values: [${property.enumName}], expectedCount: 1) {
            $0.${property.colName} == ${property.value(1)}
        }
        % else:
        assertQuery(predicate: "${property.colName} == %@", values: [${property.foundationValue(1)}], expectedCount: 1) {
            $0.${property.colName} == ${property.value(1)}
        }
        % end
        % end
    }


    func testEqualsOptional() {
        % for property in optProperties:
        // ${property.colName}

        % if property.enumName != None:
        assertQuery(predicate: "${property.colName} == %@", values: [${property.enumName}], expectedCount: 1) {
            $0.${property.colName} == ${property.value(1)}
        }
        % else:
        assertQuery(predicate: "${property.colName} == %@", values: [${property.foundationValue(1)}], expectedCount: 1) {
            $0.${property.colName} == ${property.value(1)}
        }
        % end
        % end

        // Test for `nil`
        % for property in optProperties:

        // ${property.colName}
        assertQuery(predicate: "${property.colName} == %@", values: [NSNull()], expectedCount: 0) {
            $0.${property.colName} == nil
        }
        % end
    }

    func testEqualAnyRealmValue() {
        % for value in anyRealmValues:

        setAnyRealmValueCol(with: AnyRealmValue${value[0]}, object: objects()[0])
        assertQuery(predicate: "anyCol == %@", values: [${value[1]}], expectedCount: 1) {
            $0.anyCol == ${value[0]}
        }
        % end
    }

    func testEqualObject() {
        let nestedObject = ModernAllTypesObject()
        let object = objects().first!
        let realm = realmWithTestPath()
        try! realm.write {
            object.objectCol = nestedObject
        }
        assertQuery(predicate: "objectCol == %@", values: [nestedObject], expectedCount: 1) {
            $0.objectCol == nestedObject
        }
    }

    func testEqualEmbeddedObject() {
        let object = ModernEmbeddedParentObject()
        let nestedObject = ModernEmbeddedTreeObject1()
        nestedObject.value = 123
        object.object = nestedObject
        let realm = realmWithTestPath()
        try! realm.write {
            realm.add(object)
        }

        let result1 = realm.objects(ModernEmbeddedParentObject.self).query {
            $0.object == nestedObject
        }
        XCTAssertEqual(result1.count, 1)

        let nestedObject2 = ModernEmbeddedTreeObject1()
        nestedObject2.value = 123
        let result2 = realm.objects(ModernEmbeddedParentObject.self).query {
            $0.object == nestedObject2
        }
        XCTAssertEqual(result2.count, 0)
    }

    func testNotEquals() {
        % for property in properties:
        // ${property.colName}

        % if property.enumName != None:
        assertQuery(predicate: "${property.colName} != %@", values: [${property.enumName}], expectedCount: 0) {
            $0.${property.colName} != ${property.values[1]}
        }
        % else:
        assertQuery(predicate: "${property.colName} != %@", values: [${property.foundationValue(1)}], expectedCount: 0) {
            $0.${property.colName} != ${property.value(1)}
        }
        % end
        % end
    }

    func testNotEqualsOptional() {
        % for property in optProperties:
        // ${property.colName}

        % if property.enumName != None:
        assertQuery(predicate: "${property.colName} != %@", values: [${property.enumName}], expectedCount: 0) {
            $0.${property.colName} != ${property.value(1)}
        }
        % else:
        assertQuery(predicate: "${property.colName} != %@", values: [${property.foundationValue(1)}], expectedCount: 0) {
            $0.${property.colName} != ${property.value(1)}
        }
        % end
        % end

        // Test for `nil`
        % for property in optProperties:

        // ${property.colName}
        assertQuery(predicate: "${property.colName} != %@", values: [NSNull()], expectedCount: 1) {
            $0.${property.colName} != nil
        }
        % end
    }

    func testNotEqualAnyRealmValue() {
        % for value in anyRealmValues:
        setAnyRealmValueCol(with: AnyRealmValue${value[0]}, object: objects()[0])
        assertQuery(predicate: "anyCol != %@", values: [${value[1]}], expectedCount: 0) {
            $0.anyCol != ${value[0]}
        }
        % end
    }

    func testNotEqualObject() {
        let nestedObject = ModernAllTypesObject()
        let object = objects().first!
        let realm = realmWithTestPath()
        try! realm.write {
            object.objectCol = nestedObject
        }
        // Count will be one because nestedObject.objectCol will be nil
        assertQuery(predicate: "objectCol != %@", values: [nestedObject], expectedCount: 1) {
            $0.objectCol != nestedObject
        }
    }

    func testNotEqualEmbeddedObject() {
        let object = ModernEmbeddedParentObject()
        let nestedObject = ModernEmbeddedTreeObject1()
        nestedObject.value = 123
        object.object = nestedObject
        let realm = realmWithTestPath()
        try! realm.write {
            realm.add(object)
        }

        let result1 = realm.objects(ModernEmbeddedParentObject.self).query {
            $0.object != nestedObject
        }
        XCTAssertEqual(result1.count, 0)

        let nestedObject2 = ModernEmbeddedTreeObject1()
        nestedObject2.value = 123
        let result2 = realm.objects(ModernEmbeddedParentObject.self).query {
            $0.object != nestedObject2
        }
        XCTAssertEqual(result2.count, 1)
    }

    func testGreaterThan() {
        % for property in properties:
        % if property.enumName != None and property.category == 'numeric':
        // ${property.colName}
        assertQuery(predicate: "${property.colName} > %@", values: [${property.enumName}], expectedCount: 0) {
            $0.${property.colName} > ${property.value(1)}
        }
        assertQuery(predicate: "${property.colName} >= %@", values: [${property.enumName}], expectedCount: 1) {
            $0.${property.colName} >= ${property.value(1)}
        }
        % elif property.category == 'numeric':
        // ${property.colName}
        assertQuery(predicate: "${property.colName} > %@", values: [${property.foundationValue(1)}], expectedCount: 0) {
            $0.${property.colName} > ${property.value(1)}
        }
        assertQuery(predicate: "${property.colName} >= %@", values: [${property.foundationValue(1)}], expectedCount: 1) {
            $0.${property.colName} >= ${property.value(1)}
        }
        % end
        % end
    }

    func testGreaterThanOptional() {
        % for property in optProperties:
        % if property.enumName != None and property.category == 'numeric':
        // ${property.colName}
        assertQuery(predicate: "${property.colName} > %@", values: [${property.enumName}], expectedCount: 0) {
            $0.${property.colName} > ${property.values[1]}
        }
        assertQuery(predicate: "${property.colName} >= %@", values: [${property.enumName}], expectedCount: 1) {
            $0.${property.colName} >= ${property.values[1]}
        }
        % elif property.category == 'numeric':
        // ${property.colName}
        assertQuery(predicate: "${property.colName} > %@", values: [${property.foundationValue(1)}], expectedCount: 0) {
            $0.${property.colName} > ${property.value(1)}
        }
        assertQuery(predicate: "${property.colName} >= %@", values: [${property.foundationValue(1)}], expectedCount: 1) {
            $0.${property.colName} >= ${property.value(1)}
        }
        % end
        % end

        // Test for `nil`
        % for property in optProperties:
        % if property.enumName != None and property.category == 'numeric':
        // ${property.colName}
        assertQuery(predicate: "${property.colName} > %@", values: [NSNull()], expectedCount: 0) {
            $0.${property.colName} > nil
        }
        assertQuery(predicate: "${property.colName} >= %@", values: [NSNull()], expectedCount: 0) {
            $0.${property.colName} >= nil
        }
        % elif property.category == 'numeric':
        // ${property.colName}
        assertQuery(predicate: "${property.colName} > %@", values: [NSNull()], expectedCount: 0) {
            $0.${property.colName} > nil
        }
        assertQuery(predicate: "${property.colName} >= %@", values: [NSNull()], expectedCount: 0) {
            $0.${property.colName} >= nil
        }
        % end
        % end
    }

    func testGreaterThanAnyRealmValue() {
        % for value in anyRealmValues:
        % if value[2] == 'numeric':
        setAnyRealmValueCol(with: AnyRealmValue${value[0]}, object: objects()[0])
        assertQuery(predicate: "anyCol > %@", values: [${value[1]}], expectedCount: 0) {
            $0.anyCol > ${value[0]}
        }
        assertQuery(predicate: "anyCol >= %@", values: [${value[1]}], expectedCount: 1) {
            $0.anyCol >= ${value[0]}
        }
        % end
        % end
    }

    func testLessThan() {
        % for property in properties:
        % if property.enumName != None and property.category == 'numeric':
        // ${property.colName}
        assertQuery(predicate: "${property.colName} < %@", values: [${property.enumName}], expectedCount: 0) {
            $0.${property.colName} < ${property.value(1)}
        }
        assertQuery(predicate: "${property.colName} <= %@", values: [${property.enumName}], expectedCount: 1) {
            $0.${property.colName} <= ${property.value(1)}
        }
        % elif property.category == 'numeric':
        // ${property.colName}
        assertQuery(predicate: "${property.colName} < %@", values: [${property.foundationValue(1)}], expectedCount: 0) {
            $0.${property.colName} < ${property.value(1)}
        }
        assertQuery(predicate: "${property.colName} <= %@", values: [${property.foundationValue(1)}], expectedCount: 1) {
            $0.${property.colName} <= ${property.value(1)}
        }
        % end
        % end
    }

    func testLessThanOptional() {
        % for property in optProperties:
        % if property.enumName != None and property.category == 'numeric':
        // ${property.colName}
        assertQuery(predicate: "${property.colName} < %@", values: [${property.enumName}], expectedCount: 0) {
            $0.${property.colName} < ${property.values[1]}
        }
        assertQuery(predicate: "${property.colName} <= %@", values: [${property.enumName}], expectedCount: 1) {
            $0.${property.colName} <= ${property.values[1]}
        }
        % elif property.category == 'numeric':
        // ${property.colName}
        assertQuery(predicate: "${property.colName} < %@", values: [${property.foundationValue(1)}], expectedCount: 0) {
            $0.${property.colName} < ${property.value(1)}
        }
        assertQuery(predicate: "${property.colName} <= %@", values: [${property.foundationValue(1)}], expectedCount: 1) {
            $0.${property.colName} <= ${property.value(1)}
        }
        % end
        % end

        // Test for `nil`
        % for property in optProperties:
        % if property.enumName != None and property.category == 'numeric':
        // ${property.colName}
        assertQuery(predicate: "${property.colName} < %@", values: [NSNull()], expectedCount: 0) {
            $0.${property.colName} < nil
        }
        assertQuery(predicate: "${property.colName} <= %@", values: [NSNull()], expectedCount: 0) {
            $0.${property.colName} <= nil
        }
        % elif property.category == 'numeric':
        // ${property.colName}
        assertQuery(predicate: "${property.colName} < %@", values: [NSNull()], expectedCount: 0) {
            $0.${property.colName} < nil
        }
        assertQuery(predicate: "${property.colName} <= %@", values: [NSNull()], expectedCount: 0) {
            $0.${property.colName} <= nil
        }
        % end
        % end
    }

    func testLessThanAnyRealmValue() {
        % for value in anyRealmValues:
        % if value[2] == 'numeric':
        setAnyRealmValueCol(with: AnyRealmValue${value[0]}, object: objects()[0])
        assertQuery(predicate: "anyCol < %@", values: [${value[1]}], expectedCount: 0) {
            $0.anyCol < ${value[0]}
        }
        assertQuery(predicate: "anyCol <= %@", values: [${value[1]}], expectedCount: 1) {
            $0.anyCol <= ${value[0]}
        }
        % end
        % end
    }

    func testNumericContains() {
        % for property in properties + optProperties:
        % if property.enumName == None and property.category == 'numeric':
        assertQuery(predicate: "${property.colName} >= %@ && ${property.colName} < %@",
                    values: [${property.foundationValue(0)}, ${property.foundationValue(2)}], expectedCount: 1) {
            $0.${property.colName}.contains(${property.value(0)}..<${property.value(2)})
        }

        assertQuery(predicate: "${property.colName} >= %@ && ${property.colName} < %@",
                    values: [${property.foundationValue(0)}, ${property.foundationValue(1)}], expectedCount: 0) {
            $0.${property.colName}.contains(${property.value(0)}..<${property.value(1)})
        }

        assertQuery(predicate: "${property.colName} BETWEEN {%@, %@}",
                    values: [${property.foundationValue(0)}, ${property.foundationValue(2)}], expectedCount: 1) {
            $0.${property.colName}.contains(${property.value(0)}...${property.value(2)})
        }

        assertQuery(predicate: "${property.colName} BETWEEN {%@, %@}",
                    values: [${property.foundationValue(0)}, ${property.foundationValue(1)}], expectedCount: 1) {
            $0.${property.colName}.contains(${property.value(0)}...${property.value(1)})
        }

        % end
        % end
    }

    // MARK: - Search

    func testStringStartsWith() {
        % for property in properties + optProperties:
        % if property.enumName == None and property.category == 'string':
        assertQuery(predicate: "${property.colName} BEGINSWITH %@",
                    values: ["fo"], expectedCount: 0) {
            $0.${property.colName}.starts(with: "fo")
        }

        assertQuery(predicate: "${property.colName} BEGINSWITH %@",
                    values: ["fo"], expectedCount: 0) {
            $0.${property.colName}.starts(with: "fo", options: [])
        }

        assertQuery(predicate: "${property.colName} BEGINSWITH[c] %@",
                    values: ["fo"], expectedCount: 1) {
            $0.${property.colName}.starts(with: "fo", options: [.caseInsensitive])
        }

        assertQuery(predicate: "${property.colName} BEGINSWITH[d] %@",
                    values: ["fo"], expectedCount: 0) {
            $0.${property.colName}.starts(with: "fo", options: [.diacriticInsensitive])
        }

        assertQuery(predicate: "${property.colName} BEGINSWITH[cd] %@",
                    values: ["fo"], expectedCount: 1) {
            $0.${property.colName}.starts(with: "fo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        % end
        % end
    }

    func testStringEndsWith() {
        % for property in properties + optProperties:
        % if property.enumName == None and property.category == 'string':
        assertQuery(predicate: "${property.colName} ENDSWITH %@",
                    values: ["oo"], expectedCount: 0) {
            $0.${property.colName}.ends(with: "oo")
        }

        assertQuery(predicate: "${property.colName} ENDSWITH %@",
                    values: ["oo"], expectedCount: 0) {
            $0.${property.colName}.ends(with: "oo", options: [])
        }

        assertQuery(predicate: "${property.colName} ENDSWITH[c] %@",
                    values: ["oo"], expectedCount: 0) {
            $0.${property.colName}.ends(with: "oo", options: [.caseInsensitive])
        }

        assertQuery(predicate: "${property.colName} ENDSWITH[d] %@",
                    values: ["oo"], expectedCount: 1) {
            $0.${property.colName}.ends(with: "oo", options: [.diacriticInsensitive])
        }

        assertQuery(predicate: "${property.colName} ENDSWITH[cd] %@",
                    values: ["oo"], expectedCount: 1) {
            $0.${property.colName}.ends(with: "oo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        % end
        % end
    }

    func testStringLike() {
        % for property in properties + optProperties:
        % if property.enumName == None and property.category == 'string':
        assertQuery(predicate: "${property.colName} LIKE %@",
                                values: ["Foó"], expectedCount: 1) {
            $0.${property.colName}.like("Foó")
        }

        assertQuery(predicate: "${property.colName} LIKE[c] %@",
                    values: ["Foó"], expectedCount: 1) {
            $0.${property.colName}.like("Foó", caseInsensitive: true)
        }

        assertQuery(predicate: "${property.colName} LIKE %@",
                    values: ["Foó"], expectedCount: 1) {
            $0.${property.colName}.like("Foó", caseInsensitive: false)
        }

        assertQuery(predicate: "${property.colName} LIKE %@",
                    values: ["f*"], expectedCount: 0) {
            $0.${property.colName}.like("f*")
        }

        assertQuery(predicate: "${property.colName} LIKE[c] %@",
                    values: ["f*"], expectedCount: 1) {
            $0.${property.colName}.like("f*", caseInsensitive: true)
        }

        assertQuery(predicate: "${property.colName} LIKE %@",
                    values: ["f*"], expectedCount: 0) {
            $0.${property.colName}.like("f*", caseInsensitive: false)
        }

        assertQuery(predicate: "${property.colName} LIKE %@",
                    values: ["*ó"], expectedCount: 1) {
            $0.${property.colName}.like("*ó")
        }

        assertQuery(predicate: "${property.colName} LIKE[c] %@",
                    values: ["*ó"], expectedCount: 1) {
            $0.${property.colName}.like("*ó", caseInsensitive: true)
        }

        assertQuery(predicate: "${property.colName} LIKE %@",
                    values: ["*ó"], expectedCount: 1) {
            $0.${property.colName}.like("*ó", caseInsensitive: false)
        }

        assertQuery(predicate: "${property.colName} LIKE %@",
                    values: ["f?ó"], expectedCount: 0) {
            $0.${property.colName}.like("f?ó")
        }

        assertQuery(predicate: "${property.colName} LIKE[c] %@",
                    values: ["f?ó"], expectedCount: 1) {
            $0.${property.colName}.like("f?ó", caseInsensitive: true)
        }

        assertQuery(predicate: "${property.colName} LIKE %@",
                    values: ["f?ó"], expectedCount: 0) {
            $0.${property.colName}.like("f?ó", caseInsensitive: false)
        }

        assertQuery(predicate: "${property.colName} LIKE %@",
                    values: ["f*ó"], expectedCount: 0) {
            $0.${property.colName}.like("f*ó")
        }

        assertQuery(predicate: "${property.colName} LIKE[c] %@",
                    values: ["f*ó"], expectedCount: 1) {
            $0.${property.colName}.like("f*ó", caseInsensitive: true)
        }

        assertQuery(predicate: "${property.colName} LIKE %@",
                    values: ["f*ó"], expectedCount: 0) {
            $0.${property.colName}.like("f*ó", caseInsensitive: false)
        }

        assertQuery(predicate: "${property.colName} LIKE %@",
                    values: ["f??ó"], expectedCount: 0) {
            $0.${property.colName}.like("f??ó")
        }

        assertQuery(predicate: "${property.colName} LIKE[c] %@",
                    values: ["f??ó"], expectedCount: 0) {
            $0.${property.colName}.like("f??ó", caseInsensitive: true)
        }

        assertQuery(predicate: "${property.colName} LIKE %@",
                    values: ["f??ó"], expectedCount: 0) {
            $0.${property.colName}.like("f??ó", caseInsensitive: false)
        }

        assertQuery(predicate: "${property.colName} LIKE %@",
                    values: ["*o*"], expectedCount: 1) {
            $0.${property.colName}.like("*o*")
        }

        assertQuery(predicate: "${property.colName} LIKE[c] %@",
                    values: ["*O*"], expectedCount: 1) {
            $0.${property.colName}.like("*O*", caseInsensitive: true)
        }

        assertQuery(predicate: "${property.colName} LIKE %@",
                    values: ["*O*"], expectedCount: 0) {
            $0.${property.colName}.like("*O*", caseInsensitive: false)
        }

        assertQuery(predicate: "${property.colName} LIKE %@",
                    values: ["?o?"], expectedCount: 1) {
            $0.${property.colName}.like("?o?")
        }

        assertQuery(predicate: "${property.colName} LIKE[c] %@",
                    values: ["?O?"], expectedCount: 1) {
            $0.${property.colName}.like("?O?", caseInsensitive: true)
        }

        assertQuery(predicate: "${property.colName} LIKE %@",
                    values: ["?O?"], expectedCount: 0) {
            $0.${property.colName}.like("?O?", caseInsensitive: false)
        }

        % end
        % end
    }

    func testStringContains() {
        % for property in properties + optProperties:
        % if property.enumName == None and property.category == 'string':
        assertQuery(predicate: "${property.colName} CONTAINS %@",
                    values: ["Foó"], expectedCount: 1) {
            $0.${property.colName}.contains("Foó")
        }

        assertQuery(predicate: "${property.colName} CONTAINS %@",
                    values: ["Foó"], expectedCount: 1) {
            $0.${property.colName}.contains("Foó", options: [])
        }

        assertQuery(predicate: "${property.colName} CONTAINS[c] %@",
                    values: ["Foó"], expectedCount: 1) {
            $0.${property.colName}.contains("Foó", options: [.caseInsensitive])
        }

        assertQuery(predicate: "${property.colName} CONTAINS[d] %@",
                    values: ["Foó"], expectedCount: 1) {
            $0.${property.colName}.contains("Foó", options: [.diacriticInsensitive])
        }

        assertQuery(predicate: "${property.colName} CONTAINS[cd] %@",
                    values: ["Foó"], expectedCount: 1) {
            $0.${property.colName}.contains("Foó", options: [.caseInsensitive, .diacriticInsensitive])
        }

        % end
        % end
    }

    func testStringNotContains() {
        % for property in properties + optProperties:
                    % if property.enumName == None and property.category == 'string':
        assertQuery(predicate: "NOT ${property.colName} CONTAINS %@",
                    values: ["Foó"], expectedCount: 0) {
            !$0.${property.colName}.contains("Foó")
        }

        assertQuery(predicate: "NOT ${property.colName} CONTAINS %@",
                    values: ["Foó"], expectedCount: 0) {
            !$0.${property.colName}.contains("Foó", options: [])
        }

        assertQuery(predicate: "NOT ${property.colName} CONTAINS[c] %@",
                    values: ["Foó"], expectedCount: 0) {
            !$0.${property.colName}.contains("Foó", options: [.caseInsensitive])
        }

        assertQuery(predicate: "NOT ${property.colName} CONTAINS[d] %@",
                    values: ["Foó"], expectedCount: 0) {
            !$0.${property.colName}.contains("Foó", options: [.diacriticInsensitive])
        }

        assertQuery(predicate: "NOT ${property.colName} CONTAINS[cd] %@",
                    values: ["Foó"], expectedCount: 0) {
            !$0.${property.colName}.contains("Foó", options: [.caseInsensitive, .diacriticInsensitive])
        }

        % end
        % end
    }

    func testStringEquals() {
        % for property in properties + optProperties:
        % if property.enumName == None and property.category == 'string':
        assertQuery(predicate: "${property.colName} == %@",
                    values: ["Foó"], expectedCount: 1) {
            $0.${property.colName}.equals("Foó")
        }

        assertQuery(predicate: "${property.colName} == %@",
                    values: ["Foó"], expectedCount: 1) {
            $0.${property.colName}.equals("Foó", options: [])
        }

        assertQuery(predicate: "${property.colName} ==[c] %@",
                    values: ["Foó"], expectedCount: 1) {
            $0.${property.colName}.equals("Foó", options: [.caseInsensitive])
        }

        assertQuery(predicate: "${property.colName} ==[d] %@",
                    values: ["Foó"], expectedCount: 1) {
            $0.${property.colName}.equals("Foó", options: [.diacriticInsensitive])
        }

        assertQuery(predicate: "${property.colName} ==[cd] %@",
                    values: ["Foó"], expectedCount: 1) {
            $0.${property.colName}.equals("Foó", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "NOT ${property.colName} == %@",
                    values: ["Foó"], expectedCount: 0) {
            !$0.${property.colName}.equals("Foó")
        }

        assertQuery(predicate: "NOT ${property.colName} == %@",
                    values: ["Foó"], expectedCount: 0) {
            !$0.${property.colName}.equals("Foó", options: [])
        }

        assertQuery(predicate: "NOT ${property.colName} ==[c] %@",
                    values: ["Foó"], expectedCount: 0) {
            !$0.${property.colName}.equals("Foó", options: [.caseInsensitive])
        }

        assertQuery(predicate: "NOT ${property.colName} ==[d] %@",
                    values: ["Foó"], expectedCount: 0) {
            !$0.${property.colName}.equals("Foó", options: [.diacriticInsensitive])
        }

        assertQuery(predicate: "NOT ${property.colName} ==[cd] %@",
                    values: ["Foó"], expectedCount: 0) {
            !$0.${property.colName}.equals("Foó", options: [.caseInsensitive, .diacriticInsensitive])
        }

        % end
        % end
    }

    func testStringNotEquals() {
        % for property in properties + optProperties:
        % if property.enumName == None and property.category == 'string':
        assertQuery(predicate: "${property.colName} != %@",
                    values: ["Foó"], expectedCount: 0) {
            $0.${property.colName}.notEquals("Foó")
        }

        assertQuery(predicate: "${property.colName} != %@",
                    values: ["Foó"], expectedCount: 0) {
            $0.${property.colName}.notEquals("Foó", options: [])
        }

        assertQuery(predicate: "${property.colName} !=[c] %@",
                    values: ["Foó"], expectedCount: 0) {
            $0.${property.colName}.notEquals("Foó", options: [.caseInsensitive])
        }

        assertQuery(predicate: "${property.colName} !=[d] %@",
                    values: ["Foó"], expectedCount: 0) {
            $0.${property.colName}.notEquals("Foó", options: [.diacriticInsensitive])
        }

        assertQuery(predicate: "${property.colName} !=[cd] %@",
                    values: ["Foó"], expectedCount: 0) {
            $0.${property.colName}.notEquals("Foó", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "NOT ${property.colName} != %@",
                    values: ["Foó"], expectedCount: 1) {
            !$0.${property.colName}.notEquals("Foó")
        }

        assertQuery(predicate: "NOT ${property.colName} != %@",
                    values: ["Foó"], expectedCount: 1) {
            !$0.${property.colName}.notEquals("Foó", options: [])
        }

        assertQuery(predicate: "NOT ${property.colName} !=[c] %@",
                    values: ["Foó"], expectedCount: 1) {
            !$0.${property.colName}.notEquals("Foó", options: [.caseInsensitive])
        }

        assertQuery(predicate: "NOT ${property.colName} !=[d] %@",
                    values: ["Foó"], expectedCount: 1) {
            !$0.${property.colName}.notEquals("Foó", options: [.diacriticInsensitive])
        }

        assertQuery(predicate: "NOT ${property.colName} !=[cd] %@",
                    values: ["Foó"], expectedCount: 1) {
            !$0.${property.colName}.notEquals("Foó", options: [.caseInsensitive, .diacriticInsensitive])
        }

        % end
        % end
    }

    func testNotPrefixUnsupported() {
        let result1 = objects()

        % for property in properties + optProperties:
        % if property.enumName == None and property.category == 'string':
        let ${property.colName}QueryStartsWith: ((Query<ModernAllTypesObject>) -> Query<ModernAllTypesObject>) = {
            !$0.${property.colName}.starts(with: "fo", options: [.caseInsensitive, .diacriticInsensitive])
        }
        assertThrows(result1.query(${property.colName}QueryStartsWith),
                     reason: "`!` prefix is only allowed for `Comparison.contains` and `Search.contains` queries")

        let ${property.colName}QueryEndWith: ((Query<ModernAllTypesObject>) -> Query<ModernAllTypesObject>) = {
            !$0.${property.colName}.ends(with: "oo", options: [.caseInsensitive, .diacriticInsensitive])
        }
        assertThrows(result1.query(${property.colName}QueryEndWith),
                     reason: "`!` prefix is only allowed for `Comparison.contains` and `Search.contains` queries")

        let ${property.colName}QueryLike: ((Query<ModernAllTypesObject>) -> Query<ModernAllTypesObject>) = {
            !$0.${property.colName}.like("f*", caseInsensitive: true)
        }
        assertThrows(result1.query(${property.colName}QueryLike),
                    reason: "`!` prefix is only allowed for `Comparison.contains` and `Search.contains` queries")

        % end
        % end
    }

    func testBinarySearchQueries() {
        % for property in properties + optProperties:
        % if property.enumName == None and property.category == 'binary':
        assertQuery(predicate: "${property.colName} BEGINSWITH %@",
                    values: [Data(count: 28)], expectedCount: 1) {
            $0.${property.colName}.starts(with: Data(count: 28))
        }

        assertQuery(predicate: "${property.colName} ENDSWITH %@",
                    values: [Data(count: 28)], expectedCount: 1) {
            $0.${property.colName}.ends(with: Data(count: 28))
        }

        assertQuery(predicate: "${property.colName} CONTAINS %@",
                    values: [Data(count: 28)], expectedCount: 1) {
            $0.${property.colName}.contains(Data(count: 28))
        }

        assertQuery(predicate: "NOT ${property.colName} CONTAINS %@",
                    values: [Data(count: 28)], expectedCount: 0) {
            !$0.${property.colName}.contains(Data(count: 28))
        }

        assertQuery(predicate: "${property.colName} == %@",
                    values: [Data(count: 28)], expectedCount: 0) {
            $0.${property.colName}.equals(Data(count: 28))
        }

        assertQuery(predicate: "NOT ${property.colName} == %@",
                    values: [Data(count: 28)], expectedCount: 1) {
            !$0.${property.colName}.equals(Data(count: 28))
        }

        assertQuery(predicate: "${property.colName} != %@",
                    values: [Data(count: 28)], expectedCount: 1) {
            $0.${property.colName}.notEquals(Data(count: 28))
        }

        assertQuery(predicate: "NOT ${property.colName} != %@",
                    values: [Data(count: 28)], expectedCount: 0) {
            !$0.${property.colName}.notEquals(Data(count: 28))
        }

        assertQuery(predicate: "${property.colName} BEGINSWITH %@",
                    values: [Data(repeating: 1, count: 28)], expectedCount: 0) {
            $0.${property.colName}.starts(with: Data(repeating: 1, count: 28))
        }

        assertQuery(predicate: "${property.colName} ENDSWITH %@",
                    values: [Data(repeating: 1, count: 28)], expectedCount: 0) {
            $0.${property.colName}.ends(with: Data(repeating: 1, count: 28))
        }

        assertQuery(predicate: "${property.colName} CONTAINS %@",
                    values: [Data(repeating: 1, count: 28)], expectedCount: 0) {
            $0.${property.colName}.contains(Data(repeating: 1, count: 28))
        }

        assertQuery(predicate: "NOT ${property.colName} CONTAINS %@",
                    values: [Data(repeating: 1, count: 28)], expectedCount: 1) {
            !$0.${property.colName}.contains(Data(repeating: 1, count: 28))
        }

        assertQuery(predicate: "${property.colName} CONTAINS %@",
                    values: [Data(repeating: 1, count: 28)], expectedCount: 0) {
            $0.${property.colName}.contains(Data(repeating: 1, count: 28))
        }

        assertQuery(predicate: "NOT ${property.colName} CONTAINS %@",
                    values: [Data(repeating: 1, count: 28)], expectedCount: 1) {
            !$0.${property.colName}.contains(Data(repeating: 1, count: 28))
        }

        assertQuery(predicate: "${property.colName} == %@",
                    values: [Data(repeating: 1, count: 28)], expectedCount: 0) {
            $0.${property.colName}.equals(Data(repeating: 1, count: 28))
        }

        assertQuery(predicate: "NOT ${property.colName} == %@",
                    values: [Data(repeating: 1, count: 28)], expectedCount: 1) {
            !$0.${property.colName}.equals(Data(repeating: 1, count: 28))
        }

        assertQuery(predicate: "${property.colName} != %@",
                    values: [Data(repeating: 1, count: 28)], expectedCount: 1) {
            $0.${property.colName}.notEquals(Data(repeating: 1, count: 28))
        }

        assertQuery(predicate: "NOT ${property.colName} != %@",
                    values: [Data(repeating: 1, count: 28)], expectedCount: 0) {
            !$0.${property.colName}.notEquals(Data(repeating: 1, count: 28))
        }

        % end
        % end
    }

    // MARK: - Array/Set

    func testListContainsElement() {
        % for property in listProperties + optListProperties:
        assertQuery(predicate: "%@ IN ${property.colName}", values: [${property.foundationValue(0)}], expectedCount: 1) {
            $0.${property.colName}.contains(${property.value(0)})
        }
        assertQuery(predicate: "%@ IN ${property.colName}", values: [${property.foundationValue(2)}], expectedCount: 0) {
            $0.${property.colName}.contains(${property.value(2)})
        }

        % end
        % for property in optListProperties:
        assertQuery(predicate: "%@ IN ${property.colName}", values: [NSNull()], expectedCount: 0) {
            $0.${property.colName}.contains(nil)
        }

        % end
    }

    func testListNotContainsElement() {
        % for property in listProperties + optListProperties:
        assertQuery(predicate: "NOT %@ IN ${property.colName}", values: [${property.foundationValue(0)}], expectedCount: 0) {
            !$0.${property.colName}.contains(${property.value(0)})
        }
        assertQuery(predicate: "NOT %@ IN ${property.colName}", values: [${property.foundationValue(2)}], expectedCount: 1) {
            !$0.${property.colName}.contains(${property.value(2)})
        }

        % end
        % for property in optListProperties:
        assertQuery(predicate: "NOT %@ IN ${property.colName}", values: [NSNull()], expectedCount: 1) {
            !$0.${property.colName}.contains(nil)
        }

        % end
    }

    func testListContainsObject() {
        let obj = objects().first!
        let colObj = collectionObject()
        let realm = realmWithTestPath()
        let result1 = realm.objects(ModernCollectionObject.self).query {
            $0.list.contains(obj)
        }
        XCTAssertEqual(result1.count, 0)
        try! realm.write {
            colObj.list.append(obj)
        }
        let result2 = realm.objects(ModernCollectionObject.self).query {
            $0.list.contains(obj)
        }
        XCTAssertEqual(result2.count, 1)
    }

    func testListContainsRange() {
        % for property in listProperties + optListProperties:
        % if property.category == 'numeric':
        assertQuery(predicate: "${property.colName}.@min >= %@ && ${property.colName}.@max <= %@",
                    values: [${property.foundationValue(0)}, ${property.foundationValue(1)}], expectedCount: 1) {
            $0.${property.colName}.contains(${property.value(0)}...${property.value(1)})
        }
        assertQuery(predicate: "${property.colName}.@min >= %@ && ${property.colName}.@max < %@",
                    values: [${property.foundationValue(0)}, ${property.foundationValue(1)}], expectedCount: 0) {
            $0.${property.colName}.contains(${property.value(0)}..<${property.value(1)})
        }

        % end
        % end
    }

    func testSetContainsElement() {
        % for property in setProperties:
        assertQuery(predicate: "%@ IN ${property.colName}", values: [${property.foundationValue(0)}], expectedCount: 1) {
            $0.${property.colName}.contains(${property.value(0)})
        }
        assertQuery(predicate: "%@ IN ${property.colName}", values: [${property.foundationValue(2)}], expectedCount: 0) {
            $0.${property.colName}.contains(${property.value(2)})
        }

        % end
        % for property in optSetProperties:
        assertQuery(predicate: "%@ IN ${property.colName}", values: [${property.foundationValue(0)}], expectedCount: 1) {
            $0.${property.colName}.contains(${property.value(0)})
        }
        assertQuery(predicate: "%@ IN ${property.colName}", values: [${property.foundationValue(2)}], expectedCount: 0) {
            $0.${property.colName}.contains(${property.value(2)})
        }
        assertQuery(predicate: "%@ IN ${property.colName}", values: [NSNull()], expectedCount: 0) {
            $0.${property.colName}.contains(nil)
        }

        % end
    }

    func testSetContainsRange() {
        % for property in setProperties:
        % if property.category == 'numeric':
        assertQuery(predicate: "${property.colName}.@min >= %@ && ${property.colName}.@max <= %@",
                    values: [${property.foundationValue(0)}, ${property.foundationValue(1)}], expectedCount: 1) {
            $0.${property.colName}.contains(${property.value(0)}...${property.value(1)})
        }
        assertQuery(predicate: "${property.colName}.@min >= %@ && ${property.colName}.@max < %@",
                    values: [${property.foundationValue(0)}, ${property.foundationValue(1)}], expectedCount: 0) {
            $0.${property.colName}.contains(${property.value(0)}..<${property.value(1)})
        }

        % end
        % end
        % for property in optSetProperties:
        % if property.category == 'numeric':
        assertQuery(predicate: "${property.colName}.@min >= %@ && ${property.colName}.@max <= %@",
                    values: [${property.foundationValue(0)}, ${property.foundationValue(1)}], expectedCount: 1) {
            $0.${property.colName}.contains(${property.value(0)}...${property.value(1)})
        }
        assertQuery(predicate: "${property.colName}.@min >= %@ && ${property.colName}.@max < %@",
                    values: [${property.foundationValue(0)}, ${property.foundationValue(1)}], expectedCount: 0) {
            $0.${property.colName}.contains(${property.value(0)}..<${property.value(1)})
        }

        % end
        % end
    }

    func testSetContainsObject() {
        let obj = objects().first!
        let colObj = collectionObject()
        let realm = realmWithTestPath()
        let result1 = realm.objects(ModernCollectionObject.self).query {
            $0.set.contains(obj)
        }
        XCTAssertEqual(result1.count, 0)
        try! realm.write {
            colObj.set.insert(obj)
        }
        let result2 = realm.objects(ModernCollectionObject.self).query {
            $0.set.contains(obj)
        }
        XCTAssertEqual(result2.count, 1)
    }

    // MARK: - Map

    func testMapContainsElement() {
        % for property in mapProperties:
        assertQuery(predicate: "%@ IN ${property.colName}", values: [${property.foundationValue(0)}], expectedCount: 1) {
            $0.${property.colName}.contains(${property.value(0)})
        }
        assertQuery(predicate: "%@ IN ${property.colName}", values: [${property.foundationValue(2)}], expectedCount: 0) {
            $0.${property.colName}.contains(${property.value(2)})
        }

        % end
        % for property in optMapProperties:
        assertQuery(predicate: "%@ IN ${property.colName}", values: [${property.foundationValue(0)}], expectedCount: 1) {
            $0.${property.colName}.contains(${property.value(0)})
        }
        assertQuery(predicate: "%@ IN ${property.colName}", values: [${property.foundationValue(2)}], expectedCount: 0) {
            $0.${property.colName}.contains(${property.value(2)})
        }
        assertQuery(predicate: "%@ IN ${property.colName}", values: [NSNull()], expectedCount: 0) {
            $0.${property.colName}.contains(nil)
        }

        % end
    }

    func testMapAllKeys() {
        % for property in mapProperties + optMapProperties:
        assertQuery(predicate: "${property.colName}.@allKeys == %@", values: ["foo"], expectedCount: 1) {
            $0.${property.colName}.keys == "foo"
        }

        assertQuery(predicate: "${property.colName}.@allKeys != %@", values: ["foo"], expectedCount: 1) {
            $0.${property.colName}.keys != "foo"
        }

        assertQuery(predicate: "${property.colName}.@allKeys CONTAINS[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.${property.colName}.keys.contains("foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "${property.colName}.@allKeys CONTAINS %@", values: ["foo"], expectedCount: 1) {
            $0.${property.colName}.keys.contains("foo")
        }

        assertQuery(predicate: "${property.colName}.@allKeys BEGINSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.${property.colName}.keys.starts(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "${property.colName}.@allKeys BEGINSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.${property.colName}.keys.starts(with: "foo")
        }

        assertQuery(predicate: "${property.colName}.@allKeys ENDSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.${property.colName}.keys.ends(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "${property.colName}.@allKeys ENDSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.${property.colName}.keys.ends(with: "foo")
        }

        assertQuery(predicate: "${property.colName}.@allKeys LIKE[c] %@", values: ["foo"], expectedCount: 1) {
            $0.${property.colName}.keys.like("foo", caseInsensitive: true)
        }

        assertQuery(predicate: "${property.colName}.@allKeys LIKE %@", values: ["foo"], expectedCount: 1) {
            $0.${property.colName}.keys.like("foo")
        }

        % end
    }

    func testMapAllValues() {
        % for property in mapProperties + optMapProperties:
        assertQuery(predicate: "${property.colName}.@allValues == %@", values: [${property.foundationValue(0)}], expectedCount: 1) {
            $0.${property.colName}.values == ${property.value(0)}
        }

        % count = 0 if property.category == 'bool' else 1
        assertQuery(predicate: "${property.colName}.@allValues != %@", values: [${property.foundationValue(0)}], expectedCount: ${count}) {
            $0.${property.colName}.values != ${property.value(0)}
        }
        % if property.category == 'numeric':
        assertQuery(predicate: "${property.colName}.@allValues > %@", values: [${property.foundationValue(0)}], expectedCount: 1) {
            $0.${property.colName}.values > ${property.value(0)}
        }

        assertQuery(predicate: "${property.colName}.@allValues >= %@", values: [${property.foundationValue(0)}], expectedCount: 1) {
            $0.${property.colName}.values >= ${property.value(0)}
        }
        assertQuery(predicate: "${property.colName}.@allValues < %@", values: [${property.foundationValue(0)}], expectedCount: 0) {
            $0.${property.colName}.values < ${property.value(0)}
        }

        assertQuery(predicate: "${property.colName}.@allValues <= %@", values: [${property.foundationValue(0)}], expectedCount: 1) {
            $0.${property.colName}.values <= ${property.value(0)}
        }
        % end

        % if property.category == 'string':
        assertQuery(predicate: "${property.colName}.@allValues CONTAINS[cd] %@", values: [${property.foundationValue(0)}], expectedCount: 1) {
            $0.${property.colName}.values.contains(${property.value(0)}, options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "${property.colName}.@allValues CONTAINS %@", values: [${property.foundationValue(0)}], expectedCount: 1) {
            $0.${property.colName}.values.contains(${property.value(0)})
        }

        assertQuery(predicate: "${property.colName}.@allValues BEGINSWITH[cd] %@", values: [${property.foundationValue(0)}], expectedCount: 1) {
            $0.${property.colName}.values.starts(with: ${property.value(0)}, options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "${property.colName}.@allValues BEGINSWITH %@", values: [${property.foundationValue(0)}], expectedCount: 1) {
            $0.${property.colName}.values.starts(with: ${property.value(0)})
        }

        assertQuery(predicate: "${property.colName}.@allValues ENDSWITH[cd] %@", values: [${property.foundationValue(0)}], expectedCount: 1) {
            $0.${property.colName}.values.ends(with: ${property.value(0)}, options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "${property.colName}.@allValues ENDSWITH %@", values: [${property.foundationValue(0)}], expectedCount: 1) {
            $0.${property.colName}.values.ends(with: ${property.value(0)})
        }

        assertQuery(predicate: "${property.colName}.@allValues LIKE[c] %@", values: [${property.foundationValue(0)}], expectedCount: 1) {
            $0.${property.colName}.values.like(${property.value(0)}, caseInsensitive: true)
        }

        assertQuery(predicate: "${property.colName}.@allValues LIKE %@", values: [${property.foundationValue(0)}], expectedCount: 1) {
            $0.${property.colName}.values.like(${property.value(0)})
        }
        % end
        % end
    }

    func testMapContainsRange() {
        % for property in mapProperties + optMapProperties:
        % if property.category == 'numeric':
        assertQuery(predicate: "${property.colName}.@min >= %@ && ${property.colName}.@max <= %@",
                    values: [${property.foundationValue(0)}, ${property.foundationValue(1)}], expectedCount: 1) {
            $0.${property.colName}.contains(${property.value(0)}...${property.value(1)})
        }
        assertQuery(predicate: "${property.colName}.@min >= %@ && ${property.colName}.@max < %@",
                    values: [${property.foundationValue(0)}, ${property.foundationValue(1)}], expectedCount: 0) {
            $0.${property.colName}.contains(${property.value(0)}..<${property.value(1)})
        }

        % end
        % end
    }

    func testMapContainsObject() {
        let obj = objects().first!
        let colObj = collectionObject()
        let realm = realmWithTestPath()
        let result1 = realm.objects(ModernCollectionObject.self).query {
            $0.map.contains(obj)
        }
        XCTAssertEqual(result1.count, 0)
        try! realm.write {
            colObj.map["foo"] = obj
        }
        let result2 = realm.objects(ModernCollectionObject.self).query {
            $0.map.contains(obj)
        }
        XCTAssertEqual(result2.count, 1)
    }

    func testMapAllKeysAllValuesSubscript() {
        % for property in mapProperties + optMapProperties:
        assertQuery(predicate: "${property.colName}.@allKeys == %@ && ${property.colName} == %@", values: ["foo", ${property.foundationValue(0)}], expectedCount: 1) {
            $0.${property.colName}["foo"] == ${property.value(0)}
        }

        % count = 0 if property.category == 'bool' else 1
        assertQuery(predicate: "${property.colName}.@allKeys == %@ && ${property.colName} != %@", values: ["foo", ${property.foundationValue(0)}], expectedCount: ${count}) {
            $0.${property.colName}["foo"] != ${property.value(0)}
        }
        % if property.category == 'numeric':
        assertQuery(predicate: "${property.colName}.@allKeys == %@ && ${property.colName} > %@", values: ["foo", ${property.foundationValue(0)}], expectedCount: 1) {
            $0.${property.colName}["foo"] > ${property.value(0)}
        }

        assertQuery(predicate: "${property.colName}.@allKeys == %@ && ${property.colName} >= %@", values: ["foo", ${property.foundationValue(0)}], expectedCount: 1) {
            $0.${property.colName}["foo"] >= ${property.value(0)}
        }
        assertQuery(predicate: "${property.colName}.@allKeys == %@ && ${property.colName} < %@", values: ["foo", ${property.foundationValue(0)}], expectedCount: 0) {
            $0.${property.colName}["foo"] < ${property.value(0)}
        }

        assertQuery(predicate: "${property.colName}.@allKeys == %@ && ${property.colName} <= %@", values: ["foo", ${property.foundationValue(0)}], expectedCount: 1) {
            $0.${property.colName}["foo"] <= ${property.value(0)}
        }
        % end

        % if property.category == 'string':
        assertQuery(predicate: "${property.colName}.@allKeys == %@ && ${property.colName} CONTAINS[cd] %@", values: ["foo", ${property.foundationValue(0)}], expectedCount: 1) {
            $0.${property.colName}["foo"].contains(${property.value(0)}, options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "${property.colName}.@allKeys == %@ && ${property.colName} CONTAINS %@", values: ["foo", ${property.foundationValue(0)}], expectedCount: 1) {
            $0.${property.colName}["foo"].contains(${property.value(0)})
        }

        assertQuery(predicate: "${property.colName}.@allKeys == %@ && ${property.colName} BEGINSWITH[cd] %@", values: ["foo", ${property.foundationValue(0)}], expectedCount: 1) {
            $0.${property.colName}["foo"].starts(with: ${property.value(0)}, options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "${property.colName}.@allKeys == %@ && ${property.colName} BEGINSWITH %@", values: ["foo", ${property.foundationValue(0)}], expectedCount: 1) {
            $0.${property.colName}["foo"].starts(with: ${property.value(0)})
        }

        assertQuery(predicate: "${property.colName}.@allKeys == %@ && ${property.colName} ENDSWITH[cd] %@", values: ["foo", ${property.foundationValue(0)}], expectedCount: 1) {
            $0.${property.colName}["foo"].ends(with: ${property.value(0)}, options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "${property.colName}.@allKeys == %@ && ${property.colName} ENDSWITH %@", values: ["foo", ${property.foundationValue(0)}], expectedCount: 1) {
            $0.${property.colName}["foo"].ends(with: ${property.value(0)})
        }

        assertQuery(predicate: "${property.colName}.@allKeys == %@ && ${property.colName} LIKE[c] %@", values: ["foo", ${property.foundationValue(0)}], expectedCount: 1) {
            $0.${property.colName}["foo"].like(${property.value(0)}, caseInsensitive: true)
        }

        assertQuery(predicate: "${property.colName}.@allKeys == %@ && ${property.colName} LIKE %@", values: ["foo", ${property.foundationValue(0)}], expectedCount: 1) {
            $0.${property.colName}["foo"].like(${property.value(0)})
        }
        % end
        % end
    }

    func testMapSubscriptObject() {
        let obj = objects().first!
        let colObj = collectionObject()
        let realm = realmWithTestPath()
        try! realm.write {
            colObj.map["foo"] = obj
        }
        % for property in properties + optProperties:
        assertCollectionObjectQuery(predicate: "map.@allKeys == %@ && map.${property.colName} == %@", values: ["foo", ${property.value(0)}], expectedCount: 1) {
            $0.map["foo"].${property.colName} == ${property.value(0)}
        }
        % end
    }

}
