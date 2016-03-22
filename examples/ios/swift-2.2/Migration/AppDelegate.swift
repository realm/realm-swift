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
    dynamic var firstName = ""
    dynamic var lastName = ""
    dynamic var age = 0
}
*/

/* V1
class Person: Object {
    dynamic var fullName = ""        // combine firstName and lastName into single field
    dynamic var age = 0
}
*/

/* V2 */
class Pet: Object {
    dynamic var name = ""
    dynamic var type = ""
}

class Person: Object {
    dynamic var fullName = ""
    dynamic var age = 0
    let pets = List<Pet>() // Add pets field
}

func bundlePath(path: String) -> String? {
    let resourcePath = NSBundle.mainBundle().resourcePath as NSString?
    return resourcePath?.stringByAppendingPathComponent(path)
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window?.rootViewController = UIViewController()
        window?.makeKeyAndVisible()

        // copy over old data files for migration
        let defaultPath = Realm.Configuration.defaultConfiguration.path!
        let defaultParentPath = (defaultPath as NSString).stringByDeletingLastPathComponent

        if let v0Path = bundlePath("default-v0.realm") {
            do {
                try NSFileManager.defaultManager().removeItemAtPath(defaultPath)
                try NSFileManager.defaultManager().copyItemAtPath(v0Path, toPath: defaultPath)
            } catch {}
        }

        // define a migration block
        // you can define this inline, but we will reuse this to migrate realm files from multiple versions
        // to the most current version of our data model
        let migrationBlock: MigrationBlock = { migration, oldSchemaVersion in
            if oldSchemaVersion < 1 {
                migration.enumerate(Person.className()) { oldObject, newObject in
                    if oldSchemaVersion < 1 {
                        // combine name fields into a single field
                        let firstName = oldObject!["firstName"] as! String
                        let lastName = oldObject!["lastName"] as! String
                        newObject?["fullName"] = "\(firstName) \(lastName)"
                    }
                }
            }
            if oldSchemaVersion < 2 {
                migration.enumerate(Person.className()) { oldObject, newObject in
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
        print("Migrated objects in the default Realm: \(try! Realm().objects(Person))")

        //
        // Migrate a realms at a custom paths
        //
        if let v1Path = bundlePath("default-v1.realm"), v2Path = bundlePath("default-v2.realm") {
            let realmv1Path = (defaultParentPath as NSString).stringByAppendingPathComponent("default-v1.realm")
            let realmv2Path = (defaultParentPath as NSString).stringByAppendingPathComponent("default-v2.realm")

            let realmv1Configuration = Realm.Configuration(path: realmv1Path, schemaVersion: 3, migrationBlock: migrationBlock)
            let realmv2Configuration = Realm.Configuration(path: realmv2Path, schemaVersion: 3, migrationBlock: migrationBlock)

            do {
                try NSFileManager.defaultManager().removeItemAtPath(realmv1Path)
                try NSFileManager.defaultManager().copyItemAtPath(v1Path, toPath: realmv1Path)
                try NSFileManager.defaultManager().removeItemAtPath(realmv2Path)
                try NSFileManager.defaultManager().copyItemAtPath(v2Path, toPath: realmv2Path)
            } catch {}

            // migrate realms at realmv1Path manually, realmv2Path is migrated automatically on access
            migrateRealm(realmv1Configuration)

            // print out all migrated objects in the migrated realms
            let realmv1 = try! Realm(configuration: realmv1Configuration)
            print("Migrated objects in the Realm migrated from v1: \(realmv1.objects(Person))")
            let realmv2 = try! Realm(configuration: realmv2Configuration)
            print("Migrated objects in the Realm migrated from v2: \(realmv2.objects(Person))")
        }

        return true
    }
}
