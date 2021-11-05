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
    @Persisted var name: String
    @Persisted var age: Int
    // Define "owners" as the inverse relationship to Person.dogs
    @Persisted(originProperty: "dogs") var owners: LinkingObjects<Person>
}

class Person: Object {
    @Persisted var name: String
    @Persisted var dogs: List<Dog>
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UIViewController()
        window?.makeKeyAndVisible()

        _ = try! Realm.deleteFiles(for: Realm.Configuration.defaultConfiguration)

        let realm = try! Realm()
        try! realm.write {
            realm.create(Person.self, value: ["John", [["Fido", 1]]])
            realm.create(Person.self, value: ["Mary", [["Rex", 2]]])
        }

        // Log all dogs and their owners using the "owners" inverse relationship
        let allDogs = realm.objects(Dog.self)
        for dog in allDogs {
            let ownerNames = Array(dog.owners.map(\.name))
            print("\(dog.name) has \(ownerNames.count) owners (\(ownerNames))")
        }
        return true
    }
}
