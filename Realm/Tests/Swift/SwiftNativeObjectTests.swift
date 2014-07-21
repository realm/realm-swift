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
import TestFramework

// FIXME: Re-enable once <rdar://17739540> "ER: Swift: It should be possible to downcast from Any to AnyObject". is resolved.

//class SwiftNativeObjectTests: SwiftTestCase {
//    
//    
//    func testNativeInsert() {
//        
//        let realm = realmWithTestPath()
//        
//        let url = NSURL(string: "http://google.com")
//        let url2 = NSURL(string: "http://apple.com")
//        
//        realm.beginWriteTransaction()
//        SwiftNativeObject.createInRealm(realm, withObject: [url, NSData()])
//        let obj = SwiftNativeObject.createInRealm(realm, withObject: [url2, NSData()])
//        obj.nativeCol = nil;
//        obj.dataCol = nil;
//        
//        realm.commitWriteTransaction()
//        
//        
//        let objects = SwiftNativeObject.allObjectsInRealm(realm)
//        XCTAssertEqual(objects.count, 2 as Int, "2 rows excepted");
//        XCTAssertTrue(objects[0].isKindOfClass(SwiftNativeObject.self), "SwiftNativeObject expected");
//        XCTAssertTrue((objects[0] as SwiftNativeObject)["nativeCol"].isKindOfClass(NSURL.self), "NSURL expected")
//        XCTAssertTrue((objects[0] as SwiftNativeObject)["nativeCol"].isEqual(url), "url expected");
//        XCTAssertTrue((objects[0] as SwiftNativeObject)["dataCol"].isEqual(NSData()))
//        XCTAssertTrue((objects[0] as SwiftNativeObject)["dataCol"].isEqual(NSData()), "'NSData' expected");
//        
//        XCTAssertTrue(objects[1].isKindOfClass(SwiftNativeObject.self), "SwiftNativeObject expected");
//        XCTAssertTrue(!(objects[1] as SwiftNativeObject)["nativeCol"], "nil expected");
//        XCTAssertTrue(!(objects[1] as SwiftNativeObject)["dataCol"], "nil expected");
//        XCTAssertTrue(!(objects[1] as SwiftNativeObject)["dataCol"], "nil expected");
//        
//    }
//    
//    func testNativeValidate() {
//        let realm = realmWithTestPath()
//        
//        realm.beginWriteTransaction()
//        let objects = SwiftNativeObject.allObjectsInRealm(realm)
//
////        XCTAssertThrows(SwiftNativeObject.createInRealm(realm, withObject: ["Not a url", NSData()]), "Native not of the correct class")
////        XCTAssertThrows(SwiftNativeObject.createInRealm(realm, withObject: [11, NSData()]), "Native not of the correct class")
//        
//        XCTAssertEqual(objects.count, 0 as Int, "0 rows excepted");
//        realm.commitWriteTransaction()
//    }
//    
//    
//}
