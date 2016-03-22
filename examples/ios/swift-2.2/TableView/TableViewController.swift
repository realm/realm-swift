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
    dynamic var title = ""
    dynamic var date = NSDate()
}

class Cell: UITableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String!) {
        super.init(style: .Subtitle, reuseIdentifier: reuseIdentifier)
    }

    required init(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
}

class TableViewController: UITableViewController {

    let realm = try! Realm()
    let array = try! Realm().objects(DemoObject).sorted("date")
    var notificationToken: NotificationToken?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()

        // Set results notification block
        notificationToken = array.addNotificationBlock { [unowned self] results, error in
            self.tableView.reloadData()
        }
    }

    // UI

    func setupUI() {
        tableView.registerClass(Cell.self, forCellReuseIdentifier: "cell")

        self.title = "TableView"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "BG Add", style: .Plain, target: self, action: "backgroundAdd")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "add")
    }

    // Table view data source

    override func tableView(tableView: UITableView?, numberOfRowsInSection section: Int) -> Int {
        return array.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! Cell

        let object = array[indexPath.row]
        cell.textLabel?.text = object.title
        cell.detailTextLabel?.text = object.date.description

        return cell
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            realm.beginWrite()
            realm.delete(array[indexPath.row])
            try! realm.commitWrite()
        }
    }

    // Actions

    func backgroundAdd() {
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        // Import many items in a background thread
        dispatch_async(queue) {
            // Get new realm and table since we are in a new thread
            let realm = try! Realm()
            realm.beginWrite()
            for _ in 0..<5 {
                // Add row via dictionary. Order is ignored.
                realm.create(DemoObject.self, value: ["title": TableViewController.randomString(), "date": TableViewController.randomDate()])
            }
            try! realm.commitWrite()
        }
    }

    func add() {
        realm.beginWrite()
        realm.create(DemoObject.self, value: [TableViewController.randomString(), TableViewController.randomDate()])
        try! realm.commitWrite()
    }

    // Helpers

    class func randomString() -> String {
        return "Title \(arc4random())"
    }

    class func randomDate() -> NSDate {
        return NSDate(timeIntervalSince1970: NSTimeInterval(arc4random()))
    }
}
