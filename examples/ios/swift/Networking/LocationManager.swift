//
//  LocationManager.swift
//  SixSquare
//
//  Created by Samuel E. Giddins on 12/9/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

import CoreLocation
import Realm

extension Dictionary {
    func select(block: ((_: Key, _: Value) -> Bool)) -> [Key:Value] {
        var copy = [Key:Value]()
        for (key, value) in self {
            if block(key, value) {
                copy[key] = value
            }
        }
        return copy
    }
}

@objc
class VenueManager: NSObject, CLLocationManagerDelegate {
    let realm: RLMRealm
    var location: CLLocation = CLLocation(latitude: 37.7798657, longitude: -122.3919903) {
        didSet {
            if oldValue != location {
                fetchVenues()
            }
        }
    }
    let locationManager = CLLocationManager()
    var searchRadius: Double = 1_000 // in meters
    let kFourSquareBaseURL = "https://api.foursquare.com"
    let kFourSquareIntent = "browse"
    let limit = 50
    let client = APIClient(baseURL: NSURL(string: "https://api.foursquare.com")!)
    let allRestaurantsID = "4d4b7105d754a06374d81259"
    var category: Category?

    init(realm: RLMRealm) {
        self.realm = realm
        category = Category.objectsInRealm(realm, "categoryID = %@", allRestaurantsID).firstObject() as? Category
        super.init()
        locationManager.delegate = self
    }
    
    var monitoring: Bool {
        get { return true }
        set(monitoring) {
            if monitoring {
                locationManager.requestWhenInUseAuthorization()
                locationManager.startMonitoringSignificantLocationChanges()
            }
            else {
                locationManager.stopMonitoringSignificantLocationChanges()
            }
        }
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        location = locations.first as? CLLocation ?? location
    }
    
    var venues: RLMResults {
        get {
            let searchRadiusDegrees = (searchRadius / 111) / 1_000 * 1.2
            return Restaurant.objectsInRealm(realm,
                "longitude < %f AND longitude > %f AND latitude < %f AND latitude > %f",
                location.coordinate.longitude + searchRadiusDegrees,
                location.coordinate.longitude - searchRadiusDegrees,
                location.coordinate.latitude  + searchRadiusDegrees,
                location.coordinate.latitude  - searchRadiusDegrees)
        }
    }
    
    func fetchVenues() {
        // Only need to run
        if Category.allObjectsInRealm(realm).count == 0 {
            fetchCategories()
        }

        let categoryID = "4d4b7105d754a06374d81259"
        let path = "/v2/venues/explore"
        let parameters = [
            "intent": kFourSquareIntent,
            "categoryId": categoryID,
            "limit": limit.description,
            "ll": "\(location.coordinate.latitude),\(location.coordinate.longitude)",
            "radius": searchRadius.description
        ] as [String:String]
        client.request(path, parameters: parameters, completion: { (json) -> () in
            let realm = RLMRealm(path: self.realm.path)
            realm.beginWriteTransaction()
            if let response = json?["response"] as? [String:AnyObject] {
                if let groups = response["groups"] as? [AnyObject] {
                    let groupItems = groups.map({ ($0 as NSDictionary)["items"] })
                    for items in groupItems {
                        for item in items as [NSDictionary] {
                            if let venue = item["venue"] as? [String:AnyObject] {
                                let location = venue["location"] as [String:AnyObject]
                                let categories = venue["categories"] as? [[String:AnyObject]]
                                let categoryID = categories?.first?["id"] as? String
                                let category = Category.objectsInRealm(realm, "categoryID == %@", categoryID!).firstObject() as Category?
                                let dict = [
                                    "venueID"    : venue["id"]     as? String,
                                    "name"       : venue["name"]   as? String,
                                    "latitude"   : location["lat"] as? Double,
                                    "longitude"  : location["lng"] as? Double,
                                    "venueScore" : venue["rating"] as? Double,
                                    "category"   : category,
                                ] as [String:AnyObject?]
                                let compactDict = dict.select({ $1 != nil }) as [String:AnyObject]
                                Restaurant.createOrUpdateInRealm(realm, withObject: compactDict)
                            }
                        }
                    }
                }
            }
            realm.commitWriteTransaction()
        })
    }

    func fetchCategories() {
        let path = "/v2/venues/categories"
        client.request(path, parameters: [:]) { (json) -> () in
            let realm = RLMRealm(path: self.realm.path)
            realm.beginWriteTransaction()
            Category.createOrUpdateInRealm(realm, withObject: ["name": "All Restaurants", "categoryID": self.allRestaurantsID])
            if let response = json?["response"] as? [String:AnyObject] {
                if let categories = response["categories"] as? [[String:AnyObject]] {
                    for category in categories {
                        if category["shortName"] as String == "Food" {
                            if let foodCategories = category["categories"] as? [[String:AnyObject]] {
                                for foodCategory in foodCategories {
                                    let dict = [
                                        "name": foodCategory["name"] as? String,
                                        "id"  : foodCategory["id"] as? String
                                    ]
                                    let compactDict = dict.select({ $1 != nil }) as [String:String]
                                    let category = Category.createOrUpdateInRealm(realm, withObject: compactDict)
                                    if category.iconImageData.length == 0 {
                                        if let icon = foodCategory["icon"] as? [String:String] {
                                            let prefix = icon["prefix"]
                                            let suffix = icon["suffix"]
                                            if prefix != nil && suffix != nil {
                                                if let iconURL = NSURL(string: "\(prefix)64\(suffix)") {
                                                    category.iconImageData = NSData(contentsOfURL: iconURL) ?? NSData()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            realm.commitWriteTransaction()
        }
    }
}
