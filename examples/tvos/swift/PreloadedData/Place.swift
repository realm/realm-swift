//
//  Place.swift
//  RealmExamples
//
//  Created by Katsumi Kishikawa on 11/20/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import UIKit
import RealmSwift

class Place: Object {
    dynamic var postalCode: String?
    dynamic var placeName: String?
    dynamic var state: String?
    dynamic var stateAbbreviation: String?
    dynamic var county: String?
    dynamic var latitude = 0.0
    dynamic var longitude = 0.0
}
