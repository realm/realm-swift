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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UIViewController()
        window?.makeKeyAndVisible()

        #if CREATE_EXAMPLES
        addExampleDataToRealm(exampleData)
        #else
        performMigration()
        #endif

        return true
    }

    private func addExampleDataToRealm(_ exampleData: (Realm) -> Void) {
        let url = realmUrl(for: schemaVersion, usingTemplate: false)
        let configuration = Realm.Configuration(fileURL: url, schemaVersion: UInt64(schemaVersion))
        let realm = try! Realm(configuration: configuration)

        try! realm.write {
            exampleData(realm)
        }
    }

    // Any version before the current versions will be migrated to check if all version combinations work.
    private func performMigration() {
        for oldSchemaVersion in 0..<schemaVersion {
            let url = realmUrl(for: oldSchemaVersion, usingTemplate: true)
            let realmConfiguration = Realm.Configuration(fileURL: url, schemaVersion: UInt64(schemaVersion), migrationBlock: migrationBlock)
            try! Realm.performMigration(for: realmConfiguration)
            let realm = try! Realm(configuration: realmConfiguration)
            migrationCheck(realm)
        }
    }

    private func realmUrl(for schemaVersion: Int, usingTemplate: Bool) -> URL {
        let defaultURL = Realm.Configuration.defaultConfiguration.fileURL!
        let defaultParentURL = defaultURL.deletingLastPathComponent()
        let fileName = "default-v\(schemaVersion)"
        let destinationUrl = defaultParentURL.appendingPathComponent(fileName + ".realm")
        if FileManager.default.fileExists(atPath: destinationUrl.path) {
            try! FileManager.default.removeItem(at: destinationUrl)
        }
        if usingTemplate {
            let bundleUrl = Bundle.main.url(forResource: fileName, withExtension: "realm")!
            try! FileManager.default.copyItem(at: bundleUrl, to: destinationUrl)
        }

        return destinationUrl
    }
}
