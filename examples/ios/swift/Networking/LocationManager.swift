//
//  LocationManager.swift
//  SixSquare
//
//  Created by Samuel E. Giddins on 12/9/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

import CoreLocation
import Realm

@objc
class VenueManager: NSObject, CLLocationManagerDelegate {
    let realm: RLMRealm
    var location: CLLocation = CLLocation(latitude: 37.7798657, longitude: -122.3919903) {
        didSet(oldLocation) {
            if oldLocation != location {
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

    init(realm: RLMRealm) {
        self.realm = realm
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
            let searchRadiusDegrees = (searchRadius / 111.325) / 1_000
            return Restaurant.objectsInRealm(realm,
                "longitude < %f AND longitude > %f AND latitude < %f AND latitude > %f",
                location.coordinate.longitude + searchRadiusDegrees,
                location.coordinate.longitude - searchRadiusDegrees,
                location.coordinate.latitude + searchRadiusDegrees,
                location.coordinate.latitude - searchRadiusDegrees)
        }
    }
    
    func fetchVenues() {
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
                                let dict = [
                                    "venueID"    : venue["id"]     as? String ?? "",
                                    "name"       : venue["name"]   as? String ?? "",
                                    "latitude"   : location["lat"] as? Double ?? 0.0,
                                    "longitude"  : location["lng"] as? Double ?? 0.0,
                                    "venueScore" : venue["rating"] as? Double ?? -1.0
                                ]
                                Restaurant.createOrUpdateInRealm(realm, withObject: dict)
                            }
                        }
                    }
                }
            }
            realm.commitWriteTransaction()
        })
    }
}
