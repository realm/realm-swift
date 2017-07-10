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

class Place: Object {
    @objc dynamic var postalCode: String?
    @objc dynamic var placeName: String?
    @objc dynamic var state: String?
    @objc dynamic var stateAbbreviation: String?
    @objc dynamic var county: String?
    @objc dynamic var latitude = 0.0
    @objc dynamic var longitude = 0.0
}
