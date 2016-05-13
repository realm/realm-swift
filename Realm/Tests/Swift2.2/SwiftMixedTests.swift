////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
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

class SwiftMixedTests: RLMTestCase {

    func testMixedInsert() {
        let data = "Hello World".dataUsingEncoding(NSUTF8StringEncoding)

        let realm = realmWithTestPath()

        // FIXME: add object with subtable
        realm.beginWriteTransaction()
        MixedObject.createInRealm(realm, withValue: [true, "Jens", 50])
        // FIXME: Adding this object makes the test fail
        // MixedObject.createInRealm(realm, withValue: [true, 10, 52] as NSArray)
        MixedObject.createInRealm(realm, withValue: [true, 3.1 as Float, 53] as NSArray)
        MixedObject.createInRealm(realm, withValue: [true, 3.1 as Double, 54] as NSArray)
        MixedObject.createInRealm(realm, withValue: [true, NSDate(), 55] as NSArray)
        MixedObject.createInRealm(realm, withValue: [true, data!, 50] as NSArray)
        try! realm.commitWriteTransaction()

        let objects = MixedObject.allObjectsInRealm(realm)
        XCTAssertEqual(objects.count, UInt(5), "5 rows expected")
        XCTAssertTrue(objects[0].isKindOfClass(MixedObject.self), "MixedObject expected")
        XCTAssertTrue((objects[0] as! MixedObject)["other"]!.isKindOfClass(NSString.self), "NSString expected")
        XCTAssertTrue((objects[0] as! MixedObject)["other"]!.isEqual("Jens"), "'Jens' expected")

        // FIXME: See above
        // XCTAssertTrue((objects[1] as MixedObject)["other"].isKindOfClass(NSNumber.self), "NSNumber expected")
        // XCTAssertEqual(((objects[1] as MixedObject)["other"] as NSNumber).longLongValue, 10, "'10' expected")

        XCTAssertTrue((objects[1] as! MixedObject)["other"]!.isKindOfClass(NSNumber.self), "NSNumber expected")
        XCTAssertEqual(((objects[1] as! MixedObject)["other"] as! NSNumber).floatValue, Float(3.1), "'3.1' expected")

        XCTAssertTrue((objects[2] as! MixedObject)["other"]!.isKindOfClass(NSNumber.self), "NSNumber expected")
        XCTAssertEqual(((objects[2] as! MixedObject)["other"] as! NSNumber).doubleValue, 3.1, "'3.1' expected")

        XCTAssertTrue((objects[3] as! MixedObject)["other"]!.isKindOfClass(NSDate.self), "NSDate expected")

        XCTAssertTrue((objects[4] as! MixedObject)["other"]!.isKindOfClass(NSData.self), "NSData expected")
    }
}
