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

        let seedFileURL = Bundle.main.url(forResource: "Places", withExtension: "realm")
        let config = Realm.Configuration(kind: .file(seedFileURL!), readOnly: true)
        Realm.Configuration.defaultConfiguration = config

        reloadData()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let place = results![indexPath.row]

        cell.textLabel!.text = place.postalCode
        cell.detailTextLabel!.text = "\(place.placeName!), \(place.state!)"
        if let county = place.county {
            cell.detailTextLabel!.text = cell.detailTextLabel!.text! + ", \(county)"
        }
        return cell
    }

    func reloadData() {
        let realm = try! Realm()
        results = realm.objects(Place.self)
        if let text = searchField.text, !text.isEmpty {
            results = results?.filter("postalCode beginswith %@", text)
        }
        results = results?.sorted(byKeyPath: "postalCode")

        tableView?.reloadData()
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        reloadData()
    }
}
