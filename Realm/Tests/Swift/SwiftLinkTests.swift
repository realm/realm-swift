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
import Realm
import RealmTestSupport

class SwiftRLMLinkTests: RLMTestCase {

    // Swift models

    func testBasicLink() {
        let realm = realmWithTestPath()

        let owner = SwiftRLMOwnerObject()
        owner.name = "Tim"
        owner.dog = SwiftRLMDogObject()
        owner.dog!.dogName = "Harvie"

        realm.beginWriteTransaction()
        realm.add(owner)
        try! realm.commitWriteTransaction()

        let owners = SwiftRLMOwnerObject.allObjects(in: realm)
        let dogs = SwiftRLMDogObject.allObjects(in: realm)
        XCTAssertEqual(owners.count, UInt(1), "Expecting 1 owner")
        XCTAssertEqual(dogs.count, UInt(1), "Expecting 1 dog")
        XCTAssertEqual((owners[0] as! SwiftRLMOwnerObject).name, "Tim", "Tim is named Tim")
        XCTAssertEqual((dogs[0] as! SwiftRLMDogObject).dogName, "Harvie", "Harvie is named Harvie")

        let tim = owners[0] as! SwiftRLMOwnerObject
        XCTAssertEqual(tim.dog!.dogName, "Harvie", "Tim's dog should be Harvie")
    }

    func testMultipleOwnerLink() {
        let realm = realmWithTestPath()

        let owner = SwiftRLMOwnerObject()
        owner.name = "Tim"
        owner.dog = SwiftRLMDogObject()
        owner.dog!.dogName = "Harvie"

        realm.beginWriteTransaction()
        realm.add(owner)
        try! realm.commitWriteTransaction()

        XCTAssertEqual(SwiftRLMOwnerObject.allObjects(in: realm).count, UInt(1), "Expecting 1 owner")
        XCTAssertEqual(SwiftRLMDogObject.allObjects(in: realm).count, UInt(1), "Expecting 1 dog")

        realm.beginWriteTransaction()
        let fiel = SwiftRLMOwnerObject.create(in: realm, withValue: ["Fiel", NSNull()])
        fiel.dog = owner.dog
        try! realm.commitWriteTransaction()

        XCTAssertEqual(SwiftRLMOwnerObject.allObjects(in: realm).count, UInt(2), "Expecting 2 owners")
        XCTAssertEqual(SwiftRLMDogObject.allObjects(in: realm).count, UInt(1), "Expecting 1 dog")
    }

    func testLinkRemoval() {
        let realm = realmWithTestPath()

        let owner = SwiftRLMOwnerObject()
        owner.name = "Tim"
        owner.dog = SwiftRLMDogObject()
        owner.dog!.dogName = "Harvie"

        realm.beginWriteTransaction()
        realm.add(owner)
        try! realm.commitWriteTransaction()

        XCTAssertEqual(SwiftRLMOwnerObject.allObjects(in: realm).count, UInt(1), "Expecting 1 owner")
        XCTAssertEqual(SwiftRLMDogObject.allObjects(in: realm).count, UInt(1), "Expecting 1 dog")

        realm.beginWriteTransaction()
        realm.delete(owner.dog!)
        try! realm.commitWriteTransaction()

        XCTAssertNil(owner.dog, "Dog should be nullified when deleted")

        // refresh owner and check
        let owner2 = SwiftRLMOwnerObject.allObjects(in: realm).firstObject() as! SwiftRLMOwnerObject
        XCTAssertNotNil(owner2, "Should have 1 owner")
        XCTAssertNil(owner2.dog, "Dog should be nullified when deleted")
        XCTAssertEqual(SwiftRLMDogObject.allObjects(in: realm).count, UInt(0), "Expecting 0 dogs")
    }

    func testLinkingObjects() {
        let realm = realmWithTestPath()

        let target = SwiftRLMLinkTargetObject()
        target.id = 0

        let source = SwiftRLMLinkSourceObject()
        source.id = 1234
        source.link = target

        XCTAssertEqual(0, target.backlinks!.count)

        realm.beginWriteTransaction()
        realm.add(source)
        try! realm.commitWriteTransaction()

        XCTAssertNotNil(target.realm)
        XCTAssertEqual(1, target.backlinks!.count)
        XCTAssertEqual(1234, (target.backlinks!.firstObject() as! SwiftRLMLinkSourceObject).id)
    }

//    FIXME - disabled until we fix commit log issue which break transacions when leaking realm objects
//    func testCircularLinks() {
//        let realm = realmWithTestPath()
//
//        let obj = SwiftRLMCircleObject()
//        obj.data = "a"
//        obj.next = obj
//
//        realm.beginWriteTransaction()
//        realm.addObject(obj)
//        obj.next.data = "b"
//        try! realm.commitWriteTransaction()
//
//        let obj2 = SwiftRLMCircleObject.allObjectsInRealm(realm).firstObject() as SwiftRLMCircleObject
//        XCTAssertEqual(obj2.data, "b", "data should be 'b'")
//        XCTAssertEqual(obj2.data, obj2.next.data, "objects should be equal")
//    }

