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
import Realm
import Realm.Private

class InitLinkedToClass: RLMObject {
    @objc dynamic var value = SwiftIntObject(value: [0])
}

class SwiftNonDefaultObject: RLMObject {
    @objc dynamic var value = 0
    public override class func shouldIncludeInDefaultSchema() -> Bool {
        return false
    }
}

class SwiftLinkedNonDefaultObject: RLMObject {
    @objc dynamic var obj: SwiftNonDefaultObject?
    public override class func shouldIncludeInDefaultSchema() -> Bool {
        return false
    }
}

class SwiftNonDefaultArrayObject: RLMObject {
    @objc dynamic var array = RLMArray(objectClassName: SwiftNonDefaultObject.className())
    public override class func shouldIncludeInDefaultSchema() -> Bool {
        return false
    }
}

class SwiftMutualLink1Object: RLMObject {
    @objc dynamic var object: SwiftMutualLink2Object?
    public override class func shouldIncludeInDefaultSchema() -> Bool {
        return false
    }
}

class SwiftMutualLink2Object: RLMObject {
    @objc dynamic var object: SwiftMutualLink1Object?
    public override class func shouldIncludeInDefaultSchema() -> Bool {
        return false
    }
}

class IgnoredLinkPropertyObject : RLMObject {
    @objc dynamic var value = 0
    var obj = SwiftIntObject()

    override class func ignoredProperties() -> [String] {
        return ["obj"]
    }
}

class SwiftRecursingSchemaTestObject : RLMObject {
    @objc dynamic var propertyWithIllegalDefaultValue: SwiftIntObject? = {
        if mayAccessSchema {
            let realm = RLMRealm.default()
            return SwiftIntObject.allObjects().firstObject() as! SwiftIntObject?
        } else {
            return nil
        }
    }()

    static var mayAccessSchema = false
}

class InvalidArrayType: FakeObject {
    @objc dynamic var array = RLMArray<SwiftIntObject>(objectClassName: "invalid class")
}

class InitAppendsToArrayProperty : RLMObject {
    @objc dynamic var propertyWithIllegalDefaultValue: RLMArray<SwiftIntObject> = {
        if mayAppend {
            let array = RLMArray<SwiftIntObject>(objectClassName: SwiftIntObject.className())
            array.add(SwiftIntObject())
            return array
        } else {
            return RLMArray<SwiftIntObject>(objectClassName: SwiftIntObject.className())
        }
    }()

    static var mayAppend = false
}

class SwiftSchemaTests: RLMMultiProcessTestCase {
    func testWorksAtAll() {
        if isParent {
            XCTAssertEqual(0, runChildAndWait(), "Tests in child process failed")
        }
    }

    func testSchemaInitWithLinkedToObjectUsingInitWithValue() {
        if isParent {
            XCTAssertEqual(0, runChildAndWait(), "Tests in child process failed")
            return
        }

        let config = RLMRealmConfiguration.default()
        config.objectClasses = [IgnoredLinkPropertyObject.self]
        config.inMemoryIdentifier = #function
        let r = try! RLMRealm(configuration: config)
        try! r.transaction {
            _ = IgnoredLinkPropertyObject.create(in: r, withValue: [1])
        }
    }

    func testCreateUnmanagedObjectWithUninitializedSchema() {
        if isParent {
            XCTAssertEqual(0, runChildAndWait(), "Tests in child process failed")
            return
        }

        // Object in default schema
        _ = SwiftIntObject()
        // Object not in default schema
        _ = SwiftNonDefaultObject()
    }

    func testCreateUnmanagedObjectWithNestedObjectWithUninitializedSchema() {
        if isParent {
            XCTAssertEqual(0, runChildAndWait(), "Tests in child process failed")
            return
        }

        // Objects in default schema

        // Should not throw (or crash) despite creating an object with an
        // unintialized schema during schema init
        _ = InitLinkedToClass()
        // Again with an object that links to an unintialized type
        // rather than creating one
        _ = SwiftCompanyObject()

        // Objects not in default schema
        _ = SwiftLinkedNonDefaultObject(value: [[1]])
        _ = SwiftNonDefaultArrayObject(value: [[[1]]])
        _ = SwiftMutualLink1Object(value: [[[:]]])
    }

    func testCreateUnmanagedObjectWhichCreatesAnotherClassViaInitWithValueDuringSchemaInit() {
        if isParent {
            XCTAssertEqual(0, runChildAndWait(), "Tests in child process failed")
            return
        }

        _ = InitLinkedToClass(value: [[0]])
        _ = SwiftCompanyObject(value: [[["Jaden", 20, false]]])
    }

    func testInitUnmanagedObjectNotInClassSubsetDuringSchemaInit() {
        if isParent {
            XCTAssertEqual(0, runChildAndWait(), "Tests in child process failed")
            return
        }

        let config = RLMRealmConfiguration.default()
        config.objectClasses = [IgnoredLinkPropertyObject.self]
        config.inMemoryIdentifier = #function
        _ = try! RLMRealm(configuration: config)
        let r = try! RLMRealm(configuration: RLMRealmConfiguration.default())
        try! r.transaction {
            _ = IgnoredLinkPropertyObject.create(in: r, withValue: [1])
        }
    }

    func testPreventsDeadLocks() {
        if isParent {
            XCTAssertEqual(0, runChildAndWait(), "Tests in child process failed")
            return
        }

        SwiftRecursingSchemaTestObject.mayAccessSchema = true
        assertThrowsWithReasonMatching(RLMSchema.shared(), ".*recursive.*")
    }

    func testAccessSchemaCreatesObjectWhichAttempsInsertionsToArrayProperty() {
        if isParent {
            XCTAssertEqual(0, runChildAndWait(), "Tests in child process failed")
            return
        }

        // This is different from the above tests in that it is a to-many link
        // and it only occurs while the schema is initializing
        InitAppendsToArrayProperty.mayAppend = true
        assertThrowsWithReasonMatching(RLMSchema.shared(), ".*unless the schema is initialized.*")
    }

    func testInvalidObjectTypeForRLMArray() {
        RLMSetTreatFakeObjectAsRLMObject(true)
        assertThrowsWithReasonMatching(RLMObjectSchema(forObjectClass: InvalidArrayType.self),
                                       "RLMArray\\<invalid class\\>")
        RLMSetTreatFakeObjectAsRLMObject(false)
    }
}
