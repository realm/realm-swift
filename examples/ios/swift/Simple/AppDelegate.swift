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
import Realm

class Dog: RLMObject {
    dynamic var name = ""
    dynamic var age = 0
}

class Person: RLMObject {
    dynamic var name = ""
    dynamic var dogs = RLMArray(objectClassName: Dog.className())
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: NSDictionary?) -> Bool {

        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window!.rootViewController = UIViewController()
        self.window!.makeKeyAndVisible()

        NSFileManager.defaultManager().removeItemAtPath(RLMRealm.defaultRealmPath(), error: nil)

        // Create a standalone object
        var mydog = Dog()

        // Set & read properties
        mydog.name = "Rex"
        mydog.age = 9
        println("Name of dog: \(mydog.name)")

        // Realms are used to group data together
        let realm = RLMRealm.defaultRealm() // Create realm pointing to default file

        // Save your object
        realm.beginWriteTransaction()
        realm.addObject(mydog)
        realm.commitWriteTransaction()

        // Query
        var results = Dog.objectsInRealm(realm, withPredicate: NSPredicate(format: "name contains 'x'"))

        // Queries are chainable!
        var results2 = results.objectsWithPredicate(NSPredicate(format: "age > 8"))
        println("Number of dogs: \(results.count)")

        // Link objects
        var person = Person()
        person.name = "Tim"
        person.dogs.addObject(mydog)

        realm.transactionWithBlock() {
            realm.addObject(person)
        }

        // Multi-threading
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let otherRealm = RLMRealm.defaultRealm()
            var otherResults = Dog.objectsInRealm(otherRealm, withPredicate: NSPredicate(format:"name contains 'Rex'"))
            println("Number of dogs \(otherResults.count)")
        }

        return true
    }
}
