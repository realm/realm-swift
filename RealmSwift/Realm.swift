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
 A `Realm` instance (also referred to as "a Realm") represents a Realm database.

 Realms can either be stored on disk (see `init(path:)`) or in memory (see `Configuration`).

 `Realm` instances are cached internally, and constructing equivalent `Realm` objects (for example,
 by using the same path or identifier) produces limited overhead.

 If you specifically want to ensure a `Realm` instance is destroyed (for example, if you wish to
 open a Realm, check some property, and then possibly delete the Realm file and re-open it), place
 the code which uses the Realm within an `autoreleasepool {}` and ensure you have no other strong
 references to it.

 - warning Non-frozen `RLMRealm` instances are thread-confined and cannot be
 shared across threads or dispatch queues. Trying to do so will cause an
 exception to be thrown. You must obtain an instance of `RLMRealm` on each
 thread or queue you want to interact with the Realm on. Realms can be confined
 to a dispatch queue rather than the thread they are opened on by explicitly
 passing in the queue when obtaining the `RLMRealm` instance. If this is not
 done, trying to use the same instance in multiple blocks dispatch to the same
 queue may fail as queues are not always run on the same thread.
 */
@frozen public struct Realm {

    // MARK: Properties

    /// The `Schema` used by the Realm.
    public var schema: Schema { return Schema(rlmRealm.schema) }

    /// The `Configuration` value that was used to create the `Realm` instance.
    public var configuration: Configuration { return Configuration.fromRLMRealmConfiguration(rlmRealm.configuration) }

    /// Indicates if the Realm contains any objects.
    public var isEmpty: Bool { return rlmRealm.isEmpty }

    // MARK: Initializers

    /**
     Obtains an instance of the default Realm.

     The default Realm is persisted as *default.realm* under the *Documents* directory of your Application on iOS, and
     in your application's *Application Support* directory on OS X.

     The default Realm is created using the default `Configuration`, which can be changed by setting the
     `Realm.Configuration.defaultConfiguration` property to a new value.

     - parameter queue: An optional dispatch queue to confine the Realm to. If
                        given, this Realm instance can be used from within
                        blocks dispatched to the given queue rather than on the
                        current thread.
     - throws: An `NSError` if the Realm could not be initialized.
     */
    public init(queue: DispatchQueue? = nil) throws {
        let rlmRealm = try RLMRealm(configuration: RLMRealmConfiguration.rawDefault(), queue: queue)
        self.init(rlmRealm)
    }

    /**
     Obtains a `Realm` instance with the given configuration.

     - parameter configuration: A configuration value to use when creating the Realm.
     - parameter queue: An optional dispatch queue to confine the Realm to. If
                        given, this Realm instance can be used from within
                        blocks dispatched to the given queue rather than on the
                        current thread.

     - throws: An `NSError` if the Realm could not be initialized.
     */
    public init(configuration: Configuration, queue: DispatchQueue? = nil) throws {
        let rlmRealm = try RLMRealm(configuration: configuration.rlmConfiguration, queue: queue)
        self.init(rlmRealm)
    }

    /**
     Obtains a `Realm` instance persisted at a specified file URL.

     - parameter fileURL: The local URL of the file the Realm should be saved at.

     - throws: An `NSError` if the Realm could not be initialized.
     */
    public init(fileURL: URL) throws {
        var configuration = Configuration.defaultConfiguration
        configuration.fileURL = fileURL
        try self.init(configuration: configuration)
    }

    // MARK: Async

    /**
     Asynchronously open a Realm and deliver it to a block on the given queue.

     Opening a Realm asynchronously will perform all work needed to get the Realm to
     a usable state (such as running potentially time-consuming migrations) on a
     background thread before dispatching to the given queue. In addition,
     synchronized Realms wait for all remote content available at the time the
     operation began to be downloaded and available locally.

     The Realm passed to the callback function is confined to the callback
     queue as if `Realm(configuration:queue:)` was used.

     - parameter configuration: A configuration object to use when opening the Realm.
     - parameter callbackQueue: The dispatch queue on which the callback should be run.
     - parameter callback:      A callback block. If the Realm was successfully opened, an
                                it will be passed in as an argument.
                                Otherwise, a `Swift.Error` describing what went wrong will be
                                passed to the block instead.
     - returns: A task object which can be used to observe or cancel the async open.
     */
    @discardableResult
    public static func asyncOpen(configuration: Realm.Configuration = .defaultConfiguration,
                                 callbackQueue: DispatchQueue = .main,
                                 callback: @escaping (Result<Realm, Swift.Error>) -> Void) -> AsyncOpenTask {
        return AsyncOpenTask(rlmTask: RLMRealm.asyncOpen(with: configuration.rlmConfiguration, callbackQueue: callbackQueue, callback: { rlmRealm, error in
            if let realm = rlmRealm.flatMap(Realm.init) {
                callback(.success(realm))
            } else {
                callback(.failure(error ?? Realm.Error.callFailed))
            }
        }))
    }

