//
//  RealmUrls.swift
//  Migration
//
//  Created by Dominic Frei on 27/01/2021.
//  Copyright © 2021 Realm. All rights reserved.
//

import Foundation
import RealmSwift

enum RealmVersion: String {
    case v0 = "default-v0"
    case v1 = "default-v1"
    case v2 = "default-v2"
    
    static var allVersions: [RealmVersion] {
        return [.v0, .v1, .v2]
    }
    
    func destinationUrl(usingTemplate: Bool) -> URL {
        let defaultURL = Realm.Configuration.defaultConfiguration.fileURL!
        let defaultParentURL = defaultURL.deletingLastPathComponent()
        let destinationUrl = defaultParentURL.appendingPathComponent(self.rawValue + ".realm")
        let bundleUrl = bundleURL(fielName: self.rawValue, fileExtension: "realm")
        
        if FileManager.default.fileExists(atPath: destinationUrl.path) {
            try! FileManager.default.removeItem(at: destinationUrl)
        }
        if usingTemplate {
            try! FileManager.default.copyItem(at: bundleUrl, to: destinationUrl)
        }
        
        return destinationUrl
    }
    
    func bundleURL(fielName: String, fileExtension: String) -> URL {
        return Bundle.main.url(forResource: fielName, withExtension: fileExtension)!
    }
}
