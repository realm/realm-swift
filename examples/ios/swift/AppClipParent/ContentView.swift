////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 Realm Inc.
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

import SwiftUI
import RealmSwift

struct ContentView: View {
    @ObservedObject var objects: RealmSwift.List<DemoObject>

    var body: some View {
        Section(header: Button("Add Object", action: addObject)) {
            List {
                ForEach(objects, id: \.uuid) { object in
                    ContentViewRow(object: object)
                }
            }
        }
    }

    private func addObject() {
        /*
         The app clip and parent application share data by accessing a common realm file path within an App Group.
         */
        let config = Realm.Configuration(fileURL: FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Constants.groupId)!.appendingPathComponent("default.realm"))

        let realm = try! Realm(configuration: config)
        try! realm.write {
            objects.append(DemoObject())
        }
    }
}

struct ContentViewRow: View {
    var object: DemoObject

    var body: some View {
        VStack {
            Text(verbatim: object.uuid.uuidString).fixedSize()
            Text(object.date.description).font(.footnote).frame(alignment: .leading)
        }
    }
}
