//
//  v1Factory.swift
//  Migration
//
//  Created by Dominic Frei on 27/01/2021.
//  Copyright © 2021 Realm. All rights reserved.
//

import Foundation
import RealmSwift

// MAKR: - schema version 1

// Changes:
// - combine `firstName` and `lastName` into `fullName`

//class Person: Object {
//    @objc dynamic var fullName = ""
//    @objc dynamic var age = 0
//}
//
//struct RealmFile {
//
//    static func create() {
//        // Wipe old data
//        let v1Url = RealmNames.v1.url(clean: true)
//
//        // Create new data
//        let person1 = Person(value: ["John Doe", 42])
//        let person2 = Person(value: ["Jane Doe", 43])
//        let person3 = Person(value: ["John Smith", 44])
//
//        Realm.Configuration.defaultConfiguration = Realm.Configuration(fileURL: v1Url, schemaVersion: 1)
//        let realm = try! Realm()
//        print("Realm created at \(String(describing: Realm.Configuration.defaultConfiguration.fileURL!))")
//        try! realm.write {
//            realm.add([person1, person2, person3])
//        }
//    }
//
//}
