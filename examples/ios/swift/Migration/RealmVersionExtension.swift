////////////////////////////////////////////////////////////////////////////
//
// Copyright 2021 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

import Foundation
import RealmSwift

extension RealmVersion {

    static var mostRecentVersion: RealmVersion {
        let allVersions = allCases.map { $0.rawValue }
        let max = allVersions.max()!
        return RealmVersion.init(rawValue: max)!
    }

    func realmUrl(usingTemplate: Bool) -> URL {
        let defaultURL = Realm.Configuration.defaultConfiguration.fileURL!
        let defaultParentURL = defaultURL.deletingLastPathComponent()
        let fileName = "default-v\(self.rawValue)"
        let destinationUrl = defaultParentURL.appendingPathComponent(fileName + ".realm")
        if FileManager.default.fileExists(atPath: destinationUrl.path) {
            try! FileManager.default.removeItem(at: destinationUrl)
        }
        if usingTemplate {
            let bundleUrl = Bundle.main.url(forResource: fileName, withExtension: "realm")!
            try! FileManager.default.copyItem(at: bundleUrl, to: destinationUrl)
        }

        return destinationUrl
    }

}
