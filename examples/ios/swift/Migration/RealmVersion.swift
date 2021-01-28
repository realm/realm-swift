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
    
    func destinationUrl(clean: Bool = false) -> URL? {
        let defaultURL = Realm.Configuration.defaultConfiguration.fileURL!
        let defaultParentURL = defaultURL.deletingLastPathComponent()
        let destinationUrl = defaultParentURL.appendingPathComponent(self.rawValue + ".realm")
        
        guard let bundleUrl = bundleURL(fielName: self.rawValue, fileExtension: "realm") else {
            print("Default files for path \(self.rawValue) could not be found.")
            return nil
        }
        
        if clean {
            do {
                try FileManager.default.removeItem(at: destinationUrl)
                try FileManager.default.copyItem(at: bundleUrl, to: destinationUrl)
            } catch let error {
                print(String(describing: error))
            }
        }
                
        return destinationUrl
    }
    
    func bundleURL(fielName: String, fileExtension: String) -> URL? {
        return Bundle.main.url(forResource: fielName, withExtension: fileExtension)
    }
}
