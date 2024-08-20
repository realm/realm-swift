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

#if canImport(RealmTestSupport)
import RealmTestSupport
#endif

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

class SwiftRLMNonDefaultSetObject: RLMObject {
    @objc dynamic var set = RLMSet<SwiftRLMNonDefaultObject>(objectClassName: SwiftRLMNonDefaultObject.className())
    public override class func shouldIncludeInDefaultSchema() -> Bool {
        return false
    }
}

class SwiftRLMNonDefaultDictionaryObject: RLMObject {
    @objc dynamic var dictionary = RLMDictionary<NSString, SwiftRLMNonDefaultObject>(objectClassName: SwiftRLMNonDefaultObject.className(), keyType: .string)
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

@MainActor
class SwiftRLMRecursingSchemaTestObject : RLMObject {
    @objc dynamic var propertyWithIllegalDefaultValue: SwiftRLMIntObject? = {
        if mayAccessSchema {
            let realm = RLMRealm.default()
            return SwiftRLMIntObject.allObjects().firstObject() as! SwiftRLMIntObject?
        }
        return nil
    }()

    static var mayAccessSchema = false
}

class InvalidArrayType: FakeObject {
    @objc dynamic var array = RLMArray<SwiftRLMIntObject>(objectClassName: "invalid class")
}

class InvalidSetType: FakeObject {
    @objc dynamic var set = RLMSet<SwiftRLMIntObject>(objectClassName: "invalid class")
}

class InvalidDictionaryType: FakeObject {
    @objc dynamic var dictionary = RLMDictionary<NSString, SwiftRLMIntObject>(objectClassName: "invalid class", keyType: .string)
}

@MainActor
class InitAppendsToArrayProperty : RLMObject {
    @objc dynamic var propertyWithIllegalDefaultValue: RLMArray<InitAppendsToArrayProperty> = {
        if mayAppend {
            mayAppend = false
            let array = RLMArray<InitAppendsToArrayProperty>(objectClassName: InitAppendsToArrayProperty.className())
            array.add(InitAppendsToArrayProperty())
            return array
        }
        return RLMArray<InitAppendsToArrayProperty>(objectClassName: InitAppendsToArrayProperty.className())
    }()

    static var mayAppend = false
}

class NoProps: FakeObject {
    // no @objc properties
}

class OnlyComputedSource: RLMObject {
    @objc dynamic var link: OnlyComputedTarget?
}

class OnlyComputedTarget: RLMObject {
    @objc dynamic var backlinks: RLMLinkingObjects<OnlyComputedSource>?

    override class func linkingObjectsProperties() -> [String : RLMPropertyDescriptor] {
        return ["backlinks": RLMPropertyDescriptor(with: OnlyComputedSource.self, propertyName: "link")]
    }
}

class OnlyComputedNoBacklinksProps: FakeObject {
    var computedProperty: String {
        return "Test_String"
    }
}

class RequiresObjcName: RLMObject {
#if compiler(>=5.10)
    nonisolated(unsafe) static var enable = false
#else
    static var enable = false
#endif
    override class func _realmIgnoreClass() -> Bool {
        return !enable
    }
}

class ClassWrappingObjectSubclass {
    class Inner: RequiresObjcName {
        @objc dynamic var value = 0
    }
}
struct StructWrappingObjectSubclass {
    class Inner: RequiresObjcName {
        @objc dynamic var value = 0
    }
}
enum EnumWrappingObjectSubclass {
    class Inner: RequiresObjcName {
        @objc dynamic var value = 0
    }
}

private class PrivateClassWithoutExplicitObjcName: RequiresObjcName {
    @objc dynamic var value = 0
}

class SwiftRLMSchemaTests: RLMMultiProcessTestCase {
    func testWorksAtAll() {
        if isParent {
            XCTAssertEqual(0, runChildAndWait(), "Tests in child process failed")
        }
    }

    func testShouldRaiseObjectWithoutProperties() {
        assertThrowsWithReasonMatching(RLMObjectSchema(forObjectClass: NoProps.self),
                                       "No properties are defined for 'NoProps'. Did you remember to mark them with '@objc' or '@Persisted' in your model?")
    }
    
