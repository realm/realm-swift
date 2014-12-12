//
//  ViewController.swift
//  SixSquare
//
//  Created by Samuel E. Giddins on 12/9/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

import UIKit
import Realm

class ViewController: UITableViewController {
    let realm: RLMRealm
    let venueManager: VenueManager
    var realmNotification: RLMNotificationToken?
    
    var restaurants: RLMResults {
        willSet(restaurants) {
            title = "\(restaurants.count) venues nearby"
        }
    }

    init(realm: RLMRealm) {
        self.realm = realm
        venueManager = VenueManager(realm: realm)
        restaurants = venueManager.venues
        super.init(nibName: .None, bundle: .None)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    override func viewDidLoad() {
        restaurants = venueManager.venues.sortedResultsUsingProperty("venueScore", ascending: false)
        super.viewDidLoad()
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "CellIdentifier")
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(venueManager, action: Selector("fetchVenues"), forControlEvents: .ValueChanged)
        realmNotification = realm.addNotificationBlock { [weak self] (name, realm) -> Void in
            NSOperationQueue.mainQueue().addOperationWithBlock {
                if let vc = self {
                    vc.restaurants = vc.venueManager.venues.sortedResultsUsingProperty("venueScore", ascending: false)
                    vc.refreshControl?.endRefreshing()
                    vc.tableView.reloadData()
                }
            }
        }
        venueManager.monitoring = true
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Int(restaurants.count)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("CellIdentifier", forIndexPath: indexPath) as UITableViewCell
        if let restaurant = restaurants[UInt(indexPath.row)] as? Restaurant {
            cell.textLabel?.text = "\(restaurant.name) (\(restaurant.venueScore))"
        }
        
        return cell
    }
}

