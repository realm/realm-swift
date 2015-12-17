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

class PlacesViewController: UITableViewController, UITextFieldDelegate {
    @IBOutlet weak var searchField: UITextField!

    var results: Results<Place>?

    override func viewDidLoad() {
        super.viewDidLoad()


        let mainBundle = NSBundle.mainBundle()
        let seedFilePath = mainBundle.pathForResource("Places", ofType: "realm")

        let config = Realm.Configuration(readOnly: true, path: seedFilePath)

        Realm.Configuration.defaultConfiguration = config

        reloadData()
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results?.count ?? 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)

        let place = results![indexPath.row]

        cell.textLabel!.text = place.postalCode
        if let county = place.county {
            cell.detailTextLabel!.text = String(format: "%@, %@, %@", place.placeName!, place.state!, county)
        } else {
            cell.detailTextLabel!.text = String(format: "%@, %@", place.placeName!, place.state!)
        }

        return cell
    }

    func reloadData() {
        let realm = try! Realm()
        results = realm.objects(Place)
        if let text = searchField.text where !text.isEmpty {
            results = results?.filter("postalCode beginswith %@", text)
        }
        results = results?.sorted("postalCode")

        tableView?.reloadData()
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        reloadData()
    }
}
