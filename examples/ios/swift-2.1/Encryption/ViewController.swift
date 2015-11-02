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

import Foundation
import RealmSwift
import Security
import UIKit

// Model definition
class EncryptionObject: Object {
    dynamic var stringProp = ""
}

class ViewController: UIViewController {
    let textView = UITextView(frame: UIScreen.mainScreen().applicationFrame)

    // Create a view to display output in
    override func loadView() {
        super.loadView()
        view.addSubview(textView)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        // Use an autorelease pool to close the Realm at the end of the block, so
        // that we can try to reopen it with different keys
        autoreleasepool {
            let configuration = Realm.Configuration(encryptionKey: getKey())
            let realm = try! Realm(configuration: configuration)

            // Add an object
            try! realm.write {
                let obj = EncryptionObject()
                obj.stringProp = "abcd"
                realm.add(obj)
            }
        }

        // Opening with wrong key fails since it decrypts to the wrong thing
        autoreleasepool {
            do {
                let configuration = Realm.Configuration(encryptionKey: "1234567890123456789012345678901234567890123456789012345678901234".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false))
                _ = try Realm(configuration: configuration)
            } catch {
                log("Open with wrong key: \(error)")
            }
        }

        // Opening wihout supplying a key at all fails
        autoreleasepool {
            do {
                _ = try Realm(path: Realm.Configuration.defaultConfiguration.path!)
            } catch {
                log("Open with no key: \(error)")
            }
        }

        // Reopening with the correct key works and can read the data
        autoreleasepool {
            let configuration = Realm.Configuration(encryptionKey: getKey())
            let realm = try! Realm(configuration: configuration)
            if let stringProp = realm.objects(EncryptionObject).first?.stringProp {
                log("Saved object: \(stringProp)")
            }
        }
    }

    func log(text: String) {
        textView.text = textView.text + text + "\n\n"
    }

    func getKey() -> NSData {
        // Identifier for our keychain entry - should be unique for your application
        let keychainIdentifier = "io.Realm.EncryptionExampleKey"
        let keychainIdentifierData = keychainIdentifier.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!

        // First check in the keychain for an existing key
        var query: [NSString: AnyObject] = [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: keychainIdentifierData,
            kSecAttrKeySizeInBits: 512,
            kSecReturnData: true
        ]

        // To avoid Swift optimization bug, should use withUnsafeMutablePointer() function to retrieve the keychain item
        // See also: http://stackoverflow.com/questions/24145838/querying-ios-keychain-using-swift/27721328#27721328
        var dataTypeRef: AnyObject?
        var status = withUnsafeMutablePointer(&dataTypeRef) { SecItemCopyMatching(query, UnsafeMutablePointer($0)) }
        if status == errSecSuccess {
            return dataTypeRef as! NSData
        }

        // No pre-existing key from this application, so generate a new one
        let keyData = NSMutableData(length: 64)!
        let result = SecRandomCopyBytes(kSecRandomDefault, 64, UnsafeMutablePointer<UInt8>(keyData.mutableBytes))
        assert(result == 0, "Failed to get random bytes")

        // Store the key in the keychain
        query = [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: keychainIdentifierData,
            kSecAttrKeySizeInBits: 512,
            kSecValueData: keyData
        ]

        status = SecItemAdd(query, nil)
        assert(status == errSecSuccess, "Failed to insert the new key in the keychain")

        return keyData
    }
}
