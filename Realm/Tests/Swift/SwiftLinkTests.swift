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
import TestFramework

class SwiftLinkTests: SwiftTestCase {

    // Swift models
    
    func testBasicLink() {
        let realm = realmWithTestPath()
        
        let owner = SwiftOwnerObject()
        owner.name = "Tim"
        owner.dog = SwiftDogObject()
        owner.dog.dogName = "Harvie"
        
        realm.beginWriteTransaction()
        realm.addObject(owner)
        realm.commitWriteTransaction()
        
        let owners = realm.objects(SwiftOwnerObject())
        let dogs = realm.objects(SwiftDogObject())
        XCTAssertEqual(owners.count, 1, "Expecting 1 owner")
        XCTAssertEqual(dogs.count, 1, "Expecting 1 dog")
        XCTAssertEqual(owners[0].name, "Tim", "Tim is named Tim")
        XCTAssertEqual(dogs[0].dogName, "Harvie", "Harvie is named Harvie")
        
        let tim = owners[0]
        XCTAssertEqual(tim.dog.dogName, "Harvie", "Tim's dog should be Harvie")
    }
    
    func testMultipleOwnerLink() {
        let realm = realmWithTestPath()
        
        let owner = SwiftOwnerObject()
        owner.name = "Tim"
        owner.dog = SwiftDogObject()
        owner.dog.dogName = "Harvie"
        
        realm.beginWriteTransaction()
        realm.addObject(owner)
        realm.commitWriteTransaction()
        
        XCTAssertEqual(realm.objects(SwiftOwnerObject()).count, 1, "Expecting 1 owner")
        XCTAssertEqual(realm.objects(SwiftDogObject()).count, 1, "Expecting 1 dog")
        
        realm.beginWriteTransaction()
        let fiel = SwiftOwnerObject.createInRealm(realm, withObject: ["Fiel", NSNull()])
        fiel.dog = owner.dog
        realm.commitWriteTransaction()
        
        XCTAssertEqual(realm.objects(SwiftOwnerObject()).count, 2, "Expecting 2 owners")
        XCTAssertEqual(realm.objects(SwiftDogObject()).count, 1, "Expecting 1 dog")
    }

    func testLinkRemoval() {
        let realm = realmWithTestPath()
        
        let owner = SwiftOwnerObject()
        owner.name = "Tim"
        owner.dog = SwiftDogObject()
        owner.dog.dogName = "Harvie"
        
        realm.beginWriteTransaction()
        realm.addObject(owner)
        realm.commitWriteTransaction()
        
        XCTAssertEqual(realm.objects(SwiftOwnerObject()).count, 1, "Expecting 1 owner")
        XCTAssertEqual(realm.objects(SwiftDogObject()).count, 1, "Expecting 1 dog")
        
        realm.beginWriteTransaction()
        realm.deleteObject(owner.dog)
        realm.commitWriteTransaction()
        
        XCTAssertNil(owner.dog, "Dog should be nullified when deleted")
        
        // refresh owner and check
        let owner2 = realm.objects(SwiftOwnerObject()).firstObject
        XCTAssertNotNil(owner, "Should have 1 owner")
        XCTAssertNil(owner.dog, "Dog should be nullified when deleted")
        XCTAssertEqual(realm.objects(SwiftDogObject()).count, 0, "Expecting 0 dogs")
    }

//    FIXME - disabled until we fix commit log issue which break transacions when leaking realm objects
//    func testCircularLinks() {
//        let realm = realmWithTestPath()
//        
//        let obj = SwiftCircleObject()
//        obj.data = "a"
//        obj.next = obj
//        
//        realm.beginWriteTransaction()
//        realm.addObject(obj)
//        obj.next.data = "b"
//        realm.commitWriteTransaction()
//        
//        let obj2 = SwiftCircleObject.allObjectsInRealm(realm).firstObject() as SwiftCircleObject
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
        realm.addObject(owner)
        realm.commitWriteTransaction()

        let owners = realm.objects(OwnerObject())
        let dogs = realm.objects(DogObject())
        XCTAssertEqual(owners.count, 1, "Expecting 1 owner")
        XCTAssertEqual(dogs.count, 1, "Expecting 1 dog")
        XCTAssertEqual(owners[0].name!, "Tim", "Tim is named Tim")
        XCTAssertEqual(dogs[0].dogName!, "Harvie", "Harvie is named Harvie")

        let tim = owners[0]
        XCTAssertEqual(tim.dog.dogName!, "Harvie", "Tim's dog should be Harvie")
    }

    func testMultipleOwnerLink_objc() {
        let realm = realmWithTestPath()

        let owner = OwnerObject()
        owner.name = "Tim"
        owner.dog = DogObject()
        owner.dog.dogName = "Harvie"

        realm.beginWriteTransaction()
        realm.addObject(owner)
        realm.commitWriteTransaction()

        XCTAssertEqual(realm.objects(OwnerObject()).count, 1, "Expecting 1 owner")
        XCTAssertEqual(realm.objects(DogObject()).count, 1, "Expecting 1 dog")

        realm.beginWriteTransaction()
        let fiel = OwnerObject.createInRealm(realm, withObject: ["Fiel", NSNull()])
        fiel.dog = owner.dog
        realm.commitWriteTransaction()

        XCTAssertEqual(realm.objects(OwnerObject()).count, 2, "Expecting 2 owners")
        XCTAssertEqual(realm.objects(DogObject()).count, 1, "Expecting 1 dog")
    }

    func testLinkRemoval_objc() {
        let realm = realmWithTestPath()

        let owner = OwnerObject()
        owner.name = "Tim"
        owner.dog = DogObject()
        owner.dog.dogName = "Harvie"

        realm.beginWriteTransaction()
        realm.addObject(owner)
        realm.commitWriteTransaction()

        XCTAssertEqual(realm.objects(OwnerObject()).count, 1, "Expecting 1 owner")
        XCTAssertEqual(realm.objects(DogObject()).count, 1, "Expecting 1 dog")

        realm.beginWriteTransaction()
        realm.deleteObject(owner.dog)
        realm.commitWriteTransaction()

        XCTAssertNil(owner.dog, "Dog should be nullified when deleted")

        // refresh owner and check
        let owner2 = realm.objects(OwnerObject()).firstObject
        XCTAssertNotNil(owner, "Should have 1 owner")
        XCTAssertNil(owner.dog, "Dog should be nullified when deleted")
        XCTAssertEqual(realm.objects(DogObject()).count, 0, "Expecting 0 dogs")
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
//        realm.commitWriteTransaction()
//
//        let obj2 = CircleObject.allObjectsInRealm(realm).firstObject() as CircleObject
//        XCTAssertEqual(obj2.data, "b", "data should be 'b'")
//        XCTAssertEqual(obj2.data, obj2.next.data, "objects should be equal")
//    }
}
