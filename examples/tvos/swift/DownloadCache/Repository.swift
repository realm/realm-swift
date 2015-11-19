//
//  Repository.swift
//  RealmExamples
//
//  Created by kishikawakatsumi on 11/20/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import UIKit
import RealmSwift

class Repository: Object {
    dynamic var identifier = ""
    dynamic var name: String?
    dynamic var avatarURL: String?

    override static func primaryKey() -> String? {
        return "identifier"
    }
}
