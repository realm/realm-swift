//
//  Restaurant.swift
//  SixSquare
//
//  Created by Samuel E. Giddins on 12/9/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

import CoreLocation.CLLocation
import Realm

class Restaurant: RLMObject {
    dynamic var venueID: String = ""
    dynamic var name: String = ""
    dynamic var latitude: Double = 0.0
    dynamic var longitude: Double = 0.0
    dynamic var iconURLString: String = ""
    dynamic var venueScore: Double = 0.0
    dynamic var category: Category? = Category()
    
    var iconURL: NSURL? {
        get { return NSURL(string: iconURLString) }
    }
    
    var location: CLLocation {
        get {
            return CLLocation(latitude: latitude, longitude: longitude)
        }
        set {
            latitude = newValue.coordinate.latitude
            longitude = newValue.coordinate.longitude
        }
    }
    
    override class func ignoredProperties() -> [AnyObject]! {
        return ["location"]
    }
    
    override class func primaryKey() -> String {
        return "venueID"
    }
}
