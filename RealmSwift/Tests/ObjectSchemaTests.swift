////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
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

class ObjectSchemaTests: TestCase {
    var objectSchema: ObjectSchema!

    var swiftObjectSchema: ObjectSchema {
        return try! Realm().schema["SwiftObject"]!
    }

    func testProperties() {
        let objectSchema = swiftObjectSchema
        let propertyNames = objectSchema.properties.map { $0.name }
        XCTAssertEqual(propertyNames,
                       ["boolCol", "intCol", "int8Col", "int16Col", "int32Col", "int64Col", "intEnumCol", "floatCol", "doubleCol",
                        "stringCol", "binaryCol", "dateCol", "decimalCol",
                        "objectIdCol", "objectCol", "uuidCol", "anyCol", "arrayCol", "setCol", "mapCol"]
        )
    }

    // Cannot name testClassName() because it interferes with the method on XCTest
    func testClassNameProperty() {
        let objectSchema = swiftObjectSchema
        XCTAssertEqual(objectSchema.className, "SwiftObject")
    }

    func testObjectClass() {
        let objectSchema = swiftObjectSchema
        XCTAssertTrue(objectSchema.objectClass === SwiftObject.self)
    }

    func testPrimaryKeyProperty() {
        let objectSchema = swiftObjectSchema
        XCTAssertNil(objectSchema.primaryKeyProperty)
        XCTAssertEqual(try! Realm().schema["SwiftPrimaryStringObject"]!.primaryKeyProperty!.name, "stringCol")
    }

    func testDescription() {
        let objectSchema = swiftObjectSchema
        let expected = """
        SwiftObject {
            boolCol {
                type = bool;
                indexed = NO;
                isPrimary = NO;
                array = NO;
                set = NO;
                dictionary = NO;
                optional = NO;
            }
            intCol {
                type = int;
                indexed = NO;
                isPrimary = NO;
                array = NO;
                set = NO;
                dictionary = NO;
                optional = NO;
            }
            int8Col {
                type = int;
                indexed = NO;
                isPrimary = NO;
                array = NO;
                set = NO;
                dictionary = NO;
                optional = NO;
            }
            int16Col {
                type = int;
                indexed = NO;
                isPrimary = NO;
                array = NO;
                set = NO;
                dictionary = NO;
                optional = NO;
            }
            int32Col {
                type = int;
                indexed = NO;
                isPrimary = NO;
                array = NO;
                set = NO;
                dictionary = NO;
                optional = NO;
            }
            int64Col {
                type = int;
                indexed = NO;
                isPrimary = NO;
                array = NO;
                set = NO;
                dictionary = NO;
                optional = NO;
            }
            intEnumCol {
                type = int;
                indexed = NO;
                isPrimary = NO;
                array = NO;
                set = NO;
                dictionary = NO;
                optional = NO;
            }
            floatCol {
                type = float;
                indexed = NO;
                isPrimary = NO;
                array = NO;
                set = NO;
                dictionary = NO;
                optional = NO;
            }
            doubleCol {
                type = double;
                indexed = NO;
                isPrimary = NO;
                array = NO;
                set = NO;
                dictionary = NO;
                optional = NO;
            }
            stringCol {
                type = string;
                indexed = NO;
                isPrimary = NO;
                array = NO;
                set = NO;
                dictionary = NO;
                optional = NO;
            }
            binaryCol {
                type = data;
                indexed = NO;
                isPrimary = NO;
                array = NO;
                set = NO;
                dictionary = NO;
                optional = NO;
            }
            dateCol {
                type = date;
                indexed = NO;
                isPrimary = NO;
                array = NO;
                set = NO;
                dictionary = NO;
                optional = NO;
            }
            decimalCol {
                type = decimal128;
                indexed = NO;
                isPrimary = NO;
                array = NO;
                set = NO;
                dictionary = NO;
                optional = NO;
            }
            objectIdCol {
                type = object id;
                indexed = NO;
                isPrimary = NO;
                array = NO;
                set = NO;
                dictionary = NO;
                optional = NO;
            }
            objectCol {
                type = object;
                objectClassName = SwiftBoolObject;
                linkOriginPropertyName = (null);
                indexed = NO;
                isPrimary = NO;
                array = NO;
                set = NO;
                dictionary = NO;
                optional = YES;
            }
            uuidCol {
                type = uuid;
                indexed = NO;
                isPrimary = NO;
                array = NO;
                set = NO;
                dictionary = NO;
                optional = NO;
            }
            anyCol {
                type = mixed;
                indexed = NO;
                isPrimary = NO;
                array = NO;
                set = NO;
                dictionary = NO;
                optional = NO;
            }
            arrayCol {
                type = object;
                objectClassName = SwiftBoolObject;
                linkOriginPropertyName = (null);
                indexed = NO;
                isPrimary = NO;
                array = YES;
                set = NO;
                dictionary = NO;
                optional = NO;
            }
            setCol {
                type = object;
                objectClassName = SwiftBoolObject;
                linkOriginPropertyName = (null);
                indexed = NO;
                isPrimary = NO;
                array = NO;
                set = YES;
                dictionary = NO;
                optional = NO;
            }
            mapCol {
                type = object;
                objectClassName = SwiftBoolObject;
                linkOriginPropertyName = (null);
                indexed = NO;
                isPrimary = NO;
                array = NO;
                set = NO;
                dictionary = YES;
                optional = YES;
            }
        }
        """
        XCTAssertEqual(objectSchema.description, expected.replacingOccurrences(of: "    ", with: "\t"))
    }

    func testSubscript() {
        let objectSchema = swiftObjectSchema
        XCTAssertNil(objectSchema["noSuchProperty"])
        XCTAssertEqual(objectSchema["boolCol"]!.name, "boolCol")
    }

    func testEquals() {
        let objectSchema = swiftObjectSchema
        XCTAssert(try! objectSchema == Realm().schema["SwiftObject"]!)
        XCTAssert(try! objectSchema != Realm().schema["SwiftStringObject"]!)
    }
}
