////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
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
import ReactKit

// Data models: GroupParent contains all of the data for a TableView, with a
// Group per section and an Entry per row in each section
class Entry: Object {
    dynamic var title = ""
    dynamic var date = NSDate()
}

class Group: Object {
    dynamic var name = ""
    let entries = List<Entry>()
}

class GroupParent: Object {
    let groups = List<Group>()
}

class Cell: UITableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String!) {
        super.init(style: .Subtitle, reuseIdentifier: reuseIdentifier)
    }

    required init(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }

    dynamic var entry: Entry?
    func attach(object: Entry) {
        // If this is the first time this Cell is used, bind its UILabels to the
        // fields of its Entry. If it's been used before, the existing bindings
        // will continue to work
        if entry == nil {
            (self.textLabel!, "text") <~ KVO.stream(self, "entry.title").ownedBy(self)
            (self.detailTextLabel!, "text") <~ (KVO.stream(self, "entry.date") |> map { $0!.description as NSString }).ownedBy(self)
        }
        entry = object
    }
}

class TableViewController: UITableViewController {
    let parent: GroupParent = {
        // Get the singleton GroupParent() object from the Realm, creating it
        // if needed. In a more complete example with more than one view, this
        // would be supplied as the data source by whatever is displaying this
        // table view
        let realm = try! Realm()
        let obj = realm.objects(GroupParent).first
        if obj != nil {
            return obj!
        }

        let newObj = GroupParent()
        try! realm.write { realm.add(newObj) }
        return newObj
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        tableView.reloadData()
    }

    // UI

    func setupUI() {
        tableView.registerClass(Cell.self, forCellReuseIdentifier: "cell")

        self.title = "ReactKit TableView"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Add Group", style: .Plain, target: self, action: "addGroup")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "addEntry")

        // Subscribe to changes to the list of groups, telling the TableView to
        // insert new sections when new groups are added to the list
        KVO.detailedStream(parent, "groups").ownedBy(self) ~> { [unowned self] _, kind, indexes in
            if let indexes = indexes where kind == .Insertion {
                self.tableView.insertSections(indexes, withRowAnimation: .Automatic)
                self.bindGroup(self.parent.groups.last!)
            }
            else {
                self.tableView.reloadData()
            }
        }

        for group in parent.groups {
            bindGroup(group)
        }
    }

    // Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return parent.groups.count
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return parent.groups[section].name
    }

    override func tableView(tableView: UITableView?, numberOfRowsInSection section: Int) -> Int {
        return parent.groups[section].entries.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! Cell
        cell.attach(objectForIndexPath(indexPath))
        return cell
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let realm = try! Realm()
            try! realm.write {
                realm.delete(self.objectForIndexPath(indexPath))
            }
        }
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // Update the date of any row selected in the UI. The display of the date
        // in the UI is automatically updated by the binding estabished in Cell.attach
        try! Realm().write {
            self.parent.groups[indexPath.section].entries[indexPath.row].date = NSDate()
        }
    }

    // Actions

    func addGroup() {
        modifyInBackground { groups in
            let group = groups.realm!.create(Group.self, value: ["name": "Group \(arc4random())", "entries": []])
            groups.append(group)
        }
    }

    func addEntry() {
        modifyInBackground { groups in
            let group = groups[Int(arc4random_uniform(UInt32(groups.count)))]
            let entry = groups.realm!.create(Entry.self, value: ["Entry \(arc4random())", NSDate()])
            group.entries.append(entry)
        }
    }

    // Helpers

    // Get the Entry at a given index path
    func objectForIndexPath(indexPath: NSIndexPath) -> Entry {
        return parent.groups[indexPath.section].entries[indexPath.row]
    }

    // Convert an NSIndexSet to an array of NSIndexPaths
    func indexSetToIndexPathArray(indexes: NSIndexSet, section: Int) -> [NSIndexPath] {
        var paths: [NSIndexPath] = []
        var index = indexes.firstIndex
        while index != NSNotFound {
            paths.append(NSIndexPath(forRow: index, inSection: section))
            index = indexes.indexGreaterThanIndex(index)
        }
        return paths
    }

    // Listen for changes to the list of entries in a Group, and tell the UI to
    // update when entries are added or removed
    func bindGroup(group: Group) {
        KVO.detailedStream(group, "entries").ownedBy(self) ~> { [unowned self] _, kind, indexes in
            if let indexes = indexes {
                let section = self.parent.groups.indexOf(group)!
                let paths = self.indexSetToIndexPathArray(indexes, section: section)
                if kind == .Insertion {
                    self.tableView.insertRowsAtIndexPaths(paths, withRowAnimation: .Automatic)
                } else if kind == .Removal {
                    self.tableView.deleteRowsAtIndexPaths(paths, withRowAnimation: .Automatic)
                } else {
                    self.tableView.reloadData()
                }
            }
            else {
                self.tableView.reloadData()
            }
        }
    }

    func modifyInBackground(block: (List<Group>) -> Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let realm = try! Realm()
            let parent = realm.objects(GroupParent).first!
            try! realm.write {
                block(parent.groups)
            }
        }
    }
}
