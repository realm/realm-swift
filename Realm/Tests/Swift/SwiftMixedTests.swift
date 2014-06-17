//
//  SwiftMixedTests.swift
//  RealmSwift
//
//  Created by JP Simard on 6/16/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

import XCTest

class SwiftMixedTests: RLMTestCase {
    
    func testMixedInsert() {
        let data = "Hello World".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        
        let realm = self.realmWithTestPath()
        
        // FIXME: add object with subtable
        realm.beginWriteTransaction()
        MixedObject.createInRealm(realm, withObject: [true, "Jens", 50])
        // FIXME: Adding this object makes the test fail
        // MixedObject.createInRealm(realm, withObject: [true, 10, 52])
        MixedObject.createInRealm(realm, withObject: [true, 3.1 as Float, 53])
        MixedObject.createInRealm(realm, withObject: [true, 3.1 as Double, 54])
        MixedObject.createInRealm(realm, withObject: [true, NSDate(), 55])
        MixedObject.createInRealm(realm, withObject: [true, data, 50])
        realm.commitWriteTransaction()
        
        let objects = realm.allObjects(MixedObject.className())
        XCTAssertEqual(objects.count, 5, "5 rows expected")
        XCTAssertTrue(objects[0].isKindOfClass(MixedObject.self), "MixedObject expected")
        XCTAssertTrue((objects[0] as MixedObject)["other"].isKindOfClass(NSString.self), "NSString expected")
        XCTAssertTrue((objects[0] as MixedObject)["other"].isEqualToString("Jens"), "'Jens' expected")
        
        // FIXME: See above
        // XCTAssertTrue((objects[1] as MixedObject)["other"].isKindOfClass(NSNumber.self), "NSNumber expected")
        // XCTAssertEqual(((objects[1] as MixedObject)["other"] as NSNumber).longLongValue, 10, "'10' expected")
        
        XCTAssertTrue((objects[1] as MixedObject)["other"].isKindOfClass(NSNumber.self), "NSNumber expected")
        XCTAssertEqual(((objects[1] as MixedObject)["other"] as NSNumber).floatValue, 3.1, "'3.1' expected")
        
        XCTAssertTrue((objects[2] as MixedObject)["other"].isKindOfClass(NSNumber.self), "NSNumber expected")
        XCTAssertEqual(((objects[2] as MixedObject)["other"] as NSNumber).doubleValue, 3.1, "'3.1' expected")
        
        XCTAssertTrue((objects[3] as MixedObject)["other"].isKindOfClass(NSDate.self), "NSDate expected")
        
        XCTAssertTrue((objects[4] as MixedObject)["other"].isKindOfClass(NSData.self), "NSData expected")
    }
}
