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

        // Create a standalone object
        let mydog = Dog()

        // Set & read properties
        mydog.name = "Rex"
        mydog.age = 9
        print("Name of dog: \(mydog.name)")

        // Realms are used to group data together
        let realm = try! Realm() // Create realm pointing to default file

        // Save your object
        realm.beginWrite()
        realm.add(mydog)
        try! realm.commitWrite()

        // Query
        let results = realm.objects(Dog).filter(NSPredicate(format:"name contains 'x'"))

        // Queries are chainable!
        let results2 = results.filter("age > 8")
        print("Number of dogs: \(results.count)")
        print("Dogs older than eight: \(results2.count)")

        // Link objects
        let person = Person()
        person.name = "Tim"
        person.dogs.append(mydog)

        try! realm.write {
            realm.add(person)
        }

        // Multi-threading
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let otherRealm = try! Realm()
            let otherResults = otherRealm.objects(Dog).filter(NSPredicate(format:"name contains 'Rex'"))
            print("Number of dogs \(otherResults.count)")
        }

        return true
    }
}
