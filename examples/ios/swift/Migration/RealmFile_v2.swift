//
//  v2Factory.swift
//  Migration
//
//  Created by Dominic Frei on 27/01/2021.
//  Copyright © 2021 Realm. All rights reserved.
//

import Foundation
import RealmSwift

// MAKR: - schema version 2

// Changes:
// add `pets` to the `Person` object
// add a `Pet` object

class Dog: Object {
    @objc dynamic var name = ""
}

class Person: Object {
    @objc dynamic var fullName = ""
    @objc dynamic var age = 0
    let dogs = List<Dog>()
}

struct RealmFile {
    
    static func create() {
        // Wipe old data
        let v2Url = RealmVersion.v2.destinationUrl(usingTemplate: false)
        
        // Create new data
        let person1 = Person(value: ["John Doe", 42])
        let person2 = Person(value: ["Jane Doe", 43])
        let person3 = Person(value: ["John Smith", 44])
        let pet1 = Dog(value: ["Marley"])
        let pet2 = Dog(value: ["Lassie"])
        let pet3 = Dog(value: ["Toto"])
        let pet4 = Dog(value: ["Slinkey"])
        
        Realm.Configuration.defaultConfiguration = Realm.Configuration(fileURL: v2Url, schemaVersion: 2)
        let realm = try! Realm()
        print("Realm created at \(String(describing: Realm.Configuration.defaultConfiguration.fileURL!))")
        try! realm.write {
            realm.add([person1, person2, person3])
            person1.dogs.append(pet1)
            person1.dogs.append(pet2)
            person2.dogs.append(pet3)
            person2.dogs.append(pet4)
        }
    }
    
}
