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

class DemoObject: Object {
    @Persisted var phoneNumber: String
    @Persisted var date: Date
    @Persisted var contactName: String
    var firstLetter: String {
        guard let char = contactName.first else {
            return ""
        }
        return String(char)
    }
}

class Cell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String!) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }

    required init(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
}

class TableViewController: UITableViewController {
    var notificationToken: NotificationToken?
    var realm: Realm!
    var sectionedResults: SectionedResults<String, DemoObject>!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        realm = try! Realm()
        sectionedResults = realm.objects(DemoObject.self)
            .sectioned(by: \.firstLetter, ascending: true)

        // Set realm notification block
        notificationToken = sectionedResults.observe { change in
            switch change {
            case .initial:
                break
            case let .update(_,
                             deletions: deletions,
                             insertions: insertions,
                             modifications: modifications,
                             sectionsToInsert: sectionsToInsert,
                             sectionsToDelete: sectionsToDelete):
                self.tableView.performBatchUpdates {
                    self.tableView.deleteRows(at: deletions, with: .automatic)
                    self.tableView.insertRows(at: insertions, with: .automatic)
                    self.tableView.reloadRows(at: modifications, with: .automatic)
                    self.tableView.insertSections(sectionsToInsert, with: .automatic)
                    self.tableView.deleteSections(sectionsToDelete, with: .automatic)
                }
            }
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
        return sectionedResults.count
    }

    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return sectionedResults.allKeys
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionedResults[section].key
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionedResults[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! Cell

        let object = sectionedResults[indexPath]
        cell.textLabel?.text = "\(object.contactName): \(object.phoneNumber)"
        cell.detailTextLabel?.text = object.date.description

        return cell
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            try! realm.write {
                realm.delete(sectionedResults[indexPath])
            }
        }
    }

    // MARK: Actions

    @objc func backgroundAdd() {
        // Import many items in a background thread
        DispatchQueue.global().async {
            // Get new realm and table since we are in a new thread
            autoreleasepool {
                let realm = try! Realm()
                realm.beginWrite()
                for _ in 0..<5 {
                    // Add row via dictionary. Order is ignored.
                    realm.create(DemoObject.self, value: ["contactName": randomName(), "date": NSDate(), "phoneNumber": randomPhoneNumber()])
                }
                try! realm.commitWrite()
            }
        }
    }

    @objc func add() {
        try! realm.write {
            realm.create(DemoObject.self, value: ["contactName": randomName(), "date": NSDate(), "phoneNumber": randomPhoneNumber()])
        }
    }
}

// MARK: Helpers

func randomPhoneNumber() -> String {
    return "555-55\(Int.random(in: 0...9))5-55\(Int.random(in: 0...9))"
}

func randomName() -> String {
    return ["John", "Jane", "Mary", "Eric", "Sarah", "Sally"].randomElement()!
}
