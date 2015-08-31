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


class Dog: Object {
    dynamic var name = ""
    dynamic var age = 0
    var owners: [Person] {
        // Realm doesn't persist this property because it only has a getter defined
        // Define "owners" as the inverse relationship to Person.dogs
        return linkingObjects(Person.self, forProperty: "dogs")
    }
}

class Person: Object {
    dynamic var name = ""
    let dogs = List<Dog>()
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window?.rootViewController = UIViewController()
        window?.makeKeyAndVisible()

        do {
            try NSFileManager.defaultManager().removeItemAtPath(Realm.Configuration.defaultConfiguration.path!)
        } catch {}

        let realm = try! Realm()
        try! realm.write {
            realm.create(Person.self, value: ["John", [["Fido", 1]]])
            realm.create(Person.self, value: ["Mary", [["Rex", 2]]])
        }

        // Log all dogs and their owners using the "owners" inverse relationship
        let allDogs = realm.objects(Dog)
        for dog in allDogs {
            let ownerNames = dog.owners.map { $0.name }
            print("\(dog.name) has \(ownerNames.count) owners (\(ownerNames))")
        }
        return true
    }
}
