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

import Foundation
import Realm
import Realm.Private

/**
A Realm instance (also referred to as "a realm") represents a Realm
database.

Realms can either be stored on disk (see `init(path:)`) or in
memory (see `init(inMemoryIdentifier:)`).

Realm instances are cached internally, and constructing equivalent Realm
objects (with the same path or identifier) produces limited overhead.

If you specifically want to ensure a Realm object is
destroyed (for example, if you wish to open a realm, check some property, and
then possibly delete the realm file and re-open it), place the code which uses
the realm within an `autoreleasepool {}` and ensure you have no other
strong references to it.

:warning: Realm instances are not thread safe and can not be shared across
          threads or dispatch queues. You must construct a new instance on each thread you want
          to interact with the realm on. For dispatch queues, this means that you must
          call it in each block which is dispatched, as a queue is not guaranteed to run
          on a consistent thread.
*/
public final class Realm {

    // MARK: Properties

    /// Path to the file where this Realm is persisted.
    public var path: String { return rlmRealm.path }

    /// Indicates if this Realm was opened in read-only mode.
    public var readOnly: Bool { return rlmRealm.readOnly }

    /// The Schema used by this realm.
    public var schema: Schema { return Schema(rlmRealm.schema) }

    /**
    The location of the default Realm as a string. Can be overridden.

    `~/Library/Application Support/{bundle ID}/default.realm` on OS X.

    `default.realm` in your application's documents directory on iOS.

    :returns: Location of the default Realm.
    */
    public class var defaultPath: String {
        get {
            return RLMRealm.defaultRealmPath()
        }
        set {
            RLMRealm.setDefaultRealmPath(newValue)
        }
    }

    // MARK: Initializers

    /**
    Obtains a Realm instance persisted at the specified file path. Defaults to
    `Realm.defaultPath`

    :param: path Path to the realm file.
    */
    public convenience init(path: String = Realm.defaultPath) {
        self.init(RLMRealm(path: path, readOnly: false, error: nil)!)
    }
    
    /**
    Obtains a `Realm` instance with persistence to a specific file path with
    options.

    Like `init(path:)`, but with the ability to open read-only realms and get
    errors as an `NSError` inout parameter rather than exceptions.

    :warning: Read-only Realms do not support changes made to the file while the
              `Realm` exists. This means that you cannot open a Realm as both read-only
              and read-write at the same time. Read-only Realms should normally only be used
              on files which cannot be opened in read-write mode, and not just for enforcing
              correctness in code that should not need to write to the Realm.

    :param: path            Path to the file you want the data saved in.
    :param: readOnly        Bool indicating if this Realm is read-only (must use for read-only files).
    :param: encryptionKey   64-byte key to use to encrypt the data.
    :param: error           If an error occurs, upon return contains an `NSError` object
                            that describes the problem. If you are not interested in
                            possible errors, omit the argument, or pass in `nil`.
    */
    public convenience init?(path: String, readOnly: Bool, encryptionKey: NSData? = nil, error: NSErrorPointer = nil) {
        if let rlmRealm = RLMRealm(path: path, key: encryptionKey, readOnly: readOnly, inMemory: false, dynamic: false, schema: nil, error: error) as RLMRealm? {
            self.init(rlmRealm)
        } else {
            self.init(RLMRealm())
            return nil
        }
    }

    /**
    Obtains a Realm instance for an un-persisted in-memory Realm. The identifier
    used to create this instance can be used to access the same in-memory Realm from
    multiple threads.

    Because in-memory Realms are not persisted, you must be sure to hold on to a
    reference to the `Realm` object returned from this for as long as you want
    the data to last. Realm's internal cache of `Realm`s will not keep the
    in-memory Realm alive across cycles of the run loop, so without a strong
    reference to the `Realm` a new Realm will be created each time. Note that
    `Object`s, `List`s, and `Results` that refer to objects persisted in a Realm have a
    strong reference to the relevant `Realm`, as do `NotifcationToken`s.

    :param: identifier A string used to identify a particular in-memory Realm.
    */
    public convenience init(inMemoryIdentifier: String) {
        self.init(RLMRealm.inMemoryRealmWithIdentifier(inMemoryIdentifier))
    }

    // MARK: Transactions

    /**
    Helper to perform actions contained within the given block inside a write transation.

    :param: block The block to be executed inside a write transaction.
    */
    public func write(block: (() -> Void)) {
        rlmRealm.transactionWithBlock(block)
    }

