//
//  SwiftObjectInterfaceTests.swift
//  RealmSwift
//
//  Created by JP Simard on 6/16/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

import XCTest

// Note: Swift doesn't support custom accessor names
// so we test to make sure models with custom accessors can still be accessed
class SwiftObjectInterfaceTests: RLMTestCase {
    
    func testCustomAccessors() {
        let realm = realmWithTestPath()
        realm.beginWriteTransaction()
        let ca = CustomAccessors.createInRealm(realm, withObject: ["name", 2])
        XCTAssertEqualObjects(ca.name, "name", "name property should be name.")
        ca.age = 99
        XCTAssertEqual(ca.age, 99, "age property should be 99")
        realm.commitWriteTransaction()
    }
    
    func testClassExtension() {
        let realm = realmWithTestPath()
        
        realm.beginWriteTransaction()
        let bObject = BaseClassTestObject()
        bObject.intCol = 1
        bObject.stringCol = "stringVal"
        realm.addObject(bObject)
        realm.commitWriteTransaction()
        
        let objectFromRealm = realm.allObjects(BaseClassTestObject.className())[0] as BaseClassTestObject
        XCTAssertEqual(objectFromRealm.intCol, 1, "Should be 1")
        XCTAssertEqualObjects(objectFromRealm.stringCol, "stringVal", "Should be stringVal")
    }
}
