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

#if !swift(>=4.2)
extension UITableViewCell {
    typealias CellStyle = UITableViewCellStyle
    typealias EditingStyle = UITableViewCellEditingStyle
}
#endif

class DemoObject: Object {
    @objc dynamic var title = ""
    @objc dynamic var date = NSDate()
    @objc dynamic var sectionTitle = ""
}

class Cell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String!) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }

    required init(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
}

var sectionTitles = ["A", "B", "C"]
var objectsBySection = [Results<DemoObject>]()

class TableViewController: UITableViewController {

    var notificationToken: NotificationToken?
    var realm: Realm!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        realm = try! Realm()

        // Set realm notification block
        notificationToken = realm.observe { [unowned self] note, realm in
            self.tableView.reloadData()
        }
        for section in sectionTitles {
            let unsortedObjects = realm.objects(DemoObject.self).filter("sectionTitle == '\(section)'")
            let sortedObjects = unsortedObjects.sorted(byKeyPath: "date", ascending: true)
            objectsBySection.append(sortedObjects)
        }
        tableView.reloadData()
    }

    // UI

    func setupUI() {
        tableView.register(Cell.self, forCellReuseIdentifier: "cell")

        self.title = "GroupedTableView"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "BG Add", style: .plain, target: self, action: #selector(TableViewController.backgroundAdd))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(TableViewController.add))
    }

    // Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTitles.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objectsBySection[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! Cell

        let object = objectForIndexPath(indexPath: indexPath)
        cell.textLabel?.text = object?.title
        cell.detailTextLabel?.text = object?.date.description

        return cell
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            try! realm.write {
                realm.delete(objectForIndexPath(indexPath: indexPath)!)
            }
        }
    }

    // Actions

    @objc func backgroundAdd() {
        // Import many items in a background thread
        DispatchQueue.global().async {
            // Get new realm and table since we are in a new thread
            autoreleasepool {
                let realm = try! Realm()
                realm.beginWrite()
                for _ in 0..<5 {
                    // Add row via dictionary. Order is ignored.
                    realm.create(DemoObject.self, value: ["title": randomTitle(), "date": NSDate(), "sectionTitle": randomSectionTitle()])
                }
                try! realm.commitWrite()
            }
        }
    }

    @objc func add() {
        try! realm.write {
            realm.create(DemoObject.self, value: [randomTitle(), NSDate(), randomSectionTitle()])
        }
    }
}

// Helpers

func objectForIndexPath(indexPath: IndexPath) -> DemoObject? {
    return objectsBySection[indexPath.section][indexPath.row]
}

func randomTitle() -> String {
    return "Title \(arc4random())"
}

func randomSectionTitle() -> String {
    return sectionTitles[Int(arc4random()) % sectionTitles.count]
}
