////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 Realm Inc.
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

class DemoObject: Object {
    @objc dynamic var uuid = UUID().uuidString
    @objc dynamic var date = NSDate()
    @objc dynamic var title = ""
}

/*
 For a more detailed example of SwiftUI List updating, see the ListSwiftUI example target.
 */
final class DemoObjects: Object {
    @objc var id = 0
    let list = RealmSwift.List<DemoObject>()

    override class func primaryKey() -> String? {
        "id"
    }
}