    #if canImport(Combine)
    /**
     Asynchronously open a Realm and deliver it to a block on the given queue.

     Opening a Realm asynchronously will perform all work needed to get the Realm to
     a usable state (such as running potentially time-consuming migrations) on a
     background thread before dispatching to the given queue. In addition,
     synchronized Realms wait for all remote content available at the time the
     operation began to be downloaded and available locally.

     The Realm passed to the publisher is confined to the callback
     queue as if `Realm(configuration:queue:)` was used.

     - parameter configuration: A configuration object to use when opening the Realm.
     - parameter callbackQueue: The dispatch queue on which the AsyncOpenTask should be run.
     - returns: A publisher. If the Realm was successfully opened, it will be received by the subscribers.
                Otherwise, a `Swift.Error` describing what went wrong will be passed upstream instead.
     */
    @available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
    public static func asyncOpen(configuration: Realm.Configuration = .defaultConfiguration) -> RealmPublishers.AsyncOpenPublisher {
        return RealmPublishers.AsyncOpenPublisher(configuration: configuration)
    }
    #endif

    /**
     A task object which can be used to observe or cancel an async open.

     When a synchronized Realm is opened asynchronously, the latest state of the
     Realm is downloaded from the server before the completion callback is
     invoked. This task object can be used to observe the state of the download
     or to cancel it. This should be used instead of trying to observe the
     download via the sync session as the sync session itself is created
     asynchronously, and may not exist yet when Realm.asyncOpen() returns.
     */
    @frozen public struct AsyncOpenTask {
        internal let rlmTask: RLMAsyncOpenTask

        /**
         Cancel the asynchronous open.

         Any download in progress will be cancelled, and the completion block for this
         async open will never be called. If multiple async opens on the same Realm are
         happening concurrently, all other opens will fail with the error "operation cancelled".
         */
        public func cancel() { rlmTask.cancel() }

        /**
         Register a progress notification block.

         Each registered progress notification block is called whenever the sync
         subsystem has new progress data to report until the task is either cancelled
         or the completion callback is called. Progress notifications are delivered on
         the supplied queue.

         - parameter queue: The queue to deliver progress notifications on.
         - parameter block: The block to invoke when notifications are available.
         */
        public func addProgressNotification(queue: DispatchQueue = .main,
                                            block: @escaping (SyncSession.Progress) -> Void) {
            rlmTask.addProgressNotification(on: queue) { transferred, transferrable in
                block(SyncSession.Progress(transferred: transferred, transferrable: transferrable))
            }
        }
    }

    // MARK: Transactions

    /**
     Performs actions contained within the given block inside a write transaction.

     If the block throws an error, the transaction will be canceled and any
     changes made before the error will be rolled back.

     Only one write transaction can be open at a time for each Realm file. Write
     transactions cannot be nested, and trying to begin a write transaction on a
     Realm which is already in a write transaction will throw an exception.
     Calls to `write` from `Realm` instances for the same Realm file in other
     threads or other processes will block until the current write transaction
     completes or is cancelled.

     Before beginning the write transaction, `write` updates the `Realm`
     instance to the latest Realm version, as if `refresh()` had been called,
     and generates notifications if applicable. This has no effect if the Realm
     was already up to date.

     You can skip notifiying specific notification blocks about the changes made
     in this write transaction by passing in their associated notification
     tokens. This is primarily useful when the write transaction is saving
     changes already made in the UI and you do not want to have the notification
     block attempt to re-apply the same changes.

     The tokens passed to this function must be for notifications for this Realm
     which were added on the same thread as the write transaction is being
     performed on. Notifications for different threads cannot be skipped using
     this method.

     - parameter tokens: An array of notification tokens which were returned
                         from adding callbacks which you do not want to be
                         notified for the changes made in this write transaction.

     - parameter block: The block containing actions to perform.
     - returns: The value returned from the block, if any.

     - throws: An `NSError` if the transaction could not be completed successfully.
               If `block` throws, the function throws the propagated `ErrorType` instead.
     */
    @discardableResult
    public func write<Result>(withoutNotifying tokens: [NotificationToken] = [], _ block: (() throws -> Result)) throws -> Result {
        beginWrite()
        var ret: Result!
        do {
            ret = try block()
        } catch let error {
            if isInWriteTransaction { cancelWrite() }
            throw error
        }
        if isInWriteTransaction { try commitWrite(withoutNotifying: tokens) }
        return ret
    }

