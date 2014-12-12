//
//  Category.swift
//  RealmExamples
//
//  Created by Samuel Giddins on 12/11/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

import Realm
import UIKit.UIImage

class Category: RLMObject {
    dynamic var name: String = ""
    dynamic var categoryID: String = ""

    dynamic var iconImageData: NSData = NSData()

    var iconImage: UIImage? {
        get {
            return UIImage(data: iconImageData)
        }
    }

    override class func primaryKey() -> String {
        return "categoryID"
    }
}