    /**
    Begins a write transaction in a `Realm`.

    Only one write transaction can be open at a time. Write transactions cannot be
    nested, and trying to begin a write transaction on a `Realm` which is
    already in a write transaction with throw an exception. Calls to
    `beginWrite` from `Realm` instances in other threads will block
    until the current write transaction completes.

    Before beginning the write transaction, `beginWrite` updates the
    `Realm` to the latest Realm version, as if `refresh()` was called, and
    generates notifications if applicable. This has no effect if the `Realm`
    was already up to date.

    It is rarely a good idea to have write transactions span multiple cycles of
    the run loop, but if you do wish to do so you will need to ensure that the
    `Realm` in the write transaction is kept alive until the write transaction
    is committed.
    */
    public func beginWrite() {
        rlmRealm.beginWriteTransaction()
    }

    /**
    Commits all writes operations in the current write transaction.

    After this is called, the `Realm` reverts back to being read-only.

    Calling this when not in a write transaction will throw an exception.
    */
    public func commitWrite() {
        rlmRealm.commitWriteTransaction()
    }

    /**
    Revert all writes made in the current write transaction and end the transaction.

    This rolls back all objects in the Realm to the state they were in at the
    beginning of the write transaction, and then ends the transaction.

    This restores the data for deleted objects, but does not reinstate deleted
    accessor objects. Any `Object`s which were added to the Realm will be
    invalidated rather than switching back to standalone objects.
    Given the following code:

    ```swift
    let oldObject = objects(ObjectType).first!
    let newObject = ObjectType()

    realm.beginWrite()
    realm.add(newObject)
    realm.delete(oldObject)
    realm.cancelWrite()
    ```

    Both `oldObject` and `newObject` will return `true` for `invalidated`,
    but re-running the query which provided `oldObject` will once again return
    the valid object.

    Calling this when not in a write transaction will throw an exception.
    */
    public func cancelWrite() {
        rlmRealm.cancelWriteTransaction()
    }

    /**
    Indicates if this Realm is currently in a write transaction.

    :warning: Wrapping mutating operations in a write transaction if this property returns `false`
              may cause a large number of write transactions to be created, which could negatively
              impact Realm's performance. Always prefer performing multiple mutations in a single
              transaction when possible.
    */
    public var inWriteTransaction: Bool {
        return rlmRealm.inWriteTransaction
    }

    // MARK: Adding and Creating objects

    /**
    Adds or updates an object to be persisted it in this Realm.

    When 'update' is 'true', the object must have a primary key. If no objects exist in
    the Realm instance with the same primary key value, the object is inserted. Otherwise,
    the existing object is updated with any changed values.

    When added, all linked (child) objects referenced by this object will also be
    added to the Realm if they are not already in it. If the object or any linked
    objects already belong to a different Realm an exception will be thrown. Use one
    of the `create` functions to insert a copy of a persisted object into a different
    Realm.

    The object to be added must be valid and cannot have been previously deleted
    from a Realm (i.e. `invalidated` must be false).

    :param: object Object to be added to this Realm.
    :param: update If true will try to update existing objects with the same primary key.
    */
    public func add(object: Object, update: Bool = false) {
        if update && object.objectSchema.primaryKeyProperty == nil {
            throwRealmException("'\(object.objectSchema.className)' does not have a primary key and can not be updated")
        }
        RLMAddObjectToRealm(object, rlmRealm, update)
    }

    /**
    Adds or updates objects in the given sequence to be persisted it in this Realm.

    :see: add(object:update:)

    :param: objects A sequence which contains objects to be added to this Realm.
    :param: update If true will try to update existing objects with the same primary key.
    */
    public func add<S: SequenceType where S.Generator.Element: Object>(objects: S, update: Bool = false) {
        for obj in objects {
            add(obj, update: update)
        }
    }

    /**
    Create an `Object` with the given value.

    Creates or updates an instance of this object and adds it to the `Realm` populating
    the object with the given value.
    
    When 'update' is 'true', the object must have a primary key. If no objects exist in
    the Realm instance with the same primary key value, the object is inserted. Otherwise, 
    the existing object is updated with any changed values.

    :param: type    The object type to create.
    :param: value   The value used to populate the object. This can be any key/value coding compliant
                    object, or a JSON dictionary such as those returned from the methods in `NSJSONSerialization`,
                    or an `Array` with one object for each persisted property. An exception will be
                    thrown if any required properties are not present and no default is set.

                    When passing in an `Array`, all properties must be present,
                    valid and in the same order as the properties defined in the model.
    :param: update  If true will try to update existing objects with the same primary key.

    :returns: The created object.
    */
    public func create<T: Object>(type: T.Type, value: AnyObject = [:], update: Bool = false) -> T {
        if update && schema[T.className()]?.primaryKeyProperty == nil {
          throwRealmException("'\(T.className())' does not have a primary key and can not be updated")
        }
        return unsafeBitCast(RLMCreateObjectInRealmWithValue(rlmRealm, T.className(), value, update), T.self)
    }