    /**
     Begins a write transaction on the Realm.

     Only one write transaction can be open at a time for each Realm file. Write
     transactions cannot be nested, and trying to begin a write transaction on a
     Realm which is already in a write transaction will throw an exception.
     Calls to `beginWrite` from `Realm` instances for the same Realm file in
     other threads or other processes will block until the current write
     transaction completes or is cancelled.

     Before beginning the write transaction, `beginWrite` updates the `Realm`
     instance to the latest Realm version, as if `refresh()` had been called,
     and generates notifications if applicable. This has no effect if the Realm
     was already up to date.

     It is rarely a good idea to have write transactions span multiple cycles of
     the run loop, but if you do wish to do so you will need to ensure that the
     Realm participating in the write transaction is kept alive until the write
     transaction is committed.
     */
    public func beginWrite() {
        rlmRealm.beginWriteTransaction()
    }

    /**
     Commits all write operations in the current write transaction, and ends
     the transaction.

     After saving the changes and completing the write transaction, all
     notification blocks registered on this specific `Realm` instance are called
     synchronously. Notification blocks for `Realm` instances on other threads
     and blocks registered for any Realm collection (including those on the
     current thread) are scheduled to be called synchronously.

     You can skip notifiying specific notification blocks about the changes made
     in this write transaction by passing in their associated notification
     tokens. This is primarily useful when the write transaction is saving
     changes already made in the UI and you do not want to have the notification
     block attempt to re-apply the same changes.

     The tokens passed to this function must be for notifications for this Realm
     which were added on the same thread as the write transaction is being
     performed on. Notifications for different threads cannot be skipped using
     this method.

     - warning: This method may only be called during a write transaction.

     - parameter tokens: An array of notification tokens which were returned
                         from adding callbacks which you do not want to be
                         notified for the changes made in this write transaction.

     - throws: An `NSError` if the transaction could not be written due to
               running out of disk space or other i/o errors.
     */
    public func commitWrite(withoutNotifying tokens: [NotificationToken] = []) throws {
        try rlmRealm.commitWriteTransactionWithoutNotifying(tokens)
    }

    /**
     Reverts all writes made in the current write transaction and ends the transaction.

     This rolls back all objects in the Realm to the state they were in at the
     beginning of the write transaction, and then ends the transaction.

     This restores the data for deleted objects, but does not revive invalidated
     object instances. Any `Object`s which were added to the Realm will be
     invalidated rather than becoming unmanaged.

     Given the following code:

     ```swift
     let oldObject = objects(ObjectType).first!
     let newObject = ObjectType()

     realm.beginWrite()
     realm.add(newObject)
     realm.delete(oldObject)
     realm.cancelWrite()
     ```

     Both `oldObject` and `newObject` will return `true` for `isInvalidated`,
     but re-running the query which provided `oldObject` will once again return
     the valid object.

     KVO observers on any objects which were modified during the transaction
     will be notified about the change back to their initial values, but no
     other notifcations are produced by a cancelled write transaction.

     - warning: This method may only be called during a write transaction.
     */
    public func cancelWrite() {
        rlmRealm.cancelWriteTransaction()
    }

    /**
     Indicates whether the Realm is currently in a write transaction.

     - warning:  Do not simply check this property and then start a write transaction whenever an object needs to be
                 created, updated, or removed. Doing so might cause a large number of write transactions to be created,
                 degrading performance. Instead, always prefer performing multiple updates during a single transaction.
     */
    public var isInWriteTransaction: Bool {
        return rlmRealm.inWriteTransaction
    }

    // MARK: Adding and Creating objects

    /**
     What to do when an object being added to or created in a Realm has a primary key that already exists.
     */
    @frozen public enum UpdatePolicy: Int {
        /**
         Throw an exception. This is the default when no policy is specified for `add()` or `create()`.

         This behavior is the same as passing `update: false` to `add()` or `create()`.
         */
        case error = 1
        /**
         Overwrite only properties in the existing object which are different from the new values. This results
         in change notifications reporting only the properties which changed, and influences the sync merge logic.

         If few or no of the properties are changing this will be faster than .all and reduce how much data has
         to be written to the Realm file. If all of the properties are changing, it may be slower than .all (but
         will never result in *more* data being written).
         */
        case modified = 3
        /**
         Overwrite all properties in the existing object with the new values, even if they have not changed. This
         results in change notifications reporting all properties as changed, and influences the sync merge logic.

         This behavior is the same as passing `update: true` to `add()` or `create()`.
         */
        case all = 2
    }

