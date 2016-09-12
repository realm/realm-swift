//
//  CollectionViewController.swift
//  CollectionView
//
//  Created by Marius Rackwitz on 14.6.16.
//  Copyright © 2016 Realm. All rights reserved.
//

import UIKit
import RealmSwift

class DemoObject: Object {
    dynamic var title = ""
    dynamic var date = NSDate()
}

class Cell: UICollectionViewCell {
    @IBOutlet var label: UILabel!
    @IBOutlet var dateLabel: UILabel!

    static var dateFormatter: NSDateFormatter = {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .ShortStyle
        dateFormatter.timeStyle = .ShortStyle
        return dateFormatter
    }()

    func attach(object: DemoObject) {
        label.text = object.title
        dateLabel.text = Cell.dateFormatter.stringFromDate(object.date)
    }
}

class CollectionViewController: UICollectionViewController {
    var notificationToken: NotificationToken? = nil

    lazy var realm = try! Realm()
    lazy var results: Results<DemoObject> = {
        self.realm.objects(DemoObject)
    }()


    // MARK: View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Observe Notifications
        notificationToken = results.addNotificationBlock { [weak self] (changes: RealmCollectionChange) in
            guard let collectionView = self?.collectionView else { return }
            switch changes {
            case .Initial:
                // Results are now populated and can be accessed without blocking the UI
                collectionView.reloadData()
                break
            case .Update(_, let deletions, let insertions, let modifications):
                // Query results have changed, so apply them to the UITableView
                collectionView.performBatchUpdates({
                    collectionView.insertItemsAtIndexPaths(insertions.map { NSIndexPath(forRow: $0, inSection: 0) })
                    collectionView.deleteItemsAtIndexPaths(deletions.map { NSIndexPath(forRow: $0, inSection: 0) })
                    collectionView.reloadItemsAtIndexPaths(modifications.map { NSIndexPath(forRow: $0, inSection: 0) })
                }, completion: { _ in })
                break
            case .Error(let error):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError("\(error)")
                break
            }
        }
    }

    deinit {
        notificationToken?.stop()
    }


    // MARK: Helpers

    func objectAtIndexPath(indexPath: NSIndexPath) -> DemoObject {
        return results[indexPath.row]
    }


    // MARK: UICollectionViewDataSource

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return results.count
    }

    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let object = objectAtIndexPath(indexPath)
        try! realm.write {
            realm.delete(object)
        }
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let object = objectAtIndexPath(indexPath)
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! Cell
        cell.attach(object)
        return cell
    }

    // MARK: Actions

    @IBAction dynamic func backgroundAdd() {
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        // Import many items in a background thread
        dispatch_async(queue) {
            // Get new realm and table since we are in a new thread
            let realm = try! Realm()
            try! realm.write {
                for _ in 0..<5 {
                    // Add row via dictionary. Order is ignored.
                    realm.create(DemoObject.self, value: ["title": randomTitle(), "date": NSDate()])
                }
            }
        }
    }

    @IBAction dynamic func add() {
        try! realm.write {
            let object = [randomTitle(), NSDate()]
            self.realm.create(DemoObject.self, value: object)
        }
    }

}


// Helpers

func randomTitle() -> String {
    return "Title \(arc4random())"
}
