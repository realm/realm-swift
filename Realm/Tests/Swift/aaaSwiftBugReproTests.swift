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
import XCTest
import Realm

class Cover: RLMObject {

    // MARK: repro note: works with fewer / smaller member variables
    dynamic var a = ""
    dynamic var b = ""
    dynamic var c = ""
    dynamic var d = ""
    dynamic var e = ""
    dynamic var f = ""
    dynamic var g = ""
    dynamic var h = ""

    dynamic var i = ""

    // MARK: repro note: works without the primaryKey function
    override class func primaryKey() -> String! {
        return "i"
    }
}

class Notebook: RLMObject {

    dynamic var i = ""
    dynamic var cover = Cover()

    override class func primaryKey() -> String! {
        return "i"
    }
}

class aaaSwiftBugReproTests: XCTestCase {

    func test1() {
        // Delete the Realm db
        NSFileManager.defaultManager().removeItemAtPath(RLMRealm.defaultRealmPath(), error: nil)

        println(RLMRealm.defaultRealm().path)

        let n1 = Notebook()
        let realm = RLMRealm.defaultRealm()
        realm.beginWriteTransaction()

        // MARK: repro note: works with addObject, but not addOrUpdateObject (uses index)
        realm.addOrUpdateObject(n1) // does not work
        //        realm.addObject(n1) // works
        realm.commitWriteTransaction()
    }
}
