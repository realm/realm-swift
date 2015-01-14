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
import Realm.Private

// MARK: Object Retrieval

public func objects<T: Object>(type: T.Type) -> Results<T> {
    return Results<T>(RLMGetObjects(RLMRealm.defaultRealm(), T.className(), nil))
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
        self.init(rlmRealm: RLMRealm(path: path, readOnly: false, error: nil))
    }

    public convenience init(inMemoryIdentifier: String) {
        self.init(rlmRealm: RLMRealm.inMemoryRealmWithIdentifier(inMemoryIdentifier))
    }

    public convenience init?(path: String, readOnly readonly: Bool, error: NSErrorPointer = nil) {
        if let rlmRealm = RLMRealm(path: path, readOnly: readonly, error: error) as RLMRealm? {
            self.init(rlmRealm: rlmRealm)
        } else {
            self.init(rlmRealm: RLMRealm())
            return nil
        }
    }

    public convenience init?(path: String, encryptionKey: NSData, readOnly: Bool, error: NSErrorPointer = nil) {
        if let rlmRealm = RLMRealm.encryptedRealmWithPath(path, key: encryptionKey, readOnly: readOnly, error: error) as RLMRealm? {
            self.init(rlmRealm: rlmRealm)
        } else {
            self.init(rlmRealm: RLMRealm())
            return nil
        }
    }

    // MARK: Writing a Copy

    public func writeCopyToPath(path: String, error: NSErrorPointer = nil) {
        rlmRealm.writeCopyToPath(path, error: error)
    }

    public func writeCopyToPath(path: String, encryptionKey: NSData, error: NSErrorPointer = nil) {
        rlmRealm.writeEncryptedCopyToPath(path, key: encryptionKey, error: error)
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

    // MARK: Invalidation

    public func invalidate() {
        rlmRealm.invalidate()
    }

    // MARK: Mutating

    public func add(object: Object) {
        RLMAddObjectToRealm(object, rlmRealm, .allZeros)
    }

    public func add<S where S: SequenceType>(objects: S) {
        for obj in objects {
            RLMAddObjectToRealm(obj as Object, rlmRealm, .allZeros)
        }
    }

    public func addOrUpdate(object: Object) {
        if object.objectSchema.primaryKeyProperty == nil {
            fatalError("'\(object.objectSchema.className)' does not have a primary key and can not be updated")
        }

        RLMAddObjectToRealm(object, rlmRealm, RLMCreationOptions.UpdateOrCreate)
    }

    public func addOrUpdate<S where S: SequenceType>(objects: S) {
        for obj in objects {
            rlmRealm.addOrUpdateObject(obj as RLMObject)
        }
    }

    public func delete(object: Object) {
        RLMDeleteObjectFromRealm(object)
    }

    public func delete(objects: [Object]) {
        rlmRealm.deleteObjects(objects)
    }

    public func delete(objects: List<Object>) {
        rlmRealm.deleteObjects(objects)
    }

    public func delete(objects: Results<Object>) {
        rlmRealm.deleteObjects(objects)
    }

    public func deleteAll() {
        RLMDeleteAllObjectsFromRealm(rlmRealm)
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
        return Results<T>(RLMGetObjects(rlmRealm, T.className(), nil))
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
        return notificationBlock(notification: Notification(rawValue: rlmNotification)!, realm: Realm(rlmRealm: rlmRealm))
    }
}
