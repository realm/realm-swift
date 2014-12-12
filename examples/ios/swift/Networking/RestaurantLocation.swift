//
//  RestaurantLocation.swift
//  RealmExamples
//
//  Created by Samuel Giddins on 12/11/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

import Foundation
import MapKit.MKAnnotation
import UIKit.UIImage

class RestaurantLocation: NSObject, MKAnnotation {
    let venueID: String
    let coordinate: CLLocationCoordinate2D
    let title: String
    let subtitle: String
    let image: UIImage?

    init(_ restaurant: Restaurant) {
        venueID = restaurant.venueID
        title = restaurant.name
        coordinate = restaurant.location.coordinate
        subtitle = "\(restaurant.category!.name) (\(restaurant.venueScore))"
        image = restaurant.category?.iconImage
    }
}