    func testShouldNotThrowForObjectWithOnlyBacklinksProps() {
        let config = RLMRealmConfiguration.default()
        config.objectClasses = [OnlyComputedTarget.self, OnlyComputedSource.self]
        config.inMemoryIdentifier = #function
        let r = try! RLMRealm(configuration: config)
        try! r.transaction {
            _ = OnlyComputedTarget.create(in: r, withValue: [])
        }

        let schema = OnlyComputedTarget().objectSchema
        XCTAssertEqual(schema.computedProperties.count, 1)
        XCTAssertEqual(schema.properties.count, 0)
    }

    func testShouldThrowForObjectWithOnlyComputedNoBacklinksProps() {
        assertThrowsWithReasonMatching(RLMObjectSchema(forObjectClass: OnlyComputedNoBacklinksProps.self),
                                       "No properties are defined for 'OnlyComputedNoBacklinksProps'. Did you remember to mark them with '@objc' or '@Persisted' in your model?")
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
        // uninitialized schema during schema init
        _ = InitLinkedToClass()
        // Again with an object that links to an uninitialized type
        // rather than creating one
        _ = SwiftRLMCompanyObject()

        // Objects not in default schema
        _ = SwiftRLMLinkedNonDefaultObject(value: [[1]])
        _ = SwiftRLMNonDefaultArrayObject(value: [[[1]]])
        _ = SwiftRLMNonDefaultSetObject(value: [[[1]]])
        _ = SwiftRLMMutualLink1Object()
    }

    func testCreateUnmanagedObjectWhichCreatesAnotherClassViaInitWithValueDuringSchemaInit() {
        if isParent {
            XCTAssertEqual(0, runChildAndWait(), "Tests in child process failed")
            return
        }

        _ = InitLinkedToClass(value: [[0]])
        _ = SwiftRLMCompanyObject(value: [[["Jaden", 20, false] as [Any]]])
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

    @MainActor
    func testPreventsDeadLocks() {
        if isParent {
            XCTAssertEqual(0, runChildAndWait(), "Tests in child process failed")
            return
        }

        SwiftRLMRecursingSchemaTestObject.mayAccessSchema = true
        assertThrowsWithReasonMatching(RLMSchema.shared(), ".*recursive.*")
    }

    @MainActor
    func testAccessSchemaCreatesObjectWhichAttempsInsertionsToArrayProperty() {
        if isParent {
            XCTAssertEqual(0, runChildAndWait(), "Tests in child process failed")
            return
        }

        // This is different from the above tests in that it is a to-many link
        // and it only occurs while the schema is initializing
        InitAppendsToArrayProperty.mayAppend = true
        assertThrowsWithReasonMatching(RLMSchema.shared(),
                                       ".*Object cannot be inserted unless the schema is initialized.*")
    }

    func testInvalidObjectTypeForRLMArray() {
        assertThrowsWithReasonMatching(RLMObjectSchema(forObjectClass: InvalidArrayType.self),
                                       "RLMArray\\<invalid class\\>")
    }

    @MainActor
    func testInvalidNestedClass() {
        if isParent {
            XCTAssertEqual(0, runChildAndWait(), "Tests in child process failed")
            return
        }

        RequiresObjcName.enable = true
        assertThrowsWithReasonMatching(RLMSchema.sharedSchema(for: ClassWrappingObjectSubclass.Inner.self),
                                       "Object subclass '.*' must explicitly set the class's objective-c name with @objc\\(ClassName\\) because it is not a top-level public class.")
        assertThrowsWithReasonMatching(RLMSchema.sharedSchema(for: StructWrappingObjectSubclass.Inner.self),
                                       "Object subclass '.*' must explicitly set the class's objective-c name with @objc\\(ClassName\\) because it is not a top-level public class.")
        assertThrowsWithReasonMatching(RLMSchema.sharedSchema(for: EnumWrappingObjectSubclass.Inner.self),
                                       "Object subclass '.*' must explicitly set the class's objective-c name with @objc\\(ClassName\\) because it is not a top-level public class.")
        assertThrowsWithReasonMatching(RLMSchema.sharedSchema(for: PrivateClassWithoutExplicitObjcName.self),
                                               "Object subclass '.*' must explicitly set the class's objective-c name with @objc\\(ClassName\\) because it is not a top-level public class.")
    }
}

#endif
