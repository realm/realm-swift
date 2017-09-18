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
import WatchKit
import RealmSwift

class Counter: Object {
    dynamic var count = 0
}

class InterfaceController: WKInterfaceController {
    @IBOutlet var button: WKInterfaceButton!
    let counter: Counter
    var token: NotificationToken! = nil

    override init() {
        counter = Counter()
        super.init()
        let realm = try! Realm()
        try! realm.write {
            realm.add(counter)
        }
    }

    @IBAction func increment() {
        try! counter.realm!.write { counter.count += 1 }
    }

    override func willActivate() {
        super.willActivate()
        token = counter.realm!.observe { [unowned self] _, _ in
            self.button.setTitle("\(self.counter.count)")
        }
    }

    override func didDeactivate() {
        token.invalidate()
        super.didDeactivate()
    }
}
