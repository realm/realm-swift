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

import UIKit
import RealmSwift

#if !swift(>=4.2)
extension UIApplication {
    typealias LaunchOptionsKey = UIApplicationLaunchOptionsKey
}
#endif

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UIViewController()
        window?.makeKeyAndVisible()
        
        // The RealmFile_vx structs are used to create the .realm files which are then used by the app to showcase different migrations.
        // This line and the corresponding file for schema version x has to be uncommented to create the file.
        // One .realm file per schema version is already included in the project.
        // RealmFile.create()
        
        // Define a migration block.
        // You can define this inline, but we will reuse this to migrate realm files from multiple versions
        // to the most current version of our data model.
        let migrationBlock: MigrationBlock = createMigrationBlock()
        
        for realmName in RealmNames.allCases {
            
            guard let url = bundleURL(fielName: realmName.rawValue, fileExtension: "realm") else {
                print("Default files for path \(realmName.rawValue) could not be found.")
                return false
            }
            let defaultURL = Realm.Configuration.defaultConfiguration.fileURL!
            let defaultParentURL = defaultURL.deletingLastPathComponent()
            let realmUrl = defaultParentURL.appendingPathComponent(realmName.rawValue + ".realm")
            do {
                try FileManager.default.removeItem(at: realmUrl)
                try FileManager.default.copyItem(at: url, to: realmUrl)
            } catch let error {
                print(String(describing: error))
            }

            // migrate realms at realmv1Path manually, realmv2Path is migrated automatically on access
            let realmConfiguration = Realm.Configuration(fileURL: realmUrl, schemaVersion: 3, migrationBlock: migrationBlock)
            try! Realm.performMigration(for: realmConfiguration)

            // print out all migrated objects in the migrated realms
            let realm = try! Realm(configuration: realmConfiguration)
            print("Migrated objects in the Realm migrated from v1: \(realm.objects(Person.self))")
        }
        
        return true
    }
    
    func bundleURL(fielName: String, fileExtension: String) -> URL? {
        return Bundle.main.url(forResource: fielName, withExtension: fileExtension)
    }
    
    func createMigrationBlock() -> MigrationBlock {
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