    // MARK: Deleting objects

    /**
    Deletes the given object from this Realm.

    :param: object The object to be deleted.
    */
    public func delete(object: Object) {
        RLMDeleteObjectFromRealm(object, rlmRealm)
    }

    /**
    Deletes the given objects from this Realm.

    :param: object The objects to be deleted. This can be a `List<Object>`, `Results<Object>`,
                   or any other enumerable SequenceType which generates Object.
    */
    public func delete<S: SequenceType where S.Generator.Element: Object>(objects: S) {
        for obj in objects {
            delete(obj)
        }
    }

    /**
    Deletes the given objects from this Realm.

    :param: object The objects to be deleted. This can be a `List<Object>`, `Results<Object>`,
                   or any other enumerable SequenceType which generates Object.
    
    :nodoc:
    */
    public func delete<T: Object>(objects: List<T>) {
        rlmRealm.deleteObjects(objects._rlmArray)
    }

    /**
    Deletes the given objects from this Realm.

    :param: object The objects to be deleted. This can be a `List<Object>`, `Results<Object>`,
                   or any other enumerable SequenceType which generates Object.
    
    :nodoc:
    */
    public func delete<T: Object>(objects: Results<T>) {
        rlmRealm.deleteObjects(objects.rlmResults)
    }

    /**
    Deletes all objects from this Realm.
    */
    public func deleteAll() {
        RLMDeleteAllObjectsFromRealm(rlmRealm)
    }

    // MARK: Object Retrieval

    /**
    Returns all objects of the given type in the Realm.

    :param: type  The type of the objects to be returned.

    :returns: All objects of the given type in Realm.
    */
    public func objects<T: Object>(type: T.Type) -> Results<T> {
        return Results<T>(RLMGetObjects(rlmRealm, T.className(), nil))
    }

    /**
    Get an object with the given primary key.

    Returns `nil` if no object exists with the given primary key.

    This method requires that `primaryKey()` be overridden on the given subclass.

    :see: Object.primaryKey()

    :param: type    The type of the objects to be returned.
    :param: key     The primary key of the desired object.

    :returns: An object of type `type` or `nil` if an object with the given primary key does not exist.
    */
    public func objectForPrimaryKey<T: Object>(type: T.Type, key: AnyObject) -> T? {
        return unsafeBitCast(RLMGetObject(rlmRealm, type.className(), key), Optional<T>.self)
    }


    // MARK: Notifications

    /**
    Add a notification handler for changes in this Realm.

    :param: block A block which is called to process Realm notifications.
                  It receives the following parameters:

                  - `Notification`: The incoming notification.
                  - `Realm`:        The realm for which this notification occurred.

    :returns: A notification token which can later be passed to `removeNotification(_:)`
              to remove this notification.
    */
    public func addNotificationBlock(block: NotificationBlock) -> NotificationToken {
        return rlmRealm.addNotificationBlock(rlmNotificationBlockFromNotificationBlock(block))
    }

    /**
    Remove a previously registered notification handler using the token returned
    from `addNotificationBlock(_:)`

    :param: notificationToken The token returned from `addNotificationBlock(_:)`
                              corresponding to the notification block to remove.
    */
    public func removeNotification(notificationToken: NotificationToken) {
        rlmRealm.removeNotification(notificationToken)
    }


    // MARK: Autorefresh and Refresh

    /**
    Whether this Realm automatically updates when changes happen in other threads.

    If set to `true` (the default), changes made on other threads will be reflected
    in this Realm on the next cycle of the run loop after the changes are
    committed.  If set to `false`, you must manually call -refresh on the Realm to
    update it to get the latest version.

    Even with this enabled, you can still call `refresh()` at any time to update the
    Realm before the automatic refresh would occur.

    Notifications are sent when a write transaction is committed whether or not
    this is enabled.

    Disabling this on a `Realm` without any strong references to it will not
    have any effect, and it will switch back to YES the next time the `Realm`
    object is created. This is normally irrelevant as it means that there is
    nothing to refresh (as persisted `Object`s, `List`s, and `Results` have strong
    references to the containing `Realm`), but it means that setting
    `Realm().autorefresh = false` in
    `application(_:didFinishLaunchingWithOptions:)` and only later storing Realm
    objects will not work.

    Defaults to true.
    */
    public var autorefresh: Bool {
        get {
            return rlmRealm.autorefresh
        }
        set {
            rlmRealm.autorefresh = newValue
        }
    }

