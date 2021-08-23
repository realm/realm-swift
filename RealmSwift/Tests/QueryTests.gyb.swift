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
@testable import RealmSwift

%{
# How to use:
#
# $ wget https://github.com/apple/swift/raw/main/utils/gyb
# $ wget https://github.com/apple/swift/raw/main/utils/gyb.py
# $ chmod +x gyb
#
# ./YOUR_GYB_LOCATION/gyb --line-directive '' -o QueryTests2.swift QueryTests.gyb.swift
}%
%{
    properties = [
        ('boolCol', 'true', 'Bool', 'bool'),
        ('intCol', 5, 'Int', 'numeric'),
        ('int8Col', 8, 'Int8', 'numeric'),
        ('int16Col', 16, 'Int16', 'numeric'),
        ('int32Col', 32, 'Int32', 'numeric'),
        ('int64Col', 64, 'Int64', 'numeric'),
        ('floatCol', 'Float(5.55444333)', 'Float', 'numeric'),
        ('doubleCol', 5.55444333, 'Double', 'numeric'),
        ('stringCol', '"Foo"', 'String', 'string'),
        ('binaryCol', 'Data(count: 64)', 'Data', 'binary'),
        ('dateCol', 'Date(timeIntervalSince1970: 1000000)', 'Date', 'numeric'),
        ('decimalCol', 'Decimal128(123.456)', 'Decimal128', 'numeric'),
        ('objectIdCol', 'ObjectId("61184062c1d8f096a3695046")', 'ObjectId', 'objectId'),
        ('intEnumCol', '.value1', 'Int', 'numeric', 'ModernIntEnum.value1.rawValue'),
        ('stringEnumCol', '.value1', 'String', 'string', 'ModernStringEnum.value1.rawValue'),
        ('uuidCol', 'UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!', 'UUID', 'uuid')
    ]

    optProperties = [
        ('optBoolCol', 'true', 'Bool?', 'bool'),
        ('optIntCol', 5, 'Int?', 'numeric'),
        ('optInt8Col', 8, 'Int8?', 'numeric'),
        ('optInt16Col', 16, 'Int16?', 'numeric'),
        ('optInt32Col', 32, 'Int32?', 'numeric'),
        ('optInt64Col', 64, 'Int64?', 'numeric'),
        ('optFloatCol', 'Float(5.55444333)', 'Float?', 'numeric'),
        ('optDoubleCol', 5.55444333,'Double?', 'numeric'),
        ('optStringCol', '"Foo"', 'String?', 'string'),
        ('optBinaryCol', 'Data(count: 64)', 'Data?', 'binary'),
        ('optDateCol', 'Date(timeIntervalSince1970: 1000000)', 'Date?', 'numeric'),
        ('optDecimalCol', 'Decimal128(123.456)', 'Decimal128?', 'numeric'),
        ('optObjectIdCol', 'ObjectId("61184062c1d8f096a3695046")', 'ObjectId?', 'objectId'),
        ('optIntEnumCol', '.value1', 'Int?', 'numeric', 'ModernIntEnum.value1.rawValue'),
        ('optStringEnumCol', '.value1', 'String?', 'string', 'ModernStringEnum.value1.rawValue'),
        ('optUuidCol', 'UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!', 'UUID?', 'uuid')
    ]

    primitiveLists = [
        ('arrayBool', '[true, true, false]'),
        ('arrayInt', '[1, 2, 3]'),
        ('arrayInt8', '[1, 2, 3]'),
        ('arrayInt16', '[1, 2, 3]'),
        ('arrayInt32', '[1, 2, 3]'),
        ('arrayInt64', '[1, 2, 3]'),
        ('arrayFloat', '[123.456, 234.456, 345.567]'),
        ('arrayDouble', '[123.456, 234.456, 345.567]'),
        ('arrayString', '["Foo", "Bar", "Baz"]'),
        ('arrayBinary', '[Data(count: 64), Data(count: 128), Data(count: 256)]'),
        ('arrayDate', '[Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 1000000)]'),
        ('arrayDecimal', '[Decimal128(123.456), Decimal128(456.789), Decimal128(963.852)]'),
        ('arrayObjectId', '[ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045"), ObjectId("61184062c1d8f096a3695044")]'),
        ('arrayAny', '[.objectId(ObjectId("61184062c1d8f096a3695046")), .string("Hello"), .int(123)]'),

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
class QueryTests_: TestCase {

    private func objects() -> Results<ModernAllTypesObject> {
        realmWithTestPath().objects(ModernAllTypesObject.self)
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
            object.${property[0]} = ${property[1]}
            % end

            % for list in primitiveLists:
            object.${list[0]}.append(objectsIn: ${list[1]})
            % end

            realm.add(object)
        }
    }

    private func assertQuery<T: Equatable>(predicate: String,
                                           values: [T],
                                           expectedCount: Int,
                                           _ query: ((Query<ModernAllTypesObject>) -> Query<ModernAllTypesObject>)) {
        let results = objects().query(query)
        XCTAssertEqual(results.count, expectedCount)

        let constructedPredicate = query(Query<ModernAllTypesObject>()).constructPredicate()
        XCTAssertEqual(constructedPredicate.0,
                       predicate)

        for (e1, e2) in zip(constructedPredicate.1, values) {
            if let e1 = e1 as? Object, let e2 = e2 as? Object {
                assertEqual(e1, e2)
            } else {
                XCTAssertEqual(e1 as! T, e2)
            }
        }
    }

    func testEquals() {
        % for property in properties:
        // ${property[0]}

        % # Count of 5 assumes enum.
        % if len(property) == 5:
        assertQuery(predicate: "${property[0]} == %@", values: [${property[4]}], expectedCount: 1) {
            $0.${property[0]} == ${property[1]}
        }
        % else:
        assertQuery(predicate: "${property[0]} == %@", values: [${property[1]}], expectedCount: 1) {
            $0.${property[0]} == ${property[1]}
        }
        % end
        % end
    }

    func testEqualsOptional() {
        % for property in optProperties:
        // ${property[0]}

        % if len(property) == 5:
        assertQuery(predicate: "${property[0]} == %@", values: [${property[4]}], expectedCount: 1) {
            $0.${property[0]} == ${property[1]}
        }
        % else:
        assertQuery(predicate: "${property[0]} == %@", values: [${property[1]}], expectedCount: 1) {
            $0.${property[0]} == ${property[1]}
        }
        % end
        % end

        // Test for `nil`
        % for property in optProperties:
        // ${property[0]}

        % if len(property) == 4:
        assertQuery(predicate: "${property[0]} == %@", values: [NSNull()], expectedCount: 0) {
            $0.${property[0]} == nil
        }
        % else:
        assertQuery(predicate: "${property[0]} == %@", values: [NSNull()], expectedCount: 0) {
            $0.${property[0]} == nil
        }
        % end
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

    func testNotEquals() {
        % for property in properties:
        // ${property[0]}

        % # Count of 5 assumes enum.
        % if len(property) == 5:
        assertQuery(predicate: "${property[0]} != %@", values: [${property[4]}], expectedCount: 0) {
            $0.${property[0]} != ${property[1]}
        }
        % else:
        assertQuery(predicate: "${property[0]} != %@", values: [${property[1]}], expectedCount: 0) {
            $0.${property[0]} != ${property[1]}
        }
        % end
        % end
    }

    func testNotEqualsOptional() {
        % for property in optProperties:
        // ${property[0]}

        % # Count of 5 assumes enum.
        % if len(property) == 5:
        assertQuery(predicate: "${property[0]} != %@", values: [${property[4]}], expectedCount: 0) {
            $0.${property[0]} != ${property[1]}
        }
        % else:
        assertQuery(predicate: "${property[0]} != %@", values: [${property[1]}], expectedCount: 0) {
            $0.${property[0]} != ${property[1]}
        }
        % end
        % end

        // Test for `nil`
        % for property in optProperties:
        // ${property[0]}

        % if len(property) == 5:
        assertQuery(predicate: "${property[0]} != %@", values: [NSNull()], expectedCount: 1) {
            $0.${property[0]} != nil
        }
        % else:
        assertQuery(predicate: "${property[0]} != %@", values: [NSNull()], expectedCount: 1) {
            $0.${property[0]} != nil
        }
        % end
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

   func testGreaterThan() {
        % for property in properties:
        % # Count of 5 assumes enum.
        % if len(property) == 5 and property[3] == 'numeric':
        // ${property[0]}
        assertQuery(predicate: "${property[0]} > %@", values: [${property[4]}], expectedCount: 0) {
            $0.${property[0]} > ${property[1]}
        }
        assertQuery(predicate: "${property[0]} >= %@", values: [${property[4]}], expectedCount: 1) {
            $0.${property[0]} >= ${property[1]}
        }
        % elif property[3] == 'numeric':
        // ${property[0]}
        assertQuery(predicate: "${property[0]} > %@", values: [${property[1]}], expectedCount: 0) {
            $0.${property[0]} > ${property[1]}
        }
        assertQuery(predicate: "${property[0]} >= %@", values: [${property[1]}], expectedCount: 1) {
            $0.${property[0]} >= ${property[1]}
        }
        % end
        % end
    }

    func testGreaterThanOptional() {
        % for property in optProperties:
        % # Count of 5 assumes enum.
        % if len(property) == 5 and property[3] == 'numeric':
        // ${property[0]}
        assertQuery(predicate: "${property[0]} > %@", values: [${property[4]}], expectedCount: 0) {
            $0.${property[0]} > ${property[1]}
        }
        assertQuery(predicate: "${property[0]} >= %@", values: [${property[4]}], expectedCount: 1) {
            $0.${property[0]} >= ${property[1]}
        }
        % elif property[3] == 'numeric':
        // ${property[0]}
        assertQuery(predicate: "${property[0]} > %@", values: [${property[1]}], expectedCount: 0) {
            $0.${property[0]} > ${property[1]}
        }
        assertQuery(predicate: "${property[0]} >= %@", values: [${property[1]}], expectedCount: 1) {
            $0.${property[0]} >= ${property[1]}
        }
        % end
        % end

        // Test for `nil`
        % for property in optProperties:
        % if len(property) == 5 and property[3] == 'numeric':
        // ${property[0]}
        assertQuery(predicate: "${property[0]} > %@", values: [NSNull()], expectedCount: 0) {
            $0.${property[0]} > nil
        }
        assertQuery(predicate: "${property[0]} >= %@", values: [NSNull()], expectedCount: 0) {
            $0.${property[0]} >= nil
        }
        % elif property[3] == 'numeric':
        // ${property[0]}
        assertQuery(predicate: "${property[0]} > %@", values: [NSNull()], expectedCount: 0) {
            $0.${property[0]} > nil
        }
        assertQuery(predicate: "${property[0]} >= %@", values: [NSNull()], expectedCount: 0) {
            $0.${property[0]} >= nil
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
        % # Count of 5 assumes enum.
        % if len(property) == 5 and property[3] == 'numeric':
        // ${property[0]}
        assertQuery(predicate: "${property[0]} < %@", values: [${property[4]}], expectedCount: 0) {
            $0.${property[0]} < ${property[1]}
        }
        assertQuery(predicate: "${property[0]} <= %@", values: [${property[4]}], expectedCount: 1) {
            $0.${property[0]} <= ${property[1]}
        }
        % elif property[3] == 'numeric':
        // ${property[0]}
        assertQuery(predicate: "${property[0]} < %@", values: [${property[1]}], expectedCount: 0) {
            $0.${property[0]} < ${property[1]}
        }
        assertQuery(predicate: "${property[0]} <= %@", values: [${property[1]}], expectedCount: 1) {
            $0.${property[0]} <= ${property[1]}
        }
        % end
        % end
    }

    func testLessThanOptional() {
        % for property in optProperties:
        % # Count of 5 assumes enum.
        % if len(property) == 5 and property[3] == 'numeric':
        // ${property[0]}
        assertQuery(predicate: "${property[0]} < %@", values: [${property[4]}], expectedCount: 0) {
            $0.${property[0]} < ${property[1]}
        }
        assertQuery(predicate: "${property[0]} <= %@", values: [${property[4]}], expectedCount: 1) {
            $0.${property[0]} <= ${property[1]}
        }
        % elif property[3] == 'numeric':
        // ${property[0]}
        assertQuery(predicate: "${property[0]} < %@", values: [${property[1]}], expectedCount: 0) {
            $0.${property[0]} < ${property[1]}
        }
        assertQuery(predicate: "${property[0]} <= %@", values: [${property[1]}], expectedCount: 1) {
            $0.${property[0]} <= ${property[1]}
        }
        % end
        % end

        // Test for `nil`
        % for property in optProperties:
        % if len(property) == 5 and property[3] == 'numeric':
        // ${property[0]}
        assertQuery(predicate: "${property[0]} < %@", values: [NSNull()], expectedCount: 0) {
            $0.${property[0]} < nil
        }
        assertQuery(predicate: "${property[0]} <= %@", values: [NSNull()], expectedCount: 0) {
            $0.${property[0]} <= nil
        }
        % elif property[3] == 'numeric':
        // ${property[0]}
        assertQuery(predicate: "${property[0]} < %@", values: [NSNull()], expectedCount: 0) {
            $0.${property[0]} < nil
        }
        assertQuery(predicate: "${property[0]} <= %@", values: [NSNull()], expectedCount: 0) {
            $0.${property[0]} <= nil
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
}
