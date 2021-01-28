//
//  Migration.swift
//  Migration
//
//  Created by Dominic Frei on 28/01/2021.
//  Copyright © 2021 Realm. All rights reserved.
//

import Foundation
import RealmSwift

struct MigrationExample {
    
    static func execute() {        
        // Define a migration block.
        // You can define this inline, but we will reuse this to migrate realm files from multiple versions
        // to the most current version of our data model.
        let migrationBlock = createMigrationBlock()
        
        for realmVersion in RealmVersion.allVersions {
            let realmUrl = realmVersion.destinationUrl(usingTemplate: true)
            let realmConfiguration = Realm.Configuration(fileURL: realmUrl, schemaVersion: 3, migrationBlock: migrationBlock)
            try! Realm.performMigration(for: realmConfiguration)
        }
    }
    
    static func createMigrationBlock() -> MigrationBlock {
        let migrationBlock: MigrationBlock = { migration, oldSchemaVersion in
            if oldSchemaVersion < 1 {
                migration.enumerateObjects(ofType: Person.className()) { oldObject, newObject in
                    // combine name fields into a single field
                    let firstName = oldObject!["firstName"] as! String
                    let lastName = oldObject!["lastName"] as! String
                    newObject!["fullName"] = "\(firstName) \(lastName)"
                }
            }
            if oldSchemaVersion < 2 {
                migration.enumerateObjects(ofType: Person.className()) { _, newObject in
                    // Add a pet to a specific person
                    if newObject!["fullName"] as! String == "John Smith" {
                        let johnsDog = migration.create(Dog.className(), value: ["Jimbo"])
                        let dogs = newObject!["dogs"] as! List<MigrationObject>
                        dogs.append(johnsDog)
                    }
                }
            }
        }
        return migrationBlock
    }
    
}