    // Objective-C models

    func testBasicLink_objc() {
        let realm = realmWithTestPath()

        let owner = OwnerObject()
        owner.name = "Tim"
        owner.dog = DogObject()
        owner.dog.dogName = "Harvie"

        realm.beginWriteTransaction()
        realm.add(owner)
        try! realm.commitWriteTransaction()

        let owners = OwnerObject.allObjects(in: realm)
        let dogs = DogObject.allObjects(in: realm)
        XCTAssertEqual(owners.count, UInt(1), "Expecting 1 owner")
        XCTAssertEqual(dogs.count, UInt(1), "Expecting 1 dog")
        XCTAssertEqual((owners[0] as! OwnerObject).name!, "Tim", "Tim is named Tim")
        XCTAssertEqual((dogs[0] as! DogObject).dogName!, "Harvie", "Harvie is named Harvie")

        let tim = owners[0] as! OwnerObject
        XCTAssertEqual(tim.dog.dogName!, "Harvie", "Tim's dog should be Harvie")
    }

    func testMultipleOwnerLink_objc() {
        let realm = realmWithTestPath()

        let owner = OwnerObject()
        owner.name = "Tim"
        owner.dog = DogObject()
        owner.dog.dogName = "Harvie"

        realm.beginWriteTransaction()
        realm.add(owner)
        try! realm.commitWriteTransaction()

        XCTAssertEqual(OwnerObject.allObjects(in: realm).count, UInt(1), "Expecting 1 owner")
        XCTAssertEqual(DogObject.allObjects(in: realm).count, UInt(1), "Expecting 1 dog")

        realm.beginWriteTransaction()
        let fiel = OwnerObject.create(in: realm, withValue: ["Fiel", NSNull()])
        fiel.dog = owner.dog
        try! realm.commitWriteTransaction()

        XCTAssertEqual(OwnerObject.allObjects(in: realm).count, UInt(2), "Expecting 2 owners")
        XCTAssertEqual(DogObject.allObjects(in: realm).count, UInt(1), "Expecting 1 dog")
    }

    func testLinkRemoval_objc() {
        let realm = realmWithTestPath()

        let owner = OwnerObject()
        owner.name = "Tim"
        owner.dog = DogObject()
        owner.dog.dogName = "Harvie"

        realm.beginWriteTransaction()
        realm.add(owner)
        try! realm.commitWriteTransaction()

        XCTAssertEqual(OwnerObject.allObjects(in: realm).count, UInt(1), "Expecting 1 owner")
        XCTAssertEqual(DogObject.allObjects(in: realm).count, UInt(1), "Expecting 1 dog")

        realm.beginWriteTransaction()
        realm.delete(owner.dog)
        try! realm.commitWriteTransaction()

        XCTAssertNil(owner.dog, "Dog should be nullified when deleted")

        // refresh owner and check
        let owner2 = OwnerObject.allObjects(in: realm).firstObject() as! OwnerObject
        XCTAssertNotNil(owner2, "Should have 1 owner")
        XCTAssertNil(owner2.dog, "Dog should be nullified when deleted")
        XCTAssertEqual(DogObject.allObjects(in: realm).count, UInt(0), "Expecting 0 dogs")
    }

//    FIXME - disabled until we fix commit log issue which break transacions when leaking realm objects
//    func testCircularLinks_objc() {
//        let realm = realmWithTestPath()
//
//        let obj = CircleObject()
//        obj.data = "a"
//        obj.next = obj
//
//        realm.beginWriteTransaction()
//        realm.addObject(obj)
//        obj.next.data = "b"
//        try! realm.commitWriteTransaction()
//
//        let obj2 = CircleObject.allObjectsInRealm(realm).firstObject() as CircleObject
//        XCTAssertEqual(obj2.data, "b", "data should be 'b'")
//        XCTAssertEqual(obj2.data, obj2.next.data, "objects should be equal")
//    }
}
