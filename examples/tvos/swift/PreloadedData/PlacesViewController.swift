//
//  PlacesViewController.swift
//  RealmExamples
//
//  Created by Katsumi Kishikawa on 11/20/15.
//  Copyright © 2015 Realm. All rights reserved.
//

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
        var results = realm.objects(Place)
        if let text = searchField.text where !text.isEmpty {
            results = results.filter("postalCode beginswith %@", text)
        }
        self.results = results.sorted("postalCode", ascending: true)

        tableView?.reloadData()
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        reloadData()
    }
}
