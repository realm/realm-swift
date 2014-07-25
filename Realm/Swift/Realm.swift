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

public class Realm {
    public var rlmRealm: RLMRealm
    public var path: String { return rlmRealm.path }
    public var readOnly: Bool { return rlmRealm.readOnly }
    public var schema: RealmSchema { return rlmRealm.schema }
    public var autorefresh: Bool {
        get {
            return rlmRealm.autorefresh
        }
        set {
            rlmRealm.autorefresh = newValue
        }
    }

    public class func defaultRealm() -> Realm {
        return Realm(rlmRealm: RLMRealm.defaultRealm())
    }

    public init(rlmRealm: RLMRealm) {
        self.rlmRealm = rlmRealm
    }

    public convenience init(path: String!) {
        self.init(path: path, readOnly: false, error: nil)
    }

    public convenience init(path: String!, readOnly readonly: Bool, error: AutoreleasingUnsafePointer<NSError?>) {
        self.init(rlmRealm: RLMRealm.realmWithPath(path, readOnly: readonly, error: error))
    }

    public class func useInMemoryDefaultRealm() {
        RLMRealm.useInMemoryDefaultRealm()
    }

    public func beginWriteTransaction() {
        rlmRealm.beginWriteTransaction()
    }

    public func commitWriteTransaction() {
        rlmRealm.commitWriteTransaction()
    }

    public func refresh() {
        rlmRealm.refresh()
    }

    public func addObject(object: RealmObject) {
        rlmRealm.addObject(object)
    }

    public func addObjects(objects: [AnyObject]) {
        rlmRealm.addObjectsFromArray(objects)
    }

    public func deleteObject(object: RealmObject) {
        rlmRealm.deleteObject(object)
    }

    public class func migrateDefaultRealmWithBlock(block: RealmMigrationBlock) {
        RLMRealm.migrateDefaultRealmWithBlock(block)
    }

    public class func migrateRealmAtPath(path: String, withBlock block: RealmMigrationBlock) {
        RLMRealm.migrateRealmAtPath(path, withBlock: block)
    }

    public func addNotificationBlock(block: RealmNotificationBlock) -> RealmNotificationToken {
        return rlmRealm.addNotificationBlock(block)
    }

    public func removeNotification(notificationToken: RealmNotificationToken) {
        rlmRealm.removeNotification(notificationToken)
    }

    public func objects<T: RealmObject>(typeObject: T) -> RealmArray<T> {
        return RealmArray<T>(rlmArray: T.self.allObjectsInRealm(rlmRealm))
    }

    public func objects<T: RealmObject>(typeObject: T, _ predicateFormat: String, _ args: CVarArg...) -> RealmArray<T> {
        return RealmArray<T>(rlmArray: T.self.objectsInRealm(rlmRealm, `where`: predicateFormat, args: getVaList(args)))
    }

    public func objects<T: RealmObject>(typeObject: T, withPredicate predicate: NSPredicate) -> RealmArray<T> {
        return RealmArray<T>(rlmArray: T.self.objectsInRealm(rlmRealm, withPredicate: predicate))
    }
}
