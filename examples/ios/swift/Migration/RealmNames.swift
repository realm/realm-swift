//
//  RealmUrls.swift
//  Migration
//
//  Created by Dominic Frei on 27/01/2021.
//  Copyright © 2021 Realm. All rights reserved.
//

import Foundation
import RealmSwift

enum RealmNames: String {
    case v0 = "default-v0"
    case v1 = "default-v1"
    case v2 = "default-v2"
    
    static var allCases: [RealmNames] {
        return [.v0, .v1, .v2]
    }
    
    func url(clean: Bool = false) -> URL {
        let defaultURL = Realm.Configuration.defaultConfiguration.fileURL!
        let defaultParentURL = defaultURL.deletingLastPathComponent()
        let finalUrl = defaultParentURL.appendingPathComponent(self.rawValue).appendingPathComponent(".realm")
        
        if clean {
            do {
                try FileManager.default.removeItem(at: finalUrl)
            } catch let error {
                print(String(describing: error))
            }
        }
                
        return finalUrl
    }
}