    /// :nodoc:
    @available(*, unavailable, message: "Pass .error, .modified or .all rather than a boolean. .error is equivalent to false and .all is equivalent to true.")
    public func add(_ object: Object, update: Bool) {
        fatalError()
    }

    /**
     Adds an unmanaged object to this Realm.

     If an object with the same primary key already exists in this Realm, it is updated with the property values from
     this object as specified by the `UpdatePolicy` selected. The update policy must be `.error` for objects with no
     primary key.

     Adding an object to a Realm will also add all child relationships referenced by that object (via `Object` and
     `List<Object>` properties). Those objects must also be valid objects to add to this Realm, and the value of
     the `update:` parameter is propagated to those adds.

     The object to be added must either be an unmanaged object or a valid object which is already managed by this
     Realm. Adding an object already managed by this Realm is a no-op, while adding an object which is managed by
     another Realm or which has been deleted from any Realm (i.e. one where `isInvalidated` is `true`) is an error.

     To copy a managed object from one Realm to another, use `create()` instead.

     - warning: This method may only be called during a write transaction.

     - parameter object: The object to be added to this Realm.
     - parameter update: What to do if an object with the same primary key alredy exists. Must be `.error` for objects
     without a primary key.
     */
    public func add(_ object: Object, update: UpdatePolicy = .error) {
        if update != .error && object.objectSchema.primaryKeyProperty == nil {
            throwRealmException("'\(object.objectSchema.className)' does not have a primary key and can not be updated")
        }
        // remove any observers still attached to the Realm.
        // if not using SwiftUI, this is a noop
        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *) {
            SwiftUIKVO.removeObservers(object: object)
        }
        RLMAddObjectToRealm(object, rlmRealm, RLMUpdatePolicy(rawValue: UInt(update.rawValue))!)
    }

    /// :nodoc:
    @available(*, unavailable, message: "Pass .error, .modified or .all rather than a boolean. .error is equivalent to false and .all is equivalent to true.")
    public func add<S: Sequence>(_ objects: S, update: Bool) where S.Iterator.Element: Object {
        fatalError()
    }

    /**
     Adds all the objects in a collection into the Realm.

     - see: `add(_:update:)`

     - warning: This method may only be called during a write transaction.

     - parameter objects: A sequence which contains objects to be added to the Realm.
     - parameter update: How to handle
     without a primary key.
     - parameter update: How to handle objects in the collection with a primary key that alredy exists in this
     Realm. Must be `.error` for object types without a primary key.
     */
    public func add<S: Sequence>(_ objects: S, update: UpdatePolicy = .error) where S.Iterator.Element: Object {
        for obj in objects {
            add(obj, update: update)
        }
    }

    /// :nodoc:
    @discardableResult
    @available(*, unavailable, message: "Pass .error, .modified or .all rather than a boolean. .error is equivalent to false and .all is equivalent to true.")
    public func create<T: Object>(_ type: T.Type, value: Any = [:], update: Bool) -> T {
        fatalError()
    }

    /**
     Creates a Realm object with a given value, adding it to the Realm and returning it.

     The `value` argument can be a Realm object, a key-value coding compliant object, an array
     or dictionary returned from the methods in `NSJSONSerialization`, or an `Array` containing
     one element for each managed property. Do not pass in a `LinkingObjects` instance, either
     by itself or as a member of a collection. If the `value` argument is an array, all properties
     must be present, valid and in the same order as the properties defined in the model.

     If the object type does not have a primary key or no object with the specified primary key
     already exists, a new object is created in the Realm. If an object already exists in the Realm
     with the specified primary key and the update policy is `.modified` or `.all`, the existing
     object will be updated and a reference to that object will be returned.

     If the object is being updated, all properties defined in its schema will be set by copying
     from `value` using key-value coding. If the `value` argument does not respond to `value(forKey:)`
     for a given property name (or getter name, if defined), that value will remain untouched.
     Nullable properties on the object can be set to nil by using `NSNull` as the updated value,
     or (if you are passing in an instance of an `Object` subclass) setting the corresponding
     property on `value` to nil.

     - warning: This method may only be called during a write transaction.

     - parameter type:   The type of the object to create.
     - parameter value:  The value used to populate the object.
     - parameter update: What to do if an object with the same primary key alredy exists. Must be `.error` for object
     types without a primary key.

     - returns: The newly created object.
     */
    @discardableResult
    public func create<T: Object>(_ type: T.Type, value: Any = [:], update: UpdatePolicy = .error) -> T {
        if update != .error {
            RLMVerifyHasPrimaryKey(type)
        }
        let typeName = (type as Object.Type).className()
        return unsafeDowncast(RLMCreateObjectInRealmWithValue(rlmRealm, typeName, value,
                                                              RLMUpdatePolicy(rawValue: UInt(update.rawValue))!), to: type)
    }

    /// :nodoc:
    @discardableResult
    @available(*, unavailable, message: "Pass .error, .modified or .all rather than a boolean. .error is equivalent to false and .all is equivalent to true.")
    public func dynamicCreate(_ typeName: String, value: Any = [:], update: Bool) -> DynamicObject {
        fatalError()
    }

    /**
     This method is useful only in specialized circumstances, for example, when building
     components that integrate with Realm. If you are simply building an app on Realm, it is
     recommended to use the typed method `create(_:value:update:)`.

     Creates or updates an object with the given class name and adds it to the `Realm`, populating
     the object with the given value.

     The `value` argument can be a Realm object, a key-value coding compliant object, an array
     or dictionary returned from the methods in `NSJSONSerialization`, or an `Array` containing
     one element for each managed property. Do not pass in a `LinkingObjects` instance, either
     by itself or as a member of a collection. If the `value` argument is an array, all properties
     must be present, valid and in the same order as the properties defined in the model.

     If the object type does not have a primary key or no object with the specified primary key
     already exists, a new object is created in the Realm. If an object already exists in the Realm
     with the specified primary key and the update policy is `.modified` or `.all`, the existing
     object will be updated and a reference to that object will be returned.

     If the object is being updated, all properties defined in its schema will be set by copying
     from `value` using key-value coding. If the `value` argument does not respond to `value(forKey:)`
     for a given property name (or getter name, if defined), that value will remain untouched.
     Nullable properties on the object can be set to nil by using `NSNull` as the updated value,
     or (if you are passing in an instance of an `Object` subclass) setting the corresponding
     property on `value` to nil.


     - warning: This method can only be called during a write transaction.

     - parameter className:  The class name of the object to create.
     - parameter value:      The value used to populate the object.
     - parameter update:     What to do if an object with the same primary key alredy exists.
     Must be `.error` for object types without a primary key.

     - returns: The created object.

     :nodoc:
     */
    @discardableResult
    public func dynamicCreate(_ typeName: String, value: Any = [:], update: UpdatePolicy = .error) -> DynamicObject {
        if update != .error && schema[typeName]?.primaryKeyProperty == nil {
            throwRealmException("'\(typeName)' does not have a primary key and can not be updated")
        }
        return noWarnUnsafeBitCast(RLMCreateObjectInRealmWithValue(rlmRealm, typeName, value,
                                                                   RLMUpdatePolicy(rawValue: UInt(update.rawValue))!),
                                   to: DynamicObject.self)
    }

    // MARK: Deleting objects

    /**
     Deletes an object from the Realm. Once the object is deleted it is considered invalidated.

     - warning: This method may only be called during a write transaction.

     - parameter object: The object to be deleted.
     */
    public func delete(_ object: ObjectBase) {
        RLMDeleteObjectFromRealm(object, rlmRealm)
    }

    /**
     Deletes zero or more objects from the Realm.

     Do not pass in a slice to a `Results` or any other auto-updating Realm collection
     type (for example, the type returned by the Swift `suffix(_:)` standard library
     method). Instead, make a copy of the objects to delete using `Array()`, and pass
     that instead. Directly passing in a view into an auto-updating collection may
     result in 'index out of bounds' exceptions being thrown.

     - warning: This method may only be called during a write transaction.

     - parameter objects:   The objects to be deleted. This can be a `List<Object>`,
                            `Results<Object>`, or any other Swift `Sequence` whose
                            elements are `Object`s (subject to the caveats above).
     */
    public func delete<S: Sequence>(_ objects: S) where S.Iterator.Element: ObjectBase {
        for obj in objects {
            delete(obj)
        }
    }

    /**
     Deletes zero or more objects from the Realm.

     - warning: This method may only be called during a write transaction.

     - parameter objects: A list of objects to delete.

     :nodoc:
     */
    public func delete<Element: ObjectBase>(_ objects: List<Element>) {
        rlmRealm.deleteObjects(objects._rlmCollection)
    }

    /**
     Deletes zero or more objects from the Realm.

     - warning: This method may only be called during a write transaction.

     - parameter objects: A map of objects to delete.

     :nodoc:
     */
    public func delete<Key: _MapKey, Value: ObjectBase>(_ map: Map<Key, Value?>) {
        rlmRealm.deleteObjects(map._rlmCollection)
    }

    /**
     Deletes zero or more objects from the Realm.

     - warning: This method may only be called during a write transaction.

     - parameter objects: A `Results` containing the objects to be deleted.

     :nodoc:
     */
    public func delete<Element: ObjectBase>(_ objects: Results<Element>) {
        rlmRealm.deleteObjects(objects.rlmResults)
    }

    /**
     Deletes all objects from the Realm.

     - warning: This method may only be called during a write transaction.
     */
    public func deleteAll() {
        RLMDeleteAllObjectsFromRealm(rlmRealm)
    }

    // MARK: Object Retrieval

    /**
     Returns all objects of the given type stored in the Realm.

     - parameter type: The type of the objects to be returned.

     - returns: A `Results` containing the objects.
     */
    public func objects<Element: Object>(_ type: Element.Type) -> Results<Element> {
        return Results(RLMGetObjects(rlmRealm, type.className(), nil))
    }

    /**
     This method is useful only in specialized circumstances, for example, when building
     components that integrate with Realm. If you are simply building an app on Realm, it is
     recommended to use the typed method `objects(type:)`.

     Returns all objects for a given class name in the Realm.

     - parameter typeName: The class name of the objects to be returned.
     - returns: All objects for the given class name as dynamic objects

     :nodoc:
     */
    public func dynamicObjects(_ typeName: String) -> Results<DynamicObject> {
        return Results<DynamicObject>(RLMGetObjects(rlmRealm, typeName, nil))
    }

    /**
     Retrieves the single instance of a given object type with the given primary key from the Realm.

     This method requires that `primaryKey()` be overridden on the given object class.

     - see: `Object.primaryKey()`

     - parameter type: The type of the object to be returned.
     - parameter key:  The primary key of the desired object.

     - returns: An object of type `type`, or `nil` if no instance with the given primary key exists.
     */
    public func object<Element: Object, KeyType>(ofType type: Element.Type, forPrimaryKey key: KeyType) -> Element? {
        return unsafeBitCast(RLMGetObject(rlmRealm, (type as Object.Type).className(),
                                          dynamicBridgeCast(fromSwift: key)) as! RLMObjectBase?,
                             to: Optional<Element>.self)
    }

    /**
     This method is useful only in specialized circumstances, for example, when building
     components that integrate with Realm. If you are simply building an app on Realm, it is
     recommended to use the typed method `objectForPrimaryKey(_:key:)`.

     Get a dynamic object with the given class name and primary key.

     Returns `nil` if no object exists with the given class name and primary key.

     This method requires that `primaryKey()` be overridden on the given subclass.

     - see: Object.primaryKey()

     - warning: This method is useful only in specialized circumstances.

     - parameter className:  The class name of the object to be returned.
     - parameter key:        The primary key of the desired object.

     - returns: An object of type `DynamicObject` or `nil` if an object with the given primary key does not exist.

     :nodoc:
     */
    public func dynamicObject(ofType typeName: String, forPrimaryKey key: Any) -> DynamicObject? {
        return unsafeBitCast(RLMGetObject(rlmRealm, typeName, key) as! RLMObjectBase?, to: Optional<DynamicObject>.self)
    }

    // MARK: Notifications

    /**
     Adds a notification handler for changes made to this Realm, and returns a notification token.

     Notification handlers are called after each write transaction is committed, independent of the thread or process.

     Handler blocks are called on the same thread that they were added on, and may only be added on threads which are
     currently within a run loop. Unless you are specifically creating and running a run loop on a background thread,
     this will normally only be the main thread.

     Notifications can't be delivered as long as the run loop is blocked by other activity. When notifications can't be
     delivered instantly, multiple notifications may be coalesced.

     You must retain the returned token for as long as you want updates to be sent to the block. To stop receiving
     updates, call `invalidate()` on the token.

     - parameter block: A block which is called to process Realm notifications. It receives the following parameters:
                        `notification`: the incoming notification; `realm`: the Realm for which the notification
                        occurred.

     - returns: A token which must be held for as long as you wish to continue receiving change notifications.
     */
    public func observe(_ block: @escaping NotificationBlock) -> NotificationToken {
        return rlmRealm.addNotificationBlock { rlmNotification, _ in
            switch rlmNotification {
            case RLMNotification.DidChange:
                block(.didChange, self)
            case RLMNotification.RefreshRequired:
                block(.refreshRequired, self)
            default:
                fatalError("Unhandled notification type: \(rlmNotification)")
            }
        }
    }

    // MARK: Autorefresh and Refresh

    /**
     Set this property to `true` to automatically update this Realm when changes happen in other threads.

     If set to `true` (the default), changes made on other threads will be reflected in this Realm on the next cycle of
     the run loop after the changes are committed.  If set to `false`, you must manually call `refresh()` on the Realm
     to update it to get the latest data.

     Note that by default, background threads do not have an active run loop and you will need to manually call
     `refresh()` in order to update to the latest version, even if `autorefresh` is set to `true`.

     Even with this property enabled, you can still call `refresh()` at any time to update the Realm before the
     automatic refresh would occur.

     Notifications are sent when a write transaction is committed whether or not automatic refreshing is enabled.

     Disabling `autorefresh` on a `Realm` without any strong references to it will not have any effect, and
     `autorefresh` will revert back to `true` the next time the Realm is created. This is normally irrelevant as it
     means that there is nothing to refresh (as managed `Object`s, `List`s, and `Results` have strong references to the
     `Realm` that manages them), but it means that setting `autorefresh = false` in
     `application(_:didFinishLaunchingWithOptions:)` and only later storing Realm objects will not work.

     Defaults to `true`.
     */
    public var autorefresh: Bool {
        get {
            return rlmRealm.autorefresh
        }
        nonmutating set {
            rlmRealm.autorefresh = newValue
        }
    }

    /**
     Updates the Realm and outstanding objects managed by the Realm to point to the most recent data.

     - returns: Whether there were any updates for the Realm. Note that `true` may be returned even if no data actually
     changed.
     */
    @discardableResult
    public func refresh() -> Bool {
        return rlmRealm.refresh()
    }

    // MARK: Frozen Realms

    /// Returns if this Realm is frozen.
    public var isFrozen: Bool {
        return rlmRealm.isFrozen
    }

    /**
     Returns a frozen (immutable) snapshot of this Realm.

     A frozen Realm is an immutable snapshot view of a particular version of a Realm's data. Unlike
     normal Realm instances, it does not live-update to reflect writes made to the Realm, and can be
     accessed from any thread. Writing to a frozen Realm is not allowed, and attempting to begin a
     write transaction will throw an exception.

     All objects and collections read from a frozen Realm will also be frozen.

     - warning: Holding onto a frozen Realm for an extended period while performing write
     transaction on the Realm may result in the Realm file growing to large sizes. See
     `Realm.Configuration.maximumNumberOfActiveVersions` for more information.
     */
    public func freeze() -> Realm {
        return isFrozen ? self : Realm(rlmRealm.freeze())
    }

    /**
     Returns a live (mutable) reference of this Realm.

     All objects and collections read from the returned Realm reference will no longer be frozen.
     Will return self if called on a Realm that is not already frozen.
     */
    public func thaw() -> Realm {
        return isFrozen ? Realm(rlmRealm.thaw()) : self
    }

    /**
     Returns a frozen (immutable) snapshot of the given object.

     The frozen copy is an immutable object which contains the same data as the given object
     currently contains, but will not update when writes are made to the containing Realm. Unlike
     live objects, frozen objects can be accessed from any thread.

     - warning: Holding onto a frozen object for an extended period while performing write
     transaction on the Realm may result in the Realm file growing to large sizes. See
     `Realm.Configuration.maximumNumberOfActiveVersions` for more information.
     */
    public func freeze<T: ObjectBase>(_ obj: T) -> T {
        return RLMObjectFreeze(obj) as! T
    }

    /**
     Returns a live (mutable) reference of this object.

     This method creates a managed accessor to a live copy of the same frozen object.
     Will return self if called on an already live object.
     */
    public func thaw<T: ObjectBase>(_ obj: T) -> T? {
        return RLMObjectThaw(obj) as? T
    }

    /**
     Returns a frozen (immutable) snapshot of the given collection.

     The frozen copy is an immutable collection which contains the same data as the given
     collection currently contains, but will not update when writes are made to the containing
     Realm. Unlike live collections, frozen collections can be accessed from any thread.

     - warning: This method cannot be called during a write transaction, or when the Realm is read-only.
     - warning: Holding onto a frozen collection for an extended period while performing write
     transaction on the Realm may result in the Realm file growing to large sizes. See
     `Realm.Configuration.maximumNumberOfActiveVersions` for more information.
    */
    public func freeze<Collection: RealmCollection>(_ collection: Collection) -> Collection {
        return collection.freeze()
    }

    // MARK: Invalidation

    /**
     Invalidates all `Object`s, `Results`, `LinkingObjects`, and `List`s managed by the Realm.

     A Realm holds a read lock on the version of the data accessed by it, so
     that changes made to the Realm on different threads do not modify or delete the
     data seen by this Realm. Calling this method releases the read lock,
     allowing the space used on disk to be reused by later write transactions rather
     than growing the file. This method should be called before performing long
     blocking operations on a background thread on which you previously read data
     from the Realm which you no longer need.

     All `Object`, `Results` and `List` instances obtained from this `Realm` instance on the current thread are
     invalidated. `Object`s and `Array`s cannot be used. `Results` will become empty. The Realm itself remains valid,
     and a new read transaction is implicitly begun the next time data is read from the Realm.

     Calling this method multiple times in a row without reading any data from the
     Realm, or before ever reading any data from the Realm, is a no-op.
     */
    public func invalidate() {
        rlmRealm.invalidate()
    }

    // MARK: File Management

    /**
     Writes a compacted and optionally encrypted copy of the Realm to the given local URL.

     The destination file cannot already exist.

     Note that if this method is called from within a write transaction, the *current* data is written, not the data
     from the point when the previous write transaction was committed.

     - parameter fileURL:       Local URL to save the Realm to.
     - parameter encryptionKey: Optional 64-byte encryption key to encrypt the new file with.

     - throws: An `NSError` if the copy could not be written.
     */
    public func writeCopy(toFile fileURL: URL, encryptionKey: Data? = nil) throws {
        try rlmRealm.writeCopy(to: fileURL, encryptionKey: encryptionKey)
    }

    /**
     Checks if the Realm file for the given configuration exists locally on disk.

     For non-synchronized, non-in-memory Realms, this is equivalent to
     `FileManager.default.fileExists(atPath:)`. For synchronized Realms, it
     takes care of computing the actual path on disk based on the server,
     virtual path, and user as is done when opening the Realm.

     @param config A Realm configuration to check the existence of.
     @return true if the Realm file for the given configuration exists on disk, false otherwise.
     */
    public static func fileExists(for config: Configuration) -> Bool {
        return RLMRealm.fileExists(for: config.rlmConfiguration)
    }

    /**
     Deletes the local Realm file and associated temporary files for the given configuration.

     This deletes the ".realm", ".note" and ".management" files which would be
     created by opening the Realm with the given configuration. It does not
     delete the ".lock" file (which contains no persisted data and is recreated
     from scratch every time the Realm file is opened).

     The Realm must not be currently open on any thread or in another process.
     If it is, this will throw the error .alreadyOpen. Attempting to open the
     Realm on another thread while the deletion is happening will block, and
     then create a new Realm and open that afterwards.

     If the Realm already does not exist this will return `false`.

     @param config A Realm configuration identifying the Realm to be deleted.
     @return true if any files were deleted, false otherwise.
     */
    public static func deleteFiles(for config: Configuration) throws -> Bool {
        return try RLMRealm.deleteFiles(for: config.rlmConfiguration)
    }

    // MARK: Internal

    internal var rlmRealm: RLMRealm

    internal init(_ rlmRealm: RLMRealm) {
        self.rlmRealm = rlmRealm
    }
}

