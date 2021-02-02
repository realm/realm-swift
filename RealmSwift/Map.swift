//
//  File.swift
//  RealmSwift
//
//  Created by Pavel Yakimenko on 27/01/2021.
//  Copyright © 2021 Realm. All rights reserved.
//

import Foundation
import Realm

/**
 * Key-value collection. Where the key is a string and value is one of the available Realm types.
 * We use Map to don't intefere with the native Swift's Dictionary type.
 */
public final class Map: RLMDictionary<AnyObject> {
}
