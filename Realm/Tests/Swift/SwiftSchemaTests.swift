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
import RealmTestSupport

#if os(macOS)

class InitLinkedToClass: RLMObject {
    @objc dynamic var value: SwiftRLMIntObject! = SwiftRLMIntObject(value: [0])
}

class SwiftRLMNonDefaultObject: RLMObject {
    @objc dynamic var value = 0
    public override class func shouldIncludeInDefaultSchema() -> Bool {
        return false
    }
}

class SwiftRLMLinkedNonDefaultObject: RLMObject {
    @objc dynamic var obj: SwiftRLMNonDefaultObject?
    public override class func shouldIncludeInDefaultSchema() -> Bool {
        return false
    }
}

class SwiftRLMNonDefaultArrayObject: RLMObject {
    @objc dynamic var array = RLMArray<SwiftRLMNonDefaultObject>(objectClassName: SwiftRLMNonDefaultObject.className())
    public override class func shouldIncludeInDefaultSchema() -> Bool {
        return false
    }
}

class SwiftRLMMutualLink1Object: RLMObject {
    @objc dynamic var object: SwiftRLMMutualLink2Object?
    public override class func shouldIncludeInDefaultSchema() -> Bool {
        return false
    }
}

class SwiftRLMMutualLink2Object: RLMObject {
    @objc dynamic var object: SwiftRLMMutualLink1Object?
    public override class func shouldIncludeInDefaultSchema() -> Bool {
        return false
    }
}

class IgnoredLinkPropertyObject : RLMObject {
    @objc dynamic var value = 0
    var obj = SwiftRLMIntObject()

    override class func ignoredProperties() -> [String] {
        return ["obj"]
    }
}

class SwiftRLMRecursingSchemaTestObject : RLMObject {
    @objc dynamic var propertyWithIllegalDefaultValue: SwiftRLMIntObject? = {
        if mayAccessSchema {
            let realm = RLMRealm.default()
            return SwiftRLMIntObject.allObjects().firstObject() as! SwiftRLMIntObject?
        } else {
            return nil
        }
    }()

    static var mayAccessSchema = false
}

class InvalidArrayType: FakeObject {
    @objc dynamic var array = RLMArray<SwiftRLMIntObject>(objectClassName: "invalid class")
}

class InitAppendsToArrayProperty : RLMObject {
    @objc dynamic var propertyWithIllegalDefaultValue: RLMArray<InitAppendsToArrayValue> = {
        if mayAppend {
            let array = RLMArray<InitAppendsToArrayValue>(objectClassName: InitAppendsToArrayValue.className())
            array.add(InitAppendsToArrayValue())
            return array
        } else {
            return RLMArray<InitAppendsToArrayValue>(objectClassName: InitAppendsToArrayValue.className())
        }
    }()

    static var mayAppend = false
}

class InitAppendsToArrayValue : RLMObject {
    @objc dynamic var value: Int = 0
}

class SwiftRLMSchemaTests: RLMMultiProcessTestCase {
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
        _ = SwiftRLMIntObject()
        // Object not in default schema
        _ = SwiftRLMNonDefaultObject()
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
        _ = SwiftRLMCompanyObject()

        // Objects not in default schema
        _ = SwiftRLMLinkedNonDefaultObject(value: [[1]])
        _ = SwiftRLMNonDefaultArrayObject(value: [[[1]]])
        _ = SwiftRLMMutualLink1Object(value: [[[:]]])
    }

    func testCreateUnmanagedObjectWhichCreatesAnotherClassViaInitWithValueDuringSchemaInit() {
        if isParent {
            XCTAssertEqual(0, runChildAndWait(), "Tests in child process failed")
            return
        }

        _ = InitLinkedToClass(value: [[0]])
        _ = SwiftRLMCompanyObject(value: [[["Jaden", 20, false]]])
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

        SwiftRLMRecursingSchemaTestObject.mayAccessSchema = true
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
        assertThrowsWithReasonMatching(RLMObjectSchema(forObjectClass: InvalidArrayType.self),
                                       "RLMArray\\<invalid class\\>")
    }
}

#endif
