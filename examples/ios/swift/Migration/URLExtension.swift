//
//  URLExtension.swift
//  Migration
//
//  Created by Dominic Frei on 28/01/2021.
//  Copyright © 2021 Realm. All rights reserved.
//

import Foundation
import RealmSwift

extension URL {
    init(for version: RealmVersion, usingTemplate: Bool) {
        let defaultURL = Realm.Configuration.defaultConfiguration.fileURL!
        let defaultParentURL = defaultURL.deletingLastPathComponent()
        let fileName = "default-v\(version.rawValue)"
        let destinationUrl = defaultParentURL.appendingPathComponent(fileName + ".realm")
        print("destinationUrl: \(destinationUrl)")
        if FileManager.default.fileExists(atPath: destinationUrl.path) {
            try! FileManager.default.removeItem(at: destinationUrl)
        }
        if usingTemplate {
            let bundleUrl = Bundle.main.url(forResource: fileName, withExtension: "realm")!
            print("bundleUrl: \(bundleUrl)")
            try! FileManager.default.copyItem(at: bundleUrl, to: destinationUrl)
        }

        self = destinationUrl
    }
}
