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
        // The RealmFile_vx structs are used to create the .realm files which are then used by the app to showcase different migrations.
        // This line and the corresponding file for schema version x has to be uncommented to create the file.
        // One .realm file per schema version is already included in the project.
        // RealmFile.create()
        
        // Define a migration block.
        // You can define this inline, but we will reuse this to migrate realm files from multiple versions
        // to the most current version of our data model.
        let migrationBlock: MigrationBlock = createMigrationBlock()
        
        for realmName in RealmVersion.allVersions {
            
            let realmUrl = realmName.destinationUrl(clean: true)
            
            // migrate realms at realmv1Path manually, realmv2Path is migrated automatically on access
            let realmConfiguration = Realm.Configuration(fileURL: realmUrl, schemaVersion: 3, migrationBlock: migrationBlock)
            try! Realm.performMigration(for: realmConfiguration)

            // print out all migrated objects in the migrated realms
            let realm = try! Realm(configuration: realmConfiguration)
            print("Migrated objects in the Realm migrated from v1: \(realm.objects(Person.self))")
        }
    }
    
    static func createMigrationBlock() -> MigrationBlock {
        let migrationBlock: MigrationBlock = { migration, oldSchemaVersion in
            if oldSchemaVersion < 1 {
                migration.enumerateObjects(ofType: Person.className()) { oldObject, newObject in
                    // combine name fields into a single field
                    let firstName = oldObject!["firstName"] as! String
                    let lastName = oldObject!["lastName"] as! String
                    newObject?["fullName"] = "\(firstName) \(lastName)"
                }
            }
            if oldSchemaVersion < 2 {
                migration.enumerateObjects(ofType: Person.className()) { _, newObject in
                    // give JP a dog
                    if newObject?["fullName"] as? String == "John Smith" {
                        let jpsDog = migration.create(Pet.className(), value: ["Jimbo", "dog"])
                        let dogs = newObject?["pets"] as? List<MigrationObject>
                        dogs?.append(jpsDog)
                    }
                }
            }
            print("Migration complete.")
        }
        return migrationBlock
    }
    
}
