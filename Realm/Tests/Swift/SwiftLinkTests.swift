//
//  SwiftLinkTests.swift
//  RealmSwift
//
//  Created by JP Simard on 6/16/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

import XCTest

class SwiftLinkTests: RLMTestCase {
    
    func testBasicLink() {
        let realm = realmWithTestPath()
        
        let owner = OwnerObject()
        owner.name = "Tim"
        owner.dog = DogObject()
        owner.dog.dogName = "Harvie"
        
        realm.beginWriteTransaction()
        realm.addObject(owner)
        realm.commitWriteTransaction()
        
        let owners = realm.objects(OwnerObject.className(), `where`: nil)
        let dogs = realm.objects(DogObject.className(), `where`: nil)
        XCTAssertEqual(owners.count, 1, "Expecting 1 owner")
        XCTAssertEqual(dogs.count, 1, "Expecting 1 dog")
        XCTAssertEqualObjects((owners[0] as OwnerObject).name, "Tim", "Tim is named Tim")
        XCTAssertEqualObjects((dogs[0] as DogObject).dogName, "Harvie", "Harvie is named Harvie")
        
        let tim = owners[0] as OwnerObject
        XCTAssertEqualObjects(tim.dog.dogName, "Harvie", "Tim's dog should be Harvie")
    }
    
    func testMultipleOwnerLink() {
        let realm = realmWithTestPath()
        
        let owner = OwnerObject()
        owner.name = "Tim"
        owner.dog = DogObject()
        owner.dog.dogName = "Harvie"
        
        realm.beginWriteTransaction()
        realm.addObject(owner)
        realm.commitWriteTransaction()
        
        XCTAssertEqual(realm.objects(OwnerObject.className(), `where`: nil).count, 1, "Expecting 1 owner")
        XCTAssertEqual(realm.objects(DogObject.className(), `where`: nil).count, 1, "Expecting 1 dog")
        
        realm.beginWriteTransaction()
        let fiel = OwnerObject.createInRealm(realm, withObject: ["Fiel", NSNull()])
        fiel.dog = owner.dog
        realm.commitWriteTransaction()
        
        XCTAssertEqual(realm.objects(OwnerObject.className(), `where`: nil).count, 2, "Expecting 2 owners")
        XCTAssertEqual(realm.objects(DogObject.className(), `where`: nil).count, 1, "Expecting 1 dog")
    }
    
    func testLinkRemoval() {
        let realm = realmWithTestPath()
        
        let owner = OwnerObject()
        owner.name = "Tim"
        owner.dog = DogObject()
        owner.dog.dogName = "Harvie"
        
        realm.beginWriteTransaction()
        realm.addObject(owner)
        realm.commitWriteTransaction()
        
        XCTAssertEqual(realm.objects(OwnerObject.className(), `where`: nil).count, 1, "Expecting 1 owner")
        XCTAssertEqual(realm.objects(DogObject.className(), `where`: nil).count, 1, "Expecting 1 dog")
        
        realm.beginWriteTransaction()
        realm.deleteObject(owner.dog)
        realm.commitWriteTransaction()
        
        XCTAssertNil(owner.dog, "Dog should be nullified when deleted")
        
        // refresh owner and check
        let owner2 = realm.allObjects(OwnerObject.className()).firstObject
        XCTAssertNotNil(owner, "Should have 1 owner")
        XCTAssertNil(owner.dog, "Dog should be nullified when deleted")
        XCTAssertEqual(realm.objects(DogObject.className(), `where`: nil).count, 0, "Expecting 0 dogs")
    }
    
    // Note: can't test testInvalidLinks() as Swift doesn't have exception handling
    
    func testCircularLinks() {
        let realm = realmWithTestPath()
        
        let obj = CircleObject()
        obj.data = "a"
        obj.next = obj
        
        realm.beginWriteTransaction()
        realm.addObject(obj)
        obj.next.data = "b"
        realm.commitWriteTransaction()
        
        let obj2 = realm.allObjects(CircleObject.className()).firstObject() as CircleObject
        XCTAssertEqualObjects(obj2.data, "b", "data should be 'b'")
        XCTAssertEqualObjects(obj2.data, obj2.next.data, "objects should be equal")
    }
}
