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
import Realm

class DemoObject: RLMObject {
    dynamic var title = ""
    dynamic var date = NSDate()
    dynamic var sectionTitle = ""
}

class Cell: UITableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String!) {
        super.init(style: .Subtitle, reuseIdentifier: reuseIdentifier)
    }

    required init(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
}

var sectionTitles = ["A", "B", "C"]
var objectsBySection = [RLMResults]()

class TableViewController: UITableViewController {

    var notificationToken: RLMNotificationToken?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()

        // Set realm notification block
        notificationToken = RLMRealm.defaultRealm().addNotificationBlock { note, realm in
            self.tableView.reloadData()
        }
        for section in sectionTitles {
            let unsortedObjects = DemoObject.objectsWhere("sectionTitle == '\(section)'")
            let sortedObjects = unsortedObjects.sortedResultsUsingProperty("date", ascending: true)
            objectsBySection.append(sortedObjects)
        }
        tableView.reloadData()
    }

    // UI

    func setupUI() {
        tableView.registerClass(Cell.self, forCellReuseIdentifier: "cell")

        self.title = "GroupedTableView"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "BG Add", style: .Plain, target: self, action: "backgroundAdd")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "add")
    }

    // Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sectionTitles.count
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }

    override func tableView(tableView: UITableView?, numberOfRowsInSection section: Int) -> Int {
        return Int(objectsBySection[section].count)
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as Cell

        let object = objectForIndexPath(indexPath)!
        cell.textLabel?.text = object.title
        cell.detailTextLabel?.text = object.date.description

        return cell
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let realm = RLMRealm.defaultRealm()
            realm.transactionWithBlock {
                realm.deleteObject(objectForIndexPath(indexPath)!)
            }
        }
    }

    // Actions

    func backgroundAdd() {
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        // Import many items in a background thread
        dispatch_async(queue) {
            // Get new realm and table since we are in a new thread
            let realm = RLMRealm.defaultRealm()
            realm.beginWriteTransaction()
            for index in 0..<5 {
                // Add row via dictionary. Order is ignored.
                DemoObject.createInRealm(realm, withObject: ["title": randomTitle(), "date": NSDate(), "sectionTitle": randomSectionTitle()])
            }
            realm.commitWriteTransaction()
        }
    }

    func add() {
        RLMRealm.defaultRealm().transactionWithBlock {
            let object = [randomTitle(), NSDate(), randomSectionTitle()]
            DemoObject.createInDefaultRealmWithObject(object)
        }
    }
}

// Helpers

func objectForIndexPath(indexPath: NSIndexPath) -> DemoObject? {
    return objectsBySection[indexPath.section][UInt(indexPath.row)] as? DemoObject
}

func randomTitle() -> String {
    return "Title \(arc4random())"
}

func randomSectionTitle() -> String {
    return sectionTitles[Int(arc4random()) % sectionTitles.count]
}