    /**
    Update a `Realm` and outstanding objects to point to the most recent
    data for this `Realm`.

    :returns: Whether the realm had any updates.
              Note that this may return true even if no data has actually changed.

    */
    public func refresh() -> Bool {
        return rlmRealm.refresh()
    }

    // MARK: Invalidation

    /**
    Invalidate all `Object`s and `Results` read from this Realm.

    A Realm holds a read lock on the version of the data accessed by it, so
    that changes made to the Realm on different threads do not modify or delete the
    data seen by this Realm. Calling this method releases the read lock,
    allowing the space used on disk to be reused by later write transactions rather
    than growing the file. This method should be called before performing long
    blocking operations on a background thread on which you previously read data
    from the Realm which you no longer need.

    All `Object`, `Results` and `List` instances obtained from this
    `Realm` on the current thread are invalidated, and can not longer be used.
    The `Realm` itself remains valid, and a new read transaction is implicitly
    begun the next time data is read from the Realm.

    Calling this method multiple times in a row without reading any data from the
    Realm, or before ever reading any data from the Realm is a no-op. This method
    cannot be called on a read-only Realm.
    */
    public func invalidate() {
        rlmRealm.invalidate()
    }

    // MARK: Writing a Copy

    /**
    Write an encrypted and compacted copy of the Realm to the given path.

    The destination file cannot already exist.

    Note that if this is called from within a write transaction it writes the
    *current* data, and not data when the last write transaction was committed.

    :param: path          Path to save the Realm to.
    :param: encryptionKey Optional 64-byte encryption key to encrypt the new file with.
    :returns:             If an error occurs, returns an `NSError` object, otherwise `nil`.

    :returns: Whether the realm was copied successfully.
    */
    public func writeCopyToPath(path: String, encryptionKey: NSData? = nil) -> NSError? {
        var error: NSError?
        if let encryptionKey = encryptionKey {
            rlmRealm.writeCopyToPath(path, encryptionKey: encryptionKey, error: &error)
        } else {
            rlmRealm.writeCopyToPath(path, error: &error)
        }
        return error
    }

    // MARK: Encryption

    /**
    Set the encryption key to use when opening Realms at a certain path.

    This can be used as an alternative to explicitly passing the key to
    `Realm(path:, encryptionKey:, readOnly:, error:)` each time a Realm instance is
    needed. The encryption key will be used any time a Realm is opened with
    `Realm(path:)` or `Realm()`.

    If you do not want Realm to hold on to your encryption keys any longer than
    needed, then use `Realm(path:, encryptionKey:, readOnly:, error:)` rather than this
    method.

    :param: encryptionKey 64-byte encryption key to use, or `nil` to unset.
    :param: path          Realm path to set the encryption key for.
    +*/
    public class func setEncryptionKey(encryptionKey: NSData?, forPath: String = Realm.defaultPath) {
        RLMRealm.setEncryptionKey(encryptionKey, forRealmsAtPath: forPath)
    }

    // MARK: Internal
    internal var rlmRealm: RLMRealm

    internal init(_ rlmRealm: RLMRealm) {
        self.rlmRealm = rlmRealm
    }
}

// MARK: Equatable

extension Realm: Equatable { }

/// Returns whether the two realms are equal.
public func ==(lhs: Realm, rhs: Realm) -> Bool {
    return lhs.rlmRealm == rhs.rlmRealm
}

// MARK: Notifications

/// A notification due to changes to a realm.
public enum Notification: String {
    /**
    Posted when the data in a realm has changed.

    DidChange are posted after a realm has been refreshed to reflect a write transaction, i.e. when
    an autorefresh occurs, `refresh()` is called, after an implicit refresh from
    `beginWriteTransaction()`, and after a local write transaction is committed.
    */
    case DidChange = "RLMRealmDidChangeNotification"

    /**
    Posted when a write transaction has been committed to a realm on a different thread for the same
    file. This is not posted if `autorefresh` is enabled or if the Realm is refreshed before the
    notifcation has a chance to run.

    Realms with autorefresh disabled should normally have a handler for this notification which
    calls `refresh()` after doing some work.
    While not refreshing is allowed, it may lead to large Realm files as Realm has to keep an extra
    copy of the data for the un-refreshed Realm.
    */
    case RefreshRequired = "RLMRealmRefreshRequiredNotification"
}

/// Closure to run when the data in a Realm was modified.
public typealias NotificationBlock = (notification: Notification, realm: Realm) -> Void

internal func rlmNotificationBlockFromNotificationBlock(notificationBlock: NotificationBlock) -> RLMNotificationBlock {
    return { rlmNotification, rlmRealm in
        return notificationBlock(notification: Notification(rawValue: rlmNotification)!, realm: Realm(rlmRealm))
    }
}
