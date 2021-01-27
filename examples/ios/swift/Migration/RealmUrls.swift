//
//  RealmUrls.swift
//  Migration
//
//  Created by Dominic Frei on 27/01/2021.
//  Copyright © 2021 Realm. All rights reserved.
//

import Foundation
import RealmSwift

enum Realms: String {
    case v0 = "default-v0.realm"
    case v1 = "default-v1.realm"
    case v2 = "default-v2.realm"
    
    func url(clean: Bool = false) -> URL {
        let defaultURL = Realm.Configuration.defaultConfiguration.fileURL!
        let defaultParentURL = defaultURL.deletingLastPathComponent()
        let finalUrl = defaultParentURL.appendingPathComponent(self.rawValue)
        
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
