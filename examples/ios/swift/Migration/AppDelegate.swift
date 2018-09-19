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

// Old data models
/* V0
class Person: Object {
    @objc dynamic var firstName = ""
    @objc dynamic var lastName = ""
    @objc dynamic var age = 0
}
*/

/* V1
class Person: Object {
    @objc dynamic var fullName = ""        // combine firstName and lastName into single field
    @objc dynamic var age = 0
}
*/

/* V2 */
class Pet: Object {
    @objc dynamic var name = ""
    @objc dynamic var type = ""
}

class Person: Object {
    @objc dynamic var fullName = ""
    @objc dynamic var age = 0
    let pets = List<Pet>() // Add pets field
}

func bundleURL(_ name: String) -> URL? {
    return Bundle.main.url(forResource: name, withExtension: "realm")
}

#if !swift(>=4.2)
extension UIApplication {
    typealias LaunchOptionsKey = UIApplicationLaunchOptionsKey
}
#endif

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UIViewController()
        window?.makeKeyAndVisible()

        // copy over old data files for migration
        let defaultURL = Realm.Configuration.defaultConfiguration.fileURL!
        let defaultParentURL = defaultURL.deletingLastPathComponent()

        if let v0URL = bundleURL("default-v0") {
            do {
                try FileManager.default.removeItem(at: defaultURL)
                try FileManager.default.copyItem(at: v0URL, to: defaultURL)
            } catch {}
        }

        // define a migration block
        // you can define this inline, but we will reuse this to migrate realm files from multiple versions
        // to the most current version of our data model
        let migrationBlock: MigrationBlock = { migration, oldSchemaVersion in
            if oldSchemaVersion < 1 {
                migration.enumerateObjects(ofType: Person.className()) { oldObject, newObject in
                    if oldSchemaVersion < 1 {
                        // combine name fields into a single field
                        let firstName = oldObject!["firstName"] as! String
                        let lastName = oldObject!["lastName"] as! String
                        newObject?["fullName"] = "\(firstName) \(lastName)"
                    }
                }
            }
            if oldSchemaVersion < 2 {
                migration.enumerateObjects(ofType: Person.className()) { oldObject, newObject in
                    // give JP a dog
                    if newObject?["fullName"] as? String == "JP McDonald" {
                        let jpsDog = migration.create(Pet.className(), value: ["Jimbo", "dog"])
                        let dogs = newObject?["pets"] as? List<MigrationObject>
                        dogs?.append(jpsDog)
                    }
                }
            }
            print("Migration complete.")
        }

        Realm.Configuration.defaultConfiguration = Realm.Configuration(schemaVersion: 3, migrationBlock: migrationBlock)

        // print out all migrated objects in the default realm
        // migration is performed implicitly on Realm access
        print("Migrated objects in the default Realm: \(try! Realm().objects(Person.self))")

        //
        // Migrate a realms at a custom paths
        //
        if let v1URL = bundleURL("default-v1"), let v2URL = bundleURL("default-v2") {
            let realmv1URL = defaultParentURL.appendingPathComponent("default-v1.realm")
            let realmv2URL = defaultParentURL.appendingPathComponent("default-v2.realm")

            let realmv1Configuration = Realm.Configuration(fileURL: realmv1URL, schemaVersion: 2, migrationBlock: migrationBlock)
            let realmv2Configuration = Realm.Configuration(fileURL: realmv2URL, schemaVersion: 3, migrationBlock: migrationBlock)

            do {
                try FileManager.default.removeItem(at: realmv1URL)
                try FileManager.default.copyItem(at: v1URL, to: realmv1URL)
                try FileManager.default.removeItem(at: realmv2URL)
                try FileManager.default.copyItem(at: v2URL, to: realmv2URL)
            } catch {}

            // migrate realms at realmv1Path manually, realmv2Path is migrated automatically on access
            try! Realm.performMigration(for: realmv1Configuration)

            // print out all migrated objects in the migrated realms
            let realmv1 = try! Realm(configuration: realmv1Configuration)
            print("Migrated objects in the Realm migrated from v1: \(realmv1.objects(Person.self))")
            let realmv2 = try! Realm(configuration: realmv2Configuration)
            print("Migrated objects in the Realm migrated from v2: \(realmv2.objects(Person.self))")
        }

        return true
    }
}
