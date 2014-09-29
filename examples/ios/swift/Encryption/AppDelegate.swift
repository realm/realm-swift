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

class StringObject: RLMObject {
    dynamic var stringProp = ""
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: NSDictionary?) -> Bool {

        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window!.rootViewController = UIViewController()
        self.window!.makeKeyAndVisible()

        // Realms are used to group data together
        let realm = RLMRealm.defaultRealm() // Create realm pointing to default file

        // Encrypt realm file
        var error: NSError?
        let success = NSFileManager.defaultManager().setAttributes([NSFileProtectionKey: NSFileProtectionComplete],
            ofItemAtPath: RLMRealm.defaultRealm().path, error: &error)
        if !success {
            println("encryption attribute was not successfully set on realm file")
            println("error: \(error?.localizedDescription)")
        }

        // Save your object
        realm.transactionWithBlock() {
            let obj = StringObject()
            obj.stringProp = "abcd"
            realm.addObject(obj)
        }

        // Read all string objects from the encrypted realm
        println("all string objects: \(StringObject.allObjects())")

        return true
    }
}
