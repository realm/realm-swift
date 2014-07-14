////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
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

class Realm {
    var rlmRealm: RLMRealm
    var path: String { get { return rlmRealm.path } }
    var readOnly: Bool { get { return rlmRealm.readOnly } }
    var schema: RealmSchema { get { return rlmRealm.schema } }
    var autorefresh: Bool {
        get {
            return rlmRealm.autorefresh
        }
        set {
            rlmRealm.autorefresh = newValue
        }
    }

    class func defaultRealm() -> Realm {
        return Realm(rlmRealm: RLMRealm.defaultRealm())
    }

    init(rlmRealm: RLMRealm) {
        self.rlmRealm = rlmRealm
    }

    convenience init(path: String!) {
        self.init(path: path, readOnly: false, error: nil)
    }

    convenience init(path: String!, readOnly readonly: Bool, error: AutoreleasingUnsafePointer<NSError?>) {
        self.init(rlmRealm: RLMRealm.realmWithPath(path, readOnly: readonly, error: error))
    }

    class func useInMemoryDefaultRealm() {
        RLMRealm.useInMemoryDefaultRealm()
    }

    func beginWriteTransaction() {
        rlmRealm.beginWriteTransaction()
    }

    func commitWriteTransaction() {
        rlmRealm.commitWriteTransaction()
    }

    func refresh() {
        rlmRealm.refresh()
    }

    func addObject(object: RealmObject) {
        rlmRealm.addObject(object)
    }

    func addObjects(objects: [AnyObject]) {
        rlmRealm.addObjectsFromArray(objects)
    }

    func deleteObject(object: RealmObject) {
        rlmRealm.deleteObject(object)
    }

    class func applyMigrationBlock(error: AutoreleasingUnsafePointer<NSError?>, block: RealmMigrationBlock) {
        RLMRealm.migrateDefaultRealmWithBlock(block)
    }

    class func applyMigrationBlock(atPath path: String, error: AutoreleasingUnsafePointer<NSError?>, block: RealmMigrationBlock) {
        RLMRealm.migrateRealmAtPath(path, withBlock: block)
    }

    func addNotificationBlock(block: RealmNotificationBlock) -> RealmNotificationToken {
        return rlmRealm.addNotificationBlock(block)
    }

    func removeNotification(notificationToken: RealmNotificationToken) {
        rlmRealm.removeNotification(notificationToken)
    }

    func objects<T: RealmObject>(typeObject: T) -> RealmArray<T> {
        return RealmArray<T>(rlmArray: T.self.allObjectsInRealm(rlmRealm))
    }

    func objects<T: RealmObject>(typeObject: T, withPredicate predicate: NSPredicate) -> RealmArray<T> {
        return RealmArray<T>(rlmArray: T.self.objectsInRealm(rlmRealm, withPredicate: predicate))
    }
}