// MARK: Equatable

extension Realm: Equatable {
    /// Returns whether two `Realm` instances are equal.
    public static func == (lhs: Realm, rhs: Realm) -> Bool {
        return lhs.rlmRealm == rhs.rlmRealm
    }
}

// MARK: Notifications

extension Realm {
    /// A notification indicating that changes were made to a Realm.
    @frozen public enum Notification: String {
        /**
         This notification is posted when the data in a Realm has changed.

         `didChange` is posted after a Realm has been refreshed to reflect a write transaction, This can happen when an
         autorefresh occurs, `refresh()` is called, after an implicit refresh from `write(_:)`/`beginWrite()`, or after
         a local write transaction is committed.
         */
        case didChange = "RLMRealmDidChangeNotification"

        /**
         This notification is posted when a write transaction has been committed to a Realm on a different thread for
         the same file.

         It is not posted if `autorefresh` is enabled, or if the Realm is refreshed before the notification has a chance
         to run.

         Realms with autorefresh disabled should normally install a handler for this notification which calls
         `refresh()` after doing some work. Refreshing the Realm is optional, but not refreshing the Realm may lead to
         large Realm files. This is because an extra copy of the data must be kept for the stale Realm.
         */
        case refreshRequired = "RLMRealmRefreshRequiredNotification"
    }
}

/// The type of a block to run for notification purposes when the data in a Realm is modified.
public typealias NotificationBlock = (_ notification: Realm.Notification, _ realm: Realm) -> Void
