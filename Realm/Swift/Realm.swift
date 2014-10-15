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

import Realm

// MARK: Migrations

public func migrateRealm(path: String = defaultRealmPath(), block: MigrationBlock) {
    RLMRealm.migrateRealmAtPath(path, withBlock: rlmMigrationBlockFromMigrationBlock(block))
}

// MARK: Object Retrieval

public func objects<T: Object>(type: T.Type) -> Results<T> {
    return Results<T>(T.allObjectsInRealm(RLMRealm.defaultRealm()))
}

// MARK: Default Realm Helpers

public func defaultRealmPath() -> String {
    return RLMRealm.defaultRealmPath()
}

public func defaultRealm() -> Realm {
    return Realm(rlmRealm: RLMRealm.defaultRealm())
}

public class Realm {
    // MARK: Properties

    var rlmRealm: RLMRealm
    public var path: String { return rlmRealm.path }
    public var readOnly: Bool { return rlmRealm.readOnly }
    public var schema: Schema { return Schema(rlmSchema: rlmRealm.schema) }
    public var autorefresh: Bool {
        get {
            return rlmRealm.autorefresh
        }
        set {
            rlmRealm.autorefresh = newValue
        }
    }

    // MARK: Initializers

    init(rlmRealm: RLMRealm) {
        self.rlmRealm = rlmRealm
    }

    public convenience init(path: String) {
        self.init(path: path, readOnly: false, error: nil)
    }

    public convenience init(path: String, readOnly readonly: Bool, error: NSErrorPointer) {
        self.init(rlmRealm: RLMRealm.realmWithPath(path, readOnly: readonly, error: error))
    }

    // MARK: Transactions

    public func write(block: (() -> Void)) {
        rlmRealm.transactionWithBlock(block)
    }

    public func beginWrite() {
        rlmRealm.beginWriteTransaction()
    }

    public func commitWrite() {
        rlmRealm.commitWriteTransaction()
    }

    // MARK: Refresh

    public func refresh() {
        rlmRealm.refresh()
    }

    // MARK: Mutating

    public func add(object: Object) {
        rlmRealm.addObject(object)
    }

    public func add(objects: [Object]) {
        rlmRealm.addObjects(objects)
    }

    public func add<S where S: SequenceType>(objects: S) {
        for obj in objects {
            rlmRealm.addObject(obj as RLMObject)
        }
    }

    public func delete(object: Object) {
        rlmRealm.deleteObject(object)
    }

    public func delete(objects: [Object]) {
        rlmRealm.deleteObjects(objects)
    }

    public func delete(objects: List<Object>) {
        rlmRealm.deleteObjects(objects)
    }

    // MARK: Notifications

    public func addNotificationBlock(block: NotificationBlock) -> NotificationToken {
        return rlmRealm.addNotificationBlock(rlmNotificationBlockFromNotificationBlock(block))
    }

    public func removeNotification(notificationToken: NotificationToken) {
        rlmRealm.removeNotification(notificationToken)
    }

    // MARK: Object Retrieval

    public func objects<T: Object>(type: T.Type) -> Results<T> {
        return Results<T>(T.allObjectsInRealm(rlmRealm))
    }
}

// MARK: Notifications

public enum Notification: String {
    case DidChange = "RLMRealmDidChangeNotification"
    case RefreshRequired = "RLMRealmRefreshRequiredNotification"
}

public typealias NotificationBlock = (notification: Notification, realm: Realm) -> Void

func rlmNotificationBlockFromNotificationBlock(notificationBlock: NotificationBlock) -> RLMNotificationBlock {
    return { rlmNotification, rlmRealm in
        return notificationBlock(notification: Notification.fromRaw(rlmNotification)!, realm: Realm(rlmRealm: rlmRealm))
    }
}
